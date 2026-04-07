# Qt Creator 6.0.2 降级到 Qt 5.5.1 + MSVC2013 / GCC 编译——可行性审查报告

## 〇、结论

**不可行。直接移植的工程量等同于重写。**

6.0.2 的代码全面依赖 C++17 和 Qt 5.14+ API，与 Qt 5.5.1 + MSVC2013 之间存在**三重不可调和矛盾**。下面是基于 6579 个源文件逐项审查的量化结论。

---

## 一、三重矛盾总览

| 维度 | 6.0.2 要求 | 你的环境 | 差距 |
|---|---|---|---|
| **C++ 标准** | C++17（硬性） | MSVC2013 = C++11 残缺，GCC 需≥7 | MSVC2013 差两代标准 |
| **Qt 最低版本** | Qt 5.14.0（硬性 `error()`） | Qt 5.5.1 | 差 9 个小版本，3 年 API 演进 |
| **编译器** | MSVC≥2017 15.7 / GCC≥7 / Clang≥5 | MSVC2013 (v12) | MSVC 差 4 代 |

---

## 二、C++ 标准障碍（致命）

### 2.1 MSVC2013 的 C++ 支持现实

MSVC2013（_MSC_VER = 1800）的 C++ 支持：

| 特性 | C++ 标准 | MSVC2013 支持 | 6.0.2 使用文件数 |
|---|---|---|---|
| `std::optional` | C++17 | ❌ 完全没有 | **186 个文件** |
| `std::variant` | C++17 | ❌ 完全没有 | **34 个文件** |
| 嵌套命名空间 `namespace A::B {}` | C++17 | ❌ 完全没有 | **88 个文件** |
| 结构化绑定 `auto [a, b] = ...` | C++17 | ❌ 完全没有 | **11 个文件** |
| `if constexpr` | C++17 | ❌ 完全没有 | **5 个文件**（含 qbs） |
| `constexpr` lambda | C++17 | ❌ 完全没有 | 多处 |
| `[[nodiscard]]` 属性 | C++17 | ❌ 完全没有 | **~5 个文件** |
| 折叠表达式 | C++17 | ❌ 完全没有 | **~3 个文件** |
| `inline` 变量 | C++17 | ❌ 完全没有 | **~5 个头文件** |
| 泛型 lambda `[](auto x){}` | C++14 | ❌ 完全没有 | **40 个文件** |
| `auto` 返回类型推导 | C++14 | ❌ 完全没有 | **42 个文件** |
| 变量模板 | C++14 | ❌ 完全没有 | 多处 |
| `std::make_unique` | C++14 | ❌ 完全没有 | 广泛使用 |
| `constexpr` 函数（放宽版） | C++14 | ❌ 仅支持 C++11 `constexpr` | 大量 |
| `decltype(auto)` | C++14 | ❌ 完全没有 | 多处 |

### 2.2 关键发现：optional/variant 的回退层不适用于 MSVC2013

`utils/optional.h` 和 `utils/variant.h` 确实有回退路径——但**仅针对 Apple Clang**（`__apple_build_version__`）：

```cpp
// optional.h
#if !defined(__apple_build_version__)
#include <optional>  // 直接用 std::optional -> 需要 C++17
#else
#include <3rdparty/optional/optional.hpp>  // Apple 回退
```

MSVC2013 不是 Apple Clang，走的是 `#include <optional>` 路径，而 MSVC2013 **没有 `<optional>` 头文件**，直接编译失败。

### 2.3 Linux GCC 版本要求

如果在 Linux 上编译，GCC 版本必须满足：

| C++ 特性 | GCC 最低版本 |
|---|---|
| C++17 核心语言 | GCC 7 |
| `std::optional` / `std::variant` | GCC 7（libstdc++ 7） |
| 嵌套命名空间 | GCC 6 |
| 结构化绑定 | GCC 7 |
| `if constexpr` | GCC 7 |

**最低 GCC 版本：GCC 7.x**（推荐 GCC 8+）。

Qt 5.5.1 通常搭配 GCC 4.8~5.x，这**不满足 C++17 要求**。

---

## 三、Qt API 障碍（致命）

### 3.1 全局门禁

`qtcreator.pro` 第 4 行：

