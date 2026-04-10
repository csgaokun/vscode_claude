# Qt Creator 4.13.3 源码审查报告：插件系统架构全解析

> **版本**: Qt Creator 4.13.3 (opensource)
> **源码根目录**: `qt-creator-opensource-src-4.13.3/`
> **审查范围**: 插件框架核心、CorePlugin、构建系统、扩展点机制、代表性插件
> **审查目的**: 为裁剪插件系统、构建独立可定制化应用提供完整技术参考

---

## 阅读指引

本报告共 **16 章 + 6 个附录**，约 10 万字。根据你的目标选择阅读路径：

### 路径 A：快速掌握框架全貌（约 2 小时）

| 顺序 | 章节 | 内容 |
|------|------|------|
| 1 | 第 1 章 | 工程全局结构 |
| 2 | 第 3 章 | ExtensionSystem 库（核心） |
| 3 | 第 4 章 | Aggregation 库 |
| 4 | 第 6 章 | 插件生命周期 |
| 5 | 第 8 章 | 对象池与扩展点 |

### 路径 B：裁剪插件系统到独立应用（约 4 小时）

| 顺序 | 章节 | 内容 |
|------|------|------|
| 1 | 路径 A 全部 | 框架全貌 |
| 2 | 第 2 章 | 应用入口与启动流程 |
| 3 | 第 5 章 | 构建系统 |
| 4 | 第 7 章 | 插件元数据与依赖解析 |
| 5 | 第 15 章 | 裁剪方案 |
| 6 | 附录 A | 最小插件系统文件清单 |

### 路径 C：团队插件开发（约 3 小时）

| 顺序 | 章节 | 内容 |
|------|------|------|
| 1 | 第 8 章 | 扩展点机制 |
| 2 | 第 9 章 | CorePlugin 架构 |
| 3 | 第 10 章 | ActionManager 系统 |
| 4 | 第 11 章 | 编辑器管理 |
| 5 | 第 13 章 | HelloWorld 插件（模板） |
| 6 | 第 16 章 | 定制化 UI 方案 |
| 7 | 附录 D | 插件开发速查手册 |

### 重要阅读点标记说明

- \U0001f534 **必读**：理解框架的关键代码，跳过会影响后续理解
- \U0001f7e1 **推荐**：对裁剪和定制有直接帮助
- \U0001f7e2 **参考**：细节补充，按需阅读

---

## 第 1 章 工程全局结构 🔴

### 1.1 顶层目录

```
qt-creator-opensource-src-4.13.3/
├── src/                    # 所有源码
│   ├── app/                # 应用入口 main.cpp（741 行）
│   ├── libs/               # 20 个共享库（1508 个 .h/.cpp 文件）
│   ├── plugins/            # 70+ 个插件（4585 个 .h/.cpp 文件）
│   ├── tools/              # 30+ 个独立工具
│   ├── shared/             # 跨模块复用代码
│   └── *.pri               # 构建模板文件
├── share/                  # 运行时资源（主题、模板、翻译等）
├── tests/                  # 测试套件（1809 个测试文件）
├── scripts/                # 构建部署脚本
├── dist/                   # 版本变更日志
├── doc/                    # 文档
├── qtcreator.pro           # qmake 根项目文件
├── qtcreator.pri           # 全局公共变量
├── qtcreator_ide_branding.pri  # IDE 品牌定制
└── qtcreatordata.pri       # 资源安装路径
```

### 1.2 核心库一览（src/libs/）

> **代码阅读指引**：先看 extensionsystem 和 aggregation，这两个是插件系统骨架。utils 是所有模块的基础设施。其余库按需了解。

| 库名 | 文件数 | 职责 | 裁剪优先级 |
|------|--------|------|-----------|
| **extensionsystem** | 22 | 插件管理核心：加载、依赖解析、生命周期、对象池 | 必须保留 |
| **aggregation** | 6 | 组件组合框架：多接口聚合、类型查询 | 必须保留 |
| **utils** | 288 | 基础设施：文件操作、算法、主题、MIME 类型 | 必须保留 |
| advanceddockingsystem | 42 | 可停靠窗口管理 | 推荐保留 |
| cplusplus | 63 | C++ 解析器 | 可移除 |
| qmljs | 88 | QML/JS 解析器 | 可移除 |
| clangsupport | 213 | Clang 集成支持 | 可移除 |
| modelinglib | 312 | UML 建模 | 可移除 |
| ssh | 25 | SSH/SFTP 客户端 | 可移除 |
| sqlite | 38 | SQLite 数据库封装 | 按需保留 |
| tracing | 48 | 性能追踪 | 可移除 |
| languageserverprotocol | 35 | LSP 协议实现 | 可移除 |
| glsl | 28 | GLSL 着色器解析 | 可移除 |
| qmldebug | 24 | QML 调试协议 | 可移除 |
| qmleditorwidgets | 27 | QML 编辑器控件 | 可移除 |
| languageutils | 5 | 语言工具基础 | 可移除 |
| qt-breakpad | 10 | 崩溃报告 | 可选 |
| qtcreatorcdbext | 33 | Windows CDB 调试扩展 | 可移除 |
| 3rdparty | 201 | 第三方库（JSON、SQLite、YAML 等） | 按需保留 |

### 1.3 插件目录概览（src/plugins/）

> **代码阅读指引**：coreplugin 是唯一必须存在的插件，其他插件都可按需裁剪。了解 helloworld 可快速掌握插件编写模式。

按文件数排序的前 20 个插件：

| 插件 | .h/.cpp 文件数 | 职责 | 裁剪建议 |
|------|---------------|------|---------|
| **coreplugin** | 295 | IDE 核心：主窗口、菜单、编辑器框架、模式管理 | 必须保留（可精简） |
| qmldesigner | 720 | QML 可视化设计器 | 可移除 |
| projectexplorer | 348 | 项目管理、构建系统抽象 | 按需保留 |
| cpptools | 200 | C++ 代码模型 | 可移除 |
| texteditor | 178 | 文本编辑器核心 | 推荐保留 |
| autotest | 168 | 自动化测试集成 | 可移除 |
| debugger | 167 | 调试器集成 | 可移除 |
| scxmleditor | 165 | 状态机编辑器 | 可移除 |
| help | 164 | 帮助系统 | 可选 |
| qmlprofiler | 122 | QML 性能分析 | 可移除 |
| clangcodemodel | 100 | Clang 代码模型 | 可移除 |
| android | 92 | Android 开发支持 | 可移除 |
| mesonprojectmanager | 88 | Meson 构建系统 | 可移除 |
| valgrind | 84 | 内存分析集成 | 可移除 |
| git | 65 | Git 版本控制 | 可选 |
| helloworld | 6 | 最小插件示例 | 学习模板 |
| welcome | 17 | 欢迎页面 | 可选 |
| bookmarks | 14 | 书签功能 | 可选 |

### 1.4 代码规模统计

| 分类 | 数量 |
|------|------|
| 核心库 .h/.cpp 文件 | 1508 |
| 插件 .h/.cpp 文件 | 4585 |
| 插件数量 | 70+ |
| 共享库数量 | 20 |
| 独立工具数量 | 30+ |
| 测试文件数量 | 1809 |
| 第三方库 | 9 个（JSON、SQLite、YAML-CPP 等） |

### 1.5 第三方库详情（src/libs/3rdparty/）

| 库 | 用途 | 文件规模 |
|----|------|---------|
| cplusplus | C++ AST 解析核心（独立于 clang） | 66 源文件 |
| json | JSON 解析/序列化 | 1 文件 127K 行 |
| optional | C++17 std::optional 替代 | 头文件库 |
| span | C++20 std::span 替代 | 头文件库 |
| sqlite | SQLite 数据库引擎 | 2 文件 |
| syntax-highlighting | Kate 语法高亮引擎 | 完整实现 |
| variant | C++17 std::variant 替代 | MPark.Variant 头文件库 |
| xdg | Freedesktop MIME 类型 | MIME 数据库 |
| yaml-cpp | YAML 1.2 解析器 | 完整实现 |

### 1.6 共享代码详情（src/shared/）

| 模块 | 用途 |
|------|------|
| proparser | .pro 文件解析器（ProfileEvaluator、ProWriter） |
| qtsingleapplication | 单实例应用支持（本地 socket IPC） |
| qtlockedfile | 跨平台文件锁 |
| registryaccess | Windows 注册表访问 |
| designerintegrationv2 | Qt Designer 集成 |
| help | 帮助系统组件（书签、搜索、索引） |
| json | JSON 工具 |
| modeltest | Qt 模型测试框架 |
| cpaster | 代码粘贴服务客户端 |

### 1.7 工具目录详情（src/tools/）

| 分类 | 工具 | 用途 |
|------|------|------|
| **Clang 后端** | clangbackend | 代码索引和补全 |
| | clangpchmanagerbackend | 预编译头管理 |
| | clangrefactoringbackend | 重构操作 |
| **C++ 工具** | cplusplus-ast2png | AST 可视化 |
| | cplusplus-frontend | 解析前端 |
| | cplusplus-mkvisitor | 访问者代码生成 |
| **IDE 工具** | sdktool | Qt/编译器 SDK 管理 |
| | qtpromaker | .pro 文件生成 |
| | iconlister | 图标提取 |
| **崩溃处理** | qtcrashhandler | 崩溃报告收集 |
| | qtcreatorcrashhandler | IDE 崩溃处理 |
| **平台工具** | iostool | iOS 设备管理 |
| | wininterrupt | Windows 信号处理 |
| | winrtdebughelper | WinRT 调试 |
| **性能工具** | perfparser | 性能数据解析 |
| **测试辅助** | valgrindfake | Valgrind 输出模拟 |

### 1.8 资源目录详情（share/qtcreator/）

| 目录 | 内容 |
|------|------|
| android/ | Android SDK 配置模板 |
| cplusplus/ | C++ 标准头文件引用 |
| debugger/ | 调试器 pretty-printer 脚本 |
| glsl/ | GLSL 语言定义 |
| qml/ | QML 库定义 |
| qml-type-descriptions/ | Qt 类型元数据 |
| qmldesigner/ | 设计器组件模板 |
| schemes/ | 编辑器配色方案 |
| snippets/ | 代码片段模板 |
| styles/ | UI 样式定义 |
| templates/ | 项目/文件模板（向导用） |
| themes/ | 应用主题 |
| translations/ | 国际化翻译文件 |


---

## 第 2 章 应用入口与启动流程 🔴

### 2.1 main.cpp 结构总览

> **代码阅读指引**：`src/app/main.cpp`（741 行）是整个应用的入口。重点关注第 455-741 行的 `main()` 函数，它定义了插件系统的完整启动序列。

**文件位置**: `src/app/main.cpp`

```
main.cpp 结构：
├── 第 1-75 行: 头文件包含和平台预处理
├── 第 76-80 行: 常量定义（corePluginNameC = "Core"）
├── 第 82-170 行: 辅助函数（路径计算、显示错误）
├── 第 171-351 行: 设置和高 DPI 处理
├── 第 353-360 行: 字体加载
├── 第 362-413 行: 命令行参数解析 Options 结构体
├── 第 415-453 行: Restarter 类（应用重启支持）
├── 第 455-741 行: main() 函数（核心启动序列）
```

### 2.2 关键头文件依赖

```cpp
#include "../tools/qtcreatorcrashhandler/crashhandlersetup.h"  // 崩溃处理
#include <app/app_version.h>              // 版本常量
#include <extensionsystem/iplugin.h>       // 插件接口
#include <extensionsystem/pluginerroroverview.h>  // 错误对话框
#include <extensionsystem/pluginmanager.h> // 插件管理器
#include <extensionsystem/pluginspec.h>    // 插件规格
#include <qtsingleapplication.h>           // 单实例控制
#include <utils/algorithm.h>               // 算法工具
#include <utils/environment.h>             // 环境变量
#include <utils/fileutils.h>               // 文件工具
#include <utils/hostosinfo.h>              // 操作系统检测
```

这些 `#include` 直接揭示了 main.cpp 的依赖：ExtensionSystem + Utils + QtSingleApplication。裁剪时只需保留这三个。

### 2.3 启动序列详解 🔴

> **这是理解整个插件框架的关键入口**。main() 函数中的每一步都对应框架的一个关键机制。

**步骤 1：环境准备**（第 457-479 行）

```cpp
Restarter restarter(argc, argv);
Utils::Environment::systemEnvironment(); // 缓存系统环境变量

Options options = parseCommandLine(argc, argv);
applicationDirPath(argv[0]);
```

- `Restarter` 记录可执行文件路径，支持自动重启
- `parseCommandLine()` 预解析 `-settingspath`、`-pluginpath` 等参数
- 这些参数在 PluginManager 初始化之前就需要处理

**步骤 2：QApplication 创建**（第 519-529 行）

```cpp
SharedTools::QtSingleApplication app(
    QLatin1String(Core::Constants::IDE_DISPLAY_NAME),
    numberofArguments, options.appArguments.data());
QCoreApplication::setApplicationName(Core::Constants::IDE_CASED_ID);
QCoreApplication::setApplicationVersion(
    QLatin1String(Core::Constants::IDE_VERSION_LONG));
QCoreApplication::setOrganizationName(
    QLatin1String(Core::Constants::IDE_SETTINGSVARIANT_STR));
```

- 使用 `QtSingleApplication` 而非标准 `QApplication`
- 单实例机制：第二次启动时通过本地 socket 将参数发送给已运行实例
- 应用名、版本、组织名用于 QSettings 存储路径

**步骤 3：PluginManager 创建与配置**（第 565-568 行）🔴

```cpp
PluginManager pluginManager;
PluginManager::setPluginIID(QLatin1String("org.qt-project.Qt.QtCreatorPlugin"));
PluginManager::setGlobalSettings(globalSettings);
PluginManager::setSettings(settings);
```

- `pluginManager` 在栈上创建，生命周期与 `main()` 绑定
- `pluginIID` 是插件识别标识，**必须与每个插件的 Q_PLUGIN_METADATA 中的 IID 完全一致**
- 两套设置：`globalSettings`（系统级，只读）和 `settings`（用户级，读写）

**步骤 4：设置插件搜索路径**（第 605-606 行）

```cpp
const QStringList pluginPaths = getPluginPaths() + options.customPluginPaths;
PluginManager::setPluginPaths(pluginPaths);
```

`getPluginPaths()` 返回默认路径（通常是 `<安装目录>/lib/qtcreator/plugins/`）。`setPluginPaths()` 触发完整的插件发现链：

```
setPluginPaths(paths)
  ├─ readSettings()          // 读取用户的插件启用/禁用配置
  ├─ readPluginPaths()       // 扫描文件系统
  │   ├─ pluginFiles(paths)  // 递归查找所有动态库文件
  │   ├─ 对每个文件调用 PluginSpec::read()
  │   │   ├─ QPluginLoader 读取元数据（不加载库）
  │   │   └─ 解析 JSON 获取插件名、版本、依赖等
  │   ├─ 应用默认启用/禁用规则
  │   └─ 按分类组织插件
  ├─ resolveDependencies()   // 解析所有插件间的依赖关系
  ├─ enableDependenciesIndirectly()  // 处理间接依赖
  └─ sort(pluginSpecs)       // 按名称排序确保确定性
```

**步骤 5：Core 插件验证**（第 628-650 行）

```cpp
PluginSpec *coreplugin = nullptr;
for (PluginSpec *spec : plugins) {
    if (spec->name() == QLatin1String(corePluginNameC)) {
        coreplugin = spec;
        break;
    }
}
if (!coreplugin) { /* 致命错误 */ }
if (!coreplugin->isEffectivelyEnabled()) { /* 致命错误 */ }
if (coreplugin->hasError()) { /* 致命错误 */ }
```

Core 是唯一的硬性依赖。缺失 Core 则应用直接退出。

**步骤 6：崩溃检测与加载**（第 696-701 行）🔴

```cpp
PluginManager::checkForProblematicPlugins();
PluginManager::loadPlugins();
```

- `checkForProblematicPlugins()`：检查上次运行时是否有插件导致崩溃，如果有则提示用户禁用
- `loadPlugins()`：执行四阶段加载（详见第 6 章）

**步骤 7：事件循环**（第 704-741 行）

```cpp
QObject::connect(&app, &SharedTools::QtSingleApplication::messageReceived,
                 &pluginManager, &PluginManager::remoteArguments);
QObject::connect(&app, SIGNAL(fileOpenRequest(QString)),
                 coreplugin->plugin(), SLOT(fileOpenRequest(QString)));
QObject::connect(&app, &QCoreApplication::aboutToQuit,
                 &pluginManager, &PluginManager::shutdown);

return restarter.restartOrExit(app.exec());
```

三个关键连接：
1. 远程参数 → 转发给 PluginManager
2. 文件打开请求 → 转发给 Core 插件
3. 退出信号 → 触发 PluginManager 关闭序列

### 2.4 启动流程时序图

