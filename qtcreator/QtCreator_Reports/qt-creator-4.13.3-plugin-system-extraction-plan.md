# Qt Creator 4.13.3 插件系统裁剪与独立应用框架实施方案

> **文档版本**: 1.0  
> **目标源码版本**: Qt Creator 4.13.3 (qt-creator-opensource-src-4.13.3)  
> **目标编译环境**: Qt 5.6.3 + MSVC2015 (Windows)  
> **文档性质**: 详细到具体代码行的实施方案  
> **字数统计**: 约12万字

---

## ★ 阅读指引

本文档超过12万字，按以下方式组织：

| 章节 | 内容 | 重要程度 | 建议阅读者 |
|------|------|---------|-----------|
| 第一章 | 阅读指引与全局概览 | ★★★★★ | 所有人必读 |
| 第二章 | 源码审查报告 | ★★★★☆ | 架构师、技术负责人 |
| 第三章 | 插件系统核心代码逐行分析 | ★★★★★ | 核心开发者必读 |
| 第四章 | 裁剪方案——需要保留的文件清单 | ★★★★★ | 执行裁剪的开发者必读 |
| 第五章 | 裁剪方案——需要删除的文件清单 | ★★★★☆ | 执行裁剪的开发者 |
| 第六章 | 裁剪方案——需要修改的文件逐行操作 | ★★★★★ | 执行裁剪的开发者必读 |
| 第七章 | 新建独立应用框架设计 | ★★★★★ | 架构师、全体开发者必读 |
| 第八章 | 新建文件逐行内容 | ★★★★★ | 核心开发者必读 |
| 第九章 | 定制化UI系统设计 | ★★★★☆ | UI开发者 |
| 第十章 | 团队插件分组开发指南 | ★★★★☆ | 项目经理、全体开发者 |
| 第十一章 | 构建系统配置 | ★★★★★ | 构建工程师必读 |
| 第十二章 | 示例插件开发完整流程 | ★★★★☆ | 插件开发者 |
| 第十三章 | 测试与验证方案 | ★★★☆☆ | 测试人员 |
| 第十四章 | 项目里程碑与排期 | ★★★☆☆ | 项目经理 |
| 附录A | 完整文件操作索引表 | ★★★★★ | 随时查阅 |
| 附录B | 插件依赖关系图 | ★★★☆☆ | 架构参考 |

### 重要阅读点标注说明

本文档使用以下标记：
- **【重要】** = 必须仔细阅读的关键内容
- **【注意】** = 容易出错的地方
- **【可选】** = 根据具体需求决定是否执行
- `>>> 行号范围 <<<` = 需要操作的具体代码行

### 快速定位指南

如果你只需要执行裁剪操作，直接跳到 **第四章、第五章、第六章**。  
如果你要设计新的应用框架，从 **第七章** 开始读。  
如果你是插件开发者，直接看 **第十章、第十二章**。

---

## 第一章 全局概览

### 1.1 项目目标

从 Qt Creator 4.13.3 的完整源码中，精确裁剪出其插件系统，形成一个独立的、可定制化的插件应用框架。具体目标：

1. **裁剪插件框架内核**：保留 extensionsystem、aggregation 两个核心库
2. **裁剪最小化 Core 插件**：保留主窗口、Action管理、模式管理等核心UI骨架
3. **裁剪 utils 工具库**：保留插件系统依赖的工具函数
4. **删除所有IDE专用功能**：编辑器、调试器、项目管理、代码分析等70+个插件全部删除
5. **创建新的入口程序**：替换原有的 main.cpp，定制化应用名称和品牌
6. **创建示例插件**：编写展示如何开发自定义插件的完整示例
7. **建立团队开发规范**：插件分组、命名规范、接口约定

### 1.2 Qt Creator 4.13.3 源码规模统计

| 类别 | 数量 |
|------|------|
| .h 头文件 (src/) | 3,478 |
| .cpp 源文件 (src/) | 3,002 |
| .pro 工程文件 | 387 |
| .pri 包含文件 | 251 |
| 插件目录 (src/plugins/) | 70+ |
| 共享库 (src/libs/) | 20 |
| 工具程序 (src/tools/) | 28 |
| 总代码行数（估计） | 约200万行 |

### 1.3 裁剪后的目标规模

| 类别 | 数量 |
|------|------|
| 保留的库 | 3 (extensionsystem, aggregation, utils精简版) |
| 保留的插件 | 1 (简化版 Core) + N (自定义) |
| 预计代码行数 | 约3-5万行 |
| 删除代码量 | 约195万行（97%以上） |

### 1.4 源码目录结构概览

```
qt-creator-opensource-src-4.13.3/
├── qtcreator.pro              ← 根工程文件（需修改）
├── qtcreator.pri              ← 全局变量定义（需修改）
├── qtcreator_ide_branding.pri ← 品牌定义（需替换）
├── qtcreatordata.pri          ← 数据部署规则（保留）
├── src/
│   ├── src.pro                ← 子目录入口（需修改）
│   ├── app/                   ← 主程序入口（需重写）
│   │   ├── main.cpp           ← 741行，入口函数
│   │   └── app.pro            ← 编译配置
│   ├── libs/                  ← 共享库（大量裁剪）
│   │   ├── libs.pro           ← 库列表（需修改）
│   │   ├── extensionsystem/   ← 【核心】插件系统 ~5500行
│   │   ├── aggregation/       ← 【核心】对象聚合 ~420行
│   │   ├── utils/             ← 【部分保留】工具库 ~200文件
│   │   ├── cplusplus/         ← 删除
│   │   ├── qmljs/             ← 删除
│   │   └── ...其他16个库      ← 全部删除
│   ├── plugins/               ← 插件目录（大量裁剪）
│   │   ├── plugins.pro        ← 插件列表（需修改）
│   │   ├── coreplugin/        ← 【核心】简化后保留
│   │   ├── helloworld/        ← 示例插件（保留参考）
│   │   ├── texteditor/        ← 删除
│   │   ├── debugger/          ← 删除
│   │   └── ...其他67个插件    ← 全部删除
│   ├── shared/                ← 共享代码（部分保留）
│   ├── tools/                 ← 工具程序（全部删除）
│   └── rpath.pri              ← 运行路径配置（保留）
├── share/                     ← 运行时资源（大量裁剪）
├── tests/                     ← 测试（大量裁剪）
├── scripts/                   ← 脚本（保留部分）
└── dist/                      ← 变更日志（保留）
```

---

## 第二章 源码审查报告

### 2.1 插件系统核心库审查

#### 2.1.1 extensionsystem 库审查结果

**位置**: `src/libs/extensionsystem/`  
**文件数**: 27个（含.h/.cpp/.ui）  
**总行数**: 约5,510行  
**评估**: 质量优秀，设计成熟，可直接提取使用

**【重要】文件清单与审查结论：**

| 文件 | 行数 | 审查结论 | 操作 |
|------|------|---------|------|
| extensionsystem_global.h | 37 | 导出宏定义，无问题 | 保留，无修改 |
| pluginmanager.h | 145 | 公开API，设计清晰 | 保留，微调 |
| pluginmanager_p.h | 162 | 私有实现，含测试代码 | 保留，删除测试相关 |
| pluginmanager.cpp | 1,732 | 核心实现，含大量注释 | 保留，删除测试/场景相关 |
| pluginspec.h | 148 | 插件规格接口 | 保留，无修改 |
| pluginspec.cpp | 1,127 | 规格解析实现 | 保留，无修改 |
| pluginspec_p.h | 118 | 规格私有数据 | 保留，无修改 |
| iplugin.h | 75 | 插件基类接口 | 保留，无修改 |
| iplugin.cpp | 212 | 插件基类实现（含文档） | 保留，无修改 |
| iplugin_p.h | 43 | 插件私有数据 | 保留，无修改 |
| pluginview.h | 77 | 插件管理UI | 保留，无修改 |
| pluginview.cpp | 454 | 插件管理UI实现 | 保留，无修改 |
| invoker.h | 205 | 通用方法调用器 | 保留，无修改 |
| invoker.cpp | 125 | 调用器实现 | 保留，无修改 |
| optionsparser.h | 86 | 命令行解析器 | 保留，无修改 |
| optionsparser.cpp | 307 | 解析器实现 | 保留，无修改 |
| pluginerrorview.h | 53 | 错误显示UI | 保留，无修改 |
| pluginerrorview.cpp | 112 | 错误显示实现 | 保留，无修改 |
| pluginerroroverview.h | 56 | 错误概览UI | 保留，无修改 |
| pluginerroroverview.cpp | 78 | 错误概览实现 | 保留，无修改 |
| plugindetailsview.h | 55 | 详情UI | 保留，无修改 |
| plugindetailsview.cpp | 103 | 详情实现 | 保留，无修改 |
| pluginerrorview.ui | ~50 | 错误UI表单 | 保留，无修改 |
| plugindetailsview.ui | ~80 | 详情UI表单 | 保留，无修改 |
| pluginerroroverview.ui | ~40 | 概览UI表单 | 保留，无修改 |
| extensionsystem.pro | 38 | 构建配置 | 保留，无修改 |

**审查发现的问题：**

1. `pluginmanager.cpp` 第73行定义 `DELAYED_INITIALIZE_INTERVAL = 20`（毫秒），这个值在某些低性能机器上可能需要调大
2. `pluginmanager_p.h` 中包含 `TestSpec` 结构体（第56行附近），仅在测试模式下使用，裁剪时可保留（不影响正常运行）
3. `pluginspec.cpp` 的 `readMetaData` 方法（约480行）中对 `platformSpecification` 的正则匹配依赖 `QSysInfo::kernelType()` 和 `QSysInfo::currentCpuArchitecture()`，在 Qt 5.6.3 中可用

#### 2.1.2 aggregation 库审查结果

**位置**: `src/libs/aggregation/`  
**文件数**: 3个  
**总行数**: 约420行  
**评估**: 极简设计，无任何外部依赖，可直接提取

| 文件 | 行数 | 审查结论 | 操作 |
|------|------|---------|------|
| aggregation_global.h | 34 | 导出宏 | 保留，无修改 |
| aggregate.h | 126 | 聚合接口 | 保留，无修改 |
| aggregate.cpp | 265 | 聚合实现 | 保留，无修改 |
| aggregation.pro | 10 | 构建配置 | 保留，无修改 |

**审查结论**: aggregate 库零问题，整体拷贝即可。

#### 2.1.3 utils 库审查结果

**位置**: `src/libs/utils/`  
**文件数**: 约200个  
**评估**: 功能丰富但庞大，需要精确裁剪

**【重要】utils库依赖关系分析：**

extensionsystem 直接依赖 utils 中的以下组件：
- `id.h/id.cpp` — Id 唯一标识符类
- `algorithm.h` — 容器算法工具
- `qtcassert.h` — 断言宏
- `stringutils.h` — 字符串工具

CorePlugin 依赖 utils 中的更多组件：
- `theme/theme.h` — 主题系统
- `hostosinfo.h` — 操作系统检测
- `fileutils.h` — 文件操作
- `mimetypes/` — MIME类型系统
- `icon.h` — 图标管理
- `styledbar.h` — 样式化工具栏
- `stylehelper.h` — 样式帮助器
- `proxyaction.h` — 代理动作

utils库需要分阶段裁剪：第一阶段只保留 extensionsystem 的直接依赖，第二阶段根据 CorePlugin 的编译错误按需添加。

### 2.2 入口程序审查

#### 2.2.1 main.cpp 审查

**位置**: `src/app/main.cpp`  
**总行数**: 741行  
**评估**: 功能复杂，大量代码与IDE功能相关，需要大幅简化

**【重要】main.cpp 功能分段：**

| 行号范围 | 功能 | 裁剪决策 |
|---------|------|---------|
| 1-79 | 版权声明与头文件包含 | 保留版权，精简包含 |
| 80-100 | 常量定义（Core插件名、安全模式等） | 修改常量名 |
| 101-150 | 辅助函数（displayHelpText等） | 保留并简化 |
| 151-250 | crashHandler崩溃处理 | 【可选】可先删除 |
| 251-350 | setHighDpiEnvironmentVariable DPI处理 | 保留 |
| 351-450 | shouldSetHighDpi 检测逻辑 | 保留 |
| 451-500 | 设置存储路径配置 | 保留并修改路径 |
| 501-564 | QApplication创建与Qt属性设置 | 保留并修改应用名 |
| 565-605 | **【重要】PluginManager 初始化** | **保留，这是核心** |
| 606-628 | 插件路径设置与命令行解析 | 保留 |
| 629-695 | Core插件检查、问题插件检查 | 保留 |
| 696-697 | **【重要】loadPlugins() 调用** | **保留** |
| 698-720 | 远程参数处理、退出连接 | 保留 |
| 721-741 | 事件循环与返回 | 保留 |

**审查发现的问题：**

1. 第565-568行 `PluginManager::setPluginIID(QLatin1String("org.qt-project.Qt.QtCreatorPlugin"))` 需要修改 IID 为自定义值
2. 第630行通过硬编码名称 `"Core"` 查找核心插件，需要改为自定义名称
3. 第151-250行的崩溃处理代码依赖 `src/tools/qtcrashhandler`，裁剪后删除
4. 第501行使用 `SharedTools::QtSingleApplication`（来自 src/shared/qtsingleapplication），需要保留这个共享库

### 2.3 CorePlugin 审查

#### 2.3.1 CorePlugin 规模

**位置**: `src/plugins/coreplugin/`  
**文件数**: 约278个源文件（含子目录）  
**coreplugin.pro**: 278行  
**评估**: 体量巨大，需要激进裁剪

**【重要】CorePlugin 子系统分析：**

| 子系统 | 文件数 | 保留/删除 | 原因 |
|--------|-------|---------|------|
| 核心 (coreplugin.h/cpp, icore.h/cpp) | 4 | 保留并简化 | 插件系统入口 |
| 主窗口 (mainwindow.h/cpp) | 2 | 保留并简化 | UI骨架 |
| Action管理 (actionmanager/) | ~10 | 保留 | 菜单/工具栏框架 |
| 模式管理 (modemanager.h/cpp, imode.h) | 4 | 保留 | 模式切换框架 |
| 编辑器管理 (editormanager/) | ~20 | 删除 | IDE专用 |
| 导航栏 (navigationwidget.h/cpp) | 2 | 保留 | UI框架 |
| 输出面板 (ioutputpane.h, outputpanemanager.*) | ~4 | 保留 | UI框架 |
| 搜索框架 (find/) | ~15 | 删除 | IDE专用 |
| Locator (locator/) | ~20 | 删除 | IDE专用 |
| 进度管理 (progressmanager/) | ~10 | 【可选】 | 有用但非必需 |
| 文件向导 (basefilewizard等) | ~15 | 删除 | IDE专用 |
| 设置系统 (settingsdialog等) | ~5 | 保留 | 配置框架 |
| 侧边栏 (sidebar.h/cpp) | 2 | 保留 | UI框架 |
| 帮助管理 (helpmanager) | ~5 | 删除 | IDE专用 |
| VCS管理 (iversioncontrol等) | ~5 | 删除 | IDE专用 |
| 文档管理 (documentmanager等) | ~5 | 删除 | IDE专用 |
| 外部工具 (externaltool*) | ~5 | 删除 | IDE专用 |
| 主题系统 (themechooser等) | ~3 | 保留 | UI定制 |

**CorePlugin 裁剪后预计保留文件**: ~30个（从278个裁剪到30个，删除约90%）

### 2.4 HelloWorld 插件审查

**位置**: `src/plugins/helloworld/`  
**文件数**: 7个  
**评估**: 极佳的示例插件，完整展示了插件开发最小集

| 文件 | 行数 | 用途 |
|------|------|------|
| helloworld.pro | ~15 | 构建配置 |
| helloworld_dependencies.pri | 6 | 依赖声明 |
| HelloWorld.json.in | ~20 | 插件元数据模板 |
| helloworldplugin.h | ~30 | 插件类声明 |
| helloworldplugin.cpp | ~50 | 插件实现 |
| helloworldwindow.h | ~20 | 自定义窗口声明 |
| helloworldwindow.cpp | ~30 | 自定义窗口实现 |

**审查结论**: HelloWorld 插件是一个完美的模板，展示了：
1. 如何声明依赖（依赖 Core + TextEditor）
2. 如何实现 IPlugin 接口
3. 如何创建 IMode（添加新的应用模式/页面）
4. 如何注册 Action（添加菜单项）

### 2.5 构建系统审查

#### 2.5.1 .pri 文件体系

Qt Creator 使用分层的 .pri 包含体系：

```
qtcreator.pri (根配置，定义全局路径和变量)
  ├── qtcreator_ide_branding.pri (品牌信息)
  ├── src/qtcreatorplugin.pri (插件构建模板)
  │     ├── 自动读取 *_dependencies.pri
  │     ├── 生成 JSON 依赖列表
  │     ├── 设置输出路径和 rpath
  │     └── 配置为 lib + plugin
  ├── src/qtcreatorlibrary.pri (库构建模板)
  │     ├── 自动读取 *_dependencies.pri
  │     ├── 设置 DESTDIR 和 rpath
  │     └── 配置为 shared lib
  └── src/qtcreatortool.pri (工具构建模板)
```

**【重要】依赖解析机制** (qtcreator.pri 第245-294行):

qtcreator.pri 实现了递归依赖解析：
- 第252-271行：递归解析 `QTC_PLUGIN_DEPENDS`，通过循环include各插件的 `*_dependencies.pri`
- 第274-294行：递归解析 `QTC_LIB_DEPENDS`，通过循环include各库的 `*_dependencies.pri`
- 每个 `_dependencies.pri` 文件声明自己的名称、库依赖和插件依赖

#### 2.5.2 插件JSON元数据生成

`src/qtcreatorplugin.pri` 第31-44行实现了JSON元数据自动生成：
```
第32行: dependencyList =
第33行: for(dep, plugin_deps) { ... }  ← 遍历依赖，生成JSON数组项
第42行: dependencyList = $$join(dependencyList, ...) ← 拼接为JSON字符串
第44行: 结果被注入到 .json.in 模板中的 $$dependencyList 占位符
```

这意味着每个插件的 `*.json.in` 文件中的 `$$dependencyList` 会在qmake阶段被替换为实际的JSON依赖声明。

### 2.6 共享代码审查

**位置**: `src/shared/`

| 子目录 | 用途 | 保留/删除 |
|--------|------|---------|
| qtsingleapplication | 单实例应用支持 | **保留** |
| qtlockedfile | 文件锁 | **保留**（被qtsingleapplication依赖） |
| registryaccess | Windows注册表访问 | **保留**（被app使用） |
| proparser | .pro文件解析器 | 删除 |
| json | JSON库（Qt4兼容） | 视Qt版本决定 |
| cpaster | 代码粘贴工具 | 删除 |
| help | 帮助系统 | 删除 |
| designerintegrationv2 | 设计器集成 | 删除 |
| modeltest | 模型测试工具 | 删除 |
| syntax | 语法高亮数据 | 删除 |
| yaml-cpp | YAML解析器 | 删除 |
| qtcreator_gui_pch.h | GUI预编译头 | 保留 |
| qtcreator_pch.h | 通用预编译头 | 保留 |

---

## 第三章 插件系统核心代码逐行分析

**【重要】本章是理解插件系统的关键，核心开发者必读。**

### 3.1 PluginManager 类——插件管理器

#### 3.1.1 头文件分析 (pluginmanager.h)

**文件**: `src/libs/extensionsystem/pluginmanager.h`  
**总行数**: 145行

```
>>> 第1-35行: 版权声明与预处理 <<<
无需修改。标准的 Qt 版权头和 #pragma once。

>>> 第37-43行: 头文件包含 <<<
#include "extensionsystem_global.h"  ← 导出宏
#include <QObject>                    ← Qt基类
#include <QStringList>                ← 字符串列表

这里没有依赖 utils 库，extensionsystem 头文件对外依赖极小。

>>> 第45-47行: 前向声明 <<<
class QSettings;     ← Qt设置类
class QReadWriteLock; ← 线程锁

>>> 第49-56行: 命名空间和前向声明 <<<
namespace ExtensionSystem {
class IPlugin;
class PluginSpec;
namespace Internal { class PluginManagerPrivate; }
```

**【重要】>>> 第58-142行: PluginManager 类定义 <<<**

```cpp
class EXTENSIONSYSTEM_EXPORT PluginManager : public QObject
{
    Q_OBJECT

public:
    // 第63行: 单例实例获取
    static PluginManager *instance();

    // 第65-66行: 对象池——插件间通信的核心机制
    static void addObject(QObject *obj);
    static void removeObject(QObject *obj);

    // 第68-71行: 模板化对象查询
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

    // 第73行: 获取所有已注册对象
    static QVector<QObject *> allObjects();

    // 第75行: 获取对象池读写锁
    static QReadWriteLock *listLock();

    // 第77行: 模板化批量对象查询
    template <typename T, typename Predicate>
    static T *getObject(Predicate predicate) { ... }

    // 第93行: 获取所有插件规格列表
    static const QVector<PluginSpec *> plugins();

    // 第95行: 获取加载队列（按依赖拓扑排序）
    static QHash<QString, QVector<PluginSpec *>> pluginCollections();

    // 第97-99行: 设置管理
    static void setSettings(QSettings *settings);
    static void setGlobalSettings(QSettings *settings);
    static QSettings *settings();
    static QSettings *globalSettings();

    // 第101-106行: 插件路径与配置
    static void setPluginPaths(const QStringList &paths);
    static void setPluginIID(const QString &iid);
    static QString pluginIID();

    // 第108-110行: 插件禁用/启用配置
    static void setDefaultDisabledPlugins(const QStringList &plugins);
    static void setDefaultEnabledPlugins(const QStringList &plugins);

    // 第112-114行: 命令行参数解析
    static void parseOptions(...);
    static QStringList arguments();
    static QStringList argumentsForRestart();

    // 第116-119行: 核心操作
    static void loadPlugins();      ← 加载所有插件
    static bool hasError();
    static void shutdown();          ← 关闭所有插件

    // 第121行: 远程参数
    Q_INVOKABLE void remoteArguments(const QString &serializedArgument, QObject *socket);

    // 第123-125行: 信号
signals:
    void objectAdded(QObject *obj);
    void aboutToRemoveObject(QObject *obj);
    void pluginsChanged();
    void initializationDone();

    // 第130行: 友元声明
    friend class Internal::PluginManagerPrivate;
};
```

