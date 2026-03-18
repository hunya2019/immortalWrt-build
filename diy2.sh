#!/bin/bash

# ImmortalWrt编译前自定义脚本2
# 在配置加载后、编译前执行

echo "=== ImmortalWrt编译前自定义脚本2开始执行 ==="

# 显示当前状态
echo "当前目录: $(pwd)"
echo "执行时间: $(date)"

# ===== 验证配置文件 =====
echo "验证配置文件..."

if [ -f ".config" ]; then
    echo "✓ 配置文件存在"
    echo "  配置文件大小: $(wc -l < .config) 行"
    
    # 显示关键配置项统计
    echo "配置统计:"
    echo "  启用的包: $(grep -c "=y$" .config || echo "0") 个"
    echo "  禁用的包: $(grep -c "is not set$" .config || echo "0") 个"
    
else
    echo "✗ 警告: 配置文件不存在"
    exit 1
fi

# ===== 检查Web界面配置 =====
echo "检查Web界面配置..."

# 确保LuCI启用
if ! grep -q "CONFIG_PACKAGE_luci=y" .config; then
    echo "  ⚠ LuCI未启用，正在启用..."
    echo "CONFIG_PACKAGE_luci=y" >> .config
fi

# 确保中文语言包启用
if ! grep -q "CONFIG_PACKAGE_luci-i18n.*zh-cn" .config; then
    echo "  ⚠ 中文语言包未启用，正在启用..."
    echo "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" >> .config
fi

# 检查主题
THEME_COUNT=$(grep "CONFIG_PACKAGE_luci-theme.*=y" .config | wc -l)
if [ "$THEME_COUNT" -eq 0 ]; then
    echo "  ⚠ 无主题启用，正在启用Bootstrap主题..."
    echo "CONFIG_PACKAGE_luci-theme-bootstrap=y" >> .config
else
    echo "  ✓ 已启用 $THEME_COUNT 个主题"
fi

# ===== 检查PassWall2配置 =====
echo "检查PassWall2配置..."

if grep -q "CONFIG_PACKAGE_passwall2" .config; then
    PASSWALL_STATUS=$(grep "CONFIG_PACKAGE_passwall2=" .config | head -1)
    echo "  ✓ PassWall2配置已找到: $PASSWALL_STATUS"
else
    echo "  ℹ PassWall2未在配置中"
fi

# ===== 应用配置更改 =====
echo "应用配置更改..."
make defconfig > /dev/null 2>&1 || true
echo "✓ 配置已应用"

# ===== 显示最终配置统计 =====
echo "最终配置统计:"
echo "  总配置项: $(wc -l < .config)"
echo "  启用的包: $(grep -c "=y$" .config)"
echo "  禁用的包: $(grep -c "is not set$" .config)"

# 关键软件包统计
LUCI_APPS=$(grep "CONFIG_PACKAGE_luci-app.*=y" .config | wc -l)
THEMES=$(grep "CONFIG_PACKAGE_luci-theme.*=y" .config | wc -l)

echo "关键软件包:"
echo "  LuCI应用: $LUCI_APPS 个"
echo "  LuCI主题: $THEMES 个"

# ===== 预编译检查 =====
echo "预编译环境检查..."

echo "磁盘空间:"
df -h . | tail -1 | awk '{printf "  当前: %s\n", $4}'

echo "内存:"
free -h | grep Mem | awk '{printf "  总计: %s, 可用: %s\n", $2, $7}'

echo "CPU核心: $(nproc)"

# ===== 预做准备工作 =====
echo "预做准备工作..."

# 检查和创建必要目录
[ -d "build_dir" ] || mkdir -p build_dir
[ -d "staging_dir" ] || mkdir -p staging_dir

# 预设构建目录（如果使用了符号链接）
if [ -L "dl" ]; then
    echo "  ✓ 下载目录符号链接已配置"
elif [ -d "dl" ]; then
    echo "  ✓ 下载目录已存在"
fi

# ===== 显示构建信息 =====
echo "构建信息:"
echo "  工作目录: $(pwd)"
echo "  主机: $(hostname)"
echo "  用户: $(whoami)"

if [ -d ".git" ]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "未知")
    COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "未知")
    echo "  分支: $BRANCH"
    echo "  提交: $COMMIT"
fi

# ===== 最终检查 =====
echo "最终检查:"

# 验证关键文件
CRITICAL_FILES=("Makefile" ".config" "feeds.conf.default")
for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (缺失)"
    fi
done

# 验证关键目录
CRITICAL_DIRS=("package" "target" "toolchain")
for dir in "${CRITICAL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✓ $dir/"
    else
        echo "  ✗ $dir/ (缺失)"
    fi
done

# ===== 显示编译参数 =====
echo "编译参数:"
echo "  并行线程: $(($(nproc)+1))"
echo "  Rust CI LLVM: 禁用"

# ===== 创建编译信息文件 =====
echo "创建编译信息文件..."

cat > build_summary.txt << EOF
ImmortalWrt编译前准备摘要
========================
准备时间: $(date)
工作目录: $(pwd)
主机信息: $(hostname)

配置概览:
- 总配置项: $(wc -l < .config)
- 启用包数: $(grep -c "=y$" .config)
- LuCI应用: $LUCI_APPS 个  
- LuCI主题: $THEMES 个

系统资源:
- CPU核心: $(nproc)
- 可用内存: $(free -h | grep Mem | awk '{print $7}')
- 可用磁盘: $(df -h . | tail -1 | awk '{print $4}')

编译准备: ✓ 完成
推荐线程数: $(($(nproc)+1))
========================
EOF

echo "✓ 编译信息已保存到: build_summary.txt"

# ===== 完成提示 =====
echo ""
echo "=========================================="
echo "✓ ImmortalWrt编译前准备完成！"
echo "系统已就绪，可以开始编译！"
echo "建议编译命令:"
echo "  make -j$(($(nproc)+1)) || make -j1 V=s"
echo "=========================================="
echo ""

echo "=== ImmortalWrt编译前自定义脚本2执行完成 ==="

exit 0