```
main()
  │
  ├─① parseCommandLine() ─ 预解析命令行
  ├─② QApplication 创建（单实例检测）
  ├─③ Settings 初始化（用户级 + 系统级）
  ├─④ PluginManager 创建
  ├─⑤ setPluginIID("org.qt-project.Qt.QtCreatorPlugin")
  ├─⑥ setPluginPaths() ──→ 扫描 → 读取元数据 → 解析依赖
  ├─⑦ 验证 Core 插件存在且可用
  ├─⑧ checkForProblematicPlugins()（崩溃恢复机制）
  ├─⑨ loadPlugins()
  │   ├─ Phase 1: loadLibrary()   ← 加载 .dll/.so
  │   ├─ Phase 2: initialize()    ← 插件初始化
  │   ├─ Phase 3: extensionsInitialized()  ← 逆序通知
  │   └─ Phase 4: delayedInitialize()      ← 定时器异步
  ├─⑩ 连接信号：远程参数、文件打开、退出关闭
  └─⑪ app.exec() ──→ 进入 Qt 事件循环
        │
        └─ aboutToQuit → shutdown() → stopAll() → deleteAll()
```

### 2.5 命令行参数完整列表

**main.cpp 预处理参数**：

| 参数 | 说明 | 示例 |
|------|------|------|
| `-settingspath <path>` | 自定义设置目录 | `-settingspath /tmp/myide` |
| `-installsettingspath <path>` | 安装设置目录 | |
| `-pluginpath <path>` | 额外插件路径 | `-pluginpath ~/myplugins` |
| `-user-library-path <path>` | 自定义 LD_LIBRARY_PATH | |
| `-temporarycleansettings` | 临时干净设置 | |

**PluginManager 处理的参数**：

| 参数 | 说明 |
|------|------|
| `-noload <plugin>` | 禁止加载指定插件 |
| `-load <plugin>` | 强制加载指定插件 |
| `-test <plugin>[,testfunction]` | 对指定插件运行测试 |
| `-notest <plugin>` | 跳过指定插件的测试 |
| `-profile` | 启用性能分析（输出每个插件加载耗时） |
| `-version` | 打印版本信息 |
| `-help` | 打印帮助 |
| `-client` | 客户端模式 |
| `-pid <pid>` | 指定目标进程 PID |
| `-block` | 阻塞模式等待 |

### 2.6 app_version.h 版本系统 🟡

> **代码阅读指引**：裁剪时必须修改此文件来定义自己的应用标识。

**文件位置**: `src/app/app_version.h.in`（模板文件，构建时由 qmake 替换变量）

关键定义：

| 常量 | 值 | 用途 |
|------|-----|------|
| `IDE_VERSION_LONG` | "4.13.3" | 完整版本号 |
| `IDE_VERSION_MAJOR` | 4 | 主版本号 |
| `IDE_VERSION_MINOR` | 13 | 次版本号 |
| `IDE_VERSION_RELEASE` | 3 | 补丁版本号 |
| `IDE_DISPLAY_NAME` | "Qt Creator" | 显示名称 |
| `IDE_CASED_ID` | "QtCreator" | 内部标识 |
| `IDE_SETTINGSVARIANT_STR` | "QtProject" | 设置组织名 |
| `IDE_ID` | "qtcreator" | 小写标识 |

裁剪要点：将这些常量替换为你的应用名称（如 "MyApp"、"myapp" 等）。

### 2.7 单实例机制详解

> **代码阅读指引**：`src/shared/qtsingleapplication/` 实现了单实例控制。核心原理是 QLocalServer + QLocalSocket。

`QtSingleApplication` 工作原理：
1. 启动时尝试连接本地 socket（名称基于应用名 + 用户）
2. 如果连接成功 → 已有实例运行 → 发送参数消息 → 退出
3. 如果连接失败 → 第一个实例 → 创建 QLocalServer 监听
4. 运行中收到消息 → 触发 `messageReceived` 信号 → 转发给 PluginManager

### 2.8 崩溃恢复机制

> **代码阅读指引**：`pluginmanager.cpp` 第 1367-1457 行的 `LockFile` 类和 `checkForProblematicPlugins()` 实现了崩溃检测。

工作原理：
1. 每次加载插件前，写入一个 lock 文件（内容为当前正在加载的插件名）
2. 加载成功后，删除 lock 文件
3. 如果加载过程中崩溃，下次启动时 lock 文件仍存在
4. 检测到 lock 文件 → 提示用户禁用该插件

```
LockFile 路径: <settings_dir>/<appname>.<hash>.lock
内容: 正在加载的插件名
生命周期: 写入 → 插件加载成功 → 删除（RAII）
```


---

## 第 3 章 ExtensionSystem 库——插件系统核心 🔴

> **代码阅读指引**：这是整个插件框架最核心的库。建议按此顺序阅读源码：`iplugin.h` → `pluginspec.h` → `pluginmanager.h` → `pluginmanager_p.h` → `pluginmanager.cpp`（重点看 loadPlugins 函数）→ `pluginspec.cpp`（重点看 loadLibrary/initializePlugin）。

**文件位置**: `src/libs/extensionsystem/`
**总代码行数**: 5510 行（22 个 .h/.cpp 文件）

### 3.1 文件清单与职责

| 文件 | 行数 | 职责 |
|------|------|------|
| `pluginmanager.h` | 145 | PluginManager 公共接口：对象池、插件操作、设置、命令行 |
| `pluginmanager_p.h` | 162 | PluginManager 私有实现：加载队列、延迟初始化、异步关闭 |
| `pluginmanager.cpp` | 1732 | PluginManager 完整实现（**最核心的文件**） |
| `pluginspec.h` | 148 | PluginSpec 公共接口：插件元数据、状态、依赖 |
| `pluginspec_p.h` | 118 | PluginSpec 私有实现：QPluginLoader、元数据解析 |
| `pluginspec.cpp` | 1127 | PluginSpec 完整实现（**第二核心文件**） |
| `iplugin.h` | 75 | IPlugin 接口：所有插件必须实现的基类 |
| `iplugin.cpp` | 212 | IPlugin 实现和文档 |
| `iplugin_p.h` | 43 | IPlugin 私有数据 |
| `pluginview.h` | 77 | PluginView 插件列表 UI 控件 |
| `pluginview.cpp` | 454 | PluginView 实现 |
| `plugindetailsview.h` | 55 | 插件详情面板 |
| `plugindetailsview.cpp` | 103 | 插件详情实现 |
| `pluginerrorview.h` | 53 | 插件错误面板 |
| `pluginerrorview.cpp` | 112 | 插件错误实现 |
| `pluginerroroverview.h` | 56 | 插件错误总览对话框 |
| `pluginerroroverview.cpp` | 78 | 插件错误总览实现 |
| `optionsparser.h` | 86 | 命令行选项解析器 |
| `optionsparser.cpp` | 307 | 选项解析实现 |
| `invoker.h` | 132 | 跨插件延迟绑定调用 |
| `invoker.cpp` | 125 | Invoker 实现 |
| `extensionsystem_global.h` | ~30 | 导出宏定义 |

### 3.2 IPlugin 接口——所有插件的基类 🔴

> **代码阅读指引**：`iplugin.h` 第 42-75 行。这是所有插件必须继承的基类。`initialize()` 是唯一的纯虚函数，其余都有默认实现。

**文件位置**: `src/libs/extensionsystem/iplugin.h`

```cpp
class EXTENSIONSYSTEM_EXPORT IPlugin : public QObject
{
    Q_OBJECT
public:
    enum ShutdownFlag {
        SynchronousShutdown,   // 同步关闭（默认）
        AsynchronousShutdown   // 异步关闭（需发射 asynchronousShutdownFinished 信号）
    };

    IPlugin();
    ~IPlugin() override;

    // 纯虚函数：插件初始化
    // arguments: PluginManager 传递的命令行参数
    // errorString: 出错时写入错误信息
    // 返回 false 表示初始化失败
    virtual bool initialize(const QStringList &arguments,
                           QString *errorString) = 0;

    // 所有插件的 initialize() 都完成后调用（逆序）
    virtual void extensionsInitialized() {}

    // 延迟初始化（返回 true 表示还有工作要做，下次继续调用）
    virtual bool delayedInitialize() { return false; }

    // 关闭前调用（返回 AsynchronousShutdown 则等待信号）
    virtual ShutdownFlag aboutToShutdown() { return SynchronousShutdown; }

    // 处理从其他实例转发的远程命令
    virtual QObject *remoteCommand(const QStringList &options,
                                   const QString &workingDirectory,
                                   const QStringList &arguments)
    { return nullptr; }

    // 创建测试对象（WITH_TESTS 编译时使用）
    virtual QVector<QObject *> createTestObjects() const;

    // 获取此插件关联的 PluginSpec
    PluginSpec *pluginSpec() const;

signals:
    void asynchronousShutdownFinished();

private:
    Internal::IPluginPrivate *d;
    friend class Internal::PluginSpecPrivate;
};
```

**各方法的调用时序和用途**：

| 方法 | 调用阶段 | 用途 | 注意事项 |
|------|---------|------|---------|
| `initialize()` | Phase 2 | 注册对象、创建 Action、注册工厂类 | 此时依赖插件已 initialize 完毕 |
| `extensionsInitialized()` | Phase 3 | 安全使用其他插件注册的对象 | **逆序调用**（最后加载的先调用） |
| `delayedInitialize()` | Phase 4 | 耗时初始化（索引构建、缓存预热） | 20ms 定时器驱动，不阻塞 UI |
| `aboutToShutdown()` | 退出时 | 清理资源、保存状态 | 异步关闭需发射 finished 信号 |
| `remoteCommand()` | 运行时 | 处理其他实例发来的命令 | 打开文件、跳转等 |

### 3.3 PluginSpec 类——插件规格描述 🔴

> **代码阅读指引**：`pluginspec.h` 第 78-148 行。每个插件文件（.dll/.so）对应一个 PluginSpec 实例。它记录了插件的所有元信息和当前状态。

**文件位置**: `src/libs/extensionsystem/pluginspec.h`

#### 3.3.1 状态机

```cpp
enum State {
    Invalid,      // 初始/读取失败
    Read,         // JSON 元数据已读取（尚未解析依赖）
    Resolved,     // 依赖关系已解析（找到所有依赖的 PluginSpec）
    Loaded,       // 动态库已加载（QPluginLoader::load()）
    Initialized,  // initialize() 已成功调用
    Running,      // extensionsInitialized() 已调用
    Stopped,      // aboutToShutdown() 已调用
    Deleted       // 插件实例已销毁
};
```

状态转换必须严格按顺序进行：
```
Invalid → Read → Resolved → Loaded → Initialized → Running → Stopped → Deleted
```

任何阶段出错都会停在当前状态，`hasError()` 返回 true。

#### 3.3.2 依赖类型

```cpp
struct PluginDependency {
    enum Type {
        Required,   // 必须依赖：依赖加载失败则本插件也失败
        Optional,   // 可选依赖：依赖缺失不影响本插件
        Test        // 测试依赖：仅测试模式下加载
    };
    QString name;      // 依赖插件名
    QString version;   // 最低版本要求
    Type type;
};
```

#### 3.3.3 PluginSpec 公共接口完整列表

**元数据访问**（Read 状态后可用）：
```cpp
QString name() const;           // 插件名（唯一标识符）
QString version() const;        // 版本号（如 "4.13.3"）
QString compatVersion() const;  // 兼容版本号
QString vendor() const;         // 厂商名
QString copyright() const;
QString license() const;
QString description() const;
QString url() const;
QString category() const;       // 分类（用于 UI 分组显示）
QString revision() const;       // Git 版本号
QRegularExpression platformSpecification() const;  // 平台限制正则
bool isAvailableForHostPlatform() const;
bool isRequired() const;        // 核心必需插件（不可禁用）
bool isExperimental() const;    // 实验性插件
bool isEnabledByDefault() const;
QVector<PluginDependency> dependencies() const;
QJsonObject metaData() const;   // 原始 JSON 元数据
```

**启用状态**：
```cpp
bool isEnabledBySettings() const;   // 用户设置中启用
bool isEffectivelyEnabled() const;  // 最终有效状态
bool isEnabledIndirectly() const;   // 被其他插件依赖而间接启用
bool isForceEnabled() const;        // 命令行强制启用
bool isForceDisabled() const;       // 命令行强制禁用
```

**依赖规格**（Resolved 状态后可用）：
```cpp
QHash<PluginDependency, PluginSpec *> dependencySpecs() const;
bool requiresAny(const QSet<PluginSpec *> &plugins) const;
```

**插件实例**（Loaded 状态后可用）：
```cpp
IPlugin *plugin() const;
```

**状态和错误**：
```cpp
State state() const;
bool hasError() const;
QString errorString() const;
```

#### 3.3.4 PluginSpecPrivate 内部实现 🟡

> **代码阅读指引**：`pluginspec_p.h` 第 46-118 行包含实际的加载逻辑方法。理解 `loadLibrary()`、`initializePlugin()`、`readMetaData()` 是掌握插件加载的关键。

**文件位置**: `src/libs/extensionsystem/pluginspec_p.h`

```cpp
class PluginSpecPrivate : public QObject {
public:
    // 生命周期驱动方法（由 PluginManager 在各阶段调用）
    bool read(const QString &fileName);           // 读取元数据
    bool provides(const QString &name, const QString &version) const;
    bool resolveDependencies(const QVector<PluginSpec *> &specs);
    bool loadLibrary();          // QPluginLoader 加载动态库
    bool initializePlugin();     // 调用 IPlugin::initialize()
    bool initializeExtensions(); // 调用 extensionsInitialized()
    bool delayedInitialize();    // 调用 delayedInitialize()
    IPlugin::ShutdownFlag stop(); // 调用 aboutToShutdown()
    void kill();                 // delete plugin

    // 核心成员
    QPluginLoader loader;        // Qt 动态库加载器
    QVector<PluginDependency> dependencies;
    QJsonObject metaData;
    QHash<PluginDependency, PluginSpec *> dependencySpecs;
    IPlugin *plugin = nullptr;
    PluginSpec::State state = PluginSpec::Invalid;
    bool hasError = false;
    QString errorString;

    // 版本工具
    static bool isValidVersion(const QString &version);
    static int versionCompare(const QString &v1, const QString &v2);
    bool readMetaData(const QJsonObject &pluginMetaData);
};
```

#### 3.3.5 loadLibrary() 实现详解 ��

> **代码阅读指引**：`pluginspec.cpp` 约第 620-680 行。这是动态库加载的核心，理解 `QPluginLoader` 如何加载 `.dll`/`.so` 并获取 `IPlugin` 指针。

```
loadLibrary() 执行流程：
├─ 检查当前状态 == Resolved（前置条件）
├─ loader.setFileName(filePath)  // 设置动态库路径
├─ loader.load()                  // 加载动态库到进程空间
│   ├─ 成功 → 继续
│   └─ 失败 → 设置错误信息，返回 false
├─ QObject *instance = loader.instance()  // 获取插件根对象
├─ IPlugin *pluginObject = qobject_cast<IPlugin *>(instance)
│   ├─ 成功 → 得到 IPlugin 指针
│   └─ 失败 → 类型不匹配，卸载库，返回 false
├─ plugin = pluginObject
├─ plugin->d->pluginSpec = q  // 建立双向关联
└─ state = Loaded
```

关键点：`QPluginLoader` 使用 Qt 的插件机制，只加载包含 `Q_PLUGIN_METADATA` 宏且 IID 匹配的动态库。IID 不匹配的库会被 `PluginSpec::read()` 阶段就过滤掉。

#### 3.3.6 initializePlugin() 实现详解

```
initializePlugin() 执行流程：
├─ 检查当前状态 == Loaded（前置条件）
├─ 调用 plugin->initialize(arguments, &err)
│   ├─ 返回 true → 成功
│   └─ 返回 false → 设置 errorString
└─ state = Initialized
```

#### 3.3.7 元数据读取 readMetaData() 🟡

> **代码阅读指引**：`pluginspec.cpp` 中 `readMetaData()` 负责解析插件 JSON 元数据。此方法在 `PluginSpec::read()` 静态工厂方法中被调用。

JSON 元数据来自编译进动态库的 Q_PLUGIN_METADATA。`QPluginLoader::metaData()` 可以在不加载库的情况下读取这些元数据。

字段映射表：

| JSON 字段 | C++ 成员 | 类型 | 必须 |
|-----------|---------|------|------|
| `"Name"` | `name` | QString | 是 |
| `"Version"` | `version` | QString | 是 |
| `"CompatVersion"` | `compatVersion` | QString | 否（默认=Version） |
| `"Required"` | `required` | bool | 否 |
| `"HiddenByDefault"` | `hiddenByDefault` | bool | 否 |
| `"Experimental"` | `experimental` | bool | 否 |
| `"DisabledByDefault"` | `enabledByDefault=false` | bool | 否 |
| `"Vendor"` | `vendor` | QString | 否 |
| `"Copyright"` | `copyright` | QString | 否 |
| `"License"` | `license` | QStringList→join | 否 |
| `"Description"` | `description` | QStringList→join | 否 |
| `"Url"` | `url` | QString | 否 |
| `"Category"` | `category` | QString | 否 |
| `"Platform"` | `platformSpecification` | QRegularExpression | 否 |
| `"Dependencies"` | `dependencies` | Array | 否 |
| `"Arguments"` | `argumentDescriptions` | Array | 否 |