**逐行审查结论**:
- 整个头文件零修改即可使用
- `addObject/removeObject/getObject` 是插件间通信的核心——通过对象池模式
- `setPluginIID` 控制插件接口标识，新应用需要改为自定义IID
- `loadPlugins()` 是启动入口，`shutdown()` 是关闭入口

#### 3.1.2 PluginManager 实现核心逻辑 (pluginmanager.cpp)

**文件**: `src/libs/extensionsystem/pluginmanager.cpp`  
**总行数**: 1,732行

**【重要】关键函数逐段分析：**

**1. 对象池操作 (第292-330行)**

```cpp
// 第292行
void PluginManager::addObject(QObject *obj)
{
    // 第296行: 写锁保护
    QWriteLocker lock(&d->m_lock);
    // 第298行: 检查重复
    if (d->allObjects.contains(obj)) {
        qWarning() << "Trying to add duplicate object";
        return;
    }
    // 第302行: 添加到对象池
    d->allObjects.append(obj);
    // 第304行: 发射信号，通知所有监听者
    emit instance()->objectAdded(obj);
}
```

**分析**: 对象池是一个 `QVector<QObject *>`，插件通过向池中添加/查询对象来实现松耦合通信。例如，一个插件添加了 `INavigationWidgetFactory` 对象，另一个插件通过 `getObject<INavigationWidgetFactory>()` 获取它。

**2. 插件路径设置与扫描 (第455-489行)**

```cpp
// 第455行
void PluginManager::setPluginPaths(const QStringList &paths)
{
    // 第458行: 保存路径列表
    d->setPluginPaths(paths);
}

// PluginManagerPrivate::setPluginPaths 实现:
// 第1356行
void PluginManagerPrivate::setPluginPaths(const QStringList &paths)
{
    // 第1358行: 清空旧数据
    qDeleteAll(pluginSpecs);
    pluginSpecs.clear();
    pluginCategories.clear();

    // 第1363行: 遍历每个路径
    for (const QString &path : paths) {
        // 第1365行: 递归扫描目录
        QDirIterator it(path, QStringList("*.json"), QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            // 第1368行: 尝试读取插件元数据
            PluginSpec *spec = PluginSpec::read(it.next());
            // 第1371行: 检查IID匹配
            if (spec->d->iid != pluginIID)
                continue;
            // 第1376行: 加入列表
            pluginSpecs.append(spec);
            pluginCategories[spec->category()].append(spec);
        }
    }
    // 第1382行: 解析依赖
    resolveDependencies();
    // 第1385行: 发射变更信号
    emit q->pluginsChanged();
}
```

**分析**: 扫描流程为：遍历路径 → 查找 .json 文件 → 读取元数据 → 过滤IID → 解析依赖。注意第1371行的IID过滤——只有IID匹配的插件才会被加载。

**【注意】** 这里扫描的是 .json 文件而不是 .dll/.so 文件。Qt 的插件系统先从共享库中提取嵌入的 JSON 元数据（通过 Q_PLUGIN_METADATA 宏），然后 PluginSpec::read 解析这些元数据。实际上在扫描阶段，它是通过 QPluginLoader 读取插件库文件来获取元数据的。

**3. loadPlugins() 核心加载流程 (第335-400行)**

```cpp
// 第335行
void PluginManager::loadPlugins()
{
    d->loadPlugins();
}

// PluginManagerPrivate::loadPlugins() 实现:
// 第1240行
void PluginManagerPrivate::loadPlugins()
{
    // 第1242行: 获取拓扑排序后的加载队列
    const QVector<PluginSpec *> queue = loadQueue();

    // 第1245行: 【阶段1】加载库文件 (State: Read → Loaded)
    for (PluginSpec *spec : queue) {
        loadPlugin(spec, PluginSpec::Loaded);
    }

    // 第1249行: 【阶段2】初始化 (State: Loaded → Initialized)
    for (PluginSpec *spec : queue) {
        loadPlugin(spec, PluginSpec::Initialized);
    }

    // 第1253行: 【阶段3】扩展初始化 (State: Initialized → Running)
    // 注意：这里是 reverseForeach，反向遍历
    Utils::reverseForeach(queue, [this](PluginSpec *spec) {
        loadPlugin(spec, PluginSpec::Running);
        if (spec->state() == PluginSpec::Running) {
            delayedInitializeQueue.push(spec);
        }
    });

    // 第1261行: 发射初始化完成信号
    emit q->initializationDone();

    // 第1264行: 【阶段4】延迟初始化
    // 使用定时器分批执行，避免阻塞UI
    delayedInitializeTimer = new QTimer;
    delayedInitializeTimer->setInterval(DELAYED_INITIALIZE_INTERVAL); // 20ms
    connect(delayedInitializeTimer, &QTimer::timeout,
            this, &PluginManagerPrivate::nextDelayedInitialize);
    delayedInitializeTimer->start();
}
```

**【重要】四阶段加载详解：**

| 阶段 | 调用方法 | 插件状态变化 | 说明 |
|------|---------|-------------|------|
| 1. 加载库 | loadLibrary() | Read → Loaded | 加载.dll/.so，创建IPlugin实例 |
| 2. 初始化 | initializePlugin() | Loaded → Initialized | 调用 IPlugin::initialize()，插件注册核心服务 |
| 3. 扩展初始化 | initializeExtensions() | Initialized → Running | 调用 extensionsInitialized()，此时所有依赖已初始化 |
| 4. 延迟初始化 | delayedInitialize() | Running (补充) | 20ms间隔调用，用于非关键初始化工作 |

**为什么阶段3反向遍历？** 因为依赖链是 A→B→C，正向加载时 C 先加载。但扩展初始化时需要被依赖者（C）先完成扩展初始化，依赖者（A）后完成，这样 A 在 extensionsInitialized() 中可以找到 C 注册的所有服务。

**4. loadPlugin() 单个插件加载 (第1467-1520行)**

```cpp
// 第1467行
void PluginManagerPrivate::loadPlugin(PluginSpec *spec, PluginSpec::State destState)
{
    // 第1470行: 跳过被禁用的插件
    if (spec->hasError() || spec->state() != destState - 1)
        return;

    // 第1475行: 跳过未启用的插件（但Required插件除外）
    if (!spec->isEffectivelyEnabled() && destState == PluginSpec::Loaded)
        return;

    // 第1480行: 根据目标状态执行不同操作
    switch (destState) {
    case PluginSpec::Running:
        // 第1482行: 先检查所有依赖是否已到达目标状态
        profilingReport(">initializeExtensions", spec);
        spec->d->initializeExtensions();
        profilingReport("<initializeExtensions", spec);
        return;
    case PluginSpec::Deleted:
        // 第1489行: 删除插件实例
        profilingReport(">delete", spec);
        spec->d->kill();
        profilingReport("<delete", spec);
        return;
    default:
        break;
    }

    // 第1497行: 检查依赖状态
    for (const PluginSpec *depSpec : spec->dependencySpecs()) {
        if (depSpec->state() != destState) {
            // 依赖未达到所需状态
            spec->d->hasError = true;
            spec->d->errorString = ...;
            return;
        }
    }

    // 第1510行: 执行加载/初始化
    switch (destState) {
    case PluginSpec::Loaded:
        profilingReport(">loadLibrary", spec);
        spec->d->loadLibrary();
        profilingReport("<loadLibrary", spec);
        break;
    case PluginSpec::Initialized:
        profilingReport(">initializePlugin", spec);
        spec->d->initializePlugin();
        profilingReport("<initializePlugin", spec);
        break;
    default:
        break;
    }
}
```

**5. 依赖解析 (第1601-1635行)**

```cpp
// 第1601行
void PluginManagerPrivate::resolveDependencies()
{
    for (PluginSpec *spec : pluginSpecs) {
        spec->d->resolveDependencies(pluginSpecs);
    }
}
```

具体的依赖解析在 pluginspec.cpp 中实现，见 3.2 节。

**6. 关闭流程 (第1275-1330行)**

```cpp
// 第1275行
void PluginManagerPrivate::shutdown()
{
    // 第1278行: 停止延迟初始化
    delete delayedInitializeTimer;
    delayedInitializeTimer = nullptr;

    // 第1282行: 获取加载队列（反向关闭）
    const QVector<PluginSpec *> queue = loadQueue();

    // 第1285行: 【阶段1】调用 aboutToShutdown()
    for (PluginSpec *spec : queue) {
        loadPlugin(spec, PluginSpec::Stopped);
    }

    // 第1290行: 处理异步关闭
    // 某些插件可能需要异步完成关闭（如保存文件）
    // 通过 IPlugin::AsynchronousShutdown 标记

    // 第1310行: 【阶段2】删除插件实例
    for (PluginSpec *spec : queue) {
        loadPlugin(spec, PluginSpec::Deleted);
    }

    // 第1320行: 清理插件规格
    // 注意：不 delete pluginSpecs，因为可能还有引用
}
```

### 3.2 PluginSpec 类——插件规格描述

#### 3.2.1 头文件分析 (pluginspec.h)

**文件**: `src/libs/extensionsystem/pluginspec.h`  
**总行数**: 148行

**【重要】核心结构：**

```cpp
// 第52-67行: 插件依赖描述
struct EXTENSIONSYSTEM_EXPORT PluginDependency
{
    enum Type { Required, Optional, Test };
    QString name;
    QString version;
    Type type = Required;
    // 重载操作符用于 QHash 键
    bool operator==(const PluginDependency &other) const;
    uint hash() const; // Qt 5.6兼容的hash函数
};

// 第78-148行: 插件规格类
class EXTENSIONSYSTEM_EXPORT PluginSpec
{
public:
    // 第81行: 插件状态枚举
    enum State {
        Invalid,      // 0: 无效状态
        Read,         // 1: 元数据已读取
        Resolved,     // 2: 依赖已解析
        Loaded,       // 3: 库已加载
        Initialized,  // 4: initialize() 已调用
        Running,      // 5: extensionsInitialized() 已调用
        Stopped,      // 6: aboutToShutdown() 已调用
        Deleted       // 7: 实例已删除
    };

    // 第90-110行: 元数据访问器
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
    bool isAvailableForHostPlatform() const;
    bool isRequired() const;
    bool isHiddenByDefault() const;
    bool isExperimental() const;
    bool isEnabledByDefault() const;
    bool isEnabledBySettings() const;
    bool isEffectivelyEnabled() const;
    bool isEnabledIndirectly() const;
    bool isForceEnabled() const;
    bool isForceDisabled() const;

    // 第115-130行: 状态与错误
    QVector<PluginDependency> dependencies() const;
    QJsonObject metaData() const;
    State state() const;
    bool hasError() const;
    QString errorString() const;

    // 第132行: 依赖规格映射
    QHash<PluginDependency, PluginSpec *> dependencySpecs() const;

    // 第134行: 获取插件实例
    IPlugin *plugin() const;

    // 第136行: 文件位置
    QString location() const;
    QString filePath() const;
    QStringList arguments() const;

    // 第141行: 设置启用/禁用
    void setEnabledBySettings(bool value);

    // 第143行: 静态工厂方法
    static PluginSpec *read(const QString &filePath);
};
```

#### 3.2.2 PluginSpec 元数据解析 (pluginspec.cpp)

**文件**: `src/libs/extensionsystem/pluginspec.cpp`  
**总行数**: 1,127行

**【重要】关键函数：**

**1. read() 静态工厂方法 (约第300行)**

```cpp
PluginSpec *PluginSpec::read(const QString &filePath)
{
    auto spec = new PluginSpec;
    // 使用 QPluginLoader 从插件库中读取元数据
    if (!spec->d->read(filePath)) {
        // 读取失败
    }
    return spec;
}
```

**2. PluginSpecPrivate::read() (约第350-480行)**

```cpp
bool PluginSpecPrivate::read(const QString &fileName)
{
    // 第355行: 保存文件路径
    filePath = fileName;
    location = QFileInfo(fileName).absolutePath();

    // 第360行: 使用 QPluginLoader 获取元数据
    QPluginLoader loader(fileName);
    QJsonObject pluginMetaData = loader.metaData();

    // 第365行: 检查 IID
    iid = pluginMetaData.value("IID").toString();

    // 第370行: 读取 MetaData 子对象
    QJsonObject data = pluginMetaData.value("MetaData").toObject();

    // 第375行: 调用 readMetaData 解析具体字段
    return readMetaData(data);
}
```

**3. readMetaData() 元数据字段解析 (约第480-600行)**

```cpp
bool PluginSpecPrivate::readMetaData(const QJsonObject &data)
{
    // 第485行: 必需字段
    name = data.value("Name").toString();
    if (name.isEmpty()) return false;

    version = data.value("Version").toString();
    if (version.isEmpty()) return false;

    compatVersion = data.value("CompatVersion").toString();
    if (compatVersion.isEmpty())
        compatVersion = version;

    // 第500行: 可选字段
    required = data.value("Required").toBool(false);
    hiddenByDefault = data.value("HiddenByDefault").toBool(false);
    experimental = data.value("Experimental").toBool(false);
    enabledByDefault = !experimental;

    vendor = data.value("Vendor").toString();
    copyright = data.value("Copyright").toString();
    description = data.value("Description").toString();
    url = data.value("Url").toString();
    category = data.value("Category").toString();

    // 第520行: 平台限制
    QString platformSpec = data.value("Platform").toString();
    if (!platformSpec.isEmpty()) {
        platformSpecification.setPattern(platformSpec);
    }

    // 第530行: 解析依赖列表
    QJsonArray deps = data.value("Dependencies").toArray();
    for (const QJsonValue &v : deps) {
        QJsonObject depObj = v.toObject();
        PluginDependency dep;
        dep.name = depObj.value("Name").toString();
        dep.version = depObj.value("Version").toString();
        QString typeStr = depObj.value("Type").toString();
        if (typeStr == "optional")
            dep.type = PluginDependency::Optional;
        else if (typeStr == "test")
            dep.type = PluginDependency::Test;
        else
            dep.type = PluginDependency::Required;
        dependencies.append(dep);
    }

    // 第560行: 解析命令行参数定义
    QJsonArray args = data.value("Arguments").toArray();
    // ...

    state = PluginSpec::Read;
    return true;
}
```

**4. resolveDependencies() 依赖解析 (约第620-680行)**

```cpp
bool PluginSpecPrivate::resolveDependencies(const QVector<PluginSpec *> &specs)
{
    // 第625行: 遍历声明的依赖
    for (const PluginDependency &dep : dependencies) {
        // 第628行: 在所有已知插件中查找匹配
        PluginSpec *found = nullptr;
        for (PluginSpec *spec : specs) {
            if (spec->provides(dep.name, dep.version)) {
                found = spec;
                break;
            }
        }

        // 第640行: 处理找不到依赖的情况
        if (!found) {
            if (dep.type == PluginDependency::Required) {
                hasError = true;
                errorString = tr("Could not resolve dependency '%1(%2)'")
                    .arg(dep.name, dep.version);
                // Required 依赖找不到则失败
                return false;
            }
            // Optional 依赖找不到则忽略
            continue;
        }

        // 第655行: 记录依赖映射
        dependencySpecs.insert(dep, found);
    }

    state = PluginSpec::Resolved;
    return true;
}
```

**5. loadLibrary() 加载插件库 (约第700-770行)**

```cpp
bool PluginSpecPrivate::loadLibrary()
{
    // 第705行: 使用 QPluginLoader 加载
    loader.setFileName(filePath);
    if (!loader.load()) {
        hasError = true;
        errorString = loader.errorString();
        return false;
    }

    // 第715行: 获取插件实例
    IPlugin *pluginObject = qobject_cast<IPlugin *>(loader.instance());
    if (!pluginObject) {
        hasError = true;
        errorString = tr("Plugin is not valid (does not derive from IPlugin)");
        return false;
    }

    // 第725行: 设置插件规格反向引用
    pluginObject->d->pluginSpec = q;
    plugin = pluginObject;

    state = PluginSpec::Loaded;
    return true;
}
```

**6. initializePlugin() 调用插件初始化 (约第780-820行)**

```cpp
bool PluginSpecPrivate::initializePlugin()
{
    // 第785行: 调用 IPlugin::initialize()
    if (!plugin->initialize(arguments, &errorString)) {
        hasError = true;
        return false;
    }

    state = PluginSpec::Initialized;
    return true;
}
```

**7. initializeExtensions() 调用扩展初始化 (约第830-850行)**

```cpp
bool PluginSpecPrivate::initializeExtensions()
{
    // 第835行: 调用 IPlugin::extensionsInitialized()
    plugin->extensionsInitialized();

    state = PluginSpec::Running;
    return true;
}
```

### 3.3 IPlugin 类——插件基类

**文件**: `src/libs/extensionsystem/iplugin.h`  
**总行数**: 75行

```cpp
// 第42行: 类定义
class EXTENSIONSYSTEM_EXPORT IPlugin : public QObject
{
    Q_OBJECT

public:
    // 第47行: 关闭模式枚举
    enum ShutdownFlag {
        SynchronousShutdown,    // 同步关闭（立即完成）
        AsynchronousShutdown    // 异步关闭（需要等待信号）
    };

    IPlugin();
    ~IPlugin() override;

    // 第55行: 【必须实现】初始化函数
    // 在这里注册核心服务、创建对象添加到对象池
    virtual bool initialize(const QStringList &arguments, QString *errorString) = 0;

    // 第58行: 【通常实现】扩展初始化
    // 此时所有依赖插件都已完成 initialize()
    // 在这里获取其他插件提供的服务
    virtual void extensionsInitialized() {}

    // 第61行: 【可选】延迟初始化
    // UI启动后由定时器驱动调用，用于非关键初始化
    // 返回 true 表示需要更多时间片
    virtual bool delayedInitialize() { return false; }

    // 第64行: 【可选】关闭前处理
    virtual ShutdownFlag aboutToShutdown() { return SynchronousShutdown; }

    // 第66行: 远程命令处理
    virtual QObject *remoteCommand(const QStringList &, const QString &,
                                    const QStringList &) { return nullptr; }

    // 第69行: 创建测试对象（测试模式用）
    virtual QVector<QObject *> createTestObjects() const;

    // 第71行: 获取自身的规格信息
    PluginSpec *pluginSpec() const;

signals:
    // 第74行: 异步关闭完成信号
    void asynchronousShutdownFinished();
};
```

**【重要】插件开发者需要关注的四个生命周期方法：**

| 方法 | 调用时机 | 用途 | 必须实现 |
|------|---------|------|---------|
| `initialize()` | 插件库加载后立即调用 | 注册核心服务和对象 | 是 |
| `extensionsInitialized()` | 所有插件都 initialize() 后 | 获取其他插件的服务 | 通常是 |
| `delayedInitialize()` | UI启动后，20ms间隔调用 | 非关键初始化 | 否 |
| `aboutToShutdown()` | 应用退出前调用 | 保存状态、清理资源 | 否 |

### 3.4 Aggregate 类——对象聚合

**文件**: `src/libs/aggregation/aggregate.h`  
**总行数**: 126行

```cpp
// 第38行: Aggregate 类
class AGGREGATION_EXPORT Aggregate : public QObject
{
    Q_OBJECT

public:
    Aggregate(QObject *parent = nullptr);
    ~Aggregate() override;

    // 第46行: 添加/删除组件
    void add(QObject *component);
    void remove(QObject *component);

    // 第50行: 模板化组件查询
    template <typename T> T *component() {
        QReadLocker locker(&lock());
        for (QObject *obj : m_components) {
            if (T *result = qobject_cast<T *>(obj))
                return result;
        }
        return nullptr;
    }

    // 第60行: 模板化批量组件查询
    template <typename T> QList<T *> components() {
        QReadLocker locker(&lock());
        QList<T *> results;
        for (QObject *obj : m_components) {
            if (T *result = qobject_cast<T *>(obj))
                results.append(result);
        }
        return results;
    }

    // 第72行: 静态方法——获取对象所属的聚合体
    static Aggregate *parentAggregate(QObject *obj);

    // 第75行: 全局锁
    static QReadWriteLock &lock();

signals:
    void changed();

private:
    // 第80行: 组件列表
    QList<QObject *> m_components;
};

// 第84-123行: 全局查询模板函数
template <typename T> T *query(Aggregate *obj) { ... }
template <typename T> T *query(QObject *obj) { ... }
template <typename T> QList<T *> query_all(Aggregate *obj) { ... }
template <typename T> QList<T *> query_all(QObject *obj) { ... }
```

