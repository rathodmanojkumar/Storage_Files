#!/bin/bash

# ================================
# Printer Fix Script
# Removes ipp-usb, stops & disables cups-browsed,
# restarts CUPS and prints status
# ================================

LOGFILE="/var/log/printer_fix.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S')  $1" | tee -a "$LOGFILE"
}

log "=== Starting Printer Fix Script ==="

# Step 1: Remove ipp-usb
log "Removing ipp-usb package..."
sudo apt purge ipp-usb -y >> "$LOGFILE" 2>&1
log "ipp-usb removed."

# Step 2: Stop cups-browsed service
log "Stopping cups-browsed.service..."
sudo systemctl stop cups-browsed.service >> "$LOGFILE" 2>&1
log "cups-browsed stopped."

# Step 3: Disable cups-browsed service
log "Disabling cups-browsed.service..."
sudo systemctl disable cups-browsed.service >> "$LOGFILE" 2>&1
log "cups-browsed disabled."

# Step 4: Restart CUPS service
log "Restarting CUPS service..."
sudo systemctl restart cups >> "$LOGFILE" 2>&1
log "CUPS restarted."

# Step 5: Show service status
log "Checking service status..."
systemctl status cups --no-pager | tee -a "$LOGFILE"

log "=== Script Completed Successfully ==="
echo ""
echo "✔ Printer fix completed."
echo "✔ Log saved at: $LOGFILE"

