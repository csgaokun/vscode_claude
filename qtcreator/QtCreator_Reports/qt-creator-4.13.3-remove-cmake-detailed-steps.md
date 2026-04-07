# Qt Creator 4.13.3 — 移除 CMake 所有相关痕迹：逐行操作手册

基于 `qt-creator-opensource-src-4.13.3/` 全目录代码审计，审计时间 2026-04-07。

**本文档只涉及 CMake，不涉及 Qbs。**

---

## 一、CMake 痕迹全量统计

| 类别 | 数量 | 磁盘占用 |
|------|:---:|:---:|
| `CMakeLists.txt` 文件 | 269 个 | — |
| `.cmake` 模块文件 | 14 个 | — |
| `.cmake.in` 模板文件 | 2 个 | — |
| `cmake/` 顶层目录 | 1 个目录（14 文件） | 116 KB |
| `conanfile.txt`（Conan 仅 CMake 使用） | 1 个 | — |
| `src/plugins/cmakeprojectmanager/` 插件目录 | 74 个文件 | 696 KB |
| 向导模板 `CMakeLists.txt` | 6 个 | — |
| CMake 相关文档（`.qdoc`/`.qdocinc`） | 3 个 | — |
| CMake 相关截图（`.png`） | 9 个 | — |
| sdktool 中 CMake 操作文件 | 4 个（2 对 `.cpp`+`.h`） | — |
| 引用了 CMakeProjectManager 的外部源码文件 | 15 个 | — |
| 引用 CMake 的 `wizard.json` | 10 个 | — |

---

## 二、操作全局顺序

整个移除分 **5 个阶段**，必须按顺序执行：

1. **阶段一**：删除 CMake 构建系统文件（`CMakeLists.txt`、`.cmake`、`cmake/`、`conanfile.txt`）
2. **阶段二**：删除 `cmakeprojectmanager` 插件目录
3. **阶段三**：修改外部源码文件（解除对 cmakeprojectmanager 的编译依赖）
4. **阶段四**：清理向导模板、文档、sdktool
5. **阶段五**：验证 qmake + 全量编译

---

## 三、阶段一：删除 CMake 构建系统文件

### 步骤 1.1 — 删除顶层 `cmake/` 目录

该目录包含 14 个文件，全部是 CMake 构建专用模块：

```
cmake/CMakeLists.txt
cmake/FindDesignerComponents.cmake
cmake/FindGoogleBenchmark.cmake
cmake/FindGoogletest.cmake
cmake/FindQbs.cmake
cmake/FindQt5.cmake
cmake/Findelfutils.cmake
cmake/Findyaml-cpp.cmake
cmake/InstallDependentSharedObjects.cmake.in
cmake/QtCreatorAPI.cmake
cmake/QtCreatorAPIInternal.cmake
cmake/QtCreatorDocumentation.cmake
cmake/QtCreatorIDEBranding.cmake
cmake/QtCreatorTranslations.cmake
```

**执行命令**（Linux）：
```bash
cd qt-creator-opensource-src-4.13.3
rm -rf cmake/
```

### 步骤 1.2 — 删除顶层 `CMakeLists.txt`

**执行命令**：
```bash
rm -f CMakeLists.txt
```

### 步骤 1.3 — 删除 `conanfile.txt`

这是 Conan 包管理器配置文件，仅用于 CMake 构建流程。

**执行命令**：
```bash
rm -f conanfile.txt
```

### 步骤 1.4 — 批量删除所有 `CMakeLists.txt`（⚠️ 有一个例外）

源码树中共有 269 个 `CMakeLists.txt`。其中 268 个可以直接删除。

**⚠️ 例外：必须保留 `src/plugins/help/qlitehtml/litehtml/CMakeLists.txt`**

原因：`src/plugins/help/help.pro` 第 78 行有如下检测：

```qmake
exists($$PWD/qlitehtml/litehtml/CMakeLists.txt)|!isEmpty(LITEHTML_INSTALL_DIR) {
    include(qlitehtml/qlitehtml.pri)
    HEADERS += litehtmlhelpviewer.h
    SOURCES += litehtmlhelpviewer.cpp
    DEFINES += QTC_LITEHTML_HELPVIEWER
}
```

如果删除这个 `CMakeLists.txt`，且没有设置 `LITEHTML_INSTALL_DIR` 环境变量，litehtml 帮助查看器功能将被跳过。**保留这一个文件不影响"去除 CMake 构建痕迹"的目标**——它只是被用作"litehtml 源码是否存在"的检测标志。

**执行命令**：
```bash
# 先备份这一个文件
cp src/plugins/help/qlitehtml/litehtml/CMakeLists.txt /tmp/litehtml_CMakeLists.txt.bak

# 删除所有 CMakeLists.txt
find . -name "CMakeLists.txt" -type f -delete

# 恢复那一个文件
cp /tmp/litehtml_CMakeLists.txt.bak src/plugins/help/qlitehtml/litehtml/CMakeLists.txt
```

### 步骤 1.5 — 删除所有 `.cmake` 文件

共 14 个（包括 cmake/ 目录里的，如果步骤 1.1 已执行则剩余的散落在其他位置）：

```
src/libs/3rdparty/syntax-highlighting/src/lib/CMakeLists.txt  # 已在 1.4 删除
src/plugins/help/qlitehtml/litehtml/src/gumbo/CMakeLists.txt  # 已在 1.4 删除
```

散落的 `.cmake` 文件：
```
src/libs/3rdparty/syntax-highlighting/KF5SyntaxHighlightingConfig.cmake.in
src/plugins/help/qlitehtml/litehtml/litehtmlConfig.cmake
src/plugins/help/qlitehtml/litehtml/src/gumbo/yaml-cpp.pc.cmake
```

**执行命令**：
```bash
find . -name "*.cmake" -type f -delete
find . -name "*.cmake.in" -type f -delete
```

---

## 四、阶段二：删除 `cmakeprojectmanager` 插件目录

### 步骤 2.1 — 删除整个 `src/plugins/cmakeprojectmanager/` 目录

该目录包含 74 个文件，是 CMake 项目管理器插件的全部实现代码。

**执行命令**：
```bash
rm -rf src/plugins/cmakeprojectmanager/
```

---

## 五、阶段三：修改外部源码文件

这是最关键的阶段。以下每个文件的修改都给出**精确的行号和改动内容**。

### 步骤 3.1 — 修改 `src/plugins/plugins.pro`

**文件**：`src/plugins/plugins.pro`

**改动**：删除第 28 行

