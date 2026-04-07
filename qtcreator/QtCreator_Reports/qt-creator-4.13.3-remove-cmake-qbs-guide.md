# Qt Creator 4.13.3 — 移除 CMake 与 Qbs 构建痕迹操作指南

基于 `qt-creator-opensource-src-4.13.3/` 全目录代码审计，审计时间 2026-04-02。

---

## 一、清除对象总览

### 1.1 文件统计

| 构建系统 | 文件类型 | 文件数 | 磁盘占用 |
|---------|---------|--------|---------|
| **CMake** | `CMakeLists.txt` | 269 | — |
| **CMake** | `.cmake` 模块文件 | 14 | — |
| **CMake** | `cmake/` 顶层目录 | 1 个目录（14 文件） | — |
| **CMake** | `conanfile.txt`（Conan 包管理） | 1 | — |
| **CMake 合计** | — | **284** | **401 KB** |
| **Qbs** | `.qbs` 文件 | 1404 | — |
| **Qbs** | `qbs/` 顶层目录 | 1 个目录（18 文件） | — |
| **Qbs** | `src/shared/qbs/`（完整 Qbs 源码树） | 5705 文件 | 36.8 MB |
| **Qbs** | `qtcreator.qbs`（顶层入口） | 1 | — |
| **Qbs 合计** | — | **~7128** | **~37.3 MB** |
| **总计** | — | **~7412** | **~37.7 MB** |

### 1.2 CMake 文件分布

| 位置 | CMakeLists.txt 数量 |
|------|:---:|
| 根目录 | 1 |
| `cmake/` | 1 + 13 个 .cmake |
| `src/` | 157 |
| `tests/` | 98 |
| `share/` | 10 |
| `doc/` | 1 |
| `bin/` | 1 |

### 1.3 Qbs 文件分布

| 位置 | .qbs 文件数量 | 说明 |
|------|:---:|------|
| 根目录 | 1 | `qtcreator.qbs` |
| `qbs/` | 15 | 构建模块 |
| `src/shared/qbs/` | **1080** | Qbs 自身源码（嵌入） |
| `src/`（其他） | 178 | 各插件/库的 .qbs |
| `tests/` | 120 | 测试 .qbs |
| `share/` | 9 | 共享资源 .qbs |
| `doc/` | 1 | `doc.qbs` |

---

## 二、需要删除的文件和目录

### 2.1 直接删除（无需修改其他文件）

#### CMake 部分

| 序号 | 操作 | 目标 | 说明 |
|:---:|------|------|------|
| 1 | 删除目录 | `cmake/` | 顶层 CMake 模块目录（14 文件） |
| 2 | 删除文件 | `CMakeLists.txt`（根目录） | 顶层 CMake 入口 |
| 3 | 删除文件 | `conanfile.txt` | Conan 包管理（仅 CMake 使用） |
| 4 | 删除文件 | `doc/CMakeLists.txt` | |
| 5 | 删除文件 | `bin/CMakeLists.txt` | |
| 6 | 删除文件 | `share/CMakeLists.txt` | |
| 7 | 删除文件 | `src/CMakeLists.txt` | |
| 8 | 批量删除 | `src/` 下所有 `CMakeLists.txt`（157 个） | 递归删除 |
| 9 | 批量删除 | `tests/` 下所有 `CMakeLists.txt`（98 个） | 递归删除 |
| 10 | 批量删除 | `share/` 下剩余 `CMakeLists.txt`（9 个） | 递归删除 |

**批量删除命令（PowerShell）：**
```powershell
# 删除所有 CMakeLists.txt
Get-ChildItem -Recurse -Filter "CMakeLists.txt" -File | Remove-Item -Force

# 删除所有 .cmake 文件
Get-ChildItem -Recurse -Filter "*.cmake" -File | Remove-Item -Force

# 删除 cmake/ 目录
Remove-Item -Recurse -Force cmake

# 删除 conanfile.txt
Remove-Item -Force conanfile.txt

# 删除 .cmake.in 文件
Get-ChildItem -Recurse -Filter "*.cmake.in" -File | Remove-Item -Force
```

#### Qbs 部分

| 序号 | 操作 | 目标 | 说明 |
|:---:|------|------|------|
| 1 | 删除目录 | `qbs/` | 顶层 Qbs 模块目录（18 文件） |
| 2 | 删除目录 | `src/shared/qbs/` | **完整 Qbs 源码树**（5705 文件，36.8 MB） |
| 3 | 删除文件 | `qtcreator.qbs`（根目录） | 顶层 Qbs 入口 |
| 4 | 删除文件 | `doc/doc.qbs` | |
| 5 | 批量删除 | 所有 `.qbs` 文件（1404 个） | 递归删除 |

