---
description: "Qt Creator 架构分析报告。分析指定版本的目录结构、构建系统、插件架构、库依赖、通信机制和设计模式。"
---

# 架构分析报告

对 Qt Creator 源码执行完整的架构分析。

## 输入参数
- **源码目录**: ${input:srcDir:源码目录名，如 qt-creator-opensource-src-4.13.3}

## 分析内容

1. 顶层目录结构与构建系统（qmake/CMake/Qbs）
2. 启动流程（main.cpp → 插件加载）
3. 核心库分析（libs/ 下每个库的职责）
4. 插件分类与依赖关系
5. 工具链（tools/）
6. 进程间通信与信号槽机制
7. 设计模式识别
8. 代码规模统计

## 输出
报告保存到 `QtCreator_Reports/` 目录。
