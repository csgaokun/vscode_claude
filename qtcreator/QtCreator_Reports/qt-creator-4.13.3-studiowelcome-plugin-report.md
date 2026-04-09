# Qt Creator 4.13.3 StudioWelcome 插件分析报告

## 1. 结论

结论先行：

- 对当前这个以 Qt Creator 4.13.3 为主体的代码库来说，StudioWelcome 可以裁剪。
- 如果目标是普通 Qt Creator 发行版，而不是 Qt Design Studio 品牌化发行版，那么裁剪风险低。
- 最推荐的裁剪方式是“构建级裁剪”：把 `src/plugins/plugins.pro` 里的 `studiowelcome` 从 `SUBDIRS` 中移除，不再编译和打包该插件。
- 不建议只删除源码目录而不改构建入口，因为真正的构建入口仍然在 `src/plugins/plugins.pro`。
- 如果后续目标是保留 Design Studio 风格欢迎页、启动 splash、Design Studio 示例/教程入口和对应帮助文档注册，则不应裁剪。

简化判断：

- 普通 Qt Creator：可以裁剪。
- Qt Design Studio 定制版：不建议直接裁剪，除非你明确不再需要 Design Studio 的欢迎页体验。

## 2. 插件定位

StudioWelcome 不是工程管理、构建、调试、代码模型之类的核心能力插件，而是一个“Qt Design Studio 风格欢迎页插件”。

直接证据：

- `src/plugins/studiowelcome/StudioWelcome.json.in` 中写明：
  - `"DisabledByDefault" : true`
  - `"Category" : "Qt Quick"`
  - `"Description" : "Qt Design Studio Welcome Page."`

这说明它的定位是：

- 面向 Qt Quick / Qt Design Studio 体验层
- 默认不启用
- 主要负责启动页和欢迎页 UI，而不是 IDE 主链功能

## 3. 源码与构建位置

### 3.1 目录位置

插件源码目录：

- `src/plugins/studiowelcome/`

主要文件：

- `studiowelcomeplugin.cpp`
- `studiowelcomeplugin.h`
- `StudioWelcome.json.in`
- `studiowelcome.pro`
- `studiowelcome_dependencies.pri`
- `studiowelcome.qrc`
- `qml/welcomepage/*`
- `qml/splashscreen/*`

### 3.2 构建入口

该插件当前会参与整体插件构建，证据是：

- `src/plugins/plugins.pro` 中包含 `studiowelcome`

也就是说，虽然它默认禁用，但当前工程仍然会编译并打包它。

### 3.3 构建依赖

`src/plugins/studiowelcome/studiowelcome_dependencies.pri` 中声明：

- `QTC_LIB_DEPENDS += extensionsystem utils`
- `QTC_PLUGIN_DEPENDS += coreplugin projectexplorer qtsupport`

`src/plugins/studiowelcome/studiowelcome.pro` 中声明：

- `QT += quick quickwidgets`

这说明它依赖：

- Qt Quick / QQuickWidget
- Core 插件框架
- ProjectExplorer
- QtSupport
- Utils / ExtensionSystem

但这些依赖是“它依赖别人”，不是“别人依赖它”。

## 4. 功能行为分析

### 4.1 提供一个 Studio 风格 Welcome 模式

在 `studiowelcomeplugin.cpp` 中，`WelcomeMode::WelcomeMode()` 做了这些事：

- `setDisplayName(tr("Studio"))`
- `setPriority(Core::Constants::P_MODE_WELCOME)`
- `setId(Core::Constants::MODE_WELCOME)`
- `setContext(Core::Context(Core::Constants::C_WELCOME_MODE))`
- 用 `QQuickWidget` 加载 `qml/welcomepage/main.qml`

这意味着它不是新增一个独立模式，而是占用了标准 Welcome 模式的同一个 ID：

- `MODE_WELCOME`
- `P_MODE_WELCOME`
- `C_WELCOME_MODE`

因此它本质上是在“替换默认欢迎页”，而不是增加一个新的 IDE 主功能模块。

### 4.2 启动后直接切到 Welcome 模式

`extensionsInitialized()` 中会执行：

- `Core::ModeManager::activateMode(m_welcomeMode->id())`

也就是说，只要插件被启用，它会把用户带到这个 Studio Welcome 页。

### 4.3 提供一个启动 splash screen

`extensionsInitialized()` 中还会：

