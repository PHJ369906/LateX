#!/bin/bash

# 系统性修复所有Java文件中的Map<String, Object>类型
echo "开始批量修复类型系统..."

# 查找所有Java文件并替换
find /Users/puhuajie/Documents/AI/WeKnora-main/weknora-java/src -name "*.java" -exec sed -i '' 's/Map<String, Object>/Map<String, Serializable>/g' {} \;

echo "批量替换完成！"

# 在需要的文件头部添加import
find /Users/puhuajie/Documents/AI/WeKnora-main/weknora-java/src -name "*.java" -exec grep -l "Map<String, Serializable>" {} \; | while read file; do
    if ! grep -q "import java.io.Serializable;" "$file"; then
        # 在import section添加Serializable import
        sed -i '' '/^import java\./a\
import java.io.Serializable;
' "$file"
    fi
done

echo "添加import完成！"