# Qt Creator 6.0.2 使用 Qmake 编译的 Qt 版本要求——代码审查报告

## 一、硬性最低版本：Qt 5.14.0

### 证据来源

**1. `qtcreator.pro` 第 4 行——全局入口门禁**

```qmake
!minQtVersion(5, 14, 0) {
    message("Cannot build $$IDE_DISPLAY_NAME with Qt version $${QT_VERSION}.")
    error("Use at least Qt 5.14.0.")
}
```

构建开始时直接检查，低于 5.14.0 立刻 `error()` 终止。

**2. `cmake/QtCreatorAPI.cmake` 第 6 行——CMake 侧一致**

```cmake
set(IDE_QT_VERSION_MIN "5.14.0")
```

与 qmake 侧保持一致，交叉验证了 5.14.0 是官方确定的最低支持版本。

**3. `qtcreator.pri` 第 210 行——废弃 API 下限**

```qmake
QT_DISABLE_DEPRECATED_BEFORE=0x050900
```

设为 `0x050900` = Qt 5.9.0，表示使用了 5.9 以来的所有 API，但不代表最低编译版本，仅作为废弃 API 告警抑制线。

## 二、Qt 5.x 版本区间：5.14.0 ~ 5.15.x

### 可编译区间

| Qt 版本 | 能否编译 | 说明 |
|---|---|---|
| < 5.14.0 | ❌ 不行 | `qtcreator.pro` 硬性拒绝 |
| 5.14.0 ~ 5.14.x | ✅ 能编译 | 最低支持版本，功能完整但部分特性缺失 |
| 5.15.0 ~ 5.15.x | ✅ 推荐 | 所有条件编译特性均能启用 |

### 5.15.0 条件编译差异

使用 Qt 5.14.x（< 5.15.0）编译时，以下特性缺失或降级：

| 位置 | 条件 | 影响 |
|---|---|---|
| `plugins/help/help.pro:7` | `minQtVersion(5, 15, 0)` → `DEFINES += HELP_NEW_FILTER_ENGINE` | Help 插件不启用新帮助过滤引擎 |
| `tools/qtcdebugger/main.cpp:374` | `QT_VERSION >= 5.15.0` | qtcdebugger 部分 API 走旧路径 |
| `tools/iostool/relayserver.cpp:58` | `QT_VERSION < 5.15.0` | iOS 中继服务器使用旧的兼容代码 |
| `tools/processlauncher/launchersockethandler.cpp:77` | `QT_VERSION < 5.15.0` | 进程启动器走旧代码路径 |
| `plugins/boot2qt/device-detection/qdbwatcher.cpp:66` | `QT_VERSION < 5.15.0` | Boot2Qt 设备检测走旧代码路径 |
| `plugins/fakevim/fakevimplugin.cpp:701,959` | `QT_VERSION >= 5.15.0` | FakeVim 部分功能访问不同 API |
| `plugins/projectexplorer/jsonwizard/jsonwizardfactory.cpp:250` | `QT_VERSION < 5.15.0` | JSON 向导工厂走旧代码 |

## 三、Qt 6.x 版本支持

### 支持 Qt 6，有条件

代码中存在大量 `QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)` 的双路径兼容代码，表明 6.0.2 的源码**同时支持 Qt 5.14+ 和 Qt 6.x**。

**qmake 构建兼容机制**（`qtcreator.pri` 第 234 行）：

```qmake
contains(QT, core): greaterThan(QT_MAJOR_VERSION, 5): QT += core5compat
```

使用 Qt 6 编译时自动引入 `core5compat` 模块，解决 `QTextCodec` 等在 Qt 6 中移出 QtCore 的问题。

**main.cpp** 中也显式包含了 `<QTextCodec>`（Qt 6 需要 core5compat 提供此头文件）。

### Qt 6.x 条件编译差异

| 范围 | `>= 6.0.0` 的变化 |
|---|---|
| `shared/qtcreator_pch.h` | 预编译头适配 Qt 6 |
| `shared/qtsingleapplication/qtlocalpeer.cpp` | 单实例通信适配 Qt 6 |
| `plugins/coreplugin/dialogs/shortcutsettings.cpp` | 快捷键设置适配 |
| `plugins/cppeditor/stringtable.cpp` | 字符串表内部实现差异 |
| `plugins/classview/classview*.cpp` | hash 函数适配 `qHash` 签名变化 |
| `plugins/clangtools/diagnosticconfigswidget.cpp` | 正则表达式适配 |
| `plugins/debugger/debuggerplugin.cpp` | 调试器插件适配 |
| `plugins/debugger/console/consoleview.cpp` | 控制台视图适配 |
| `plugins/qmlprofiler/inputeventsmodel.cpp` | 输入事件模型适配 |
| `plugins/help/helpmanager.cpp, localhelpmanager.cpp` | 帮助系统适配 |
| `plugins/remotelinux/tarpackagecreationstep.cpp` | tar 封包适配 |
| `plugins/remotelinux/abstractremotelinuxdeploystep.cpp` | 部署步骤适配 |