**批量删除命令（PowerShell）：**
```powershell
# 删除 qbs/ 和 src/shared/qbs/ 目录
Remove-Item -Recurse -Force qbs
Remove-Item -Recurse -Force src\shared\qbs

# 删除所有 .qbs 文件
Get-ChildItem -Recurse -Filter "*.qbs" -File | Remove-Item -Force

# 删除顶层 qtcreator.qbs
Remove-Item -Force qtcreator.qbs
```

#### Linux Shell 命令（等价）：
```bash
# CMake
find . -name "CMakeLists.txt" -delete
find . -name "*.cmake" -delete
find . -name "*.cmake.in" -delete
rm -rf cmake/
rm -f conanfile.txt

# Qbs
find . -name "*.qbs" -delete
rm -rf qbs/
rm -rf src/shared/qbs/
```

---

## 三、需要修改的文件（交叉引用清理）

### 3.1 qtcreator.pro — Qbs 配置块移除

**文件**：`qtcreator.pro`

**修改 1**：删除 DISTFILES 中的 Qbs 引用（第 21-22 行）

```diff
 DISTFILES += dist/copyright_template.txt \
     README.md \
     $$files(dist/changes-*) \
-    qtcreator.qbs \
-    $$files(qbs/*, true) \
     $$files(scripts/*.py) \
     $$files(scripts/*.sh) \
     $$files(scripts/*.pl)
```

**修改 2**：删除整个 Qbs 配置条件块（第 27-80 行，约 54 行）

```diff
-exists(src/shared/qbs/qbs.pro) {
-    # Make sure the qbs dll ends up alongside the Creator executable.
-    QBS_DLLDESTDIR = $${IDE_BUILD_TREE}/bin
-    cache(QBS_DLLDESTDIR)
-    ... (共 54 行 QBS 配置)
-    include(src/shared/qbs/doc/doc_shared.pri)
-    include(src/shared/qbs/doc/doc_targets.pri)
-    docs.depends += qbs_docs
-    !build_online_docs {
-        ...
-    }
-}
```

### 3.2 qtcreator.pri — 全局 .qbs DISTFILES 机制移除

**文件**：`qtcreator.pri` 第 243-244 行

```diff
-QBSFILE = $$replace(_PRO_FILE_, \\.pro$, .qbs)
-exists($$QBSFILE):DISTFILES += $$QBSFILE
```

这两行是**全局机制**——每个 .pro 编译时自动将同名 .qbs 加入 DISTFILES。删除后所有 .pro 不再查找对应 .qbs。

### 3.3 plugins.pro — 移除 qbsprojectmanager 和 cmakeprojectmanager 条件编译

**文件**：`src/plugins/plugins.pro`

**修改 1**：cmakeprojectmanager 行（第 28 行）
```diff
-    cmakeprojectmanager \
```

**修改 2**：qbsprojectmanager 条件块（第 112-114 行）
```diff
-exists(../shared/qbs/qbs.pro)|!isEmpty(QBS_INSTALL_DIR): \
-    SUBDIRS += qbsprojectmanager
```

### 3.4 projectexplorer — 硬编码依赖解耦

**文件**：`src/plugins/projectexplorer/desktoprunconfiguration.cpp`

**修改 1**：删除 include（第 34-35 行）
```diff
-#include <cmakeprojectmanager/cmakeprojectconstants.h>
-#include <qbsprojectmanager/qbsprojectmanagerconstants.h>
```

**修改 2**：删除 project type 注册（第 199 和 206 行）
```diff
-    addSupportedProjectType(CMakeProjectManager::Constants::CMAKE_PROJECT_ID);
     ...
-    addSupportedProjectType(QbsProjectManager::Constants::PROJECT_ID);
```

**文件**：`src/plugins/projectexplorer/simpleprojectwizard.cpp`

**修改 1**：删除 include（第 35 行）
```diff
-#include <cmakeprojectmanager/cmakeprojectconstants.h>
```

**修改 2**：删除 CMake project type 引用（第 171 行及相关）
```diff
-    CMakeProjectManager::Constants::CMAKE_PROJECT_ID,
```

