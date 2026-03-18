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
    echo "配置文件大小: $(wc -l < .config) 行"
    
    # 显示关键配置项
    echo "关键配置项检查:"
    echo "目标架构:"
    grep "^CONFIG_TARGET_" .config | head -5
    
    echo "已启用的应用:"
    grep "^CONFIG_PACKAGE_luci-app.*=y" .config | wc -l | xargs echo "  LuCI应用数量:"
    
    echo "已启用的主题:"
    grep "^CONFIG_PACKAGE_luci-theme.*=y" .config | wc -l | xargs echo "  LuCI主题数量:"
    
else
    echo "✗ 警告: 配置文件不存在"
    echo "创建基础配置..."
    make defconfig
fi

# ===== 检查自定义设置应用状态 =====
echo "检查自定义设置应用状态..."

if [ -d "package/emortal/default-settings" ]; then
    cd package/emortal/default-settings
    
    echo "检查Makefile修改:"
    if grep -q "my-default-settings" Makefile 2>/dev/null; then
        echo "✓ Makefile包含自定义设置包"
        grep -A3 -B1 "my-default-settings" Makefile
    else
        echo "ℹ Makefile未包含自定义设置包"
    fi
    
    echo "检查自定义设置文件:"
    if [ -f "files/99-my-default-settings" ]; then
        echo "✓ 自定义设置文件存在"
        echo "文件大小: $(wc -l < files/99-my-default-settings) 行"
        echo "文件权限: $(ls -l files/99-my-default-settings | awk '{print $1}')"
        
        echo "自定义设置内容预览:"
        echo "----------------------------------------"
        head -20 files/99-my-default-settings
        echo "----------------------------------------"
    else
        echo "ℹ 自定义设置文件不存在"
    fi
    
    echo "检查默认设置文件:"
    if [ -f "files/99-default-settings" ]; then
        echo "✓ 默认设置文件存在"
        echo "默认设置文件内容预览:"
        echo "----------------------------------------"
        head -10 files/99-default-settings
        echo "----------------------------------------"
    else
        echo "ℹ 默认设置文件不存在"
    fi
    
    cd - >/dev/null
else
    echo "✗ default-settings目录不存在"
fi

# ===== 最终配置调整 =====
echo "最终配置调整..."

# 确保关键配置启用
echo "检查和调整关键配置..."

# 确保Web界面启用
if ! grep -q "CONFIG_PACKAGE_luci=y" .config; then
    echo "CONFIG_PACKAGE_luci=y" >> .config
    echo "✓ 启用LuCI Web界面"
fi

# 确保中文语言包启用
if ! grep -q "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" .config; then
    echo "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" >> .config
    echo "✓ 启用中文语言包"
fi

# 确保基础主题启用
if ! grep -q "CONFIG_PACKAGE_luci-theme-" .config; then
    echo "CONFIG_PACKAGE_luci-theme-bootstrap=y" >> .config
    echo "✓ 启用基础主题"
fi

# 如果自定义设置包存在，确保其启用
if [ -f "package/emortal/default-settings/Makefile" ] && grep -q "my-default-settings" package/emortal/default-settings/Makefile; then
    if ! grep -q "CONFIG_PACKAGE_my-default-settings=y" .config; then
        echo "CONFIG_PACKAGE_my-default-settings=y" >> .config
        echo "✓ 启用自定义默认设置包"
    fi
fi

# ===== 应用配置更改 =====
echo "应用配置更改..."
make defconfig

# ===== Rust编译配置 =====
echo "配置Rust编译环境..."

# 设置环境变量以禁用CI LLVM下载
export RUSTFLAGS="-C target-feature=+crt-static"
export BOOTSTRAP_DOWNLOAD_CI_LLVM=false
export BOOTSTRAP_ON_FAIL=1

# 预创建bootstrap.toml文件供Rust使用
# Rust构建时会查找此文件的配置
mkdir -p build_dir/target-aarch64_generic_musl/host
cat > build_dir/target-aarch64_generic_musl/host/bootstrap.toml << 'BOOTSTRAP_EOF'
[llvm]
download-ci-llvm = false
change-id = "ignore"
BOOTSTRAP_EOF