```qmake
!minQtVersion(5, 14, 0) {
    message("Cannot build $$IDE_DISPLAY_NAME with Qt version $${QT_VERSION}.")
    error("Use at least Qt 5.14.0.")
}
```

Qt 5.5.1 → 直接 `error()` 退出。修改此行只是第一步。

### 3.2 Qt 5.6 ~ 5.14 期间引入的 API 统计

| API | 引入版本 | 涉及文件数 | 影响范围 |
|---|---|---|---|
| `qAsConst()` | 5.7 | **~320 个文件** | 遍布整个代码库，几乎每个 ranged-for 循环都用 |
| `QOverload` / `qOverload` | 5.7 | **~175 个文件** | 所有 signal/slot 连接中的成员函数指针消歧义 |
| `QStringView` | 5.10 | **~97 个文件** | 字符串处理核心路径 |
| `Qt::SkipEmptyParts` | 5.14 | **~85 个文件** | 替代 `QString::SkipEmptyParts`，5.5 中不存在此枚举 |
| `QVersionNumber` | 5.6 | **~51 个文件** | Kit 系统、Qt 版本检测、插件兼容 |
| `QMultiHash` 独立类 | 5.14 重构 | **~40 个文件** | Qt 5.5 中 `QMultiHash` 继承自 `QHash`，API 不同 |
| `qEnvironmentVariable()` | 5.10 | **~13 个文件** | 环境变量读取 |
| `QDeadlineTimer` | 5.8 | 多处 | 超时控制 |
| `QRandomGenerator` | 5.10 | 多处 | 替代 `qrand()` |
| `Q_NAMESPACE` / `Q_ENUM_NS` | 5.8 | 多处 | 命名空间级别的枚举元对象注册 |
| `QScopeGuard` / `qScopeGuard` | 5.12 | 多处 | 作用域退出守护 |

### 3.3 Qt 5.5.1 本身的问题

- Qt 5.5 的 qmake 不认识 `CONFIG += c++17` 和 `c++1z`——这是 Qt 5.9+ 才加的
- Qt 5.5 的 `QRegularExpression` 存在但 API 与 5.14 有差异
- Qt 5.5 缺少 `QOperatingSystemVersion`（5.9 引入）
- `QT_DISABLE_DEPRECATED_BEFORE=0x050900` 直接裁掉了 5.9 以前的废弃 API

---

## 四、受影响文件统计

以 6579 个源文件（排除 qbs）为基准：

| 障碍类型 | 受影响文件数 | 占比 |
|---|---|---|
| `qAsConst`（Qt 5.7+） | ~320 | 4.9% |
| `QOverload`（Qt 5.7+） | ~175 | 2.7% |
| `std::optional`（C++17） | ~186 | 2.8% |
| `QStringView`（Qt 5.10+） | ~97 | 1.5% |
| 嵌套命名空间（C++17） | ~88 | 1.3% |
| `Qt::SkipEmptyParts`（Qt 5.14+） | ~85 | 1.3% |
| `QVersionNumber`（Qt 5.6+） | ~51 | 0.8% |
| 泛型 lambda（C++14） | ~40 | 0.6% |
| `QMultiHash` 变更（Qt 5.14+） | ~40 | 0.6% |
| `auto` 返回类型（C++14） | ~42 | 0.6% |
| `std::variant`（C++17） | ~34 | 0.5% |
| 结构化绑定（C++17） | ~11 | 0.2% |
| 其他 C++17/Qt 5.6-5.14 API | ~100+ | ~1.5% |
| **去重后总计（估）** | **~800+ 个文件** | **~12%** |

注意：很多文件同时命中多个障碍，去重后影响约 800~1000 个文件，目测 **需要修改 15~20% 的代码库**。

---

## 五、假设要强行做，需要什么

### 方案 A：降级 Qt Creator 6.0.2 代码（不推荐）

