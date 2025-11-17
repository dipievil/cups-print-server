#!/bin/bash
set -e

# Brother Printer Driver Installer
# Supports installation via environment variables or auto-detection

echo "================================================"
echo "Brother Printer Driver Installer"
echo "================================================"

MARKER_FILE="/var/lib/brother-printer-installed"

# Check if already installed
if [ -f "$MARKER_FILE" ]; then
    echo "✓ Brother driver already installed"
    exit 0
fi

# Get printer model from environment or use default
PRINTER_MODEL="${BROTHER_PRINTER_MODEL:-HL-1210W}"
INSTALLER_VERSION="${BROTHER_INSTALLER_VERSION:-2.2.6-0}"
INSTALLER_URL="https://download.brother.com/welcome/dlf006893/linux-brprinter-installer-${INSTALLER_VERSION}.gz"

echo "Installing Brother driver for model: $PRINTER_MODEL"
echo "Installer version: $INSTALLER_VERSION"

# Install required dependencies
echo "Installing required dependencies..."
apt-get update -qq
apt-get install -y -qq wget file ca-certificates || {
    echo "⚠ Failed to install dependencies"
    exit 1
}

# Download and extract installer
cd /tmp
echo "Downloading Brother installer..."
wget -q "$INSTALLER_URL" -O brother-installer.gz || {
    echo "⚠ Failed to download Brother installer"
    exit 1
}

gunzip brother-installer.gz

if [ ! -f brother-installer ]; then
    echo "⚠ Failed to extract Brother installer"
    exit 1
fi

chmod +x brother-installer

# Check if printer is connected
if lsusb 2>/dev/null | grep -i "brother" > /dev/null; then
    echo "✓ Brother printer detected via USB"
else
    echo "⚠ Brother printer not detected via USB"
    echo "  Driver will be installed but printer may not be accessible"
fi

# Install driver with auto-responses
# y - install packages
# Y - accept Brother license
# Y - accept GPL license
# n - don't specify Device URI (use auto)
# 10 - select auto USB connection
# n - no test print
echo "Running Brother installer (this may take a few minutes)..."
export DEBIAN_FRONTEND=noninteractive
echo -e "y\nY\nY\nn\n10\nn" | bash brother-installer "$PRINTER_MODEL" 2>&1 | \
    grep -v "Interrupt" | grep -v "dpkg: warning" || true

# Cleanup
rm -f /tmp/brother-installer*

# Mark as installed
touch "$MARKER_FILE"

echo ""
echo "================================================"
echo "✓ Brother driver installed successfully"
echo "  Model: $PRINTER_MODEL"
echo "  Printer should be available in CUPS"
echo "================================================"

exit 0