`"Dependencies"` 数组中每个元素的格式：
```json
{
    "Name": "Core",
    "Version": "4.13.3",
    "Type": "required"   // 可选值: "required"(默认), "optional", "test"
}
```

#### 3.3.8 resolveDependencies() 实现

```
resolveDependencies(allSpecs) 执行流程：
├─ 遍历 dependencies 列表中每个 PluginDependency
│   ├─ 在 allSpecs 中查找同名插件
│   │   ├─ 找到 → 检查版本兼容性
│   │   │   ├─ 调用 provides(name, version)
│   │   │   │   └─ versionCompare(spec.version, dep.version) >= 0
│   │   │   │       && versionCompare(spec.compatVersion, dep.version) <= 0
│   │   │   ├─ 兼容 → dependencySpecs[dep] = spec
│   │   │   └─ 不兼容 → 错误
│   │   └─ 未找到
│   │       ├─ Required → 错误
│   │       └─ Optional/Test → 跳过
├─ 所有依赖解析成功
└─ state = Resolved
```

### 3.4 PluginManager 类 🔴

> **代码阅读指引**：`pluginmanager.h` 定义了全部公共 API。所有方法都是 `static`，通过全局单例 `d` 指针调用 `PluginManagerPrivate`。重点看对象池操作和 `loadPlugins`。

**文件位置**: `src/libs/extensionsystem/pluginmanager.h`

#### 3.4.1 对象池操作 🔴

```cpp
// 添加对象到全局池（触发 objectAdded 信号）
static void addObject(QObject *obj);

// 从池中移除（触发 aboutToRemoveObject 信号）
static void removeObject(QObject *obj);

// 获取所有池中对象
static QVector<QObject *> allObjects();

// 获取读写锁（外部手动加锁用）
static QReadWriteLock *listLock();

// 按类型查找第一个匹配对象
template <typename T> static T *getObject() {
    QReadLocker lock(listLock());
    const QVector<QObject *> all = allObjects();
    for (QObject *obj : all) {
        if (T *result = qobject_cast<T *>(obj))
            return result;
    }
    return nullptr;
}

// 按类型+谓词查找
template <typename T, typename Predicate>
static T *getObject(Predicate predicate) {
    QReadLocker lock(listLock());
    const QVector<QObject *> all = allObjects();
    for (QObject *obj : all) {
        if (T *result = qobject_cast<T *>(obj))
            if (predicate(result))
                return result;
    }
    return 0;
}

// 按名称查找
static QObject *getObjectByName(const QString &name);
```

对象池的设计思路：
- 所有插件共享一个全局对象列表
- 插件在 `initialize()` 中将服务对象添加到池中
- 其他插件通过 `getObject<T>()` 按接口类型查找服务
- 信号 `objectAdded` / `aboutToRemoveObject` 支持动态发现

#### 3.4.2 插件操作 API

```cpp
static QVector<PluginSpec *> loadQueue();        // 按依赖排序的加载队列
static void loadPlugins();                        // 执行四阶段加载
static QStringList pluginPaths();                 // 获取搜索路径
static void setPluginPaths(const QStringList &);  // 设置搜索路径
static QString pluginIID();                       // 获取 IID
static void setPluginIID(const QString &iid);     // 设置 IID
static const QVector<PluginSpec *> plugins();     // 所有插件
static QHash<QString, QVector<PluginSpec *>> pluginCollections();
static bool hasError();
static const QStringList allErrors();
static const QSet<PluginSpec *> pluginsRequiringPlugin(PluginSpec *);
static const QSet<PluginSpec *> pluginsRequiredByPlugin(PluginSpec *);
static void checkForProblematicPlugins();
```

#### 3.4.3 设置管理 API

```cpp
static void setSettings(QSettings *settings);     // 用户设置
static QSettings *settings();
static void setGlobalSettings(QSettings *settings); // 全局设置
static QSettings *globalSettings();
static void writeSettings();
```

两级设置系统：
- `globalSettings`：系统级，通常只读，所有用户共享
- `settings`：用户级，存储用户的插件启用/禁用偏好

#### 3.4.4 信号

```cpp
signals:
    void objectAdded(QObject *obj);          // 对象加入池
    void aboutToRemoveObject(QObject *obj);  // 对象即将移除
    void pluginsChanged();                    // 插件列表变化
    void initializationDone();               // 所有初始化完成
    void testsFinished(int failedTests);     // 测试完成
```

`objectAdded` 和 `aboutToRemoveObject` 是最常用的两个信号，用于动态感知服务的注册和注销。

#### 3.4.5 PluginManagerPrivate 内部数据 🟡

> **代码阅读指引**：`pluginmanager_p.h` 第 56-162 行。理解这些数据成员是理解加载流程的基础。

```cpp
class PluginManagerPrivate : public QObject {
public:
    // 插件数据
    QHash<QString, QVector<PluginSpec *>> pluginCategories; // 按分类
    QVector<PluginSpec *> pluginSpecs;    // 全部插件
    QStringList pluginPaths;              // 搜索路径
    QString pluginIID;                    // 接口标识

    // 对象池
    QVector<QObject *> allObjects;        // 全局池

    // 启用/禁用控制
    QStringList defaultDisabledPlugins;   // 安装设置默认禁用
    QStringList defaultEnabledPlugins;    // 安装设置默认启用
    QStringList disabledPlugins;          // 用户禁用
    QStringList forceEnabledPlugins;      // 用户强制启用

    // 延迟初始化
    QTimer *delayedInitializeTimer = nullptr;
    std::queue<PluginSpec *> delayedInitializeQueue;

    // 异步关闭
    QSet<PluginSpec *> asynchronousPlugins;
    QEventLoop *shutdownEventLoop = nullptr;

    // 性能分析
    QScopedPointer<QElapsedTimer> m_profileTimer;
    QHash<const PluginSpec *, int> m_profileTotal;
    int m_profileElapsedMS = 0;
    unsigned m_profilingVerbosity = 0;

    // 设置
    QSettings *settings = nullptr;
    QSettings *globalSettings = nullptr;

    // 线程安全
    mutable QReadWriteLock m_lock;

    // 状态
    bool m_isInitializationDone = false;
    bool enableCrashCheck = true;

    // 测试
    std::vector<TestSpec> testSpecs;
    QStringList arguments;
    QStringList argumentsForRestart;
};
```

### 3.5 OptionsParser 命令行解析 🟢

> **代码阅读指引**：`optionsparser.h`（86 行）和 `optionsparser.cpp`（307 行）。一般裁剪时不需要修改，但自定义命令行参数时需了解。

**文件位置**: `src/libs/extensionsystem/optionsparser.h`

OptionsParser 处理 PluginManager 级别的命令行参数。它在 `PluginManager::parseOptions()` 中被调用。

处理逻辑：
```
parseOptions(args, appOptions, foundAppOptions, errorString)
├─ 遍历参数列表
├─ 匹配 appOptions 中定义的应用级参数 → 放入 foundAppOptions
├─ 匹配 "-noload", "-load", "-test" 等 → 直接处理
├─ 匹配插件定义的参数 → 转发给对应插件
└─ 未匹配 → 放入 PluginManager::arguments()
```

### 3.6 Invoker 跨插件调用 🟢

> **代码阅读指引**：`invoker.h`（132 行）和 `invoker.cpp`（125 行）。当插件间没有编译时依赖但需要运行时交互时使用。

**文件位置**: `src/libs/extensionsystem/invoker.h`

Invoker 利用 Qt 元对象系统的 `QMetaObject::invokeMethod` 实现运行时方法调用：

```cpp
// 使用方式：不需要 #include 目标插件头文件
bool result = ExtensionSystem::invoke<bool>(targetObject, "methodName", arg1, arg2);
```

原理：
1. 查找目标 QObject 的 `QMetaObject`
2. 按方法名在元对象中查找方法
3. 构造参数列表
4. 调用 `QMetaObject::invokeMethod`

适用场景：软依赖（两个插件不声明编译时依赖，但运行时协作）。

### 3.7 UI 组件 🟢

#### PluginView（插件列表控件）

**文件位置**: `src/libs/extensionsystem/pluginview.h`（77 行）、`pluginview.cpp`（454 行）

```cpp
class PluginView : public QWidget {
    Q_OBJECT
public:
    explicit PluginView(QWidget *parent = nullptr);
    ~PluginView() override;

    PluginSpec *currentPlugin() const;
    void setFilter(const QString &filter);

signals:
    void currentPluginChanged(PluginSpec *spec);
    void pluginActivated(PluginSpec *spec);
    void pluginSettingsChanged(PluginSpec *spec);
};
```

功能：以树形列表展示所有插件，按 `category` 分组。每个插件有勾选框控制启用/禁用。通常嵌入"关于插件"对话框中。

内部使用 `QTreeWidget`，每行显示：
- 勾选框（启用/禁用）
- 插件名
- 版本号
- 厂商
- 加载状态图标

#### PluginDetailsView

**文件位置**: `plugindetailsview.h`（55 行）

显示单个插件的详细元数据：名称、版本、兼容版本、厂商、URL、描述、许可证、依赖列表等。

#### PluginErrorView

**文件位置**: `pluginerrorview.h`（53 行）

显示插件加载过程中的错误信息。

#### PluginErrorOverview

**文件位置**: `pluginerroroverview.h`（56 行）

启动时如果有插件出错，弹出此对话框概览所有错误。用户可选择继续或退出。

### 3.8 构建配置与依赖

**extensionsystem.pro**:
```pro
include(../../qtcreatorlibrary.pri)
DEFINES += EXTENSIONSYSTEM_LIBRARY
```

**extensionsystem_dependencies.pri**:
```pro
QTC_LIB_NAME = ExtensionSystem
QTC_LIB_DEPENDS += aggregation utils
```

依赖关系图：
```
ExtensionSystem
├─→ Aggregation（组件组合，query<T> 支持）
└─→ Utils（算法、文件工具、断言宏等）
```

### 3.9 线程安全设计

ExtensionSystem 的线程安全通过 `QReadWriteLock` 实现：

| 操作 | 锁类型 | 并发性 |
|------|--------|--------|
| `getObject<T>()` | QReadLocker | 多线程并发读 |
| `allObjects()` | QReadLocker | 多线程并发读 |
| `addObject()` | QWriteLocker | 独占写 |
| `removeObject()` | QWriteLocker | 独占写 |
| `getObjectByName()` | QReadLocker | 多线程并发读 |

设计意图：对象池的读操作远多于写操作（插件初始化后很少新增/移除对象），读写锁在读多写少场景下性能优于互斥锁。

---

## 第 4 章 Aggregation 库——组件组合框架 🔴

> **代码阅读指引**：`aggregate.h`（126 行）和 `aggregate.cpp`（265 行）是全部核心代码。这个库实现了一种非继承的多接口组合模式，是 Qt Creator 中"一个对象同时实现多种接口"的基础设施。

### 4.1 文件清单

| 文件 | 行数 | 职责 |
|------|------|------|
| `aggregate.h` | 126 | 类声明与模板函数 |
| `aggregate.cpp` | 265 | 核心实现 |
| `aggregation_global.h` | 34 | 导出宏定义 |
| `aggregation_dependencies.pri` | 1 | 构建依赖声明 |
| `aggregation.pro` | 7 | 项目文件 |
| `examples/text/main.cpp` | 103 | 使用示例 |
| `examples/text/main.h` | 51 | 示例头文件 |
| `examples/text/myinterfaces.h` | 81 | 示例接口定义 |
| **合计** | **~668** | |

### 4.2 核心设计思想

Aggregation 解决的问题：**如何让多个独立的 QObject 组合成一个"逻辑整体"，使得通过任意一个组件都能查询到其他组件？**

传统做法是多重继承，但存在 QObject 不能多继承的限制。Aggregation 用**组合替代继承**：

```
传统方式（不可行）：
  class MyEditor : public IEditor, public ITextEditor, public IFindSupport
  // ❌ QObject 不能多重继承

Aggregation 方式：
  Aggregate *agg = new Aggregate;
  agg->add(new EditorImpl);        // 实现 IEditor
  agg->add(new TextEditorImpl);    // 实现 ITextEditor
  agg->add(new FindSupportImpl);   // 实现 IFindSupport
  // ✅ 通过任意一个可查到其他
```

### 4.3 Aggregate 类声明 🔴

**文件位置**: `src/libs/aggregation/aggregate.h`

```cpp
class AGGREGATION_EXPORT Aggregate : public QObject
{
    Q_OBJECT

public:
    Aggregate(QObject *parent = nullptr);
    ~Aggregate() override;

    void add(QObject *component);
    void remove(QObject *component);

    // 查询单个匹配组件
    template <typename T> T *component() {
        QReadLocker locker(&lock());
        for (QObject *component : qAsConst(m_components)) {
            if (T *result = qobject_cast<T *>(component))
                return result;       // 返回第一个匹配
        }
        return nullptr;
    }

    // 查询所有匹配组件
    template <typename T> QList<T *> components() {
        QReadLocker locker(&lock());
        QList<T *> results;
        for (QObject *component : qAsConst(m_components)) {
            if (T *result = qobject_cast<T *>(component))
                results << result;   // 累积所有匹配
        }
        return results;
    }

    static Aggregate *parentAggregate(QObject *obj);
    static QReadWriteLock &lock();

signals:
    void changed();

private:
    void deleteSelf(QObject *obj);
    static QHash<QObject *, Aggregate *> &aggregateMap();

    QList<QObject *> m_components;
};
```

关键设计点：
- 模板方法 `component<T>()` / `components<T>()` 使用 `qobject_cast` 实现类型安全查询
- 全局静态 `aggregateMap()` 维护组件到聚合体的反向映射
- 全局 `QReadWriteLock` 保护所有并发访问

### 4.4 全局查询函数 query<T>() 🔴

这是 Aggregation 库最重要的 API，提供**透明的跨组件类型查询**：

```cpp
// 对 QObject 指针的查询（最常用）
template <typename T> T *query(QObject *obj)
{
    if (!obj)
        return nullptr;
    T *result = qobject_cast<T *>(obj);    // 步骤1：直接类型转换
    if (!result) {
        QReadLocker locker(&Aggregate::lock());
        Aggregate *parentAggregation = Aggregate::parentAggregate(obj);
        result = (parentAggregation 
                  ? query<T>(parentAggregation)  // 步骤2：在聚合体中查找
                  : nullptr);
    }
    return result;
}
```

**两步查询过程**：

```
query<ITextEditor>(someObject)
├─ 步骤1: qobject_cast<ITextEditor*>(someObject)
│  ├─ 成功 → 直接返回（O(1)）
│  └─ 失败 → 继续步骤2
└─ 步骤2: 查找 someObject 所属的 Aggregate
   ├─ aggregateMap 查找 → O(1) Hash 查找
   ├─ 找到 Aggregate → 遍历 m_components 逐一 qobject_cast → O(n)
   └─ 未找到 → 返回 nullptr
```

还有批量查询版本：

```cpp
template <typename T> QList<T *> query_all(QObject *obj)
```

### 4.5 核心数据结构：全局聚合体映射表

```cpp
// 静态成员：全局映射 组件→所属聚合体
QHash<QObject *, Aggregate *> &Aggregate::aggregateMap()
{
    static QHash<QObject *, Aggregate *> map;
    return map;
}
```

映射关系示意：
```
aggregateMap:
  {EditorImpl*     → Aggregate_A*}
  {TextEditorImpl* → Aggregate_A*}
  {FindSupport*    → Aggregate_A*}
  {Aggregate_A*    → Aggregate_A*}   // 聚合体映射到自身
  {OtherImpl*      → Aggregate_B*}
  ...
```

### 4.6 生命周期耦合 🔴

Aggregation 最重要的设计特性：**所有组件生死与共**。

#### 添加组件 (add)

```cpp
void Aggregate::add(QObject *component)
{
    if (!component)
        return;
    {
        QWriteLocker locker(&lock());
        Aggregate *parentAggregation = aggregateMap().value(component);
        if (parentAggregation == this)
            return;                    // 幂等：已在此聚合体中
        if (parentAggregation) {
            qWarning() << "Cannot add a component that belongs to a different aggregate";
            return;                    // 一个组件只能属于一个聚合体
        }
        m_components.append(component);
        connect(component, &QObject::destroyed, this, &Aggregate::deleteSelf);
        aggregateMap().insert(component, this);
    }
    emit changed();                    // 锁外发信号，避免死锁
}
```

