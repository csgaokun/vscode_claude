# Qt Creator 6.0.2 — C++17 特性使用审计报告

**审核范围**: `qt-creator-opensource-src-6.0.2/src/` 目录（排除 `shared/qbs/`、`3rdparty/`、`tests/`）  
**生成日期**: 2026-04-02

---

## 总览

| # | C++17 特性 | 使用文件数 | 采用程度 |
|---|-----------|-----------|---------|
| 1 | `optional<` (Utils::optional / std::optional) | ~186 | ★★★★★ 广泛使用 |
| 2 | `namespace A::B` 嵌套命名空间 | ~88 | ★★★★☆ 大量使用 |
| 3 | `variant<` (Utils::variant) | ~34 | ★★★☆☆ 中等使用 |
| 4 | 结构化绑定 (`auto [x, y]`) | ~12 | ★★☆☆☆ 少量使用 |
| 5 | `if constexpr` | ~5 | ★☆☆☆☆ 少量使用 |
| 6 | `[[nodiscard]]` | ~5 | ★☆☆☆☆ 少量使用 |
| 7 | `inline static` / `inline constexpr` 变量（头文件中） | ~5 | ★☆☆☆☆ 少量使用 |
| 8 | `std::string_view` | ~2 | ★☆☆☆☆ 极少使用 |
| 9 | `std::filesystem` | 1 | ★☆☆☆☆ 极少使用 |
| 10 | 折叠表达式 (Fold expressions) | ~3-5（真正的折叠表达式） | ★☆☆☆☆ 少量使用 |
| 11 | `[[maybe_unused]]` | 0 | 未使用 |
| 12 | `std::any` | 0 | 未使用 |
| 13 | 类模板参数推导 (CTAD) / 推导指南 | 0（仅3rdparty span库中有） | 未使用 |

---

## 1. `optional<` — Utils::optional / std::optional

**文件数**: ~186 个文件  
**采用方式**: 通过 `Utils::optional` 包装器间接使用 `std::optional`

### 包装机制

`src/libs/utils/optional.h` 提供了一个兼容性层：
- **非 Apple 平台**: 直接 `using std::optional`（来自 `<optional>` 头文件）
- **Apple 平台** (macOS < 10.14): 回退到 `std::experimental::optional`（来自 `3rdparty/optional/optional.hpp`）

代码注释明确指出：
> `// TODO: Use std::optional everywhere when we can require macOS 10.14`

### 示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/plugins/docker/dockerplugin.h` | L42-43 | `static Utils::optional<bool> isDaemonRunning()` |
| `src/plugins/coreplugin/documentmanager.cpp` | L1138 | `optional<IDocument::ChangeType> type;` |
| `src/plugins/coreplugin/editormanager/documentmodel.h` | L77 | `static Utils::optional<int> rowOfDocument(IDocument *document);` |
| `src/plugins/clangtools/clangtoolslogfilereader.h` | L52 | `using OptionalLineColumnInfo = Utils::optional<LineColumnInfo>;` |
| `src/plugins/compilationdatabaseprojectmanager/compilationdatabaseutils.cpp` | L114-115 | `Utils::optional<HeaderPathType> includePathType;` |

---

## 2. 嵌套命名空间 (`namespace A::B`)

**文件数**: ~88 个文件  
**说明**: C++17 允许 `namespace A::B::C {` 替代嵌套的 `namespace A { namespace B { namespace C {`。该特性在 **CppEditor 插件** 中被大量采用。

### 示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/plugins/cppeditor/typehierarchybuilder.h` | L44 | `namespace CppEditor::Internal {` |
| `src/plugins/cppeditor/doxygengenerator.cpp` | L45 | `namespace CppEditor::Internal {` |
| `src/plugins/cppeditor/followsymbol_switchmethoddecldef_test.h` | L30 | `namespace CppEditor::Internal::Tests {` (三级嵌套) |
| `src/plugins/cppeditor/stringtable.h` | L30 | `namespace CppEditor::Internal {` |
| `src/plugins/cppeditor/builtinindexingsupport.cpp` | — | `namespace CppEditor::Internal {` |

> **注意**: 此特性几乎仅限于 `cppeditor` 插件使用，其他模块仍使用传统嵌套方式。

---

## 3. `variant<` — Utils::variant

**文件数**: ~34 个文件  
**采用方式**: 通过 `Utils::variant` 包装器间接使用 `std::variant`

### 包装机制