第 26-30 行原内容：
```qmake
    debugger \
    cpaster \
    cmakeprojectmanager \
    mesonprojectmanager \
    autotoolsprojectmanager \
```

改为：
```qmake
    debugger \
    cpaster \
    mesonprojectmanager \
    autotoolsprojectmanager \
```

**操作**：删除包含 `cmakeprojectmanager \` 的那一行（第 28 行）。

---

### 步骤 3.2 — 修改 `src/plugins/projectexplorer/desktoprunconfiguration.h`

**文件**：`src/plugins/projectexplorer/desktoprunconfiguration.h`

**改动**：删除第 46-50 行的 `CMakeRunConfigurationFactory` 类声明

第 44-52 行原内容：
```cpp
class QbsRunConfigurationFactory final : public RunConfigurationFactory
{
public:
    QbsRunConfigurationFactory();
};

class CMakeRunConfigurationFactory final : public RunConfigurationFactory
{
public:
    CMakeRunConfigurationFactory();
};
```

改为：
```cpp
class QbsRunConfigurationFactory final : public RunConfigurationFactory
{
public:
    QbsRunConfigurationFactory();
};
```

**操作**：删除第 46-50 行（含空行），即 `CMakeRunConfigurationFactory` 类的完整声明。

---

### 步骤 3.3 — 修改 `src/plugins/projectexplorer/desktoprunconfiguration.cpp`

**文件**：`src/plugins/projectexplorer/desktoprunconfiguration.cpp`

**共 6 处改动**：

#### 改动 3.3.1 — 删除 `#include`（第 34 行）

第 33-36 行原内容：
```cpp
#include <qmakeprojectmanager/qmakeprojectmanagerconstants.h>
#include <cmakeprojectmanager/cmakeprojectconstants.h>
#include <qbsprojectmanager/qbsprojectmanagerconstants.h>
```

改为：
```cpp
#include <qmakeprojectmanager/qmakeprojectmanagerconstants.h>
#include <qbsprojectmanager/qbsprojectmanagerconstants.h>
```

#### 改动 3.3.2 — 修改枚举（第 55 行）

第 55 行原内容：
```cpp
    enum Kind { Qmake, Qbs, CMake }; // FIXME: Remove
```

改为：
```cpp
    enum Kind { Qmake, Qbs }; // FIXME: Remove
```

#### 改动 3.3.3 — 删除 CMake 分支（第 141-145 行）

第 139-146 行原内容：
```cpp
    } else if (m_kind == Qbs) {
        // ... Qbs 分支代码 ...
    } else if (m_kind == CMake) {

        aspect<ExecutableAspect>()->setExecutable(bti.targetFilePath);
        aspect<WorkingDirectoryAspect>()->setDefaultWorkingDirectory(bti.workingDirectory);
        aspect<LocalEnvironmentAspect>()->environmentChanged();

    }
```

改为：
```cpp
    } else if (m_kind == Qbs) {
        // ... Qbs 分支代码 ...
    }
```

**操作**：删除 `} else if (m_kind == CMake) {` 到对应的 `}` 之间的全部代码（约第 141-146 行）。

#### 改动 3.3.4 — 删除 `CMakeRunConfiguration` 类定义（第 184-190 行）

第 184-190 行原内容：
```cpp
class CMakeRunConfiguration final : public DesktopRunConfiguration
{
public:
    CMakeRunConfiguration(Target *target, Utils::Id id)
        : DesktopRunConfiguration(target, id, CMake)
    {}
};
```

**操作**：删除这 7 行。

#### 改动 3.3.5 — 删除 `CMAKE_RUNCONFIG_ID` 常量和工厂实现（第 194-200 行）

第 192-201 行原内容：
```cpp
const char QMAKE_RUNCONFIG_ID[] = "Qt4ProjectManager.Qt4RunConfiguration:";
const char QBS_RUNCONFIG_ID[]   = "Qbs.RunConfiguration:";
const char CMAKE_RUNCONFIG_ID[] = "CMakeProjectManager.CMakeRunConfiguration.";

CMakeRunConfigurationFactory::CMakeRunConfigurationFactory()
{
    registerRunConfiguration<CMakeRunConfiguration>(CMAKE_RUNCONFIG_ID);
    addSupportedProjectType(CMakeProjectManager::Constants::CMAKE_PROJECT_ID);
    addSupportedTargetDeviceType(ProjectExplorer::Constants::DESKTOP_DEVICE_TYPE);
}
```

改为：
```cpp
const char QMAKE_RUNCONFIG_ID[] = "Qt4ProjectManager.Qt4RunConfiguration:";
const char QBS_RUNCONFIG_ID[]   = "Qbs.RunConfiguration:";
```

**操作**：删除第 194 行（`CMAKE_RUNCONFIG_ID` 定义）和第 196-200 行（`CMakeRunConfigurationFactory` 构造函数实现）。

---

### 步骤 3.4 — 修改 `src/plugins/projectexplorer/projectexplorer.cpp`

**文件**：`src/plugins/projectexplorer/projectexplorer.cpp`

**共 2 处改动**：

#### 改动 3.4.1 — 删除 `cmakeRunConfigFactory` 成员变量声明（第 655 行）

第 653-656 行原内容：
```cpp
    DesktopQmakeRunConfigurationFactory qmakeRunConfigFactory;
    QbsRunConfigurationFactory qbsRunConfigFactory;
    CMakeRunConfigurationFactory cmakeRunConfigFactory;
```

改为：
```cpp
    DesktopQmakeRunConfigurationFactory qmakeRunConfigFactory;
    QbsRunConfigurationFactory qbsRunConfigFactory;
```

#### 改动 3.4.2 — 删除 `cmakeRunConfigFactory` 引用（第 662 行）

第 657-663 行原内容：
```cpp
    RunWorkerFactory desktopRunWorkerFactory{
        RunWorkerFactory::make<SimpleTargetRunner>(),
        {ProjectExplorer::Constants::NORMAL_RUN_MODE},
        {qmakeRunConfigFactory.runConfigurationId(),
         qbsRunConfigFactory.runConfigurationId(),
         cmakeRunConfigFactory.runConfigurationId()}
    };
```

改为：
```cpp
    RunWorkerFactory desktopRunWorkerFactory{
        RunWorkerFactory::make<SimpleTargetRunner>(),
        {ProjectExplorer::Constants::NORMAL_RUN_MODE},
        {qmakeRunConfigFactory.runConfigurationId(),
         qbsRunConfigFactory.runConfigurationId()}
    };
```

