// Firewall whitelist auto-update — Mac slot 4 (pinned), iOS slotless (LRU)
// Triggered by: network-changed event + cron (via 华东 Po0 Firewall Update .sgmodule)
// Console-only logging — no notifications.

// Token 由 .sgmodule 的 argument=token=xxx 注入 —— 脚本本身不含密钥，可公开托管
var API_TOKEN = '';
try {
  var _arg = (typeof $argument !== 'undefined' && $argument) ? String($argument) : '';
  var _m = _arg.match(/(?:^|&)token=([^&]+)/);
  API_TOKEN = _m ? _m[1] : _arg.trim();
} catch (e) {}
var API_BASE = 'https://124.221.69.228/api/firewall/';
var STORE_PREFIX = 'txpo0_fw_';
var HTTP_TIMEOUT = 10;   // 服务端自身处理就要 1.4-1.9s；3s 会常态化超时（实测 132 次 timeout）
var RETRY_DELAY = 2000;  // 仅对超时/网络错误重试一次；429/403 不重试

// --- Slot detection: macOS → slot 4 (pinned, never LRU-evicted); iOS → slotless ---
var slot = 0;
try {
  var sys = ($environment.system || '').toLowerCase();
  slot = sys === 'macos' ? 4 : 0;
} catch (e) {}

// --- Link type (logging + iOS cellular delay) ---
var link = 'wired';
try {
  var iface = ($network.v4 && $network.v4.primaryInterface) ||
              ($network.v6 && $network.v6.primaryInterface) || '';
  if (iface.indexOf('pdp_ip') === 0) link = 'cell';
} catch (e) {}

var label = slot > 0 ? 'slot=' + slot : 'slotless';
var apiURL = API_BASE + encodeURIComponent(API_TOKEN) + '/add';
var body = slot > 0 ? JSON.stringify({ slot: slot }) : '{}';

function storeWrite(k, v) {
  try { if (typeof $persistentStore !== 'undefined') $persistentStore.write(v, STORE_PREFIX + k); } catch (e) {}
}
function stamp() {
  var d = new Date();
  var p = function (n) { return (n < 10 ? '0' : '') + n; };
  return p(d.getMonth() + 1) + '-' + p(d.getDate()) + ' ' + p(d.getHours()) + ':' + p(d.getMinutes()) + ':' + p(d.getSeconds());
}
function record(result) {
  storeWrite('result', stamp() + ' ' + result);   // 供面板显示
  console.log('🔥 ' + label + ' ' + result);
}
function finish() { try { $done(); } catch (e) {} }

function attempt(n) {
  $httpClient.post({
    url: apiURL,
    headers: { 'Content-Type': 'application/json' },
    body: body,
    policy: 'DIRECT',
    timeout: HTTP_TIMEOUT
  }, function (e, resp, data) {
    var status = resp && (resp.status || resp.statusCode);

    // 传输层失败（含超时）→ 重试一次
    if (e) {
      if (n === 0) {
        console.log('🔥 ' + label + ' retry after: ' + e);
        setTimeout(function () { attempt(1); }, RETRY_DELAY);
        return;
      }
      record('fail: ' + e);
      finish();
      return;
    }

    // HTTP 状态码必须校验 —— 429/403 以前会被误报成 ok
    if (status === 429) { record('fail: rate limited (429)，不重试'); finish(); return; }
    if (status === 403) { record('fail: 403 槽位冲突（本机段已被钉在其他槽位，去面板删）'); finish(); return; }
    if (status !== 200 && status !== 204) { record('fail: HTTP ' + status); finish(); return; }

    var parsed = null;
    try { parsed = JSON.parse(data); } catch (err) {}
    if (!parsed || parsed.currentIp === undefined) {
      var why = parsed && parsed.message ? parsed.message : String(data).slice(0, 60);
      record('fail: HTTP ' + status + ' 响应异常: ' + why);
      finish();
      return;
    }

    storeWrite('last_ip', parsed.currentIp);
    record('ok ' + parsed.currentIp + ' (' + (parsed.whitelist ? parsed.whitelist.length : '?') + '/' + parsed.limit + ')');
    finish();
  });
}

console.log('📱 ' + (slot > 0 ? 'macOS detected, slot=4 (pinned, ' : 'iOS detected, slotless (LRU, ') + link + ')');

// 没拿到 token 就别发（否则会打到 /api/firewall//add 上）
if (!API_TOKEN) {
  record('fail: 未拿到 token（检查 .sgmodule 的 argument=token=xxx）');
} else if (slot === 0 && link === 'cell') {
  // iOS 蜂窝：network-changed 触发时接口可能还没就绪，等 2s 再发
  setTimeout(function () { attempt(0); }, 2000);
} else {
  attempt(0);
}
