# Qt Creator 4.13.3 — MSVC2013 C++11/14/17 兼容性审计报告

**审计范围**: `qt-creator-opensource-src-4.13.3/src/`  
**日期**: 2026-04-02  
**目标**: 识别 MSVC2013 (_MSC_VER=1800) 无法编译或行为异常的 C++ 特性

---

## 摘要

| # | 特性 | 风险等级 | 匹配数 | 是否阻塞编译 |
|---|------|---------|--------|-------------|
| 1 | noexcept(expr) 表达式 | 🟡 中 | ~73 | 可能 (3rdparty 集中) |
| 2 | Expression SFINAE | 🟡 中 | ~20+ | 可能 (3rdparty 集中) |
| 3 | constexpr 构造函数/复杂用法 | 🟡 中 | 200+ | 部分 |
| 4 | **继承构造函数 (using Base::Base)** | 🔴 高 | **~100+** | **是** |
| 5 | thread_local | 🟢 低 | 0 (实际代码) | 否 (仅 parser/token 定义) |
| 6 | alignas/alignof | 🟢 低 | ~2 | 否 (仅注释/宏) |
| 7 | char16_t/char32_t | 🟢 低 | ~20 | 否 (仅 token/字符串比较) |
| 8 | **用户定义字面量 operator""** | 🟡 中 | 3 (实际定义) | 需要修改 |
| 9 | Utils::optional (3rdparty polyfill) | 🟡 中 | 200+ | 依赖 optional.hpp 兼容性 |
| 10 | Utils::variant (3rdparty polyfill) | 🔴 高 | **85+** | 依赖 mpark::variant 兼容性 |
| 11 | if constexpr | 🟢 低 | 0 | 否 (仅 parser 注释) |
| 12 | 结构化绑定 auto [...] | 🟢 低 | 0 | 否 |
| 13 | 嵌套命名空间 namespace A::B | 🟢 低 | 0 (声明形式) | 否 |
| 14 | std::any | 🟢 低 | 0 (仅 std::any_of) | 否 |
| 15 | constexpr17/constexpr20 宏守卫 | ✅ 已处理 | — | 已有降级宏 |
| 16 | 编译器/版本守卫 | ✅ 已有 | 200+ | 代码已含 _MSC_VER 守卫 |

---

## 详细分析

### 1. noexcept(expr) — noexcept 表达式 (🟡 中风险)

**匹配数**: 73  
**MSVC2013 状态**: 支持但有 bug，复杂嵌套 noexcept(noexcept(...)) 可能失败

**分布**:
- **3rdparty 库** (占绝大多数):
  - `libs/3rdparty/variant/variant.hpp` — ~22 处，大量 `noexcept(noexcept(...))` 嵌套
  - `libs/3rdparty/optional/optional.hpp` — ~12 处
  - `libs/3rdparty/json/json.hpp` — ~14 处
- **项目代码**:
  - `libs/utils/smallstringvector.h` — 1 处
  - `libs/sqlite/sqlitetransaction.h` — 2 处 (`noexcept(false)`)
  - `plugins/cppeditor/cppquickfix_test.cpp` — 3 处 (测试字符串,非编译代码)

**建议**: 3rdparty 库内部问题，需评估 mpark::variant 和 experimental::optional 对 MSVC2013 的支持。项目代码影响很小。

---

### 2. Expression SFINAE (🟡 中风险)

**MSVC2013 状态**: 根本性缺陷 (broken)。`decltype(expr)` 在模板参数推导中失败。

**涉及文件**:
- `libs/3rdparty/variant/variant.hpp` — 大量使用 `decltype(...)`, `std::enable_if`
- `libs/3rdparty/json/json.hpp` — 大量 SFINAE
- `libs/3rdparty/optional/optional.hpp` — 使用 expression SFINAE
- `libs/utils/functiontraits.h` — 使用 `decltype(&Callable::operator())`，并且代码中已有注释:
  ```cpp
  static const unsigned arity = sizeof...(Args); // TODO const -> constexpr with MSVC2015
  ```
  *注*: 该文件注释表明开发者已知 MSVC 限制，但仍使用了 `decltype` 模式。

**影响**: 主要集中在 3rdparty 库 (variant, optional, json) 的内部实现中。这些库如果不支持 MSVC2013 则是阻塞性问题。

---

### 3. constexpr 构造函数/复杂用法 (🟡 中风险)

**匹配数**: 200+ (截断)  
**MSVC2013 状态**: 支持基本 constexpr，但不支持 C++14 relaxed constexpr、constexpr 成员函数内多语句等

**高风险用例**:

