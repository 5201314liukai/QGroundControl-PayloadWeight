
## 强制备份规则

在你准备修改任何源码文件之前，必须先备份原文件。

备份方式：

使用项目内脚本：

./tools/backup_before_edit.sh 文件路径

例如：

./tools/backup_before_edit.sh src/ui/toolbar/MainStatusIndicator.qml

如果一次要修改多个文件，必须一次性全部备份：

./tools/backup_before_edit.sh \
src/Vehicle/Vehicle.h \
src/Vehicle/Vehicle.cc \
src/ui/toolbar/MainStatusIndicator.qml

工作规则：

1. 修改源码前必须先执行备份脚本。
2. 没有完成备份，不允许修改源码。
3. 每次回答中要先说明“准备修改哪些文件”。
4. 然后先给出备份命令。
5. 备份完成后，才能给出修改代码。
6. 如果我说“只分析”，则不要备份、不要修改。
7. 如果我说“可以改代码”，也必须先备份再改。