关键不变量：
- **幂等性**：重复添加同一组件是无操作
- **排他性**：一个组件只能属于一个聚合体
- **信号连接**：`destroyed()` → `deleteSelf()`

#### 组件被删除时——级联销毁

```cpp
void Aggregate::deleteSelf(QObject *obj)
{
    {
        QWriteLocker locker(&lock());
        aggregateMap().remove(obj);
        m_components.removeAll(obj);
    }
    delete this;    // 聚合体自杀 → 触发析构 → 删除剩余组件
}
```

#### 聚合体析构——清理所有组件

```cpp
Aggregate::~Aggregate()
{
    QList<QObject *> components;
    {
        QWriteLocker locker(&lock());
        for (QObject *component : qAsConst(m_components)) {
            disconnect(component, &QObject::destroyed, 
                      this, &Aggregate::deleteSelf);
            aggregateMap().remove(component);
        }
        components = m_components;     // 拷贝到锁外安全删除
        m_components.clear();
        aggregateMap().remove(this);
    }
    qDeleteAll(components);            // 锁外删除，避免死锁
}
```

**生命周期流程图**：

```
删除任意组件 component_A
  ↓
component_A::destroyed() 信号发射
  ↓
Aggregate::deleteSelf(component_A)
  ↓ 从映射表和列表中移除 component_A
  ↓ delete this  →  触发 ~Aggregate()
  ↓
~Aggregate()
  ↓ 断开所有剩余组件的 destroyed() 信号
  ↓ 从映射表中移除所有组件
  ↓ qDeleteAll(components)  →  删除 component_B, component_C, ...
```

### 4.7 与 ExtensionSystem 的协作关系

Aggregation 和 ExtensionSystem 是两个**独立但互补**的系统：

| 机制 | ExtensionSystem (对象池) | Aggregation (组件组合) |
|------|------------------------|---------------------|
| 数据结构 | `QVector<QObject*>` 平坦列表 | `QHash<QObject*, Aggregate*>` 映射 |
| 查询方式 | 遍历全局池 `getObject<T>()` | 在聚合体内查找 `query<T>()` |
| 注册 | `addObject()` | `add()` |
| 生命周期 | 手动管理 | 自动级联销毁 |
| 用途 | 全局服务发现 | 局部多接口组合 |

**典型协作模式**：

```cpp
// 1. 创建聚合体
Aggregate *agg = new Aggregate;
IEditor *editor = new MyEditorImpl;
IFindSupport *find = new MyFindSupportImpl;
agg->add(editor);
agg->add(find);

// 2. 将其中一个接口注册到全局对象池
PluginManager::addObject(editor);

// 3. 其他插件通过对象池找到 editor，再通过 Aggregation 找到 find
IEditor *e = PluginManager::getObject<IEditor>();
IFindSupport *f = Aggregation::query<IFindSupport>(e);  // 跨聚合体查询
```

### 4.8 构建配置

```pro
# aggregation_dependencies.pri
QTC_LIB_NAME = Aggregation
# 无额外依赖——这是最底层的库之一
```

依赖关系：
```
ExtensionSystem
├─→ Aggregation（本章）
└─→ Utils
```

### 4.9 线程安全设计

全局单一 `QReadWriteLock` 保护所有操作：

| 操作 | 锁类型 | 说明 |
|------|--------|------|
| `query<T>()` | QReadLocker | 查询不修改状态 |
| `component<T>()` | QReadLocker | 在组件列表中查找 |
| `parentAggregate()` | QReadLocker | 查映射表 |
| `add()` | QWriteLocker | 修改列表和映射表 |
| `remove()` | QWriteLocker | 修改列表和映射表 |
| 构造函数 | QWriteLocker | 注册到映射表 |
| 析构函数 | QWriteLocker | 从映射表删除 |

**设计要点**：信号 `changed()` 始终在锁外发射，避免信号槽链引起死锁。

---

## 第 5 章 构建系统 🟡

> **代码阅读指引**：Qt Creator 使用 qmake 递归构建系统。理解 `qtcreator.pri` 的依赖解析算法和 `qtcreatorplugin.pri` 的插件模板是裁剪的前提。

### 5.1 构建系统总览

```
qtcreator.pro                    # 根项目文件（91 行）
├── qtcreator.pri                # 全局变量、路径、依赖解析（295 行）
├── qtcreator_ide_branding.pri   # 品牌定制（17 行）
├── qtcreatordata.pri            # 资源部署（45 行）
├── src/
│   ├── qtcreatorlibrary.pri     # 库构建模板（37 行）
│   ├── qtcreatorplugin.pri      # 插件构建模板（106 行）
│   ├── rpath.pri                # RPATH 处理（20 行）
│   ├── libs/libs.pro            # 库列表（73 行）
│   └── plugins/plugins.pro      # 插件列表（135 行）
└── 各插件/库的 *_dependencies.pri
```

### 5.2 根项目文件 qtcreator.pro

```pro
# 核心配置
include(qtcreator.pri)
TEMPLATE = subdirs
CONFIG += ordered     # 按顺序构建子目录

SUBDIRS = src share   # 核心子目录
# 条件子目录：bin, tests

# 平台检测与部署
macx:    PLATFORM = "mac"
else:win32: PLATFORM = "windows"
else:linux: PLATFORM = "linux-$$QT_ARCH"
```

### 5.3 全局变量 qtcreator.pri 🔴

这是整个构建系统的核心配置文件（295 行），定义了所有路径、变量和依赖解析算法。

#### 库命名函数

```pro
# 库名转换（处理调试后缀）
qtLibraryTargetName(lib_name):
  macOS debug  → 追加 "_debug"
  Windows debug → 追加 "d"
  其他         → 不变

qtLibraryName(lib_name):
  调用 qtLibraryTargetName()
  Windows → 追加主版本号（如 "4"）
```

#### 平台路径配置

**Linux/Windows**:
```
IDE_LIBRARY_PATH  = $$IDE_BUILD_TREE/lib/qtcreator
IDE_PLUGIN_PATH   = $$IDE_LIBRARY_PATH/plugins
IDE_DATA_PATH     = $$IDE_BUILD_TREE/share/qtcreator
IDE_LIBEXEC_PATH  = $$IDE_BUILD_TREE/libexec/qtcreator  (Unix)
                  = $$IDE_BUILD_TREE/bin               (Windows)
```

**macOS**:
```
IDE_APP_BUNDLE    = $$IDE_APP_PATH/Qt Creator.app
IDE_LIBRARY_PATH  = $$IDE_APP_BUNDLE/Contents/Frameworks
IDE_PLUGIN_PATH   = $$IDE_APP_BUNDLE/Contents/PlugIns
IDE_LIBEXEC_PATH  = $$IDE_APP_BUNDLE/Contents/Resources/libexec
```

#### 全局 INCLUDEPATH

```pro
$$IDE_BUILD_TREE/src           # 生成的头文件
$$IDE_SOURCE_TREE/src          # 源码头文件
$$IDE_SOURCE_TREE/src/libs     # 库头文件
$$IDE_SOURCE_TREE/tools        # 工具头文件

# 插件和库目录（支持环境变量扩展）
QTC_PLUGIN_DIRS                # 默认: src/plugins
QTC_LIB_DIRS                   # 默认: src/libs, src/libs/3rdparty
```

#### 全局 DEFINES

```pro
QT_CREATOR                          # 标识 Qt Creator 构建环境
QT_NO_JAVA_STYLE_ITERATORS          # 禁用 Java 风格迭代器
QT_NO_CAST_TO_ASCII                 # 禁止隐式转 ASCII
QT_RESTRICTED_CAST_FROM_ASCII       # 限制从 ASCII 转换
QT_DISABLE_DEPRECATED_BEFORE=0x050900  # 禁用 Qt 5.9 前的废弃 API
QT_USE_FAST_OPERATOR_PLUS           # 字符串快速拼接
QT_USE_FAST_CONCATENATION           # 字符串快速连接
```

#### 递归依赖解析算法 🔴

这是构建系统最关键的部分，处理传递性依赖：

```
插件依赖解析算法（伪代码）：
1. done_plugins = ∅
2. while QTC_PLUGIN_DEPENDS ≠ ∅:
   a. done_plugins += QTC_PLUGIN_DEPENDS
   b. for each dep in QTC_PLUGIN_DEPENDS:
      - 在 QTC_PLUGIN_DIRS 中查找 dep/dep_dependencies.pri
      - include 该文件 → 加载 QTC_PLUGIN_NAME
      - LIBS += -l$$qtLibraryName($$QTC_PLUGIN_NAME)
   c. 去重，移除已处理项
   d. 继续循环（处理传递依赖）

库依赖解析：同样的算法，作用于 QTC_LIB_DEPENDS
```

### 5.4 品牌定制 qtcreator_ide_branding.pri

```pro
QTCREATOR_VERSION = 4.13.3
QTCREATOR_COMPAT_VERSION = 4.13.0
QTCREATOR_DISPLAY_VERSION = 4.13.3
QTCREATOR_COPYRIGHT_YEAR = 2020

IDE_DISPLAY_NAME = Qt Creator
IDE_ID = qtcreator
IDE_CASED_ID = QtCreator

PRODUCT_BUNDLE_ORGANIZATION = org.qt-project
PROJECT_USER_FILE_EXTENSION = .user
```

**裁剪要点**：自定义应用时修改此文件，改变 IDE_DISPLAY_NAME、IDE_ID 等即可实现品牌替换。

### 5.5 库构建模板 qtcreatorlibrary.pri

```pro
# 自动加载依赖声明
include($$lib_name/$$lib_name_dependencies.pri)

# 加载全局配置
include(../qtcreator.pri)

# 输出目录
DESTDIR = $$IDE_LIBRARY_PATH

# 构建类型
TEMPLATE = lib
CONFIG += shared dll

# macOS 特殊处理
macx: QMAKE_LFLAGS_SONAME = -Wl,-install_name,@rpath/

# RPATH（相对路径链接）
include(rpath.pri)
```

### 5.6 插件构建模板 qtcreatorplugin.pri 🔴

```pro
# 1. 加载依赖声明
include(plugin_name/plugin_name_dependencies.pri)
# 加载 QTC_PLUGIN_NAME, QTC_LIB_DEPENDS, QTC_PLUGIN_DEPENDS

# 2. JSON 元数据生成
# 将 QTC_PLUGIN_DEPENDS → JSON 依赖列表
# 将 QTC_PLUGIN_RECOMMENDS → JSON 可选依赖（Type: "optional"）
# 将 QTC_TEST_DEPENDS → JSON 测试依赖（Type: "test"）

# 3. 输出目录
DESTDIR = $$IDE_PLUGIN_PATH
#   Linux:   $$IDE_BUILD_TREE/lib/qtcreator/plugins
#   macOS:   $$IDE_APP_BUNDLE/Contents/PlugIns
#   Windows: $$IDE_BUILD_TREE/lib/qtcreator/plugins

# 4. 用户构建模式（USE_USER_DESTDIR）
#   Windows: $LOCALAPPDATA/QtProject/qtcreator/plugins/4.13.3
#   macOS:   ~/Library/Application Support/QtProject/Qt Creator/plugins/4.13.3
#   Linux:   $XDG_DATA_HOME/data/QtProject/qtcreator/plugins/4.13.3

# 5. 元数据处理
# 查找 plugin.json.in → 通过 QMAKE_SUBSTITUTES 生成 plugin.json

# 6. 构建配置
TEMPLATE = lib
CONFIG += plugin plugin_with_soname
```

### 5.7 RPATH 处理 rpath.pri

实现可重定位的二进制文件：

```pro
# 计算相对路径
REL_PATH_TO_LIBS = $$relative_path($$IDE_LIBRARY_PATH, $$RPATH_BASE)
REL_PATH_TO_PLUGINS = $$relative_path($$IDE_PLUGIN_PATH, $$RPATH_BASE)

# macOS: 使用 @loader_path
QMAKE_LFLAGS += -Wl,-rpath,@loader_path/$$REL_PATH_TO_LIBS

# Linux: 使用 $ORIGIN
QMAKE_RPATHDIR += $ORIGIN
QMAKE_RPATHDIR += $ORIGIN/$$REL_PATH_TO_LIBS
QMAKE_RPATHDIR += $ORIGIN/$$REL_PATH_TO_PLUGINS
QMAKE_LFLAGS += -Wl,-z,origin
```

### 5.8 依赖声明模式 _dependencies.pri

每个库和插件都有一个 `*_dependencies.pri` 文件，格式统一：

```pro
# 库依赖示例（utils - 无依赖）
QTC_LIB_NAME = Utils

# 库依赖示例（extensionsystem）
QTC_LIB_NAME = ExtensionSystem
QTC_LIB_DEPENDS += aggregation utils

# 插件依赖示例（coreplugin）
QTC_PLUGIN_NAME = Core
QTC_LIB_DEPENDS += \
    aggregation \
    extensionsystem \
    utils

# 插件依赖示例（texteditor）
QTC_PLUGIN_NAME = TextEditor
QTC_LIB_DEPENDS += \
    aggregation \
    extensionsystem \
    utils
QTC_PLUGIN_DEPENDS += coreplugin

# 插件依赖示例（helloworld）
QTC_PLUGIN_NAME = HelloWorld
QTC_LIB_DEPENDS += extensionsystem
QTC_PLUGIN_DEPENDS += coreplugin
QTC_PLUGIN_RECOMMENDS += \
    # 可选依赖
```

### 5.9 库与插件列表

#### 库列表 (src/libs/libs.pro)

```
核心库（14个）：
  aggregation, extensionsystem, utils, languageutils, cplusplus,
  modelinglib, qmljs, qmldebug, qmleditorwidgets, glsl, ssh,
  clangsupport, languageserverprotocol, sqlite

条件库：
  tracing              (需要 Qt Quick)
  advanceddockingsystem (需要 Qt Quick Private)
  syntax-highlighting   (外部或内置)
  yaml-cpp             (外部或内置)
```

#### 插件列表 (src/plugins/plugins.pro)

```
核心插件（60+个）：
  coreplugin, texteditor, cppeditor, cpptools, projectexplorer,
  debugger, qmldesigner, git, subversion, perforce, cvs, mercurial,
  bazaar, android, ios, winrt, baremetal, qmlprojectmanager,
  qmakeprojectmanager, python, nim, valgrind, clangtools, clangformat,
  marketplace, updateinfo ...

条件插件：
  serialterminal       (需要 Qt SerialPort)
  qmlprofiler         (需要 Qt Quick)
  perfprofiler        (需要 Qt Quick)
  help                (需要 Qt Help)
  designer            (需要 Qt Designer)
  qmldesigner         (需要 Qt Quick Controls 1)
  helloworld          (非打包构建)
```

---

## 第 6 章 插件生命周期 🔴

> **代码阅读指引**：重点看 `pluginmanager.cpp` 的 `loadPlugins()` 方法（~100 行核心代码），以及 `iplugin.h` 的四个虚函数。这是理解插件何时被加载、初始化、运行、关闭的关键。

### 6.1 IPlugin 接口 🔴

**文件位置**: `src/libs/extensionsystem/iplugin.h`

```cpp
class EXTENSIONSYSTEM_EXPORT IPlugin : public QObject
{
    Q_OBJECT

public:
    enum ShutdownFlag {
        SynchronousShutdown,     // 同步关闭（默认）
        AsynchronousShutdown     // 异步关闭（需等待外部进程）
    };

    IPlugin();
    ~IPlugin() override;

    // 必须实现
    virtual bool initialize(const QStringList &arguments, 
                           QString *errorString) = 0;

    // 可选实现（有默认空实现）
    virtual void extensionsInitialized() {}
    virtual bool delayedInitialize() { return false; }
    virtual ShutdownFlag aboutToShutdown() { return SynchronousShutdown; }
    virtual QObject *remoteCommand(const QStringList &options,
                                   const QString &workingDirectory,
                                   const QStringList &arguments) { return nullptr; }
    virtual QVector<QObject *> createTestObjects() const;

    PluginSpec *pluginSpec() const;

signals:
    void asynchronousShutdownFinished();
};
```

### 6.2 四个生命周期方法详解

#### initialize() 🔴

```
调用时机：插件库加载后，实例创建后
调用顺序：按依赖顺序——被依赖的插件先调用
参数：命令行参数（从 OptionsParser 分发）
返回值：true=成功，false=失败（通过 errorString 报告原因）
用途：
  - 初始化内部状态
  - 注册 Action、Menu、Mode 等到 CorePlugin
  - 注册服务对象到对象池
  - 不能假设其他插件已经可用
```

#### extensionsInitialized()

```
调用时机：所有插件的 initialize() 都已成功调用后
调用顺序：反向依赖顺序——依赖方先调用
用途：
  - 可以安全地在对象池中查找其他插件注册的服务
  - 适合设置跨插件协作
  - 弱依赖（optional dependency）的发现在此进行
```

#### delayedInitialize()