echo "✓ Rust编译环境已配置"
echo "  - RUSTFLAGS=$RUSTFLAGS"
echo "  - BOOTSTRAP_DOWNLOAD_CI_LLVM=$BOOTSTRAP_DOWNLOAD_CI_LLVM"
echo "  - BOOTSTRAP_ON_FAIL=$BOOTSTRAP_ON_FAIL"
echo "  - bootstrap.toml已创建"

# ===== 显示最终配置统计 =====
echo "最终配置统计:"
echo "总配置项: $(wc -l < .config)"
echo "启用的包: $(grep -c "=y$" .config)"
echo "禁用的包: $(grep -c "is not set$" .config)"

echo "关键软件包状态:"
echo "----------------------------------------"
echo "LuCI核心: $(grep "CONFIG_PACKAGE_luci=" .config || echo "未配置")"
echo "中文支持: $(grep "CONFIG_PACKAGE_luci-i18n.*zh-cn=y" .config | wc -l) 个语言包"
echo "主题数量: $(grep "CONFIG_PACKAGE_luci-theme.*=y" .config | wc -l) 个主题"
echo "应用数量: $(grep "CONFIG_PACKAGE_luci-app.*=y" .config | wc -l) 个应用"

# 检查自定义设置
if grep -q "CONFIG_PACKAGE_my-default-settings=y" .config; then
    echo "自定义设置: ✓ 已启用"
elif grep -q "CONFIG_PACKAGE_default-settings=y" .config; then
    echo "自定义设置: ℹ 使用默认设置"
else
    echo "自定义设置: ✗ 未找到设置包"
fi
echo "----------------------------------------"

# ===== 预编译检查 =====
echo "预编译环境检查..."

echo "磁盘空间检查:"
df -h . | tail -1

echo "内存使用情况:"
free -h

echo "可用CPU核心: $(nproc)"

# 检查必要的编译工具
echo "编译工具检查:"
TOOLS_CHECK=("make" "gcc" "g++" "git" "python3" "wget" "unzip")
for tool in "${TOOLS_CHECK[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool (缺失)"
    fi
done

# ===== 创建编译信息文件 =====
echo "创建编译信息文件..."

cat > build_info.txt << EOF
ImmortalWrt编译信息
==================
编译时间: $(date)
编译主机: $(hostname)
系统信息: $(uname -a)
编译用户: $(whoami)
工作目录: $(pwd)

源码信息:
分支: $REPO_BRANCH
提交: $(git rev-parse HEAD 2>/dev/null || echo "未知")

配置统计:
总配置项: $(wc -l < .config)
启用包数: $(grep -c "=y$" .config)
禁用包数: $(grep -c "is not set$" .config)

自定义功能:
- 中文界面支持
- 自定义IP地址: 192.168.10.1
- 自定义WiFi配置
- 优化的时区设置
- 预设管理密码

系统资源:
CPU核心: $(nproc)
内存: $(free -h | grep Mem | awk '{print $2}')
磁盘: $(df -h . | tail -1 | awk '{print $4}') 可用

编译环境: 就绪
==================
EOF

echo "编译信息已保存到: build_info.txt"

# ===== 最终验证 =====
echo "最终验证..."

# 验证关键文件存在
REQUIRED_FILES=("Makefile" ".config" "feeds.conf.default")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file 存在"
    else
        echo "✗ $file 缺失"
    fi
done

# 验证关键目录存在
REQUIRED_DIRS=("package" "target" "toolchain" "tools")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✓ $dir/ 目录存在"
    else
        echo "✗ $dir/ 目录缺失"
    fi
done

# ===== 记录脚本执行信息 =====
SCRIPT2_LOG="build_script2.log"
cat > "$SCRIPT2_LOG" << EOF
ImmortalWrt编译脚本2执行记录
============================
执行时间: $(date)
工作目录: $(pwd)

执行的操作:
- 验证配置文件
- 检查自定义设置
- 调整最终配置
- 环境预检查
- 创建编译信息

配置统计:
- 总配置项: $(wc -l < .config)
- 启用包数: $(grep -c "=y$" .config)
- 自定义设置: $(grep "my-default-settings" .config >/dev/null && echo "已启用" || echo "未启用")

脚本状态: 执行完成
============================
EOF

echo "脚本2执行日志已保存到: $SCRIPT2_LOG"

echo "=== ImmortalWrt编译前自定义脚本2执行完成 ==="
echo "系统准备就绪，可以开始编译！"
echo ""

exit 0