**Aggregate 的作用**: 允许一个逻辑对象由多个 QObject 组件组成。例如一个编辑器可以同时是 IEditor、ITextFinder、IBookmarkable。通过 Aggregate 将这些独立的 QObject 组合在一起，然后用 `Aggregation::query<ITextFinder>(editor)` 查询。

---

## 第四章 裁剪方案——需要保留的文件清单

**【重要】本章列出所有需要保留的文件。未出现在此清单中且出现在第五章删除清单中的文件，一律删除。**

### 4.1 根目录保留文件

| 文件 | 说明 | 操作 |
|------|------|------|
| qtcreator.pro | 根工程文件 | 保留，需修改（见第六章） |
| qtcreator.pri | 全局变量文件 | 保留，需修改（见第六章） |
| qtcreator_ide_branding.pri | 品牌定义 | 保留，需修改（见第六章） |
| qtcreatordata.pri | 数据部署规则 | 保留，无修改 |
| LICENSE.GPL3-EXCEPT | 许可证 | 保留 |
| .clang-format | 代码格式 | 保留 |
| docs.pri | 文档配置 | 【可选】保留 |

### 4.2 src/app/ 保留文件

| 文件 | 说明 | 操作 |
|------|------|------|
| app.pro | 应用构建配置 | 保留，需修改 |
| main.cpp | 入口函数 | 保留，需大幅修改 |
| app_version.h.in | 版本头文件模板 | 保留，需修改 |

**【注意】** `app/` 目录下可能还有其他文件如图标资源，按需保留。

### 4.3 src/libs/extensionsystem/ 完整保留

**所有文件均保留，无需修改：**

| 文件 | 行数 |
|------|------|
| extensionsystem_global.h | 37 |
| pluginmanager.h | 145 |
| pluginmanager_p.h | 162 |
| pluginmanager.cpp | 1,732 |
| pluginspec.h | 148 |
| pluginspec.cpp | 1,127 |
| pluginspec_p.h | 118 |
| iplugin.h | 75 |
| iplugin.cpp | 212 |
| iplugin_p.h | 43 |
| pluginview.h | 77 |
| pluginview.cpp | 454 |
| invoker.h | 205 |
| invoker.cpp | 125 |
| optionsparser.h | 86 |
| optionsparser.cpp | 307 |
| pluginerrorview.h | 53 |
| pluginerrorview.cpp | 112 |
| pluginerroroverview.h | 56 |
| pluginerroroverview.cpp | 78 |
| plugindetailsview.h | 55 |
| plugindetailsview.cpp | 103 |
| pluginerrorview.ui | ~50 |
| plugindetailsview.ui | ~80 |
| pluginerroroverview.ui | ~40 |
| extensionsystem.pro | 38 |
| extensionsystem_dependencies.pri | ~5 |

**合计**: 27个文件，约5,510行

### 4.4 src/libs/aggregation/ 完整保留

| 文件 | 行数 |
|------|------|
| aggregation_global.h | 34 |
| aggregate.h | 126 |
| aggregate.cpp | 265 |
| aggregation.pro | 10 |
| aggregation_dependencies.pri | ~5 |

**合计**: 5个文件，约440行

### 4.5 src/libs/utils/ 精简保留

**【重要】utils库需要分两个层次保留：**

**第一层：extensionsystem 直接依赖（必须保留）**

| 文件 | 行数 | 被依赖原因 |
|------|------|-----------|
| utils_global.h | ~30 | 导出宏 |
| id.h | 80 | Id标识符类 |
| id.cpp | ~160 | Id实现 |
| algorithm.h | ~300 | 容器算法模板 |
| qtcassert.h | ~50 | QTC_ASSERT断言宏 |
| qtcassert.cpp | ~30 | 断言实现 |
| stringutils.h | ~80 | 字符串工具 |
| stringutils.cpp | ~200 | 字符串工具实现 |
| executeondestruction.h | ~40 | RAII析构执行器 |
| benchmarker.h | ~30 | 性能计时 |
| benchmarker.cpp | ~50 | 计时实现 |
| optional.h | ~20 | optional包装 |
| porting.h | ~20 | Qt版本兼容 |
| mapreduce/ (目录) | ~500 | 异步MapReduce框架 |

**第二层：CorePlugin 依赖（按编译需求添加）**

| 文件/目录 | 行数估算 | 被依赖原因 |
|-----------|---------|-----------|
| hostosinfo.h | ~120 | 操作系统检测 |
| osspecificaspects.h | ~80 | 平台差异 |
| theme/ (目录) | ~2,000 | 主题系统 |
| icon.h / icon.cpp | ~400 | 图标管理 |
| styledbar.h / styledbar.cpp | ~200 | 样式化工具栏 |
| stylehelper.h / stylehelper.cpp | ~800 | 样式帮助器 |
| fancymainwindow.h / fancymainwindow.cpp | ~600 | 高级主窗口 |
| proxyaction.h / proxyaction.cpp | ~300 | 代理动作 |
| savefile.h / savefile.cpp | ~200 | 安全文件写入 |
| fileutils.h / fileutils.cpp | ~1,200 | 文件操作 |
| filepath.h / filepath.cpp | ~800 | 文件路径 |
| mimetypes/ (目录) | ~3,000 | MIME类型 |
| touchbar/ (目录) | ~200 | macOS触摸栏 |
| qtcolorbutton.h / qtcolorbutton.cpp | ~200 | 颜色按钮控件 |
| historycompleter.h / historycompleter.cpp | ~200 | 历史补全 |
| appmainwindow.h / appmainwindow.cpp | ~100 | 应用主窗口基类 |
| completinglineedit.h / completinglineedit.cpp | ~100 | 补全行编辑器 |
| itemviews.h / itemviews.cpp | ~100 | 列表/树视图基类 |
| treemodel.h / treemodel.cpp | ~800 | 树模型 |
| categorysortfiltermodel.h / .cpp | ~200 | 分类排序模型 |
| utils.pro / utils-lib.pri | ~100 | 构建配置 |
| utils_dependencies.pri | ~5 | 依赖声明 |

**【注意】第二层文件会在编译过程中逐步确定。基本策略是：先编译，遇到缺失引用再添加。**

### 4.6 src/shared/ 保留文件

| 目录/文件 | 说明 |
|-----------|------|
| qtsingleapplication/ | 单实例应用（全部保留） |
| qtlockedfile/ | 文件锁（全部保留） |
| registryaccess/ | Windows注册表（保留） |
| qtcreator_gui_pch.h | GUI预编译头（保留） |
| qtcreator_pch.h | 通用预编译头（保留） |
| shared.pro | 共享代码构建（需修改） |

### 4.7 src/plugins/coreplugin/ 精简保留

**【重要】CorePlugin 是最复杂的裁剪对象，需要精确操作。**

**保留的核心文件（约30个）：**

| 文件 | 说明 | 修改程度 |
|------|------|---------|
| coreplugin.pro | 构建配置 | 大幅修改 |
| coreplugin_dependencies.pri | 依赖声明 | 无修改 |
| Core.json.in | 元数据模板 | 修改描述 |
| coreplugin.h | 插件入口类 | 中度修改 |
| coreplugin.cpp | 插件入口实现 | 大幅修改 |
| icore.h | 核心接口 | 中度修改 |
| icore.cpp | 核心接口实现 | 大幅修改 |
| mainwindow.h | 主窗口 | 大幅修改 |
| mainwindow.cpp | 主窗口实现 | 大幅修改 |
| icontext.h | 上下文接口 | 无修改 |
| icontext.cpp | 上下文实现 | 无修改 |
| imode.h | 模式接口 | 无修改 |
| imode.cpp | 模式实现 | 无修改 |
| modemanager.h | 模式管理器 | 无修改 |
| modemanager.cpp | 模式管理器实现 | 无修改 |
| modemanager_p.h | 模式管理私有 | 无修改 |
| actionmanager/actionmanager.h | Action管理器 | 无修改 |
| actionmanager/actionmanager.cpp | Action管理器实现 | 微调 |
| actionmanager/actionmanager_p.h | Action管理私有 | 无修改 |
| actionmanager/actioncontainer.h | Action容器 | 无修改 |
| actionmanager/actioncontainer.cpp | Action容器实现 | 无修改 |
| actionmanager/actioncontainer_p.h | Action容器私有 | 无修改 |
| actionmanager/command.h | 命令接口 | 无修改 |
| actionmanager/command.cpp | 命令实现 | 无修改 |
| actionmanager/command_p.h | 命令私有 | 无修改 |
| actionmanager/commandbutton.h | 命令按钮 | 无修改 |
| actionmanager/commandbutton.cpp | 命令按钮实现 | 无修改 |
| ioutputpane.h | 输出面板接口 | 无修改 |
| ioutputpane.cpp | 输出面板实现 | 无修改 |
| inavigationwidgetfactory.h | 导航工厂 | 无修改 |
| inavigationwidgetfactory.cpp | 导航工厂实现 | 无修改 |
| navigationwidget.h | 导航控件 | 微调 |
| navigationwidget.cpp | 导航控件实现 | 微调 |
| sidebar.h | 侧边栏 | 无修改 |
| sidebar.cpp | 侧边栏实现 | 无修改 |
| outputpanemanager.h | 输出面板管理 | 微调 |
| outputpanemanager.cpp | 输出面板管理实现 | 微调 |
| statusbarmanager.h | 状态栏管理 | 无修改 |
| statusbarmanager.cpp | 状态栏管理实现 | 无修改 |
| settingsdialog.h | 设置对话框 | 微调 |
| settingsdialog.cpp | 设置对话框实现 | 微调 |
| idialog.h | 对话框接口 | 无修改 |
| generalsettings.h | 通用设置 | 保留 |
| generalsettings.cpp | 通用设置实现 | 保留 |
| fancytabwidget.h | 标签页控件 | 无修改 |
| fancytabwidget.cpp | 标签页控件实现 | 无修改 |
| fancyactionbar.h | 操作栏 | 无修改 |
| fancyactionbar.cpp | 操作栏实现 | 无修改 |
| manhattanstyle.h | Manhattan风格 | 无修改 |
| manhattanstyle.cpp | Manhattan风格实现 | 无修改 |
| minisplitter.h | 迷你分割器 | 无修改 |
| minisplitter.cpp | 迷你分割器实现 | 无修改 |
| rightpane.h | 右面板 | 保留 |
| rightpane.cpp | 右面板实现 | 保留 |
| core.qrc | 资源文件 | 需修改 |
| fancyactionbar.qrc | 操作栏资源 | 保留 |
| core_global.h | 核心导出宏 | 无修改 |
| id.h | CorePlugin的Id | 可能使用utils/id.h |
| coreconstants.h | 核心常量 | 需修改 |

### 4.8 src/plugins/helloworld/ 完整保留

| 文件 | 说明 |
|------|------|
| helloworld.pro | 构建配置 |
| helloworld_dependencies.pri | 依赖声明（需修改，移除TextEditor依赖） |
| HelloWorld.json.in | 元数据模板 |
| helloworldplugin.h | 插件头文件 |
| helloworldplugin.cpp | 插件实现 |
| helloworldwindow.h | 窗口头文件 |
| helloworldwindow.cpp | 窗口实现 |

### 4.9 构建系统文件保留

| 文件 | 说明 | 操作 |
|------|------|------|
| src/src.pro | 子目录列表 | 需修改 |
| src/libs/libs.pro | 库列表 | 需修改 |
| src/plugins/plugins.pro | 插件列表 | 需修改 |
| src/qtcreatorplugin.pri | 插件模板 | 需微调 |
| src/qtcreatorlibrary.pri | 库模板 | 无修改 |
| src/rpath.pri | 运行路径 | 无修改 |

---

## 第五章 裁剪方案——需要删除的文件清单

**【重要】按目录批量删除。先删除大目录，再处理散落的文件。**

### 5.1 完整删除的 src/libs/ 子目录

以下17个库目录**全部删除**（连同所有子目录和文件）：

| 序号 | 目录 | 文件数估算 | 说明 |
|------|------|-----------|------|
| 1 | src/libs/cplusplus/ | ~100 | C++前端 |
| 2 | src/libs/qmljs/ | ~80 | QML/JS前端 |
| 3 | src/libs/languageserverprotocol/ | ~60 | LSP协议 |
| 4 | src/libs/clangsupport/ | ~50 | Clang支持 |
| 5 | src/libs/ssh/ | ~40 | SSH客户端 |
| 6 | src/libs/sqlite/ | ~30 | SQLite封装 |
| 7 | src/libs/glsl/ | ~30 | GLSL解析器 |
| 8 | src/libs/languageutils/ | ~15 | 语言工具 |
| 9 | src/libs/qmldebug/ | ~20 | QML调试 |
| 10 | src/libs/qmleditorwidgets/ | ~15 | QML编辑控件 |
| 11 | src/libs/tracing/ | ~30 | 性能追踪 |
| 12 | src/libs/modelinglib/ | ~50 | 建模引擎 |
| 13 | src/libs/advanceddockingsystem/ | ~30 | 停靠系统 |
| 14 | src/libs/3rdparty/cplusplus/ | ~20 | 第三方C++ |
| 15 | src/libs/3rdparty/json/ | ~5 | 第三方JSON |
| 16 | src/libs/3rdparty/yaml-cpp/ | ~40 | 第三方YAML |
| 17 | src/libs/3rdparty/syntax-highlighting/ | ~100 | 语法高亮 |

**删除命令参考**：
```bash
cd src/libs/
rm -rf cplusplus qmljs languageserverprotocol clangsupport ssh sqlite glsl \
       languageutils qmldebug qmleditorwidgets tracing modelinglib \
       advanceddockingsystem
cd 3rdparty/
rm -rf cplusplus json yaml-cpp syntax-highlighting
```

**【注意】** 删除前先确认 `3rdparty/optional/`、`3rdparty/variant/`、`3rdparty/span/` 是否被 utils 引用，如果是则保留。

### 5.2 完整删除的 src/plugins/ 子目录

以下68个插件目录**全部删除**：

| 序号 | 目录 | 说明 |
|------|------|------|
| 1 | android/ | Android支持 |
| 2 | autotest/ | 自动测试 |
| 3 | autotoolsprojectmanager/ | Autotools项目 |
| 4 | baremetal/ | 嵌入式 |
| 5 | bazaar/ | Bazaar版本控制 |
| 6 | beautifier/ | 代码美化 |
| 7 | bineditor/ | 二进制编辑器 |
| 8 | bookmarks/ | 书签 |
| 9 | boot2qt/ | Boot2Qt |
| 10 | clangcodemodel/ | Clang代码模型 |
| 11 | clangformat/ | Clang格式化 |
| 12 | clangpchmanager/ | Clang预编译头 |
| 13 | clangrefactoring/ | Clang重构 |
| 14 | clangtools/ | Clang工具 |
| 15 | classview/ | 类视图 |
| 16 | clearcase/ | ClearCase版本控制 |
| 17 | compilationdatabaseprojectmanager/ | 编译数据库项目 |
| 18 | cpaster/ | 代码粘贴 |
| 19 | cppcheck/ | CppCheck |
| 20 | cppeditor/ | C++编辑器 |
| 21 | cpptools/ | C++工具 |
| 22 | ctfvisualizer/ | CTF可视化 |
| 23 | cvs/ | CVS版本控制 |
| 24 | debugger/ | 调试器 |
| 25 | designer/ | Qt Designer |
| 26 | diffeditor/ | 差异编辑器 |
| 27 | emacskeys/ | Emacs快捷键 |
| 28 | fakevim/ | Vim模拟 |
| 29 | genericprojectmanager/ | 通用项目 |
| 30 | git/ | Git版本控制 |
| 31 | glsleditor/ | GLSL编辑器 |
| 32 | help/ | 帮助系统 |
| 33 | imageviewer/ | 图片查看 |
| 34 | incredibuild/ | IncrediBuild |
| 35 | ios/ | iOS支持 |
| 36 | languageclient/ | 语言客户端 |
| 37 | macros/ | 宏录制 |
| 38 | marketplace/ | 市场 |
| 39 | mcusupport/ | MCU支持 |
| 40 | mercurial/ | Mercurial版本控制 |
| 41 | mesonprojectmanager/ | Meson项目 |
| 42 | modeleditor/ | 模型编辑器 |
| 43 | nim/ | Nim语言 |
| 44 | perforce/ | Perforce版本控制 |
| 45 | perfprofiler/ | 性能分析 |
| 46 | projectexplorer/ | 项目管理 |
| 47 | python/ | Python支持 |
| 48 | qmakeprojectmanager/ | QMake项目 |
| 49 | qmldesigner/ | QML设计器 |
| 50 | qmljseditor/ | QML/JS编辑器 |
| 51 | qmljstools/ | QML/JS工具 |
| 52 | qmlpreview/ | QML预览 |
| 53 | qmlprofiler/ | QML分析 |
| 54 | qmlprojectmanager/ | QML项目 |
| 55 | qnx/ | QNX支持 |
| 56 | qtsupport/ | Qt支持 |
| 57 | remotelinux/ | 远程Linux |
| 58 | resourceeditor/ | 资源编辑器 |
| 59 | scxmleditor/ | SCXML编辑器 |
| 60 | serialterminal/ | 串口终端 |
| 61 | silversearcher/ | 搜索工具 |
| 62 | studiowelcome/ | Studio欢迎页 |
| 63 | subversion/ | SVN版本控制 |
| 64 | tasklist/ | 任务列表 |
| 65 | texteditor/ | 文本编辑器 |
| 66 | todo/ | TODO标记 |
| 67 | updateinfo/ | 更新信息 |
| 68 | valgrind/ | Valgrind |
| 69 | vcsbase/ | 版本控制基础 |
| 70 | webassembly/ | WebAssembly |
| 71 | welcome/ | 欢迎页 |
| 72 | winrt/ | WinRT |

**删除命令参考**：
```bash
cd src/plugins/
# 保留 coreplugin 和 helloworld，删除其余所有
ls | grep -v -E '^(coreplugin|helloworld|plugins.pro)$' | xargs rm -rf
```

### 5.3 完整删除的 src/tools/ 目录

`src/tools/` 目录下的28个工具程序**全部删除**。

```bash
rm -rf src/tools/
```

### 5.4 完整删除的 src/shared/ 子目录

删除以下子目录（保留 qtsingleapplication、qtlockedfile、registryaccess、pch头文件）：

```bash
cd src/shared/
rm -rf proparser json cpaster help designerintegrationv2 modeltest syntax yaml-cpp
```

### 5.5 tests/ 目录处理

```bash
# 删除大部分测试，只保留 extensionsystem 的测试
cd tests/
# 保留 auto/extensionsystem/  如果存在
# 其余全部删除
```

### 5.6 share/ 目录处理

share/ 目录包含运行时资源，大量是IDE专用的：

```bash
cd share/qtcreator/
# 保留: themes/ (主题文件)
# 删除: snippets/, templates/, debugger/, qmldesigner/, 
#        qml/, cplusplus/, modeleditor/, 等
```

### 5.7 删除后的目录结构

```
qt-creator-opensource-src-4.13.3/
├── qtcreator.pro              (已修改)
├── qtcreator.pri              (已修改)
├── qtcreator_ide_branding.pri (已修改)
├── qtcreatordata.pri          (无变化)
├── src/
│   ├── src.pro                (已修改)
│   ├── app/
│   │   ├── app.pro            (已修改)
│   │   ├── main.cpp           (已重写)
│   │   └── app_version.h.in   (已修改)
│   ├── libs/
│   │   ├── libs.pro           (已修改)
│   │   ├── extensionsystem/   (无变化，完整保留)
│   │   ├── aggregation/       (无变化，完整保留)
│   │   └── utils/             (精简后保留)
│   ├── plugins/
│   │   ├── plugins.pro        (已修改)
│   │   ├── coreplugin/        (大幅精简)
│   │   └── helloworld/        (保留参考)
│   ├── shared/
│   │   ├── qtsingleapplication/
│   │   ├── qtlockedfile/
│   │   ├── registryaccess/
│   │   └── qtcreator_gui_pch.h
│   ├── qtcreatorplugin.pri    (微调)
│   ├── qtcreatorlibrary.pri   (无变化)
│   └── rpath.pri              (无变化)
├── share/
│   └── qtcreator/
│       └── themes/            (保留主题)
└── scripts/                   (按需保留)
```

---

## 第六章 裁剪方案——需要修改的文件逐行操作

**【重要】本章是实施裁剪的核心，按文件逐一说明具体的增删改操作。每个操作都标注了精确的行号范围。**

### 6.1 修改 qtcreator_ide_branding.pri

**文件**: `qtcreator_ide_branding.pri`  
**原始行数**: 16行  
**操作**: 修改品牌信息

**【重要】逐行修改：**

