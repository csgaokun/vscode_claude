# Qt Creator 4.13.3 降级到 Qt 5.5.1 + MSVC2013 / Linux GCC 可行性审计报告

基于对 `qt-creator-opensource-src-4.13.3/src/` 全目录代码审计（6590 个源文件，排除 qbs）。

---

## 一、版本门槛

| 项目 | 当前要求 | 目标环境 | 差距 |
|------|---------|---------|------|
| Qt 最低版本 | **5.12.0**（qtcreator.pro 第4行 `error()` 硬门槛） | Qt 5.5.1 | **7 个小版本** |
| C++ 标准 | **C++14**（qtcreator.pri `CONFIG += c++14`） | MSVC2013 = C++11（不完整） | **1 代** |
| MSVC 版本 | 未硬编码，但代码依赖 C++14 特性 | MSVC2013 (_MSC_VER=1800) | 见下方详分 |
| Linux GCC | 未硬编码，C++14 需 GCC ≥ 5 | 取决于实际版本 | GCC 5+ 即可 |

### 修改 qtcreator.pro 门槛
```diff
- !minQtVersion(5, 12, 0) {
+ !minQtVersion(5, 5, 1) {
```
仅此一行可绕过门槛，但真正的障碍在代码层面。

---

## 二、C++14 特性障碍（MSVC2013 不支持）

| # | C++14 特性 | 文件数 | 出现次数 | 严重度 | 集中位置 | 替代方案 |
|---|-----------|--------|---------|--------|---------|---------|
| 1 | `std::make_unique` | **131** | ~314 | **极高** | projectexplorer(34), cmake(9), qmldesigner(8), tools(7) | 手写 `make_unique` polyfill 或逐一改 `new` + `unique_ptr` |
| 2 | `decltype(auto)` 返回类型 | **4** | **33** | **高** | `utils/algorithm.h` 集中 33 处（transform/take 函数族） | 改为 `auto` + 尾置返回类型 `-> decltype(...)` |
| 3 | 泛型 Lambda `[](auto ...)` | **11** | ~17 | **中** | algorithm.h, clang 后端, languageclient, qmldesigner | 改为显式类型参数或函数对象 |
| 4 | `std::index_sequence` / `std::integer_sequence` | **2** (非3rdparty) | ~8 | **低** | `runextensions.h`, `sqlitebasestatement.h` | 手写 index_sequence polyfill |

### 关键说明：algorithm.h 影响链
`utils/algorithm.h` 被 **492 个文件** include。其中 33 处 `decltype(auto)` 和 2 处泛型 Lambda 的修改将间接影响整个项目的编译。但修改集中在 algorithm.h 本文件内，**不需要改 492 个下游文件**。

---

## 三、C++11 特性障碍（MSVC2013 已知缺陷）

| # | 特性 | 文件数 | 严重度 | 集中位置 | 替代方案 |
|---|------|--------|--------|---------|---------|
| 1 | **继承构造函数** `using Base::Base;` | **192** | **极高** | languageserverprotocol(172), sqlite(3), clangsupport(3) | 手写转发构造函数 |
| 2 | 3rdparty `optional.hpp` 守卫 `_MSC_VER >= 1900` | 影响 **152** 个使用者 | **高** | `Utils::optional` 全局使用 | 需降级 optional 库或提供 MSVC2013 兼容分支 |
| 3 | 3rdparty `variant.hpp` 守卫 `_MSC_FULL_VER >= 190024210` | 影响 **21** 个使用者 | **高** | `Utils::variant` | 需降级 variant 库或用 tagged union 替代 |
| 4 | Expression SFINAE（MSVC2013 bug） | 不确定 | **中** | algorithm.h 模板重载, extensionsystem | 需逐一测试，可能需简化模板重载 |

### 继承构造函数详细分布

| 目录 | 文件数 |
|------|--------|
| libs/languageserverprotocol | 172 |
| libs/sqlite | 3 |
| libs/clangsupport | 3 |
| plugins/languageclient | 2 |
| plugins/mesonprojectmanager | 2 |
| tools/clangpchmanagerbackend | 2 |
| libs/utils | 2 |
| plugins/qbsprojectmanager | 2 |
| 其他（4个目录各1处） | 4 |

**languageserverprotocol 是重灾区**：172 处继承构造函数，全部需要改为手写转发构造函数。

---

## 四、Qt API 断层（Qt 5.5.1 中不存在）