```
调用时机：应用主事件循环已启动后，每 20ms 调一个
调用顺序：依赖顺序
返回值：true=有实际工作（下一个插件延迟调用），false=无工作
用途：
  - 非紧急的初始化工作
  - 避免阻塞启动界面
  - 如索引构建、缓存预热
```

#### aboutToShutdown()

```
调用时机：关闭序列开始时
调用顺序：与 initialize() 相同顺序
返回值：SynchronousShutdown=同步完成，AsynchronousShutdown=需要等待
用途：
  - 断开与其他插件的连接
  - 隐藏所有 UI
  - 如需异步关闭，返回 AsynchronousShutdown 并稍后发射 asynchronousShutdownFinished()
```

### 6.3 四阶段加载流程 🔴

**文件位置**: `src/libs/extensionsystem/pluginmanager.cpp`，`loadPlugins()` 方法

```cpp
void PluginManagerPrivate::loadPlugins()
{
    // 获取拓扑排序后的加载队列
    const QVector<PluginSpec *> queue = loadQueue();

    // 阶段 1：加载库
    Utils::setMimeStartupPhase(MimeStartupPhase::PluginsLoading);
    for (PluginSpec *spec : queue)
        loadPlugin(spec, PluginSpec::Loaded);

    // 阶段 2：调用 initialize()
    Utils::setMimeStartupPhase(MimeStartupPhase::PluginsInitializing);
    for (PluginSpec *spec : queue)
        loadPlugin(spec, PluginSpec::Initialized);

    // 阶段 3：调用 extensionsInitialized()（反向顺序）
    Utils::setMimeStartupPhase(MimeStartupPhase::PluginsDelayedInitializing);
    Utils::reverseForeach(queue, [this](PluginSpec *spec) {
        loadPlugin(spec, PluginSpec::Running);
        if (spec->state() == PluginSpec::Running)
            delayedInitializeQueue.push(spec);
        else
            spec->d->kill();
    });

    emit q->pluginsChanged();
    Utils::setMimeStartupPhase(MimeStartupPhase::UpAndRunning);

    // 阶段 4：延迟初始化（定时器驱动）
    delayedInitializeTimer = new QTimer;
    delayedInitializeTimer->setInterval(20);  // 20ms 间隔
    delayedInitializeTimer->setSingleShot(true);
    connect(delayedInitializeTimer, &QTimer::timeout,
            this, &PluginManagerPrivate::nextDelayedInitialize);
    delayedInitializeTimer->start();
}
```

**四阶段时序图**：

```
时间轴 ──────────────────────────────────────────────────────────→

阶段1: loadLibrary()
  [Core] → [TextEditor] → [ProjectExplorer] → [Debugger] → ...
  │ QPluginLoader::load()
  │ 创建 IPlugin 实例
  │ 状态: Read → Loaded

阶段2: initializePlugin()
  [Core.init()] → [TextEditor.init()] → [ProjectExplorer.init()] → ...
  │ 调用 IPlugin::initialize()
  │ 注册 Action、Menu、Service
  │ 状态: Loaded → Initialized

阶段3: initializeExtensions()（反向）
  ... → [ProjectExplorer.extInit()] → [TextEditor.extInit()] → [Core.extInit()]
  │ 调用 IPlugin::extensionsInitialized()
  │ 跨插件协作建立
  │ 状态: Initialized → Running

阶段4: delayedInitialize()（定时器 20ms）
  [Core.delay()] ─20ms─ [TextEditor.delay()] ─20ms─ ...
  │ 非紧急初始化
  │ 事件循环已运行
  │ UI 已显示
```

### 6.4 loadPlugin() 状态转换器

```cpp
void PluginManagerPrivate::loadPlugin(PluginSpec *spec, PluginSpec::State destState)
{
    // 状态机守卫：只在前一状态时处理
    if (spec->hasError() || spec->state() != destState - 1)
        return;

    // 禁用的插件不加载
    if (!spec->isEffectivelyEnabled() && destState == PluginSpec::Loaded)
        return;

    // 崩溃检测锁文件
    std::unique_ptr<LockFile> lockFile;
    if (enableCrashCheck)
        lockFile.reset(new LockFile(this, spec));

    switch (destState) {
    case PluginSpec::Running:
        spec->d->initializeExtensions();  // 阶段3
        return;
    case PluginSpec::Deleted:
        spec->d->kill();
        return;
    default:
        break;
    }

    // 检查所有必要依赖是否已到达目标状态
    for (auto it = deps.cbegin(); it != deps.cend(); ++it) {
        if (it.key().type != PluginDependency::Required)
            continue;
        if (it.value()->state() != destState) {
            // 依赖未就绪，标记错误
            spec->d->hasError = true;
            return;
        }
    }

    // 执行实际的状态转换
    switch (destState) {
    case PluginSpec::Loaded:
        spec->d->loadLibrary();      // QPluginLoader::load()
        break;
    case PluginSpec::Initialized:
        spec->d->initializePlugin(); // IPlugin::initialize()
        break;
    default:
        break;
    }
}
```

### 6.5 关闭流程

```cpp
void PluginManagerPrivate::shutdown()
{
    // 阶段1：按加载顺序调用 aboutToShutdown()
    // 注意：不是反向！
    for (PluginSpec *spec : loadQueue()) {
        if (spec->plugin()) {
            auto flag = spec->plugin()->aboutToShutdown();
            if (flag == IPlugin::AsynchronousShutdown)
                asynchronousPlugins.insert(spec);
        }
    }

    // 阶段2：等待异步关闭
    if (!asynchronousPlugins.isEmpty()) {
        shutdownEventLoop = new QEventLoop;
        shutdownEventLoop->exec();  // 阻塞直到所有异步关闭完成
    }

    // 阶段3：反向删除插件实例
    Utils::reverseForeach(loadQueue(), [this](PluginSpec *spec) {
        loadPlugin(spec, PluginSpec::Deleted);
    });
}
```

### 6.6 插件状态机完整图

```
                   readMetaData()
  [Invalid] ───────────────────────→ [Read]
                                       │
                               resolveDependencies()
                                       │
                                       ↓
                                   [Resolved]
                                       │
                                loadLibrary()
                                       │
                                       ↓
                                   [Loaded]
                                       │
                               initializePlugin()
                                       │
                                       ↓
                                 [Initialized]
                                       │
                          initializeExtensions()
                                       │
                                       ↓
                                   [Running]
                                       │
                              aboutToShutdown()
                                       │
                                       ↓
                                   [Stopped]
                                       │
                                    kill()
                                       │
                                       ↓
                                   [Deleted]
```

---

## 第 7 章 插件元数据与依赖解析 🟡

> **代码阅读指引**：重点看 `pluginspec.cpp` 的 `readMetaData()` 和 `resolveDependencies()` 方法。理解 JSON 元数据格式和版本匹配规则。

### 7.1 PluginSpec 类 🔴

**文件位置**: `src/libs/extensionsystem/pluginspec.h`

```cpp
class EXTENSIONSYSTEM_EXPORT PluginSpec
{
public:
    enum State { Invalid, Read, Resolved, Loaded, Initialized, Running, Stopped, Deleted };

    // 元数据（Read 状态后有效）
    QString name() const;
    QString version() const;
    QString compatVersion() const;
    QString vendor() const;
    QString copyright() const;
    QString license() const;
    QString description() const;
    QString url() const;
    QString category() const;
    QRegularExpression platformSpecification() const;
    bool isRequired() const;
    bool isExperimental() const;
    bool isEnabledByDefault() const;
    QVector<PluginDependency> dependencies() const;

    // 启用状态
    bool isEnabledBySettings() const;
    bool isEffectivelyEnabled() const;
    bool isEnabledIndirectly() const;
    bool isForceEnabled() const;
    bool isForceDisabled() const;

    // 依赖解析结果（Resolved 状态后有效）
    QHash<PluginDependency, PluginSpec *> dependencySpecs() const;

    // 插件实例（Loaded 状态后有效）
    IPlugin *plugin() const;

    // 状态
    State state() const;
    bool hasError() const;
    QString errorString() const;

    // 版本匹配
    bool provides(const QString &pluginName, const QString &version) const;

    static PluginSpec *read(const QString &filePath);
};
```

### 7.2 JSON 元数据格式 🔴

插件元数据通过 `Q_PLUGIN_METADATA` 宏嵌入到插件 DLL 中。开发时使用 `.json.in` 模板，构建时通过 `QMAKE_SUBSTITUTES` 生成最终 `.json`。

**完整 JSON 格式**：

```json
{
    "Name" : "PluginName",
    "Version" : "4.13.3",
    "CompatVersion" : "4.13.0",
    "Required" : false,
    "Experimental" : false,
    "DisabledByDefault" : false,
    "Vendor" : "The Qt Company Ltd",
    "Copyright" : "(C) 2020 The Qt Company Ltd",
    "License" : [
        "Commercial Usage",
        "Licensees holding valid Qt Commercial licenses..."
    ],
    "Description" : "Plugin description text.",
    "Url" : "http://www.qt.io",
    "Category" : "Core",
    "Platform" : "Windows",
    "Dependencies" : [
        { "Name" : "Core", "Version" : "4.13.0" },
        { "Name" : "TextEditor", "Version" : "4.13.0", "Type" : "optional" },
        { "Name" : "CppTools", "Version" : "4.13.0", "Type" : "test" }
    ],
    "Arguments" : [
        {
            "Name" : "-my-arg",
            "Parameter" : "<value>",
            "Description" : "Description of the argument"
        }
    ]
}
```

**字段说明**：

| 字段 | 必填 | 类型 | 说明 |
|------|------|------|------|
| Name | ✅ | string | 插件唯一标识 |
| Version | ✅ | string | 当前版本（x.y.z 格式） |
| CompatVersion | ❌ | string | 兼容版本（默认=Version） |
| Required | ❌ | bool | 是否必须（默认 false） |
| Experimental | ❌ | bool | 实验性（默认 false，自动禁用） |
| DisabledByDefault | ❌ | bool | 默认禁用（默认 false） |
| Vendor | ❌ | string | 开发商 |
| Copyright | ❌ | string | 版权信息 |
| License | ❌ | string/array | 许可证（支持多行） |
| Description | ❌ | string | 描述 |
| Url | ❌ | string | 项目URL |
| Category | ❌ | string | 分类（用于 PluginView 分组） |
| Platform | ❌ | string | 平台限制（正则表达式） |
| Dependencies | ❌ | array | 依赖列表 |
| Arguments | ❌ | array | 命令行参数定义 |

**依赖类型**：

| Type 值 | 枚举值 | 含义 |
|---------|--------|------|
| `"required"` (默认) | `PluginDependency::Required` | 必须依赖，缺少则加载失败 |
| `"optional"` | `PluginDependency::Optional` | 可选依赖，缺少不影响加载 |
| `"test"` | `PluginDependency::Test` | 测试依赖，仅测试时需要 |

### 7.3 元数据解析 readMetaData()

**文件位置**: `pluginspec.cpp`（~180 行代码）

解析流程：

```
readMetaData(pluginMetaData)
├─ 验证 IID 匹配（必须是 "org.qt-project.Qt.QtCreatorPlugin"）
├─ 提取 MetaData 子对象
├─ 解析必填字段
│  ├─ Name（字符串，必须存在）
│  └─ Version（字符串，必须是有效版本格式）
├─ 解析可选字段
│  ├─ CompatVersion（默认=Version）
│  ├─ Required, Experimental, DisabledByDefault（布尔值）
│  ├─ Vendor, Copyright, Description, Url, Category（字符串）
│  ├─ License（支持多行：字符串或字符串数组）
│  └─ Platform（正则表达式，用于平台过滤）
├─ 解析 Dependencies 数组
│  └─ 每个依赖：Name（必须）、Version（必须）、Type（可选）
├─ 解析 Arguments 数组
│  └─ 每个参数：Name（必须）、Parameter（可选）、Description（可选）
└─ 特殊逻辑：Experimental 插件自动 DisabledByDefault
```

**IID 验证代码**：
```cpp
value = pluginMetaData.value(QLatin1String("IID"));
if (value.toString() != PluginManager::pluginIID()) {
    qCDebug(pluginLog) << "Plugin ignored (IID does not match)";
    return false;
}
```

### 7.4 依赖解析 resolveDependencies() 🔴

```cpp
bool PluginSpecPrivate::resolveDependencies(const QVector<PluginSpec *> &specs)
{
    if (hasError)
        return false;
    if (state == PluginSpec::Resolved)
        state = PluginSpec::Read;     // 允许重新解析
    if (state != PluginSpec::Read)
        return false;

    QHash<PluginDependency, PluginSpec *> resolvedDependencies;

    for (const PluginDependency &dependency : qAsConst(dependencies)) {
        // 在所有已知插件中查找提供者
        PluginSpec *found = Utils::findOrDefault(specs,
            [&dependency](PluginSpec *spec) {
                return spec->provides(dependency.name, dependency.version);
            });

        if (!found) {
            if (dependency.type == PluginDependency::Required) {
                hasError = true;
                errorString += tr("Could not resolve dependency '%1(%2)'")
                    .arg(dependency.name, dependency.version);
            }
            continue;  // 可选/测试依赖找不到不报错
        }

        resolvedDependencies.insert(dependency, found);
    }

    if (hasError)
        return false;

    dependencySpecs = resolvedDependencies;
    state = PluginSpec::Resolved;
    return true;
}
```

### 7.5 版本匹配规则 🔴

```cpp
bool PluginSpecPrivate::provides(const QString &pluginName, 
                                  const QString &pluginVersion) const
{
    if (QString::compare(pluginName, name, Qt::CaseInsensitive) != 0)
        return false;
    return (versionCompare(version, pluginVersion) >= 0)
        && (versionCompare(compatVersion, pluginVersion) <= 0);
}
```

**匹配条件**：

```
插件能满足依赖 "需要 PluginX 版本 V" 的条件是：
  1. 插件名匹配（大小写不敏感）
  2. 插件实际版本 ≥ V  （插件至少是依赖要求的版本）
  3. 插件兼容版本 ≤ V  （插件向下兼容到依赖要求的版本）

示例：
  PluginX 实际版本 4.13.3，兼容版本 4.13.0
  → 能满足 "需要 PluginX 4.13.0" ✅
  → 能满足 "需要 PluginX 4.13.2" ✅
  → 能满足 "需要 PluginX 4.13.3" ✅
  → 不能满足 "需要 PluginX 4.14.0" ❌（实际版本不够）
  → 不能满足 "需要 PluginX 4.12.0" ❌（不在兼容范围内）
```

### 7.6 加载队列算法 loadQueue()

```cpp
// 入口
const QVector<PluginSpec *> PluginManagerPrivate::loadQueue()
{
    QVector<PluginSpec *> queue;
    for (PluginSpec *spec : qAsConst(pluginSpecs)) {
        QVector<PluginSpec *> circularityCheckQueue;
        loadQueue(spec, queue, circularityCheckQueue);
    }
    return queue;
}

// 递归实现（拓扑排序）
bool PluginManagerPrivate::loadQueue(PluginSpec *spec,
                                     QVector<PluginSpec *> &queue,
                                     QVector<PluginSpec *> &circularityCheckQueue)
{
    if (queue.contains(spec))
        return true;                   // 已排队

    if (circularityCheckQueue.contains(spec)) {
        spec->d->hasError = true;
        spec->d->errorString = "Circular dependency detected: ...";
        return false;                  // 循环依赖
    }

    circularityCheckQueue.append(spec);

    // 先递归处理所有依赖
    for (auto it = deps.cbegin(); it != deps.cend(); ++it) {
        if (it.key().type == PluginDependency::Test)
            continue;                  // 跳过测试依赖
        if (!loadQueue(it.value(), queue, circularityCheckQueue))
            return false;              // 依赖处理失败
    }

    queue.append(spec);                // 依赖都处理完后才加入自己
    return true;
}
```

**算法本质**：后序遍历的拓扑排序，确保被依赖方排在前面。

### 7.7 启用/禁用逻辑

插件是否最终被加载取决于多个因素：

```
isEffectivelyEnabled() =
  (isEnabledBySettings() || isForceEnabled()) && !isForceDisabled()
  && isAvailableForHostPlatform()

其中：
  isEnabledBySettings() = enabledByDefault（由元数据决定）
                          可被用户设置覆盖
  isForceEnabled()      = 命令行 -load 指定
  isForceDisabled()     = 命令行 -noload 指定
  isAvailableForHostPlatform() = Platform 正则匹配当前平台

间接启用：
  isEnabledIndirectly() = 其他已启用插件的必须依赖指向此插件
                          → 即使用户禁用也会被自动启用
```

---

## 第 8 章 对象池与扩展点机制 🔴

> **代码阅读指引**：对象池是 Qt Creator 插件间通信的核心。理解 `addObject()` / `getObject<T>()` / `objectAdded()` 信号三元组，即可理解大部分跨插件交互。

