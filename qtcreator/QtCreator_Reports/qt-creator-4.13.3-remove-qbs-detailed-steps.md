# Qt Creator 4.13.3 — 移除 Qbs 所有相关痕迹：逐行操作手册

基于 `qt-creator-opensource-src-4.13.3/` 全目录代码审计，审计时间 2026-04-07。

**本文档只涉及 Qbs，不涉及 CMake。**

---

## 一、Qbs 痕迹全量统计

| 类别 | 数量 | 说明 |
|------|:---:|------|
| `.qbs` 构建文件 | 1403 个 | 分布在整个源码树，是 Qbs 构建系统的工程描述文件 |
| `qbs/` 顶层目录 | 1 个目录（含 16 文件） | Qbs 构建模块（imports/modules） |
| `src/shared/qbs/` 嵌入式 Qbs 源码 | 整个子目录树 | 完整的 Qbs 构建工具源码副本 |
| `src/plugins/qbsprojectmanager/` 插件目录 | 47 个文件 | Qbs 项目管理器插件的全部实现代码 |
| `qtcreator.qbs` 顶层工程文件 | 1 个 | Qbs 构建入口文件 |
| 向导模板 `.qbs` 文件 | 7 个 | 新建项目向导中的 Qbs 模板 |
| 向导模板 `wizard.json` 中的 Qbs 条目 | 11 个文件 | 向导配置中的 Qbs 构建系统选项 |
| QML 类型描述文件 | 3 个 | `qbs.qmltypes`、`qbs-base.qmltypes`、`qbs-bundle.json` |
| Qbs 相关文档（`.qdoc`/`.qdocinc`） | 2 个 | 专门的 Qbs 文档页面 |
| Qbs 相关截图（`.png`） | 6 个 | 文档中的 Qbs 界面截图 |
| 引用了 QbsProjectManager 的外部源码文件 | 约 30 个 | 散布在 qmljs、projectexplorer 等模块 |
| `.pro`/`.pri` 中的 Qbs 引用 | 约 8 个文件 | 构建系统中的 Qbs 条件编译逻辑 |
| 脚本中的 Qbs 引用 | 3 个文件 | 部署、打包、版权检查脚本 |
| `dist/` 更新日志中的 Qbs 条目 | 约 25 个文件 | 历史版本变更记录 |

---

## 二、操作全局顺序

整个移除分 **8 个阶段**，必须按顺序执行：

1. **阶段一**：删除全部 `.qbs` 构建文件和顶层 `qbs/` 目录
2. **阶段二**：删除嵌入式 Qbs 源码 `src/shared/qbs/`
3. **阶段三**：删除 `qbsprojectmanager` 插件目录
4. **阶段四**：修改 `.pro`/`.pri` 构建配置文件（解除 Qbs 编译依赖）
5. **阶段五**：修改 C++ 源码文件（移除对 Qbs 的代码引用）
6. **阶段六**：清理向导模板（wizard.json 和模板 .qbs 文件）
7. **阶段七**：清理文档、截图、QML 类型描述、脚本
8. **阶段八**：验证 qmake + 全量编译

---

## 三、阶段一：删除全部 `.qbs` 构建文件和顶层 `qbs/` 目录

### 步骤 1.1 — 删除顶层 `qtcreator.qbs`

这是 Qbs 构建系统的入口文件，等价于 `qtcreator.pro` 对 qmake 的作用。

**执行命令**：
```bash
cd qt-creator-opensource-src-4.13.3
rm -f qtcreator.qbs
```

### 步骤 1.2 — 删除顶层 `qbs/` 目录

该目录包含 Qbs 构建的 imports 和 modules，共 16 个文件：

```
qbs/imports/QtcAutotest.qbs
qbs/imports/QtcCommercialPlugin.qbs
qbs/imports/QtcDevHeaders.qbs
qbs/imports/QtcDocumentation.qbs
qbs/imports/QtcLibrary.qbs
qbs/imports/QtcPlugin.qbs
qbs/imports/QtcProduct.qbs
qbs/imports/QtcTool.qbs
qbs/modules/clang_defines/clang_defines.qbs
qbs/modules/copyable_resource/copyable-resource.qbs
qbs/modules/libclang/libclang.qbs
qbs/modules/pluginjson/pluginjson.qbs
qbs/modules/qbsbuildconfig/qbsbuildconfig.qbs
qbs/modules/qtc/qtc.qbs
qbs/modules/sqlite_sources/sqlite-sources.qbs
```

**执行命令**：
```bash
rm -rf qbs/
```

### 步骤 1.3 — 批量删除所有 `.qbs` 文件

源码树中共有 1403 个 `.qbs` 文件（步骤 1.1 已删除 1 个，步骤 1.2 已删除 15 个，剩余约 1387 个分布在 `src/`、`share/`、`tests/`、`doc/` 等目录）。

**执行命令**：
```bash
find . -name "*.qbs" -type f -delete
```

执行后验证：
```bash
find . -name "*.qbs" -type f | wc -l
# 期望输出：0
```

---

## 四、阶段二：删除嵌入式 Qbs 源码 `src/shared/qbs/`

### 步骤 2.1 — 删除整个 `src/shared/qbs/` 目录

该目录是完整的 Qbs 构建工具源码副本，包含 Qbs 的 corelib、app、plugins、tests、doc 等全部内容。

**执行命令**：
```bash
rm -rf src/shared/qbs/
```

---

## 五、阶段三：删除 `qbsprojectmanager` 插件目录

### 步骤 3.1 — 删除整个 `src/plugins/qbsprojectmanager/` 目录

该目录包含 47 个文件，是 Qbs 项目管理器插件的全部实现代码。

**执行命令**：
```bash
rm -rf src/plugins/qbsprojectmanager/
```

---

## 六、阶段四：修改 `.pro`/`.pri` 构建配置文件

### 步骤 4.1 — 修改 `qtcreator.pro`

**文件**：`qtcreator.pro`

**共 4 处改动**：

#### 改动 4.1.1 — 删除 DISTFILES 中的 qbs 引用（第 21-22 行）

第 19-24 行原内容：
```qmake
DISTFILES += \
    dist/copyright_template.txt \
    qtcreator.qbs \
    $$files(qbs/*, true) \
    dist/changelog \
    dist/changes-*
```

改为：
```qmake
DISTFILES += \
    dist/copyright_template.txt \
    dist/changelog \
    dist/changes-*
```

