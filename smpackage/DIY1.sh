#!/bin/bash

# ImmortalWrt编译前自定义脚本1
# 在更新feeds之前执行

echo "=== ImmortalWrt编译前自定义脚本1开始执行 ==="

# 显示当前工作目录和基本信息
echo "当前目录: $(pwd)"
echo "系统信息: $(uname -a)"
echo "编译开始时间: $(date)"

# ===== 修改默认feeds源 =====
echo "检查和修改feeds配置..."

if [ -f "feeds.conf.default" ]; then
    echo "原始feeds.conf.default内容:"
    cat feeds.conf.default
    
    # 备份原始配置
    cp feeds.conf.default feeds.conf.default.bak
    
    # 可以在这里修改feeds源，例如添加自定义源
    # echo 'src-git custom https://github.com/your-username/your-packages.git' >> feeds.conf.default
    
    echo "修改后的feeds.conf.default内容:"
    cat feeds.conf.default
else
    echo "警告: feeds.conf.default文件不存在"
fi

# ===== 修改版本信息 =====
echo "修改版本信息..."

# 查找版本文件
VERSION_FILE=""
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    VERSION_FILE="package/lean/default-settings/files/zzz-default-settings"
elif [ -f "package/emortal/default-settings/files/zzz-default-settings" ]; then
    VERSION_FILE="package/emortal/default-settings/files/zzz-default-settings"
elif [ -f "package/base-files/files/etc/banner" ]; then
    VERSION_FILE="package/base-files/files/etc/banner"
fi

if [ -n "$VERSION_FILE" ] && [ -f "$VERSION_FILE" ]; then
    echo "找到版本文件: $VERSION_FILE"
    # 这里可以修改版本信息
    # sed -i 's/原始版本/自定义版本/g' "$VERSION_FILE"
else
    echo "未找到版本文件"
fi

# ===== 添加自定义软件包 =====
echo "检查是否需要添加自定义软件包..."

# 示例: 克隆额外的软件包
# git clone https://github.com/kenzok8/openwrt-packages.git package/custom-packages
git clone https://github.com/xiaorouji/openwrt-passwall2.git package/passwall2

# 添加 iStore
git clone https://github.com/linkease/istore package/istore

# 添加 nikki
git clone https://github.com/nikkinikki-org/OpenWrt-nikki.git package/OpenWrt-nikki

# 添加 momo
git clone https://github.com/nikkinikki-org/OpenWrt-momo.git package/OpenWrt-momo

# 添加 AdGuardHome 插件
git clone https://github.com/rufengsuixing/luci-app-adguardhome package/luci-app-adguardhome

# 删除 geoview（避免编译失败）
rm -rf package/passwall-packages/geoview

# ===== 修改目标架构配置 =====
echo "检查目标架构配置..."

# 显示可用的目标架构
if [ -d "target/linux" ]; then
    echo "可用的目标架构:"
    ls target/linux/
fi

# ===== 预处理配置文件 =====
echo "预处理配置..."

# 如果存在预设配置文件，可以在这里进行预处理
if [ -f "../config/immortalwrt.info" ]; then
    echo "发现预设配置文件"
    # 可以在这里对配置文件进行预处理
fi

# ===== 设置编译环境变量 =====
echo "设置编译环境变量..."

# 设置编译线程数
export FORCE_UNSAFE_CONFIGURE=1

# 设置编译优化选项
export MAKEFLAGS="-j$(nproc)"

# ===== 显示系统资源信息 =====
echo "显示系统资源信息..."
echo "CPU信息:"
nproc
echo "内存信息:"
free -h
echo "磁盘空间:"
df -h

# ===== 清理可能的冲突 =====
echo "清理可能的编译冲突..."

# 清理可能存在的临时文件
rm -rf tmp/ 2>/dev/null || true
rm -rf .config.old 2>/dev/null || true

# ===== 检查必要的工具 =====
echo "检查编译必要工具..."

REQUIRED_TOOLS=("git" "gcc" "make" "python3" "wget" "curl")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "✓ $tool: $(which $tool)"
    else
        echo "✗ $tool: 未找到"
    fi
done

# ===== 创建自定义目录结构 =====
echo "创建自定义目录结构..."

# 创建可能需要的目录
mkdir -p files/etc/config 2>/dev/null || true
mkdir -p files/etc/init.d 2>/dev/null || true
mkdir -p files/usr/bin 2>/dev/null || true

# ===== 下载额外资源 =====
echo "下载额外资源..."

# 示例: 下载自定义主题或插件
# wget -O package/custom-theme.tar.gz https://github.com/username/theme/archive/main.tar.gz
# tar -xzf package/custom-theme.tar.gz -C package/

# ===== 应用预设补丁 =====
echo "应用预设补丁..."

# 这里可以应用一些通用的补丁
# 例如修复已知问题或添加功能

# ===== 修复Rust编译问题 =====
echo "配置Rust编译环境..."

# 禁用CI LLVM下载（通常在GitHub Actions中不可用）
export BOOTSTRAP_DOWNLOAD_CI_LLVM=false
export BOOTSTRAP_ON_FAIL=1

echo "✓ Rust编译环境变量已配置"
echo "  - BOOTSTRAP_DOWNLOAD_CI_LLVM=false"
echo "  - BOOTSTRAP_ON_FAIL=1"

# ===== 显示编译准备完成 =====
echo "==================="
echo "源码准备完成！"
echo "系统时间: $(date)"
echo "当前工作目录: $(pwd)"
echo "Git分支: $(git branch --show-current 2>/dev/null || echo '未知')"
echo "Git提交: $(git rev-parse --short HEAD 2>/dev/null || echo '未知')"
echo "可用CPU核心: $(nproc)"
echo "可用磁盘: $(df -h . | tail -1)"
echo "==================="

echo "=== ImmortalWrt编译前自定义脚本1执行完成 ==="

exit 0
EOF

echo "脚本1执行日志已保存到: $SCRIPT1_LOG"

echo "=== ImmortalWrt编译前自定义脚本1执行完成 ==="
echo ""

exit 0
