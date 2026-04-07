# Qt Creator 4.13.3 — CMakeProjectManager / QbsProjectManager 全量引用审计报告

> 审计日期: 2026-04-02
> 源码路径: `qt-creator-opensource-src-4.13.3/src/`
> 审计目标: 找出 cmakeprojectmanager/ 和 qbsprojectmanager/ 以外的**所有**引用，评估删除这两个插件目录后能否编译通过

---

## 一、总结概览

| 类别 | CMakeProjectManager 引用 | QbsProjectManager 引用 |
|------|--------------------------|------------------------|
| 硬依赖（#include 头文件） | 5 个文件 | 1 个文件 |
| 构建系统依赖（_dependencies.pri） | 2 个插件 | 2 个插件 |
| 构建系统子项目入口（plugins.pro） | 1 处 | 1 处 |
| CMakeLists.txt 依赖声明 | 2 个插件 | 0 |
| 字符串常量/注释（软引用） | 多处 | 多处 |

**结论：不能直接删除这两个目录。必须同时修改 5 个外部插件（mcusupport、projectexplorer、incredibuild、clangtools、autotest）和构建入口文件。**

---

## 二、硬依赖 — #include 引用（会导致编译错误）

### 2.1 引用 cmakeprojectmanager/ 头文件的外部文件

#### (A) projectexplorer/desktoprunconfiguration.cpp (L34-35)
```cpp
#include <cmakeprojectmanager/cmakeprojectconstants.h>   // L34
#include <qbsprojectmanager/qbsprojectmanagerconstants.h> // L35
```
- **依赖类型**: **硬依赖** — 使用了 `CMakeProjectManager::Constants::CMAKE_PROJECT_ID` 和 `QbsProjectManager::Constants::PROJECT_ID`
- **影响范围**: `CMakeRunConfigurationFactory` 和 `QbsRunConfigurationFactory` 类（L196-206）直接引用这些常量
- **对应头文件**: desktoprunconfiguration.h (L40-49) 声明了 `QbsRunConfigurationFactory` 和 `CMakeRunConfigurationFactory` 类

#### (B) projectexplorer/simpleprojectwizard.cpp (L35)
```cpp
#include <cmakeprojectmanager/cmakeprojectconstants.h>   // L35
```
- **依赖类型**: **硬依赖** — 使用了 `CMakeProjectManager::Constants::CMAKE_PROJECT_ID`（L171）
- **影响范围**: 简单项目向导里添加 cmake 项目类型支持

#### (C) mcusupport/mcusupportrunconfiguration.cpp (L36-37)
```cpp
#include <cmakeprojectmanager/cmakekitinformation.h>     // L36
#include <cmakeprojectmanager/cmaketool.h>               // L37
```
- **依赖类型**: **硬依赖** — 调用 `CMakeProjectManager::CMakeKitAspect::cmakeTool()`、`CMakeProjectManager::CMakeTool` 等 API
- **影响范围**: MCU flash/run 功能核心依赖

#### (D) mcusupport/mcusupportoptionspage.cpp (L30-31)
```cpp
#include <cmakeprojectmanager/cmakeprojectconstants.h>   // L30
#include <cmakeprojectmanager/cmaketoolmanager.h>        // L31
```
- **依赖类型**: **硬依赖** — 使用 `CMakeProjectManager::Constants::CMAKE_SETTINGS_PAGE_ID`（L95）和 `CMakeProjectManager::CMakeToolManager::cmakeTools()`（L165）

#### (E) mcusupport/mcusupportoptions.cpp (L30, L33)
```cpp
#include <cmakeprojectmanager/cmaketoolmanager.h>        // L30
#include <cmakeprojectmanager/cmakekitinformation.h>     // L33
```
- **依赖类型**: **硬依赖** — MCU Kit 创建时需要 CMake 工具信息

### 2.2 引用 qbsprojectmanager/ 头文件的外部文件