**修改 3**：删除 CMakeLists.txt 检测（第 262 行附近）
```diff
-    files << QFileInfo(dir, "CMakeLists.txt");
```

**文件**：`src/plugins/projectexplorer/userfileaccessor.cpp`

第 478、788、799、807 行有硬编码的 `"CMakeProjectManager.CMake*"` 字符串键。这些是**用户配置迁移代码**——用于升级旧版 .user 文件。**建议保留**，因为删除会导致旧项目的用户设置迁移失败。

### 3.5 QmlJSTools — Qbs MIME 类型和语法支持

**文件**：`src/plugins/qmljstools/qmljstoolsconstants.h`（第 34 行）
```diff
-const char QBS_MIMETYPE[] = "application/x-qt.qbs+qml";
```

**文件**：`src/plugins/qmljstools/qmljsbundleprovider.cpp`（第 76-78, 97 行）
```diff
-QmlBundle BasicBundleProvider::defaultQbsBundle()
-{
-    return defaultBundle(QLatin1String("qbs-bundle.json"));
-}
 ...
-    bundles.mergeBundleForLanguage(Dialect::QmlQbs, defaultQbsBundle());
```

**文件**：`src/plugins/qmljstools/qmljsbundleprovider.h`（第 70 行）
```diff
-    static QmlJS::QmlBundle defaultQbsBundle();
```

**文件**：`src/plugins/qmljstools/qmljsmodelmanager.cpp`（第 115, 189-191, 232-235 行）
```diff
-    const QSet<QString> qmlTypeNames = { Constants::QML_MIMETYPE, Constants::QBS_MIMETYPE, ...
+    const QSet<QString> qmlTypeNames = { Constants::QML_MIMETYPE, ...
 ...
-    MimeType qbsSourceTy = Utils::mimeTypeForName(Constants::QBS_MIMETYPE);
-    foreach (const QString &suffix, qbsSourceTy.suffixes())
-        res[suffix] = Dialect::QmlQbs;
 ...
-    ViewerContext qbsVContext;
-    qbsVContext.language = Dialect::QmlQbs;
-    qbsVContext.paths.append(ICore::resourcePath() + QLatin1String("/qbs"));
-    setDefaultVContext(qbsVContext);
```

**文件**：`src/plugins/qmljstools/QmlJSTools.json.in`（第 30-34 行，MIME 注册）
```diff
-    \"    <mime-type type='application/x-qt.qbs+qml'>\",
-    \"        <alias type='text/x-qt.qbs+qml'/>\",
-    \"        ...\",
-    \"        <glob pattern='*.qbs' weight='70'/>\",
```

**文件**：`src/plugins/qmljstools/qmljstoolssettings.cpp`（第 134 行）
```diff
-    TextEditorSettings::registerMimeTypeForLanguageId(Constants::QBS_MIMETYPE, Constants::QML_JS_SETTINGS_ID);
```

### 3.6 插件依赖文件修改