**操作**：删除第 662 行 `cmakeRunConfigFactory.runConfigurationId()}`，并将第 661 行末尾的逗号去掉（`qbsRunConfigFactory.runConfigurationId()}` 变为闭合）。

---

### 步骤 3.5 — 修改 `src/plugins/projectexplorer/simpleprojectwizard.cpp`

**文件**：`src/plugins/projectexplorer/simpleprojectwizard.cpp`

**共 6 处改动**：

#### 改动 3.5.1 — 删除 `#include`（第 35 行）

第 34-36 行原内容：
```cpp
#include <qmakeprojectmanager/qmakeprojectmanagerconstants.h>
#include <cmakeprojectmanager/cmakeprojectconstants.h>

```

改为：
```cpp
#include <qmakeprojectmanager/qmakeprojectmanagerconstants.h>

```

#### 改动 3.5.2 — 修改 comboBox 选项（第 112 行）

第 112 行原内容：
```cpp
        comboBox->addItems(QStringList() << "qmake" << "cmake");
```

改为：
```cpp
        comboBox->addItems(QStringList() << "qmake");
```

#### 改动 3.5.3 — 修改 `setSupportedProjectTypes`（第 170-171 行）

第 170-171 行原内容：
```cpp
    setSupportedProjectTypes({QmakeProjectManager::Constants::QMAKEPROJECT_ID,
                              CMakeProjectManager::Constants::CMAKE_PROJECT_ID});
```

改为：
```cpp
    setSupportedProjectTypes({QmakeProjectManager::Constants::QMAKEPROJECT_ID});
```

#### 改动 3.5.4 — 修改显示文本（第 173 行）

第 173 行原内容：
```cpp
    setDisplayName(tr("Import as qmake or cmake Project (Limited Functionality)"));
```

改为：
```cpp
    setDisplayName(tr("Import as qmake Project (Limited Functionality)"));
```

#### 改动 3.5.5 — 修改描述文本（第 175 行）

第 175 行原内容：
```cpp
    setDescription(tr("Imports existing projects that do not use qmake, CMake or Autotools.<p>"
```

改为：
```cpp
    setDescription(tr("Imports existing projects that do not use qmake or Autotools.<p>"
```

#### 改动 3.5.6 — 删除 `generateCmakeFiles` 函数和调用

**第 255-330 行**：删除整个 `generateCmakeFiles` 函数定义（约 76 行）。

第 255-330 行原内容：
```cpp
GeneratedFiles generateCmakeFiles(const SimpleProjectWizardDialog *wizard,
                                  QString *errorMessage)
{
    Q_UNUSED(errorMessage)
    const QString projectPath = wizard->path();
    // ... 约 70 行 CMakeLists.txt 生成代码 ...
    return GeneratedFiles{generatedProFile};
}
```

**操作**：从 `GeneratedFiles generateCmakeFiles(` 开始，到其对应的闭合 `}` 为止，整个函数删除。

**第 343-344 行**（在删除 generateCmakeFiles 后行号会前移）：删除 cmake 分支调用。

原内容：
```cpp
    if (wizard->buildSystem() == "qmake")
        return generateQmakeFiles(wizard, errorMessage);
    else if (wizard->buildSystem() == "cmake")
        return generateCmakeFiles(wizard, errorMessage);
```

改为：
```cpp
    if (wizard->buildSystem() == "qmake")
        return generateQmakeFiles(wizard, errorMessage);
```

---

### 步骤 3.6 — 修改 `src/plugins/mcusupport/mcusupport_dependencies.pri`

**文件**：`src/plugins/mcusupport/mcusupport_dependencies.pri`

第 7-12 行原内容：
```qmake
QTC_PLUGIN_DEPENDS += \
    coreplugin \
    projectexplorer \
    debugger \
    cmakeprojectmanager \
    qtsupport
```

改为：
```qmake
QTC_PLUGIN_DEPENDS += \
    coreplugin \
    projectexplorer \
    debugger \
    qtsupport
```

**操作**：删除第 11 行 `cmakeprojectmanager \`。

---

### 步骤 3.7 — 修改 `src/plugins/mcusupport/mcusupportoptionspage.cpp`

**文件**：`src/plugins/mcusupport/mcusupportoptionspage.cpp`

**共 3 处改动**：

#### 改动 3.7.1 — 删除 `#include`（第 30-31 行）

第 29-32 行原内容：
```cpp
#include "mcusupportoptions.h"

#include <cmakeprojectmanager/cmakeprojectconstants.h>
#include <cmakeprojectmanager/cmaketoolmanager.h>
#include <coreplugin/icore.h>
```

改为：
```cpp
#include "mcusupportoptions.h"

#include <coreplugin/icore.h>
```

#### 改动 3.7.2 — 修改 linkActivated 回调（第 94-96 行）

第 94-96 行原内容：
```cpp
        connect(m_statusInfoLabel, &QLabel::linkActivated, this, [] {
            Core::ICore::showOptionsDialog(CMakeProjectManager::Constants::CMAKE_SETTINGS_PAGE_ID);
        });
```

改为：
```cpp
        connect(m_statusInfoLabel, &QLabel::linkActivated, this, [] {
            Core::ICore::showOptionsDialog("CMakeProjectManager.CMakeSettingsPage");
        });
```

**说明**：将编译期常量引用替换为等价的字符串字面量。这样不需要 #include cmakeprojectconstants.h 也能正常工作（Options 对话框的 ID 匹配是字符串匹配）。

#### 改动 3.7.3 — 修改 `updateStatus` 中的 CMake 检测（第 165 行）

第 161-207 行中，`cMakeAvailable` 变量使用了 `CMakeProjectManager::CMakeToolManager::cmakeTools()`。

**有两种方案**：

**方案 A（推荐）**：移除 CMake 检测，MCU 页面始终显示：

第 165 行原内容：
```cpp
    const bool cMakeAvailable = !CMakeProjectManager::CMakeToolManager::cmakeTools().isEmpty();
```

改为：
```cpp
    const bool cMakeAvailable = true; // CMake 检测已移除，始终视为可用
```

并删除第 200-206 行的"No CMake tool"提示块：
```cpp
    // Status label in the bottom
    {
        m_statusInfoLabel->setVisible(!cMakeAvailable);
        if (m_statusInfoLabel->isVisible()) {
            m_statusInfoLabel->setType(Utils::InfoLabel::NotOk);
            m_statusInfoLabel->setText("No CMake tool was detected. Add a CMake tool in the "
                                       "<a href=\"cmake\">CMake options</a> and press Apply.");
        }
    }
```

