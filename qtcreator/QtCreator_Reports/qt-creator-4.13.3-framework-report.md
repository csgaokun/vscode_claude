# Qt Creator 4.13.3 代码框架报告

## 一、顶层目录职责

| 目录 | 职责 |
|---|---|
| `src/app/` | 入口点，`main.cpp` → 初始化 QApplication → 加载 ExtensionSystem → 查找并启动 Core 插件 |
| `src/libs/` | 20 个共享库，为所有插件提供底层能力 |
| `src/plugins/` | 70+ 个功能插件，每个插件一个目录 |
| `src/tools/` | 28 个独立工具/后端进程（clang 后端、崩溃处理、SDK 工具等） |
| `src/shared/` | 跨模块复用的非独立库代码（proparser、qtsingleapplication、registryaccess 等） |
| `share/` | 运行时资源：主题、代码片段、MIME 定义、模板 |
| `tests/` | 自动化测试、基准测试、手动测试 |
| `scripts/` | 构建打包部署脚本（Python/Perl/Shell） |
| `dist/` | 发行版变更日志 |

## 二、构建系统

三套并行构建描述共存：
- **qmake**：`.pro` / `.pri` 文件，传统主力
- **CMake**：`CMakeLists.txt`，逐步迁移中
- **Qbs**：`.qbs` 文件，Qt 自研构建工具

版本号定义在 `src/app/app_version.h.in`，构建时注入。

## 三、启动流程

`src/app/main.cpp` 的执行路径：

1. 解析命令行参数（`-settingspath`, `-pluginpath`, `-client` 等）
2. 创建 `QtSingleApplication` 实例，保证单实例运行
3. 实例化 `PluginManager`，设置插件搜索路径
4. 扫描插件目录，读取每个 `.json` 元数据（`PluginSpec`）
5. 解析插件依赖关系，生成加载队列
6. 按拓扑顺序依次调用 `IPlugin::initialize()` → `extensionsInitialized()` → `delayedInitialize()`
7. 强制要求 **Core** 插件（`corePluginNameC = "Core"`）存在，否则直接退出

## 四、核心库层（src/libs/）

| 库 | 功能 |
|---|---|
| **extensionsystem** | 插件框架核心。`PluginManager` 管理插件生命周期；`IPlugin` 是所有插件的基类；`PluginSpec` 描述插件元数据与依赖 |
| **aggregation** | 对象聚合模式——将多个 QObject 组合为一个逻辑实体，支持跨组件 `qobject_cast` |
| **utils** | 约 200 个文件的工具库：文件操作、进程管理、环境变量、主题/样式、树模型、向导框架、异步 MapReduce、SmallString 等 |
| **cplusplus** | C++ 词法分析器、解析器、AST、语义模型——独立于 Clang 的自研前端 |
| **qmljs** | QML/JS 的词法分析器、解析器、AST、类型系统 |
| **languageserverprotocol** | LSP 客户端协议实现（JSON-RPC 消息、Request/Response/Notification 类型绑定） |
| **clangsupport** | Clang 前后端进程间通信的消息定义 |
| **ssh** | SSH/SFTP 客户端库 |
| **sqlite** | 轻量 SQLite 封装 |
| **glsl** | GLSL 着色器语言解析器 |
| **languageutils** | 语言公共抽象（组件信息、假的工具提示等） |
| **qmldebug** | QML 调试协议客户端 |
| **qmleditorwidgets** | QML 编辑器专用控件（颜色选择器等） |
| **tracing** | 性能追踪时间线的数据模型和渲染 |
| **modelinglib** | UML/SCXML 建模引擎 |
| **advanceddockingsystem** | 高级停靠窗口系统（来自第三方 ADS 库） |

### 第三方库（src/libs/3rdparty/）

cplusplus 词法规则、JSON 解析、`std::optional`/`std::variant`/`std::span` 的 backport、KSyntaxHighlighting、yaml-cpp、xdg-utils。

## 五、插件体系（src/plugins/）

### 5.1 核心层插件

| 插件 | 角色 |
|---|---|
| **coreplugin** | IDE 主窗口（`MainWindow`）、模式管理（`ModeManager`）、动作管理（`ActionManager`）、编辑器管理（`EditorManager`）、文档管理、导航栏、输出面板、进度管理、Locator 搜索框、设置体系 |

`ICore` 是全局单例入口，所有插件通过它访问主窗口、设置、上下文等。

### 5.2 编辑器插件

| 插件 | 功能 |
|---|---|
| **texteditor** | 文本编辑器引擎：语法高亮、代码补全（`codeassist/`）、代码折叠、书签、片段、QuickFix、重构覆盖层、搜索替换 |
| **cppeditor** / **cpptools** | C++ 编辑支持与代码模型 |
| **qmljseditor** / **qmljstools** | QML/JS 编辑支持 |
| **glsleditor** | GLSL 编辑器 |
| **diffeditor** | 差异对比编辑器 |
| **bineditor** | 二进制/十六进制编辑器 |
| **imageviewer** | 图片查看器 |

### 5.3 项目管理插件

