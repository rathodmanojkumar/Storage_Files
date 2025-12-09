#!/bin/bash

# Automated CUPS config reset + backup + restart

BACKUP="/etc/cups/cupsd.conf.backup_$(date +%Y%m%d_%H%M%S)"
DEFAULT="/usr/share/cups/cupsd.conf.default"
TARGET="/etc/cups/cupsd.conf"

echo "Backing up current CUPS config to: $BACKUP"
sudo cp $TARGET $BACKUP

echo "Restoring default CUPS configuration..."
sudo cp $DEFAULT $TARGET

echo "Restarting CUPS service..."
sudo service cups restart

echo "Checking CUPS status..."
sudo service cups status

echo ""
echo "✔ Default CUPS configuration restored."
echo "✔ Backup saved at: $BACKUP"
echo "If printing still fails, share the error messages here."

