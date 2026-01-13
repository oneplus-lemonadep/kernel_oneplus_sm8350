#!/bin/bash

echo "=== SUSFS 补丁验证脚本 ==="
echo

files=(
    "fs/Makefile:obj-$(CONFIG_KSU_SUSFS) += susfs.o"
    "include/linux/sched.h:susfs_task_state"
    "include/linux/sched.h:susfs_last_fake_mnt_id"
    "include/linux/mount.h:susfs_mnt_id_backup"
    "kernel/kallsyms.c:CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS"
    "kernel/sys.c:susfs_spoof_uname"
    "fs/susfs.c:SUSFS_VERSION"
    "include/linux/susfs.h:SUSFS_VERSION"
    "include/linux/susfs_def.h:INODE_STATE_SUS_PATH"
)

echo "检查关键文件修改..."
echo

all_passed=true

for item in "${files[@]}"; do
    file="${item%%:*}"
    pattern="${item##*:}"
    
    if [ -f "$file" ]; then
        if grep -q "$pattern" "$file"; then
            echo "✓ $file - 包含 '$pattern'"
        else
            echo "✗ $file - 缺少 '$pattern'"
            all_passed=false
        fi
    else
        echo "✗ $file - 文件不存在"
        all_passed=false
    fi
done

echo

# 检查 SUSFS 核心文件
echo "检查 SUSFS 核心文件..."
for file in fs/susfs.c include/linux/susfs.h include/linux/susfs_def.h; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        if [ "$size" -gt 1000 ]; then
            echo "✓ $file - 存在且大小正常 (${size} bytes)"
        else
            echo "⚠ $file - 存在但大小异常 (${size} bytes)"
        fi
    else
        echo "✗ $file - 文件不存在"
        all_passed=false
    fi
done

echo

if $all_passed; then
    echo "✓ 所有关键检查通过！"
    exit 0
else
    echo "✗ 存在失败的检查项"
    exit 1
fi
