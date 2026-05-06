#!/usr/bin/env bash
set -e

if [ "$#" -lt 1 ]; then
    echo "用法: ./tools/backup_before_edit.sh 文件1 文件2 ..."
    exit 1
fi

TIME_TAG=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=".codex_backups/$TIME_TAG"

mkdir -p "$BACKUP_DIR"

for file in "$@"; do
    if [ -f "$file" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        cp "$file" "$BACKUP_DIR/$file"
        echo "已备份: $file -> $BACKUP_DIR/$file"
    else
        echo "警告: 文件不存在，跳过: $file"
    fi
done

echo "备份完成，目录: $BACKUP_DIR"
