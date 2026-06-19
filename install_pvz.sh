#!/bin/bash
# 植物大战僵尸杂交版源码环境一键安装脚本
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT_ZIP="$SCRIPT_DIR/Godot_v4.6-stable_macos.universal.zip"
SOURCE_DIR="$SCRIPT_DIR/PVZ工程/pvz_full_source"

echo "=============================="
echo " PVZ 杂交版源码环境 安装脚本"
echo "=============================="

# 1. 安装 Godot
if [ -d "/Applications/Godot.app" ]; then
    echo "[✓] Godot 已安装，跳过"
else
    if [ ! -f "$GODOT_ZIP" ]; then
        echo "[✗] 找不到 $GODOT_ZIP"
        echo "    请把 Godot_v4.6-stable_macos.universal.zip 放在脚本同目录"
        exit 1
    fi
    echo "[→] 安装 Godot 4.6..."
    unzip -q "$GODOT_ZIP" -d /tmp/godot_install
    cp -r /tmp/godot_install/Godot.app /Applications/
    xattr -dr com.apple.quarantine /Applications/Godot.app
    rm -rf /tmp/godot_install
    echo "[✓] Godot 安装完成"
fi

# 2. 复制源码到桌面
DEST="$HOME/Desktop/PVZ工程/pvz_full_source"
if [ -d "$DEST" ]; then
    echo "[✓] 源码已存在于桌面，跳过"
else
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "[✗] 找不到 PVZ工程/pvz_full_source 目录"
        echo "    请把 PVZ工程/pvz_full_source 文件夹放在脚本同目录"
        exit 1
    fi
    echo "[→] 复制源码到桌面（约 1.1GB，请稍候...）"
    cp -r "$SOURCE_DIR" "$DEST"
    echo "[✓] 源码复制完成"
fi

# 3. 创建快捷方式
SHORTCUT="$HOME/Desktop/打开PVZ源码.command"
cat > "$SHORTCUT" << 'EOF'
#!/bin/bash
open -a "/Applications/Godot.app" --args --path "$HOME/Desktop/PVZ工程/pvz_full_source"
EOF
chmod +x "$SHORTCUT"
echo "[✓] 桌面快捷方式已创建"

echo ""
echo "=============================="
echo " 安装完成！"
echo " 双击桌面「打开PVZ源码.command」即可打开"
echo "=============================="