改为：
```cpp
    // Status label in the bottom
    {
        m_statusInfoLabel->setVisible(false);
    }
```

**方案 B**：使用 `QStandardPaths` 自行检测 cmake 可执行文件（不依赖 CMakeProjectManager 插件）：

```cpp
    const bool cMakeAvailable = !QStandardPaths::findExecutable("cmake").isEmpty();
```

需要在文件头部加 `#include <QStandardPaths>`。

---

### 步骤 3.8 — 修改 `src/plugins/mcusupport/mcusupportoptions.cpp`

**文件**：`src/plugins/mcusupport/mcusupportoptions.cpp`

这是改动量最大的单个文件。`mcusupport` 插件与 `CMakeProjectManager` 深度耦合。

**共 5 处改动**：

#### 改动 3.8.1 — 删除 `#include`（第 30 行和第 33 行）

第 29-34 行原内容：
```cpp

#include <cmakeprojectmanager/cmaketoolmanager.h>
#include <coreplugin/icore.h>
#include <coreplugin/helpmanager.h>
#include <cmakeprojectmanager/cmakekitinformation.h>
#include <debugger/debuggeritem.h>
```

改为：
```cpp

#include <coreplugin/icore.h>
#include <coreplugin/helpmanager.h>
#include <debugger/debuggeritem.h>
```

#### 改动 3.8.2 — 修改 `setKitEnvironment` 函数（第 581-584 行）

第 580-585 行原内容：
```cpp
    // If CMake's fileApi is avaialble, we can rely on the "Add library search path to PATH"
    // feature of the run configuration. Otherwise, we just prepend the path, here.
    if (mcuTarget->toolChainPackage()->isDesktopToolchain()
            && !CMakeProjectManager::CMakeToolManager::defaultCMakeTool()->hasFileApi())
        pathAdditions.append(QDir::toNativeSeparators(qtForMCUsSdkPackage->path() + "/bin"));
```

改为：
```cpp
    // 始终将 Qul bin 路径加入 PATH（CMake fileApi 检测已移除）
    if (mcuTarget->toolChainPackage()->isDesktopToolchain())
        pathAdditions.append(QDir::toNativeSeparators(qtForMCUsSdkPackage->path() + "/bin"));
```

**说明**：移除对 `CMakeToolManager::defaultCMakeTool()->hasFileApi()` 的调用。简化为始终添加 bin 路径。这是安全的——多加一个 PATH 路径不会造成副作用。

#### 改动 3.8.3 — 重写 `setKitCMakeOptions` 函数（第 605-637 行）

这是最复杂的一处改动。原函数使用了 `CMakeProjectManager` 的以下 API：
- `CMakeProjectManager::CMakeConfig`
- `CMakeProjectManager::CMakeConfigItem`
- `CMakeProjectManager::CMakeConfigurationKitAspect::configuration()`
- `CMakeProjectManager::CMakeConfigurationKitAspect::setConfiguration()`
- `CMakeProjectManager::CMakeGeneratorKitAspect::setGenerator()`

第 605-637 行原内容：
```cpp
static void setKitCMakeOptions(ProjectExplorer::Kit *k, const McuTarget* mcuTarget,
                               const QString &qulDir)
{
    using namespace CMakeProjectManager;

    CMakeConfig config = CMakeConfigurationKitAspect::configuration(k);
    // CMake ToolChain file for ghs handles CMAKE_*_COMPILER autonomously
    if (mcuTarget->toolChainPackage()->type() != McuToolChainPackage::TypeGHS) {
        config.append(CMakeConfigItem("CMAKE_CXX_COMPILER", "%{Compiler:Executable:Cxx}"));
        config.append(CMakeConfigItem("CMAKE_C_COMPILER", "%{Compiler:Executable:C}"));
    }
    if (!mcuTarget->toolChainPackage()->isDesktopToolchain())
        config.append(CMakeConfigItem(
                          "CMAKE_TOOLCHAIN_FILE",
                          (qulDir + "/lib/cmake/Qul/toolchain/"
                           + mcuTarget->toolChainPackage()->cmakeToolChainFileName()).toUtf8()));
    config.append(CMakeConfigItem("QUL_GENERATORS",
                                  (qulDir + "/lib/cmake/Qul/QulGenerators.cmake").toUtf8()));
    config.append(CMakeConfigItem("QUL_PLATFORM",
                                  mcuTarget->platform().name.toUtf8()));

    if (mcuTarget->qulVersion() <= QVersionNumber{1,3} // OS variable was removed in Qul 1.4
        && mcuTarget->os() == McuTarget::OS::FreeRTOS)
        config.append(CMakeConfigItem("OS", "FreeRTOS"));
    if (mcuTarget->colorDepth() >= 0)
        config.append(CMakeConfigItem("QUL_COLOR_DEPTH",
                                      QString::number(mcuTarget->colorDepth()).toLatin1()));
    const Utils::FilePath jom = jomExecutablePath();
    if (jom.exists()) {
        config.append(CMakeConfigItem("CMAKE_MAKE_PROGRAM", jom.toString().toLatin1()));
        CMakeGeneratorKitAspect::setGenerator(k, "NMake Makefiles JOM");
    }
    CMakeConfigurationKitAspect::setConfiguration(k, config);
}
```

**有两种方案**：

**方案 A（推荐）**：直接通过 Kit 的通用 `setValue` API 写入 CMake 配置，绕过 CMakeProjectManager 的类型系统：

```cpp
static void setKitCMakeOptions(ProjectExplorer::Kit *k, const McuTarget* mcuTarget,
                               const QString &qulDir)
{
    // 使用 Kit 的通用键值对 API 替代 CMakeProjectManager 的强类型 API
    // CMake 配置在 Kit 内部以 "CMake.ConfigurationKitInformation" 键存储
    QVariantMap configMap;

    if (mcuTarget->toolChainPackage()->type() != McuToolChainPackage::TypeGHS) {
        configMap.insert("CMAKE_CXX_COMPILER", "%{Compiler:Executable:Cxx}");
        configMap.insert("CMAKE_C_COMPILER", "%{Compiler:Executable:C}");
    }
    if (!mcuTarget->toolChainPackage()->isDesktopToolchain())
        configMap.insert("CMAKE_TOOLCHAIN_FILE",
                         qulDir + "/lib/cmake/Qul/toolchain/"
                         + mcuTarget->toolChainPackage()->cmakeToolChainFileName());
    configMap.insert("QUL_GENERATORS",
                     qulDir + "/lib/cmake/Qul/QulGenerators.cmake");
    configMap.insert("QUL_PLATFORM", mcuTarget->platform().name);

    if (mcuTarget->qulVersion() <= QVersionNumber{1,3}
        && mcuTarget->os() == McuTarget::OS::FreeRTOS)
        configMap.insert("OS", "FreeRTOS");
    if (mcuTarget->colorDepth() >= 0)
        configMap.insert("QUL_COLOR_DEPTH", QString::number(mcuTarget->colorDepth()));

    const Utils::FilePath jom = jomExecutablePath();
    if (jom.exists()) {
        configMap.insert("CMAKE_MAKE_PROGRAM", jom.toString());
        k->setValue("CMake.GeneratorKitInformation", "NMake Makefiles JOM");
    }

    k->setValue("CMake.ConfigurationKitInformation", configMap);
}
```