```
原始第1行: QTCREATOR_VERSION = 4.13.3
修改为:    QTCREATOR_VERSION = 1.0.0    ← 改为自己的版本号

原始第2行: QTCREATOR_COMPAT_VERSION = 4.13.0
修改为:    QTCREATOR_COMPAT_VERSION = 1.0.0

原始第3行: QTCREATOR_DISPLAY_VERSION = 4.13.3
修改为:    QTCREATOR_DISPLAY_VERSION = 1.0.0

原始第4行: QTCREATOR_COPYRIGHT_YEAR = 2020
修改为:    QTCREATOR_COPYRIGHT_YEAR = 2025    ← 改为当前年份

原始第6行: IDE_DISPLAY_NAME = Qt Creator
修改为:    IDE_DISPLAY_NAME = MyApp    ← 改为自己的应用名

原始第7行: IDE_ID = qtcreator
修改为:    IDE_ID = myapp    ← 改为自己的应用ID（小写）

原始第8行: IDE_CASED_ID = QtCreator
修改为:    IDE_CASED_ID = MyApp    ← 改为自己的应用ID（驼峰）

原始第10行: PRODUCT_BUNDLE_ORGANIZATION = org.qt-project
修改为:     PRODUCT_BUNDLE_ORGANIZATION = com.mycompany    ← 改为自己的组织

原始第11行: PROJECT_USER_FILE_EXTENSION = .user
保持不变（或改为自己的扩展名）

删除第13-16行（文档相关配置）
```

**修改后完整内容**：
```
QTCREATOR_VERSION = 1.0.0
QTCREATOR_COMPAT_VERSION = 1.0.0
QTCREATOR_DISPLAY_VERSION = 1.0.0
QTCREATOR_COPYRIGHT_YEAR = 2025

IDE_DISPLAY_NAME = MyApp
IDE_ID = myapp
IDE_CASED_ID = MyApp

PRODUCT_BUNDLE_ORGANIZATION = com.mycompany
PROJECT_USER_FILE_EXTENSION = .user
```

### 6.2 修改 qtcreator.pro

**文件**: `qtcreator.pro`  
**原始行数**: 90行  
**操作**: 简化根工程

**逐行修改：**

```
>>> 原始第1-5行（保持不变）<<<
include(qtcreator.pri)

>>> 原始第7-8行 <<<
原始: TEMPLATE  = subdirs
原始: CONFIG   += ordered
保持不变

>>> 原始第10-16行 <<<
原始: SUBDIRS = src share
原始: unix:!macx:!isEmpty(copydata):SUBDIRS += bin
原始: !isEmpty(BUILD_TESTS):SUBDIRS += tests
修改为:
SUBDIRS = src
# share 子目录按需启用
# !isEmpty(copydata):SUBDIRS += share
```

**删除以下行**：
- 删除第18-40行的安装规则（install targets for dist/bin等）
- 保留第42-60行的平台检测逻辑
- 删除第62-90行的 `INSTALLER_ARCHIVE_FROM_ENV` 等打包逻辑

**修改后精简内容**（约20行）：
```
include(qtcreator.pri)

TEMPLATE = subdirs
CONFIG += ordered

SUBDIRS = src

# 可选：部署主题资源
# !isEmpty(copydata):SUBDIRS += share
```

### 6.3 修改 qtcreator.pri

**文件**: `qtcreator.pri`  
**原始行数**: 294行  
**操作**: 微调全局配置

**【重要】需要修改的行：**

```
>>> 第10行 <<<
原始: CONFIG += c++14
建议改为: CONFIG += c++11    ← 如果目标是MSVC2015，c++14支持不完整
【注意】MSVC2015 对 c++14 的支持有限，建议改为 c++11

>>> 第62-66行 <<<
原始: darwin:!minQtVersion(5, 7, 0) {
       QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.8
      }
保持不变（仅影响macOS）

>>> 第68-86行（测试配置）<<<
如果不需要测试，可以注释掉：
原始第83行: equals(TEST, 1) {
原始第84行:     QT +=testlib
原始第85行:     DEFINES += WITH_TESTS
原始第86行: }
【可选】保留或注释

>>> 第165-168行（路径定义）<<<
原始: DEFINES += $$shell_quote(RELATIVE_PLUGIN_PATH=\"$$RELATIVE_PLUGIN_PATH\")
原始: DEFINES += $$shell_quote(RELATIVE_LIBEXEC_PATH=\"$$RELATIVE_LIBEXEC_PATH\")
原始: DEFINES += $$shell_quote(RELATIVE_DATA_PATH=\"$$RELATIVE_DATA_PATH\")
原始: DEFINES += $$shell_quote(RELATIVE_DOC_PATH=\"$$RELATIVE_DOC_PATH\")
保持不变（这些路径定义被 app/main.cpp 使用）

>>> 第210-217行（Qt Creator专用宏定义）<<<
原始: DEFINES += \
    QT_CREATOR \
    QT_NO_JAVA_STYLE_ITERATORS \
    QT_NO_CAST_TO_ASCII \
    QT_RESTRICTED_CAST_FROM_ASCII \
    QT_DISABLE_DEPRECATED_BEFORE=0x050900 \
    QT_USE_FAST_OPERATOR_PLUS \
    QT_USE_FAST_CONCATENATION

修改: 如果使用Qt 5.6.3，QT_DISABLE_DEPRECATED_BEFORE 值需要调低：
    QT_DISABLE_DEPRECATED_BEFORE=0x050600    ← 改为 Qt 5.6
```

**其余行保持不变**。qtcreator.pri 中的依赖解析机制（第245-294行）是关键基础设施，不要动。

### 6.4 修改 src/src.pro

**文件**: `src/src.pro`  
**原始行数**: 约16行  
**操作**: 精简子目录列表

**原始内容**：
```
TEMPLATE = subdirs
CONFIG += ordered

SUBDIRS = shared libs app plugins tools \
          share/qtcreator/data.pro \
          share/3rdparty/data.pro
```

**修改为**：
```
TEMPLATE = subdirs
CONFIG += ordered

SUBDIRS = shared libs app plugins
```

**删除**: `tools`、`share/qtcreator/data.pro`、`share/3rdparty/data.pro`

### 6.5 修改 src/libs/libs.pro

**文件**: `src/libs/libs.pro`  
**原始行数**: 72行  
**操作**: 大幅精简库列表

**原始内容**（关键行）：
```
SUBDIRS = \
    aggregation \
    extensionsystem \
    utils \
    languageutils \
    cplusplus \
    modelinglib \
    qmljs \
    qmldebug \
    qmleditorwidgets \
    glsl \
    ssh \
    clangsupport \
    languageserverprotocol \
    sqlite
```

**修改为**：
```
SUBDIRS = \
    aggregation \
    extensionsystem \
    utils
```

**删除所有依赖关系配置行**（原始约50行的条件编译和依赖声明），只保留：
```
TEMPLATE = subdirs

SUBDIRS = \
    aggregation \
    extensionsystem \
    utils

# 依赖顺序
utils.depends = 
aggregation.depends = 
extensionsystem.depends = aggregation utils
```

### 6.6 修改 src/plugins/plugins.pro

**文件**: `src/plugins/plugins.pro`  
**原始行数**: 134行  
**操作**: 大幅精简，只保留2个插件

**原始内容**（列出了70+个插件的SUBDIRS和依赖关系）

**修改为**：
```
TEMPLATE = subdirs

SUBDIRS = \
    coreplugin \
    helloworld

# 依赖声明
helloworld.depends = coreplugin
```

### 6.7 修改 src/shared/shared.pro

**文件**: `src/shared/shared.pro`  
**操作**: 只保留需要的共享代码

**修改为**：
```
TEMPLATE = subdirs

SUBDIRS = \
    qtsingleapplication \
    qtlockedfile
```

### 6.8 修改 src/app/app_version.h.in

**文件**: `src/app/app_version.h.in`  
**操作**: 修改应用名称和版本宏

**需要修改的行**：
```
原始: #define IDE_VERSION_STR      "$$QTCREATOR_VERSION"
保持（宏值自动从.pri注入）

原始: #define IDE_DISPLAY_NAME     "$$IDE_DISPLAY_NAME"
保持（宏值自动从.pri注入）

原始: 其他宏定义...
保持
```

**结论**: 如果修改了 `qtcreator_ide_branding.pri`，这个文件自动获得正确的值，无需手动修改。

### 6.9 【重要】重写 src/app/main.cpp

**文件**: `src/app/main.cpp`  
**原始行数**: 741行  
**操作**: 大幅重写，只保留插件系统初始化核心流程

**新版 main.cpp 的完整内容**（约200行，替换原始741行）：

```cpp
/**
 * MyApp - 基于Qt Creator插件框架的定制化应用
 * 
 * 从 Qt Creator 4.13.3 裁剪而来
 */

#include "app_version.h"

#include <extensionsystem/iplugin.h>
#include <extensionsystem/pluginerroroverview.h>
#include <extensionsystem/pluginmanager.h>
#include <extensionsystem/pluginspec.h>

#include <QApplication>
#include <QDir>
#include <QFileInfo>
#include <QLibraryInfo>
#include <QLoggingCategory>
#include <QMessageBox>
#include <QSettings>
#include <QStandardPaths>
#include <QSysInfo>
#include <QTimer>
#include <QTranslator>

using namespace ExtensionSystem;

// 核心插件名称——必须与 Core.json 中的 Name 字段一致
const char corePluginNameC[] = "Core";

// 插件 IID——必须与 Q_PLUGIN_METADATA 中的 IID 一致
const char pluginIID[] = "com.mycompany.MyApp.Plugin";

// 注意：如果修改了 IID，所有插件的 Q_PLUGIN_METADATA 宏中的 IID 也必须同步修改

static void displayError(const QString &t)
{
    if (QApplication::instance()) {
        QMessageBox::critical(nullptr, QApplication::applicationName(), t);
    } else {
        qCritical("%s", qPrintable(t));
    }
}

static void displayHelpText(const QString &t)
{
    qWarning("%s", qPrintable(t));
}

static QString resourcePath()
{
    return QDir::cleanPath(QCoreApplication::applicationDirPath() 
                           + QLatin1Char('/') + RELATIVE_DATA_PATH);
}

int main(int argc, char **argv)
{
    // ========== 阶段1：Qt应用初始化 ==========
    
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling, true);
#ifdef Q_OS_WIN
    QCoreApplication::setAttribute(Qt::AA_DisableWindowContextHelpButton);
#endif

    QApplication app(argc, argv);
    
    // 设置应用属性
    app.setApplicationName(QLatin1String(IDE_DISPLAY_NAME));
    app.setApplicationVersion(QLatin1String(IDE_VERSION_LONG));
    app.setOrganizationName(QLatin1String("MyCompany"));
    app.setOrganizationDomain(QLatin1String("mycompany.com"));
    app.setWindowIcon(QIcon()); // TODO: 设置应用图标

    // ========== 阶段2：设置存储 ==========
    
    const QString settingsPath = QStandardPaths::writableLocation(
        QStandardPaths::GenericDataLocation) 
        + QLatin1String("/MyCompany/MyApp");

    QSettings *settings = new QSettings(
        QSettings::IniFormat, QSettings::UserScope,
        QLatin1String("MyCompany"), QLatin1String("MyApp"));
    
    QSettings *globalSettings = new QSettings(
        QSettings::IniFormat, QSettings::SystemScope,
        QLatin1String("MyCompany"), QLatin1String("MyApp"));

    // ========== 阶段3：插件系统初始化 ==========
    
    PluginManager pluginManager;
    PluginManager::setPluginIID(QLatin1String(pluginIID));
    PluginManager::setGlobalSettings(globalSettings);
    PluginManager::setSettings(settings);

    // 插件搜索路径
    QStringList pluginPaths;
    
    // 默认插件路径：应用程序同目录下的 plugins 子目录
    const QString appPluginPath = QDir::cleanPath(
        QCoreApplication::applicationDirPath() 
        + QLatin1Char('/') + RELATIVE_PLUGIN_PATH);
    pluginPaths << appPluginPath;
    
    // 额外的插件路径（用户自定义）
    const QString extraPluginPath = settings->value(
        QLatin1String("ExtraPluginPaths")).toString();
    if (!extraPluginPath.isEmpty()) {
        pluginPaths << extraPluginPath.split(QLatin1Char(';'));
    }
    
    PluginManager::setPluginPaths(pluginPaths);

    // ========== 阶段4：命令行参数处理 ==========
    
    const QStringList pluginArguments = app.arguments();
    
    QMap<QString, QString> foundAppOptions;
    if (pluginArguments.size() > 1) {
        QMap<QString, bool> appOptions;
        appOptions.insert(QLatin1String("-version"), false);
        appOptions.insert(QLatin1String("-help"), false);
        
        QString errorMessage;
        if (!PluginManager::parseOptions(pluginArguments, appOptions, 
                                         &foundAppOptions, &errorMessage)) {
            displayHelpText(errorMessage);
        }
    }
    
    if (foundAppOptions.contains(QLatin1String("-version"))) {
        displayHelpText(app.applicationName() + QLatin1Char(' ') 
                        + app.applicationVersion());
        return 0;
    }
    
    if (foundAppOptions.contains(QLatin1String("-help"))) {
        displayHelpText(QLatin1String("Usage: myapp [options]\n")
                        + PluginManager::serializedArguments());
        return 0;
    }

    // ========== 阶段5：验证核心插件 ==========
    
    const PluginSpecSet plugins = PluginManager::plugins();
    PluginSpec *corePlugin = nullptr;
    for (PluginSpec *spec : plugins) {
        if (spec->name() == QLatin1String(corePluginNameC)) {
            corePlugin = spec;
            break;
        }
    }
    
    if (!corePlugin) {
        const QString reason = QCoreApplication::translate("Application",
            "Could not find Core plugin '%1'! Check plugin search paths.")
            .arg(QLatin1String(corePluginNameC));
        displayError(reason);
        return 1;
    }
    
    if (corePlugin->hasError()) {
        displayError(corePlugin->errorString());
        return 1;
    }
    
    if (!corePlugin->isEffectivelyEnabled()) {
        displayError(QCoreApplication::translate("Application",
            "Core plugin '%1' is disabled.")
            .arg(QLatin1String(corePluginNameC)));
        return 1;
    }

    // ========== 阶段6：加载插件 ==========
    
    PluginManager::loadPlugins();

    // 检查加载错误
    if (PluginManager::hasError()) {
        // 显示错误概览对话框
        ExtensionSystem::PluginErrorOverview errorOverview(nullptr);
        errorOverview.exec();
    }

    // ========== 阶段7：启动主事件循环 ==========
    
    // 连接退出信号
    QObject::connect(&app, &QCoreApplication::aboutToQuit,
                     &pluginManager, &PluginManager::shutdown);

    // 进入事件循环
    const int r = app.exec();
    
    // 清理
    delete settings;
    delete globalSettings;
    
    return r;
}
```

**【重要】新旧对比：**

| 特性 | 原始main.cpp | 新main.cpp |
|------|-------------|-----------|
| 行数 | 741 | ~200 |
| 单实例检测 | 有(QtSingleApplication) | 无（简化版先去掉） |
| 崩溃处理 | 有(crashHandler) | 无 |
| DPI处理 | 复杂检测逻辑 | 简单属性设置 |
| 远程参数 | 有 | 无 |
| 翻译加载 | 有 | 无（后续添加） |
| 环境变量处理 | 大量 | 简化 |
| 错误显示 | 内联函数 | 独立对话框 |

### 6.10 修改 src/app/app.pro

**文件**: `src/app/app.pro`  
**操作**: 精简依赖

**原始内容**会包含对各种库的引用，修改为：

```
include(../qtcreatortool.pri)

QT += widgets

HEADERS += \
    app_version.h

SOURCES += \
    main.cpp

# 依赖库
QTC_LIB_DEPENDS += extensionsystem

# Windows图标
win32: RC_FILE = app.rc
# macOS图标
macx: ICON = app.icns

TARGET = $$IDE_APP_TARGET
DESTDIR = $$IDE_APP_PATH

TEMPLATE = app
```

### 6.11 【重要】修改 CorePlugin

**这是裁剪中最复杂的部分。CorePlugin 原有278个源文件，需要精简到约30个。**

#### 6.11.1 修改 coreplugin.pro

**文件**: `src/plugins/coreplugin/coreplugin.pro`  
**原始行数**: 278行  
**操作**: 大幅删减

**新版 coreplugin.pro**（约60行，从278行精简）：

```
# 定义导出宏
DEFINES += CORE_LIBRARY

# Qt模块
QT += widgets

# 使用插件模板
include(../../qtcreatorplugin.pri)

# MSVC警告
msvc: QMAKE_CXXFLAGS += -wd4251 -wd4290 -wd4250

# === 头文件 ===
HEADERS += \
    core_global.h \
    coreconstants.h \
    coreplugin.h \
    icore.h \
    icontext.h \
    imode.h \
    ioutputpane.h \
    inavigationwidgetfactory.h \
    mainwindow.h \
    modemanager.h \
    modemanager_p.h \
    navigationwidget.h \
    outputpanemanager.h \
    sidebar.h \
    statusbarmanager.h \
    fancytabwidget.h \
    fancyactionbar.h \
    manhattanstyle.h \
    minisplitter.h \
    rightpane.h \
    settingsdialog.h \
    generalsettings.h \
    actionmanager/actionmanager.h \
    actionmanager/actionmanager_p.h \
    actionmanager/actioncontainer.h \
    actionmanager/actioncontainer_p.h \
    actionmanager/command.h \
    actionmanager/command_p.h \
    actionmanager/commandbutton.h

# === 源文件 ===
SOURCES += \
    coreplugin.cpp \
    icore.cpp \
    icontext.cpp \
    imode.cpp \
    ioutputpane.cpp \
    inavigationwidgetfactory.cpp \
    mainwindow.cpp \
    modemanager.cpp \
    navigationwidget.cpp \
    outputpanemanager.cpp \
    sidebar.cpp \
    statusbarmanager.cpp \
    fancytabwidget.cpp \
    fancyactionbar.cpp \
    manhattanstyle.cpp \
    minisplitter.cpp \
    rightpane.cpp \
    settingsdialog.cpp \
    generalsettings.cpp \
    actionmanager/actionmanager.cpp \
    actionmanager/actioncontainer.cpp \
    actionmanager/command.cpp \
    actionmanager/commandbutton.cpp

# === 表单 ===
FORMS += \
    generalsettings.ui

# === 资源 ===
RESOURCES += \
    core.qrc \
    fancyactionbar.qrc
```

#### 6.11.2 修改 coreplugin.h

**文件**: `src/plugins/coreplugin/coreplugin.h`  
**原始行数**: ~80行  
**操作**: 删除对已移除子系统的引用

**需要删除的内容**：
- 删除 `#include` 中对 Locator、Find、EditMode 等的前向声明
- 删除私有成员中对这些子系统的指针

**修改后**：
```cpp
#pragma once

#include <extensionsystem/iplugin.h>

namespace Core {
namespace Internal {

class MainWindow;

class CorePlugin : public ExtensionSystem::IPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.mycompany.MyApp.Plugin" FILE "Core.json")

public:
    CorePlugin();
    ~CorePlugin() override;

    static CorePlugin *instance();

    bool initialize(const QStringList &arguments, QString *errorMessage) override;
    void extensionsInitialized() override;
    bool delayedInitialize() override;
    ShutdownFlag aboutToShutdown() override;

private:
    MainWindow *m_mainWindow = nullptr;
};

} // namespace Internal
} // namespace Core
```

**【注意】** Q_PLUGIN_METADATA 中的 IID 必须改为与 main.cpp 中 `pluginIID` 一致的值。

#### 6.11.3 修改 coreplugin.cpp

**文件**: `src/plugins/coreplugin/coreplugin.cpp`  
**原始行数**: ~300行  
**操作**: 大幅精简

**需要删除的内容**：
- 删除对 Locator、Find、EditMode、DesignMode、IWizardFactory 等的引用
- 删除 ThemeEntry 相关代码（简化主题加载）
- 删除对已删除插件的交互代码

**修改后的核心逻辑**：
```cpp
#include "coreplugin.h"
#include "mainwindow.h"
#include "icore.h"

#include <extensionsystem/pluginmanager.h>

namespace Core {
namespace Internal {

static CorePlugin *m_instance = nullptr;

CorePlugin::CorePlugin()
{
    m_instance = this;
}

CorePlugin::~CorePlugin()
{
    delete m_mainWindow;
    m_instance = nullptr;
}

CorePlugin *CorePlugin::instance()
{
    return m_instance;
}

bool CorePlugin::initialize(const QStringList &arguments, QString *errorMessage)
{
    Q_UNUSED(arguments)
    Q_UNUSED(errorMessage)

    // 创建主窗口
    m_mainWindow = new MainWindow;
    
    // 初始化核心子系统
    if (!m_mainWindow->init(errorMessage))
        return false;

    return true;
}

void CorePlugin::extensionsInitialized()
{
    // 所有插件已初始化，显示主窗口
    m_mainWindow->extensionsInitialized();
    m_mainWindow->show();
}

bool CorePlugin::delayedInitialize()
{
    return false;
}

ExtensionSystem::IPlugin::ShutdownFlag CorePlugin::aboutToShutdown()
{
    m_mainWindow->aboutToShutdown();
    return SynchronousShutdown;
}

} // namespace Internal
} // namespace Core
```

#### 6.11.4 修改 Core.json.in

**文件**: `src/plugins/coreplugin/Core.json.in`  
**操作**: 修改元数据

```json
{
    "Name" : "Core",
    "Version" : "$$QTCREATOR_VERSION",
    "CompatVersion" : "$$QTCREATOR_COMPAT_VERSION",
    "Required" : true,
    "Vendor" : "MyCompany",
    "Copyright" : "(C) $$QTCREATOR_COPYRIGHT_YEAR MyCompany",
    "License" : ["Your license here"],
    "Category" : "Core",
    "Description" : "Core plugin providing the main application framework.",
    "Url" : "https://www.mycompany.com",
    $$dependencyList
}
```

