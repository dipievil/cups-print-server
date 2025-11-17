#!/bin/bash
set -e

echo "================================================"
echo "CUPS Print Server - Starting"
echo "================================================"

# Setup CUPS admin user with password from environment variable
CUPS_USER="${CUPSADMIN:-admin}"
CUPS_PASS="${CUPSPASSWORD:-admin}"

echo "Setting up CUPS admin user: $CUPS_USER"
echo "$CUPS_USER:$CUPS_PASS" | chpasswd
usermod -aG lpadmin "$CUPS_USER" 2>/dev/null || true
echo "✓ CUPS admin user configured"

# Optional: Install Brother printer driver
if [ "${INSTALL_BROTHER_DRIVER}" = "true" ] && [ -f /usr/local/bin/install-brother-printer.sh ]; then
    echo "Brother driver installation requested..."
    bash /usr/local/bin/install-brother-printer.sh || echo "⚠ Brother driver installation failed"
fi

# Optional: Install HP printer driver (future support)
if [ "${INSTALL_HP_DRIVER}" = "true" ] && [ -f /usr/local/bin/install-hp-printer.sh ]; then
    echo "HP driver installation requested..."
    bash /usr/local/bin/install-hp-printer.sh || echo "⚠ HP driver installation failed"
fi

echo "================================================"
echo "Starting CUPS daemon..."
echo "================================================"

# Start cupsd in foreground
exec cupsd -f &
CUPSD_PID=$!

# Run validation script after CUPS starts
if [ -f /docker-entrypoint.d/validate-start.sh ]; then
    bash /docker-entrypoint.d/validate-start.sh &
fi

# Keep container alive
wait $CUPSD_PID