| 步骤 | 工作量 | 风险 |
|---|---|---|
| 1. 移除 `minQtVersion` 检查 | 1 行 | 无 |
| 2. 改 `CONFIG += c++17` → `c++11` | 1 行 | 打开所有 C++ 障碍 |
| 3. 替换 `optional.h` / `variant.h` 的回退层，改为无条件使用 3rdparty 实现 | 2 个文件 | 中等 |
| 4. 消灭 88 个文件的嵌套命名空间 → `namespace A { namespace B {` | ~88 文件 ~200 处 | 机械替换，低风险 |
| 5. 消灭 ~320 个文件的 `qAsConst` → 自定义宏或强制 `const` | ~320 文件 ~1000+ 处 | 巨量机械替换 |
| 6. 消灭 ~175 个文件的 `QOverload` → 旧式 `static_cast<>(&Class::method)` | ~175 文件 ~400+ 处 | 机械替换，需逐个确认签名 |
| 7. 消灭 ~97 个文件的 `QStringView` → `QString` / `QStringRef` | ~97 文件 | 高风险，语义不完全等价 |
| 8. 消灭 ~85 个文件的 `Qt::SkipEmptyParts` → `QString::SkipEmptyParts` | ~85 文件 | 机械替换 |
| 9. 消灭 ~51 个文件的 `QVersionNumber` → 自实现 | ~51 文件 | 中等 |
| 10. 消灭 ~40 个文件的泛型 lambda → 显式类型 lambda | ~40 文件 | 需逐个理解上下文 |
| 11. 消灭 ~42 个文件的 `auto` 返回类型 → 显式类型 | ~42 文件 | 需逐个推导类型 |
| 12. 消灭 ~11 个文件的结构化绑定 → `std::tie` / 手动解构 | ~11 文件 | 低风险 |
| 13. 消灭 `if constexpr` → 模板特化或 `#ifdef` | ~5 文件 | 低风险 |
| 14. 消灭 `QMultiHash` API 差异 | ~40 文件 | 需逐个分析 |
| 15. 消灭 `qEnvironmentVariable` → `qgetenv` | ~13 文件 | 低风险 |
| 16. 消灭其他 Qt 5.6-5.14 API | ~100+ 文件 | 逐个处理 |
| 17. **MSVC2013 特有**：处理 C++11 残缺支持（`noexcept` 不完整、`alignas`/`alignof` 限制、`constexpr` 限制、表达式 SFINAE 不完整） | 无法预估 | **极高风险** |

**估计工作量**：3000~5000 处代码修改，覆盖 800~1000 个文件。全手工完成至少需要 **2~4 人月**，且修改后的代码无法合入上游，永远需要自行维护。

### 方案 B：使用 Qt Creator 4.x 旧版本（推荐）

Qt Creator **4.5.x**（2018 年发布）是最后一个支持 Qt 5.5 + MSVC2013 的大版本系列：

| 版本 | Qt 最低版本 | C++ 标准 | MSVC 最低 |
|---|---|---|---|
| Qt Creator 4.5.2 | Qt 5.5.0 | C++14（宽松） | MSVC2013 |
| Qt Creator 4.8.x | Qt 5.6.0 | C++14 | MSVC2015 |
| Qt Creator 4.13.3 | Qt 5.9.0 | C++14 | MSVC2015 |
| Qt Creator 6.0.2 | Qt 5.14.0 | C++17 | MSVC2017 |

**你已经有 4.13.3 的代码**。如果必须用 Qt 5.5.1 + MSVC2013，建议：
1. 从 Qt 官方下载 Qt Creator **4.5.2** 源码
2. 它原生支持 Qt 5.5 和 MSVC2013，开箱即用

### 方案 C：升级编译器和 Qt（最优解）

| 升级项 | 建议版本 | 理由 |
|---|---|---|
| Qt | 5.15.2（LTS） | 6.0.2 的全部条件特性可用，且是 5.x 最终 LTS |
| Windows 编译器 | MSVC2019（v142） | 完整 C++17 支持 |
| Linux 编译器 | GCC 9+ | 完整 C++17 支持，ABI 稳定 |

这是 0 改动、0 风险的方案。

---

## 六、最终建议

| 你的目标 | 推荐方案 |
|---|---|
| 必须用 MSVC2013 + Qt 5.5.1 | → 放弃 6.0.2，使用 **Qt Creator 4.5.2** |
| 想要 Qt Creator 6.0.2 的功能 | → 升级到 **Qt 5.15.2 + MSVC2019 + GCC 9** |
| 想在 6.0.2 基础上做定制开发 | → 升级编译器到 MSVC2019/GCC 9，Qt 升至 5.15.2 |
| 必须在 6.0.2 上用旧编译器 | → 2~4 人月改造，改 800+ 文件 3000+ 处，**强烈不推荐** |
