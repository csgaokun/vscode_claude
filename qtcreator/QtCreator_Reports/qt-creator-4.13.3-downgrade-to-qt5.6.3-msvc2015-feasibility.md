# Qt Creator 4.13.3 降级到 Qt 5.6.3 + MSVC2015 / Linux GCC 可行性审计报告

基于 `qt-creator-opensource-src-4.13.3/src/` 全目录代码审计（6388 个源文件，排除 qbs 和 3rdparty 单独计数）。

---

## 一、版本门槛对比

| 项目 | 当前要求 | 目标环境 | 差距 |
|------|---------|---------|------|
| Qt 最低版本 | **5.12.0**（qtcreator.pro 第4行 `error()` 硬门槛） | Qt 5.6.3 | **6 个小版本** |
| C++ 标准 | **C++14**（qtcreator.pri `CONFIG += c++14`） | MSVC2015 支持 C++14 | **无差距** |
| MSVC 版本 | 未硬编码 | MSVC2015 (_MSC_VER=1900) | 见第三节 |
| Linux GCC | 未硬编码，C++14 需 GCC ≥ 5 | GCC ≥ 5 即可 | **无差距** |

**与之前 Qt 5.5.1 + MSVC2013 报告的本质区别**：MSVC2015 完整支持 C++14，继承构造函数、泛型 Lambda、`decltype(auto)`、`std::make_unique` 全部原生可用。**C++ 层面障碍归零。** 问题仅剩 Qt API 断层。

---

## 二、C++ 标准兼容性（无障碍）

MSVC2015 对 C++14 的支持：

| C++14 特性 | MSVC2015 支持 | 4.13.3 使用情况 | 状态 |
|-----------|:---:|---------|:---:|
| `std::make_unique` | ✅ | 131 文件 ~314 处 | **通过** |
| `decltype(auto)` | ✅ | 4 文件 ~33 处 | **通过** |
| 泛型 Lambda `[](auto)` | ✅ | 11 文件 ~17 处 | **通过** |
| 继承构造函数 `using Base::Base` | ✅ | 192 文件 ~192 处 | **通过** |
| `std::index_sequence` | ✅ | 已有 polyfill | **通过** |
| Relaxed constexpr | ✅ | 少量 | **通过** |

Linux GCC ≥ 5 同样全部支持。**两个平台在 C++ 层面都不需要任何修改。**

---

## 三、3rdparty 库 MSVC 守卫

| 库 | 守卫条件 | MSVC2015 RTM | MSVC2015 Update 3 |
|---|---------|:---:|:---:|
| `optional.hpp` | `_MSC_VER >= 1900` | ✅ 通过（1900） | ✅ |
| `variant.hpp` | `_MSC_FULL_VER >= 190024210` | ❌ RTM=190023026 | ✅ Update3=190024210 |

### variant.hpp 要求 MSVC2015 Update 3

```cpp
// variant.hpp 第221行
#if __cplusplus < 201103L && (!defined(_MSC_VER) || _MSC_FULL_VER < 190024210)
#error "MPark.Variant requires C++11 support."
#endif
```

MSVC 默认 `__cplusplus = 199711L`（不随编译标准更新），所以第一个条件始终为 true。MSVC2015 RTM（`_MSC_FULL_VER = 190023026`）会触发 `#error`。

| MSVC2015 版本 | `_MSC_FULL_VER` | variant.hpp |
|--|--|:--:|
| RTM | 190023026 | ❌ 编译失败 |
| Update 1 | 190023506 | ❌ 编译失败 |
| Update 2 | 190023918 | ❌ 编译失败 |
| **Update 3** | **190024210** | ✅ 通过 |

**结论：必须使用 MSVC2015 Update 3 或更高版本。** Qt 5.6.3 发布于 2017 年，通常已搭配 Update 3。

---

## 四、Qt API 断层（核心改动区）

以下 API 在 Qt 5.12 中存在，但 Qt 5.6.3 中**不存在**：

### 4.1 高影响（需处理）

| # | API | 引入版本 | 文件数 | 出现次数 | 替代方案 | 可脚本化 |
|---|-----|---------|--------|---------|---------|:---:|
| 1 | `qAsConst()` | Qt 5.7 | **167** | 335 | polyfill 头文件（5行代码） | ✅ 零文件改动 |
| 2 | `QOverload<>` | Qt 5.7 | **212** | 322 | `static_cast` 写法 | ✅ 可脚本 |
| 3 | `Q_FALLTHROUGH()` | Qt 5.8 | **37** | 145 | polyfill 宏定义 | ✅ 零文件改动 |

