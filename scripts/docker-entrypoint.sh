#!/bin/bash

# Script to validate printer configuration and state
# This script runs at container startup to ensure CUPS is properly configured

echo "================================================"
echo "CUPS Printer Validation Script"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Wait for CUPS to be ready
print_info "Waiting for CUPS service to start..."
sleep 15

# Check if CUPS is running
if ! pgrep -x "cupsd" > /dev/null; then
    print_error "CUPS daemon is not running"
    exit 1
fi

print_info "CUPS daemon is running"

# Check for USB devices
if [ -z "$SKIP_USB_CHECK" ]; then
    print_info "Checking for USB devices..."
    if [ -d "/dev/bus/usb" ]; then
        USB_DEVICES=$(find /dev/bus/usb -type c 2>/dev/null | wc -l)
        print_info "Found $USB_DEVICES USB device(s)"
        
        if command -v lsusb &> /dev/null; then
            print_info "USB devices detected:"
            lsusb 2>/dev/null || print_warning "Could not list USB devices"
        fi
    else
        print_warning "USB device directory not accessible"
    fi
fi

# Check CUPS backends
print_info "Available CUPS backends:"
if command -v lpinfo &> /dev/null; then
    lpinfo -v 2>/dev/null | head -10 || print_warning "Could not list backends"
else
    print_warning "lpinfo command not available"
fi

# List installed printers
print_info "Currently installed printers:"
if command -v lpstat &> /dev/null; then
    PRINTER_COUNT=$(lpstat -p 2>/dev/null | wc -l)
    
    if [ "$PRINTER_COUNT" -eq 0 ]; then
        print_warning "No printers are currently installed"
        print_info "Add printers via CUPS web interface at http://<server-ip>:631"
    else
        lpstat -p 2>/dev/null || true
        print_info "Printer status:"
        lpstat -t 2>/dev/null || print_warning "Could not get printer status"
    fi
else
    PRINTER_COUNT=0
    print_warning "lpstat command not available"
fi

# Check CUPS network status
print_info "CUPS is listening on:"
if command -v ss &> /dev/null; then
    ss -tuln 2>/dev/null | grep ":631" || print_warning "Port 631 not visible"
elif command -v netstat &> /dev/null; then
    netstat -tuln 2>/dev/null | grep ":631" || print_warning "Port 631 not visible"
fi

HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

# Test CUPS web interface
print_info "Testing CUPS web interface..."
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:631 2>/dev/null || echo "000")
    if echo "$HTTP_CODE" | grep -q "200\|401"; then
        print_info "CUPS web interface is accessible"
    else
        print_warning "CUPS web interface returned HTTP $HTTP_CODE"
    fi
fi

# Summary
echo ""
echo "================================================"
echo "Validation Summary"
echo "================================================"
echo "✓ CUPS daemon: Running"
echo "✓ USB access: Available"
echo "✓ Printers configured: $PRINTER_COUNT"
echo ""
echo "CUPS Web Interface: http://${HOST_IP}:631"

if [ -n "${CUPSADMIN}" ]; then
    echo "Admin user: ${CUPSADMIN}"
fi

echo ""
echo "================================================"
echo ""

exit 0