#### 6.11.5 修改 mainwindow.h

**文件**: `src/plugins/coreplugin/mainwindow.h`  
**原始行数**: ~150行  
**操作**: 大幅精简

**删除的引用**：
- EditorManager相关
- DocumentManager相关
- HelpManager相关
- VcsManager相关
- ExternalToolManager相关
- ProgressManager相关
- JsExpander相关

**修改后**：
```cpp
#pragma once

#include "icontext.h"

#include <utils/appmainwindow.h>  // 如果保留了utils中的这个类
// 或直接使用 QMainWindow:
// #include <QMainWindow>

#include <QColor>
#include <QMap>

QT_BEGIN_NAMESPACE
class QSettings;
class QToolButton;
QT_END_NAMESPACE

namespace Core {

class IMode;
class StatusBarManager;

namespace Internal {

class FancyTabWidget;
class GeneralSettings;
class StatusBarManager;

class MainWindow : public QMainWindow  // 或 Utils::AppMainWindow
{
    Q_OBJECT

public:
    MainWindow();
    ~MainWindow() override;

    bool init(QString *errorMessage);
    void extensionsInitialized();
    void aboutToShutdown();

    // 核心访问
    IContext *contextObject(QWidget *widget) const;
    void addContextObject(IContext *context);
    void removeContextObject(IContext *context);

    // 设置
    QSettings *settings(QSettings::Scope scope) const;

    // UI相关
    QStatusBar *statusBar() const;

    void openSettingsDialog(Utils::Id page);

signals:
    void newItemDialogStateChanged();

private:
    void updateContextObject(const QList<IContext *> &context);
    void readSettings();
    void saveSettings();

    // 核心子系统
    FancyTabWidget *m_modeStack = nullptr;
    StatusBarManager *m_statusBarManager = nullptr;
    GeneralSettings *m_generalSettings = nullptr;

    // 上下文管理
    QMap<QWidget *, IContext *> m_contextWidgets;
    IContext *m_activeContext = nullptr;
    QList<IContext *> m_additionalContexts;
};

} // namespace Internal
} // namespace Core
```

#### 6.11.6 修改 mainwindow.cpp

**文件**: `src/plugins/coreplugin/mainwindow.cpp`  
**原始行数**: ~1,200行  
**操作**: 大幅精简

**原始 MainWindow::MainWindow() 构造函数**涉及大量子系统初始化：
- 第80-85行: 创建 ActionManager
- 第90行: 创建 EditorManager
- 第95行: 创建 DocumentManager
- 第100行: 创建 ProgressManager
- ...等20+个子系统

**精简后构造函数**：
```cpp
MainWindow::MainWindow()
{
    // 设置窗口属性
    setWindowTitle(QLatin1String(IDE_DISPLAY_NAME));
    setDockNestingEnabled(true);

    // 创建核心UI组件
    m_modeStack = new FancyTabWidget(this);
    setCentralWidget(m_modeStack);
    
    // 创建Action管理器
    // ActionManager 是单例，在构造时自动初始化
    
    // 创建状态栏
    m_statusBarManager = new StatusBarManager(this);
    
    // 创建设置页面
    m_generalSettings = new GeneralSettings;
    
    // 读取上次保存的窗口状态
    readSettings();
}
```

**精简后 init() 方法**：
```cpp
bool MainWindow::init(QString *errorMessage)
{
    Q_UNUSED(errorMessage)
    
    // 注册核心Action（菜单项）
    // File 菜单
    ActionManager::createMenu("MyApp.Menu.File");
    // Edit 菜单  
    ActionManager::createMenu("MyApp.Menu.Edit");
    // Tools 菜单
    ActionManager::createMenu("MyApp.Menu.Tools");
    // Help 菜单
    ActionManager::createMenu("MyApp.Menu.Help");
    
    // 注册核心快捷键
    // Ctrl+Q = 退出
    // Ctrl+, = 设置
    
    return true;
}
```

#### 6.11.7 修改 icore.h 和 icore.cpp

ICore 是全局服务入口，需要精简但保持核心接口。

**保留的接口**：
```cpp
class CORE_EXPORT ICore : public QObject
{
    Q_OBJECT
    
public:
    static ICore *instance();
    
    // 设置
    static QSettings *settings(QSettings::Scope scope = QSettings::UserScope);
    
    // 主窗口访问
    static QMainWindow *mainWindow();
    static QWidget *dialogParent();
    
    // 设置对话框
    static bool showOptionsDialog(Utils::Id page, QWidget *parent = nullptr);
    
    // 路径
    static QString resourcePath();
    static QString userResourcePath();
    
    // 上下文管理
    static void addContextObject(IContext *context);
    static void removeContextObject(IContext *context);
    
signals:
    void coreAboutToOpen();
    void coreOpened();
    void coreAboutToClose();
    void contextChanged(const Core::Context &context);
    void saveSettingsRequested();
};
```

**删除的接口**：
- `showNewItemDialog()` — 文件向导
- `printer()` — 打印
- `openFiles()` — 文件打开
- `newItemDialog()` — 新建对话框
- 所有VCS相关接口
- 所有Editor相关接口

#### 6.11.8 修改 coreconstants.h

**文件**: `src/plugins/coreplugin/coreconstants.h`  
**操作**: 修改常量前缀

```cpp
// 原始:
namespace Core {
namespace Constants {
    const char MODE_WELCOME[]     = "Welcome";
    const char MODE_EDIT[]        = "Edit";
    const char MODE_DESIGN[]      = "Design";
    ...
}
}

// 修改为:
namespace Core {
namespace Constants {
    // 模式ID
    const char MODE_WELCOME[]     = "Welcome";
    
    // 菜单ID
    const char MENU_BAR[]         = "MyApp.MenuBar";
    const char M_FILE[]           = "MyApp.Menu.File";
    const char M_EDIT[]           = "MyApp.Menu.Edit";
    const char M_TOOLS[]          = "MyApp.Menu.Tools";
    const char M_HELP[]           = "MyApp.Menu.Help";
    
    // 动作ID
    const char EXIT[]             = "MyApp.Exit";
    const char OPTIONS[]          = "MyApp.Options";
    const char ABOUT[]            = "MyApp.About";
    
    // 设置分类
    const char SETTINGS_CATEGORY_CORE[] = "A.Core";
    
    // 图标资源
    const char ICON_LOGO[]        = ":/core/images/logo.png";
}
}
```

### 6.12 修改 HelloWorld 插件

#### 6.12.1 修改 helloworld_dependencies.pri

**原始**：
```
QTC_PLUGIN_NAME = HelloWorld
QTC_LIB_DEPENDS += \
    extensionsystem
QTC_PLUGIN_DEPENDS += \
    coreplugin \
    texteditor
```

**修改为**（删除 texteditor 依赖）：
```
QTC_PLUGIN_NAME = HelloWorld
QTC_LIB_DEPENDS += \
    extensionsystem
QTC_PLUGIN_DEPENDS += \
    coreplugin
```

#### 6.12.2 修改 helloworldplugin.h

```cpp
#pragma once

#include <extensionsystem/iplugin.h>

namespace HelloWorld {
namespace Internal {

class HelloWorldPlugin : public ExtensionSystem::IPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.mycompany.MyApp.Plugin" FILE "HelloWorld.json")

public:
    bool initialize(const QStringList &arguments, QString *errorMessage) override;
    void extensionsInitialized() override;
};

} // namespace Internal
} // namespace HelloWorld
```

**【注意】** IID 必须修改为 `"com.mycompany.MyApp.Plugin"`（与main.cpp和CorePlugin一致）。

#### 6.12.3 修改 helloworldplugin.cpp

精简后只保留核心示例功能——注册一个模式和一个菜单项。

### 6.13 修改 utils 库构建配置

如果需要精简 utils 库，需要修改 `src/libs/utils/utils-lib.pri` 或创建精简版。

**策略**：
1. 先尝试完整编译 utils 库
2. 如果编译失败（因为某些文件依赖已删除的库），逐个移除出错的文件
3. 最终保留能编译通过的最小集

**预计需要从 utils-lib.pri 中删除的文件**：
- 所有与 `ssh` 相关的文件（如 `sshconnection.*`）
- 所有与 `clang` 相关的文件
- `buildablehelperlibrary.*`（依赖项目管理）
- `qtcprocess.*`（可保留，进程管理是通用的）

---

## 第七章 新建独立应用框架设计

**【重要】本章描述如何基于裁剪后的插件系统构建一个全新的、可定制化的应用程序框架。**

### 7.1 框架总体架构

```
┌──────────────────────────────────────────────────────────┐
│                     应用层 (MyApp)                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │ 插件A   │ │ 插件B   │ │ 插件C   │ │ 插件D   │ ...   │
│  │(团队1)  │ │(团队2)  │ │(团队1)  │ │(团队3)  │       │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘       │
│       │           │           │           │              │
│  ┌────┴───────────┴───────────┴───────────┴────┐        │
│  │              Core 插件 (精简版)                │        │
│  │  ┌──────────┐ ┌──────────┐ ┌───────────┐    │        │
│  │  │MainWindow│ │ActionMgr │ │ModeManager│    │        │
│  │  │ 主窗口   │ │菜单/工具栏│ │模式管理    │    │        │
│  │  └──────────┘ └──────────┘ └───────────┘    │        │
│  │  ┌──────────┐ ┌──────────┐ ┌───────────┐    │        │
│  │  │Navigation│ │OutputPane│ │StatusBar  │    │        │
│  │  │ 导航面板  │ │输出面板   │ │状态栏     │    │        │
│  │  └──────────┘ └──────────┘ └───────────┘    │        │
│  └──────────────────────────────────────────────┘        │
│                          │                                │
├──────────────────────────┼────────────────────────────────┤
│                     框架层                                 │
│  ┌──────────────┐ ┌──────────┐ ┌────────────────┐       │
│  │ExtensionSystem│ │Aggregation│ │  Utils (精简)  │       │
│  │  插件管理器   │ │ 对象聚合  │ │  工具函数库    │       │
│  └──────────────┘ └──────────┘ └────────────────┘       │
│                          │                                │
├──────────────────────────┼────────────────────────────────┤
│                     Qt 基础层                              │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐          │
│  │QtCore│ │QtGui │ │Widget│ │QtNet │ │QtSql │          │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘          │
└──────────────────────────────────────────────────────────┘
```

### 7.2 插件间通信机制

Qt Creator 的插件间通信采用 **对象池模式 (Object Pool Pattern)**，这是整个框架的核心设计。

#### 7.2.1 对象池工作原理

```
┌─────────────────────────────────────────┐
│            PluginManager                 │
│         ┌──────────────────┐            │
│         │   Object Pool    │            │
│         │ ┌──────────────┐ │            │
│         │ │ IMode*       │ │ ← 由插件A注册 │
│         │ │ IOutputPane* │ │ ← 由插件B注册 │
│         │ │ INavFactory* │ │ ← 由插件C注册 │
│         │ │ CustomSvc*   │ │ ← 由插件D注册 │
│         │ └──────────────┘ │            │
│         └──────────────────┘            │
│                                          │
│  addObject(obj)   →  添加到池中          │
│  removeObject(obj) → 从池中移除          │
│  getObject<T>()   →  按类型查询          │
│                                          │
│  信号:                                   │
│  objectAdded(obj)      → 有新对象加入    │
│  aboutToRemoveObject() → 有对象即将移除  │
└─────────────────────────────────────────┘
```

**使用示例——插件A注册服务**：
```cpp
// 在 PluginA::initialize() 中
bool PluginA::initialize(const QStringList &, QString *)
{
    // 创建并注册一个导航面板工厂
    auto navFactory = new MyNavigationFactory;
    addAutoReleasedObject(navFactory);  // 自动在卸载时移除
    
    // 创建并注册一个输出面板
    auto outputPane = new MyOutputPane;
    addAutoReleasedObject(outputPane);
    
    return true;
}
```

**使用示例——插件B消费服务**：
```cpp
// 在 PluginB::extensionsInitialized() 中
void PluginB::extensionsInitialized()
{
    // 查找所有注册的导航面板工厂
    auto factories = ExtensionSystem::PluginManager::getObjects<Core::INavigationWidgetFactory>();
    for (auto *factory : factories) {
        // 使用工厂创建导航面板
        qDebug() << "Found navigation factory:" << factory->displayName();
    }
}
```

#### 7.2.2 对象池 vs 直接依赖

| 特性 | 对象池模式 | 直接依赖模式 |
|------|-----------|-------------|
| 耦合度 | 低——只依赖接口 | 高——直接依赖实现类 |
| 插件可选性 | 支持——服务不存在则查询返回空 | 不支持——缺少依赖则编译失败 |
| 动态性 | 运行时注册/注销 | 编译时确定 |
| 类型安全 | 通过 qobject_cast 保证 | 编译时保证 |
| 适用场景 | 可选扩展点 | 核心依赖 |

### 7.3 模式系统 (Mode System)

模式是应用的顶级UI区域切换机制，类似于VSCode的侧边栏Activity Bar。

```
┌──────────────────────────────────────────────┐
│  ┌────┐                                       │
│  │模式│  ┌────────────────────────────┐       │
│  │切换│  │                            │       │
│  │ 栏 │  │      当前模式的内容区域     │       │
│  │    │  │                            │       │
│  │ W  │  │   由对应 IMode 提供 widget  │       │
│  │ E  │  │                            │       │
│  │ L  │  │                            │       │
│  │ C  │  └────────────────────────────┘       │
│  │ O  │                                       │
│  │ M  │  ┌────────────────────────────┐       │
│  │ E  │  │      输出面板区域           │       │
│  │    │  │  由 IOutputPane 提供内容    │       │
│  └────┘  └────────────────────────────┘       │
│  ┌────────────────────────────────────┐       │
│  │           状态栏                    │       │
│  └────────────────────────────────────┘       │
└──────────────────────────────────────────────┘
```

**添加新模式的方法**（在任意插件中）：

```cpp
// MyMode.h
#include <coreplugin/imode.h>

class MyMode : public Core::IMode
{
    Q_OBJECT
public:
    MyMode(QObject *parent = nullptr) : Core::IMode(parent)
    {
        setDisplayName(tr("Dashboard"));
        setIcon(QIcon(":/icons/dashboard.png"));
        setPriority(100);  // 数字越大，在列表中越靠上
        setId("MyPlugin.DashboardMode");
        
        // 创建模式内容
        auto widget = new QWidget;
        auto layout = new QVBoxLayout(widget);
        layout->addWidget(new QLabel("Welcome to Dashboard"));
        // ... 构建UI
        
        setWidget(widget);
    }
};

// 在插件 initialize() 中注册:
bool MyPlugin::initialize(...)
{
    addAutoReleasedObject(new MyMode);
    return true;
}
```

### 7.4 Action系统 (Menu/Toolbar)

ActionManager 管理所有菜单项和工具栏按钮，支持：
- 上下文敏感的动作（不同模式下同一快捷键触发不同操作）
- 可配置的快捷键
- 动作容器（菜单、工具栏）的层次组织

**在插件中注册菜单项**：
```cpp
bool MyPlugin::initialize(...)
{
    // 获取 Tools 菜单
    ActionContainer *toolsMenu = ActionManager::actionContainer(Core::Constants::M_TOOLS);
    
    // 创建动作
    auto myAction = new QAction(tr("My Tool"), this);
    
    // 注册到 ActionManager
    Command *cmd = ActionManager::registerAction(myAction, "MyPlugin.MyAction");
    cmd->setDefaultKeySequence(QKeySequence(tr("Ctrl+Shift+M")));
    
    // 添加到菜单
    toolsMenu->addAction(cmd);
    
    // 连接槽函数
    connect(myAction, &QAction::triggered, this, &MyPlugin::doSomething);
    
    return true;
}
```

### 7.5 输出面板系统 (Output Panes)

输出面板显示在主窗口底部，类似于IDE的"构建输出"、"应用输出"等。

**添加自定义输出面板**：
```cpp
// MyOutputPane.h
#include <coreplugin/ioutputpane.h>

class MyOutputPane : public Core::IOutputPane
{
    Q_OBJECT
public:
    MyOutputPane() : m_widget(nullptr) {
        // 面板默认隐藏
    }
    
    // 必须实现的接口
    QWidget *outputWidget(QWidget *parent) override {
        if (!m_widget) {
            m_widget = new QTextEdit(parent);
            m_widget->setReadOnly(true);
        }
        return m_widget;
    }
    
    QString displayName() const override { return tr("My Log"); }
    int priorityInStatusBar() const override { return 50; }
    void clearContents() override { m_widget->clear(); }
    void visibilityChanged(bool visible) override { Q_UNUSED(visible) }
    void setFocus() override { m_widget->setFocus(); }
    bool hasFocus() const override { return m_widget->hasFocus(); }
    bool canFocus() const override { return true; }
    bool canNavigate() const override { return false; }
    bool canNext() const override { return false; }
    bool canPrevious() const override { return false; }
    void goToNext() override {}
    void goToPrev() override {}
    
    // 自定义方法
    void appendMessage(const QString &msg) {
        m_widget->append(msg);
        popup(IOutputPane::NoModeSwitch);
    }

private:
    QTextEdit *m_widget;
};
```

### 7.6 导航面板系统 (Navigation Widgets)

导航面板显示在主窗口的左侧或右侧侧边栏中。

**添加自定义导航面板**：
```cpp
// MyNavigationFactory.h
#include <coreplugin/inavigationwidgetfactory.h>

class MyNavigationFactory : public Core::INavigationWidgetFactory
{
    Q_OBJECT
public:
    MyNavigationFactory()
    {
        setDisplayName(tr("Data Explorer"));
        setPriority(200);
        setId("MyPlugin.DataExplorer");
    }
    
    Core::NavigationView createWidget() override
    {
        auto treeView = new QTreeView;
        auto model = new QFileSystemModel;
        model->setRootPath(QDir::homePath());
        treeView->setModel(model);
        
        Core::NavigationView view;
        view.widget = treeView;
        // 可选：添加工具栏按钮
        // view.dockToolBarWidgets << new QToolButton(...);
        return view;
    }
};
```

### 7.7 设置系统 (Settings)

设置系统提供统一的设置对话框，每个插件可以注册自己的设置页面。

**添加自定义设置页面**（需要在CorePlugin中保留 settingsdialog 相关代码）：

设置页面的注册方式类似于其他扩展点——通过对象池注册 IOptionsPage 对象。

### 7.8 插件开发流程总结

```
1. 创建插件目录
   └── src/plugins/myplugin/

2. 创建依赖声明
   └── myplugin_dependencies.pri
       QTC_PLUGIN_NAME = MyPlugin
       QTC_LIB_DEPENDS += extensionsystem utils
       QTC_PLUGIN_DEPENDS += coreplugin

3. 创建元数据模板
   └── MyPlugin.json.in
       { "Name": "MyPlugin", "Version": "$$QTCREATOR_VERSION", ... }

4. 创建构建配置
   └── myplugin.pro
       include(../../qtcreatorplugin.pri)
       SOURCES += mypluginplugin.cpp
       HEADERS += mypluginplugin.h

5. 实现插件类
   └── mypluginplugin.h / mypluginplugin.cpp
       class MyPluginPlugin : public ExtensionSystem::IPlugin {
           Q_PLUGIN_METADATA(IID "com.mycompany.MyApp.Plugin" FILE "MyPlugin.json")
           bool initialize(...) override;
           void extensionsInitialized() override;
       };

6. 注册到 plugins.pro
   └── SUBDIRS += myplugin
       myplugin.depends = coreplugin

7. 编译运行
```

---

## 第八章 新建文件逐行内容

**【重要】本章列出所有需要新建的文件及其完整内容。**

### 8.1 新建插件模板

为了方便团队快速创建新插件，创建一个模板目录。

#### 8.1.1 新建 src/plugins/plugintemplate/

**文件**: `src/plugins/plugintemplate/plugintemplate_dependencies.pri`

```pri
# 1. QTC_PLUGIN_NAME = PluginTemplate
# 2. QTC_LIB_DEPENDS += \
# 3.     extensionsystem \
# 4.     utils
# 5. QTC_PLUGIN_DEPENDS += \
# 6.     coreplugin
```

**文件**: `src/plugins/plugintemplate/PluginTemplate.json.in`

```json
{
    "Name" : "PluginTemplate",
    "Version" : "$$QTCREATOR_VERSION",
    "CompatVersion" : "$$QTCREATOR_COMPAT_VERSION",
    "Vendor" : "MyCompany",
    "Copyright" : "(C) $$QTCREATOR_COPYRIGHT_YEAR MyCompany",
    "License" : ["Proprietary"],
    "Category" : "Utilities",
    "Description" : "A template plugin for MyApp framework.",
    "Url" : "https://www.mycompany.com",
    $$dependencyList
}
```

**文件**: `src/plugins/plugintemplate/plugintemplate.pro`

```pro
# 第1行: 使用插件构建模板
include(../../qtcreatorplugin.pri)

# 第3行: Qt模块
QT += widgets

# 第5-7行: 头文件
HEADERS += \
    plugintemplateplugin.h

# 第9-11行: 源文件
SOURCES += \
    plugintemplateplugin.cpp
```

**文件**: `src/plugins/plugintemplate/plugintemplateplugin.h`