**⚠️ 注意**：方案 A 的键值格式可能与 CMakeProjectManager 内部的序列化格式不完全兼容。如果 MCU 功能在你的定制版本中不需要，**方案 B 更安全**。

**方案 B**：将函数体清空（MCU 支持不使用 CMake 配置）：

```cpp
static void setKitCMakeOptions(ProjectExplorer::Kit *k, const McuTarget* mcuTarget,
                               const QString &qulDir)
{
    Q_UNUSED(k)
    Q_UNUSED(mcuTarget)
    Q_UNUSED(qulDir)
    // CMakeProjectManager 已移除，CMake Kit 配置不再设置
}
```

#### 改动 3.8.4 — 修改 `setKitProperties` 中的 CMake.GeneratorKitInformation（第 534-535 行）

第 530-536 行原内容：
```cpp
    QSet<Utils::Id> irrelevant = {
        SysRootKitAspect::id(),
        QtSupport::QtKitAspect::id()
    };
    if (jomExecutablePath().exists()) // TODO: add id() getter to CMakeGeneratorKitAspect
        irrelevant.insert("CMake.GeneratorKitInformation");
    k->setIrrelevantAspects(irrelevant);
```

改为：
```cpp
    QSet<Utils::Id> irrelevant = {
        SysRootKitAspect::id(),
        QtSupport::QtKitAspect::id()
    };
    k->setIrrelevantAspects(irrelevant);
```

**操作**：删除第 534-535 行（jom 检测和 CMake.GeneratorKitInformation 插入）。

#### 改动 3.8.5 — 修改 `registerDocumentation` 中的 quickultralitecmake.qch（第 450 行）

第 448-451 行原内容：
```cpp
    const QStringList qchFiles = {
        docsDir + "/quickultralite.qch",
        docsDir + "/quickultralitecmake.qch"
    };
```

改为：
```cpp
    const QStringList qchFiles = {
        docsDir + "/quickultralite.qch"
    };
```

**操作**：删除第 450 行。

---

### 步骤 3.9 — 修改 `src/plugins/mcusupport/mcusupportrunconfiguration.cpp`

**文件**：`src/plugins/mcusupport/mcusupportrunconfiguration.cpp`

**共 2 处改动**：

#### 改动 3.9.1 — 删除 `#include` 并替换 cmake 工具查找（第 36-49 行）

第 35-49 行原内容：
```cpp
#include <projectexplorer/target.h>
#include <cmakeprojectmanager/cmakekitinformation.h>
#include <cmakeprojectmanager/cmaketool.h>

using namespace ProjectExplorer;
using namespace Utils;

namespace McuSupport {
namespace Internal {

static FilePath cmakeFilePath(const Target *target)
{
    const CMakeProjectManager::CMakeTool *tool =
            CMakeProjectManager::CMakeKitAspect::cmakeTool(target->kit());
    return tool->filePath();
}
```

改为：
```cpp
#include <projectexplorer/target.h>

#include <QStandardPaths>

using namespace ProjectExplorer;
using namespace Utils;

namespace McuSupport {
namespace Internal {

static FilePath cmakeFilePath(const Target *target)
{
    Q_UNUSED(target)
    // CMakeProjectManager 已移除，直接在 PATH 中查找 cmake 可执行文件
    const QString cmakePath = QStandardPaths::findExecutable("cmake");
    return FilePath::fromString(cmakePath);
}
```

**说明**：原代码通过 Kit 关联的 CMakeTool 获取 cmake 路径。移除 CMakeProjectManager 后，改为在系统 PATH 中直接查找 cmake。

#### 改动 3.9.2 — 修改标签文本（第 71 行）

第 71 行原内容：
```cpp
        flashAndRunParameters->setLabelText(tr("Flash and run CMake parameters:"));
```

这是纯 UI 字符串，**可以保留不改**——因为 MCU flash 确实使用 cmake 命令。如果想彻底清理，改为：
```cpp
        flashAndRunParameters->setLabelText(tr("Flash and run parameters:"));
```

---

### 步骤 3.10 — 修改 `src/plugins/mcusupport/mcusupport.qrc`

**文件**：`src/plugins/mcusupport/mcusupport.qrc`

第 9 行原内容：
```xml
        <file>wizards/application/CMakeLists.txt</file>
```

**保留不改**。这个 CMakeLists.txt 是 MCU 应用程序的项目模板文件（不是 Qt Creator 自身的构建文件），MCU 项目需要它。如果你确定不使用 MCU 功能，可以删除。

---

### 步骤 3.11 — 修改 `src/plugins/incredibuild/incredibuild_dependencies.pri`

**文件**：`src/plugins/incredibuild/incredibuild_dependencies.pri`

第 8-10 行原内容：
```qmake
QTC_PLUGIN_RECOMMENDS += \
        qmakeprojectmanager \
        cmakeprojectmanager
```

改为：
```qmake
QTC_PLUGIN_RECOMMENDS += \
        qmakeprojectmanager
```

**操作**：删除第 10 行 `cmakeprojectmanager`。

---

### 步骤 3.12 — 处理 `src/plugins/incredibuild/` 的 CMake 构建器

**涉及文件**：
- `src/plugins/incredibuild/cmakecommandbuilder.h`（56 行）
- `src/plugins/incredibuild/cmakecommandbuilder.cpp`（108 行）
- `src/plugins/incredibuild/incredibuild.pro`
- `src/plugins/incredibuild/buildconsolebuildstep.cpp`
- `src/plugins/incredibuild/ibconsolebuildstep.cpp`

