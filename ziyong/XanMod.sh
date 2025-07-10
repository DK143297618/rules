#!/bin/bash

# This script adds the XanMod kernel repository, fetches the necessary GPG keys,
# detects the CPU instruction set, installs the appropriate XanMod kernel version,
# and reboots the system.

set -euo pipefail

# Function to handle errors
error() {
    echo "Error: $1" >&2
    exit 1
}

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root."
fi

# Update package lists
echo "Updating package lists..."
apt update || error "Failed to update package lists."

# Install necessary tools (gpg and curl)
for cmd in gpg curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Installing $cmd..."
        apt install "$cmd" -y || error "Failed to install $cmd."
    fi
done

# Ensure the keyrings directory exists
KEYRING_DIR="/etc/apt/keyrings"
mkdir -p "$KEYRING_DIR"

# Define XanMod's GPG key URL and keyring file path
XANMOD_KEY_URL="https://dl.xanmod.org/archive.key"
XANMOD_KEYRING="$KEYRING_DIR/xanmod-archive-keyring.gpg"

# Method 1: Use gpg options to suppress prompts
echo "Adding XanMod GPG key using gpg options..."
if ! curl -fsSL "$XANMOD_KEY_URL" | gpg --batch --yes --dearmor -o "$XANMOD_KEYRING"; then
    echo "Failed to add GPG key using gpg options. Trying Method 2..."

    # Method 2: Remove existing keyring file before writing
    rm -f "$XANMOD_KEYRING"
    if ! curl -fsSL "$XANMOD_KEY_URL" | gpg --dearmor -o "$XANMOD_KEYRING"; then
        error "Failed to add GPG key from $XANMOD_KEY_URL using both methods."
    fi
fi

# Define the repository list file and repository entry
REPO_LIST="/etc/apt/sources.list.d/xanmod-release.list"
REPO_ENTRY="deb [signed-by=$XANMOD_KEYRING] http://deb.xanmod.org releases main"

# Check if the repository is already added
if [ ! -f "$REPO_LIST" ] || ! grep -Fxq "$REPO_ENTRY" "$REPO_LIST"; then
    echo "Adding XanMod repository..."
    echo "$REPO_ENTRY" | tee "$REPO_LIST" >/dev/null
else
    echo "XanMod repository already exists."
fi

# Update package lists to include the new repository
echo "Updating package lists (including XanMod repository)..."
apt update || error "Failed to update package lists after adding repository."

# Detect CPU instruction set
echo "Detecting CPU instruction set..."
cpu_flags=$(grep -o -w -E 'lm|cmov|cx8|fpu|fxsr|mmx|syscall|sse2|cx16|lahf|popcnt|sse4_1|sse4_2|ssse3|avx|avx2|bmi1|bmi2|f16c|fma|abm|movbe|xsave|avx512f|avx512bw|avx512cd|avx512dq|avx512vl' /proc/cpuinfo | sort -u | tr '\n' ' ')
echo "Detected CPU flags: $cpu_flags"

# Function to check if all required flags are present
has_flags() {
    local flags="$1"
    for flag in $flags; do
        [[ "$cpu_flags" =~ $flag ]] || return 1
    done
    return 0
}

# Determine the CPU level based on flags
if has_flags "avx512f avx512bw avx512cd avx512dq avx512vl"; then
    level=4
elif has_flags "avx avx2 bmi1 bmi2 f16c fma abm movbe xsave"; then
    level=3
elif has_flags "cx16 lahf popcnt sse4_1 sse4_2 ssse3"; then
    level=2
elif has_flags "lm cmov cx8 fpu fxsr mmx syscall sse2"; then
    level=1
else
    error "Unable to determine the appropriate XanMod kernel version based on CPU instruction set."
fi

echo "Detected CPU level: $level"

# Set the kernel package name based on the CPU level
case "$level" in
    1)
        kernel_package="linux-xanmod-lts-x64v1"
        ;;
    2)
        kernel_package="linux-xanmod-lts-x64v2"
        ;;
    3)
        kernel_package="linux-xanmod-lts-x64v3"
        ;;
    4)
        kernel_package="linux-xanmod-lts-x64v4"
        ;;
    *)
        error "Invalid CPU level: $level"
        ;;
esac

# Install the appropriate XanMod kernel
echo "Installing $kernel_package..."
apt install "$kernel_package" -y || error "Failed to install $kernel_package."

# Prompt for system reboot
echo "The system will reboot in 10 seconds. Press Ctrl+C to cancel."
for i in {10..1}; do
    echo "$i..."
    sleep 1
done
echo "Rebooting now!"
reboot