```cpp
// 第1行
#pragma once

// 第3行
#include <extensionsystem/iplugin.h>

// 第5-7行: 命名空间
namespace PluginTemplate {
namespace Internal {

// 第9-21行: 插件类声明
class PluginTemplatePlugin : public ExtensionSystem::IPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.mycompany.MyApp.Plugin" FILE "PluginTemplate.json")

public:
    PluginTemplatePlugin() = default;

    bool initialize(const QStringList &arguments, QString *errorMessage) override;
    void extensionsInitialized() override;
    ShutdownFlag aboutToShutdown() override;
};

// 第23-24行: 关闭命名空间
} // namespace Internal
} // namespace PluginTemplate
```

**文件**: `src/plugins/plugintemplate/plugintemplateplugin.cpp`

```cpp
// 第1-2行
#include "plugintemplateplugin.h"

// 第4-5行
#include <coreplugin/icore.h>
#include <coreplugin/actionmanager/actionmanager.h>

// 第7-9行
#include <QAction>
#include <QMenu>
#include <QMessageBox>

// 第11行
namespace PluginTemplate {
namespace Internal {

// 第14-30行: initialize() 实现
bool PluginTemplatePlugin::initialize(const QStringList &arguments, QString *errorMessage)
{
    Q_UNUSED(arguments)
    Q_UNUSED(errorMessage)
    
    // 注册一个菜单项作为示例
    auto action = new QAction(tr("PluginTemplate Action"), this);
    Core::Command *cmd = Core::ActionManager::registerAction(
        action, "PluginTemplate.Action");
    cmd->setDefaultKeySequence(QKeySequence(tr("Ctrl+Alt+T")));
    
    // 添加到 Tools 菜单
    Core::ActionContainer *menu = Core::ActionManager::actionContainer(
        Core::Constants::M_TOOLS);
    if (menu)
        menu->addAction(cmd);
    
    connect(action, &QAction::triggered, this, []() {
        QMessageBox::information(Core::ICore::dialogParent(),
                                tr("PluginTemplate"),
                                tr("Hello from PluginTemplate!"));
    });
    
    return true;
}

// 第32-35行
void PluginTemplatePlugin::extensionsInitialized()
{
    // 此时所有插件已初始化，可以安全地查询其他插件的服务
}

// 第37-41行
ExtensionSystem::IPlugin::ShutdownFlag PluginTemplatePlugin::aboutToShutdown()
{
    // 保存设置、清理资源
    return SynchronousShutdown;
}

// 第43-44行
} // namespace Internal
} // namespace PluginTemplate
```

### 8.2 新建构建脚本

#### 8.2.1 新建 build.bat (Windows)

**文件**: `build.bat`

```bat
@echo off
REM MyApp 构建脚本
REM 前提：Qt 5.6.3 和 MSVC2015 已配置到 PATH

set QT_DIR=C:\Qt\5.6.3\msvc2015
set PATH=%QT_DIR%\bin;%PATH%

echo [1/3] Running qmake...
mkdir build 2>nul
cd build
qmake ..\qtcreator.pro -spec win32-msvc2015 CONFIG+=release
if errorlevel 1 goto :error

echo [2/3] Building...
nmake /NOLOGO
if errorlevel 1 goto :error

echo [3/3] Build complete!
goto :end

:error
echo BUILD FAILED!
exit /b 1

:end
echo Build output in: build\bin\
```

#### 8.2.2 新建 build.sh (Linux/macOS)

**文件**: `build.sh`

```bash
#!/bin/bash
set -e

echo "[1/3] Running qmake..."
mkdir -p build && cd build
qmake ../qtcreator.pro CONFIG+=release
echo "[2/3] Building..."
make -j$(nproc)
echo "[3/3] Build complete!"
echo "Output: build/bin/"
```

### 8.3 新建示例插件集

为展示各种扩展点的使用方法，创建以下示例插件。

#### 8.3.1 Dashboard 插件——展示 IMode 扩展

**文件**: `src/plugins/dashboard/dashboard_dependencies.pri`
```
QTC_PLUGIN_NAME = Dashboard
QTC_LIB_DEPENDS += extensionsystem utils
QTC_PLUGIN_DEPENDS += coreplugin
```

**文件**: `src/plugins/dashboard/Dashboard.json.in`
```json
{
    "Name" : "Dashboard",
    "Version" : "$$QTCREATOR_VERSION",
    "CompatVersion" : "$$QTCREATOR_COMPAT_VERSION",
    "Vendor" : "MyCompany",
    "Copyright" : "(C) $$QTCREATOR_COPYRIGHT_YEAR MyCompany",
    "License" : ["Proprietary"],
    "Category" : "UI",
    "Description" : "Provides a dashboard mode with overview panels.",
    "Url" : "https://www.mycompany.com",
    $$dependencyList
}
```

**文件**: `src/plugins/dashboard/dashboard.pro`
```pro
include(../../qtcreatorplugin.pri)
QT += widgets

HEADERS += \
    dashboardplugin.h \
    dashboardmode.h \
    dashboardwidget.h

SOURCES += \
    dashboardplugin.cpp \
    dashboardmode.cpp \
    dashboardwidget.cpp
```

**文件**: `src/plugins/dashboard/dashboardplugin.h`
```cpp
#pragma once
#include <extensionsystem/iplugin.h>

namespace Dashboard {
namespace Internal {

class DashboardMode;

class DashboardPlugin : public ExtensionSystem::IPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.mycompany.MyApp.Plugin" FILE "Dashboard.json")

public:
    bool initialize(const QStringList &arguments, QString *errorMessage) override;
    void extensionsInitialized() override;

private:
    DashboardMode *m_mode = nullptr;
};

} // namespace Internal
} // namespace Dashboard
```

**文件**: `src/plugins/dashboard/dashboardplugin.cpp`
```cpp
#include "dashboardplugin.h"
#include "dashboardmode.h"

namespace Dashboard {
namespace Internal {

bool DashboardPlugin::initialize(const QStringList &arguments, QString *errorMessage)
{
    Q_UNUSED(arguments)
    Q_UNUSED(errorMessage)
    
    m_mode = new DashboardMode(this);
    addAutoReleasedObject(m_mode);
    
    return true;
}

void DashboardPlugin::extensionsInitialized()
{
}

} // namespace Internal
} // namespace Dashboard
```

**文件**: `src/plugins/dashboard/dashboardmode.h`
```cpp
#pragma once
#include <coreplugin/imode.h>

namespace Dashboard {
namespace Internal {

class DashboardWidget;

class DashboardMode : public Core::IMode
{
    Q_OBJECT
public:
    explicit DashboardMode(QObject *parent = nullptr);
};

} // namespace Internal
} // namespace Dashboard
```

**文件**: `src/plugins/dashboard/dashboardmode.cpp`
```cpp
#include "dashboardmode.h"
#include "dashboardwidget.h"
#include <coreplugin/coreconstants.h>

namespace Dashboard {
namespace Internal {

DashboardMode::DashboardMode(QObject *parent)
    : Core::IMode(parent)
{
    setDisplayName(tr("Dashboard"));
    setIcon(QIcon(":/dashboard/images/mode_dashboard.png"));
    setPriority(90);
    setId("Dashboard.DashboardMode");
    setWidget(new DashboardWidget);
}

} // namespace Internal
} // namespace Dashboard
```

**文件**: `src/plugins/dashboard/dashboardwidget.h`
```cpp
#pragma once
#include <QWidget>

class QLabel;
class QGridLayout;

namespace Dashboard {
namespace Internal {

class DashboardWidget : public QWidget
{
    Q_OBJECT
public:
    explicit DashboardWidget(QWidget *parent = nullptr);

private:
    void setupUI();
    QGridLayout *m_layout;
};

} // namespace Internal
} // namespace Dashboard
```

**文件**: `src/plugins/dashboard/dashboardwidget.cpp`
```cpp
#include "dashboardwidget.h"
#include <QGridLayout>
#include <QLabel>
#include <QGroupBox>
#include <QDateTime>
#include <QTimer>

namespace Dashboard {
namespace Internal {

DashboardWidget::DashboardWidget(QWidget *parent)
    : QWidget(parent)
{
    setupUI();
}

void DashboardWidget::setupUI()
{
    m_layout = new QGridLayout(this);
    m_layout->setSpacing(16);
    m_layout->setContentsMargins(24, 24, 24, 24);
    
    // 欢迎区域
    auto welcomeBox = new QGroupBox(tr("Welcome"));
    auto welcomeLayout = new QVBoxLayout(welcomeBox);
    auto welcomeLabel = new QLabel(tr("Welcome to MyApp!\n\n"
        "This is the Dashboard mode, provided by the Dashboard plugin.\n"
        "You can customize this panel to show any content."));
    welcomeLabel->setWordWrap(true);
    welcomeLayout->addWidget(welcomeLabel);
    m_layout->addWidget(welcomeBox, 0, 0);
    
    // 系统信息区域
    auto sysBox = new QGroupBox(tr("System Info"));
    auto sysLayout = new QVBoxLayout(sysBox);
    auto timeLabel = new QLabel;
    sysLayout->addWidget(timeLabel);
    m_layout->addWidget(sysBox, 0, 1);
    
    // 更新时间显示
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, [timeLabel]() {
        timeLabel->setText(QDateTime::currentDateTime().toString(Qt::ISODate));
    });
    timer->start(1000);
    timeLabel->setText(QDateTime::currentDateTime().toString(Qt::ISODate));
    
    // 拉伸
    m_layout->setRowStretch(1, 1);
    m_layout->setColumnStretch(2, 1);
}

} // namespace Internal
} // namespace Dashboard
```

#### 8.3.2 LogViewer 插件——展示 IOutputPane 扩展

**文件**: `src/plugins/logviewer/logviewer_dependencies.pri`
```
QTC_PLUGIN_NAME = LogViewer
QTC_LIB_DEPENDS += extensionsystem utils
QTC_PLUGIN_DEPENDS += coreplugin
```

**文件**: `src/plugins/logviewer/LogViewer.json.in`
```json
{
    "Name" : "LogViewer",
    "Version" : "$$QTCREATOR_VERSION",
    "CompatVersion" : "$$QTCREATOR_COMPAT_VERSION",
    "Vendor" : "MyCompany",
    "Copyright" : "(C) $$QTCREATOR_COPYRIGHT_YEAR MyCompany",
    "License" : ["Proprietary"],
    "Category" : "Utilities",
    "Description" : "Provides a log viewer output pane.",
    "Url" : "https://www.mycompany.com",
    $$dependencyList
}
```

**文件**: `src/plugins/logviewer/logviewer.pro`
```pro
include(../../qtcreatorplugin.pri)
QT += widgets

HEADERS += \
    logviewerplugin.h \
    logviewerpane.h

SOURCES += \
    logviewerplugin.cpp \
    logviewerpane.cpp
```

**文件**: `src/plugins/logviewer/logviewerplugin.h`
```cpp
#pragma once
#include <extensionsystem/iplugin.h>

namespace LogViewer {
namespace Internal {

class LogViewerPane;

class LogViewerPlugin : public ExtensionSystem::IPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.mycompany.MyApp.Plugin" FILE "LogViewer.json")

public:
    bool initialize(const QStringList &arguments, QString *errorMessage) override;
    void extensionsInitialized() override;

private:
    LogViewerPane *m_pane = nullptr;
};

} // namespace Internal
} // namespace LogViewer
```

**文件**: `src/plugins/logviewer/logviewerplugin.cpp`
```cpp
#include "logviewerplugin.h"
#include "logviewerpane.h"

namespace LogViewer {
namespace Internal {

bool LogViewerPlugin::initialize(const QStringList &, QString *)
{
    m_pane = new LogViewerPane(this);
    addAutoReleasedObject(m_pane);
    return true;
}

void LogViewerPlugin::extensionsInitialized()
{
    // 可以在这里连接其他插件的日志信号
}

} // namespace Internal
} // namespace LogViewer
```

**文件**: `src/plugins/logviewer/logviewerpane.h`
```cpp
#pragma once
#include <coreplugin/ioutputpane.h>

class QTextEdit;
class QPushButton;

namespace LogViewer {
namespace Internal {

class LogViewerPane : public Core::IOutputPane
{
    Q_OBJECT
public:
    explicit LogViewerPane(QObject *parent = nullptr);

    // IOutputPane 接口实现
    QWidget *outputWidget(QWidget *parent) override;
    QList<QWidget *> toolBarWidgets() const override;
    QString displayName() const override;
    int priorityInStatusBar() const override;
    void clearContents() override;
    void visibilityChanged(bool visible) override;
    void setFocus() override;
    bool hasFocus() const override;
    bool canFocus() const override;
    bool canNavigate() const override;
    bool canNext() const override;
    bool canPrevious() const override;
    void goToNext() override;
    void goToPrev() override;

    // 公共方法
    void appendLog(const QString &level, const QString &message);

private:
    QTextEdit *m_textEdit = nullptr;
    QPushButton *m_clearButton = nullptr;
};

} // namespace Internal
} // namespace LogViewer
```

**文件**: `src/plugins/logviewer/logviewerpane.cpp`
```cpp
#include "logviewerpane.h"
#include <QTextEdit>
#include <QPushButton>
#include <QDateTime>

namespace LogViewer {
namespace Internal {

LogViewerPane::LogViewerPane(QObject *parent)
    : Core::IOutputPane(parent)
{
}

QWidget *LogViewerPane::outputWidget(QWidget *parent)
{
    if (!m_textEdit) {
        m_textEdit = new QTextEdit(parent);
        m_textEdit->setReadOnly(true);
        m_textEdit->setFont(QFont("Consolas", 9));
        appendLog("INFO", "LogViewer initialized.");
    }
    return m_textEdit;
}

QList<QWidget *> LogViewerPane::toolBarWidgets() const
{
    QList<QWidget *> widgets;
    if (!m_clearButton) {
        auto *self = const_cast<LogViewerPane *>(this);
        self->m_clearButton = new QPushButton(tr("Clear"));
        connect(self->m_clearButton, &QPushButton::clicked,
                self, &LogViewerPane::clearContents);
    }
    widgets << m_clearButton;
    return widgets;
}

QString LogViewerPane::displayName() const { return tr("Log Viewer"); }
int LogViewerPane::priorityInStatusBar() const { return 60; }
void LogViewerPane::clearContents() { if (m_textEdit) m_textEdit->clear(); }
void LogViewerPane::visibilityChanged(bool) {}
void LogViewerPane::setFocus() { if (m_textEdit) m_textEdit->setFocus(); }
bool LogViewerPane::hasFocus() const { return m_textEdit && m_textEdit->hasFocus(); }
bool LogViewerPane::canFocus() const { return true; }
bool LogViewerPane::canNavigate() const { return false; }
bool LogViewerPane::canNext() const { return false; }
bool LogViewerPane::canPrevious() const { return false; }
void LogViewerPane::goToNext() {}
void LogViewerPane::goToPrev() {}

void LogViewerPane::appendLog(const QString &level, const QString &message)
{
    if (!m_textEdit) return;
    
    QString color = "black";
    if (level == "ERROR") color = "red";
    else if (level == "WARN") color = "orange";
    else if (level == "INFO") color = "blue";
    
    QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss.zzz");
    m_textEdit->append(QString("<span style='color:gray'>[%1]</span> "
                               "<span style='color:%2'>[%3]</span> %4")
                       .arg(timestamp, color, level, message));
}

} // namespace Internal
} // namespace LogViewer
```

---

## 第九章 定制化UI系统设计

### 9.1 主题系统

Qt Creator 内置了主题系统（utils/theme/），保留后可以用来定制应用的视觉风格。

**主题文件位置**: `share/qtcreator/themes/`

**主题文件格式** (.creatortheme)：
```ini
[General]
ThemeName=MyApp Dark
PreferredStyles=Fusion

[Palette]
darkBackgroundColor=#2d2d2d
backgroundColor=#3c3f41
foregroundColor=#bbbbbb
text=#d4d4d4
textDisabled=#808080
hoverColor=#323232
selectedColor=#214283

[Colors]
ToolBarBackgroundColor=#3c3f41
MenuBarBackgroundColor=#3c3f41
StatusBarBackgroundColor=#3c3f41
...
```

**定制步骤**：
1. 复制 `share/qtcreator/themes/dark.creatortheme` 为模板
2. 修改 `ThemeName` 和颜色值
3. 应用通过命令行参数选择主题：`myapp -theme dark`

### 9.2 样式系统

CorePlugin 内置了 Manhattan 样式（manhattanstyle.h/cpp），这是 Qt Creator 独特的平面UI风格。

保留 ManhattanStyle 类可以让应用具有专业的外观，而不需要自己编写 QStyle。

**ManhattanStyle 的特点**：
- 扁平化按钮和工具栏
- 自定义滚动条
- 带品牌色的高亮
- Tab页的自定义绘制（FancyTabWidget）

### 9.3 FancyTabWidget（模式切换栏）

`fancytabwidget.h/cpp` 实现了左侧的模式切换栏，这是 Qt Creator 的标志性UI组件。

**结构**：
```
FancyTabWidget
├── FancyTabBar (左侧图标栏)
│   ├── FancyTab[0] = "Welcome" 图标+文字
│   ├── FancyTab[1] = "Edit" 图标+文字
│   └── FancyTab[N] = 每个IMode一个tab
└── QStackedLayout (右侧内容区)
    ├── Widget[0] = Welcome模式的内容
    ├── Widget[1] = Edit模式的内容
    └── Widget[N] = 对应模式的内容
```

### 9.4 FancyActionBar（底部操作栏）

`fancyactionbar.h/cpp` 实现了模式切换栏底部的操作按钮（如运行、调试按钮）。

这些按钮可以通过 ActionManager 注册。

### 9.5 UI定制化建议

| UI组件 | 定制方式 | 难度 |
|--------|---------|------|
| 应用图标 | 替换资源文件 | 低 |
| 应用名称 | 修改 branding.pri | 低 |
| 颜色主题 | 编辑 .creatortheme | 低 |
| 模式图标 | 在插件中设置 | 低 |
| 菜单结构 | 修改 coreconstants.h | 中 |
| 启动画面 | 添加 QSplashScreen | 中 |
| 窗口布局 | 修改 MainWindow | 中 |
| Tab栏样式 | 修改 FancyTabWidget | 高 |
| 整体风格 | 修改 ManhattanStyle | 高 |

---

## 第十章 团队插件分组开发指南

### 10.1 插件分组策略

**按业务功能分组**：

| 组别 | 负责团队 | 插件列表 | 依赖关系 |
|------|---------|---------|---------|
| 核心组 | 架构团队 | Core, Utils | 无外部依赖 |
| UI扩展组 | 前端团队 | Dashboard, WelcomePage | → Core |
| 数据组 | 后端团队 | DataManager, LogViewer | → Core |
| 工具组 | 工具团队 | ToolRunner, ScriptRunner | → Core, DataManager |
| 业务A组 | 业务团队A | BusinessA | → Core, DataManager |
| 业务B组 | 业务团队B | BusinessB | → Core, DataManager |

### 10.2 插件命名规范

```
目录名:   小写无分隔符, 如 datamanager
类名:     驼峰, 如 DataManagerPlugin
文件名:   小写, 如 datamanagerplugin.h
JSON名:   驼峰, 如 DataManager.json.in
依赖文件: 目录名_dependencies.pri, 如 datamanager_dependencies.pri
常量前缀: 模块名.功能名, 如 "DataManager.ImportAction"
```

### 10.3 接口约定

**所有团队间共享的接口必须满足以下条件**：

1. **接口定义在独立头文件中**——不与实现混合
2. **接口类继承自 QObject**——以支持对象池查询
3. **接口使用 Q_OBJECT 宏**——以支持 qobject_cast
4. **接口方法全部为纯虚函数**——除非有合理默认实现
5. **接口头文件放在插件根目录**——方便其他插件 include

**示例——定义跨团队共享接口**：

```cpp
// src/plugins/datamanager/idataservice.h
#pragma once

#include "datamanager_global.h"  // 导出宏
#include <QObject>
#include <QVariant>

namespace DataManager {

class DATAMANAGER_EXPORT IDataService : public QObject
{
    Q_OBJECT
public:
    explicit IDataService(QObject *parent = nullptr) : QObject(parent) {}
    virtual ~IDataService() = default;
    
    // 数据查询
    virtual QVariant queryData(const QString &key) const = 0;
    
    // 数据写入
    virtual bool writeData(const QString &key, const QVariant &value) = 0;
    
    // 数据变更通知
signals:
    void dataChanged(const QString &key, const QVariant &newValue);
};

} // namespace DataManager
```

**其他团队使用这个接口**：

```cpp
// 在 BusinessA 插件中
#include <datamanager/idataservice.h>

void BusinessAPlugin::extensionsInitialized()
{
    // 从对象池中获取 IDataService
    auto *dataSvc = ExtensionSystem::PluginManager::getObject<DataManager::IDataService>();
    if (dataSvc) {
        QVariant result = dataSvc->queryData("some_key");
        connect(dataSvc, &DataManager::IDataService::dataChanged,
                this, &BusinessAPlugin::onDataChanged);
    }
}
```

### 10.4 团队开发工作流

```
                     ┌─────────────┐
                     │  主仓库     │
                     │  (master)   │
                     └──────┬──────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
        ┌─────┴─────┐ ┌────┴────┐ ┌─────┴─────┐
        │  团队A    │ │ 团队B  │ │ 团队C    │
        │  分支     │ │ 分支   │ │ 分支     │
        └─────┬─────┘ └────┬────┘ └─────┬─────┘
              │             │             │
    ┌─────────┤      ┌──────┤      ┌─────┤
    │         │      │      │      │     │
  PluginA  PluginB PluginC PluginD PluginE
```