**⚠️ 重要说明**：这两个文件（`cmakecommandbuilder.h/cpp`）是 incredibuild 插件**自己的**代码，**不** `#include` 任何 `cmakeprojectmanager` 的头文件。它们内部的 `"CMakeProjectManager::Internal::CMakeBuildStep"` 是运行时字符串匹配，不是编译依赖。

**方案 A（彻底移除 CMake 构建器）**：

1. 删除文件：
```bash
rm src/plugins/incredibuild/cmakecommandbuilder.h
rm src/plugins/incredibuild/cmakecommandbuilder.cpp
```

2. 修改 `incredibuild.pro`，删除第 16 行和第 24 行：
```
第 16 行：cmakecommandbuilder.cpp \
第 24 行：cmakecommandbuilder.h \
```

3. 修改 `buildconsolebuildstep.cpp`：

第 29 行原内容：
```cpp
#include "cmakecommandbuilder.h"
```
**删除这一行。**

第 285 行原内容：
```cpp
    m_commandBuildersList.push_back(new CMakeCommandBuilder(this));
```
**删除这一行。**

4. 修改 `ibconsolebuildstep.cpp`：

第 28 行原内容：
```cpp
#include "cmakecommandbuilder.h"
```
**删除这一行。**

第 165 行原内容：
```cpp
    m_commandBuildersList.push_back(new CMakeCommandBuilder(this));
```
**删除这一行。**

**方案 B（保留，因为不影响编译）**：

这些文件不依赖 `cmakeprojectmanager` 插件的任何头文件，编译不会报错。如果不在意 incredibuild 插件中保留一个"CMake 构建器"功能选项，可以不改。

---

### 步骤 3.13 — 修改 sdktool（`src/tools/sdktool/`）

sdktool 是 Qt Creator 的 SDK 配置命令行工具，其中有 4 个文件专门处理 CMake 工具配置：

- `addcmakeoperation.h`（61 行）
- `addcmakeoperation.cpp`（~170 行）
- `rmcmakeoperation.h`（52 行）
- `rmcmakeoperation.cpp`（~130 行）

以及在其他文件中有引用。

**方案 A（彻底移除 CMake 操作）**：

#### 步骤 3.13.1 — 删除 4 个 CMake 操作文件

```bash
rm src/tools/sdktool/addcmakeoperation.h
rm src/tools/sdktool/addcmakeoperation.cpp
rm src/tools/sdktool/rmcmakeoperation.h
rm src/tools/sdktool/rmcmakeoperation.cpp
```

#### 步骤 3.13.2 — 修改 `sdktool.pro`

删除以下 4 行（行号：14、26、47、59）：

```
第 14 行：    addcmakeoperation.cpp \
第 26 行：    rmcmakeoperation.cpp \
第 47 行：    addcmakeoperation.h \
第 59 行：    rmcmakeoperation.h \
```

#### 步骤 3.13.3 — 修改 `main.cpp`

第 30 行原内容：
```cpp
#include "addcmakeoperation.h"
```
**删除这一行。**

第 42 行（原行号）原内容：
```cpp
#include "rmcmakeoperation.h"
```
**删除这一行。**

第 186 行（原行号）原内容：
```cpp
    operations.emplace_back(std::make_unique<AddCMakeOperation>());
```
**删除这一行。**

第 197 行（原行号）原内容：
```cpp
    operations.emplace_back(std::make_unique<RmCMakeOperation>());
```
**删除这一行。**

#### 步骤 3.13.4 — 修改 `addkitoperation.h`

第 28 行（如果有 `#include "addcmakeoperation.h"` 前置声明或引用）及函数参数中的 cmake 相关参数。

`addKit()` 静态方法签名（约第 48-60 行）中包含参数 `cmakeId`、`cmakeGenerator`、`cmakeExtraGenerator`、`cmakeGeneratorToolset`、`cmakeGeneratorPlatform`、`cmakeConfiguration`。

**有两种方案**：

- **方案 A1**：从函数签名中删除所有 cmake 参数，并修改所有调用点。这会导致大量改动。
- **方案 A2（推荐）**：保留函数签名，但在实现中忽略 cmake 参数（传空值）。这样改动最小。

如果选择 **方案 A2**：

修改 `addkitoperation.cpp` 第 28 行：
```cpp
#include "addcmakeoperation.h"
```
**删除这一行。**

第 70-72 行原内容：
```cpp
const char CMAKE_ID[] = "CMakeProjectManager.CMakeKitInformation";
const char CMAKE_GENERATOR[] = "CMake.GeneratorKitInformation";
const char CMAKE_CONFIGURATION[] = "CMake.ConfigurationKitInformation";
```

**保留这些字符串常量**——它们是 Kit 数据键名，不依赖任何 #include。

第 605-611 行有对 `AddCMakeOperation::exists()` 的调用：
```cpp
    if (!cmakeId.isEmpty() && !AddCMakeOperation::exists(cmakeMap, cmakeId)) {
```

改为：
```cpp
    if (!cmakeId.isEmpty()) {
        // AddCMakeOperation 已移除，跳过 CMake 工具存在性检查
    }
```

或直接删除整个 cmake 校验块。

#### 步骤 3.13.5 — 修改 `settings.cpp`

第 61-63 行原内容：
```cpp
    const QStringList identical
            = QStringList({ "android", "cmaketools", "debuggers", "devices",
                            "profiles", "qtversions", "toolchains", "abi" });
    if (lowerFile == "cmake")
        result = result.pathAppended("cmaketools");
```

**可以保留不改**——这只是文件路径映射逻辑，不依赖任何 cmake 头文件。删了也不影响编译，但会导致 `sdktool cmake` 子命令无法找到正确的配置文件路径。

**方案 B（保留 sdktool 的 CMake 操作）**：

sdktool 是独立的命令行工具，其 CMake 操作文件不依赖 `cmakeprojectmanager` 插件。保留这些文件**不影响编译**，也不影响"去除 CMake 构建痕迹"的目标。如果用户仍然需要通过 sdktool 管理 CMake 工具配置（比如 CI 环境中），建议保留。

---

## 六、阶段四：清理向导模板和文档

### 步骤 4.1 — 清理 `share/qtcreator/templates/wizards/` 中的 wizard.json

以下 10 个 `wizard.json` 文件包含 CMake 引用：

