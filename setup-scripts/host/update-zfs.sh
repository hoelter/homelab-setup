#!/bin/bash

# Reinstall headers
sudo apt install linux-headers-$(uname -r)
# Check Status
sudo dkms status
# Build newer version
sudo dkms build zfs/2.3.2 -k $(uname -r)
# Install newer version
sudo dkms install zfs/2.3.2 -k $(uname -r)
# Verify it's working
sudo modprobe zfs
