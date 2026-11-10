#!/bin/bash
# SD15 模型离线包恢复脚本
# 用法：把所有 .part 文件、SHA256SUMS-MODEL.txt、restore_model.sh
#       一起放到绿联「项目」向导生成的项目目录里，然后在此目录执行：
#           sh restore_model.sh
set -e

echo "=== 1/4 校验分卷 ==="
sha256sum -c SHA256SUMS-MODEL.txt

echo "=== 2/4 合并分卷 ==="
cat sd15-model-layer.tar.part* > sd15-model-layer.tar
sha256sum -c SHA256SUMS-FULL.txt

echo "=== 3/4 解压并整理目录 ==="
rm -rf models ovms-models
tar -xf sd15-model-layer.tar
mv models ovms-models
# 模型许可证随包单独附带，放进模型目录一起保留
if [ -f LICENSE-MODEL-OpenRAIL-M.txt ]; then
  cp LICENSE-MODEL-OpenRAIL-M.txt ovms-models/
fi
# state.json 必须是 0 字节文件，不能是目录
if [ ! -f state.json ]; then : > state.json; fi

echo "=== 4/4 核对 ==="
N=$(find ovms-models -type f | wc -l)
echo "模型目录文件数：$N（至少 27 = 26 个模型文件 + config.json）"
[ "$N" -ge 27 ] || { echo "模型文件不完整，请检查分卷"; exit 1; }
[ -f state.json ] || { echo "state.json 缺失"; exit 1; }
echo "完成。现在可以回到绿联「项目 → 创建」粘贴 compose.ugnas-offline.yaml 部署了。"