| # | 文件路径 |
|---|---------|
| 1 | `share/qtcreator/templates/wizards/autotest/wizard.json` |
| 2 | `share/qtcreator/templates/wizards/projects/consoleapp/wizard.json` |
| 3 | `share/qtcreator/templates/wizards/projects/cpplibrary/wizard.json` |
| 4 | `share/qtcreator/templates/wizards/projects/plainc/wizard.json` |
| 5 | `share/qtcreator/templates/wizards/projects/plaincpp/wizard.json` |
| 6 | `share/qtcreator/templates/wizards/projects/qtquickapplication/empty/wizard.json` |
| 7 | `share/qtcreator/templates/wizards/projects/qtquickapplication/scroll/wizard.json` |
| 8 | `share/qtcreator/templates/wizards/projects/qtquickapplication/stack/wizard.json` |
| 9 | `share/qtcreator/templates/wizards/projects/qtquickapplication/swipe/wizard.json` |
| 10 | `share/qtcreator/templates/wizards/projects/qtwidgetsapplication/wizard.json` |

**每个 `wizard.json` 中需要修改的内容模式**（以 `consoleapp/wizard.json` 为例）：

#### 4.1.1 — `supportedProjectTypes` 数组

原内容：
```json
"supportedProjectTypes": [ "CMakeProjectManager.CMakeProject", "QmakeProjectManager.QmakeProject", "QbsProjectManager.QbsProject", "MesonProjectManager.MesonProject" ],
```

改为（删除 `CMakeProjectManager.CMakeProject`）：
```json
"supportedProjectTypes": [ "QmakeProjectManager.QmakeProject", "QbsProjectManager.QbsProject", "MesonProjectManager.MesonProject" ],
```

#### 4.1.2 — `options` 中的 CMake 条件

找到类似以下内容：
```json
{ "key": "CMakeFile", "value": "%{ProjectDirectory}/CMakeLists.txt" }
```
**删除这一行**。

#### 4.1.3 — `enabled` 条件中的 CMakeProjectManager 检查

找到类似：
```json
"enabled": "%{JS: value('Plugins').indexOf('CMakeProjectManager') >= 0 || ...}"
```

删除 `value('Plugins').indexOf('CMakeProjectManager') >= 0 ||` 部分。

#### 4.1.4 — `pages` 中的构建系统选择页

在 `"Define Build System"` 页面的 ComboBox 选项中，找到：
```json
{
    "trKey": "CMake",
    "value": "cmake",
    "condition": "%{JS: value('Plugins').indexOf('CMakeProjectManager') >= 0}"
}
```
**删除这一个对象**。

#### 4.1.5 — `generators` 中的 CMake 文件生成

找到类似：
```json
{
    "source": "CMakeLists.txt",
    "openAsProject": true,
    "condition": "%{JS: value('BuildSystem') === 'cmake'}"
}
```
**删除这一个对象**。

#### 4.1.6 — `options` 中的 ProjectFile CMake 条件

找到类似：
```json
{ "key": "ProjectFile", "value": "%{JS: value('BuildSystem') === 'cmake' ? value('CMakeFile') : ...}" }
```

简化为去掉 cmake 分支。

**每个 wizard.json 都需要单独检查并修改**，因为各文件的结构略有差异。

---

### 步骤 4.2 — 删除 wizard 模板中的 CMakeLists.txt 文件

以下 6 个 CMakeLists.txt 是向导模板文件（不是 Qt Creator 自身的构建文件）：

```
share/qtcreator/templates/wizards/projects/consoleapp/CMakeLists.txt
share/qtcreator/templates/wizards/projects/cpplibrary/CMakeLists.txt
share/qtcreator/templates/wizards/projects/plainc/CMakeLists.txt
share/qtcreator/templates/wizards/projects/plaincpp/CMakeLists.txt
share/qtcreator/templates/wizards/projects/qtquickapplication/CMakeLists.txt
share/qtcreator/templates/wizards/projects/qtwidgetsapplication/CMakeLists.txt
```

**执行命令**：
```bash
rm share/qtcreator/templates/wizards/projects/consoleapp/CMakeLists.txt
rm share/qtcreator/templates/wizards/projects/cpplibrary/CMakeLists.txt
rm share/qtcreator/templates/wizards/projects/plainc/CMakeLists.txt
rm share/qtcreator/templates/wizards/projects/plaincpp/CMakeLists.txt
rm share/qtcreator/templates/wizards/projects/qtquickapplication/CMakeLists.txt
rm share/qtcreator/templates/wizards/projects/qtwidgetsapplication/CMakeLists.txt
```

---

### 步骤 4.3 — 删除 CMake 文档文件

#### 文档源文件（3 个）：
```bash
rm -rf doc/qtcreator/src/cmake/
```

这将删除：
- `doc/qtcreator/src/cmake/creator-projects-cmake.qdoc`
- `doc/qtcreator/src/cmake/creator-projects-cmake-building.qdocinc`
- `doc/qtcreator/src/cmake/creator-projects-cmake-deploying.qdocinc`

#### CMake 相关截图（9 个）：
```bash
rm doc/qtcreator/images/qtcreator-cmake-build-settings.png
rm doc/qtcreator/images/qtcreator-build-steps-cmake-ninja.png
rm doc/qtcreator/images/qtcreator-cmakeexecutable.png
rm doc/qtcreator/images/qtcreator-cmake-run-cmake.png
rm doc/qtcreator/images/qtcreator-cmake-run-settings.png
rm doc/qtcreator/images/qtcreator-android-cmake-settings.png
rm doc/qtcreator/images/qtcreator-cmake-build-steps.png
rm doc/qtcreator/images/qtcreator-kits-cmake.png
rm doc/qtcreator/images/qtcreator-cmake-clean-steps.png
```

#### 修改引用了 CMake 文档的其他 .qdoc 文件

以下文件引用了 CMake 文档页面或包含了 CMake 的 `.qdocinc` 文件，需要逐一修改：