| 插件 | 功能 |
|---|---|
| **projectexplorer** | 项目管理核心：Project/Target/BuildConfiguration/RunConfiguration 四层抽象、Kit 系统、工具链管理、构建管理器、会话管理、任务系统 |
| **qmakeprojectmanager** | .pro 项目支持 |
| **cmakeprojectmanager** | CMake 项目支持 |
| **qbsprojectmanager** | Qbs 项目支持 |
| **mesonprojectmanager** | Meson 项目支持 |
| **genericprojectmanager** | 通用项目（无构建系统） |
| **compilationdatabaseprojectmanager** | compile_commands.json 项目 |
| **autotoolsprojectmanager** | Autotools 项目 |

### 5.4 调试与分析插件

| 插件 | 功能 |
|---|---|
| **debugger** | 多后端调试器：GDB（`gdb/`）、LLDB（`lldb/`）、CDB（`cdb/`）、PDB（`pdb/`）、QML（`qml/`）、UVSC（`uvsc/`）。含断点引擎、变量监视、内存查看、反汇编、线程/栈帧管理 |
| **valgrind** | Valgrind Memcheck / Callgrind 集成 |
| **perfprofiler** | Linux perf 性能分析 |
| **qmlprofiler** | QML 性能分析 |
| **clangtools** | Clang-Tidy / Clazy 静态分析 |
| **cppcheck** | Cppcheck 静态分析 |
| **ctfvisualizer** | Chrome Trace Format 可视化 |

### 5.5 Clang 集成插件

| 插件 | 功能 |
|---|---|
| **clangcodemodel** | 基于 Clang 的代码模型（补全、诊断） |
| **clangformat** | ClangFormat 代码格式化 |
| **clangpchmanager** | 预编译头管理 |
| **clangrefactoring** | 基于 Clang 的重构 |

### 5.6 版本控制插件

git、bazaar、clearcase、cvs、mercurial、perforce、subversion——全部基于 `vcsbase` 公共层。

### 5.7 Qt/QML 特化插件

| 插件 | 功能 |
|---|---|
| **qtsupport** | Qt 版本检测与 Kit 集成 |
| **qmldesigner** | QML 可视化设计器 |
| **qmlpreview** | QML 实时预览 |
| **qmlprojectmanager** | .qmlproject 项目 |
| **designer** | Qt Widgets Designer 集成 |

### 5.8 平台/设备插件

android、ios、baremetal、boot2qt、qnx、remotelinux、webassembly、winrt、mcusupport——每个对接 `projectexplorer` 的 Device/Kit/Deploy 抽象。

### 5.9 其他工具插件

autotest（测试框架集成）、beautifier（代码美化）、bookmarks、cpaster（代码粘贴）、fakevim、emacskeys、help（帮助系统）、languageclient（通用 LSP 客户端）、macros、marketplace、python、scxmleditor、serialterminal、todo、welcome、studiowelcome、incredibuild 等。

## 六、工具后端（src/tools/）

| 工具 | 用途 |
|---|---|
| `clangbackend` | Clang 代码模型的独立后端进程 |
| `clangpchmanagerbackend` | PCH 管理后端进程 |
| `clangrefactoringbackend` | Clang 重构后端进程 |
| `sdktool` | 命令行管理 Kit/Qt 版本/工具链 |
| `qml2puppet` | QML Designer 渲染傀儡进程 |
| `perfparser` | perf.data 解析器 |
| `qtcreatorcrashhandler` | 崩溃处理 |
| `buildoutputparser` | 构建输出解析 |
| `iostool` | iOS 设备通信 |

## 七、插件间通信机制

1. **对象池（Object Pool）**：`PluginManager::addObject()` / `getObject<T>()`——插件向全局池注册服务实现，其他插件按接口类型检索
2. **信号槽**：Qt 标准机制，跨插件连接
3. **Aggregation**：将多个 QObject 聚合，允许在同一个逻辑实体上做跨类型 `qobject_cast`
4. **接口（纯虚类）**：如 `IEditor`、`IDocument`、`IOutputPane`、`INavigationWidgetFactory`——插件实现接口后注入对象池

## 八、关键设计模式

| 模式 | 体现 |
|---|---|
| 插件架构 | `IPlugin` + `PluginSpec` + `PluginManager` 的微内核模式 |
| 模式切换 | `IMode`（Welcome / Edit / Design / Debug）+ `ModeManager` |
| 文档-编辑器 | `IDocument` + `IEditor` + `EditorManager`，一个文档可有多个编辑器视图 |
| Kit 抽象 | `Kit` = 设备 + 工具链 + Qt 版本 + 调试器 + ... 的配置聚合 |
| 构建管线 | `Project` → `Target` → `BuildConfiguration` → `BuildStepList` → `BuildStep` |
| 运行管线 | `RunConfiguration` → `RunControl` → `RunWorker`（可链式组合多个 Worker） |
| PImpl | 几乎所有公开类使用 `_p.h` 私有实现，保持 ABI 兼容 |

## 九、代码规模概览

- **libs**：20 个库，其中 `utils` 约 200+ 源文件
- **plugins**：70+ 个插件
- **tools**：28 个独立工具
- 总 C++ 源文件数量级：**数千个 `.cpp` / `.h`**
- 构建描述文件三套共存（qmake / CMake / Qbs）
