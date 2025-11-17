FROM debian:bookworm-slim AS base

# Install CUPS core and diagnostic tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cups \
        cups-client \
        cups-bsd \
        cups-filters \
        printer-driver-all \
        libusb-1.0-0 \
        usbutils \
        curl \
        wget \
        ca-certificates \
        file \
        iproute2 && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create CUPS admin user
RUN useradd -r -G lpadmin -M admin

# Set correct permissions for USB backend
RUN chmod 700 /usr/lib/cups/backend/usb && \
    chown root:root /usr/lib/cups/backend/usb

# Copy base scripts
COPY scripts/start-cups.sh /usr/local/bin/
COPY scripts/docker-entrypoint.sh /docker-entrypoint.d/validate-start.sh
RUN chmod +x /usr/local/bin/start-cups.sh /docker-entrypoint.d/validate-start.sh

# Expose CUPS ports
EXPOSE 631

WORKDIR /etc/cups

# Base image without specific drivers
FROM base AS cups-server

CMD ["/usr/local/bin/start-cups.sh"]

# Brother variant with driver pre-installed
FROM base AS cups-server-brother

COPY scripts/install-brother-printer.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-brother-printer.sh

# Set environment to auto-install Brother driver
ENV INSTALL_BROTHER_DRIVER=true

CMD ["/usr/local/bin/start-cups.sh"]