### 8.1 对象池 API

**文件位置**: `src/libs/extensionsystem/pluginmanager.h`

```cpp
class EXTENSIONSYSTEM_EXPORT PluginManager : public QObject
{
    Q_OBJECT
public:
    // 注册/注销
    static void addObject(QObject *obj);
    static void removeObject(QObject *obj);

    // 按类型查找（模板）
    template <typename T> static T *getObject()
    {
        QReadLocker lock(listLock());
        const QVector<QObject *> all = allObjects();
        for (QObject *obj : all) {
            if (T *result = qobject_cast<T *>(obj))
                return result;
        }
        return nullptr;
    }

    // 按类型和谓词查找
    template <typename T, typename Predicate>
    static T *getObject(Predicate predicate)
    {
        QReadLocker lock(listLock());
        const QVector<QObject *> all = allObjects();
        for (QObject *obj : all) {
            if (T *result = qobject_cast<T *>(obj)) {
                if (predicate(result))
                    return result;
            }
        }
        return nullptr;
    }

    // 按类名查找
    static QObject *getObjectByName(const QString &name);

    // 获取所有对象
    static QVector<QObject *> allObjects();

signals:
    void objectAdded(QObject *obj);
    void aboutToRemoveObject(QObject *obj);
};
```

### 8.2 对象池内部实现

```cpp
void PluginManagerPrivate::addObject(QObject *obj)
{
    {
        QWriteLocker lock(&m_lock);
        if (obj == nullptr) {
            qWarning() << "trying to add null object";
            return;
        }
        if (allObjects.contains(obj)) {
            qWarning() << "trying to add duplicate object";
            return;
        }
        allObjects.append(obj);
    }
    emit q->objectAdded(obj);    // 锁外发信号
}

void PluginManagerPrivate::removeObject(QObject *obj)
{
    if (obj == nullptr) {
        qWarning() << "trying to remove null object";
        return;
    }
    if (!allObjects.contains(obj)) {
        qWarning() << "object not in list";
        return;
    }
    emit q->aboutToRemoveObject(obj);  // 先发信号
    QWriteLocker lock(&m_lock);
    allObjects.removeAll(obj);
}
```

**关键设计**：
- `addObject()` 后发信号 `objectAdded()`
- `removeObject()` 先发信号 `aboutToRemoveObject()`，再删除
- 这保证了观察者能在对象删除前做清理

### 8.3 扩展点模式 🔴

对象池本身只是一个 `QVector<QObject*>`，"扩展点"是建立在对象池之上的**设计模式**，不是框架强制的机制。

**模式定义**：

```
扩展点 = 一个接口（纯虚类）+ 对象池注册/查询约定

1. 定义方（通常是 CorePlugin 或框架插件）：
   - 定义接口类 IXxx（继承 QObject）
   - 在 extensionsInitialized() 中查询所有 IXxx 实现

2. 实现方（具体插件）：
   - 继承 IXxx
   - 在 initialize() 中 addObject(new MyXxxImpl)

3. 运行时：
   - getObject<IXxx>() 获取单个实现
   - getObjects<IXxx>() 获取所有实现
   - objectAdded() 信号监听新注册
```

### 8.4 核心扩展点列表

| 扩展点接口 | 定义位置 | 用途 | 典型实现 |
|-----------|---------|------|---------|
| `IEditor` | coreplugin/editormanager/ieditor.h | 编辑器 | TextEditor, BinEditor |
| `IEditorFactory` | coreplugin/ieditorfactory.h | 创建编辑器 | TextEditorFactory |
| `IMode` | coreplugin/imode.h | IDE 模式 | EditMode, DesignMode |
| `INavigationWidgetFactory` | coreplugin/inavigationwidgetfactory.h | 导航面板 | ProjectTree, Outline |
| `IOutputPane` | coreplugin/ioutputpane.h | 输出面板 | AppOutput, Compile |
| `IDocument` | coreplugin/idocument.h | 文档抽象 | TextDocument |
| `IDocumentFactory` | coreplugin/idocumentfactory.h | 创建文档 | - |
| `IWizardFactory` | coreplugin/iwizardfactory.h | 新建向导 | CustomWizard |
| `IVersionControl` | coreplugin/iversioncontrol.h | 版本控制 | GitClient |
| `IWelcomePage` | coreplugin/iwelcomepage.h | 欢迎页 | ExamplesPage |

### 8.5 实际使用模式

#### 模式1：注册服务实现

```cpp
// BinEditor 插件：注册编辑器工厂和服务
BinEditorPluginPrivate::BinEditorPluginPrivate()
{
    ExtensionSystem::PluginManager::addObject(&m_factoryService);
    ExtensionSystem::PluginManager::addObject(&m_editorFactory);
}

// 析构时注销
BinEditorPluginPrivate::~BinEditorPluginPrivate()
{
    ExtensionSystem::PluginManager::removeObject(&m_editorFactory);
    ExtensionSystem::PluginManager::removeObject(&m_factoryService);
}
```

#### 模式2：注册自身作为可发现对象

```cpp
// Debugger 插件：将自身注册到对象池
bool DebuggerPlugin::initialize(const QStringList &arguments, QString *errorMessage)
{
    ExtensionSystem::PluginManager::addObject(this);
    dd = new DebuggerPluginPrivate(arguments);
    return true;
}

// 其他插件通过名字发现
static QObject *debuggerPlugin()
{
    return ExtensionSystem::PluginManager::getObjectByName("DebuggerPlugin");
}
```

#### 模式3：可选依赖的运行时发现

```cpp
// DiffEditor 检查 CodePaster 服务是否可用
void DiffEditorWidgetController::addCodePasterAction(QMenu *menu, ...)
{
    if (ExtensionSystem::PluginManager::getObject<CodePaster::Service>()) {
        // CodePaster 插件已加载，添加菜单项
        menu->addAction(tr("Send Chunk to CodePaster..."));
    }
    // 否则不显示此菜单项
}
```

#### 模式4：动态方法调用（Invoker）

```cpp
// VcsBase 使用 Invoker 调用 CppModelManager 的方法
// 不需要 #include CppModelManager 头文件
QObject *cppModelManager = 
    ExtensionSystem::PluginManager::getObjectByName("CppModelManager");
if (cppModelManager) {
    const auto symbols = ExtensionSystem::invoke<QSet<QString>>(
        cppModelManager, "symbolsInFiles", files);
    completionItems += symbols;
}
```

### 8.6 对象池 vs. Aggregation 对比

```
对象池 PluginManager::addObject/getObject:
  ┌───────────────────────────────┐
  │ [IEditor_A] [IMode_B] [IOutputPane_C] [IEditor_D] ... │
  └───────────────────────────────┘
  → 全局扁平列表，线性搜索
  → 用于"服务发现"：找到实现某接口的对象

Aggregation query<T>:
  ┌─ Aggregate_1 ────────────┐
  │ [EditorImpl] [FindSupport] [TextEditorImpl] │
  └─────────────────────────┘
  → 局部组件组合，组内查询
  → 用于"接口组合"：一个逻辑实体的多个方面

两者协作：
  1. PluginManager::getObject<IEditor>() → 找到 EditorImpl
  2. Aggregation::query<IFindSupport>(editor) → 从同一聚合体找到 FindSupport
```

---

## 第 9 章 CorePlugin 架构 🟡

> **代码阅读指引**：CorePlugin 是所有插件的根依赖，提供 IDE 框架的核心服务。重点看 `icore.h`（全局 API）、`mainwindow.h`（UI 骨架）、`coreplugin.cpp`（初始化流程）。

### 9.1 CorePlugin 概览

| 指标 | 数值 |
|------|------|
| 文件数 | 90+ 源文件 + 7 子目录 |
| 核心类数 | ~40 |
| 依赖 | aggregation, extensionsystem, utils |
| 被依赖方 | 几乎所有其他插件 |

**子目录结构**：

```
coreplugin/
├── actionmanager/      # 命令与菜单管理
├── dialogs/            # 对话框（设置、关于等）
├── editormanager/      # 编辑器管理
├── find/               # 查找替换
├── locator/            # 快速定位器（Ctrl+K）
├── progressmanager/    # 进度显示
└── *.h/*.cpp           # 核心类
```

### 9.2 ICore 全局接口 🔴

**文件位置**: `src/plugins/coreplugin/icore.h`（174 行）

ICore 是一个**单例**，提供 IDE 全局服务的静态方法：

```cpp
class CORE_EXPORT ICore : public QObject
{
    Q_OBJECT
public:
    static ICore *instance();

    // UI 操作
    static QMainWindow *mainWindow();
    static QWidget *dialogParent();
    static bool showOptionsDialog(const Utils::Id page, QWidget *parent = nullptr);

    // 设置
    static QSettings *settings(QSettings::Scope scope = QSettings::UserScope);
    static SettingsDatabase *settingsDatabase();

    // 资源路径
    static QString resourcePath();        // share/qtcreator/
    static QString userResourcePath();    // ~/.config/QtProject/qtcreator/
    static QString cacheResourcePath();   // 缓存目录

    // 上下文管理
    static IContext *currentContextObject();
    static void addContextObject(IContext *context);
    static void removeContextObject(IContext *context);
    static void updateAdditionalContexts(const Context &remove, const Context &add,
                                         ContextPriority priority = ContextPriority::Low);

    // 文件操作
    static void openFiles(const QStringList &fileNames, OpenFilesFlags flags = None);

signals:
    void coreAboutToOpen();              // 主窗口即将显示
    void coreOpened();                   // 主窗口已显示
    void saveSettingsRequested(SaveSettingsReason reason);
    void coreAboutToClose();             // 即将关闭
    void contextAboutToChange(const QList<Core::IContext *> &context);
    void contextChanged(const Core::Context &context);
};
```

### 9.3 CorePlugin 初始化流程

**文件位置**: `src/plugins/coreplugin/coreplugin.cpp`（349 行）

```cpp
bool CorePlugin::initialize(const QStringList &arguments, QString *errorMessage)
{
    // 1. MIME 类型注册
    //    遍历所有插件的元数据，注册其声明的 MIME 类型
    for (PluginSpec *plugin : PluginManager::plugins()) {
        if (!plugin->isEffectivelyEnabled()) continue;
        const QJsonValue mimetypes = plugin->metaData().value("Mimetypes");
        // 注册到 MIME 数据库
    }

    // 2. 主题初始化
    Theme *theme = ThemeEntry::createTheme(args.themeId);
    setCreatorTheme(theme);

    // 3. ActionManager 创建
    new ActionManager(this);

    // 4. MainWindow 创建和初始化
    m_mainWindow = new MainWindow;
    m_mainWindow->init();

    // 5. 编辑模式创建
    m_editMode = new EditMode;
    ModeManager::activateMode(m_editMode->id());

    // 6. 向导、查找、定位器初始化
    IWizardFactory::initialize();
    Find::initialize();
    m_locator->initialize();

    // 7. 宏展开器注册
    //    注册 CurrentDate, CurrentTime, Config, HostOs, UUID 等变量

    return true;
}
```

### 9.4 MainWindow 布局

```
┌──────────────────────────────────────────────────────────┐
│ 菜单栏 (Menu Bar)                                         │
│  File | Edit | View | Tools | Window | Help               │
├────┬─────────────────────────────────────────────┬───────┤
│    │                                             │       │
│ 模 │  编辑器区域 (Editor Area)                    │ 右    │
│ 式 │  ┌─────────────────────────────────────────┐│ 侧    │
│ 选 │  │ EditorManager                          ││ 栏    │
│ 择 │  │  - 标签页                               ││       │
│ 器 │  │  - 分屏                                 ││ Right │
│    │  │  - 编辑器内容                            ││ Nav   │
│ F  │  └─────────────────────────────────────────┘│ Widget│
│ a  │                                             │       │
│ n  │                                             │       │
│ c  ├─────────────────────────────────────────────┤       │
│ y  │ 输出面板区域 (Output Panes)                   │       │
│    │  编译输出 | 应用输出 | 搜索结果 | 问题         │       │
│ T  │                                             │       │
│ a  │                                             │       │
│ b  │                                             │       │
├────┴─────────────────────────────────────────────┴───────┤
│ 状态栏 (Status Bar)                                       │
│  进度条 | 行号列号 | 编码 | 模式指示                       │
└──────────────────────────────────────────────────────────┘
```

**左侧导航栏**（由 NavigationWidget 管理）：
- 项目树 (Projects)
- 文件系统 (File System)
- 打开文件列表 (Open Documents)
- 书签 (Bookmarks)
- 大纲 (Outline)

### 9.5 上下文系统 (Context)

上下文系统是 CorePlugin 的核心设计，用于**根据当前焦点决定命令行为**：

```
Context 工作流程：
1. 每个 IContext 对象关联一个 QWidget 和若干 Context ID
2. 当焦点变化时，MainWindow 收集当前焦点链上的所有 Context
3. ActionManager 根据当前 Context 激活/禁用命令
4. 同一命令在不同上下文中可以有不同的实现

示例：
  - 在 TextEditor 中按 Ctrl+C → 调用 TextEditor 的复制
  - 在 ProjectTree 中按 Ctrl+C → 调用 ProjectTree 的复制
  - 两者是同一个 Command "Core.Copy"，但绑定不同 QAction
```

---

## 第 10 章 ActionManager 系统 🟡

> **代码阅读指引**：`actionmanager/actionmanager.h`（95 行）定义全局 API，`command.h`（105 行）是命令抽象，`actioncontainer.h`（80 行）是菜单/工具栏容器。

### 10.1 ActionManager 全局 API

```cpp
class CORE_EXPORT ActionManager : public QObject
{
    Q_OBJECT
public:
    static ActionManager *instance();

    // 创建容器
    static ActionContainer *createMenu(Utils::Id id);
    static ActionContainer *createMenuBar(Utils::Id id);
    static ActionContainer *createTouchBar(Utils::Id id, const QIcon &icon,
                                           const QString &text);

    // 注册/注销命令
    static Command *registerAction(QAction *action, Utils::Id id,
                                   const Context &context = Context(Constants::C_GLOBAL),
                                   bool scriptable = false);
    static void unregisterAction(QAction *action, Utils::Id id);

    // 查找
    static Command *command(Utils::Id id);
    static ActionContainer *actionContainer(Utils::Id id);
    static QList<Command *> commands();

    // 演示模式
    static void setPresentationModeEnabled(bool enabled);

signals:
    void commandListChanged();
    void commandAdded(Utils::Id id);
};
```

### 10.2 Command 命令抽象

```cpp
class CORE_EXPORT Command : public QObject
{
    Q_OBJECT
public:
    enum CommandAttribute {
        CA_Hide = 1,              // 在 UI 中隐藏
        CA_UpdateText = 2,        // 动态更新文本
        CA_UpdateIcon = 4,        // 动态更新图标
        CA_NonConfigurable = 8    // 不出现在快捷键设置中
    };

    // 快捷键
    virtual void setDefaultKeySequence(const QKeySequence &key) = 0;
    virtual QKeySequence keySequence() const = 0;
    virtual QList<QKeySequence> keySequences() const = 0;

    // 标识
    virtual Utils::Id id() const = 0;
    virtual QAction *action() const = 0;
    virtual Context context() const = 0;

    // 状态
    virtual bool isActive() const = 0;
    virtual bool isScriptable() const = 0;

signals:
    void keySequenceChanged();
    void activeStateChanged();
};
```

### 10.3 ActionContainer 菜单容器

```cpp
class CORE_EXPORT ActionContainer : public QObject
{
    Q_OBJECT
public:
    // 获取底层 Qt 控件
    virtual QMenu *menu() const = 0;
    virtual QMenuBar *menuBar() const = 0;

    // 分组管理
    virtual void appendGroup(Utils::Id group) = 0;
    virtual void insertGroup(Utils::Id before, Utils::Id group) = 0;

    // 添加内容
    virtual void addAction(Command *action, Utils::Id group = {}) = 0;
    virtual void addMenu(ActionContainer *menu, Utils::Id group = {}) = 0;
    Command *addSeparator(Utils::Id group = {});
};
```

### 10.4 上下文感知命令调度

ActionManager 的核心设计是**同一命令 ID 可以绑定多个 QAction，根据当前上下文选择激活哪个**：

```
registerAction(editorCopyAction,  "Core.Copy", Context("TextEditor.Context"))
registerAction(treeCopyAction,    "Core.Copy", Context("ProjectTree.Context"))
registerAction(globalCopyAction,  "Core.Copy", Context(C_GLOBAL))

用户按 Ctrl+C 时：
  1. ActionManager 获取当前上下文列表
  2. 按优先级匹配：TextEditor.Context > ProjectTree.Context > C_GLOBAL
  3. 触发匹配到的 QAction
```

### 10.5 菜单结构

MainWindow 中注册的默认菜单：