| 文件 | 用法类型 | 备注 |
|------|---------|------|
| `libs/utils/smallstringlayout.h` | constexpr 构造函数带参数赋值 | 多语句 constexpr 构造函数 |
| `libs/utils/smallstringview.h` | constexpr 成员函数 | ~20处，含分支逻辑 |
| `libs/utils/smallstringiterator.h` | constexpr 运算符重载 | ~20处 |
| `libs/utils/smallstring.h` | constexpr 构造函数 | 复杂初始化 |
| `libs/utils/hostosinfo.h` | static constexpr 成员函数 | 含 if 分支 — 可能需要 relaxed constexpr |
| `libs/utils/sizedarray.h` | constexpr 构造函数和方法 | |
| `libs/clangsupport/*.h` | constexpr 默认构造函数 | `constexpr Xxx() = default;` |
| `plugins/coreplugin/command.h` | constexpr 变量调用 constexpr 函数 | `constexpr bool useMacShortcuts = Utils::HostOsInfo::isMacHost();` |

**注意**: `smallstringfwd.h` 中已有降级宏:
```cpp
#if __cplusplus >= 201703L
#define constexpr17 constexpr
#else
#define constexpr17 inline
#endif
```
但这仅基于 `__cplusplus`，不处理 MSVC2013 的基础 constexpr 限制。

---

### 4. 继承构造函数 using Base::Base (🔴 高风险 — 编译阻塞)

**匹配数**: ~100+  
**MSVC2013 状态**: **完全不支持**。这是最严重的阻塞项。

**关键受影响文件/库**:

#### languageserverprotocol 库 (最大影响 — ~70+ 处):
| 文件 | 继承构造函数数量 |
|------|----------------|
| `libs/languageserverprotocol/languagefeatures.h` | ~40+ (`using JsonObject::JsonObject`, `using Request::Request`, `using variant::variant` 等) |
| `libs/languageserverprotocol/workspace.h` | ~20+ |
| `libs/languageserverprotocol/textsynchronization.h` | ~15 |
| `libs/languageserverprotocol/servercapabilities.h` | ~15 |
| `libs/languageserverprotocol/lsptypes.h` | ~15 |
| `libs/languageserverprotocol/client.h` | ~5 |
| `libs/languageserverprotocol/messages.h` | ~5 |
| `libs/languageserverprotocol/lsputils.h` | `using Utils::variant<...>::variant;` |
| `libs/languageserverprotocol/completion.h` | ~3 |
| `libs/languageserverprotocol/shutdownmessages.h` | 2 |
| `libs/languageserverprotocol/initializemessages.h` | 通过基类间接依赖 |

#### sqlite 库:
| 文件 | 模式 |
|------|------|
| `libs/sqlite/sqlitebasestatement.h` | `using BaseStatement::BaseStatement;` |
| `libs/sqlite/sqlitevalue.h` | `using Base::Base;` |
| `libs/sqlite/sqlstatementbuilderexception.h` | `using Exception::Exception;` |
| `libs/sqlite/sqlitereadstatement.h` | (间接) |
| `libs/sqlite/sqlitewritestatement.h` | (间接) |
| `libs/sqlite/sqlitereadwritestatement.h` | (间接) |

#### utils 库:
| 文件 | 模式 |
|------|------|
| `libs/utils/smallstringvector.h` | `using Base::Base;` |
| `libs/utils/environment.h` | `using NameValueDictionary::NameValueDictionary;` |

#### clangsupport 库:
| 文件 | 模式 |
|------|------|
| `libs/clangsupport/projectpartstoragestructs.h` | `using Base::Base;` |
| `libs/clangsupport/filepathstoragesources.h` | `using Base::Base;` (2 处) |

#### 其他:
| 文件 | 模式 |
|------|------|
| `libs/advanceddockingsystem/dockingstatereader.h` | `using QXmlStreamReader::QXmlStreamReader;` |
| `tools/clangpchmanagerbackend/source/collectusedmacrosandsourcespreprocessorcallbacks.h` | `using CollectUsedMacrosAndSourcesPreprocessorCallbacksBase::CollectUsedMacrosAndSourcesPreprocessorCallbacksBase;` |

**修复策略**: 每个 `using Base::Base;` 需替换为显式构造函数转发:
```cpp
// 原始
using JsonObject::JsonObject;

// MSVC2013 兼容
ClassName(const QJsonObject &obj) : JsonObject(obj) {}
ClassName(const QJsonValue &val) : JsonObject(val) {}
// ... 逐一转发每个基类构造函数
```

---

### 5. thread_local (🟢 低风险)