`src/libs/utils/variant.h` 提供兼容性层：
- **非 Apple 平台**: 直接 `using std::variant` 及相关工具（`std::visit`, `std::get`, `std::holds_alternative` 等）
- **Apple 平台**: 回退到 `mpark::variant`（来自 `3rdparty/variant/variant.hpp`，Michael Park 的 C++17 variant 兼容实现）

### 示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/libs/languageserverprotocol/clientcapabilities.cpp` | — | variant 用于 LSP 协议消息类型 |
| `src/libs/languageserverprotocol/completion.h` | — | variant 用于补全项的多态参数 |
| `src/libs/languageserverprotocol/jsonobject.h` | — | variant 用于 JSON 值表示 |

---

## 4. 结构化绑定 (`auto [x, y]`)

**文件数**: ~12 个文件  
**说明**: 用于解构 `std::pair`、`std::tuple` 及自定义结构体的返回值。

### 示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/plugins/languageclient/languageclientsettings.cpp` | L683 | `auto [stdioSettings, typedSettings] = Utils::partition(...)` |
| `src/plugins/clangtools/documentclangtoolrunner.cpp` | L252 | `auto [clangIncludeDir, clangVersion] = getClangIncludeDirAndVersion(...)` |
| `src/plugins/texteditor/semantichighlighter.cpp` | L89 | `for (const auto &[newResult, newBlock] : splitter(...))` |
| `src/plugins/cppeditor/cppquickfixes.cpp` | L8007 | `for (auto &[_, node] : includeGraph)` |
| `src/plugins/qmldesigner/designercore/imagecache/synchronousimagecache.cpp` | L57 | `const auto &[image, smallImage] = m_collector.createImage(...)` |

---

## 5. `if constexpr`

**文件数**: ~5 个文件  
**说明**: 用于编译期条件分支，主要出现在模板代码和平台判断中。

### 示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/plugins/android/javalanguageserver.cpp` | L137-141 | `if constexpr (HostOsInfo::hostOs() == OsTypeWindows)` — 编译期平台选择 |
| `src/libs/sqlite/createtablesqlstatementbuilder.h` | L107 | `if constexpr (std::is_same_v<ColumnType, ::Sqlite::ColumnType>)` |
| `src/libs/sqlite/sqlitevalue.h` | L119 | `if constexpr (std::is_same_v<BlobType, Blob>)` |
| `src/libs/utils/singleton.h` | L73 | `if constexpr (sizeof...(Dependencies))` |
| `src/libs/sqlite/sqlitecolumn.h` | L60 | `if constexpr (std::is_same_v<ColumnType, ::Sqlite::ColumnType>)` |

---

## 6. `[[nodiscard]]` 属性

**文件数**: ~5 个文件  
**说明**: 主要在 `Utils::FilePath` 类中大量使用，作为返回值不可忽略的标记。

### 示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/libs/utils/filepath.h` | L61-157 | 几乎所有 `FilePath` 的工厂方法和转换方法都标记了 `[[nodiscard]]`（约30+处） |
| `src/plugins/studiowelcome/algorithm.h` | L35, L47, L57 | `[[nodiscard]]` 标记在 `findOptional()`、`filterOut()`、`filtered()` 等算法函数上 |
| `src/plugins/cppeditor/cppquickfixprojectsettings.h` | L51 | `[[nodiscard]] bool useCustomSettings()` |

---

## 7. `inline` 变量（头文件中的 `inline static`）

**文件数**: ~5 个头文件  
**说明**: C++17 的 `inline` 变量允许在头文件中直接定义静态成员变量，避免在 .cpp 文件中提供定义。

### 示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/plugins/coreplugin/dialogs/newdialog.h` | L59 | `inline static NewDialog *m_currentDialog = nullptr;` |
| `src/plugins/qmldesigner/components/itemlibrary/itemlibrarywidget.h` | L98 | `inline static bool isHorizontalLayout = false;` |
| `src/plugins/qmldesigner/components/itemlibrary/itemlibrarywidget.h` | L164 | `inline static int HORIZONTAL_LAYOUT_WIDTH_LIMIT = 600;` |
| `src/plugins/qmldesigner/components/itemlibrary/itemlibrarymodel.h` | L96, L124, L125 | `inline static QHash<...> categorySortingHash;` 等多个 |
| `src/plugins/qmldesigner/components/itemlibrary/itemlibraryassetsmodel.h` | L106 | `inline static QHash<QString, bool> m_expandedStateHash;` |

---

## 8. `std::string_view`

**文件数**: ~2 个文件（排除 3rdparty 和 shared/qbs 后）  
**说明**: Qt Creator 自身代码几乎不直接使用 `std::string_view`，而是通过自有的 `SmallStringView` 类来封装。