| # | API | 引入版本 | 文件数 | 出现次数 | 替代方案 |
|---|-----|---------|--------|---------|---------|
| 1 | `qAsConst()` | **Qt 5.7** | **172** | ~575 | 自定义 polyfill 头文件（约 5 行实现） |
| 2 | `QOverload<>` | **Qt 5.7** | **212** | ~322 | `static_cast<void(Class::*)(Type)>(&Class::signal)` 逐一替换 |
| 3 | `QVersionNumber` | **Qt 5.6** | **25** | ~139 | 手写简易版本号类 |
| 4 | `QStringView` | **Qt 5.10** | **7** | ~20 | 改用 `QStringRef`（Qt 5.5 可用） |
| 5 | `qEnvironmentVariable()` | **Qt 5.10** | **6** | ~13 | `QString::fromLocal8Bit(qgetenv(...))` |
| 6 | `QCborValue` / `QCborMap` | **Qt 5.12** | **4** | ~9 | 仅在 3rdparty syntax-highlighting 中，用 JSON API 替代 |
| 7 | `qScopeGuard` | **Qt 5.12** | **2** | ~3 | 手写 RAII guard |
| 8 | `QOperatingSystemVersion` | **Qt 5.9** | **5** | ~14 | `#ifdef Q_OS_WIN` + 平台 API |
| 9 | `QRandomGenerator` | **Qt 5.10** | **2** | ~3 | `qrand()` |

### qAsConst polyfill 方案
```cpp
// compat.h — 放在 utils/ 下
#if QT_VERSION < QT_VERSION_CHECK(5, 7, 0)
template <typename T>
constexpr typename std::add_const<T>::type &qAsConst(T &t) noexcept { return t; }
template <typename T>
void qAsConst(const T &&) = delete;
#endif
```
此 polyfill 可消除 172 个文件 575 次引用，零文件改动。

### QOverload 替换难度
322 处 `QOverload` → `static_cast` 是纯机械替换，不涉及逻辑修改，可脚本化处理。

---

## 五、已有兼容层（可复用）

代码中 44 个文件已有 `QT_VERSION_CHECK` 守卫，主要是 5.11~5.15 到 6.0 的前向兼容：

| 文件 | 守卫内容 |
|------|---------|
| `utils/porting.h` | `Qt::SkipEmptyParts` ↔ `QString::SkipEmptyParts`（5.14 分界） |
| `utils/algorithm.h` | `toList()`/`toSet()` 兼容（5.14, 5.15 分界） |
| `app/main.cpp` | 高 DPI 设置（5.14 分界） |
| `advanceddockingsystem/` | 浮动窗口 API（5.12 分界） |

这些守卫对降级到 5.5.1 不直接有用，但说明代码架构**允许条件编译**。

---

## 六、Qt 模块可用性

| 模块 | Qt 5.5.1 有无 | 使用位置 | 处理 |
|------|:---:|---------|------|
| core, gui, widgets, network, xml | ✅ | 全局 | 无需处理 |
| concurrent | ✅ | utils/ | 无需处理 |
| printsupport | ✅ | texteditor, designer | 无需处理 |
| qml, quick, quickwidgets | ✅ | qmldesigner, qmlprofiler | 无需处理 |
| sql | ✅ | sqlite 插件 | 无需处理 |
| script, scripttools | ✅ | qbs | 无需处理 |
| serialport | ✅ | serialterminal 插件 | 无需处理 |
| testlib | ✅ | 测试 | 无需处理 |
| webenginewidgets | ✅（5.4引入） | help 插件（可选） | 无需处理 |
| designercomponents-private | ✅ | designer 插件 | 无需处理 |
| multimedia | ✅ | perfprofiler | 无需处理 |

所有 Qt 模块在 5.5.1 中均可用。**模块层面无障碍**。

---

## 七、Linux GCC 要求

| 项目 | 要求 |
|------|------|
| C++14 支持 | GCC **≥ 5.0**（`-std=c++14`） |
| 继承构造函数 | GCC **≥ 4.8**（与 MSVC 不同，GCC 全面支持） |
| 泛型 Lambda | GCC **≥ 4.9** |
| `decltype(auto)` | GCC **≥ 4.9** |
| `std::make_unique` | GCC **≥ 4.9**（libstdc++） |

**结论：Linux GCC ≥ 5.0 可直接编译 4.13.3 的 C++14 代码，无需任何 C++ 层面修改。**

GCC 障碍仅在 Qt API 层面（与 MSVC 相同的 qAsConst / QOverload / QVersionNumber 等问题）。

---

## 八、改动统计总表

### A. MSVC2013 专有改动（Linux GCC 不需要）

| 类别 | 需改文件数 | 改动点数 | 可脚本化 |
|------|-----------|---------|:--------:|
| `std::make_unique` → polyfill | 131 | ~314 | ✅ polyfill 头文件即可消除 |
| `decltype(auto)` → 尾置返回 | 4 | ~33 | ❌ 需手工改 algorithm.h |
| 泛型 Lambda → 显式类型 | 11 | ~17 | ❌ 需手工改 |
| 继承构造函数 → 转发构造 | 192 | ~192 | ⚠️ 半自动化 |
| optional.hpp MSVC 守卫 | 1 | 1 | ✅ 改守卫或降级库 |
| variant.hpp MSVC 守卫 | 1 | 1 | ✅ 改守卫或降级库 |
| `std::index_sequence` polyfill | 2 | ~8 | ✅ polyfill |
| Expression SFINAE 规避 | 未知（需编译验证） | 未知 | ❌ |