**匹配数**: 0 个实际使用  
**分析**: 所有匹配均为 C++ parser/lexer 中的 token 定义 (`T_THREAD_LOCAL`)，以及 `qmljsast.cpp` 中关于 gcc bug 的注释。项目代码本身不使用 `thread_local`。

---

### 6. alignas/alignof (🟢 低风险)

**匹配数**: 2  
- `cplusplus/MatchingText.cpp` — 仅注释: "This does not handle alignas()"
- `qbs/.../Vector.h` — 使用 `__alignof` (MSVC 兼容的替代方案)

**分析**: 无实际阻塞。

---

### 7. char16_t/char32_t (🟢 低风险)

**匹配数**: ~20  
**分析**: 所有匹配均为 C++ parser/token 系统中的字符串比较和 token 定义，以及测试数据。项目不直接使用 `char16_t`/`char32_t` 类型声明变量。无编译阻塞。

---

### 8. 用户定义字面量 operator"" (🟡 中风险)

**匹配数**: 3 个实际定义  
**MSVC2013 状态**: 有限支持

| 文件 | 字面量 | 用途 |
|------|--------|------|
| `libs/utils/smallstringview.h:239` | `operator""_sv` | SmallStringView 字面量，项目代码使用 |
| `libs/3rdparty/json/json.hpp:20793` | `operator""_json` | JSON 字面量，3rdparty |
| `libs/3rdparty/json/json.hpp:20811` | `operator""_json_pointer` | JSON pointer 字面量，3rdparty |

**建议**: `operator""_sv` 需要验证 MSVC2013 兼容性或提供替代方案。

---

### 9. Utils::optional — 基于 3rdparty polyfill (🟡 中风险)

**匹配数**: 200+  
**实现**: 使用 `libs/3rdparty/optional/optional.hpp` (std::experimental::optional polyfill)

**架构**: `utils/optional.h` 是轻量包装层:
```cpp
#include <3rdparty/optional/optional.hpp>
namespace Utils {
using std::experimental::optional;
using std::experimental::nullopt;
}
```

**广泛使用区域**:
- `libs/languageserverprotocol/` — 大量使用 `Utils::optional`
- `libs/utils/` — archive.cpp, environmentdialog.h 等
- `tools/clangrefactoringbackend/` — 多处使用
- `plugins/` — coreplugin, texteditor, languageclient 等
- `app/main.cpp` — `Utils::optional<QString> userLibraryPath;`

**风险**: optional.hpp (3rdparty) 内部使用了 `noexcept(expr)` 和 expression SFINAE。如果该库不支持 MSVC2013，则全部 200+ 使用点都会受影响。

---

### 10. Utils::variant — 基于 mpark::variant (🔴 高风险)

**匹配数**: 85+  
**实现**: C++17 下使用 `std::variant`，否则使用 `libs/3rdparty/variant/variant.hpp` (mpark::variant)

**架构**: `utils/variant.h`:
```cpp
#if __cplusplus >= 201703L
  using std::variant;  // C++17
#else
  using mpark::variant; // polyfill
#endif
```

**关键风险**: `variant.hpp` 内部:
- 大量 `noexcept(noexcept(...))` 嵌套
- 大量 expression SFINAE (`decltype`, `std::enable_if`)
- 已有 `_MSC_VER` 守卫 (检查 `_MSC_VER < 1910`、`_MSC_VER < 1915` 等)
- **variant.hpp line 221**: `#if __cplusplus < 201103L && (!defined(_MSC_VER) || _MSC_FULL_VER < 190024210)` — 要求至少 MSVC2015 Update 3

**使用最密集的区域**:
- `libs/languageserverprotocol/` — 大量使用 `Utils::variant<>` 作为类基类
- `libs/sqlite/` — `sqlitevalue.h`, `constraints.h`, `tableconstraints.h`
- `plugins/clangtools/` — `clangtool.h`
- `plugins/coreplugin/` — `fileiconprovider.cpp`
- `plugins/languageclient/` — `client.cpp`, `languageclientquickfix.cpp`

**阻塞性评估**: mpark::variant **不支持 MSVC2013**。代码中的 `_MSC_VER` 守卫明确排除了低于 MSVC2015 的版本。

---

### 11-14. C++17 特性 (🟢 低风险 — 均未使用)

| 特性 | 搜索结果 |
|------|---------|
| `if constexpr` | 0 (仅 parser 注释) |
| 结构化绑定 `auto [...]` | 0 |
| 嵌套命名空间 `namespace A::B {}` | 0 (仅 `using namespace A::B;` 形式) |
| `std::any` | 0 (仅 `std::any_of` 算法调用) |

