# Qt Creator 6.0.2 代码框架报告

## 一、顶层目录职责

| 目录 | 职责 |
|---|---|
| `src/app/` | 入口点，`main.cpp` → 初始化 QApplication → 加载 ExtensionSystem → 启动 Core 插件 |
| `src/libs/` | 21 个共享库（比 4.13.3 多 `qlitehtml`），为所有插件提供底层能力 |
| `src/plugins/` | 72 个功能插件（新增 `docker`、`conan`；移除 `clangpchmanager`、`clangrefactoring`） |
| `src/tools/` | 27 个独立工具（新增 `processlauncher`；移除 `clangpchmanagerbackend`、`clangrefactoringbackend`） |
| `src/shared/` | 跨模块复用的非独立库代码（proparser、qtsingleapplication、registryaccess 等，与 4.13.3 相同） |
| `share/` | 运行时资源：主题、代码片段、MIME 定义、模板 |
| `tests/` | 自动化测试、基准测试、手动测试 |
| `scripts/` | 构建打包部署脚本 |
| `coin/` | **新增**——Qt CI 系统（Coin）配置：`dependencies.yaml`、`module_config.yaml`、`product_dependencies.yaml` |
| `dist/` | 发行版变更日志 |

## 二、构建系统

三套构建描述仍然共存，但重心已明显向 CMake 倾斜：
- **CMake**：`CMakeLists.txt`，6.x 系列的主力构建系统
- **qmake**：`.pro` / `.pri` 文件，仍保留但逐步降级
- **Qbs**：`.qbs` 文件，仍保留

新增 `qtcreator_testvars.pri` 用于测试变量配置。

版本号定义在 `src/app/app_version.h.in`（qmake）和 `src/app/app_version.h.cmakein`（CMake），构建时注入。

## 三、启动流程

`src/app/main.cpp` 执行路径与 4.13.3 基本一致，关键变化：

1. 新增 **Crashpad** 崩溃报告支持（`#ifdef ENABLE_CRASHPAD`，引入 `crashpad_client.h`）
2. 引入 `utils/singleton.h` —— 单例基础设施
3. 引入 `utils/qtcsettings.h` —— 替代直接使用 `QSettings`
4. 命令行帮助文本合并了 `-temporarycleansettings` 和 `-tcs` 的描述
5. 插件版本兼容逻辑更精细：X.Y.Z 可加载 X.Y.(Z-n) 到兼容版本的插件

核心流程不变：`PluginManager` → 扫描插件 → 拓扑排序 → `initialize()` → `extensionsInitialized()` → `delayedInitialize()`。

## 四、核心库层（src/libs/）

### 与 4.13.3 相同的库

| 库 | 功能 |
|---|---|
| **extensionsystem** | 插件框架核心，接口与 4.13.3 完全一致（`PluginManager` / `IPlugin` / `PluginSpec`） |
| **aggregation** | 对象聚合模式 |
| **cplusplus** | C++ 自研前端 |
| **qmljs** | QML/JS 解析器 |
| **languageserverprotocol** | LSP 协议实现 |
| **clangsupport** | Clang 前后端通信消息 |
| **ssh** | SSH/SFTP 客户端 |
| **sqlite** | SQLite 封装 |
| **glsl** | GLSL 解析器 |
| **languageutils** | 语言公共抽象 |
| **qmldebug** | QML 调试协议 |
| **qmleditorwidgets** | QML 编辑器控件 |
| **tracing** | 性能追踪数据模型 |
| **modelinglib** | UML/SCXML 建模引擎 |
| **advanceddockingsystem** | 高级停靠窗口系统 |

### 新增/变化的库

| 库 | 说明 |
|---|---|
| **qlitehtml** | **新增**——`litehtml` HTML 渲染引擎的 Qt 封装，用于帮助系统内嵌 HTML 渲染 |

### utils 库的重要变化

6.0.2 的 `utils` 库新增了大量文件，体现了架构演进：

| 新增文件 | 功能 |
|---|---|
| `aspects.h/cpp` | 统一的配置 Aspect 框架（替代散布在各插件中的 `projectconfigurationaspects`） |
| `filepath.h/cpp` | 独立的 `FilePath` 类型（从 `fileutils` 中拆出，支持远程路径抽象） |
| `commandline.h/cpp` | 命令行参数构建/解析 |
| `layoutbuilder.h/cpp` | 声明式 UI 布局构建器 |
| `launcherinterface.h/cpp` | 进程启动器客户端接口 |
| `launcherpackets.h/cpp` | 启动器通信数据包 |
| `launchersocket.h/cpp` | 启动器 Socket 通信 |
| `multitextcursor.h/cpp` | 多光标编辑支持 |
| `singleton.h/cpp` | 单例模板基础设施 |
| `qtcsettings.h/cpp` | 增强的 `QSettings` 封装 |
| `processreaper.h/cpp` | 进程回收器（优雅终止子进程） |
| `processutils.h/cpp` | 进程工具函数 |
| `futuresynchronizer.h/cpp` | Future 同步器 |
| `threadutils.h/cpp` | 线程工具 |
| `variablechooser.h/cpp` | 变量选择器（从 coreplugin 下沉到 utils） |
| `indexedcontainerproxyconstiterator.h` | 索引容器代理迭代器 |
| `set_algorithm.h` | 集合算法 |
| `linecolumn.cpp` | LineColumn 从 header-only 变为 cpp 实现 |
| `link.cpp` | Link 从 header-only 变为 cpp 实现 |

已移除的文件：`savedaction.h/cpp`（被 `aspects` 替代）。

### 第三方库（src/libs/3rdparty/）

在 4.13.3 基础上新增 **minitrace**（轻量性能追踪库）。

## 五、插件体系（src/plugins/）