```
Menu Bar
├── File (M_FILE)
│   ├── G_FILE_NEW     ── 新建
│   ├── G_FILE_OPEN    ── 打开
│   ├── G_FILE_PROJECT ── 项目
│   ├── G_FILE_SAVE    ── 保存
│   ├── G_FILE_EXPORT  ── 导出
│   ├── G_FILE_CLOSE   ── 关闭
│   ├── G_FILE_PRINT   ── 打印
│   └── G_FILE_OTHER   ── 其他（退出）
├── Edit (M_EDIT)
│   ├── G_EDIT_UNDOREDO    ── 撤销/重做
│   ├── G_EDIT_COPYPASTE   ── 复制/粘贴
│   ├── G_EDIT_SELECTALL   ── 全选
│   ├── G_EDIT_ADVANCED    ── 高级编辑
│   ├── G_EDIT_FIND        ── 查找
│   └── G_EDIT_OTHER       ── 其他
├── View (M_VIEW)
├── Tools (M_TOOLS)
├── Window (M_WINDOW)
│   ├── G_WINDOW_SIZE      ── 窗口大小
│   ├── G_WINDOW_SPLIT     ── 分屏
│   └── G_WINDOW_NAVIGATE  ── 导航
└── Help (M_HELP)
    ├── G_HELP_HELP    ── 帮助内容
    └── G_HELP_ABOUT   ── 关于
```

---

## 第 11 章 编辑器管理 🟡

> **代码阅读指引**：`editormanager/editormanager.h`（216 行）是编辑器管理的全局 API。理解 IEditor → IDocument → EditorManager 三者关系即可。

### 11.1 EditorManager 全局 API

```cpp
class CORE_EXPORT EditorManager : public QObject
{
    Q_OBJECT
public:
    // 打开编辑器
    static IEditor *openEditor(const QString &fileName, Utils::Id editorId = {},
                               OpenEditorFlags flags = NoFlags, bool *newEditor = nullptr);
    static IEditor *openEditorAt(const QString &fileName, int line, int column = 0, ...);
    static IEditor *openEditorWithContents(Utils::Id editorId, QString *titlePattern = nullptr,
                                           const QByteArray &contents = QByteArray(), ...);

    // 查询当前状态
    static IDocument *currentDocument();
    static IEditor *currentEditor();
    static QList<IEditor *> visibleEditors();

    // 激活编辑器
    static void activateEditor(IEditor *editor, OpenEditorFlags flags = NoFlags);

    // 关闭操作
    static bool closeDocument(IDocument *document, bool askAboutModifiedEditors = true);
    static bool closeAllDocuments();

    // 保存操作
    static bool saveDocument(IDocument *document);

    // 导航历史
    static void addCurrentPositionToNavigationHistory(const QByteArray &saveState);

    // 状态持久化
    static QByteArray saveState();
    static bool restoreState(const QByteArray &state);

signals:
    void currentEditorChanged(Core::IEditor *editor);
    void editorOpened(Core::IEditor *editor);
    void editorsClosed(QList<Core::IEditor *> editors);
    void documentOpened(Core::IDocument *document);
    void documentClosed(Core::IDocument *document);
};
```

### 11.2 IEditor 接口

```cpp
class CORE_EXPORT IEditor : public IContext
{
    Q_OBJECT
public:
    virtual IDocument *document() const = 0;   // 关联文档
    virtual IEditor *duplicate() { return nullptr; }  // 复制编辑器
    virtual QWidget *toolBar() = 0;            // 编辑器工具栏
    virtual int currentLine() const;
    virtual int currentColumn() const;
    virtual void gotoLine(int line, int column = 0, bool centerLine = true);
    virtual QByteArray saveState() const;
    virtual bool restoreState(const QByteArray &state);
    virtual bool isDesignModePreferred() const;

    bool duplicateSupported() const;
};
```

### 11.3 三层架构

```
┌───────────────────┐
│   EditorManager   │ ← 全局管理器（单例）
│  管理所有编辑器    │    打开、关闭、切换、保存
├───────────────────┤
│     IEditor       │ ← 编辑器实例
│  提供编辑 UI      │    每个打开的标签页对应一个
│  继承 IContext     │    上下文感知
├───────────────────┤
│    IDocument      │ ← 文档模型
│  管理文件内容      │    多个 IEditor 可共享一个 IDocument
│  处理保存/加载     │    监听文件系统变化
└───────────────────┘
```

### 11.4 打开编辑器流程

```
EditorManager::openEditor("main.cpp")
├─ 1. 查找已打开的文档 → 有则激活返回
├─ 2. 确定 MIME 类型 → text/x-c++src
├─ 3. 查找匹配的 IEditorFactory
│     → 遍历对象池中所有 IEditorFactory
│     → 匹配 mimeType
├─ 4. 调用 factory->createEditor()
│     → 创建 IEditor 实例
│     → 创建关联的 IDocument
├─ 5. 加载文件内容
├─ 6. 将编辑器添加到 DocumentModel
├─ 7. 显示编辑器（创建标签页）
└─ 8. 发射 editorOpened() 信号
```

---

## 第 12 章 代表性插件分析 🟢

> **代码阅读指引**：选择 TextEditor 和 ProjectExplorer 作为代表，了解大型插件的内部组织和与框架的交互模式。

### 12.1 TextEditor 插件

| 指标 | 数值 |
|------|------|
| 文件数 | 238 |
| 核心文件 | texteditor.cpp (8817行)、textdocument.cpp (1118行) |
| 分类 | Core（核心插件） |
| 依赖 | CorePlugin |

**职责**：
- 提供文本编辑器基础框架
- 语法高亮、代码折叠、行号
- 自动补全框架
- 查找替换集成
- 缩进管理

**核心类**：

```cpp
class TextEditorPlugin : public ExtensionSystem::IPlugin { ... };

class TextEditorWidget : public QPlainTextEdit {
    // 8817 行：完整的代码编辑器控件
    void setCursorPosition(int pos);
    void print(QPrinter *);
    void setAutoCompleter(AutoCompleter *);
    void setHighlightCurrentLine(bool);
    void setCodeFoldingSupported(bool);
    void invokeAssist(AssistKind, IAssistProvider *);
    // ...
};
```

### 12.2 ProjectExplorer 插件

| 指标 | 数值 |
|------|------|
| 文件数 | 283 |
| 核心文件 | projectexplorer.cpp (4010行)、project.cpp (1250行) |
| 分类 | Core（核心插件） |
| 依赖 | CorePlugin, TextEditor |

**数据模型**：

```
Project（项目）
├── Target（构建目标）= Project + Kit
│   ├── BuildConfiguration（构建配置）
│   │   ├── Debug
│   │   └── Release
│   └── RunConfiguration（运行配置）
│       ├── 环境变量
│       ├── 工作目录
│       └── 命令行参数
└── Kit（工具包）
    ├── 编译器
    ├── 调试器
    ├── 目标架构
    └── 设备/平台
```

**核心类**：

```cpp
class Project : public QObject {
    QString displayName() const;
    BuildSystem *createBuildSystem(Target *target) const;
    Utils::FilePath projectFilePath() const;
    ProjectNode *rootProjectNode() const;
};

class Target : public QObject {
    Project *project() const;
    Kit *kit() const;
    BuildConfiguration *activeBuildConfiguration() const;
    const QList<BuildConfiguration *> buildConfigurations() const;
};
```

---

## 第 13 章 HelloWorld 插件——开发模板 🟡

> **代码阅读指引**：HelloWorld 是最简单的完整插件，仅 319 行代码（7 个文件）。它演示了插件开发的所有基本模式，是开发新插件的最佳起点。

### 13.1 文件清单

```
helloworld/
├── HelloWorld.json.in           19 行  ── 元数据模板
├── helloworld.pro                7 行  ── 项目文件
├── helloworld_dependencies.pri   9 行  ── 依赖声明
├── helloworldplugin.h           56 行  ── 插件头文件
├── helloworldplugin.cpp        147 行  ── 插件实现
├── helloworldwindow.h           42 行  ── 窗口头文件
└── helloworldwindow.cpp         39 行  ── 窗口实现
    合计                        319 行
```

### 13.2 插件声明

```cpp
// helloworldplugin.h
class HelloWorldPlugin : public ExtensionSystem::IPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QtCreatorPlugin" FILE "HelloWorld.json")

public:
    HelloWorldPlugin();
    ~HelloWorldPlugin() override;

    bool initialize(const QStringList &arguments, QString *errorMessage) override;
    void extensionsInitialized() override;

private:
    void sayHelloWorld();
    HelloMode *m_helloMode = nullptr;
};
```

**关键要素**：
- 继承 `ExtensionSystem::IPlugin`
- `Q_PLUGIN_METADATA` 宏指定 IID 和 JSON 文件
- 实现 `initialize()` 和 `extensionsInitialized()`

### 13.3 自定义 Mode

```cpp
// helloworldplugin.cpp
class HelloMode : public Core::IMode
{
public:
    HelloMode()
    {
        setWidget(new QPushButton(tr("Hello World PushButton!")));
        setContext(Core::Context("HelloWorld.MainView"));
        setDisplayName(tr("Hello world!"));
        setIcon(QIcon());
        setPriority(0);
        setId("HelloWorld.HelloWorldMode");
    }
};
```

**模式**：IMode 子类，设置 widget/context/displayName/icon/priority/id 即可在模式选择器中显示。

### 13.4 初始化：注册菜单和命令

```cpp
bool HelloWorldPlugin::initialize(const QStringList &arguments, QString *errorMessage)
{
    // 1. 创建上下文
    Core::Context context("HelloWorld.MainView");

    // 2. 创建 QAction
    auto helloWorldAction = new QAction(tr("Say \"&Hello World!\""), this);
    connect(helloWorldAction, &QAction::triggered, 
            this, &HelloWorldPlugin::sayHelloWorld);

    // 3. 注册到 ActionManager
    Core::Command *command = Core::ActionManager::registerAction(
        helloWorldAction, "HelloWorld.HelloWorldAction", context);

    // 4. 创建菜单
    Core::ActionContainer *helloWorldMenu =
        Core::ActionManager::createMenu("HelloWorld.HelloWorldMenu");
    helloWorldMenu->menu()->setTitle(tr("&Hello World"));
    helloWorldMenu->menu()->setEnabled(true);

    // 5. 将命令添加到菜单
    helloWorldMenu->addAction(command);

    // 6. 将菜单添加到 Tools 菜单
    Core::ActionContainer *toolsMenu =
        Core::ActionManager::actionContainer(Core::Constants::M_TOOLS);
    toolsMenu->addMenu(helloWorldMenu);

    // 7. 创建模式
    m_helloMode = new HelloMode;

    return true;
}

void HelloWorldPlugin::extensionsInitialized()
{
    // HelloWorld 不依赖其他插件，所以这里为空
}
```

### 13.5 依赖声明

```pro
# helloworld_dependencies.pri
QTC_PLUGIN_NAME = HelloWorld
QTC_LIB_DEPENDS += \
    extensionsystem
QTC_PLUGIN_DEPENDS += \
    coreplugin
QTC_PLUGIN_RECOMMENDS += \
    # optional plugin dependencies
```

### 13.6 元数据模板

```json
{
    "Name" : "HelloWorld",
    "Version" : "$$QTCREATOR_VERSION",
    "CompatVersion" : "$$QTCREATOR_COMPAT_VERSION",
    "DisabledByDefault" : true,
    "Vendor" : "The Qt Company Ltd",
    "Copyright" : "(C) $$QTCREATOR_COPYRIGHT_YEAR The Qt Company Ltd",
    "License" : [ "..." ],
    "Description" : "Hello World sample plugin.",
    "Url" : "http://www.qt.io",
    "$$dependencyList"
}
```

**注意**：`$$dependencyList` 是构建时由 `qtcreatorplugin.pri` 替换为实际的 JSON 依赖数组。

### 13.7 开发新插件的步骤

基于 HelloWorld 模板开发新插件：

```
1. 复制 helloworld/ 目录，重命名
2. 修改 *_dependencies.pri
   - QTC_PLUGIN_NAME = YourPlugin
   - 添加所需依赖
3. 修改 *.json.in
   - Name, Description 等元数据
4. 修改 *.pro
   - 文件列表
5. 实现 YourPlugin : public ExtensionSystem::IPlugin
   - initialize(): 注册 Action、Menu、Mode
   - extensionsInitialized(): 跨插件协作
6. 在 src/plugins/plugins.pro 的 SUBDIRS 中添加目录名
7. 构建测试
```

---

## 第 14 章 跨插件通信模式 🟢

> **代码阅读指引**：理解 Qt Creator 插件间通信的五种模式，按耦合度从低到高排列。

### 14.1 五种通信模式概览

| 模式 | 耦合度 | 编译依赖 | 运行时查找 | 典型用途 |
|------|--------|---------|-----------|---------|
| 信号槽直连 | 高 | 需要头文件 | 不需要 | 同插件内通信 |
| 对象池 getObject<T> | 中 | 需要接口头文件 | 类型匹配 | 标准扩展点 |
| 对象池 getObjectByName | 低 | 不需要 | 字符串匹配 | 软依赖 |
| Invoker 动态调用 | 最低 | 不需要 | 字符串+QMetaObject | 完全解耦 |
| Aggregation query | 中 | 需要接口头文件 | 组件查询 | 多接口对象 |

### 14.2 模式1：信号槽直连

```cpp
// 同一插件或有编译依赖的插件之间
connect(editorManager, &EditorManager::currentEditorChanged,
        this, &MyPlugin::onEditorChanged);
```

**优点**：类型安全、性能好
**缺点**：需要头文件依赖

### 14.3 模式2：对象池类型查询

```cpp
// 查找实现某接口的对象
auto *factory = ExtensionSystem::PluginManager::getObject<IEditorFactory>(
    [](IEditorFactory *f) {
        return f->mimeTypes().contains("text/x-c++src");
    });
```

**优点**：标准化、类型安全
**缺点**：需要接口头文件

### 14.4 模式3：按名称查找

```cpp
// 不需要任何头文件依赖
QObject *debugger = ExtensionSystem::PluginManager::getObjectByName("DebuggerPlugin");
if (debugger) {
    // 使用 QMetaObject 调用方法
}
```

**优点**：零编译依赖
**缺点**：不类型安全、字符串易出错

### 14.5 模式4：Invoker 动态调用

```cpp
// 完全解耦：不需要头文件、不需要编译依赖
QObject *cppModelManager = PluginManager::getObjectByName("CppModelManager");
if (cppModelManager) {
    auto symbols = ExtensionSystem::invoke<QSet<QString>>(
        cppModelManager, "symbolsInFiles", files);
}
```

**优点**：最大解耦
**缺点**：运行时发现、性能开销、无编译检查

### 14.6 模式5：Aggregation 查询

```cpp
// 从一个接口查询同一聚合体中的另一个接口
IEditor *editor = ...;  // 从 EditorManager 获取
IFindSupport *find = Aggregation::query<IFindSupport>(editor);
if (find) {
    find->findNext("searchText");
}
```

**优点**：多接口组合
**缺点**：需要接口头文件

### 14.7 推荐使用场景

```
开发新插件时的选择指南：

需要与 CorePlugin 交互？
  → 模式2：getObject<IEditor>()

需要与可选插件交互？
  → 模式3：getObjectByName("PluginName")
  → 或模式4：invoke<T>(obj, "method")

实现多个接口？
  → 模式5：Aggregation

插件内部通信？
  → 模式1：直接信号槽
```

---

## 第 15 章 裁剪方案 🟡

> **代码阅读指引**：基于前面所有章节的分析，给出裁剪 Qt Creator 到独立应用的方案。

### 15.1 最小可运行系统

要构建一个基于 Qt Creator 插件系统的独立应用，最少需要：

```
必须保留的库：
  ExtensionSystem  (22 文件, ~2500 行)  ── 插件框架核心
  Aggregation      (6 文件, ~400 行)    ── 组件组合
  Utils            (288 文件, ~70000 行) ── 基础设施

必须保留的插件：
  CorePlugin       (90+ 文件)           ── IDE 框架

合计约 400+ 文件
```

### 15.2 三级裁剪方案

#### 方案 A：最小框架（仅保留插件系统骨架）

```
保留：
  src/libs/extensionsystem/
  src/libs/aggregation/
  src/libs/utils/（精简）
  src/app/main.cpp（精简）

移除：
  所有插件（包括 CorePlugin）
  其他所有库
  tests/、share/、doc/ 等

结果：
  一个空的插件加载器
  可以加载自定义插件
  无任何 UI
  代码量约 3000 行
```

#### 方案 B：基础 IDE 框架

```
保留：
  方案 A 全部
  src/plugins/coreplugin/（精简）
  src/libs/utils/（完整）

移除：
  所有非核心插件
  cplusplus, qmljs, clangsupport 等语言库
  ssh, modelinglib, tracing 等可选库

结果：
  带菜单、工具栏、模式选择器的空 IDE
  支持 EditorManager、ActionManager
  可以通过插件添加功能
  代码量约 80000 行
```