| 文件 | 修改内容 |
|------|---------|
| `src/plugins/autotest/autotest_dependencies.pri` 第 17 行 | 删除 `qbsprojectmanager \` (QTC_TEST_DEPENDS) |
| `src/plugins/clangtools/clangtools_dependencies.pri` 第 15 行 | 删除 `qbsprojectmanager \` (QTC_TEST_DEPENDS) |
| `src/plugins/mcusupport/mcusupport_dependencies.pri` 第 11 行 | 删除 `cmakeprojectmanager \` (QTC_PLUGIN_DEPENDS) |
| `src/plugins/incredibuild/incredibuild_dependencies.pri` 第 10 行 | 删除 `cmakeprojectmanager` (QTC_PLUGIN_RECOMMENDS) |

### 3.7 incredibuild 插件 — CMake 构建器移除

**文件**：`src/plugins/incredibuild/cmakecommandbuilder.cpp` 和 `cmakecommandbuilder.h`

两个选择：
- **方案 A**：删除这两个文件 + 从 incredibuild.pro 中移除引用
- **方案 B**：保留但将 CMake 构建器类中对 `CMakeProjectManager` 的引用改为字符串常量

推荐**方案 A**——incredibuild 插件的 CMake 构建器不是核心功能。

### 3.8 android 插件 — CMake 引用清理

**文件**：`src/plugins/android/androidbuildapkwidget.cpp`（第 375-376 行）
```diff
-    if (projectPath.endsWith("CMakeLists.txt")) {
-        ... // 生成 CMake include 代码
-    }
```

**文件**：`src/plugins/android/androidsettingswidget.cpp`（第 172, 406-407, 587-589 行）
```diff
-    // OpenSslCmakeListsPathExists 验证点
```

**注意**：android 插件的 CMake 引用是用于**检测用户项目中的 CMakeLists.txt**（不是 Qt Creator 自身的构建），属于 IDE 功能逻辑。**如果目标是「去掉构建痕迹」但保留 CMake 项目支持功能，则不改此文件。如果目标是「彻底移除 CMake 相关一切」，则需要修改。**

### 3.9 autotest / clangtools 插件 — Qbs 测试引用清理

**文件**：`src/plugins/autotest/testcodeparser.cpp`（第 201 行）
```diff
-    if (!fileName.endsWith(".qbs"))
```

**文件**：`src/plugins/autotest/autotestunittests.cpp`（第 142, 145, 188, 189, 246, 303 行）
- 删除所有引用 `.qbs` 测试项目的测试用例行

**文件**：`src/plugins/clangtools/clangtoolsunittests.cpp`（第 147-169 行）
- 删除所有 `addTestRow("simple/simple.qbs", ...)` 行（6 处）

### 3.10 向导模板 — wizard.json 清理

**位置**：`share/qtcreator/templates/wizards/`（49 个 wizard.json 文件）

| 引用类型 | 文件数 | 修改内容 |
|---------|:---:|---------|
| `QbsProjectManager` | 10 | 删除 Qbs 相关的 `requiredFeatures`、构建步骤、文件生成 |
| `CMakeProjectManager` | 11 | 删除 CMake 相关的 `requiredFeatures`、构建步骤、文件生成 |

每个 wizard.json 中的典型修改：
```diff
 "requiredFeatures": [
-    { "value": "CMakeProjectManager.CMakeProjectManager" },
-    { "value": "QbsProjectManager.QbsActionManager" },
     { "value": "QmakeProjectManager.QmakeManager" }
 ]