### 示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/libs/utils/smallstringview.h` | L49 | `class SmallStringView : public std::string_view` — 继承自 `std::string_view` |
| `src/plugins/qmldesigner/designercore/projectstorage/qmldocumentparser.cpp` | — | 间接使用 |

> **注意**: `SmallStringView` 直接继承 `std::string_view` 并复用其构造函数（`using std::string_view::string_view`），说明项目依赖 C++17 的 `<string_view>` 头文件。

---

## 9. `std::filesystem`

**文件数**: 1 个文件（排除 shared/qbs 后）  
**说明**: 在核心代码中极少使用，Qt Creator 更多依赖 `QDir`/`QFileInfo` 等 Qt 文件系统 API。

### 示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/plugins/qmldesigner/designercore/projectstorage/qmldocumentparser.cpp` | L59-62 | `std::filesystem::path path{...}; auto x = std::filesystem::weakly_canonical(path);` |

---

## 10. 折叠表达式 (Fold Expressions)

**文件数**: ~3-5 个文件（真正的 C++17 折叠表达式）  
**说明**: 折叠表达式用于展开参数包，形如 `(expr, ...)` 或 `(... && expr)`。

### 确认的折叠表达式示例

| 文件 | 行号 | 用法 |
|------|------|------|
| `src/libs/utils/singleton.h` | L95 | `static_assert ((... && std::is_base_of_v<Singleton, Dependency>), ...)` — 一元左折叠 |
| `src/libs/utils/singleton.h` | L97 | `(..., Dependency::instance());` — 逗号折叠表达式 |
| `src/libs/sqlite/sqlitebasestatement.h` | L182 | `(BaseStatement::bind(++index, values), ...);` — 逗号折叠表达式 |

---

## 11. `[[maybe_unused]]`

**文件数**: 0  
**说明**: 在核心源码中未找到任何 `[[maybe_unused]]` 属性的使用。项目可能使用 `Q_UNUSED()` 宏作为替代方案。

---

## 12. `std::any`

**文件数**: 0  
**说明**: 未找到 `std::any` 的使用（仅发现大量 `std::any_of` 算法调用，这是 C++11 特性）。

---

## 13. 类模板参数推导 (CTAD) / 推导指南

**文件数**: 0（项目自身代码中无使用）  
**说明**:
- 3rdparty 的 `span.hpp` 中有推导指南定义（通过 `__cpp_deduction_guides` 宏条件编译）
- `src/plugins/cppeditor/compileroptionsbuilder.cpp` L598 定义了 `__cpp_deduction_guides` 宏供 Clang 模型使用
- 但 Qt Creator 自身代码中未使用 CTAD

---

## 14. 其他 C++17 相关特性

### `std::is_same_v` / `std::is_base_of_v` (变量模板)
虽非本次审计重点，但 `if constexpr` 示例中频繁搭配使用了 C++17 的 `_v` 后缀变量模板（如 `std::is_same_v` 替代 `std::is_same<>::value`）。

### `constexpr` lambda
未发现明确的 `constexpr` lambda 使用。

---

## C++17 兼容性层总结

| 包装文件 | C++17 标准类型 | Apple 回退 | 命名空间 |
|----------|---------------|-----------|---------|
| `src/libs/utils/optional.h` | `std::optional` | `std::experimental::optional` (3rdparty/optional) | `Utils::optional` |
| `src/libs/utils/variant.h` | `std::variant` | `mpark::variant` (3rdparty/variant) | `Utils::variant` |

**关键设计决策**: Qt Creator 6.0.2 通过 `Utils` 命名空间的别名层来抽象 C++17 类型，主要是为了兼容 Apple Clang 在 macOS < 10.14 上不支持 `std::bad_optional_access` 的问题。一旦可以要求 macOS 10.14+，这些包装将被移除（源码中有 TODO 注释）。

---

## 结论

Qt Creator 6.0.2 的 C++17 采用呈**保守+渐进**策略：
1. **深度采用**: `optional` 和 `variant`（通过兼容层包装，186+34 个文件）
2. **广泛但局部**: 嵌套命名空间（88个文件，集中在 cppeditor）
3. **选择性采用**: 结构化绑定、`if constexpr`、`[[nodiscard]]`、inline 变量（各5-12个文件）
4. **极少或未使用**: `std::filesystem`、`std::string_view`（直接使用）、`[[maybe_unused]]`、`std::any`、CTAD、折叠表达式
