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
    head -10 feeds.conf.default
    
    # 备份原始配置
    cp feeds.conf.default feeds.conf.default.bak
    echo "✓ Feeds配置已备份"
    
    # 添加自定义feeds源（避免重复）
    if ! grep -q "smpackage" feeds.conf.default; then
        echo "src-git smpackage https://github.com/kenzok8/small-package.git" >> feeds.conf.default
        echo "✓ 已添加 smpackage 源"
    fi
    
    if ! grep -q "openwrt_packages" feeds.conf.default; then
        echo "src-git openwrt_packages https://github.com/kenzok8/openwrt-packages.git" >> feeds.conf.default
        echo "✓ 已添加 openwrt_packages 源"
    fi
else
    echo "警告: feeds.conf.default文件不存在"
fi

# ===== 修改版本信息 =====
echo "修改版本信息..."

# 查找版本文件
VERSION_FILE=""
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    VERSION_FILE="package/lean/default-settings/files/zzz-default-settings"
    echo "✓ 找到Lean版本设置文件"
elif [ -f "package/emortal/default-settings/files/zzz-default-settings" ]; then
    VERSION_FILE="package/emortal/default-settings/files/zzz-default-settings"
    echo "✓ 找到eMortal版本设置文件"
elif [ -f "package/base-files/files/etc/banner" ]; then
    VERSION_FILE="package/base-files/files/etc/banner"
    echo "✓ 找到base-files banner文件"
fi

if [ -n "$VERSION_FILE" ] && [ -f "$VERSION_FILE" ]; then
    echo "版本文件: $VERSION_FILE"
fi

# ===== 添加自定义软件包 =====
echo "检查是否需要添加自定义软件包..."

# 定义克隆函数，支持重试
clone_repo() {
    local repo_url=$1
    local target_path=$2
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if [ -d "$target_path" ]; then
            echo "  ✓ $target_path 已存在"
            return 0
        fi
        
        echo "  尝试克隆 ($attempt/$max_attempts): $repo_url"
        if git clone --depth 1 "$repo_url" "$target_path" 2>/dev/null; then
            echo "  ✓ 成功克隆: $target_path"
            return 0
        else
            echo "  ✗ 克隆失败 (尝试 $attempt/$max_attempts)"
            attempt=$((attempt + 1))
            if [ $attempt -le $max_attempts ]; then
                sleep 5
            fi
        fi
    done
    
    echo "  ⚠️ 克隆失败: $target_path"
    return 1
}

# 克隆PassWall2 - 代理工具
clone_repo "https://github.com/xiaorouji/openwrt-passwall2.git" "package/passwall2"

# 添加 iStore - 应用商店
clone_repo "https://github.com/linkease/istore.git" "package/istore"

# 添加 AdGuardHome 插件
clone_repo "https://github.com/rufengsuixing/luci-app-adguardhome.git" "package/luci-app-adguardhome"

echo "✓ 自定义软件包检查完成"

# ===== 清理可能的冲突 =====
echo "清理可能的编译冲突..."

rm -rf tmp/ 2>/dev/null || true
rm -rf .config.old 2>/dev/null || true
echo "✓ 临时文件已清理"

# ===== 检查必要的工具 =====
echo "检查编译必要工具..."

REQUIRED_TOOLS=("git" "gcc" "make" "python3" "wget")
MISSING_TOOLS=""
for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool: 未找到"
        MISSING_TOOLS="$MISSING_TOOLS $tool"
    fi
done

if [ -n "$MISSING_TOOLS" ]; then
    echo "警告: 缺少必要工具:$MISSING_TOOLS"
fi

# ===== 设置编译环境变量 =====
echo "设置编译环境变量..."

export FORCE_UNSAFE_CONFIGURE=1
export BOOTSTRAP_DOWNLOAD_CI_LLVM=false
export BOOTSTRAP_ON_FAIL=1

echo "✓ 环境变量已设置"

# ===== 显示系统资源信息 =====
echo "系统资源信息:"
echo "  CPU核心数: $(nproc)"
echo "  内存总量: $(free -h | grep Mem | awk '{print $2}')"
echo "  可用磁盘: $(df -h . | tail -1 | awk '{print $4}')"

# ===== 创建自定义目录结构 =====
echo "创建自定义目录结构..."

mkdir -p files/etc/config 2>/dev/null || true
mkdir -p files/etc/init.d 2>/dev/null || true
mkdir -p files/usr/bin 2>/dev/null || true

echo "✓ 目录结构已创建"

# ===== 显示编译准备完成 =====
echo "==================="
echo "✓ 源码准备完成！"
echo "系统时间: $(date)"
echo "当前工作目录: $(pwd)"
if [ -d ".git" ]; then
    echo "Git分支: $(git branch --show-current 2>/dev/null || echo '未知')"
    echo "Git提交: $(git rev-parse --short HEAD 2>/dev/null || echo '未知')"
fi
echo "可用CPU核心: $(nproc)"
echo "==================="

echo "=== ImmortalWrt编译前自定义脚本1执行完成 ==="
echo ""

exit 0