### B. Qt API 改动（MSVC2013 和 Linux GCC 都需要）

| 类别 | 需改文件数 | 改动点数 | 可脚本化 |
|------|-----------|---------|:--------:|
| `qAsConst` → polyfill | 0（polyfill 消除） | 0 | ✅ 1 个头文件 |
| `QOverload` → static_cast | 212 | ~322 | ✅ 可脚本替换 |
| `QVersionNumber` → 自定义类 | 25 | ~139 | ⚠️ 需写 polyfill 类 |
| `QStringView` → QStringRef | 7 | ~20 | ❌ 需手工适配 |
| `qEnvironmentVariable()` | 6 | ~13 | ✅ 脚本化 |
| `QCborValue/Map` | 4 | ~9 | ❌ 需改 3rdparty |
| `QOperatingSystemVersion` | 5 | ~14 | ❌ 需手工 |
| `qScopeGuard` | 2 | ~3 | ✅ |
| `QRandomGenerator` | 2 | ~3 | ✅ |
| qtcreator.pro 版本门槛 | 1 | 1 | ✅ |
| qtcreator.pri `c++14` → `c++11` (仅 MSVC) | 1 | 1 | ✅ |

---

## 九、可行性结论

### 评定：有条件可行（大量工作但非不可能）

与 6.0.2 的"不可行"结论不同，4.13.3 降级到 Qt 5.5.1 **在技术上可行**，原因：
1. C++ 标准差距是 C++14 → C++11，而非 C++17 → C++11
2. Qt API 差距是 5.12 → 5.5（7 个小版本），而非 5.14 → 5.5（9 个小版本）
3. 所有 Qt 模块在 5.5.1 中均可用
4. 大量改动可通过 polyfill 头文件和脚本化替换完成

### 分平台评估

| 平台 | 可行性 | 预计改动文件 | 预计改动点 |
|------|:------:|------------|-----------|
| **Linux GCC ≥ 5** | ✅ **高可行** | ~260 文件 | ~520 处（仅 Qt API） |
| **Windows MSVC2013** | ⚠️ **中等可行** | ~450 文件 | ~1100 处（Qt API + C++14 + C++11） |

### 推荐实施顺序

**第一步：Polyfill 层（消除 60% 改动量）**
1. 创建 `src/libs/utils/compat.h`，添加：
   - `qAsConst` polyfill → 消除 172 文件 575 处
   - `std::make_unique` polyfill → 消除 131 文件 314 处
   - `std::index_sequence` polyfill → 消除 2 文件 8 处
   - `QVersionNumber` 简易替代类 → 消除 25 文件 139 处
   - `qScopeGuard` 替代 → 消除 2 文件 3 处
2. 修改 `qtcreator.pro` 版本门槛
3. 修改 `qtcreator.pri` C++ 标准（MSVC 条件分支）

**第二步：脚本化替换（消除 25%）**
4. 脚本替换 `QOverload` → `static_cast`（212 文件 322 处）
5. 脚本替换 `qEnvironmentVariable()` → `QString::fromLocal8Bit(qgetenv())`

**第三步：手工修改（剩余 15%）**
6. 修改 `algorithm.h` 的 33 处 `decltype(auto)` 为尾置返回类型
7. 修改 11 个文件的泛型 Lambda 为显式类型
8. 修改 `optional.hpp` / `variant.hpp` 的 MSVC 守卫或降级库
9. 处理 192 处继承构造函数（languageserverprotocol 占 172 处）
10. 编译测试 → 修复 Expression SFINAE 残留问题

### 工作量估算

| 阶段 | 预计耗时 |
|------|---------|
| Polyfill + 门槛修改 | 1-2 天 |
| 脚本化替换 | 1 天 |
| algorithm.h + Lambda 手工修改 | 1-2 天 |
| optional/variant 3rdparty 降级 | 1-2 天 |
| 继承构造函数改写（192 处） | 3-5 天 |
| 编译调试 + SFINAE 修复 | 3-5 天 |
| **总计** | **10-17 个工作日（2-3.5 周）** |

---

## 十、替代方案对比

| 方案 | 难度 | 改动量 | 维护成本 |
|------|:----:|--------|---------|
| **A. 降级 4.13.3 到 Qt 5.5.1**（本报告） | 中高 | ~1100 处（MSVC）/ ~520 处（GCC） | 高（分叉维护） |
| **B. 使用 Qt Creator 4.5.2** | **零** | **零**——原生支持 Qt 5.5 + MSVC2013 | 零 |
| **C. 升级到 Qt 5.12.x + MSVC2015** | 低 | 零改动 | 零 |
| **D. 仅降级 Qt 到 5.9.x + MSVC2015** | 低 | 极少（< 50 处 Qt API 差异） | 低 |

**如果目标是"能用"而非"一定要 5.5.1 + MSVC2013"**，方案 B（Qt Creator 4.5.2）是零成本选择。
