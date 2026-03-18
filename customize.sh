#!/bin/bash
# Custom OpenWrt build script
# This script will be executed automatically during build

# Enable this script
set -e

# Enter OpenWrt directory
cd openwrt || exit 1

# Example: Remove unwanted packages from feeds
# rm -rf feeds/smpackage/{unwanted_package}

# Example: Clone additional packages
# git clone https://github.com/your-user/your-package.git package/your-package

# Example: Modify default settings
# sed -i 's/old_value/new_value/g' feeds/luci/collections/luci/Makefile

# Example: Add custom banner
# echo "Your Custom Banner" > package/base-files/files/etc/banner

echo "Customize script completed!"