### 4.2 中影响（少量文件）

| # | API | 引入版本 | 文件数 | 出现次数 | 替代方案 |
|---|-----|---------|--------|---------|---------|
| 4 | `QStringView` | Qt 5.10 | 7 | ~20 | `QStringRef`（Qt 5.6 可用） |
| 5 | `qEnvironmentVariable()` | Qt 5.10 | 6 | ~13 | `QString::fromLocal8Bit(qgetenv(...))` |
| 6 | `QOperatingSystemVersion` | Qt 5.9 | 1 | ~14 | 条件编译 + WinAPI/uname |
| 7 | `QCborValue/QCborMap` | Qt 5.12 | 4 | ~9 | 仅在 3rdparty syntax-highlighting 中，改用 QJsonDocument |

### 4.3 低影响（极少文件）

| # | API | 引入版本 | 文件数 | 替代方案 |
|---|-----|---------|--------|---------|
| 8 | `qScopeGuard` | Qt 5.12 | 2 | 手写 RAII guard |
| 9 | `QT_CONFIG()` 宏 | Qt 5.8 | 2 (仅 androidsdkdownloader) | 改用 `#ifndef QT_NO_SSL` |
| 10 | `QFont::setFamilies` | Qt 5.13 | 1 | 已有 `QT_VERSION_CHECK` 守卫，自动回退 |

### 4.4 已安全（Qt 5.6.3 中存在）

| API | 引入版本 | 文件数 | 状态 |
|-----|---------|--------|:---:|
| `QVersionNumber` | Qt 5.6 | 25 | ✅ 安全 |
| `QRegularExpression` | Qt 5.0 | 276 | ✅ 安全 |
| `qCDebug` / `qCWarning` | Qt 5.2 | 137 | ✅ 安全 |
| `qCInfo` | Qt 5.5 | 22 | ✅ 安全 |
| `QMetaEnum::fromType` | Qt 5.5 | 5 | ✅ 安全 |
| `qEnvironmentVariableIsSet/IntValue` | Qt 5.1 | 30 | ✅ 安全 |

---

## 五、已有兼容层（代码中已存在的条件编译）

| 文件 | 守卫 | 功能 |
|------|------|------|
| `utils/porting.h` | `QT_VERSION_CHECK(5, 14, 0)` | `Qt::SkipEmptyParts` ↔ `QString::SkipEmptyParts` |
| `utils/algorithm.h` | `QT_VERSION_CHECK(5, 14, 0)` | `toList()`/`toSet()` 兼容 |
| `help/qlitehtml/container_qpainter.cpp` | `QT_VERSION_CHECK(5, 13, 0)` | `QFont::setFamilies` 回退 |
| `app/main.cpp` | `QT_VERSION_CHECK(5, 14, 0)` | 高 DPI 设置 |
| 其他约 40 个文件 | 5.11 ~ 5.15 各守卫 | 向前兼容 Qt 6 |

这些守卫在 Qt 5.6.3 下会自动走旧代码路径，**无需修改**。

---

## 六、Qt 模块可用性

| 模块 | Qt 5.6.3 | 使用位置 | 状态 |
|------|:---:|---------|:---:|
| core, gui, widgets, network, xml | ✅ | 全局 | 安全 |
| concurrent, printsupport, sql | ✅ | utils, texteditor | 安全 |
| qml, quick, quickwidgets | ✅ | qmldesigner, qmlprofiler | 安全 |
| script, scripttools | ✅ | qbs | 安全 |
| serialport | ✅ | serialterminal 插件 | 安全 |
| webenginewidgets | ✅（5.4 引入） | help 插件（可选） | 安全 |
| designercomponents-private | ✅ | designer 插件 | 安全 |
| multimedia | ✅ | perfprofiler | 安全 |

**所有 Qt 模块在 5.6.3 中均可用，模块层面无障碍。**

---

## 七、Polyfill 方案（解决 80% 问题）

创建 `src/libs/utils/qt56compat.h`：