### 5.1 核心层插件

**coreplugin** 结构与 4.13.3 基本一致。新增 `core.qrc.cmakein`（CMake 资源文件模板）。移除了 `id.h/cpp`（已合并到 `utils` 库）。

### 5.2 编辑器插件

与 4.13.3 相同：texteditor、qmljseditor、qmljstools、glsleditor、diffeditor、bineditor、imageviewer。

关键合并：**cppeditor** 吸收了原来 **cpptools** 的功能，`cpptools` 插件不再独立存在。

### 5.3 项目管理插件

与 4.13.3 相同的插件列表。`projectexplorer` 新增了：
- `buildsystem.md`——构建系统设计文档
- `buildpropertiessettings.cpp`（从 header-only 变为需要 cpp）
- `projectexplorerconstants.cpp`（常量从 header-only 变为 cpp）
- `filesinallprojectsfind.h/cpp`——跨项目文件搜索
- `projectnodeshelper.h`——项目节点辅助
- `testdata/`——内置测试数据目录

### 5.4 调试与分析插件

调试器结构与 4.13.3 完全一致（GDB/LLDB/CDB/PDB/QML/UVSC 多后端）。

分析插件不变：valgrind、perfprofiler、qmlprofiler、clangtools、cppcheck、ctfvisualizer。

### 5.5 Clang 集成插件

**重大精简**：
- ✅ 保留：**clangcodemodel**、**clangformat**、**clangtools**
- ❌ 移除：**clangpchmanager**、**clangrefactoring**（对应的 backend 工具也一并移除）

Clang 集成从"多进程分离后端"回归到更紧凑的架构。

### 5.6 版本控制插件

与 4.13.3 相同：git、bazaar、clearcase、cvs、mercurial、perforce、subversion，基于 `vcsbase` 公共层。

### 5.7 Qt/QML 特化插件

与 4.13.3 相同：qtsupport、qmldesigner、qmlpreview、qmlprojectmanager、designer。

### 5.8 平台/设备插件

在 4.13.3 基础上新增：
| 新增插件 | 功能 |
|---|---|
| **docker** | Docker 容器设备支持——`DockerDevice` 实现远程开发容器化，含构建步骤、设备检测、设置页面 |
| **conan** | Conan 包管理器集成——`ConanInstallStep` 构建步骤、设置页面 |

其余不变：android、ios、baremetal、boot2qt、qnx、remotelinux、webassembly、winrt、mcusupport。

### 5.9 其他工具插件

与 4.13.3 基本相同。

## 六、工具后端（src/tools/）

### 与 4.13.3 相同的工具

clangbackend、sdktool、qml2puppet、perfparser、qtcreatorcrashhandler、buildoutputparser、iostool 等。

### 新增的工具

| 工具 | 用途 |
|---|---|
| **processlauncher** | **新增**——独立进程启动器守护进程。通过 Socket 与 IDE 通信，集中管理子进程的创建和生命周期，避免每次 fork 的开销。对应 `utils` 库中的 `launcherinterface` / `launchersocket` / `launcherpackets` |

### 移除的工具

| 工具 | 原因 |
|---|---|
| **clangpchmanagerbackend** | 随 clangpchmanager 插件一起移除 |
| **clangrefactoringbackend** | 随 clangrefactoring 插件一起移除 |

## 七、插件间通信机制

与 4.13.3 完全一致：
1. **对象池**：`PluginManager::addObject()` / `getObject<T>()`
2. **信号槽**：Qt 标准
3. **Aggregation**：多 QObject 聚合
4. **接口（纯虚类）**：`IEditor`、`IDocument`、`IOutputPane` 等

## 八、关键设计模式

与 4.13.3 相同，新增一条：

| 模式 | 体现 |
|---|---|
| 插件架构 | `IPlugin` + `PluginSpec` + `PluginManager` 微内核 |
| 模式切换 | `IMode` + `ModeManager` |
| 文档-编辑器 | `IDocument` + `IEditor` + `EditorManager` |
| Kit 抽象 | `Kit` = 设备 + 工具链 + Qt 版本 + 调试器配置聚合 |
| 构建管线 | `Project` → `Target` → `BuildConfiguration` → `BuildStepList` → `BuildStep` |
| 运行管线 | `RunConfiguration` → `RunControl` → `RunWorker` |
| PImpl | `_p.h` 私有实现 |
| **Aspect 模式** | **新增**——`utils/aspects.h` 提供声明式配置项框架，统一了原来分散在各插件中的 `savedaction` 和 `projectconfigurationaspects` |
| **进程委托** | **新增**——`processlauncher` 守护进程 + `launcherinterface` 客户端，将子进程管理从 IDE 主进程分离 |

## 九、相对 4.13.3 的架构演进总结

| 维度 | 变化 |
|---|---|
| 构建系统 | CMake 地位上升，新增 Coin CI 集成 |
| 崩溃报告 | 新增 Crashpad 支持（除原有 Qt Breakpad） |
| 进程管理 | 新增 `processlauncher` 守护进程架构 |
| Clang 集成 | 精简——砍掉 pchmanager 和 refactoring 两套独立后端 |
| C++ 代码模型 | `cpptools` 合并入 `cppeditor` |
| 远程开发 | 新增 `docker` 插件，`FilePath` 开始支持远程路径抽象 |
| 包管理 | 新增 `conan` 插件 |
| HTML 渲染 | 新增 `qlitehtml` 库 |
| 配置框架 | `aspects` 统一替代 `savedaction` |
| UI 构建 | 新增 `layoutbuilder` 声明式布局 |
| 多光标 | `utils` 层新增 `multitextcursor` |
| 代码规模 | libs 21 个（+1），plugins 72 个（净增 ~0，有增有减），tools 27 个（净减 1） |
