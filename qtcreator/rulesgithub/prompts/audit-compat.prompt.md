---
description: "Qt/C++ API 兼容性审计。输入目标 Qt 版本和编译器，自动审计源码中不兼容的 API 和 C++ 特性。"
---

# API 兼容性审计

对 Qt Creator 4.13.3 源码执行完整的兼容性审计。

## 输入参数
- **目标 Qt 版本**: ${input:qtVersion:目标 Qt 版本，如 5.6.3}
- **目标编译器**: ${input:compiler:编译器，如 MSVC2015/GCC5}

## 审计步骤

1. 确认 qtcreator.pro 中的版本门槛与目标版本的差距
2. 确认 qtcreator.pri 中的 C++ 标准要求与目标编译器的兼容性
3. 审计源码中使用的 C++ 特性（按目标编译器的支持情况分类）
4. 审计源码中使用的 Qt API（按引入版本分类，标记目标版本中不存在的）
5. 检查 3rdparty 库的编译器版本守卫
6. 统计需改动的文件数和出现次数
7. 给出 polyfill 方案和实施顺序
8. 估算工作量

## 输出
报告保存到 `QtCreator_Reports/` 目录。
