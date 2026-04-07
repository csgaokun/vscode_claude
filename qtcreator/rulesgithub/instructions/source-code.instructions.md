---
applyTo: "qt-creator-opensource-src-4.13.3/**/*.{cpp,h,hpp,pri,pro}"
description: "Qt Creator 源码编辑规范。Use when: 修改 Qt Creator 4.13.3 源码、添加 polyfill、修改构建文件时自动应用。"
---

# 源码修改规范

## 兼容性要求
- 所有修改必须同时兼容 MSVC2015 (Update 3) 和 GCC ≥ 5
- 添加 polyfill 时使用 `QT_VERSION_CHECK` 条件编译守卫
- 不得引入 C++17 或更高标准的特性
- 不得引入 Qt 5.7+ 的 API（除非有 polyfill 保护）

## 修改风格
- 修改处添加注释标记：`// Qt56Compat: 原因说明`
- polyfill 集中放在 `src/libs/utils/qt56compat.h`
- 不改动 3rdparty/ 下的代码，除非是版本守卫修改