- 在 `coreOpened` 后创建 `QQuickWidget`
- 设置 `Qt::SplashScreen`
- 加载 `qml/splashscreen/main.qml`
- 连接 `closeClicked()`
- 15 秒后自动关闭

并且它支持“不再显示”开关：

- 使用设置键 `StudioSplashScreen`

因此它不仅仅是欢迎页，还负责一个 Design Studio 风格启动闪屏。

### 4.4 提供 Recent Projects / Examples / Tutorials 三个标签页

`qml/welcomepage/main.qml` 显示的主界面包含：

- Recent Projects
- Examples
- Tutorials

同时还有：

- Create New
- Open Project
- Help
- Community
- Blog

这是一个明显的“产品入口页”，不是开发能力页。

### 4.5 Recent Projects / New / Open 实际是转调 ProjectExplorer

`ProjectModel` 暴露给 QML 的调用包括：

- `createProject()`
- `openProject()`
- `openProjectAt(int row)`
- `showHelp()`
- `openExample(...)`

这些操作实际调用的是：

- `ProjectExplorer::ProjectExplorerPlugin::openNewProjectDialog()`
- `ProjectExplorer::ProjectExplorerPlugin::openOpenProjectDialog()`
- `ProjectExplorer::ProjectExplorerPlugin::openProjectWelcomePage(...)`
- `Core::EditorManager::openEditor(...)`

换句话说：

- StudioWelcome 自己不实现项目系统
- 它只是给已有能力包了一层 Design Studio 风格入口 UI

### 4.6 Examples / Tutorials 内容高度偏向 Design Studio

QML 模型里写死了大量 Qt Design Studio 相关示例和教程条目，例如：

- Cluster Tutorial
- Coffee Machine
- E-Bike Design
- Learn to use Qt Design Studio (Part 1~5)
- Qt Design Studio QuickTip
- Sketch Bridge Tutorial

这进一步说明该插件服务的是 Design Studio 品牌化入口，而不是通用 Qt Creator IDE 主功能。

## 5. 额外副作用

这部分对是否裁剪很重要。

### 5.1 启用后会全局改应用字体

在 `initialize()` 中，它会：

- `QFontDatabase::addApplicationFont(":/studiofonts/TitilliumWeb-Regular.ttf")`
- `QApplication::setFont(systemFont)`

这不是局部欢迎页字体，而是全局应用字体修改。

影响：

- 如果启用 StudioWelcome，整个应用的视觉风格都会被它改动。
- 对普通 Qt Creator 发行版来说，这属于品牌/UI 定制，而不是功能需求。

### 5.2 启用后会注册 Design Studio 相关帮助文档

在 `WelcomeMode::WelcomeMode()` 中，它会调用：

- `Core::HelpManager::registerDocumentation(...)`

注册的文档包括：

- `qtdesignstudio.qch`
- `qtquick.qch`
- `qtquickcontrols.qch`

我在 `src/` 范围内检索到这些文档名时，只在 StudioWelcome 中发现引用。

影响：

- 如果你的发行版依赖这个插件来注册这些帮助文档，裁剪后这一步会消失。
- 对普通 Qt Creator 来说，这不是核心必需路径。

### 5.3 存在额外运行时 QML 依赖

源码里有显式警告：

- `The StudioWelcomePlugin has a runtime depdendency on qt/qtquicktimeline.`

这说明如果相关 QML/模块不完整，插件本身还会带来额外运行时装配风险。

对“精简 IDE”来说，这反而是支持裁剪的证据。

## 6. 反向依赖分析

这是裁剪判断的核心部分。

我在 `src/plugins/**` 内检索 `StudioWelcome`，结果显示：

- 命中主要集中在 `src/plugins/studiowelcome/` 自身
- 以及 `src/plugins/plugins.pro` 中的构建入口

未发现其他插件在源码层面对 StudioWelcome 的反向依赖。

这意味着：

- 没有其他插件把它当成前置能力插件
- 没有其他插件通过插件依赖链要求它必须存在
- 它更像一个可选 UI/品牌层插件

## 7. 与标准 Welcome 插件的关系

仓库里本来就有标准欢迎页插件：

- `src/plugins/welcome/`

标准 Welcome 插件同样使用：

- `MODE_WELCOME`
- `P_MODE_WELCOME`
- `C_WELCOME_MODE`

StudioWelcome 也是这组常量。

这说明二者关系不是互补，而是替换关系：

- `welcome` 是普通 Qt Creator 欢迎页
- `studiowelcome` 是 Qt Design Studio 风格欢迎页