#### (A) projectexplorer/desktoprunconfiguration.cpp (L35)
```cpp
#include <qbsprojectmanager/qbsprojectmanagerconstants.h> // L35
```
- **依赖类型**: **硬依赖** — 使用了 `QbsProjectManager::Constants::PROJECT_ID`（L206）

---

## 三、构建系统依赖 — _dependencies.pri 文件

### 3.1 引用 cmakeprojectmanager 的 _dependencies.pri

| 文件 | 行号 | 依赖类型 | 内容 |
|------|------|----------|------|
| `mcusupport/mcusupport_dependencies.pri` | L11 | **QTC_PLUGIN_DEPENDS**（强依赖） | `cmakeprojectmanager \` |
| `incredibuild/incredibuild_dependencies.pri` | L10 | **QTC_PLUGIN_RECOMMENDS**（推荐依赖） | `cmakeprojectmanager` |

### 3.2 引用 qbsprojectmanager 的 _dependencies.pri

| 文件 | 行号 | 依赖类型 | 内容 |
|------|------|----------|------|
| `clangtools/clangtools_dependencies.pri` | L15 | **QTC_TEST_DEPENDS**（仅测试依赖） | `qbsprojectmanager \` |
| `autotest/autotest_dependencies.pri` | L17 | **QTC_TEST_DEPENDS**（仅测试依赖） | `qbsprojectmanager \` |

---

## 四、构建入口 — plugins.pro

### 4.1 CMakeProjectManager (L28)
```qmake
    cmakeprojectmanager \               # L28 — 无条件 SUBDIRS
```
- **类型**: **构建入口** — 无条件编译，直接删目录会导致 qmake 报找不到子目录

### 4.2 QbsProjectManager (L110-114)
```qmake
isEmpty(QBS_INSTALL_DIR): QBS_INSTALL_DIR = $$(QBS_INSTALL_DIR)
exists(../shared/qbs/qbs.pro)|!isEmpty(QBS_INSTALL_DIR): \
    SUBDIRS += \
        qbsprojectmanager
