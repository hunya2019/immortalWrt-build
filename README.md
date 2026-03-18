# immortalWrt-build

This repository contains a GitHub Actions workflow to build OpenWrt (inspired by https://github.com/kenzok8/openwrt_Build).

## Usage

1. Push to `main` or run the workflow manually via **Actions → OpenWrt Build → Run workflow**.
2. (Optional) Provide a custom OpenWrt config by adding a `.config` file to the repo and setting the `config_path` input.

The built firmware artifacts will be available as workflow artifacts under `openwrt/bin`.
