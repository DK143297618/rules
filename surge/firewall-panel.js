// Firewall whitelist status panel — Mac slot 4 (pinned), iOS slotless (LRU)
// Single token. Shows: exit CIDR, whitelist N/limit, all CIDRs with slot/cell markers.
// Features: history tracking, change detection, error handling.
// Triggered via Surge Panel (generic script) — read-only status viewer.

// Token 由 .sgmodule 的 argument=token=xxx 注入 —— 脚本本身不含密钥，可公开托管
var API_TOKEN = '';
try {
  var _arg = (typeof $argument !== 'undefined' && $argument) ? String($argument) : '';
  var _m = _arg.match(/(?:^|&)token=([^&]+)/);
  API_TOKEN = _m ? _m[1] : _arg.trim();
} catch (e) {}
var API_BASE = 'https://124.221.69.228/api/firewall/';
var STORE_PREFIX = 'txpo0_fw_';
var HIST_MS = 24 * 3600 * 1000;

// --- Slot detection ---
var slot = 0;
try {
  var sys = ($environment.system || '').toLowerCase();
  slot = sys === 'macos' ? 4 : 0;
} catch(e) {}

// --- Helpers ---
function storeRead(k) {
  return typeof $persistentStore !== 'undefined' ? $persistentStore.read(k) : null;
}
function storeWrite(v, k) {
  return typeof $persistentStore !== 'undefined' ? $persistentStore.write(v, k) : false;
}
function httpPost(url, body) {
  return new Promise(function(r) {
    $httpClient.post({
      url: url, headers: { 'Content-Type': 'application/json' }, body: body || '{}', policy: 'DIRECT', timeout: 15
    }, function(e, resp, b) {
      if (e) r({ error: String(e) });
      else r({ body: b, status: resp && (resp.status || resp.statusCode) });
    });
  });
}
function onCell() {
  try {
    var iface = ($network.v4 && $network.v4.primaryInterface) ||
                ($network.v6 && $network.v6.primaryInterface) || '';
    return iface.indexOf('pdp_ip') === 0;
  } catch(e) { return false; }
}
function readHist(k) {
  try {
    var h = JSON.parse(storeRead(k) || '[]');
    return h.filter(function(e) { return e.ts > Date.now() - HIST_MS; });
  } catch(e) { return []; }
}

var apiURL = API_BASE + encodeURIComponent(API_TOKEN) + '/add';
var isCell = onCell();

httpPost(apiURL, slot > 0 ? JSON.stringify({slot: slot}) : '{}')
  .then(function(r) {
    var title, content, icon, iconColor;

    if (r.error) {
      title = '🔥 防火墙 ❌'; content = '请求失败: ' + r.error;
      icon = 'exclamationmark.shield'; iconColor = '#FF3B30';
    } else if (r.status === 403) {
      title = '🔥 防火墙 ❌ 冲突'; content = '本机段已在其他槽位，去 UI 删除';
      icon = 'exclamationmark.shield'; iconColor = '#FF3B30';
    } else {
      var data;
      try { data = JSON.parse(r.body); } catch(e) {}
      if (!data) {
        title = '🔥 防火墙 ❌'; content = '响应异常: ' + String(r.body).slice(0, 80);
        icon = 'exclamationmark.shield'; iconColor = '#FF3B30';
      } else if (data.enabled === false) {
        title = '🔥 防火墙 ⚠️'; content = '防火墙未启用';
        icon = 'exclamationmark.shield'; iconColor = '#FF9500';
      } else if (data.currentIp === undefined || data.code === 400) {
        title = '🔥 防火墙 ❌';
        content = data.message || ('无法获取出口段' + (isCell ? ' 📶' : ''));
        icon = 'exclamationmark.shield'; iconColor = '#FF3B30';
        console.log('🔥 error: ' + (data.message || 'no currentIp') + (isCell ? ' cell' : ''));
      } else {
        // Parse whitelist
        var raw = Array.isArray(data.whitelist) ? data.whitelist : [];
        var slotOf = {};
        raw.forEach(function(e) {
          if (e && typeof e === 'object' && e.slot != null) slotOf[e.ip] = e.slot;
        });
        var ips = raw.map(function(e) { return e && typeof e === 'object' ? e.ip : e; });
        var applied = data.enabled === true && ips.indexOf(data.currentIp) !== -1;

        // History tracking (last 10 CIDR changes — CIDR 稳定，几乎不会变)
        var hist = readHist(STORE_PREFIX + 'hist');
        if (!hist.length || hist[hist.length - 1].ip !== data.currentIp) {
          hist.push({ ip: data.currentIp, src: isCell ? 'cell' : 'fixed', ts: Date.now() });
          storeWrite(JSON.stringify(hist.slice(-10)), STORE_PREFIX + 'hist');
        }

        // Change detection
        var prevState = storeRead(STORE_PREFIX + 'state');
        var newState = (data.currentIp || '?') + '|' + (applied ? '1' : '0');
        var changed = prevState !== newState;
        storeWrite(newState, STORE_PREFIX + 'state');

        // Build display
        var lines = ips.map(function(ip, i) {
          var t = [];
          if (slotOf[ip] !== undefined) t.push('📌' + slotOf[ip]);
          if (hist.some(function(h) { return h.ip === ip && h.src === 'cell'; })) t.push('📶');
          return (i + 1) + '. ' + ip + (t.length ? ' ' + t.join('') : '') + (ip === data.currentIp ? ' ←' : '');
        });

        var sl = slot > 0 ? ' 📌' + slot : ' LRU';
        title = '🔥 防火墙 ' + ips.length + '/' + data.limit + sl + (isCell ? ' 📶' : '');
        var lastRun = storeRead(STORE_PREFIX + 'result');
        content = '出口段: ' + data.currentIp + (applied ? ' ✅' : ' ❌') +
                  (lastRun ? '\n上次自动更新: ' + lastRun : '') +
                  '\n白名单:\n' + lines.join('\n');
        icon = applied ? 'checkmark.shield' : 'exclamationmark.shield';
        iconColor = applied ? '#34C759' : '#FF3B30';

        // 变更只记日志（用户偏好：不要通知）
        if (changed) {
          console.log('🔥 changed: 出口段 ' + data.currentIp + ' (' + ips.length + '/' + data.limit + ')');
        }

        console.log('🔥 panel: ' + data.currentIp + ' ' + ips.length + '/' + data.limit +
                    (changed ? ' changed' : '') + (isCell ? ' cell' : ''));
      }
    }
    $done({ title: title, content: content, icon: icon, 'icon-color': iconColor });
  });