```cpp
#pragma once
#include <QtGlobal>

// --- qAsConst polyfill (Qt 5.7) ---
#if QT_VERSION < QT_VERSION_CHECK(5, 7, 0)
template <typename T>
constexpr typename std::add_const<T>::type &qAsConst(T &t) noexcept { return t; }
template <typename T>
void qAsConst(const T &&) = delete;
#endif

// --- Q_FALLTHROUGH polyfill (Qt 5.8) ---
#if QT_VERSION < QT_VERSION_CHECK(5, 8, 0)
#  if defined(__has_cpp_attribute)
#    if __has_cpp_attribute(fallthrough)
#      define Q_FALLTHROUGH() [[fallthrough]]
#    elif __has_cpp_attribute(clang::fallthrough)
#      define Q_FALLTHROUGH() [[clang::fallthrough]]
#    elif __has_cpp_attribute(gnu::fallthrough)
#      define Q_FALLTHROUGH() __attribute__((fallthrough))
#    endif
#  endif
#  ifndef Q_FALLTHROUGH
#    if defined(__GNUC__) && __GNUC__ >= 7
#      define Q_FALLTHROUGH() __attribute__((fallthrough))
#    else
#      define Q_FALLTHROUGH() (void)0
#    endif
#  endif
#endif

// --- QT_CONFIG polyfill (Qt 5.8) ---
#if QT_VERSION < QT_VERSION_CHECK(5, 8, 0)
#  define QT_CONFIG(feature) QT_FEATURE_##feature
#endif

// --- qEnvironmentVariable polyfill (Qt 5.10) ---
#if QT_VERSION < QT_VERSION_CHECK(5, 10, 0)
#include <QString>
inline QString qEnvironmentVariable(const char *varName)
{
    return QString::fromLocal8Bit(qgetenv(varName));
}
inline QString qEnvironmentVariable(const char *varName, const QString &defaultValue)
{
    const QByteArray val = qgetenv(varName);
    return val.isNull() ? defaultValue : QString::fromLocal8Bit(val);
}
#endif

// --- qScopeGuard polyfill (Qt 5.12) ---
#if QT_VERSION < QT_VERSION_CHECK(5, 12, 0)
template <typename F>
class QScopeGuardImpl {
    F m_func;
    bool m_active;
public:
    explicit QScopeGuardImpl(F &&f) : m_func(std::move(f)), m_active(true) {}
    ~QScopeGuardImpl() { if (m_active) m_func(); }
    void dismiss() { m_active = false; }
    QScopeGuardImpl(QScopeGuardImpl &&o) : m_func(std::move(o.m_func)), m_active(o.m_active) { o.dismiss(); }
};
template <typename F>
QScopeGuardImpl<typename std::decay<F>::type> qScopeGuard(F &&f)
{
    return QScopeGuardImpl<typename std::decay<F>::type>(std::forward<F>(f));
}
#endif
```

此文件注入方式：在 `utils/utils_global.h` 或 `qtcreator.pri` 中 `INCLUDEPATH` 添加，或在预编译头中 include。

**效果**：polyfill 可直接消除以下改动需求：

| API | 消除的文件数 | 消除的出现次数 | 下游文件改动 |
|-----|-----------|-------------|:---:|
| `qAsConst` | 167 | 335 | 零 |
| `Q_FALLTHROUGH` | 37 | 145 | 零 |
| `qEnvironmentVariable` | 6 | 13 | 零 |
| `qScopeGuard` | 2 | 3 | 零 |
| 合计 | **212** | **496** | **零** |

---

## 八、需手工/脚本修改的部分

### 8.1 QOverload → static_cast（可脚本化）

| 原始写法 | 替换写法 |
|---------|---------|
| `QOverload<int>::of(&QComboBox::currentIndexChanged)` | `static_cast<void(QComboBox::*)(int)>(&QComboBox::currentIndexChanged)` |

**212 文件 322 处**，全部是机械替换，可用 Python/sed 脚本批量处理。

### 8.2 QStringView → QStringRef（7 文件手工）

`QStringView` 的 API 与 `QStringRef` 有细微差异（构造方式、method 名称），需逐文件适配。

### 8.3 QCborValue → QJsonDocument（4 文件，3rdparty）

仅在 `3rdparty/syntax-highlighting` 子目录中使用，可降级该第三方库版本或改用 JSON API。

### 8.4 QOperatingSystemVersion（1 文件）

仅 `utils/fileutils.cpp` 中 1 处（之前的搜索含 qbs 导致数字偏高）。

### 8.5 QT_CONFIG 宏（2 处，1 文件）

```diff
- #if QT_CONFIG(ssl)
+ #ifndef QT_NO_SSL
```

仅在 `androidsdkdownloader.cpp`/`.h` 中，polyfill 方案也可覆盖。

### 8.6 qtcreator.pro 版本门槛

```diff
- !minQtVersion(5, 12, 0) {
-     message("Cannot build $$IDE_DISPLAY_NAME with Qt version $${QT_VERSION}.")
-     error("Use at least Qt 5.12.0.")
+ !minQtVersion(5, 6, 3) {
+     message("Cannot build $$IDE_DISPLAY_NAME with Qt version $${QT_VERSION}.")
+     error("Use at least Qt 5.6.3.")
```