### Qt 6.2.0 高版本特性

部分代码还针对 Qt 6.2.0 做了条件编译：

| 位置 | 说明 |
|---|---|
| `plugins/ctfvisualizer/ctfvisualizertraceview.cpp` | 6.2 QuickWidget 变化 |
| `plugins/perfprofiler/perfprofilerflamegraphview.cpp` | 火焰图视图适配 |
| `plugins/perfprofiler/perfprofilerflamegraphmodel.h` | 火焰图模型适配 |
| `plugins/perfprofiler/perfprofilertraceview.cpp` | 追踪视图适配 |
| `plugins/qmlprofiler/flamegraphview.cpp` | QML 火焰图适配 |
| `plugins/help/webenginehelpviewer.cpp` | WebEngine 帮助查看器适配 |

这些仅在使用 Qt 6.2+ 时才走新路径，低于此版本走兼容路径，**不影响编译**。

## 四、Qt 模块依赖清单

以下是通过审查 `.pro` 文件提取的全部 Qt 模块依赖：

### 必需模块（无 `qtHaveModule` 保护）

| 模块 | 需要它的组件 |
|---|---|
| **core** | 全局（所有组件） |
| **concurrent** | 全局（`qtcreator.pri` 自动追加） |
| **gui** | 全局（`qtcreator.pri`：`contains(QT, gui): QT += widgets`） |
| **widgets** | 全局（自动从 gui 追加） |
| **network** | coreplugin、texteditor、debugger、ssh、qmldebug、vcsbase、android、remotelinux、qnx、baremetal、updateinfo、mcusupport、cpaster、qmlprojectmanager、qtsupport、processlauncher 等 |
| **printsupport** | coreplugin、texteditor、help |
| **qml** | coreplugin、tracing |
| **sql** | coreplugin、help |
| **xml** | qmldesigner、qnx、android、updateinfo、iostool |
| **svg** | qmldesigner |

### 可选模块（有 `qtHaveModule` 保护，缺失时对应插件不编译）

| 模块 | 对应插件 | 缺失影响 |
|---|---|---|
| **quick** + **quickwidgets** | qmlprofiler、perfprofiler、ctfvisualizer、studiowelcome、qmldesigner | 6 个插件不编译，IDE 可用但无 QML 分析/设计 |
| **help** | help 插件 | 无帮助系统 |
| **serialport** | serialterminal | 无串口终端 |
| **designercomponents-private** | designer（Qt Widget Designer） | 无可视化 UI 设计 |
| **quick-private** | qmldesigner | 无 QML 设计器 |

### Qt 6 附加需求

| 模块 | 条件 |
|---|---|
| **core5compat** | Qt 6 时自动追加（`qtcreator.pri`），提供 `QTextCodec` 等兼容类 |

## 五、C++ 标准要求

`qtcreator.pri` 第 14 行：

```qmake
CONFIG += c++17 c++1z
```

要求 **C++17**。`c++1z` 是 `c++17` 在旧版 Qt/编译器中的别名。

这意味着：
- 编译器必须支持 C++17（GCC ≥ 7、Clang ≥ 5、MSVC ≥ 2017 15.7）
- Qt 5.14 本身用 C++11/14 构建，但其 qmake 支持向项目传递 `c++17` 标志

## 六、结论

| 项目 | 值 |
|---|---|
| **qmake 最低 Qt 版本** | **Qt 5.14.0**（硬性门禁，`error()` 拒绝更低版本） |
| **推荐 Qt 5.x 版本** | **Qt 5.15.x**（全部条件特性可用） |
| **Qt 6.x 支持** | ✅ 支持（需要 `core5compat` 模块，`qtcreator.pri` 自动处理） |
| **Qt 6 推荐版本** | **Qt 6.2.x**（部分 QuickWidget/WebEngine 特性需要） |
| **Qt 6 最低版本** | Qt 6.0.0（可编译，部分功能走兼容路径） |
| **必需 Qt 模块** | core、concurrent、gui、widgets、network、printsupport、qml、sql |
| **可选 Qt 模块** | quick、quickwidgets、help、serialport、designercomponents-private、quick-private |
| **C++ 标准** | C++17 |
| **废弃 API 下限** | Qt 5.9.0（`QT_DISABLE_DEPRECATED_BEFORE=0x050900`） |