| 文件 | 引用类型 | 处理方式 |
|------|---------|---------|
| `doc/qtcreator/src/projects/creator-only/creator-projects-other.qdoc` 第 35、46-48 行 | `\nextpage creator-project-cmake.html`、CMake 描述段落 | 删除 CMake 相关段落，修改 `\nextpage` |
| `doc/qtcreator/src/projects/creator-only/creator-projects-settings-build.qdoc` 第 47-54、125、144、161-162、181、228 行 | `\include creator-projects-cmake-building.qdocinc` | 删除所有 `\include ...cmake...` 行和 CMake 描述文本 |
| `doc/qtcreator/src/projects/creator-only/creator-projects-building.qdoc` 第 99、118-129 行 | "Building with CMake" 章节 | 删除整个 CMake 构建章节 |
| `doc/qtcreator/src/projects/creator-only/creator-projects-opening.qdoc` 第 84-85 行 | 提及 CMakeLists.txt | 删除 CMake 文件类型说明 |
| `doc/qtcreator/src/projects/creator-only/creator-projects-targets.qdoc` 第 71、165-178、196 行 | CMake Tool/Generator/Configuration 配置说明 | 删除 CMake 配置段落 |
| `doc/qtcreator/src/projects/creator-only/creator-projects-settings-run.qdoc` 第 70、119 行 | 提及 CMakeLists.txt 和 CMake | 删除 CMake 提及 |
| `doc/qtcreator/src/projects/creator-only/creator-projects-creating.qdoc` 第 60 行 | 提及 CMake | 删除 CMake 提及 |
| `doc/qtcreator/src/projects/creator-only/creator-projects-generic.qdoc` 第 147-148 行 | 引用 CMake 部署文档 | 删除交叉引用 |
| `doc/qtcreator/src/projects/creator-only/creator-projects-custom-wizards-json.qdocinc` 第 148 行 | `CMakeProjectManager.CMakeProject` | 删除该常量提及 |

---

## 七、不需要改动的文件（纯软引用，不影响编译）

以下文件包含 "cmake" 字样但**不 #include 任何 cmakeprojectmanager 头文件**，不影响编译，可以不改：

| 文件 | 行号 | 内容 | 原因 |
|------|:---:|------|------|
| `projectexplorer/userfileaccessor.cpp` | 478, 788, 799, 807 | `"CMakeProjectManager.CMake..."` 字符串 | 用户 .user 文件格式迁移代码，删除会导致旧项目配置丢失 |
| `projectexplorer/runconfiguration.cpp` | 331 | `// Hack for cmake projects 4.10 -> 4.11.` | 注释 |
| `projectexplorer/target.cpp` | 882 | `// Hack for cmake 4.10 -> 4.11` | 注释 |
| `remotelinux/makeinstallstep.cpp` | 172-195 | `m_isCmakeProject`、`.contains("cmake")` | 运行时字符串匹配检测用户项目类型 |
| `remotelinux/makeinstallstep.h` | 67 | `bool m_isCmakeProject = false;` | 同上 |
| `android/androidbuildapkwidget.cpp` | 375-376 | `projectPath.endsWith("CMakeLists.txt")` | 检测用户项目是否使用 CMake（IDE 功能） |
| `android/androidsettingswidget.cpp` | 172, 406-407, 587-589 | OpenSSL CMakeLists.txt 路径检测 | 检测外部库路径（非 Qt Creator 构建） |
| `qnx/qnxdeployqtlibrariesdialog.cpp` | 261, 275 | `"cmake"` 在文件过滤列表中 | 部署时过滤 cmake 模块文件 |
| `valgrind/valgrindmemcheckparsertest.cpp` | 101 | `// Qbs uses the install-root/bin` | 注释（提及了 cmake 上下文） |

---

## 八、阶段五：验证

### 步骤 5.1 — 搜索残留的编译依赖

```bash
# 搜索 .pro/.pri 文件中的 cmake 引用
grep -rn -i "cmakeprojectmanager" --include="*.pro" --include="*.pri" src/

# 搜索 #include 中的 cmake 引用
grep -rn "#include.*cmake" --include="*.cpp" --include="*.h" src/
```

预期结果：无输出（或仅有保留的软引用）。

### 步骤 5.2 — qmake 配置

```bash
cd qt-creator-opensource-src-4.13.3
qmake qtcreator.pro
```

预期结果：无报错。

### 步骤 5.3 — 全量编译

```bash
make -j$(nproc)
```

预期结果：编译通过，无与 cmake 相关的链接错误。

### 步骤 5.4 — 验证 litehtml 未被跳过

```bash
grep "QTC_LITEHTML_HELPVIEWER" src/plugins/help/Makefile
```

预期结果：应能找到 `DEFINES += QTC_LITEHTML_HELPVIEWER`（说明 litehtml 检测仍然工作）。

---

## 九、完整改动量化

| 阶段 | 操作类型 | 涉及文件/目录数 | 详细说明 |
|:---:|---------|:---:|---------|
| 一 | 删除文件 | ~285 | 269 个 CMakeLists.txt（保留 1 个）+ 14 个 .cmake + 2 个 .cmake.in + cmake/ 目录 + conanfile.txt |
| 二 | 删除目录 | 74 | `src/plugins/cmakeprojectmanager/` 全部 |
| 三 | 修改源码 | 10 个文件 | plugins.pro、desktoprunconfiguration.h/cpp、projectexplorer.cpp、simpleprojectwizard.cpp、mcusupport（4 个文件）、incredibuild_dependencies.pri |
| 三（可选） | 修改/删除 | 6 个文件 | incredibuild 的 CMakeCommandBuilder（2 文件删除 + 2 文件修改）、sdktool（4 文件删除 + 3 文件修改） |
| 四 | 修改 wizard.json | 10 个文件 | 删除 CMake 选项和模板引用 |
| 四 | 删除模板 | 6 个文件 | wizard CMakeLists.txt 模板 |
| 四 | 删除文档 | 12 个文件 | 3 个 .qdoc/.qdocinc + 9 个 .png |
| 四 | 修改文档 | ~9 个文件 | 删除其他 .qdoc 中的 CMake 引用 |

**总计**：删除约 380 个文件，修改约 30 个文件。

---

## 十、风险清单

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| `help.pro` 中 litehtml 检测失效 | Help 插件失去 litehtml HTML 渲染支持 | 保留 `src/plugins/help/qlitehtml/litehtml/CMakeLists.txt` 这一个文件（步骤 1.4 已处理） |
| mcusupport 插件功能受损 | MCU Kit 创建时无法自动配置 CMake 选项 | 使用方案 B（清空 setKitCMakeOptions 函数体）或完全移除 mcusupport 插件 |
| 旧 .user 文件迁移失败 | 用户打开旧版 Creator 创建的 CMake 项目时配置丢失 | 保留 userfileaccessor.cpp 中的字符串不动 |
| wizard.json 修改错误 | 新建项目向导选项异常或崩溃 | 修改后逐一测试每种项目模板的创建向导 |
| sdktool 功能缺失 | CI 环境中无法通过 sdktool 管理 CMake 工具配置 | 保留 sdktool 的 cmake 操作文件（不影响编译） |
| 文档交叉引用断裂 | Qt Creator 帮助文档中出现死链接 | 修改所有引用了 cmake 文档的 .qdoc 文件 |