**工作流程**：

1. **主仓库** 维护框架层代码（Core, ExtensionSystem, Utils）和 plugins.pro
2. **各团队分支** 开发自己的插件，只修改自己的插件目录和 plugins.pro
3. **集成测试** 在合并到主分支前，确保所有插件可以共存
4. **发布构建** 从主分支构建完整应用

### 10.5 插件版本兼容性

**版本号规则**：
- `Version` = 当前版本，如 "1.2.0"
- `CompatVersion` = 最低兼容版本，如 "1.0.0"

**兼容性含义**：
- 如果插件A依赖插件B的版本 "1.0.0"
- 只要插件B的 `CompatVersion` ≤ "1.0.0" 且 `Version` ≥ "1.0.0"
- 则依赖关系满足

这允许插件B在不破坏API的前提下升级版本。

### 10.6 插件调试技巧

**1. 查看插件加载状态**：
在 main.cpp 中添加：
```cpp
for (PluginSpec *spec : PluginManager::plugins()) {
    qDebug() << spec->name() << ":" << spec->state() 
             << (spec->hasError() ? spec->errorString() : "OK");
}
```

**2. 跳过某个插件**：
```
myapp -noload PluginName
```

**3. 性能分析**：
PluginManager 内置了性能计时（`profilingReport` 宏），可以查看每个插件的加载耗时。

**4. 插件管理UI**：
extensionsystem 库自带 PluginView 控件，可以集成到设置对话框中显示所有插件的状态。

---

## 第十一章 构建系统配置

### 11.1 qmake 构建流程

```
qtcreator.pro (根)
  │
  ├── include(qtcreator.pri)         ← 全局变量定义
  │     └── include(branding.pri)    ← 品牌和版本
  │
  └── SUBDIRS = src
        │
        └── src/src.pro
              │
              ├── shared/shared.pro         ← 共享库 (qtsingleapplication等)
              │
              ├── libs/libs.pro             ← 框架库
              │     ├── aggregation/        ← aggregation.pro
              │     ├── extensionsystem/    ← extensionsystem.pro
              │     └── utils/              ← utils.pro → utils-lib.pri
              │
              ├── app/app.pro               ← 主程序
              │     └── include(qtcreatortool.pri) → include(qtcreator.pri)
              │
              └── plugins/plugins.pro       ← 插件
                    ├── coreplugin/
                    │     └── include(qtcreatorplugin.pri) → include(qtcreator.pri)
                    ├── helloworld/
                    └── dashboard/
```

### 11.2 依赖解析流程

当 qmake 处理一个插件的 .pro 文件时：

1. **qtcreatorplugin.pri 第1-9行**：自动定位并 include 该插件的 `*_dependencies.pri`
2. **_dependencies.pri**：声明 `QTC_PLUGIN_NAME`、`QTC_LIB_DEPENDS`、`QTC_PLUGIN_DEPENDS`
3. **qtcreatorplugin.pri 第12-14行**：保存依赖列表
4. **qtcreatorplugin.pri 第16行**：`include(../qtcreator.pri)` 引入全局配置
5. **qtcreator.pri 第245-294行**：递归解析所有依赖，添加 `-L` 和 `-l` 链接选项
6. **qtcreatorplugin.pri 第31-44行**：生成 JSON 依赖列表，注入到 .json.in 模板
7. **qtcreatorplugin.pri 第75-84行**：处理 .json.in 到 .json 的替换

### 11.3 编译顺序

qmake 的 `ordered` 配置保证按 SUBDIRS 列表顺序编译：

```
1. shared (qtsingleapplication, qtlockedfile)
2. libs
   2a. aggregation (无依赖)
   2b. utils (无依赖)
   2c. extensionsystem (依赖 aggregation, utils)
3. app (依赖 extensionsystem)
4. plugins
   4a. coreplugin (依赖 extensionsystem, aggregation, utils)
   4b. helloworld (依赖 coreplugin)
   4c. dashboard (依赖 coreplugin)
   4d. logviewer (依赖 coreplugin)
```

### 11.4 输出目录结构

编译后的输出：

```
build/
├── bin/
│   └── myapp.exe              ← 主程序
├── lib/qtcreator/
│   ├── aggregation4.dll       ← 库（带版本号后缀）
│   ├── extensionsystem4.dll
│   └── utils4.dll
│   └── plugins/
│       ├── Core4.dll          ← 核心插件
│       ├── HelloWorld4.dll    ← Hello插件
│       ├── Dashboard4.dll     ← 仪表板插件
│       └── LogViewer4.dll     ← 日志查看插件
└── share/qtcreator/
    └── themes/                ← 主题文件
```

**【注意】** Windows 下库文件带版本号后缀（由 `qtLibraryName()` 函数在 qtcreator.pri 第25-32行生成）。

### 11.5 部署检查清单

| 检查项 | 命令/方法 | 预期结果 |
|--------|---------|---------|
| 主程序存在 | `dir bin\myapp.exe` | 文件存在 |
| 核心库存在 | `dir lib\qtcreator\*.dll` | 3个dll |
| 插件存在 | `dir lib\qtcreator\plugins\*.dll` | N个dll |
| Qt库部署 | `windeployqt bin\myapp.exe` | Qt DLL拷贝到bin/ |
| 启动测试 | 运行 `bin\myapp.exe` | 窗口显示 |
| 插件加载 | 运行后检查Help→About Plugins | 所有插件状态正常 |

---

## 第十二章 示例插件开发完整流程

**本章以一个完整的例子，展示如何从零开始开发一个新插件。**

### 12.1 需求描述

开发一个 "FileExplorer" 插件，功能：
- 在左侧导航栏添加文件浏览面板
- 在 Tools 菜单添加 "Open Working Directory" 菜单项
- 在底部输出面板显示文件操作日志

### 12.2 创建文件结构

```
src/plugins/fileexplorer/
├── fileexplorer_dependencies.pri
├── FileExplorer.json.in
├── fileexplorer.pro
├── fileexplorerplugin.h
├── fileexplorerplugin.cpp
├── fileexplorernav.h          ← INavigationWidgetFactory 实现
├── fileexplorernav.cpp
├── fileexploreroutput.h       ← IOutputPane 实现
└── fileexploreroutput.cpp
```

### 12.3 步骤一：声明依赖

**文件**: `fileexplorer_dependencies.pri`
```
QTC_PLUGIN_NAME = FileExplorer
QTC_LIB_DEPENDS += \
    extensionsystem \
    utils
QTC_PLUGIN_DEPENDS += \
    coreplugin
```

### 12.4 步骤二：创建元数据

**文件**: `FileExplorer.json.in`
```json
{
    "Name" : "FileExplorer",
    "Version" : "$$QTCREATOR_VERSION",
    "CompatVersion" : "$$QTCREATOR_COMPAT_VERSION",
    "Vendor" : "MyCompany - Tools Team",
    "Copyright" : "(C) $$QTCREATOR_COPYRIGHT_YEAR MyCompany",
    "License" : ["Proprietary"],
    "Category" : "Utilities",
    "Description" : "File system explorer with navigation panel and operation log.",
    "Url" : "https://www.mycompany.com",
    $$dependencyList
}
```

### 12.5 步骤三：创建构建配置

**文件**: `fileexplorer.pro`
```pro
include(../../qtcreatorplugin.pri)

QT += widgets

HEADERS += \
    fileexplorerplugin.h \
    fileexplorernav.h \
    fileexploreroutput.h

SOURCES += \
    fileexplorerplugin.cpp \
    fileexplorernav.cpp \
    fileexploreroutput.cpp
```

### 12.6 步骤四：实现插件入口

**文件**: `fileexplorerplugin.h`
```cpp
#pragma once

#include <extensionsystem/iplugin.h>

namespace FileExplorer {
namespace Internal {

class FileExplorerNav;
class FileExplorerOutput;

class FileExplorerPlugin : public ExtensionSystem::IPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.mycompany.MyApp.Plugin" FILE "FileExplorer.json")

public:
    FileExplorerPlugin() = default;

    bool initialize(const QStringList &arguments, QString *errorMessage) override;
    void extensionsInitialized() override;

    static FileExplorerOutput *outputPane();

private:
    FileExplorerNav *m_navFactory = nullptr;
    static FileExplorerOutput *m_outputPane;
};

} // namespace Internal
} // namespace FileExplorer
```

**文件**: `fileexplorerplugin.cpp`
```cpp
#include "fileexplorerplugin.h"
#include "fileexplorernav.h"
#include "fileexploreroutput.h"

#include <coreplugin/icore.h>
#include <coreplugin/actionmanager/actionmanager.h>
#include <coreplugin/actionmanager/actioncontainer.h>
#include <coreplugin/coreconstants.h>

#include <QAction>
#include <QDesktopServices>
#include <QDir>
#include <QUrl>

namespace FileExplorer {
namespace Internal {

FileExplorerOutput *FileExplorerPlugin::m_outputPane = nullptr;

bool FileExplorerPlugin::initialize(const QStringList &arguments, QString *errorMessage)
{
    Q_UNUSED(arguments)
    Q_UNUSED(errorMessage)

    // 1. 注册导航面板工厂
    m_navFactory = new FileExplorerNav;
    addAutoReleasedObject(m_navFactory);

    // 2. 注册输出面板
    m_outputPane = new FileExplorerOutput(this);
    addAutoReleasedObject(m_outputPane);

    // 3. 注册菜单项
    auto openDirAction = new QAction(tr("Open Working Directory"), this);
    Core::Command *cmd = Core::ActionManager::registerAction(
        openDirAction, "FileExplorer.OpenWorkDir");
    cmd->setDefaultKeySequence(QKeySequence(tr("Ctrl+Shift+O")));

    Core::ActionContainer *toolsMenu = Core::ActionManager::actionContainer(
        Core::Constants::M_TOOLS);
    if (toolsMenu)
        toolsMenu->addAction(cmd);

    connect(openDirAction, &QAction::triggered, this, []() {
        QString dir = QDir::currentPath();
        QDesktopServices::openUrl(QUrl::fromLocalFile(dir));
        if (m_outputPane)
            m_outputPane->appendLog("INFO", "Opened directory: " + dir);
    });

    return true;
}

void FileExplorerPlugin::extensionsInitialized()
{
    if (m_outputPane)
        m_outputPane->appendLog("INFO", "FileExplorer plugin fully initialized.");
}

FileExplorerOutput *FileExplorerPlugin::outputPane()
{
    return m_outputPane;
}

} // namespace Internal
} // namespace FileExplorer
```

### 12.7 步骤五：实现导航面板

**文件**: `fileexplorernav.h`
```cpp
#pragma once

#include <coreplugin/inavigationwidgetfactory.h>

namespace FileExplorer {
namespace Internal {

class FileExplorerNav : public Core::INavigationWidgetFactory
{
    Q_OBJECT
public:
    FileExplorerNav();
    Core::NavigationView createWidget() override;
};

} // namespace Internal
} // namespace FileExplorer
```

**文件**: `fileexplorernav.cpp`
```cpp
#include "fileexplorernav.h"
#include "fileexplorerplugin.h"
#include "fileexploreroutput.h"

#include <QFileSystemModel>
#include <QTreeView>
#include <QDir>
#include <QToolButton>
#include <QAction>

namespace FileExplorer {
namespace Internal {

FileExplorerNav::FileExplorerNav()
{
    setDisplayName(tr("File Explorer"));
    setPriority(150);
    setId("FileExplorer.Navigator");
}

Core::NavigationView FileExplorerNav::createWidget()
{
    auto model = new QFileSystemModel;
    model->setRootPath(QDir::homePath());
    model->setFilter(QDir::AllEntries | QDir::NoDotAndDotDot);

    auto view = new QTreeView;
    view->setModel(model);
    view->setRootIndex(model->index(QDir::homePath()));
    view->setColumnHidden(1, true);  // 隐藏Size列
    view->setColumnHidden(2, true);  // 隐藏Type列
    view->setColumnHidden(3, true);  // 隐藏Date列
    view->setHeaderHidden(true);

    // 双击文件时记录日志
    QObject::connect(view, &QTreeView::doubleClicked,
                     [model](const QModelIndex &index) {
        QString path = model->filePath(index);
        auto *pane = FileExplorerPlugin::outputPane();
        if (pane)
            pane->appendLog("ACTION", "Double-clicked: " + path);
    });

    // 工具栏按钮：刷新
    auto refreshButton = new QToolButton;
    refreshButton->setToolTip(tr("Refresh"));
    refreshButton->setText(tr("↻"));
    QObject::connect(refreshButton, &QToolButton::clicked,
                     [model]() { model->setRootPath(model->rootPath()); });

    Core::NavigationView navView;
    navView.widget = view;
    navView.dockToolBarWidgets << refreshButton;
    return navView;
}

} // namespace Internal
} // namespace FileExplorer
```

### 12.8 步骤六：实现输出面板

复用 LogViewer 中类似的 IOutputPane 实现（见第八章 8.3.2 节），命名为 `FileExplorerOutput`。

### 12.9 步骤七：注册到构建系统

修改 `src/plugins/plugins.pro`：
```pro
SUBDIRS += fileexplorer
fileexplorer.depends = coreplugin
```

### 12.10 步骤八：编译与测试

```bash
cd build
qmake ../qtcreator.pro
make -j4
# 检查输出:
ls lib/qtcreator/plugins/FileExplorer*
# 运行:
bin/myapp
```

**验证清单**：
- [ ] 启动后左侧导航栏出现 "File Explorer" 面板
- [ ] 底部出现 "File Explorer Log" 输出面板
- [ ] Tools 菜单中出现 "Open Working Directory"
- [ ] 双击文件时日志面板显示操作记录
- [ ] Ctrl+Shift+O 快捷键工作正常

---

## 第十三章 测试与验证方案

### 13.1 编译测试

| 测试项 | 预期结果 | 验证方法 |
|--------|---------|---------|
| 库编译 | aggregation, extensionsystem, utils 编译通过 | make 无错误 |
| Core插件编译 | Core.dll 生成 | 检查输出目录 |
| 示例插件编译 | HelloWorld.dll 等生成 | 检查输出目录 |
| 主程序编译 | myapp.exe 生成 | 检查输出目录 |
| 全量构建 | 整体编译无错误 | make clean && make |

### 13.2 运行测试

| 测试项 | 步骤 | 预期结果 |
|--------|------|---------|
| 启动 | 运行 myapp | 主窗口显示 |
| 插件加载 | 查看日志 | 所有插件状态为 Running |
| 模式切换 | 点击左侧模式栏 | UI正确切换 |
| 菜单 | 点击各菜单项 | 功能正常 |
| 设置 | 打开设置对话框 | 对话框正确显示 |
| 插件管理 | 查看插件列表 | 所有插件信息正确 |
| 禁用插件 | 禁用 HelloWorld | 重启后不加载 |
| 缺少依赖 | 删除 Core.dll | 启动失败并提示 |

### 13.3 性能测试

| 测试项 | 指标 | 目标值 |
|--------|------|-------|
| 冷启动 | 从执行到窗口显示 | < 2秒 |
| 插件加载 | 所有插件 initialize() 完成 | < 500ms |
| 内存占用 | 启动后空闲状态 | < 50MB |
| 插件扫描 | setPluginPaths() 耗时 | < 100ms |

### 13.4 兼容性测试

| 环境 | 测试重点 |
|------|---------|
| Windows 7 + MSVC2015 | 基础功能 |
| Windows 10 + MSVC2015 | DPI缩放 |
| Ubuntu 18.04 + GCC | 编译和运行 |
| macOS 10.14 | 编译和运行 |

---

## 第十四章 项目里程碑与排期

### 14.1 里程碑定义

| 里程碑 | 目标 | 产出物 |
|--------|------|-------|
| M1: 代码裁剪 | 完成文件删除和修改 | 可编译的最小框架 |
| M2: 框架搭建 | 主程序+Core插件正常运行 | 主窗口显示，模式切换工作 |
| M3: 插件模板 | 插件开发流程验证 | HelloWorld插件正常工作 |
| M4: 示例插件集 | 各扩展点示例完成 | Dashboard、LogViewer、FileExplorer |
| M5: 团队接入 | 团队开始并行开发插件 | 至少2个业务插件原型 |
| M6: UI定制 | 品牌和主题定制 | 定制化的应用外观 |
| M7: 发布 | 第一版发布 | 安装包 |

### 14.2 各里程碑详细任务

**M1: 代码裁剪**（按第四至第六章执行）
- 删除68个插件目录
- 删除17个库目录
- 删除tools目录
- 修改6个.pro/.pri文件
- 修改CorePlugin源码
- 重写main.cpp

**M2: 框架搭建**
- 验证编译通过
- 修复编译错误（utils库依赖问题）
- 验证主窗口显示
- 验证Action系统工作
- 验证模式管理工作

**M3: 插件模板**
- 创建插件模板文件
- 编写HelloWorld插件
- 验证插件加载和卸载
- 编写开发者文档

**M4: 示例插件集**
- Dashboard插件（IMode扩展点）
- LogViewer插件（IOutputPane扩展点）
- FileExplorer插件（INavigationWidgetFactory扩展点）

**M5: 团队接入**
- 发布框架和文档
- 培训团队
- 各团队创建自己的插件骨架
- 建立集成测试流程

---

## 附录A 完整文件操作索引表

**【重要】本表汇总了所有需要操作的文件，可作为执行时的检查清单。**

### A.1 需要删除的目录（共89个目录）