#### 方案 C：定制化 IDE

```
保留：
  方案 B 全部
  src/plugins/texteditor/（文本编辑）
  src/plugins/projectexplorer/（项目管理）
  选择性保留其他插件

移除：
  不需要的语言支持插件
  不需要的平台支持插件
  不需要的工具插件

结果：
  完整的可定制 IDE
  按需启用插件
  代码量视选择而定
```

### 15.3 裁剪操作步骤

#### 步骤1：修改品牌

```pro
# qtcreator_ide_branding.pri
IDE_DISPLAY_NAME = MyApp
IDE_ID = myapp
IDE_CASED_ID = MyApp
PRODUCT_BUNDLE_ORGANIZATION = com.mycompany
```

#### 步骤2：修改插件列表

```pro
# src/plugins/plugins.pro
SUBDIRS = \
    coreplugin \        # 核心（必须）
    texteditor \        # 按需
    myCustomPlugin      # 自定义插件
```

#### 步骤3：修改库列表

```pro
# src/libs/libs.pro
SUBDIRS = \
    aggregation \       # 必须
    extensionsystem \   # 必须
    utils               # 必须
```

#### 步骤4：修改 main.cpp

```cpp
// 修改插件搜索路径
PluginManager::setPluginPaths(QStringList() << myPluginPath);

// 修改 IID（可选，防止加载不兼容的插件）
PluginManager::setPluginIID(QLatin1String("com.mycompany.Plugin"));

// 修改设置路径
QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, mySettingsPath);
```

### 15.4 Utils 库精简指南

Utils 库有 288 个文件，但很多是可选的：

```
必须保留的 Utils 组件：
  algorithm.h          ── 容器算法
  fileutils.*          ── 文件操作
  hostosinfo.h         ── 系统检测
  qtcassert.*          ── 断言宏
  savefile.*           ── 安全文件写入
  stringutils.*        ── 字符串工具
  theme/theme.*        ── 主题系统
  mimetypes/*          ── MIME 类型

可以移除的 Utils 组件：
  ssh/                 ── SSH 相关
  touchbar/            ── Touch Bar (macOS)
  processenums.*       ── 进程管理（如无需）
  wizard*              ── 向导框架（如无需）
```

### 15.5 裁剪后的构建验证

```bash
# 1. 修改后先编译检查
qmake qtcreator.pro
make -j$(nproc) 2>&1 | head -100

# 2. 常见错误：
#    - 未定义引用 → 缺少库依赖，检查 _dependencies.pri
#    - 头文件找不到 → 缺少库，检查 INCLUDEPATH
#    - 链接错误 → 缺少 .so/.dll，检查 LIBS

# 3. 运行验证
./bin/myapp -version
./bin/myapp -noload AllPlugins  # 不加载插件，验证基础框架
```

---

## 第 16 章 定制化 UI 方案 🟢

> **代码阅读指引**：如何在保留插件系统的前提下，替换 Qt Creator 的 UI 外观和行为。

### 16.1 主题定制

**主题文件位置**: `share/qtcreator/themes/`

```
主题文件格式：.creatortheme（INI 格式）
├── [General] 节
│   └── ThemeName = "MyTheme"
├── [Palette] 节
│   ├── shadowBackground = #ff1e1e1e
│   ├── text = #ffcccccc
│   └── ... 完整调色板
└── [Colors] 节
    ├── BackgroundColorNormal = shadowBackground
    ├── TextColorNormal = text
    └── ... 语义颜色映射
```

### 16.2 模式定制

替换或添加 IDE 模式：

```cpp
// 自定义 Mode
class MyMode : public Core::IMode
{
public:
    MyMode()
    {
        setWidget(new MyMainWidget);
        setContext(Core::Context("MyApp.MainView"));
        setDisplayName(tr("My View"));
        setIcon(QIcon(":/icons/mymode.png"));
        setPriority(100);  // 值越高排越前
        setId("MyApp.MyMode");
    }
};
```

### 16.3 欢迎页定制

```cpp
// 实现 IWelcomePage 接口
class MyWelcomePage : public Core::IWelcomePage
{
public:
    QString title() const override { return tr("Getting Started"); }
    int priority() const override { return 100; }
    Utils::Id id() const override { return "MyApp.Welcome"; }
    QWidget *createWidget() const override { return new MyWelcomeWidget; }
};
```

### 16.4 导航栏定制

```cpp
// 实现 INavigationWidgetFactory
class MyNavigationFactory : public Core::INavigationWidgetFactory
{
public:
    MyNavigationFactory()
    {
        setDisplayName(tr("My Navigator"));
        setPriority(300);
        setId("MyApp.MyNavigator");
        setActivationSequence(QKeySequence(tr("Alt+M")));
    }

    Core::NavigationView createWidget() override
    {
        return {new MyNavigatorWidget};
    }
};
```

### 16.5 输出面板定制

```cpp
// 实现 IOutputPane
class MyOutputPane : public Core::IOutputPane
{
    Q_OBJECT
public:
    QWidget *outputWidget(QWidget *parent) override { return new MyOutputWidget(parent); }
    QString displayName() const override { return tr("My Output"); }
    int priorityInStatusBar() const override { return 50; }
    void clearContents() override { m_widget->clear(); }
    // ... 其他必须实现的纯虚函数
};
```

### 16.6 完整的品牌替换清单

| 项目 | 文件 | 说明 |
|------|------|------|
| 应用名称 | qtcreator_ide_branding.pri | IDE_DISPLAY_NAME |
| 应用图标 | src/app/app_icon.ico | 替换图标文件 |
| 闪屏 | src/plugins/coreplugin/core_icons.h | 启动画面 |
| 关于对话框 | coreplugin/versiondialog.cpp | 版本信息 |
| 主题 | share/qtcreator/themes/ | 颜色方案 |
| 翻译 | share/qtcreator/translations/ | 本地化 |
| 文档 | doc/ | 帮助内容 |
| 安装包 ID | PRODUCT_BUNDLE_ORGANIZATION | macOS Bundle ID |
| 设置路径 | main.cpp 中的 QSettings | 配置存储位置 |

---

## 附录 A 最小插件系统文件清单

### A.1 ExtensionSystem 库（必须）

```
src/libs/extensionsystem/
├── extensionsystem_global.h           # 导出宏
├── pluginmanager.h                    # PluginManager 声明
├── pluginmanager.cpp                  # PluginManager 实现（1531 行）
├── pluginmanager_p.h                  # Private 实现
├── pluginspec.h                       # PluginSpec 声明
├── pluginspec.cpp                     # PluginSpec 实现
├── pluginspec_p.h                     # Private 实现
├── iplugin.h                          # IPlugin 接口
├── iplugin.cpp                        # IPlugin 实现
├── iplugin_p.h                        # Private 实现
├── optionsparser.h                    # 命令行解析
├── optionsparser.cpp
├── invoker.h                          # 跨插件调用
├── invoker.cpp
├── pluginview.h                       # 插件列表 UI（可选）
├── pluginview.cpp
├── plugindetailsview.h               # 插件详情 UI（可选）
├── plugindetailsview.cpp
├── pluginerrorview.h                  # 错误显示 UI（可选）
├── pluginerrorview.cpp
├── pluginerroroverview.h             # 错误概览 UI（可选）
├── pluginerroroverview.cpp
├── extensionsystem.pro                # 项目文件
└── extensionsystem_dependencies.pri   # 依赖声明
```

### A.2 Aggregation 库（必须）

```
src/libs/aggregation/
├── aggregate.h                        # 核心声明
├── aggregate.cpp                      # 核心实现
├── aggregation_global.h               # 导出宏
├── aggregation.pro                    # 项目文件
└── aggregation_dependencies.pri       # 依赖声明
```

### A.3 Utils 库（必须，可精简）

```
src/libs/utils/
├── algorithm.h                        # 容器算法
├── fileutils.h/cpp                    # 文件操作
├── hostosinfo.h                       # 系统信息
├── qtcassert.h/cpp                    # 断言
├── savefile.h/cpp                     # 安全写入
├── stringutils.h/cpp                  # 字符串工具
├── id.h/cpp                           # Utils::Id
├── mimetypes/                         # MIME 类型子系统
├── theme/                             # 主题子系统
└── ... (按需保留)
```

---

## 附录 B 插件依赖关系图

```
                    ExtensionSystem (lib)
                    ├── Aggregation (lib)
                    └── Utils (lib)
                          │
                    CorePlugin (plugin)
                    ├── ExtensionSystem
                    ├── Aggregation
                    └── Utils
                          │
          ┌───────────────┼───────────────┐
          │               │               │
     TextEditor      ProjectExplorer    Help
     ├── Core        ├── Core           ├── Core
     │               ├── TextEditor     │
     │               │                  │
   ┌─┴─────┐      ┌─┴──────────┐     ┌─┴──┐
   │       │      │            │     │    │
 CppEditor QmlJS  QmakeProj  Debugger  Designer
 ├── Core  Mgr    ├── Core    ├── Core
 ├── Text  ├──Core├── ProjExp ├── ProjExp
 ├── Cpp   ├──Text├── Text    ├── Text
 Tools     │      │           │
           │      │           │
         ...    ...         ...
```

---

## 附录 C 关键代码行索引

| 概念 | 文件 | 关键行 |
|------|------|--------|
| 插件加载入口 | pluginmanager.cpp | loadPlugins() |
| 拓扑排序 | pluginmanager.cpp | loadQueue() 递归 |
| 对象池 addObject | pluginmanager.cpp | addObject() |
| 元数据解析 | pluginspec.cpp | readMetaData() |
| 依赖解析 | pluginspec.cpp | resolveDependencies() |
| 版本匹配 | pluginspec.cpp | provides() |
| IPlugin 接口 | iplugin.h | initialize/extensionsInitialized/aboutToShutdown |
| Aggregate 查询 | aggregate.h | query<T>() |
| 聚合体映射表 | aggregate.cpp | aggregateMap() |
| 品牌配置 | qtcreator_ide_branding.pri | IDE_DISPLAY_NAME 等 |
| 插件模板 | qtcreatorplugin.pri | DESTDIR/JSON 生成 |
| 库模板 | qtcreatorlibrary.pri | DESTDIR/RPATH |
| 依赖解析算法 | qtcreator.pri | QTC_PLUGIN_DEPENDS 循环 |
| MainWindow 初始化 | mainwindow.cpp | init()/extensionsInitialized() |
| ICore 单例 | icore.h | 静态方法集合 |
| ActionManager | actionmanager.h | registerAction() |
| EditorManager | editormanager.h | openEditor() |
| ModeManager | modemanager.h | activateMode() |

---

## 附录 D 插件开发速查手册

### D.1 插件骨架

```cpp
// myplugin.h
#pragma once
#include <extensionsystem/iplugin.h>

namespace MyNamespace {
namespace Internal {

class MyPlugin : public ExtensionSystem::IPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QtCreatorPlugin" FILE "MyPlugin.json")

public:
    bool initialize(const QStringList &arguments, QString *errorMessage) override;
    void extensionsInitialized() override;
    ShutdownFlag aboutToShutdown() override;
};

} // namespace Internal
} // namespace MyNamespace
```

### D.2 注册菜单和命令

```cpp
bool MyPlugin::initialize(const QStringList &, QString *)
{
    // 创建 Action
    auto action = new QAction(tr("My Action"), this);
    connect(action, &QAction::triggered, this, &MyPlugin::doSomething);

    // 注册命令
    auto cmd = Core::ActionManager::registerAction(action, "MyPlugin.MyAction");
    cmd->setDefaultKeySequence(QKeySequence(tr("Ctrl+Shift+M")));

    // 添加到 Tools 菜单
    auto toolsMenu = Core::ActionManager::actionContainer(Core::Constants::M_TOOLS);
    toolsMenu->addAction(cmd);

    return true;
}
```

### D.3 注册服务到对象池

```cpp
// 定义接口
class IMyService : public QObject
{
    Q_OBJECT
public:
    virtual void doWork() = 0;
};

// 实现
class MyServiceImpl : public IMyService { ... };

// 注册
bool MyPlugin::initialize(...)
{
    m_service = new MyServiceImpl(this);
    ExtensionSystem::PluginManager::addObject(m_service);
    return true;
}

// 其他插件使用
auto service = ExtensionSystem::PluginManager::getObject<IMyService>();
if (service)
    service->doWork();
```

### D.4 创建导航面板

```cpp
class MyNavigationFactory : public Core::INavigationWidgetFactory
{
public:
    MyNavigationFactory()
    {
        setDisplayName(tr("My Panel"));
        setPriority(200);
        setId("MyPlugin.Navigation");
    }

    Core::NavigationView createWidget() override
    {
        return {new MyNavigationWidget};
    }
};

// 在 initialize() 中创建即可，INavigationWidgetFactory 构造时自动注册
new MyNavigationFactory;
```

### D.5 创建输出面板

```cpp
class MyOutputPane : public Core::IOutputPane
{
    Q_OBJECT
public:
    QWidget *outputWidget(QWidget *parent) override;
    QString displayName() const override { return tr("My Output"); }
    int priorityInStatusBar() const override { return 50; }
    void clearContents() override;
    void visibilityChanged(bool visible) override;
    void setFocus() override;
    bool hasFocus() const override;
    bool canFocus() const override;
    bool canNavigate() const override { return false; }
    bool canNext() const override { return false; }
    bool canPrevious() const override { return false; }
    void goToNext() override {}
    void goToPrev() override {}
};
```

### D.6 依赖声明模板

```pro
# myplugin_dependencies.pri
QTC_PLUGIN_NAME = MyPlugin

QTC_LIB_DEPENDS += \
    extensionsystem \
    utils

QTC_PLUGIN_DEPENDS += \
    coreplugin

QTC_PLUGIN_RECOMMENDS += \
    texteditor          # 可选依赖
```

---

## 附录 E Qt Creator 常用常量 ID

### E.1 菜单 ID

| 常量 | 值 | 说明 |
|------|---|------|
| `M_FILE` | Core.Menu.File | 文件菜单 |
| `M_EDIT` | Core.Menu.Edit | 编辑菜单 |
| `M_VIEW` | Core.Menu.View | 视图菜单 |
| `M_TOOLS` | Core.Menu.Tools | 工具菜单 |
| `M_WINDOW` | Core.Menu.Window | 窗口菜单 |
| `M_HELP` | Core.Menu.Help | 帮助菜单 |

### E.2 菜单组 ID

| 常量 | 说明 |
|------|------|
| `G_FILE_NEW` | 文件→新建组 |
| `G_FILE_OPEN` | 文件→打开组 |
| `G_FILE_SAVE` | 文件→保存组 |
| `G_FILE_CLOSE` | 文件→关闭组 |
| `G_EDIT_UNDOREDO` | 编辑→撤销重做组 |
| `G_EDIT_COPYPASTE` | 编辑→复制粘贴组 |
| `G_EDIT_FIND` | 编辑→查找组 |

### E.3 上下文 ID

| 常量 | 说明 |
|------|------|
| `C_GLOBAL` | 全局上下文（始终有效） |
| `C_WELCOME_MODE` | 欢迎模式 |
| `C_EDIT_MODE` | 编辑模式 |
| `C_DESIGN_MODE` | 设计模式 |
| `C_NAVIGATION_PANE` | 导航面板 |
| `C_PROBLEM_PANE` | 问题面板 |

### E.4 模式优先级

| 常量 | 值 | 说明 |
|------|---|------|
| `P_MODE_WELCOME` | 100 | 欢迎模式（最左） |
| `P_MODE_EDIT` | 90 | 编辑模式 |
| `P_MODE_DESIGN` | 89 | 设计模式 |

---

## 附录 F 术语表

| 术语 | 英文 | 解释 |
|------|------|------|
| 插件 | Plugin | 实现 IPlugin 接口的动态库，是功能的基本单元 |
| 插件规格 | PluginSpec | 描述插件元数据（名称、版本、依赖等）的对象 |
| 对象池 | Object Pool | PluginManager 维护的全局 QObject 列表 |
| 扩展点 | Extension Point | 基于对象池的接口注册/查询模式 |
| 聚合体 | Aggregate | 将多个 QObject 组合成逻辑整体的容器 |
| 上下文 | Context | 决定命令激活状态的标识符集合 |
| 命令 | Command | ActionManager 中注册的操作抽象 |
| 模式 | Mode | IDE 的主要工作视图（编辑、设计、调试等） |
| 工具包 | Kit | 编译器+调试器+目标平台的组合 |
| 构建目标 | Target | 项目+Kit 的绑定 |
| 构建配置 | BuildConfiguration | Debug/Release/Custom 等构建参数集 |
| 运行配置 | RunConfiguration | 可执行程序的启动参数 |
| RPATH | - | 动态库搜索路径（嵌入二进制文件中） |
| IID | Interface ID | Qt 插件系统的接口标识字符串 |
| 拓扑排序 | Topological Sort | 依赖图的线性化，保证被依赖方先处理 |