---

## 九、改动总表

| 类别 | 文件数 | 改动点数 | 方式 | 耗时预估 |
|------|--------|---------|------|---------|
| polyfill 头文件创建 | 1 (新建) | — | 手写 | 0.5 天 |
| qtcreator.pro 门槛 | 1 | 1 | 手工 | 5 分钟 |
| `QOverload` → `static_cast` | 212 | 322 | **脚本** | 0.5 天 |
| `QStringView` → `QStringRef` | 7 | ~20 | 手工 | 0.5 天 |
| `QCborValue` → JSON | 4 | ~9 | 手工 | 0.5 天 |
| `QOperatingSystemVersion` | 1 | ~2 | 手工 | 0.5 小时 |
| `QT_CONFIG` → `QT_NO_xxx` | 1 | 3 | 手工 | 10 分钟 |
| 编译测试 + 修复残留 | — | — | — | 1-2 天 |
| **总计** | **~227** | **~357** | — | **3-5 个工作日** |

---

## 十、平台差异

| 维度 | Windows MSVC2015 | Linux GCC ≥ 5 |
|------|:---:|:---:|
| C++14 支持 | ✅ 完整 | ✅ 完整 |
| 继承构造函数 | ✅ | ✅ |
| optional.hpp | ✅（`_MSC_VER >= 1900`） | ✅（GCC 4.8+ 通过） |
| variant.hpp | ⚠️ 需 **Update 3** | ✅（`__cplusplus >= 201103L`） |
| Qt API 改动 | 与 Linux 相同 | 与 Windows 相同 |
| 额外注意 | 确保不是 RTM/Update1/2 | 确保 GCC ≥ 5（C++14 完整支持） |

**两个平台共享完全相同的 Qt API 改动集。** MSVC2015 唯一额外要求是确认 Update 3。

---

## 十一、实施步骤（推荐顺序）

### 第一步：构建环境准备
1. 确认 MSVC2015 为 **Update 3**（`cl.exe` 版本 ≥ 19.00.24210）
2. 确认 Linux GCC ≥ 5.0
3. 确认 Qt 5.6.3 安装完整（含所有 modules）

### 第二步：Polyfill 注入（消除 70% 工作量）
4. 创建 `src/libs/utils/qt56compat.h`（第七节内容）
5. 在 `src/libs/utils/utils.pri` 中添加到 `HEADERS`
6. 在使用 `qAsConst`/`Q_FALLTHROUGH` 的文件中确认 include 路径可达（utils 库被全项目依赖，通常自动可达）

### 第三步：版本门槛修改
7. 修改 `qtcreator.pro` 第 4 行版本检查

### 第四步：QOverload 脚本替换
8. 编写替换脚本处理 212 文件 322 处
9. 验证替换结果无语法错误

### 第五步：手工修改少量文件
10. 修改 7 个 `QStringView` 文件
11. 修改 4 个 `QCborValue` 文件（3rdparty/syntax-highlighting）
12. 修改 1 个 `QOperatingSystemVersion` 文件
13. 修改 1 个 `QT_CONFIG` 文件

### 第六步：编译验证
14. Windows qmake 全量构建 + 修复残留
15. Linux qmake 全量构建 + 修复残留

---

## 十二、可行性结论

### 评定：高度可行

| 维度 | 评分 | 说明 |
|------|:---:|------|
| C++ 兼容性 | ★★★★★ | MSVC2015 + GCC5 完整支持 C++14，零代码改动 |
| Qt API 兼容性 | ★★★☆☆ | 6 个小版本差距，但大部分可 polyfill 消除 |
| 3rdparty 库 | ★★★★☆ | optional 直接通过，variant 需 Update 3 |
| 工作量 | ★★★★☆ | 3-5 个工作日，无结构性重写 |
| 风险 | ★★★★☆ | 改动均为表面 API 替换，不涉及逻辑变更 |

### 与 Qt 5.5.1 + MSVC2013 对比

| 对比项 | Qt 5.5.1 + MSVC2013 | **Qt 5.6.3 + MSVC2015** |
|--------|:---:|:---:|
| C++ 改动量 | ~1100 处（C++14→C++11 降级） | **0 处** |
| Qt API 改动量 | ~520 处 | **~357 处** |
| 总改动文件 | ~450 | **~227** |
| 预计工时 | 10-17 天 | **3-5 天** |
| 可行性 | 有条件可行（大量工作） | **高度可行** |

**升级编译器从 MSVC2013 → MSVC2015 消除了全部 C++ 层面障碍，将工作量降低约 70%。**