```
- **类型**: **条件构建入口** — 仅在存在 qbs 源码或设置了 `QBS_INSTALL_DIR` 时编译
- **注意**: 如果不设置环境变量且没有 shared/qbs/，**不会被编译**（可能已经不编译）

---

## 五、CMakeLists.txt 依赖声明（CMake 构建路径）

| 文件 | 行号 | 内容 | 依赖类型 |
|------|------|------|----------|
| `mcusupport/CMakeLists.txt` | L3 | `PLUGIN_DEPENDS Core ProjectExplorer Debugger CMakeProjectManager QtSupport` | **硬依赖** |
| `incredibuild/CMakeLists.txt` | L3 | `PLUGIN_RECOMMENDS QmakeProjectManager CmakeProjectManager` | 推荐依赖 |

---

## 六、Android 插件的条件 QBS 引用

### androidplugin.cpp (L45-46)
```cpp
#ifdef HAVE_QBS
#  include "androidqbspropertyprovider.h"
#endif
```
- **依赖类型**: **条件编译** — 仅在定义了 `HAVE_QBS` 宏时编译
- **android.pro / android_dependencies.pri**: **没有**声明对 qbsprojectmanager 的依赖
- **结论**: 默认不编译，删除 qbsprojectmanager 后此处不受影响

---

## 七、软引用 — 字符串常量和注释（不影响编译，但影响运行时）

### 7.1 projectexplorer/desktoprunconfiguration.cpp

| 行号 | 内容 | 类型 |
|------|------|------|
| L55 | `enum Kind { Qmake, Qbs, CMake };` | 枚举值（硬依赖，配合 #include 一起） |
| L128 | `} else if (m_kind == Qbs) {` | 枚举分支 |
| L141 | `} else if (m_kind == CMake) {` | 枚举分支 |
| L193 | `const char QBS_RUNCONFIG_ID[] = "Qbs.RunConfiguration:";` | 字符串 ID |
| L194 | `const char CMAKE_RUNCONFIG_ID[] = "CMakeProjectManager.CMakeRunConfiguration.";` | 字符串 ID |

### 7.2 projectexplorer/userfileaccessor.cpp（用户文件版本兼容迁移）

| 行号 | 内容 | 类型 |
|------|------|------|
| L148 | `// Version 20 renames "Qbs.Deploy"...` | 注释 |
| L478 | `"CMakeProjectManager.CMakeBuildConfiguration.BuildDirectory"` | 字符串常量 |
| L480 | `"Qbs.BuildDirectory"` | 字符串常量 |
| L788 | `"CMakeProjectManager.CMakeRunConfiguration.Arguments"` | 字符串常量 |
| L793 | `"Qbs.RunConfiguration.CommandLineArguments"` | 字符串常量 |
| L799 | `"CMakeProjectManager.CMakeRunConfiguration.UserWorkingDirectory"` | 字符串常量 |
| L802 | `"Qbs.RunConfiguration.WorkingDirectory"` | 字符串常量 |
| L807 | `"CMakeProjectManager.CMakeRunConfiguration.UseTerminal"` | 字符串常量 |
| L811 | `"Qbs.RunConfiguration.UseTerminal"` | 字符串常量 |

- **依赖类型**: **纯软引用** — 这些是用于旧项目文件格式升级的字符串，不引用任何头文件，不影响编译

### 7.3 projectexplorer/runconfiguration.cpp (L331)
```cpp
// Hack for cmake projects 4.10 -> 4.11.
```
- **依赖类型**: **注释** — 不影响编译

### 7.4 projectexplorer/simpleprojectwizard.cpp — cmake 项目生成相关

| 行号 | 内容 | 类型 |
|------|------|------|
| L112 | `comboBox->addItems(QStringList() << "qmake" << "cmake");` | 字符串（UI） |
| L173 | `setDisplayName(tr("Import as qmake or cmake Project..."))` | 显示文本 |
| L175 | `setDescription(tr("...do not use qmake, CMake or Autotools..."))` | 描述文本 |
| L255-344 | `generateCmakeFiles()` 函数 — 生成 CMakeLists.txt 模板内容 | 纯字符串生成逻辑 |

- **L171 中的 `CMakeProjectManager::Constants::CMAKE_PROJECT_ID`**: **硬依赖**（需 #include）
- 其余生成 CMakeLists.txt 的代码是**纯字符串**，不依赖 cmake 插件头文件

### 7.5 remotelinux/makeinstallstep.cpp

| 行号 | 内容 | 类型 |
|------|------|------|
| L172-174 | `m_isCmakeProject = buildStep...contains("cmake");` | 字符串检测 |
| L193-195 | `"to your CMakeLists.txt file for deployment to work."` | 显示文本 |

- **依赖类型**: **纯软引用** — 运行时字符串匹配，不引用任何 cmake 头文件

### 7.6 qmljstools/ — QBS MIME 类型注册

| 文件 | 行号 | 内容 | 类型 |
|------|------|------|------|
| `qmljstoolsconstants.h` | L34 | `const char QBS_MIMETYPE[] = "application/x-qt.qbs+qml";` | MIME 类型常量 |
| `qmljstoolssettings.cpp` | L134 | `registerMimeTypeForLanguageId(Constants::QBS_MIMETYPE, ...)` | 注册 |
| `qmljsmodelmanager.cpp` | L115 | `Constants::QBS_MIMETYPE` 加入 qmlTypeNames | 过滤 |
| `qmljsmodelmanager.cpp` | L189 | `mimeTypeForName(Constants::QBS_MIMETYPE)` | 查询 |
| `qmljsbundleprovider.cpp` | L78 | `defaultBundle("qbs-bundle.json")` | 加载 JSON 束 |
| `QmlJSTools.json.in` | L30-34 | MIME type 注册 `application/x-qt.qbs+qml`, `*.qbs` | 元数据 |

- **依赖类型**: **纯软引用** — 这些是 QML/JS 语言服务对 .qbs 文件的编辑器支持，完全不依赖 qbsprojectmanager 插件的头文件或库

### 7.7 qnx/qnxdeployqtlibrariesdialog.cpp

| 行号 | 内容 | 类型 |
|------|------|------|
| L261 | `QStringList unusedDirs = {"include", "mkspecs", "cmake", "pkgconfig"};` | 文件过滤 |
| L275 | `QStringList unusedSuffixes = {"cmake", "la", "prl", "a", "pc"};` | 后缀过滤 |

- **依赖类型**: **纯软引用** — "cmake" 这里指 cmake 模块文件/后缀，与 cmake 插件无关

### 7.8 incredibuild/ — CMakeCommandBuilder（自包含）

| 文件 | 行号 | 关键内容 |
|------|------|----------|
| `cmakecommandbuilder.h` | L35-43 | `CMakeCommandBuilder` 类定义 |
| `cmakecommandbuilder.cpp` | L50 | `QString makeClassName("CMakeProjectManager::Internal::CMakeBuildStep")` |
| `cmakecommandbuilder.cpp` | L67 | `m_defaultMake = "cmake"` |
| `ibconsolebuildstep.cpp` | L28, L165 | `#include "cmakecommandbuilder.h"`, 创建 CMakeCommandBuilder |
| `buildconsolebuildstep.cpp` | L29, L285 | 同上 |

- **依赖类型**: **自包含的软引用** — `cmakecommandbuilder.h/cpp` 是 incredibuild 自己的文件（不是从 cmakeprojectmanager 引入的），不 `#include` 任何 cmakeprojectmanager 头文件。L50 的 `"CMakeProjectManager::Internal::CMakeBuildStep"` 是**运行时字符串匹配**
- **incredibuild_dependencies.pri 中的 `QTC_PLUGIN_RECOMMENDS`**: 只是建议加载顺序，不是编译依赖

### 7.9 valgrind/valgrindmemcheckparsertest.cpp (L101)
```cpp
// Qbs uses the install-root/bin
```
- **依赖类型**: **注释** — 不影响编译

---

## 八、.qbs 文件引用（Qbs 构建系统自身文件）

以下 `.qbs` 文件是 Qbs 构建系统自身的构建描述文件（类似于 .pro 文件），如果使用 qmake 构建则**全部不参与编译**，可忽略：

- `clangtools/clangtools.qbs` (L26: `"QbsProjectManager"`)
- `mcusupport/mcusupport.qbs` (L13: `Depends { name: "CMakeProjectManager" }`)
- 各插件目录下的 `*.qbs` 文件中的 `import qbs` 语句

---

## 九、需修改的文件清单（移除两个插件目录前必须修改）

### 9.1 必须修改（否则编译失败）

| # | 文件 | 修改内容 |
|---|------|----------|
| 1 | `src/plugins/plugins.pro` | 删除 L28 `cmakeprojectmanager \`；L110-114 的 qbsprojectmanager 条件块 |
| 2 | `src/plugins/projectexplorer/desktoprunconfiguration.h` | 删除 `QbsRunConfigurationFactory` 和 `CMakeRunConfigurationFactory` 类声明 |
| 3 | `src/plugins/projectexplorer/desktoprunconfiguration.cpp` | 删除 L34-35 的 #include，删除 CMake/Qbs 相关类和工厂注册代码 |
| 4 | `src/plugins/projectexplorer/simpleprojectwizard.cpp` | 删除 L35 的 #include，删除或替换 cmake 项目类型常量引用(L171)，可选择保留 cmake 文件生成字符串代码 |
| 5 | `src/plugins/mcusupport/mcusupport_dependencies.pri` | 从 `QTC_PLUGIN_DEPENDS` 中删除 `cmakeprojectmanager` |
| 6 | `src/plugins/mcusupport/mcusupportrunconfiguration.cpp` | 删除 L36-37 的 #include，重写 flash 逻辑 |
| 7 | `src/plugins/mcusupport/mcusupportoptionspage.cpp` | 删除 L30-31 的 #include，重写 CMake 检测逻辑 |
| 8 | `src/plugins/mcusupport/mcusupportoptions.cpp` | 删除 L30,L33 的 #include，重写 CMake kit 逻辑 |
| 9 | `src/plugins/mcusupport/CMakeLists.txt` | 从 `PLUGIN_DEPENDS` 中删除 `CMakeProjectManager` |

### 9.2 建议修改（推荐依赖 / 测试依赖）

| # | 文件 | 修改内容 |
|---|------|----------|
| 10 | `src/plugins/incredibuild/incredibuild_dependencies.pri` | 从 `QTC_PLUGIN_RECOMMENDS` 中删除 `cmakeprojectmanager` |
| 11 | `src/plugins/incredibuild/CMakeLists.txt` | 从 `PLUGIN_RECOMMENDS` 中删除 `CmakeProjectManager` |
| 12 | `src/plugins/clangtools/clangtools_dependencies.pri` | 从 `QTC_TEST_DEPENDS` 中删除 `qbsprojectmanager` |
| 13 | `src/plugins/autotest/autotest_dependencies.pri` | 从 `QTC_TEST_DEPENDS` 中删除 `qbsprojectmanager` |

### 9.3 无需修改（纯软引用）

以下文件只包含字符串常量、注释或独立逻辑，**不影响编译**：

- `projectexplorer/userfileaccessor.cpp` — 用户文件升级迁移字符串
- `projectexplorer/runconfiguration.cpp` — 注释
- `remotelinux/makeinstallstep.cpp` — 运行时字符串匹配
- `qmljstools/*` — QBS MIME 类型注册（编辑器功能，不依赖 QbsProjectManager 插件）
- `qnx/qnxdeployqtlibrariesdialog.cpp` — 文件后缀过滤
- `incredibuild/cmakecommandbuilder.h/cpp` — 自包含的 cmake 命令逻辑
- `android/androidplugin.cpp` — `#ifdef HAVE_QBS` 条件编译，默认不激活
- `android/androidbuildapkwidget.cpp` — CMakeLists.txt 字符串
- `android/androidsettingswidget.cpp` — OpenSSL CMakeLists.txt 检测
- `valgrind/valgrindmemcheckparsertest.cpp` — 注释

---

## 十、风险评估

| 风险级别 | 说明 |
|----------|------|
| **高** | **mcusupport 插件**与 CMakeProjectManager 深度耦合（4个源文件 + 依赖声明），建议**整个移除 mcusupport 插件**或彻底重写其 CMake 依赖 |
| **中** | **projectexplorer/desktoprunconfiguration** 需要移除两个 RunConfigurationFactory，修改量中等但核心代码 |
| **中** | **projectexplorer/simpleprojectwizard** 移除 cmake 项目类型引用 |
| **低** | incredibuild 的 RECOMMENDS 依赖和 clangtools/autotest 的 TEST_DEPENDS 只是可选/测试依赖 |
| **无** | 所有字符串常量和注释引用对编译零影响 |

---

## 十一、推荐移除顺序

1. **plugins.pro** — 删除两个 SUBDIRS 入口
2. **projectexplorer/desktoprunconfiguration.{h,cpp}** — 删除 CMake/Qbs 工厂类
3. **projectexplorer/simpleprojectwizard.cpp** — 删除 cmake 常量引用
4. **mcusupport 全部 4 个源文件 + dependencies.pri + CMakeLists.txt** — 需大量重写或移除此插件
5. **incredibuild_dependencies.pri + CMakeLists.txt** — 删除推荐依赖行
6. **clangtools_dependencies.pri + autotest_dependencies.pri** — 删除测试依赖行