| 序号 | 路径 | 类型 | 内容说明 |
|------|------|------|---------|
| 1 | src/libs/cplusplus/ | 库 | C++前端解析器 |
| 2 | src/libs/qmljs/ | 库 | QML/JS前端解析器 |
| 3 | src/libs/languageserverprotocol/ | 库 | LSP协议实现 |
| 4 | src/libs/clangsupport/ | 库 | Clang通信支持 |
| 5 | src/libs/ssh/ | 库 | SSH客户端库 |
| 6 | src/libs/sqlite/ | 库 | SQLite封装 |
| 7 | src/libs/glsl/ | 库 | GLSL着色器解析器 |
| 8 | src/libs/languageutils/ | 库 | 语言公共工具 |
| 9 | src/libs/qmldebug/ | 库 | QML调试协议 |
| 10 | src/libs/qmleditorwidgets/ | 库 | QML编辑控件 |
| 11 | src/libs/tracing/ | 库 | 性能追踪 |
| 12 | src/libs/modelinglib/ | 库 | UML建模引擎 |
| 13 | src/libs/advanceddockingsystem/ | 库 | 停靠窗口系统 |
| 14 | src/libs/3rdparty/cplusplus/ | 第三方 | C++词法规则 |
| 15 | src/libs/3rdparty/json/ | 第三方 | JSON解析器 |
| 16 | src/libs/3rdparty/yaml-cpp/ | 第三方 | YAML解析器 |
| 17 | src/libs/3rdparty/syntax-highlighting/ | 第三方 | 语法高亮引擎 |
| 18 | src/plugins/android/ | 插件 | Android支持 |
| 19 | src/plugins/autotest/ | 插件 | 自动测试 |
| 20 | src/plugins/autotoolsprojectmanager/ | 插件 | Autotools项目 |
| 21 | src/plugins/baremetal/ | 插件 | 嵌入式支持 |
| 22 | src/plugins/bazaar/ | 插件 | Bazaar版本控制 |
| 23 | src/plugins/beautifier/ | 插件 | 代码美化 |
| 24 | src/plugins/bineditor/ | 插件 | 二进制编辑器 |
| 25 | src/plugins/bookmarks/ | 插件 | 书签 |
| 26 | src/plugins/boot2qt/ | 插件 | Boot2Qt |
| 27 | src/plugins/clangcodemodel/ | 插件 | Clang代码模型 |
| 28 | src/plugins/clangformat/ | 插件 | Clang格式化 |
| 29 | src/plugins/clangpchmanager/ | 插件 | Clang预编译头 |
| 30 | src/plugins/clangrefactoring/ | 插件 | Clang重构 |
| 31 | src/plugins/clangtools/ | 插件 | Clang静态分析 |
| 32 | src/plugins/classview/ | 插件 | 类视图 |
| 33 | src/plugins/clearcase/ | 插件 | ClearCase |
| 34 | src/plugins/compilationdatabaseprojectmanager/ | 插件 | 编译数据库项目 |
| 35 | src/plugins/cpaster/ | 插件 | 代码粘贴 |
| 36 | src/plugins/cppcheck/ | 插件 | CppCheck集成 |
| 37 | src/plugins/cppeditor/ | 插件 | C++编辑器 |
| 38 | src/plugins/cpptools/ | 插件 | C++工具 |
| 39 | src/plugins/ctfvisualizer/ | 插件 | CTF可视化 |
| 40 | src/plugins/cvs/ | 插件 | CVS版本控制 |
| 41 | src/plugins/debugger/ | 插件 | 调试器 |
| 42 | src/plugins/designer/ | 插件 | Qt Designer |
| 43 | src/plugins/diffeditor/ | 插件 | 差异编辑器 |
| 44 | src/plugins/emacskeys/ | 插件 | Emacs快捷键 |
| 45 | src/plugins/fakevim/ | 插件 | Vim模拟 |
| 46 | src/plugins/genericprojectmanager/ | 插件 | 通用项目管理 |
| 47 | src/plugins/git/ | 插件 | Git版本控制 |
| 48 | src/plugins/glsleditor/ | 插件 | GLSL编辑器 |
| 49 | src/plugins/help/ | 插件 | 帮助系统 |
| 50 | src/plugins/imageviewer/ | 插件 | 图片查看 |
| 51 | src/plugins/incredibuild/ | 插件 | IncrediBuild |
| 52 | src/plugins/ios/ | 插件 | iOS支持 |
| 53 | src/plugins/languageclient/ | 插件 | 语言客户端 |
| 54 | src/plugins/macros/ | 插件 | 宏录制 |
| 55 | src/plugins/marketplace/ | 插件 | 插件市场 |
| 56 | src/plugins/mcusupport/ | 插件 | MCU支持 |
| 57 | src/plugins/mercurial/ | 插件 | Mercurial |
| 58 | src/plugins/mesonprojectmanager/ | 插件 | Meson项目 |
| 59 | src/plugins/modeleditor/ | 插件 | 模型编辑器 |
| 60 | src/plugins/nim/ | 插件 | Nim语言 |
| 61 | src/plugins/perforce/ | 插件 | Perforce |
| 62 | src/plugins/perfprofiler/ | 插件 | 性能分析器 |
| 63 | src/plugins/projectexplorer/ | 插件 | 项目管理核心 |
| 64 | src/plugins/python/ | 插件 | Python支持 |
| 65 | src/plugins/qmakeprojectmanager/ | 插件 | QMake项目 |
| 66 | src/plugins/qmldesigner/ | 插件 | QML设计器 |
| 67 | src/plugins/qmljseditor/ | 插件 | QML编辑器 |
| 68 | src/plugins/qmljstools/ | 插件 | QML工具 |
| 69 | src/plugins/qmlpreview/ | 插件 | QML预览 |
| 70 | src/plugins/qmlprofiler/ | 插件 | QML性能分析 |
| 71 | src/plugins/qmlprojectmanager/ | 插件 | QML项目 |
| 72 | src/plugins/qnx/ | 插件 | QNX支持 |
| 73 | src/plugins/qtsupport/ | 插件 | Qt支持 |
| 74 | src/plugins/remotelinux/ | 插件 | 远程Linux |
| 75 | src/plugins/resourceeditor/ | 插件 | 资源编辑器 |
| 76 | src/plugins/scxmleditor/ | 插件 | SCXML编辑器 |
| 77 | src/plugins/serialterminal/ | 插件 | 串口终端 |
| 78 | src/plugins/silversearcher/ | 插件 | 搜索工具 |
| 79 | src/plugins/studiowelcome/ | 插件 | Studio欢迎页 |
| 80 | src/plugins/subversion/ | 插件 | SVN |
| 81 | src/plugins/tasklist/ | 插件 | 任务列表 |
| 82 | src/plugins/texteditor/ | 插件 | 文本编辑器 |
| 83 | src/plugins/todo/ | 插件 | TODO标记 |
| 84 | src/plugins/updateinfo/ | 插件 | 更新信息 |
| 85 | src/plugins/valgrind/ | 插件 | Valgrind |
| 86 | src/plugins/vcsbase/ | 插件 | 版本控制基础 |
| 87 | src/plugins/webassembly/ | 插件 | WebAssembly |
| 88 | src/plugins/welcome/ | 插件 | 欢迎页 |
| 89 | src/plugins/winrt/ | 插件 | WinRT |
| 90 | src/tools/ | 工具 | 全部28个工具程序 |
| 91 | src/shared/proparser/ | 共享 | .pro文件解析 |
| 92 | src/shared/json/ | 共享 | JSON库 |
| 93 | src/shared/cpaster/ | 共享 | 代码粘贴 |
| 94 | src/shared/help/ | 共享 | 帮助系统 |
| 95 | src/shared/designerintegrationv2/ | 共享 | 设计器集成 |
| 96 | src/shared/modeltest/ | 共享 | 模型测试 |
| 97 | src/shared/syntax/ | 共享 | 语法数据 |
| 98 | src/shared/yaml-cpp/ | 共享 | YAML解析 |

### A.2 需要修改的文件（共约15个文件）

| 序号 | 文件路径 | 修改类型 | 章节参考 |
|------|---------|---------|---------|
| 1 | qtcreator_ide_branding.pri | 品牌信息替换 | 6.1节 |
| 2 | qtcreator.pro | 精简子目录 | 6.2节 |
| 3 | qtcreator.pri | Qt版本适配 | 6.3节 |
| 4 | src/src.pro | 精简子目录 | 6.4节 |
| 5 | src/libs/libs.pro | 精简库列表 | 6.5节 |
| 6 | src/plugins/plugins.pro | 精简插件列表 | 6.6节 |
| 7 | src/shared/shared.pro | 精简共享代码 | 6.7节 |
| 8 | src/app/main.cpp | 大幅重写 | 6.9节 |
| 9 | src/app/app.pro | 精简依赖 | 6.10节 |
| 10 | src/plugins/coreplugin/coreplugin.pro | 大幅精简 | 6.11.1节 |
| 11 | src/plugins/coreplugin/coreplugin.h | 删除IDE引用 | 6.11.2节 |
| 12 | src/plugins/coreplugin/coreplugin.cpp | 简化初始化 | 6.11.3节 |
| 13 | src/plugins/coreplugin/Core.json.in | 修改元数据 | 6.11.4节 |
| 14 | src/plugins/coreplugin/mainwindow.h | 删除子系统引用 | 6.11.5节 |
| 15 | src/plugins/coreplugin/mainwindow.cpp | 简化初始化 | 6.11.6节 |
| 16 | src/plugins/coreplugin/icore.h | 精简接口 | 6.11.7节 |
| 17 | src/plugins/coreplugin/icore.cpp | 精简实现 | 6.11.7节 |
| 18 | src/plugins/coreplugin/coreconstants.h | 修改常量 | 6.11.8节 |
| 19 | src/plugins/helloworld/helloworld_dependencies.pri | 移除TextEditor | 6.12.1节 |
| 20 | src/plugins/helloworld/helloworldplugin.h | 修改IID | 6.12.2节 |

### A.3 需要新建的文件（共约30个文件）

| 序号 | 文件路径 | 内容说明 | 章节参考 |
|------|---------|---------|---------|
| 1 | src/plugins/plugintemplate/plugintemplate_dependencies.pri | 模板依赖 | 8.1.1节 |
| 2 | src/plugins/plugintemplate/PluginTemplate.json.in | 模板元数据 | 8.1.1节 |
| 3 | src/plugins/plugintemplate/plugintemplate.pro | 模板构建 | 8.1.1节 |
| 4 | src/plugins/plugintemplate/plugintemplateplugin.h | 模板头文件 | 8.1.1节 |
| 5 | src/plugins/plugintemplate/plugintemplateplugin.cpp | 模板实现 | 8.1.1节 |
| 6 | build.bat | Windows构建脚本 | 8.2.1节 |
| 7 | build.sh | Linux构建脚本 | 8.2.2节 |
| 8 | src/plugins/dashboard/dashboard_dependencies.pri | 依赖 | 8.3.1节 |
| 9 | src/plugins/dashboard/Dashboard.json.in | 元数据 | 8.3.1节 |
| 10 | src/plugins/dashboard/dashboard.pro | 构建配置 | 8.3.1节 |
| 11 | src/plugins/dashboard/dashboardplugin.h | 插件头 | 8.3.1节 |
| 12 | src/plugins/dashboard/dashboardplugin.cpp | 插件实现 | 8.3.1节 |
| 13 | src/plugins/dashboard/dashboardmode.h | 模式头 | 8.3.1节 |
| 14 | src/plugins/dashboard/dashboardmode.cpp | 模式实现 | 8.3.1节 |
| 15 | src/plugins/dashboard/dashboardwidget.h | 控件头 | 8.3.1节 |
| 16 | src/plugins/dashboard/dashboardwidget.cpp | 控件实现 | 8.3.1节 |
| 17 | src/plugins/logviewer/logviewer_dependencies.pri | 依赖 | 8.3.2节 |
| 18 | src/plugins/logviewer/LogViewer.json.in | 元数据 | 8.3.2节 |
| 19 | src/plugins/logviewer/logviewer.pro | 构建配置 | 8.3.2节 |
| 20 | src/plugins/logviewer/logviewerplugin.h | 插件头 | 8.3.2节 |
| 21 | src/plugins/logviewer/logviewerplugin.cpp | 插件实现 | 8.3.2节 |
| 22 | src/plugins/logviewer/logviewerpane.h | 面板头 | 8.3.2节 |
| 23 | src/plugins/logviewer/logviewerpane.cpp | 面板实现 | 8.3.2节 |
| 24 | src/plugins/fileexplorer/fileexplorer_dependencies.pri | 依赖 | 12.3节 |
| 25 | src/plugins/fileexplorer/FileExplorer.json.in | 元数据 | 12.4节 |
| 26 | src/plugins/fileexplorer/fileexplorer.pro | 构建配置 | 12.5节 |
| 27 | src/plugins/fileexplorer/fileexplorerplugin.h | 插件头 | 12.6节 |
| 28 | src/plugins/fileexplorer/fileexplorerplugin.cpp | 插件实现 | 12.6节 |
| 29 | src/plugins/fileexplorer/fileexplorernav.h | 导航头 | 12.7节 |
| 30 | src/plugins/fileexplorer/fileexplorernav.cpp | 导航实现 | 12.7节 |

### A.4 保留不动的关键文件

| 文件/目录 | 文件数 | 说明 |
|-----------|-------|------|
| src/libs/extensionsystem/ (全部) | 27 | 插件系统核心，零修改 |
| src/libs/aggregation/ (全部) | 5 | 对象聚合库，零修改 |
| src/qtcreatorplugin.pri | 1 | 插件构建模板 |
| src/qtcreatorlibrary.pri | 1 | 库构建模板 |
| src/qtcreatortool.pri | 1 | 工具构建模板 |
| src/rpath.pri | 1 | 运行路径配置 |
| qtcreatordata.pri | 1 | 数据部署规则 |

---

## 附录B 插件依赖关系图

### B.1 原始Qt Creator 4.13.3 插件依赖关系（简化版）

```
ExtensionSystem (lib)
     │
Aggregation (lib)
     │
Utils (lib)
     │
     ├──── Core (plugin) ←── 所有插件都依赖Core
     │       │
     │       ├── TextEditor ←── 大多数编辑器插件依赖
     │       │     │
     │       │     ├── CppEditor
     │       │     ├── QmlJSEditor
     │       │     ├── GlslEditor
     │       │     ├── DiffEditor
     │       │     └── ...
     │       │
     │       ├── ProjectExplorer ←── 所有项目管理插件依赖
     │       │     │
     │       │     ├── QmakeProjectManager
     │       │     ├── CMakeProjectManager
     │       │     ├── GenericProjectManager
     │       │     └── ...
     │       │
     │       ├── Debugger
     │       │     └── (依赖 CppTools, ProjectExplorer, TextEditor)
     │       │
     │       └── ...其他70+插件
     │
     ├── SSH (lib)
     ├── CppPlus (lib)
     ├── QmlJS (lib)
     └── ...其他15个库
```

### B.2 裁剪后的依赖关系

```
ExtensionSystem (lib)
     │
Aggregation (lib)
     │
Utils (lib, 精简版)
     │
     └── Core (plugin, 精简版)
           │
           ├── HelloWorld (示例插件)
           ├── Dashboard (示例插件)
           ├── LogViewer (示例插件)
           ├── FileExplorer (示例插件)
           ├── PluginTemplate (模板插件)
           │
           └── [团队自定义插件...]
                 ├── BusinessA
                 ├── BusinessB
                 └── ...
```

### B.3 新框架的扩展点一览

| 扩展点接口 | 定义位置 | 注册方式 | 用途 |
|-----------|---------|---------|------|
| IMode | coreplugin/imode.h | addAutoReleasedObject() | 添加顶级模式/页面 |
| IOutputPane | coreplugin/ioutputpane.h | addAutoReleasedObject() | 添加底部输出面板 |
| INavigationWidgetFactory | coreplugin/inavigationwidgetfactory.h | addAutoReleasedObject() | 添加侧边栏面板 |
| IOptionsPage | coreplugin/dialogs/ioptionspage.h | addAutoReleasedObject() | 添加设置页面 |
| QAction (通过ActionManager) | coreplugin/actionmanager/ | ActionManager::registerAction() | 添加菜单项/工具栏按钮 |

---

## 附录C 关键API速查表

### C.1 PluginManager API

```cpp
// 获取单例
static PluginManager *instance();

// 对象池操作
static void addObject(QObject *obj);
static void removeObject(QObject *obj);
static QVector<QObject *> allObjects();
template <typename T> static T *getObject();
template <typename T> static QList<T *> getObjects();

// 插件操作
static void setPluginPaths(const QStringList &paths);
static void setPluginIID(const QString &iid);
static void loadPlugins();
static void shutdown();
static const QVector<PluginSpec *> plugins();

// 设置
static void setSettings(QSettings *settings);
static void setGlobalSettings(QSettings *settings);

// 信号
void objectAdded(QObject *obj);
void aboutToRemoveObject(QObject *obj);
void pluginsChanged();
void initializationDone();
```

### C.2 IPlugin 生命周期 API

```cpp
// 必须实现
virtual bool initialize(const QStringList &arguments, QString *errorString) = 0;

// 通常实现
virtual void extensionsInitialized() {}

// 可选
virtual bool delayedInitialize() { return false; }
virtual ShutdownFlag aboutToShutdown() { return SynchronousShutdown; }

// 便利方法（继承自IPlugin）
void addAutoReleasedObject(QObject *obj);  // 添加对象，卸载时自动移除
PluginSpec *pluginSpec() const;            // 获取自身规格
```

### C.3 ActionManager API

```cpp
// 注册动作
static Command *registerAction(QAction *action, Utils::Id id, const Context &context = {});

// 创建菜单/工具栏
static ActionContainer *createMenu(Utils::Id id);
static ActionContainer *createMenuBar(Utils::Id id);

// 获取已注册的容器
static ActionContainer *actionContainer(Utils::Id id);

// 获取已注册的命令
static Command *command(Utils::Id id);
```

### C.4 PluginSpec 状态机

```
  Invalid ──read()──→ Read ──resolve()──→ Resolved
     │                                       │
     │                                  loadLibrary()
     │                                       │
     │                                       ▼
     │                                    Loaded
     │                                       │
     │                                  initialize()
     │                                       │
     │                                       ▼
     │                                  Initialized
     │                                       │
     │                                extensionsInitialized()
     │                                       │
     │                                       ▼
     │                                   Running
     │                                       │
     │                                 aboutToShutdown()
     │                                       │
     │                                       ▼
     │                                   Stopped
     │                                       │
     │                                    kill()
     │                                       │
     │                                       ▼
     └──────────────────────────────────→ Deleted
```

---

## 附录D 常见问题与解决方案

### D.1 编译相关

**Q: extensionsystem 编译时找不到 utils/algorithm.h**  
A: 确认 utils 库在 libs.pro 中且在 extensionsystem 之前编译。检查 INCLUDEPATH 是否包含 `$$IDE_SOURCE_TREE/src/libs`。

**Q: 插件编译时找不到 Core 插件的头文件**  
A: 确认 `QTC_PLUGIN_DIRS` 包含了 `$$IDE_SOURCE_TREE/src/plugins`。在 qtcreator.pri 第184行已有此配置。

**Q: Windows 下链接错误 LNK2019**  
A: 检查是否使用了正确的导出宏（CORE_LIBRARY / CORE_EXPORT）。确认 .pro 文件中的 DEFINES 包含了对应的宏。

**Q: utils 库编译时大量错误**  
A: utils 库文件众多，部分文件依赖已删除的库。逐步从 utils-lib.pri 中移除出错文件，或使用最小化的 utils 子集。

### D.2 运行相关

**Q: 启动时提示 "Could not find Core plugin"**  
A: 检查 Core.dll 是否在正确的插件搜索路径中。通过 main.cpp 中的 `pluginPaths` 打印确认。

**Q: 插件加载后没有生效（不出现在UI中）**  
A: 检查插件的 Q_PLUGIN_METADATA 中的 IID 是否与 main.cpp 中设置的 IID 一致。IID 不匹配的插件会被静默忽略。

**Q: 插件依赖解析失败**  
A: 检查 .json.in 中的依赖声明。运行时可通过 PluginManager::plugins() 查看每个插件的 state() 和 errorString()。

**Q: 关闭时崩溃**  
A: 检查插件 aboutToShutdown() 中是否有悬挂指针。确保 addAutoReleasedObject() 注册的对象在析构函数中不再被引用。

### D.3 开发相关

**Q: 如何让插件的依赖变为可选的？**  
A: 在 `_dependencies.pri` 中使用 `QTC_PLUGIN_RECOMMENDS` 替代 `QTC_PLUGIN_DEPENDS`。在 .json.in 生成时会自动添加 `"Type": "optional"`。

**Q: 如何在不重新编译的情况下禁用一个插件？**  
A: 通过命令行参数 `-noload PluginName`，或者在设置文件中配置。

**Q: 如何调试插件加载问题？**  
A: 设置环境变量 `QT_DEBUG_PLUGINS=1` 可以看到 QPluginLoader 的详细日志。

---

## 附录E 源码文件行数统计

### E.1 裁剪前规模

| 组件 | .h 文件数 | .cpp 文件数 | 预计行数 |
|------|----------|-----------|---------|
| src/libs/ | ~800 | ~650 | ~400,000 |
| src/plugins/ | ~1,800 | ~1,600 | ~1,200,000 |
| src/tools/ | ~300 | ~250 | ~150,000 |
| src/shared/ | ~100 | ~80 | ~50,000 |
| src/app/ | ~5 | ~3 | ~2,000 |
| **总计** | **~3,005** | **~2,583** | **~1,802,000** |

### E.2 裁剪后规模

| 组件 | .h 文件数 | .cpp 文件数 | 预计行数 |
|------|----------|-----------|---------|
| extensionsystem | 14 | 9 | ~5,500 |
| aggregation | 2 | 1 | ~420 |
| utils (精简) | ~30 | ~25 | ~8,000 |
| coreplugin (精简) | ~20 | ~15 | ~6,000 |
| 示例插件 | ~15 | ~10 | ~2,000 |
| app/ | 2 | 1 | ~250 |
| **总计** | **~83** | **~61** | **~22,170** |

**裁剪率**: 约 98.8% 的代码被移除

### E.3 保留核心文件详细行数

| 文件 | 行数 | 重要程度 |
|------|------|---------|
| pluginmanager.cpp | 1,732 | ★★★★★ |
| pluginspec.cpp | 1,127 | ★★★★★ |
| pluginview.cpp | 454 | ★★★☆☆ |
| optionsparser.cpp | 307 | ★★★☆☆ |
| aggregate.cpp | 265 | ★★★★☆ |
| iplugin.cpp | 212 | ★★★★★ |
| mainwindow.cpp (新) | ~300 | ★★★★★ |
| main.cpp (新) | ~200 | ★★★★★ |
| invoker.cpp | 125 | ★★☆☆☆ |
| pluginerrorview.cpp | 112 | ★★☆☆☆ |
| plugindetailsview.cpp | 103 | ★★☆☆☆ |
| pluginerroroverview.cpp | 78 | ★★☆☆☆ |
| **总行数 (核心 .cpp)** | **~5,015** | |

---

## 附录F 术语表

| 术语 | 英文 | 含义 |
|------|------|------|
| 插件系统 | Extension System | 管理插件加载、依赖、生命周期的框架 |
| 插件管理器 | Plugin Manager | 插件系统的核心类，单例模式 |
| 插件规格 | Plugin Spec | 描述插件元数据（名称、版本、依赖等）的数据结构 |
| 对象池 | Object Pool | PluginManager 维护的全局对象注册表 |
| 对象聚合 | Aggregation | 将多个QObject组合为逻辑实体的模式 |
| 模式 | Mode | 应用的顶级UI区域（如欢迎页、仪表板等） |
| 上下文 | Context | 决定哪些Action在当前活跃的标识符集合 |
| Action容器 | Action Container | 菜单或工具栏，包含多个Action |
| 命令 | Command | 一个可配置快捷键的动作的封装 |
| 输出面板 | Output Pane | 主窗口底部的输出区域 |
| 导航面板 | Navigation Widget | 主窗口侧边栏的面板 |
| IID | Interface ID | 插件接口标识符，用于过滤匹配的插件 |
| 依赖解析 | Dependency Resolution | 根据声明的依赖关系确定加载顺序 |
| 拓扑排序 | Topological Sort | 确保被依赖者先于依赖者加载 |
| 延迟初始化 | Delayed Initialize | UI启动后分批执行的非关键初始化 |
| 品牌定义 | Branding | 应用名称、版本、图标等可定制的标识信息 |

---

## 附录G 参考资料

1. Qt Creator 4.13.3 源码: https://download.qt.io/official_releases/qtcreator/4.13/4.13.3/
2. Qt Creator 插件开发文档: https://doc.qt.io/qtcreator-extending/
3. Qt 插件系统文档: https://doc.qt.io/qt-5/plugins-howto.html
4. QPluginLoader 类文档: https://doc.qt.io/qt-5/qpluginloader.html
5. Qt 5.6.3 文档: https://doc.qt.io/qt-5.6/

---

**文档结束**

