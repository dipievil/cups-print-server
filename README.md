# CUPS Print Server Docker Image

🖨️ A flexible, self-hosted CUPS print server with optional printer driver support for containerized printing solutions.

[![Docker Pulls](https://img.shields.io/docker/pulls/dipi/cups-server)](https://hub.docker.com/r/dipi/cups-server)
[![Docker Image Size](https://img.shields.io/docker/image-size/dipi/cups-server/latest)](https://hub.docker.com/r/dipi/cups-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🚀 **Quick Setup** - Run a CUPS server in seconds
- 🔌 **USB Support** - Direct USB printer connection
- 🌐 **Network Printing** - Share printers across your LAN
- 🔧 **Modular Design** - Base image + optional printer drivers
- 🖨️ **Brother Support** - Pre-built Brother printer drivers
- 📊 **Monitoring** - Built-in validation and health checks
- 🐳 **Docker Native** - Lightweight and portable

## 🚀 Quick Start

### Basic Usage

```bash
docker run -d \
  --name cups-server \
  -p 631:631 \
  --device /dev/bus/usb:/dev/bus/usb \
  --privileged \
  -e CUPSADMIN=admin \
  -e CUPSPASSWORD=yourpassword \
  dipi/cups-server:latest
```

Access CUPS web interface at `http://localhost:631`

### With Docker Compose

```yaml
version: '3.8'
services:
  cups:
    image: dipi/cups-server:latest
    ports:
      - "631:631"
    devices:
      - /dev/bus/usb:/dev/bus/usb
    privileged: true
    environment:
      - CUPSADMIN=admin
      - CUPSPASSWORD=changeme
    volumes:
      - cups_data:/etc/cups

volumes:
  cups_data:
```

## 🏷️ Image Variants

| Tag | Description | Size |
|-----|-------------|------|
| `latest` | Base CUPS server (no specific drivers) | ~300MB |
| `brother` | Pre-installed Brother printer drivers | ~350MB |

## 🔧 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CUPSADMIN` | `admin` | Admin username for CUPS web interface |
| `CUPSPASSWORD` | `admin` | Admin password (change in production!) |
| `INSTALL_BROTHER_DRIVER` | `false` | Install Brother driver at runtime |
| `BROTHER_PRINTER_MODEL` | `HL-1210W` | Brother printer model to install |
| `TZ` | `UTC` | Container timezone |
| `SKIP_USB_CHECK` | `false` | Skip USB device validation |

## 🖨️ Brother Printer Support

### Option 1: Pre-built Image (Recommended)

```bash
docker run -d \
  -p 631:631 \
  --device /dev/bus/usb:/dev/bus/usb \
  --privileged \
  dipi/cups-server:brother
```

### Option 2: Runtime Installation

```bash
docker run -d \
  -p 631:631 \
  --device /dev/bus/usb:/dev/bus/usb \
  --privileged \
  -e INSTALL_BROTHER_DRIVER=true \
  -e BROTHER_PRINTER_MODEL=HL-1212W \
  dipi/cups-server:latest
```

### Supported Brother Models

The installer supports most Brother printer models. Common models include:
- HL-1210W, HL-1212W
- HL-2270DW, HL-2280DW
- DCP-L2540DW, DCP-L2550DW
- MFC-L2700DW, MFC-L2720DW

Check [Brother's Linux support page](https://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=hll2300d_us_eu_as&os=127) for your specific model.

## 🔐 USB Device Permissions

For USB printers to work, you need to configure udev rules on the **host machine**.

### Brother Printers

```bash
# Create udev rule
cat > /etc/udev/rules.d/99-brother-printer.rules << 'EOF'
# Brother printers - allow CUPS access
SUBSYSTEM=="usb", ATTR{idVendor}=="04f9", MODE="0666", GROUP="lp"
EOF

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

# Reconnect printer
```

### Generic USB Printers

```bash
# Allow all USB printers
cat > /etc/udev/rules.d/99-usb-printers.rules << 'EOF'
SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", MODE="0666"
EOF

udevadm control --reload-rules
udevadm trigger
```

## 📖 Usage Examples

### Network Printing

```bash
docker run -d \
  --name cups-server \
  --network host \
  -e CUPSADMIN=admin \
  -e CUPSPASSWORD=secure123 \
  dipi/cups-server:latest
```

### Persistent Configuration

```bash
docker run -d \
  --name cups-server \
  -p 631:631 \
  --device /dev/bus/usb:/dev/bus/usb \
  --privileged \
  -v cups_config:/etc/cups \
  -v cups_spool:/var/spool/cups \
  dipi/cups-server:latest
```

### Custom CUPS Configuration

```bash
docker run -d \
  --name cups-server \
  -p 631:631 \
  -v $(pwd)/cupsd.conf:/etc/cups/cupsd.conf:ro \
  dipi/cups-server:latest
```

## 🏗️ Building from Source

```bash
# Clone repository
git clone https://github.com/dipievil/cups-print-server.git
cd cups-print-server

# Build base image
docker build -t cups-server:latest --target cups-server .

# Build Brother variant
docker build -t cups-server:brother --target cups-server-brother .

# Test
docker run -d -p 631:631 cups-server:latest
```

## 🩺 Health Checks

The container includes built-in health checks:

```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' cups-server

# View validation logs
docker logs cups-server | grep "Validation Summary"
```

## 🐛 Troubleshooting

### Printer Not Detected

1. **Check USB permissions:**
   ```bash
   ls -la /dev/bus/usb/*/*
   # Should show rw-rw-rw- permissions
   ```

2. **Verify USB passthrough:**
   ```bash
   docker exec cups-server lsusb
   # Should list your printer
   ```

3. **Check CUPS backends:**
   ```bash
   docker exec cups-server lpinfo -v
   # Should show usb:// devices
   ```

### Cannot Access Web Interface

1. **Check if CUPS is running:**
   ```bash
   docker exec cups-server pgrep cupsd
   ```

2. **Verify port binding:**
   ```bash
   docker port cups-server
   # Should show 631/tcp -> 0.0.0.0:631
   ```

3. **Test connection:**
   ```bash
   curl -I http://localhost:631
   ```

### Driver Installation Failed

```bash
# Check logs
docker logs cups-server | grep "Brother"

# Manual installation
docker exec -it cups-server bash
bash /usr/local/bin/install-brother-printer.sh
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Based on Debian Bookworm
- Uses [CUPS](https://www.cups.org/) - Common UNIX Printing System
- Brother driver installer from [Brother Solutions](https://support.brother.com/)

## 📞 Support

- 🐛 [Report Issues](https://github.com/dipievil/cups-print-server/issues)
- 💬 [Discussions](https://github.com/dipievil/cups-print-server/discussions)
- 📧 Email: your.email@example.com

## 🔗 Links

- [Docker Hub](https://hub.docker.com/r/dipi/cups-server)
- [GitHub Repository](https://github.com/dipievil/cups-print-server)
- [Documentation](https://github.com/dipievil/cups-print-server/wiki)

---

Made with ❤️ by [dipievil](https://github.com/dipievil)