---

### 15. constexpr17/constexpr20 降级宏 (✅ 已处理)

`libs/utils/smallstringfwd.h` 定义了:
```cpp
#if __cplusplus >= 201703L
#define constexpr17 constexpr
#else
#define constexpr17 inline  // 降级为 inline
#endif
```

**注意**: 该守卫基于 `__cplusplus` 宏。MSVC2013 的 `__cplusplus` 报告为 `199711L`（即使实际支持部分 C++11），所以 `constexpr17` 会正确降级为 `inline`。但是，代码中大量直接使用的 `constexpr`（非 `constexpr17`）不受此宏保护。

---

### 16. 现有编译器/版本守卫 (✅ 代码中已有)

**匹配数**: 200+ (包含 3rdparty)

**项目代码中的关键守卫**:

| 文件 | 守卫 | 用途 |
|------|------|------|
| `plugins/coreplugin/icore.cpp` | `#elif defined(Q_CC_MSVC)` + `_MSC_VER` 范围检测 | MSVC 版本显示 |
| `shared/proparser/qmakeevaluator.cpp` | `#if defined(Q_CC_MSVC)` | MSVC 特定代码路径 |
| `shared/proparser/proitems.h` | `#ifdef Q_CC_MSVC` | MSVC 特定声明 |
| `plugins/clangtools/.../main.cpp` | `#if defined(_MSC_VER) && _MSC_VER > 1800` | 排除 MSVC2013 |
| `plugins/cpptools/symbolfinder.cpp` | `#if defined(_MSC_VER)` | MSVC 特定 |
| `libs/advanceddockingsystem/floatingdockcontainer.cpp` | `#ifdef _MSC_VER` | MSVC 特定 |

**3rdparty 库中的守卫 (对 MSVC2013 有影响)**:
| 库 | 守卫 | 含义 |
|----|------|------|
| `variant.hpp` | `_MSC_FULL_VER < 190024210` | **要求至少 MSVC2015 Update 3** |
| `variant.hpp` | `_MSC_VER < 1910` | 针对 MSVC2015 的 workaround |
| `optional.hpp` | `_MSC_VER >= 1900` | **要求至少 MSVC2015** |
| `json.hpp` | `_MSC_VER` | 运行时探测 MSVC |
| `span.hpp` | `_MSC_VER > 1900` | **要求高于 MSVC2015** |

---

## 阻塞性总结

### 🔴 编译阻塞项 (必须修复)

1. **继承构造函数** (`using Base::Base;`) — ~100+ 处，主要在 `languageserverprotocol` 和 `sqlite` 库
2. **mpark::variant (3rdparty)** — 明确要求 MSVC2015+，影响 85+ 使用点
3. **experimental::optional (3rdparty)** — 可能要求 MSVC2015+，影响 200+ 使用点
4. **tcb::span (3rdparty)** — 要求高于 MSVC2015

### 🟡 可能需要修复

5. **constexpr** — 大量使用 (200+)，MSVC2013 的 constexpr 限制可能导致部分编译失败
6. **用户定义字面量** — 3 处定义，MSVC2013 支持有限
7. **functiontraits.h** — 使用 `decltype` 的 expression SFINAE 模式

### 🟢 无需修改

8. thread_local, alignas/alignof, char16_t/char32_t — 项目代码不使用
9. if constexpr, 结构化绑定, 嵌套命名空间, std::any — 项目不使用
10. constexpr17/constexpr20 宏 — 已有降级机制

---

## 工作量估算

| 类别 | 文件数 | 修改点 | 难度 |
|------|--------|--------|------|
| 继承构造函数替换 | ~25 文件 | ~100+ 处 | 高 (需理解每个基类的构造函数签名) |
| 3rdparty variant 替换/降级 | 1 核心 + 85 使用点 | — | 极高 (需完全替代 mpark::variant) |
| 3rdparty optional 替换/降级 | 1 核心 + 200 使用点 | — | 极高 (需完全替代 experimental::optional) |
| constexpr 降级 | ~30 文件 | ~200 处 | 中 (可用 const/inline 替换) |
| 用户定义字面量 | 1 文件 | 1 处 | 低 |

**结论**: 将 Qt Creator 4.13.3 适配到 MSVC2013 面临极大挑战。核心阻塞在于 3rdparty 的 variant/optional polyfill 库明确不支持 MSVC2013，以及继承构造函数的广泛使用。建议优先评估是否可以用更低版本的 variant/optional polyfill 替代，或将最低编译器要求提升到 MSVC2015。