**操作**：删除第 21 行 `qtcreator.qbs \` 和第 22 行 `$$files(qbs/*, true) \`。

#### 改动 4.1.2 — 删除整个 Qbs 配置块（第 27-70 行）

第 27-70 行原内容：
```qmake
exists(src/shared/qbs/qbs.pro) {
    # Make sure the qbs dll ends up alongside the Creator executable.
    QBS_DLLDESTDIR = $${IDE_BUILD_TREE}/bin
    cache(QBS_DLLDESTDIR)
    QBS_DESTDIR = $${IDE_LIBRARY_PATH}
    cache(QBS_DESTDIR)
    QBSLIBDIR = $${IDE_LIBRARY_PATH}
    cache(QBSLIBDIR)
    QBS_INSTALL_PREFIX = $${QTC_PREFIX}
    cache(QBS_INSTALL_PREFIX)
    QBS_LIB_INSTALL_DIR = $$INSTALL_LIBRARY_PATH
    cache(QBS_LIB_INSTALL_DIR)
    QBS_RESOURCES_BUILD_DIR = $${IDE_DATA_PATH}/qbs
    cache(QBS_RESOURCES_BUILD_DIR)
    QBS_RESOURCES_INSTALL_DIR = $$INSTALL_DATA_PATH/qbs
    cache(QBS_RESOURCES_INSTALL_DIR)
    macos {
        QBS_PLUGINS_BUILD_DIR = $${IDE_PLUGIN_PATH}
        QBS_APPS_RPATH_DIR = @loader_path/../Frameworks
    } else {
        QBS_PLUGINS_BUILD_DIR = $$IDE_PLUGIN_PATH
        QBS_APPS_RPATH_DIR = \$\$ORIGIN/../$$IDE_LIBRARY_BASENAME/qtcreator
    }
    cache(QBS_PLUGINS_BUILD_DIR)
    cache(QBS_APPS_RPATH_DIR)
    QBS_PLUGINS_INSTALL_DIR = $$INSTALL_PLUGIN_PATH
    cache(QBS_PLUGINS_INSTALL_DIR)
    QBS_LIBRARY_DIRNAME = $${IDE_LIBRARY_BASENAME}
    cache(QBS_LIBRARY_DIRNAME)
    QBS_APPS_DESTDIR = $${IDE_BIN_PATH}
    cache(QBS_APPS_DESTDIR)
    QBS_APPS_INSTALL_DIR = $$INSTALL_BIN_PATH
    cache(QBS_APPS_INSTALL_DIR)
    QBS_LIBEXEC_DESTDIR = $${IDE_LIBEXEC_PATH}
    cache(QBS_LIBEXEC_DESTDIR)
    QBS_LIBEXEC_INSTALL_DIR = $$INSTALL_LIBEXEC_PATH
    cache(QBS_LIBEXEC_INSTALL_DIR)
    QBS_RELATIVE_LIBEXEC_PATH = $$relative_path($$QBS_LIBEXEC_DESTDIR, $$QBS_APPS_DESTDIR)
    isEmpty(QBS_RELATIVE_LIBEXEC_PATH):QBS_RELATIVE_LIBEXEC_PATH = .
    cache(QBS_RELATIVE_LIBEXEC_PATH)
    QBS_RELATIVE_PLUGINS_PATH = $$relative_path($$QBS_PLUGINS_BUILD_DIR, $$QBS_APPS_DESTDIR$$)
    cache(QBS_RELATIVE_PLUGINS_PATH)
    QBS_RELATIVE_SEARCH_PATH = $$relative_path($$QBS_RESOURCES_BUILD_DIR, $$QBS_APPS_DESTDIR)
    cache(QBS_RELATIVE_SEARCH_PATH)
    !qbs_no_dev_install {
        QBS_CONFIG_ADDITION = qbs_no_dev_install qbs_enable_project_file_updates
        cache(CONFIG, add, QBS_CONFIG_ADDITION)
    }
```

**操作**：从第 27 行 `exists(src/shared/qbs/qbs.pro) {` 开始，到第 74 行对应的 `}` 结束，整个 `exists(...)` 块全部删除。

#### 改动 4.1.3 — 删除 Qbs 文档目标（第 76-83 行）

第 75-84 行原内容：
```qmake
    # Create qbs documentation targets.
    DOC_FILES += src/shared/qbs/doc/qbs.qdoc
    DOC_TARGET_PREFIX = qbs_
    include(src/shared/qbs/doc/doc_shared.pri)
    include(src/shared/qbs/doc/doc_targets.pri)
    docs.depends += qbs_docs
    !isEmpty(INSTALL_DOC_PATH) {
        install_docs.depends += install_qbs_docs
    }
```

**操作**：删除这整个 Qbs 文档目标块（从 `# Create qbs documentation targets.` 到 `}` 的闭合大括号）。

> **注意**：改动 4.1.2 和 4.1.3 实际上处于同一个 `exists(src/shared/qbs/qbs.pro) { ... }` 代码块内，所以只要整个删除该 `exists(...)` 块即可一并完成这两处改动。

#### 改动 4.1.4 — 删除 `qtcreator.pri` 中的 qbs 分发文件逻辑（位于 `qtcreator.pri`）

**文件**：`qtcreator.pri`

第 243-244 行原内容：
```qmake
QBSFILE = $$replace(_PRO_FILE_, \\.pro$, .qbs)
exists($$QBSFILE):DISTFILES += $$QBSFILE
```

**操作**：删除这两行。这两行的作用是为每个 `.pro` 文件自动把同目录下的 `.qbs` 文件加入分发列表。

---

### 步骤 4.2 — 修改 `src/shared/shared.pro`

**文件**：`src/shared/shared.pro`

**改动**：删除全部 Qbs 相关的 SUBDIRS 定义和条件块。

第 1-33 行原内容：
```qmake
TEMPLATE = subdirs

QBS_DIRS = \
    qbscorelib \
    qbsapps \
    qbslibexec \
    qbsmsbuildlib \
    qbsplugins \
    qbsstatic

qbscorelib.subdir = qbs/src/lib/corelib
qbsapps.subdir = qbs/src/app
qbsapps.depends = qbscorelib
qbslibexec.subdir = qbs/src/libexec
qbslibexec.depends = qbscorelib
qbsmsbuildlib.subdir = qbs/src/lib/msbuild
qbsmsbuildlib.depends = qbscorelib
qbsplugins.subdir = qbs/src/plugins
qbsplugins.depends = qbscorelib qbsmsbuildlib
qbsstatic.file = qbs/static.pro

exists(qbs/qbs.pro) {
    isEmpty(QBS_INSTALL_DIR):QBS_INSTALL_DIR = $$(QBS_INSTALL_DIR)
    isEmpty(QBS_INSTALL_DIR):SUBDIRS += $$QBS_DIRS

    include(qbs/src/lib/bundledlibs.pri)
    qbs_use_bundled_qtscript {
        qbsscriptenginelib.file = qbs/src/lib/scriptengine/scriptengine.pro
        qbscorelib.depends = qbsscriptenginelib
        SUBDIRS += qbsscriptenginelib
    }
}

TR_EXCLUDE = qbs
```

改为：
```qmake
TEMPLATE = subdirs
```

**操作**：删除第 3 行到第 33 行的全部内容，只保留第 1 行 `TEMPLATE = subdirs`。如果 `shared.pro` 中除了 qbs 还有其他 SUBDIRS（如 proparser），需要保留那些行。请先检查文件完整内容——如果文件中只有 qbs 相关的 SUBDIRS，那么只保留 `TEMPLATE = subdirs` 即可。

---

### 步骤 4.3 — 修改 `src/plugins/plugins.pro`

**文件**：`src/plugins/plugins.pro`

**改动**：删除第 110-113 行的 Qbs 条件编译块。

第 109-114 行原内容（行号可能因之前修改 CMake 而偏移，以内容为准）：
```qmake
isEmpty(QBS_INSTALL_DIR): QBS_INSTALL_DIR = $$(QBS_INSTALL_DIR)
exists(../shared/qbs/qbs.pro)|!isEmpty(QBS_INSTALL_DIR): \
    SUBDIRS += \
        qbsprojectmanager
```

**操作**：删除这 4 行。这 4 行的作用是：如果嵌入的 Qbs 源码存在或者设置了 `QBS_INSTALL_DIR` 环境变量，就编译 `qbsprojectmanager` 插件。

---

### 步骤 4.4 — 修改 `src/plugins/autotest/autotest_dependencies.pri`

**文件**：`src/plugins/autotest/autotest_dependencies.pri`

第 17 行原内容：
```qmake
    qbsprojectmanager \
```

**操作**：删除第 17 行 `    qbsprojectmanager \`。

查看上下文确认——这是 `QTC_PLUGIN_DEPENDS` 列表中的一项，删除该行后要确保上一行的反斜杠续行符正确。如果 `qbsprojectmanager \` 是列表的最后一项，删除后需要把上一行末尾的 `\` 也一并去掉。

---

### 步骤 4.5 — 修改 `src/plugins/clangtools/clangtools_dependencies.pri`

**文件**：`src/plugins/clangtools/clangtools_dependencies.pri`

第 15 行原内容：
```qmake
    qbsprojectmanager \
```

**操作**：删除第 15 行 `    qbsprojectmanager \`。同样注意续行符处理。

---

### 步骤 4.6 — 修改 `share/share.pro`

**文件**：`share/share.pro`

第 19-20 行原内容：
```qmake
DISTFILES += share.qbs \
    ../src/share/share.qbs
```

**操作**：删除这两行。它们把 `share.qbs` 和 `src/share/share.qbs` 加入分发列表，文件已在阶段一删除。

---

### 步骤 4.7 — 修改 `share/qtcreator/translations/translations.pro`

**文件**：`share/qtcreator/translations/translations.pro`

第 59 行原内容：
```qmake
    src/shared/qbs \
```

**操作**：删除第 59 行。这一行将 `src/shared/qbs` 加入翻译源文件扫描路径，目录已在阶段二删除。

---

## 七、阶段五：修改 C++ 源码文件

### 步骤 5.1 — 修改 `src/plugins/projectexplorer/desktoprunconfiguration.h`

**文件**：`src/plugins/projectexplorer/desktoprunconfiguration.h`

**改动**：删除第 40-44 行的 `QbsRunConfigurationFactory` 类声明。

第 35-47 行原内容：
```cpp
{
public:
    DesktopQmakeRunConfigurationFactory();
};

class QbsRunConfigurationFactory final : public RunConfigurationFactory
{
public:
    QbsRunConfigurationFactory();
};

} // namespace Internal
} // namespace ProjectExplorer
```

改为：
```cpp
{
public:
    DesktopQmakeRunConfigurationFactory();
};

} // namespace Internal
} // namespace ProjectExplorer
```

**操作**：删除第 40-44 行（`QbsRunConfigurationFactory` 类声明及其大括号，含空行）。

---

### 步骤 5.2 — 修改 `src/plugins/projectexplorer/desktoprunconfiguration.cpp`

**文件**：`src/plugins/projectexplorer/desktoprunconfiguration.cpp`

**共 6 处改动**：

#### 改动 5.2.1 — 删除 `#include`（第 34 行）

第 33-35 行原内容：
```cpp
#include <qbsprojectmanager/qbsprojectmanagerconstants.h>
#include <qmakeprojectmanager/qmakeprojectmanagerconstants.h>
```

改为：
```cpp
#include <qmakeprojectmanager/qmakeprojectmanagerconstants.h>
```

**操作**：删除第 34 行 `#include <qbsprojectmanager/qbsprojectmanagerconstants.h>`。

#### 改动 5.2.2 — 修改枚举（第 54 行）

第 54 行原内容：
```cpp
    enum Kind { Qmake, Qbs }; // FIXME: Remove
```

改为：
```cpp
    enum Kind { Qmake }; // FIXME: Remove
```

**操作**：从枚举中删除 `, Qbs`。

#### 改动 5.2.3 — 删除 Qbs 分支（第 127-140 行）

第 125-141 行原内容：
```cpp
        aspect<ExecutableAspect>()->setExecutable(bti.targetFilePath);

    }  else if (m_kind == Qbs) {

        setDefaultDisplayName(bti.displayName);
        const FilePath executable = executableToRun(bti);

        aspect<ExecutableAspect>()->setExecutable(executable);

        if (!executable.isEmpty()) {
            const FilePath defaultWorkingDir = executable.absolutePath();
            if (!defaultWorkingDir.isEmpty())
                aspect<WorkingDirectoryAspect>()->setDefaultWorkingDirectory(defaultWorkingDir);
        }

    }
```

改为：
```cpp
        aspect<ExecutableAspect>()->setExecutable(bti.targetFilePath);

    }
```

**操作**：删除从 `}  else if (m_kind == Qbs) {` 到其对应闭合 `}` 之间的全部代码（第 127-140 行）。

#### 改动 5.2.4 — 删除 `QbsRunConfiguration` 类定义（第 169-175 行）

第 169-175 行原内容：
```cpp
class QbsRunConfiguration final : public DesktopRunConfiguration
{
public:
    QbsRunConfiguration(Target *target, Utils::Id id)
        : DesktopRunConfiguration(target, id, Qbs)
    {}
};
```

**操作**：删除这 7 行。

#### 改动 5.2.5 — 删除 `QBS_RUNCONFIG_ID` 常量和工厂实现（第 178-185 行）

第 177-185 行原内容：
```cpp
const char QMAKE_RUNCONFIG_ID[] = "Qt4ProjectManager.Qt4RunConfiguration:";
const char QBS_RUNCONFIG_ID[]   = "Qbs.RunConfiguration:";

QbsRunConfigurationFactory::QbsRunConfigurationFactory()
{
    registerRunConfiguration<QbsRunConfiguration>(QBS_RUNCONFIG_ID);
    addSupportedProjectType(QbsProjectManager::Constants::PROJECT_ID);
    addSupportedTargetDeviceType(ProjectExplorer::Constants::DESKTOP_DEVICE_TYPE);
}
```

改为：
```cpp
const char QMAKE_RUNCONFIG_ID[] = "Qt4ProjectManager.Qt4RunConfiguration:";
```

**操作**：删除第 178 行 `const char QBS_RUNCONFIG_ID[]` 和第 180-185 行 `QbsRunConfigurationFactory` 构造函数实现。

---

### 步骤 5.3 — 修改 `src/plugins/projectexplorer/projectexplorer.cpp`

**文件**：`src/plugins/projectexplorer/projectexplorer.cpp`

**共 2 处改动**：

#### 改动 5.3.1 — 删除 `qbsRunConfigFactory` 成员变量（第 654 行）

第 653-654 行原内容：
```cpp
    DesktopQmakeRunConfigurationFactory qmakeRunConfigFactory;
    QbsRunConfigurationFactory qbsRunConfigFactory;
```

改为：
```cpp
    DesktopQmakeRunConfigurationFactory qmakeRunConfigFactory;
```

#### 改动 5.3.2 — 删除 `qbsRunConfigFactory` 引用（第 660 行）

第 656-661 行原内容：
```cpp
    RunWorkerFactory desktopRunWorkerFactory{
        RunWorkerFactory::make<SimpleTargetRunner>(),
        {ProjectExplorer::Constants::NORMAL_RUN_MODE},
        {qmakeRunConfigFactory.runConfigurationId(),
         qbsRunConfigFactory.runConfigurationId()}
    };
```

改为：
```cpp
    RunWorkerFactory desktopRunWorkerFactory{
        RunWorkerFactory::make<SimpleTargetRunner>(),
        {ProjectExplorer::Constants::NORMAL_RUN_MODE},
        {qmakeRunConfigFactory.runConfigurationId()}
    };
```

**操作**：删除第 660 行 `         qbsRunConfigFactory.runConfigurationId()}`，并将第 659 行末尾的逗号去掉，变成 `{qmakeRunConfigFactory.runConfigurationId()}`。

---

### 步骤 5.4 — 修改 `src/plugins/projectexplorer/userfileaccessor.cpp`

**文件**：`src/plugins/projectexplorer/userfileaccessor.cpp`

该文件中有多处 Qbs 字符串引用（第 148、480、793、802、811、813、815、860 行）。这些全部是**版本迁移/升级逻辑**，用于将旧版用户配置文件迁移到新格式。

**处理策略**：**保留不改**。

**原因**：这些是用户项目文件的版本迁移器。即使 Qbs 插件已被移除，如果用户打开旧的项目配置文件，这些迁移代码仍然需要正确处理旧数据而不是崩溃。字符串只是用来匹配旧配置键名，不引入任何对 Qbs 模块的编译依赖。

---

### 步骤 5.5 — 修改 `src/libs/qmljs/qmljsconstants.h`

**文件**：`src/libs/qmljs/qmljsconstants.h`

第 68-81 行原内容：
```cpp
namespace Language {
enum Enum
{
    NoLanguage = 0,
    JavaScript = 1,
    Json = 2,
    Qml = 3,
    QmlQtQuick2 = 5,
    QmlQbs = 6,
    QmlProject = 7,
    QmlTypeInfo = 8,
    AnyLanguage = 9,
};
}
```

改为：
```cpp
namespace Language {
enum Enum
{
    NoLanguage = 0,
    JavaScript = 1,
    Json = 2,
    Qml = 3,
    QmlQtQuick2 = 5,
    QmlProject = 7,
    QmlTypeInfo = 8,
    AnyLanguage = 9,
};
}
```

**操作**：删除第 76 行 `    QmlQbs = 6,`。注意不要改变其他枚举值的数值——保持 `QmlProject = 7` 不变。

---

### 步骤 5.6 — 修改 `src/libs/qmljs/qmljsdialect.h`

**文件**：`src/libs/qmljs/qmljsdialect.h`

第 38-52 行原内容：
```cpp
    enum Enum
    {
        NoLanguage = 0,
        JavaScript = 1,
        Json = 2,
        Qml = 3,
        QmlQtQuick2 = 5,
        QmlQbs = 6,
        QmlProject = 7,
        QmlTypeInfo = 8,
        QmlQtQuick2Ui = 9,
        AnyLanguage = 10,
    };
```

改为：
```cpp
    enum Enum
    {
        NoLanguage = 0,
        JavaScript = 1,
        Json = 2,
        Qml = 3,
        QmlQtQuick2 = 5,
        QmlProject = 7,
        QmlTypeInfo = 8,
        QmlQtQuick2Ui = 9,
        AnyLanguage = 10,
    };
```

**操作**：删除 `        QmlQbs = 6,` 这一行。

---

### 步骤 5.7 — 修改 `src/libs/qmljs/qmljsdialect.cpp`

**文件**：`src/libs/qmljs/qmljsdialect.cpp`

**共 7 处改动**：

#### 改动 5.7.1 — 第 39 行

原内容：
```cpp
    case Dialect::QmlQbs:
```

在该 `switch` 语句中，找到 `case Dialect::QmlQbs:` 及其对应的代码块，删除该 case 分支。需要根据上下文判断是否是 fall-through（直接穿透到下一个 case）还是有独立的 `return`/`break`。

查看上下文，第 38-40 行：
```cpp
    case Dialect::QmlProject:
    case Dialect::QmlQbs:
        return true;
```

改为：
```cpp
    case Dialect::QmlProject:
        return true;
```

**操作**：删除第 39 行 `    case Dialect::QmlQbs:`。

#### 改动 5.7.2 — 第 60 行

同样的 fall-through 模式。第 59-61 行：
```cpp
    case Dialect::QmlProject:
    case Dialect::QmlQbs:
        return true;
```

改为：
```cpp
    case Dialect::QmlProject:
        return true;
```

**操作**：删除第 60 行。

#### 改动 5.7.3 — 第 74 行

第 73-75 行：
```cpp
    case Dialect::QmlProject:
    case Dialect::QmlQbs:
        return true;
```

改为：
```cpp
    case Dialect::QmlProject:
        return true;
```

**操作**：删除第 74 行。

#### 改动 5.7.4 — 第 102-103 行

第 101-104 行：
```cpp
    case Dialect::QmlTypeInfo:
    case Dialect::QmlQbs:
        return QLatin1String("QmlQbs");
    case Dialect::QmlProject:
```

改为：
```cpp
    case Dialect::QmlTypeInfo:
        return QLatin1String("QmlTypeInfo");
    case Dialect::QmlProject:
```

**注意**：这里 `case Dialect::QmlQbs:` 不是 fall-through，它有自己的 `return` 语句。删除后，`case Dialect::QmlTypeInfo:` 需要有自己的 return。请仔细查看原始代码确认 `QmlTypeInfo` 原本的 return 值。如果原代码中 `QmlTypeInfo` 是穿透到 `QmlQbs` 的，那么删除 `QmlQbs` 后需要给 `QmlTypeInfo` 加上正确的 return 语句。

查看上下文确认：原代码第 100-104 行实际是：
```cpp
    case Dialect::QmlTypeInfo:
        return QLatin1String("QmlTypeInfo");
    case Dialect::QmlQbs:
        return QLatin1String("QmlQbs");
    case Dialect::QmlProject:
```

**操作**：删除第 102-103 行（`case Dialect::QmlQbs:` 和 `return QLatin1String("QmlQbs");`）。

#### 改动 5.7.5 — 第 199 行

在另一个 switch 语句中，第 198-200 行：
```cpp
    case Dialect::QmlProject:
    case Dialect::QmlQbs:
        return 0;
```

改为：
```cpp
    case Dialect::QmlProject:
        return 0;
```

**操作**：删除第 199 行。

#### 改动 5.7.6 — 第 212 行

第 211-213 行原内容：
```cpp
        langs << Dialect::JavaScript << Dialect::Json << Dialect::QmlProject << Dialect:: QmlQbs
              << Dialect::QmlTypeInfo << Dialect::QmlQtQuick2 << Dialect::QmlQtQuick2Ui
              << Dialect::Qml;
```

改为：
```cpp
        langs << Dialect::JavaScript << Dialect::Json << Dialect::QmlProject
              << Dialect::QmlTypeInfo << Dialect::QmlQtQuick2 << Dialect::QmlQtQuick2Ui
              << Dialect::Qml;
```

**操作**：删除 `<< Dialect:: QmlQbs`（注意原代码中有个多余空格 `Dialect:: QmlQbs`）。

---

### 步骤 5.8 — 修改 `src/libs/qmljs/qmljsbind.cpp`

**文件**：`src/libs/qmljs/qmljsbind.cpp`

第 193-198 行原内容：
```cpp
    if (_doc->language() == Dialect::QmlQbs) {
        static const QString qbsBaseImport = QStringLiteral("qbs");
        static auto isQbsBaseImport = [] (const ImportInfo &ii) {
            return ii.name() == qbsBaseImport; };
        if (!Utils::anyOf(_imports, isQbsBaseImport))
            _imports += ImportInfo::moduleImport(qbsBaseImport, ComponentVersion(), QString());
```

**操作**：删除这整个 `if` 块（第 193-198 行），包含闭合的 `}` 如果在第 198 行末尾。检查上下文确认闭合大括号位置。

---

### 步骤 5.9 — 修改 `src/libs/qmljs/qmljscheck.cpp`

**文件**：`src/libs/qmljs/qmljscheck.cpp`

第 938-939 行原内容：
```cpp
    // TODO: currently Qbs checks are not working properly
    if (_doc->language() == Dialect::QmlQbs)
```

查看下一行（通常是 `return;` 或 `return false;`）：
```cpp
    // TODO: currently Qbs checks are not working properly
    if (_doc->language() == Dialect::QmlQbs)
        return;
```

**操作**：删除这 3 行（第 938-940 行，含注释行、if 判断行和 return 语句行）。

---

### 步骤 5.10 — 修改 `src/libs/qmljs/qmljsimportdependencies.cpp`

**文件**：`src/libs/qmljs/qmljsimportdependencies.cpp`

第 53-55 行（switch case 中的一个分支）：
```cpp
    case Dialect::QmlQbs:
```

查看上下文确认这是一个 fall-through case。删除该行即可。

**操作**：删除第 54 行 `    case Dialect::QmlQbs:`。

---

### 步骤 5.11 — 修改 `src/libs/qmljs/qmljslink.cpp`

**文件**：`src/libs/qmljs/qmljslink.cpp`

**共 2 处改动**：

#### 改动 5.11.1 — 第 441-442 行

原内容：
```cpp
    // TODO: at the moment there is not any types information on Qbs imports.
    if (doc->language() == Dialect::QmlQbs)
```

及其下一行（通常是 `return;` 或 `continue;`），整个块如：
```cpp
    // TODO: at the moment there is not any types information on Qbs imports.
    if (doc->language() == Dialect::QmlQbs)
        return;
```

**操作**：删除这 3 行。

#### 改动 5.11.2 — 第 454 行和第 504 行

这两行是错误提示文字中的 Qbs 帮助信息：
```cpp
"For Qbs projects, declare and set a qmlImportPaths property in your product "
```

这两处分别出现在两段错误消息中。需要删除包含 Qbs 提示的子字符串。

第 454 行所在的字符串拼接上下文：
```cpp
    warning(import->token, Check::tr("unknown module"));
    ... "For Qbs projects, declare and set a qmlImportPaths property in your product " ...
```

**操作**：在两处错误消息中，删除 `"For Qbs projects, declare and set a qmlImportPaths property in your product "` 这一段文字。注意保持剩余字符串语法正确。

---

### 步骤 5.12 — 修改 `src/libs/qmljs/qmljsmodelmanagerinterface.cpp`

**文件**：`src/libs/qmljs/qmljsmodelmanagerinterface.cpp`

**共 2 处改动**：

#### 改动 5.12.1 — 第 157 行

第 156-158 行原内容：
```cpp
        {QLatin1String("qmlproject"), Dialect::QmlProject},
        {QLatin1String("qbs"), Dialect::QmlQbs},
        {QLatin1String("qmltypes"), Dialect::QmlTypeInfo},
```

改为：
```cpp
        {QLatin1String("qmlproject"), Dialect::QmlProject},
        {QLatin1String("qmltypes"), Dialect::QmlTypeInfo},
```

**操作**：删除第 157 行 `        {QLatin1String("qbs"), Dialect::QmlQbs},`。

#### 改动 5.12.2 — 第 1493 行

原内容（switch case 分支）：
```cpp
        case Dialect::QmlQbs:
```

查看上下文确认是 fall-through 还是有独立代码，然后删除该 case 行。

**操作**：删除 `        case Dialect::QmlQbs:` 这一行。

---

### 步骤 5.13 — 修改 `src/plugins/qmljstools/qmljstoolsconstants.h`

**文件**：`src/plugins/qmljstools/qmljstoolsconstants.h`

第 34 行原内容：
```cpp
const char QBS_MIMETYPE[] = "application/x-qt.qbs+qml";
```

**操作**：删除第 34 行。

---

### 步骤 5.14 — 修改 `src/plugins/qmljstools/qmljsbundleprovider.cpp`

**文件**：`src/plugins/qmljstools/qmljsbundleprovider.cpp`

**共 2 处改动**：

#### 改动 5.14.1 — 删除 `defaultQbsBundle()` 函数定义（第 76-79 行）

第 76-79 行原内容：
```cpp
QmlBundle BasicBundleProvider::defaultQbsBundle()
{
    return defaultBundle(QLatin1String("qbs-bundle.json"));
}
```

**操作**：删除这 4 行。

#### 改动 5.14.2 — 删除 Qbs bundle 合并调用（第 97 行）

第 97 行原内容：
```cpp
    bundles.mergeBundleForLanguage(Dialect::QmlQbs, defaultQbsBundle());
```

**操作**：删除这 1 行。

---

### 步骤 5.15 — 修改 `src/plugins/qmljstools/qmljsbundleprovider.h`

**文件**：`src/plugins/qmljstools/qmljsbundleprovider.h`

第 70 行原内容：
```cpp
    static QmlJS::QmlBundle defaultQbsBundle();
```

**操作**：删除这 1 行。

---

### 步骤 5.16 — 修改 `src/plugins/qmljstools/qmljsmodelmanager.cpp`

**文件**：`src/plugins/qmljstools/qmljsmodelmanager.cpp`

**共 3 处改动**：

#### 改动 5.16.1 — 删除 QBS_MIMETYPE 注册（第 115 行）

第 114-116 行原内容：
```cpp
        const QSet<QString> qmlTypeNames = { Constants::QML_MIMETYPE ,Constants::QBS_MIMETYPE,
```

改为：
```cpp
        const QSet<QString> qmlTypeNames = { Constants::QML_MIMETYPE,
```

**操作**：从 `QSet` 初始化列表中删除 `,Constants::QBS_MIMETYPE`。

#### 改动 5.16.2 — 删除 qbs suffix 到 dialect 映射（第 189-191 行）

第 188-192 行原内容：
```cpp
        MimeType qbsSourceTy = Utils::mimeTypeForName(Constants::QBS_MIMETYPE);
        foreach (const QString &suffix, qbsSourceTy.suffixes())
            res[suffix] = Dialect::QmlQbs;
```

**操作**：删除这 3 行。

#### 改动 5.16.3 — 删除 Qbs ViewerContext 设置（第 232-235 行）

第 232-235 行原内容：
```cpp
    ViewerContext qbsVContext;
    qbsVContext.language = Dialect::QmlQbs;
    qbsVContext.paths.append(ICore::resourcePath() + QLatin1String("/qbs"));
    setDefaultVContext(qbsVContext);
```

**操作**：删除这 4 行。

---

### 步骤 5.17 — 修改 `src/plugins/qmljstools/qmljstoolssettings.cpp`

**文件**：`src/plugins/qmljstools/qmljstoolssettings.cpp`

第 134 行原内容：
```cpp
    TextEditorSettings::registerMimeTypeForLanguageId(Constants::QBS_MIMETYPE, Constants::QML_JS_SETTINGS_ID);
```

**操作**：删除这 1 行。

---

### 步骤 5.18 — 修改 `src/plugins/qmljstools/QmlJSTools.json.in`

**文件**：`src/plugins/qmljstools/QmlJSTools.json.in`

第 30-34 行原内容：
```json
\"    <mime-type type=\'application/x-qt.qbs+qml\'>\",
\"        <alias type=\'text/x-qt.qbs+qml\'/>\",
\"        <sub-class-of type=\'text/x-qml\'/>\",
\"        <comment>Qt Build Suite file</comment>\",
\"        <glob pattern=\'*.qbs\' weight=\'70\'/>\",
\"    </mime-type>\",
```

**操作**：删除这 6 行（第 30-35 行，从 `<mime-type type='application/x-qt.qbs+qml'>` 到 `</mime-type>`）。这注销了 `.qbs` 文件的 MIME 类型定义。

---

### 步骤 5.19 — 修改 `src/plugins/qmljseditor/qmljseditor.cpp`

**文件**：`src/plugins/qmljseditor/qmljseditor.cpp`

**共 2 处改动**：

#### 改动 5.19.1 — 第 165 行

第 163-167 行原内容：
```cpp
    QStringList qmlTypes { QmlJSTools::Constants::QML_MIMETYPE,
                QmlJSTools::Constants::QBS_MIMETYPE,
                QmlJSTools::Constants::QMLTYPES_MIMETYPE,
                QmlJSTools::Constants::QMLUI_MIMETYPE };
```

改为：
```cpp
    QStringList qmlTypes { QmlJSTools::Constants::QML_MIMETYPE,
                QmlJSTools::Constants::QMLTYPES_MIMETYPE,
                QmlJSTools::Constants::QMLUI_MIMETYPE };
```

**操作**：删除第 165 行 `                QmlJSTools::Constants::QBS_MIMETYPE,`。

#### 改动 5.19.2 — 第 1085 行

原内容：
```cpp
    addMimeType(QmlJSTools::Constants::QBS_MIMETYPE);
```

**操作**：删除这 1 行。

---

### 步骤 5.20 — 修改 `src/plugins/cpaster/protocol.cpp`

**文件**：`src/plugins/cpaster/protocol.cpp`

第 98 行原内容：
```cpp
        || mt == QLatin1String(QmlJSTools::Constants::QBS_MIMETYPE)
```

**操作**：删除这 1 行。

---

### 步骤 5.21 — 修改 `src/plugins/qmlpreview/qmlpreviewplugin.cpp`

**文件**：`src/plugins/qmlpreview/qmlpreviewplugin.cpp`

第 534-535 行原内容：
```cpp
    else if (mimeType == QmlJSTools::Constants::QBS_MIMETYPE)
        dialect = QmlJS::Dialect::QmlQbs;
```

**操作**：删除这 2 行。

---

### 步骤 5.22 — 修改 `src/plugins/android/androidplugin.cpp`

**文件**：`src/plugins/android/androidplugin.cpp`

第 45-47 行原内容：
```cpp
#ifdef HAVE_QBS
#  include "androidqbspropertyprovider.h"
#endif
```

**操作**：删除这 3 行。这是条件编译的 Qbs 头文件包含，删除插件后不再需要。

同时搜索该文件中是否有其他 `HAVE_QBS` 的使用，如果有，也一并删除对应的 `#ifdef HAVE_QBS ... #endif` 块。

---

### 步骤 5.23 — 修改 `src/plugins/autotest/testcodeparser.cpp`

**文件**：`src/plugins/autotest/testcodeparser.cpp`

第 201 行原内容：
```cpp
    if (!fileName.endsWith(".qbs"))
```

查看上下文，第 199-202 行：
```cpp
void TestCodeParser::onQmlDocumentUpdated(const QmlJS::Document::Ptr &document)
{
    const QString fileName = document->fileName();
    if (!fileName.endsWith(".qbs"))
        onDocumentUpdated(fileName, true);
}
```

这段代码的含义是：当 QML 文档更新时，如果文件不是 `.qbs` 文件就处理它（即跳过 `.qbs` 文件）。移除 Qbs 后不会再有 `.qbs` 文件被解析，但这个保护性检查可以简化。

改为：
```cpp
void TestCodeParser::onQmlDocumentUpdated(const QmlJS::Document::Ptr &document)
{
    const QString fileName = document->fileName();
    onDocumentUpdated(fileName, true);
}
```

**操作**：删除第 201 行 `    if (!fileName.endsWith(".qbs"))` 的条件判断，让 `onDocumentUpdated` 直接调用（去掉 if 判断，保留调用语句并去掉缩进）。

---

### 步骤 5.24 — 处理测试文件中的 Qbs 引用

以下文件包含 Qbs 相关的测试用例引用：

#### 5.24.1 — `src/plugins/autotest/autotestunittests.cpp`

第 141-142、144-145、188-189、245-246、302-303 行包含引用 `.qbs` 项目文件的测试用例行。

**操作**：删除所有以 `Qbs` 结尾的测试行（`QTest::newRow("plainAutoTestQbs")`、`QTest::newRow("mixedAutoTestAndQuickTestsQbs")` 等），以及对应的 `.qbs` 文件路径参数行。

具体删除以下行：
- 第 141-142 行：`QTest::newRow("plainAutoTestQbs")` 及其 `.qbs` 路径行
- 第 144-145 行：`QTest::newRow("mixedAutoTestAndQuickTestsQbs")` 及其路径行
- 第 188-189 行：涉及 `plain.qbs` 和 `mixed_atp.qbs` 的行
- 第 245-246 行：`QTest::newRow("simpleGoogletestQbs")` 及其路径行
- 第 302-303 行：`QTest::newRow("simpleBoostTestQbs")` 及其路径行

#### 5.24.2 — `src/plugins/clangtools/clangtoolsunittests.cpp`

第 147、152、157、161、165、169 行包含 `addTestRow("*.qbs", ...)` 调用。

**操作**：删除这 6 行。每一行都是一个独立的 `addTestRow` 调用，引用了 `.qbs` 测试项目文件。

#### 5.24.3 — `src/plugins/valgrind/valgrindmemcheckparsertest.cpp`

第 101 行原内容：
```cpp
        // Qbs uses the install-root/bin
```

**处理策略**：**保留不改**。这只是一行注释，解释了为什么要在特定路径查找可执行文件。删除注释可能降低代码可读性，且不影响编译。

#### 5.24.4 — `src/plugins/diffeditor/diffeditorplugin.cpp`

第 1263-1272 行原内容：
```cpp
    patch = "diff --git a/src/shared/qbs b/src/shared/qbs\n"
            "--- a/src/shared/qbs\n"
            "+++ b/src/shared/qbs\n"
            "@@ -1 +1 @@\n"
            "-Subproject commit eda76354077a427d692fee05479910de31040d3f\n"
            "+Subproject commit eda76354077a427d692fee05479910de31040d3f-dirty\n"
            ;
    fileData1 = FileData();
    fileData1.leftFileInfo = DiffFileInfo("src/shared/qbs");
    fileData1.rightFileInfo = DiffFileInfo("src/shared/qbs");
```

**处理策略**：**保留不改**。这是 diff 编辑器的单元测试数据，测试的是 diff 解析能力，不是 Qbs 功能。字符串 `src/shared/qbs` 只是测试用例中的一个路径样本，改成别的路径也无意义。保留不影响编译，也不引入对 Qbs 的编译依赖。

---

### 步骤 5.25 — 处理注释中的 Qbs 引用

以下文件仅在**注释**中提到 Qbs，**全部保留不改**：

| 文件 | 行号 | 内容 | 保留原因 |
|------|------|------|---------|
| `src/plugins/designer/resourcehandler.cpp` | 108 | `// We do not want qbs groups or qmake .pri files here` | 纯注释，解释设计意图 |
| `src/plugins/modeleditor/modelsmanager.cpp` | 112 | `#ifdef OPEN_DEFAULT_MODEL // ... does not work with qbs` | 注释，且代码已被 `#ifdef` 禁用 |
| `src/plugins/cpptools/compileroptionsbuilder.cpp` | 770 | `//  QbsProject: -m64 -fPIC -std=c++11 -fexceptions` | 注释，示例命令行 |

---

### 步骤 5.26 — 处理 `src/tools/perfparser/app/perfunwind.cpp`

**文件**：`src/tools/perfparser/app/perfunwind.cpp`

第 525 行原内容：
```cpp
    return byteSwap ? qbswap(number) : number;
```

**处理策略**：**保留不改**。

**原因**：`qbswap` 是 Qt 的字节序交换函数（定义在 `<QtEndian>`），全名 `qbswap`（Qt byte swap），与 Qbs 构建系统无关。函数名中的 `qbs` 是 `q` + `bswap`（byte swap）的缩写，不是 `qbs`（Qt Build Suite）。

---

## 八、阶段六：清理向导模板

### 步骤 6.1 — 删除向导 .qbs 模板文件

以下 7 个文件是新建项目向导中的 Qbs 工程模板，在阶段一的 `find . -name "*.qbs" -delete` 中已被删除：

```
share/qtcreator/templates/wizards/autotest/files/tst.qbs
share/qtcreator/templates/wizards/projects/consoleapp/file.qbs
share/qtcreator/templates/wizards/projects/cpplibrary/project.qbs
share/qtcreator/templates/wizards/projects/plainc/file.qbs
share/qtcreator/templates/wizards/projects/plaincpp/file.qbs
share/qtcreator/templates/wizards/projects/qtquickapplication/app.qbs
share/qtcreator/templates/wizards/projects/qtwidgetsapplication/project.qbs
```

如果阶段一已执行，这里无需额外操作。如果未执行阶段一，则手动删除：
```bash
rm -f share/qtcreator/templates/wizards/autotest/files/tst.qbs
rm -f share/qtcreator/templates/wizards/projects/consoleapp/file.qbs
rm -f share/qtcreator/templates/wizards/projects/cpplibrary/project.qbs
rm -f share/qtcreator/templates/wizards/projects/plainc/file.qbs
rm -f share/qtcreator/templates/wizards/projects/plaincpp/file.qbs
rm -f share/qtcreator/templates/wizards/projects/qtquickapplication/app.qbs
rm -f share/qtcreator/templates/wizards/projects/qtwidgetsapplication/project.qbs
```

### 步骤 6.2 — 修改 `share/qtcreator/templates/wizards/projects/consoleapp/wizard.json`

**文件**：`share/qtcreator/templates/wizards/projects/consoleapp/wizard.json`

**共 3 处改动**：

#### 改动 6.2.1 — 删除 `QbsFile` key 定义（第 17 行）

第 16-18 行原内容：
```json
        { "key": "ProFile", "value": "%{JS: Util.fileName(value('ProjectDirectory') + '/' + value('ProjectName'), 'pro')}" },
        { "key": "QbsFile", "value": "%{JS: Util.fileName(value('ProjectDirectory') + '/' + value('ProjectName'), 'qbs')}" },
        { "key": "MesonFile", ...
```

**操作**：删除第 17 行（`QbsFile` key 定义行）。

#### 改动 6.2.2 — 从 BuildSystem 选项中删除 Qbs 条目（第 55 行附近）

在 `"options"` 数组的 `BuildSystem` 项的 `"items"` 列表中，找到 `"value": "qbs"` 的对象并删除。

原内容（包含三个选项 qmake、qbs、meson）：
```json
                            {
                                "trKey": "qmake",
                                "value": "qmake",
                                "condition": "%{JS: value('Plugins').indexOf('QmakeProjectManager') >= 0}"
                            },
                            {
                                "trKey": "Qbs",
                                "value": "qbs",
                                "condition": "%{JS: value('Plugins').indexOf('QbsProjectManager') >= 0}"
                            },
                            {
                                "trKey": "Meson",
                                "value": "meson",
                                "condition": "%{JS: value('Plugins').indexOf('MesonProjectManager') >= 0}"
                            }
```

改为（删除 qbs 对象后）：
```json
                            {
                                "trKey": "qmake",
                                "value": "qmake",
                                "condition": "%{JS: value('Plugins').indexOf('QmakeProjectManager') >= 0}"
                            },
                            {
                                "trKey": "Meson",
                                "value": "meson",
                                "condition": "%{JS: value('Plugins').indexOf('MesonProjectManager') >= 0}"
                            }
```

**操作**：删除 Qbs 选项的整个 JSON 对象（含大括号和逗号）。注意保持 JSON 语法正确。

#### 改动 6.2.3 — 从 generators 中删除 qbs 文件生成器（第 99-102 行）

在 `"generators"` 数组中，找到条件为 `'BuildSystem' === 'qbs'` 的项并删除。

原内容：
```json
                {
                    "source": "file.qbs",
                    "target": "%{QbsFile}",
                    "condition": "%{JS: value('BuildSystem') === 'qbs'}"
                },
```

**操作**：删除这个 generator 对象（含逗号）。

同时需要处理 `ProjectFile` key 的条件逻辑。找到类似：
```json
{ "key": "ProjectFile", "value": "%{JS: value('BuildSystem') === 'qmake' ? value('ProFile') : (value('BuildSystem') === 'meson' ? value('MesonFile') : value('QbsFile'))}" }
```

改为：
```json
{ "key": "ProjectFile", "value": "%{JS: value('BuildSystem') === 'qmake' ? value('ProFile') : value('MesonFile')}" }
```

**操作**：从 `ProjectFile` 的三元表达式中删除 Qbs 分支。

---

### 步骤 6.3 — 修改 `share/qtcreator/templates/wizards/projects/plainc/wizard.json`

操作与 6.2 相同，具体改动：

1. 删除第 16 行 `QbsFile` key 定义
2. 从 BuildSystem items 中删除 Qbs 选项对象
3. 从 generators 中删除 `file.qbs` 生成器
4. 简化 `ProjectFile` key 的条件表达式，去掉 qbs 分支

---

### 步骤 6.4 — 修改 `share/qtcreator/templates/wizards/projects/plaincpp/wizard.json`

操作与 6.2 相同：

1. 删除 `QbsFile` key 定义
2. 从 BuildSystem items 中删除 Qbs 选项
3. 从 generators 中删除 `file.qbs` 生成器
4. 简化 `ProjectFile` key 的条件表达式

---

### 步骤 6.5 — 修改 `share/qtcreator/templates/wizards/projects/cpplibrary/wizard.json`

操作类似，但该向导的 `ProFile` key 直接判断 qbs：

第 15 行原内容：
```json
{ "key": "ProFile", "value": "%{JS: Util.fileName(value('ProjectDirectory') + '/' + value('ProjectName'), value('BuildSystem') === 'qmake' ? 'pro' : 'qbs')}" },
```

改为：
```json
{ "key": "ProFile", "value": "%{JS: Util.fileName(value('ProjectDirectory') + '/' + value('ProjectName'), 'pro')}" },
```

其他改动：
1. 从 BuildSystem items 中删除 Qbs 选项
2. 从 generators 中删除 `project.qbs` 生成器

---

### 步骤 6.6 — 修改 `share/qtcreator/templates/wizards/projects/qtwidgetsapplication/wizard.json`

1. 删除 `QbsFile` key 定义（第 18 行）
2. 从 BuildSystem items 中删除 Qbs 选项
3. 从 generators 中删除 `project.qbs` 生成器（第 175-178 行）
4. 简化 `ProjectFile` key 的条件表达式

---

### 步骤 6.7 — 修改 `share/qtcreator/templates/wizards/projects/qtquickapplication/empty/wizard.json`

1. 删除 `QbsFile` key 定义（第 17 行）
2. 从 BuildSystem items 中删除 Qbs 选项（第 59 行附近）
3. 从 generators 中删除 `../app.qbs` 生成器（第 222-225 行）
4. 简化 `ProjectFile` key 的条件表达式

---

### 步骤 6.8 — 修改 `share/qtcreator/templates/wizards/projects/qtquickapplication/scroll/wizard.json`

操作与 6.7 相同。

---

### 步骤 6.9 — 修改 `share/qtcreator/templates/wizards/projects/qtquickapplication/stack/wizard.json`

操作与 6.7 相同。

---

### 步骤 6.10 — 修改 `share/qtcreator/templates/wizards/projects/qtquickapplication/swipe/wizard.json`

操作与 6.7 相同。

---

### 步骤 6.11 — 修改 `share/qtcreator/templates/wizards/autotest/wizard.json`

**共 3 处改动**：

#### 改动 6.11.1 — 删除 `QbsFileName` key 定义（第 23 行附近）

原内容：
```json
          "value": "%{JS: Util.fileName(value('ProjectDirectory') + '/' + value('ProjectName'), 'qbs')}"
```

**操作**：删除整个 `QbsFileName` 的 key 对象。

#### 改动 6.11.2 — 从 BuildSystem items 中删除 Qbs 选项

原内容含 `"value": "qbs"` 的选项对象。

**操作**：删除该 Qbs 选项对象。

#### 改动 6.11.3 — 从 generators 中删除 qbs 相关生成器

删除条件为 `BuildSystem == 'qbs'` 的所有 generator 对象，包括：
- `tst.qbs` 的生成器
- 与 GTest + Qbs 组合相关的 `googlecommon.js` 条件生成器

---

## 九、阶段七：清理文档、截图、QML 类型描述、脚本

### 步骤 7.1 — 删除 Qbs 专属文档文件

```bash
rm -f doc/qtcreator/src/projects/creator-only/creator-projects-qbs.qdoc
rm -f doc/qtcreator/src/projects/creator-only/creator-projects-settings-build-qbs.qdocinc
```

### 步骤 7.2 — 删除 Qbs 相关截图

```bash
rm -f doc/qtcreator/images/creator-qbs-build-app.png
rm -f doc/qtcreator/images/creator-qbs-build-clean.png
rm -f doc/qtcreator/images/creator-qbs-profiles.png
rm -f doc/qtcreator/images/creator-qbs-project.png
rm -f doc/qtcreator/images/qtcreator-options-qbs.png
rm -f doc/qtcreator/images/qtcreator-qbs-profile-settings.png
```

### 步骤 7.3 — 删除 QML 类型描述文件

```bash
rm -f share/qtcreator/qml-type-descriptions/qbs.qmltypes
rm -f share/qtcreator/qml-type-descriptions/qbs-base.qmltypes
rm -f share/qtcreator/qml-type-descriptions/qbs-bundle.json
```

### 步骤 7.4 — 修改文档中的 Qbs 引用

以下 26 个文档文件中有 Qbs 的文本引用，需要逐一清理：

#### 7.4.1 — `doc/qtcreator/src/projects/creator-only/creator-projects-build-systems.qdocinc`

删除提到 Qbs 作为构建系统选项的段落。

#### 7.4.2 — `doc/qtcreator/src/projects/creator-only/creator-projects-building.qdoc`

删除 Qbs 构建步骤的相关描述。

#### 7.4.3 — `doc/qtcreator/src/projects/creator-only/creator-projects-settings-build.qdoc`

删除 `\include creator-projects-settings-build-qbs.qdocinc` 的引用行。

#### 7.4.4 — `doc/qtcreator/src/projects/creator-only/creator-projects-other.qdoc`

确认导航链接。步骤 7.1 删除了 `creator-projects-qbs.qdoc`，该文件的 `\previouspage` 是 `creator-project-other.html`，`\nextpage` 是 `creator-projects-autotools.html`。需要修改 `creator-projects-other.qdoc` 的 `\nextpage` 从 `creator-project-qbs.html` 改为 `creator-projects-autotools.html`。

同时修改 `creator-projects-autotools.qdoc` 的 `\previouspage` 从 `creator-project-qbs.html` 改为 `creator-project-other.html`。

#### 7.4.5 — `doc/qtcreator/src/qtcreator-toc.qdoc`

删除目录中指向 Qbs 页面的条目。

#### 7.4.6 — 其他文档文件

对以下文件中的 Qbs 引用，删除提及 Qbs 的句子或列表项：

- `doc/qtcreator/src/howto/creator-only/creator-autotest.qdoc`
- `doc/qtcreator/src/howto/creator-views.qdoc`
- `doc/qtcreator/src/ios/creator-ios-dev.qdoc`
- `doc/qtcreator/src/overview/creator-only/creator-advanced.qdoc`
- `doc/qtcreator/src/overview/creator-only/creator-overview.qdoc`
- `doc/qtcreator/src/projects/creator-only/creator-projects-compilers.qdoc`
- `doc/qtcreator/src/projects/creator-only/creator-projects-creating.qdoc`
- `doc/qtcreator/src/projects/creator-only/creator-projects-custom-wizards-json.qdocinc`
- `doc/qtcreator/src/projects/creator-only/creator-projects-opening.qdoc`
- `doc/qtcreator/src/projects/creator-only/creator-projects-targets.qdoc`
- `doc/qtcreator/src/qtquick/creator-only/qtquick-creating.qdoc`
- `doc/qtcreator/src/qtquick/creator-only/qtquick-modules-with-plugins.qdoc`
- `doc/qtcreator/src/qtquick/creator-only/qtquick-tutorial-create-empty-project.qdocinc`
- `doc/qtcreator/src/widgets/qtdesigner-app-tutorial.qdoc`

每个文件中搜索 `qbs`/`Qbs`/`QBS` 关键词，删除包含该关键词的句子或列表项。如果一段中只有 Qbs 的内容，删除整段。如果是与 qmake 和 Qbs 并列的列表（如"支持 qmake、Qbs、CMake"），只删除 Qbs 条目。

#### 7.4.7 — Qt Design Studio 文档

以下文件在 Qt Design Studio 文档中提到了 Qbs：
- `doc/qtdesignstudio/src/qtbridge/qtbridge-overview.qdoc`
- `doc/qtdesignstudio/src/qtbridge/qtbridge-sketch-overview.qdoc`
- `doc/qtdesignstudio/src/qtbridge/qtbridge-sketch-setup.qdoc`
- `doc/qtdesignstudio/src/qtbridge/qtbridge-sketch-using.qdoc`

搜索并删除这些文件中对 Qbs 的引用文字。

---

### 步骤 7.5 — 修改 `scripts/deployqtHelper_mac.sh`

**文件**：`scripts/deployqtHelper_mac.sh`

**改动**：删除 Qbs 应用程序部署逻辑。

第 166-176 行原内容：
```bash
    qbsapp="$app_path/Contents/MacOS/qbs"
    if [ -f "$qbsapp" ]; then
        qbsArguments=("-executable=$qbsapp" \
        "-executable=$qbsapp-config" \
        "-executable=$qbsapp-config-ui" \
        "-executable=$qbsapp-qmltypes" \
        "-executable=$qbsapp-setup-android" \
        "-executable=$qbsapp-setup-qt" \
        "-executable=$qbsapp-setup-toolchains" \
        "-executable=$qbsapp-create-project" \
        "-executable=$libexec_path/qbs_processlauncher")
    fi
```

**操作**：删除这 12 行。

同时第 188 行原内容：
```bash
        "${qbsArguments[@]}" \
```

**操作**：删除这 1 行。

---

### 步骤 7.6 — 修改 `scripts/createSourcePackages.py`

**文件**：`scripts/createSourcePackages.py`

第 102 行原内容：
```python
        submodules = [os.path.join('src', 'shared', 'qbs'),
                      os.path.join('src', 'tools', 'perfparser')]
```

改为：
```python
        submodules = [os.path.join('src', 'tools', 'perfparser')]
```

**操作**：从 `submodules` 列表中删除 `os.path.join('src', 'shared', 'qbs'),` 条目。

---

### 步骤 7.7 — 修改 `scripts/hasCopyright.pl`

**文件**：`scripts/hasCopyright.pl`

第 47 行原内容：
```perl
        $file =~ /\.qbs$/ or
```

**操作**：删除这 1 行。这行将 `.qbs` 文件排除在版权检查之外，移除 Qbs 后不再需要。

---

### 步骤 7.8 — 修改 `README.md`

**文件**：`README.md`

第 53 行原内容：
```
* Qbs 1.7.x (optional, sources also contain Qbs itself)
```

**操作**：删除这 1 行。

第 63-64 行原内容：
```
    # Optional, needed to let the QbsProjectManager plugin use system Qbs:
    export QBS_INSTALL_DIR=/path/to/qbs
```

**操作**：删除这 2 行。

---

### 步骤 7.9 — 处理 `dist/` 更新日志

**文件**：`dist/changes-*` 系列文件

约 25 个更新日志文件中包含 Qbs 相关的变更记录。

**处理策略**：**保留不改**。

**原因**：更新日志是历史记录，记录的是过去版本中发生的事实。删除历史记录没有技术意义，也不影响编译。

---

### 步骤 7.10 — 删除 `doc/doc.qbs`

如果阶段一的 `find . -name "*.qbs" -delete` 已执行，该文件已被删除。否则手动删除：
```bash
rm -f doc/doc.qbs
```

---

### 步骤 7.11 — 删除 syntax-highlighting 补丁中的 Qbs 引用

**文件**：`src/libs/3rdparty/syntax-highlighting/patches/0003-Add-qmake-Qbs-files-and-files-generated-by-CMake.patch`

**处理策略**：**保留不改**。

**原因**：这是第三方库的补丁文件，记录了对 syntax-highlighting 库的修改。该补丁添加了 qmake 和 Qbs 文件的语法高亮支持。修改补丁文件可能导致后续应用补丁时出错。如果你确实要清理，需要修改补丁内容以移除 Qbs 部分，但这是高风险操作。

---

## 十、阶段八：验证

### 步骤 8.1 — 验证无残留 .qbs 文件

```bash
find . -name "*.qbs" -type f
# 期望输出为空
```

### 步骤 8.2 — 验证无残留 qbs 目录

```bash
find . -type d -name "qbs" | grep -v ".git"
# 期望输出为空
```

### 步骤 8.3 — 验证 qmake 构建通过

```bash
mkdir build && cd build
qmake ../qtcreator.pro
make -j$(nproc)
```

如果编译报错，根据错误信息定位遗漏的修改点。常见问题：

1. **找不到 `qbsprojectmanager/qbsprojectmanagerconstants.h`** — 说明某个 `.cpp` 文件还有 `#include <qbsprojectmanager/...>` 未删除
2. **未声明的标识符 `QBS_MIMETYPE`** — 说明某个文件还在使用 `Constants::QBS_MIMETYPE`
3. **未声明的标识符 `QmlQbs`** — 说明某个文件还在使用 `Dialect::QmlQbs`
4. **链接错误引用 `QbsRunConfigurationFactory`** — 说明头文件或 `.cpp` 中还有未清理的声明/定义

### 步骤 8.4 — 最终检索验证

```bash
# 检查是否还有编译依赖性的 qbs 引用（排除注释、字符串常量、dist目录、补丁文件）
grep -rn "QmlQbs\|QBS_MIMETYPE\|QbsProjectManager\|qbsprojectmanager" \
    --include="*.cpp" --include="*.h" --include="*.pro" --include="*.pri" . \
    | grep -v "dist/" | grep -v ".patch" | grep -v "userfileaccessor.cpp"
# 期望输出为空
```

---

## 附录 A：完整删除清单（按文件类型汇总）

### 删除的目录（3 个）

| 目录 | 说明 |
|------|------|
| `qbs/` | Qbs 构建模块目录 |
| `src/shared/qbs/` | 嵌入式 Qbs 源码 |
| `src/plugins/qbsprojectmanager/` | Qbs 项目管理器插件 |

### 删除的文件（约 1420 个）

| 类别 | 数量 |
|------|:---:|
| `.qbs` 文件 | 1403 |
| `qbsprojectmanager/` 插件文件 | 47 |
| Qbs 文档文件（`.qdoc`/`.qdocinc`） | 2 |
| Qbs 截图（`.png`） | 6 |
| QML 类型描述（`.qmltypes`/`.json`） | 3 |

### 修改的文件（约 45 个）

| 文件 | 改动类型 |
|------|---------|
| `qtcreator.pro` | 删除 Qbs 配置块 |
| `qtcreator.pri` | 删除 .qbs 分发文件逻辑 |
| `src/shared/shared.pro` | 删除 Qbs SUBDIRS |
| `src/plugins/plugins.pro` | 删除 qbsprojectmanager 条件编译 |
| `src/plugins/autotest/autotest_dependencies.pri` | 删除 qbsprojectmanager 依赖 |
| `src/plugins/clangtools/clangtools_dependencies.pri` | 删除 qbsprojectmanager 依赖 |
| `share/share.pro` | 删除 .qbs DISTFILES |
| `share/qtcreator/translations/translations.pro` | 删除 qbs 翻译路径 |
| `src/plugins/projectexplorer/desktoprunconfiguration.h` | 删除 QbsRunConfigurationFactory 声明 |
| `src/plugins/projectexplorer/desktoprunconfiguration.cpp` | 删除 Qbs 相关类和逻辑 |
| `src/plugins/projectexplorer/projectexplorer.cpp` | 删除 qbsRunConfigFactory 引用 |
| `src/libs/qmljs/qmljsconstants.h` | 删除 QmlQbs 枚举 |
| `src/libs/qmljs/qmljsdialect.h` | 删除 QmlQbs 枚举 |
| `src/libs/qmljs/qmljsdialect.cpp` | 删除 QmlQbs 的 7 处 case 引用 |
| `src/libs/qmljs/qmljsbind.cpp` | 删除 QmlQbs 自动导入逻辑 |
| `src/libs/qmljs/qmljscheck.cpp` | 删除 QmlQbs 跳过逻辑 |
| `src/libs/qmljs/qmljsimportdependencies.cpp` | 删除 QmlQbs case |
| `src/libs/qmljs/qmljslink.cpp` | 删除 QmlQbs 检查和错误提示 |
| `src/libs/qmljs/qmljsmodelmanagerinterface.cpp` | 删除 qbs 后缀映射和 case |
| `src/plugins/qmljstools/qmljstoolsconstants.h` | 删除 QBS_MIMETYPE 常量 |
| `src/plugins/qmljstools/qmljsbundleprovider.cpp` | 删除 defaultQbsBundle() |
| `src/plugins/qmljstools/qmljsbundleprovider.h` | 删除 defaultQbsBundle() 声明 |
| `src/plugins/qmljstools/qmljsmodelmanager.cpp` | 删除 QBS_MIMETYPE 引用和 qbs ViewerContext |
| `src/plugins/qmljstools/qmljstoolssettings.cpp` | 删除 QBS_MIMETYPE 注册 |
| `src/plugins/qmljstools/QmlJSTools.json.in` | 删除 qbs MIME 类型定义 |
| `src/plugins/qmljseditor/qmljseditor.cpp` | 删除 QBS_MIMETYPE 引用 |
| `src/plugins/cpaster/protocol.cpp` | 删除 QBS_MIMETYPE 引用 |
| `src/plugins/qmlpreview/qmlpreviewplugin.cpp` | 删除 QBS_MIMETYPE 和 QmlQbs 引用 |
| `src/plugins/android/androidplugin.cpp` | 删除 HAVE_QBS 条件编译 |
| `src/plugins/autotest/testcodeparser.cpp` | 删除 .qbs 文件过滤 |
| `src/plugins/autotest/autotestunittests.cpp` | 删除 Qbs 测试用例 |
| `src/plugins/clangtools/clangtoolsunittests.cpp` | 删除 .qbs 测试行 |
| `scripts/deployqtHelper_mac.sh` | 删除 qbs 部署逻辑 |
| `scripts/createSourcePackages.py` | 删除 qbs 子模块引用 |
| `scripts/hasCopyright.pl` | 删除 .qbs 文件排除 |
| `README.md` | 删除 Qbs 依赖和构建说明 |
| 11 个 `wizard.json` 文件 | 删除 Qbs 构建系统选项和生成器 |
| 约 20 个 `.qdoc`/`.qdocinc` 文件 | 删除 Qbs 相关文字 |

### 保留不改的文件

| 文件 | 保留原因 |
|------|---------|
| `src/plugins/projectexplorer/userfileaccessor.cpp` | 版本迁移器，字符串匹配不引入编译依赖 |
| `src/tools/perfparser/app/perfunwind.cpp` | `qbswap` 是 Qt 字节序函数，非 Qbs 相关 |
| `src/plugins/diffeditor/diffeditorplugin.cpp` | 测试数据中的路径字符串，不影响编译 |
| `src/plugins/valgrind/valgrindmemcheckparsertest.cpp` | 纯注释 |
| `src/plugins/designer/resourcehandler.cpp` | 纯注释 |
| `src/plugins/modeleditor/modelsmanager.cpp` | 纯注释，代码已被 #ifdef 禁用 |
| `src/plugins/cpptools/compileroptionsbuilder.cpp` | 纯注释 |
| `dist/changes-*` 系列文件 | 历史变更记录 |
| `src/libs/3rdparty/syntax-highlighting/patches/0003-...patch` | 第三方库补丁 |