因此裁剪 StudioWelcome 后：

- 不会导致 Welcome 模式这一概念消失
- 标准 `welcome` 插件仍然可以承担欢迎页功能

## 8. 规模与负担

基于当前仓库统计：

- `src/plugins/studiowelcome/` 下文件总数：93
- 源码与资源总大小：1,218,067 bytes
- 已构建插件 `StudioWelcome4.dll` 大小：1,345,536 bytes

另外，该插件自带大量：

- QML 文件
- PNG 图片
- splashscreen 资源
- 教程与示例缩略图

所以它不是一个很小的“胶水插件”，而是带着一整套 UI 资产的品牌入口模块。

如果目标是：

- 缩小构建范围
- 减少发布包体积
- 降低 Qt Quick / QML 运行时依赖面
- 降低非核心 UI 路径风险

那么它是一个合理的裁剪对象。

## 9. 是否可以裁剪

### 9.1 可以裁剪的前提

在以下前提下，可以裁剪：

- 你要的是普通 Qt Creator，而不是 Qt Design Studio 风格发行版
- 你不依赖它提供的 Studio 品牌欢迎页和 splash
- 你不需要它在启动时注册 `qtdesignstudio.qch` 等帮助文档
- 你保留普通 `welcome` 插件

### 9.2 不建议直接裁剪的场景

以下场景不建议直接裁剪：

- 你的产品目标就是 Qt Design Studio 风格体验
- 你需要 Recent Projects / Examples / Tutorials 这套 Design Studio 入口页
- 你需要它的启动 splash 品牌展示
- 你的帮助文档注册链依赖这个插件

### 9.3 当前代码库下的判定

结合当前仓库实际情况，判定如下：

- StudioWelcome 可以裁剪。
- 裁剪后对 Qt Creator 打开工程、编辑、构建、调试、项目管理等主能力预计无直接影响。
- 裁剪后损失的主要是 Design Studio 风格欢迎页、splash、教程/示例入口、全局字体定制和特定帮助文档注册。

## 10. 推荐裁剪方案

### 方案 A：仅运行时不启用

做法：

- 保留编译与打包
- 依赖 `DisabledByDefault`，默认不加载

优点：

- 风险最小
- 不改源码结构

缺点：

- 仍然占用构建时间
- 仍然产出 DLL
- 仍然带来包体积与维护负担

适合：

- 只想避免它干扰运行，但不急着做真正精简

### 方案 B：构建级裁剪

做法：

- 从 `src/plugins/plugins.pro` 的 `SUBDIRS` 里移除 `studiowelcome`

优点：

- 不再编译该插件
- 不再产出 `StudioWelcome4.dll`
- 不再把这套 QML/图片/字体资产打进插件
- 风险低，且符合当前依赖分析结果

缺点：

- 会失去 Design Studio 风格欢迎页及其附加 UI 资产

这是最推荐方案。

### 方案 C：源码级彻底删除

做法：

- 删除 `src/plugins/studiowelcome/`
- 同时修改 `src/plugins/plugins.pro`

优点：

- 源码树最干净

缺点：

- 侵入性更高
- 后续如果要恢复，需要回退整目录

除非你确认以后都不会再启用 Design Studio 风格欢迎页，否则不必一步做到这么彻底。

## 11. 最终建议

最终建议如下：

- 对当前 Qt Creator 4.13.3 工程，StudioWelcome 属于可裁剪插件。
- 推荐采用“方案 B：构建级裁剪”。
- 即：保留普通 `welcome` 插件，移除 `src/plugins/plugins.pro` 中的 `studiowelcome` 子项目。

这样做能达到以下效果：

- 不影响普通 Qt Creator 的主功能链
- 不影响标准 Welcome 模式的存在
- 降低构建和发布负担
- 避免额外的 Qt Quick / splash / Design Studio 品牌化路径进入最终产品

## 12. 如果下一步要实施裁剪

最小改动步骤建议：

1. 修改 `src/plugins/plugins.pro`，移除 `studiowelcome`。
2. 重新 qmake 生成 `src/plugins` 子树 Makefile。
3. 全量或至少插件子树重编译。
4. 确认最终安装目录不再生成 `StudioWelcome4.dll`。
5. 启动回归，确认普通 `welcome` 插件仍能正常显示欢迎页。

如果要继续，我建议直接按“方案 B”落地裁剪，这个方案收益和风险比最好。