```
以及删除对应的 CMakeLists.txt / .qbs 模板文件生成段落。

### 3.11 share/qtcreator/ 资源文件

**需删除的资源目录/文件**：
```
share/qtcreator/qbs/              ← Qbs 运行时资源
share/qtcreator/templates/wizards/projects/*/CMakeLists.txt 模板
share/qtcreator/templates/wizards/projects/*/*.qbs 模板
```

### 3.12 文档文件清理

| 文件 | 操作 |
|------|------|
| `doc/doc.qbs` | 删除 |
| `doc/qtcreator/src/cmake/` 目录（3 个 .qdoc 文件） | 删除 |
| `doc/qtcreator/src/projects/creator-only/creator-projects-qbs.qdoc` | 删除 |
| `doc/qtcreator/src/projects/creator-only/creator-projects-settings-build-qbs.qdocinc` | 删除 |
| `doc/qtcreator/images/creator-qbs-*.png`（4 个） | 删除 |
| `doc/qtcreator/images/qtcreator-cmake-*.png`（7 个） | 删除 |
| `doc/qtcreator/images/qtcreator-kits-cmake.png` | 删除 |
| `doc/qtcreator/images/qtcreator-cmakeexecutable.png` | 删除 |
| `doc/qtcreator/images/qtcreator-options-qbs.png` | 删除 |
| `doc/qtcreator/images/qtcreator-qbs-profile-settings.png` | 删除 |

---

## 四、需要删除的插件目录

| 插件目录 | 文件数 | 说明 |
|---------|:---:|------|
| `src/plugins/cmakeprojectmanager/` | 75 | CMake 项目管理器（整个删除） |
| `src/plugins/qbsprojectmanager/` | 50 | Qbs 项目管理器（整个删除） |

---

## 五、需要保留的文件（长得像但不该删）

| 文件/代码 | 原因 |
|---------|------|
| `src/plugins/projectexplorer/userfileaccessor.cpp` 中的 `"CMakeProjectManager.CMake*"` 字符串 | 用户配置迁移代码，删除会导致旧 .user 文件无法升级 |
| `src/tools/sdktool/` 中的 `addcmakeoperation.cpp/h`、`rmcmakeoperation.cpp/h` | sdktool 的 CMake kit 管理功能，如果不需要可删，但不影响构建 |
| `src/plugins/help/qlitehtml/litehtml/` 下的 CMakeLists.txt | 第三方库 litehtml 的构建文件，help.pro 中用 `exists(CMakeLists.txt)` 检测是否存在 litehtml 源码。**删除 CMakeLists.txt 会导致 litehtml 被跳过**——但 qlitehtml.pri 有回退逻辑，只要 `LITEHTML_INSTALL_DIR` 已设则不受影响 |

---

## 六、操作顺序总结

### 第一阶段：文件删除（安全，可回退）

| 步骤 | 操作 | 数量 | 说明 |
|:---:|------|:---:|------|
| 1 | 删除 `src/shared/qbs/` 目录 | 5705 文件 | 最大单项，释放 36.8 MB |
| 2 | 删除 `src/plugins/qbsprojectmanager/` 目录 | 50 文件 | |
| 3 | 删除 `src/plugins/cmakeprojectmanager/` 目录 | 75 文件 | |
| 4 | 删除 `qbs/` 目录 | 18 文件 | |
| 5 | 删除 `cmake/` 目录 | 14 文件 | |
| 6 | 批量删除所有 `.qbs` 文件 | ~1404 文件 | |
| 7 | 批量删除所有 `CMakeLists.txt` | ~269 文件 | |
| 8 | 批量删除所有 `.cmake` 和 `.cmake.in` 文件 | ~14 文件 | |
| 9 | 删除 `qtcreator.qbs`、`conanfile.txt` | 2 文件 | |
| 10 | 删除文档中的 cmake/qbs 图片和 qdoc 文件 | ~18 文件 | |

### 第二阶段：代码修改（需小心）

| 步骤 | 文件 | 改动点 | 说明 |
|:---:|------|:---:|------|
| 11 | `qtcreator.pro` | 2 处 | DISTFILES + Qbs 配置块 |
| 12 | `qtcreator.pri` | 1 处 | 全局 .qbs DISTFILES 机制 |
| 13 | `src/plugins/plugins.pro` | 2 处 | cmake + qbs 插件引用 |
| 14 | `desktoprunconfiguration.cpp` | 4 处 | include + project type |
| 15 | `simpleprojectwizard.cpp` | 3 处 | include + cmake 检测 |
| 16 | QmlJSTools（6 个文件） | ~15 处 | Qbs MIME + 语法 + bundle |
| 17 | 插件依赖 .pri 文件（4 个） | 4 处 | 测试/插件依赖 |
| 18 | incredibuild 插件（2 文件删除或修改） | — | cmake 构建器 |
| 19 | autotest/clangtools 测试文件（3 个） | ~12 处 | qbs 测试用例 |
| 20 | wizard.json 文件（~21 个） | ~21 处 | cmake/qbs 向导清理 |

### 第三阶段：验证

| 步骤 | 操作 |
|:---:|------|
| 21 | `qmake qtcreator.pro` 无报错 |
| 22 | 全量编译通过 |
| 23 | 搜索残留：`grep -r "cmake\|qbs\|CMake\|Qbs" --include="*.pro" --include="*.pri"` |

---

## 七、改动量化统计

| 指标 | CMake | Qbs | 合计 |
|------|:---:|:---:|:---:|
| 删除的独立文件 | ~284 | ~7128 | **~7412** |
| 删除的插件目录 | 1（75 文件） | 1（50 文件） | **2（125 文件）** |
| 需修改的源码文件 | ~8 | ~12 | **~20** |
| 需修改的 wizard.json | 11 | 10 | **~21** |
| 需修改的 .pro/.pri | 4 | 4 | **~6**（部分重叠） |
| 释放磁盘空间 | ~401 KB | ~37.3 MB | **~37.7 MB** |
| 预计工时 | 0.5 天 | 1 天 | **1-2 天** |

---

## 八、风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| litehtml 检测失效 | help 插件的 qlitehtml 功能可能被跳过 | 设置 `LITEHTML_INSTALL_DIR` 或保留 `src/plugins/help/qlitehtml/litehtml/CMakeLists.txt` 这一个文件 |
| 旧 .user 文件迁移失败 | 用户打开旧版 Creator 生成的 cmake 项目设置会丢失 | 保留 `userfileaccessor.cpp` 中的字符串不动 |
| wizard.json 修改错误 | 新建项目向导选项异常 | 逐一测试每种项目模板 |
| QmlJSTools 清理不完整 | qbs 文件仍尝试关联 QML 语法高亮 | 确保 MIME 注册、bundle、modelmanager 三处全部清理 |
| sdktool 功能缺失 | kit 管理无法添加/删除 CMake 相关配置 | 如不需要可接受，否则保留 sdktool 的 cmake 操作文件 |
