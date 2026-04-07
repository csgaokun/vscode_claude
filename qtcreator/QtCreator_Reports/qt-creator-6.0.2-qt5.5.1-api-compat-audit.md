# Qt Creator 6.0.2 — Qt 5.5.1 API 兼容性审计报告

**审计范围**: `qt-creator-opensource-src-6.0.2/src/` (排除 `shared/qbs/` 和 `tests/`)  
**目标**: 识别 Qt 5.5.1 之后引入的 Qt API，如果用 Qt 5.5.1 编译将会失败  
**审计日期**: 2026-04-02

---

## 总结

| 严重程度 | API 数量 | 涉及文件(去重) |
|---------|---------|---------------|
| 🔴 致命 (大量使用) | 4 | ~677 |
| 🟠 高 (中等使用) | 7 | ~115 |
| 🟡 低 (少量使用) | 5 | ~13 |
| ⚪ 未使用 | 4 | 0 |

**结论**: Qt Creator 6.0.2 **完全不可能**在 Qt 5.5.1 上编译。至少 ~680+ 个源文件需要修改。

---

## 🔴 致命 — 大规模使用的 API

### 1. `qAsConst` (Qt 5.7+)
- **引入版本**: Qt 5.7
- **涉及文件数**: ~320
- **影响**: 遍布整个代码库，几乎每个使用 range-based for 遍历 Qt 容器引用的地方都在用
- **示例文件**:
  - `src/app/main.cpp`
  - `src/plugins/welcome/welcomeplugin.cpp`
  - `src/plugins/fakevim/fakevimhandler.cpp`

### 2. `QOverload` / `qOverload` (Qt 5.7+)
- **引入版本**: Qt 5.7
- **涉及文件数**: ~175
- **影响**: 所有 `connect()` 中用于消除重载信号/槽歧义的地方
- **示例文件**:
  - `src/plugins/debugger/debuggerdialogs.cpp`
  - `src/plugins/clangtools/diagnosticconfigswidget.cpp`
  - `src/plugins/ios/iosrunconfiguration.cpp`

### 3. `QStringView` (Qt 5.10+)
- **引入版本**: Qt 5.10 (完整独立类)
- **涉及文件数**: ~97
- **影响**: 广泛用于字符串处理，`utils/porting.h` 中还定义了 `using StringView = QStringView`
- **示例文件**:
  - `src/libs/utils/porting.h` — 核心兼容层
  - `src/libs/utils/smallstring.h`
  - `src/libs/cplusplus/MatchingText.cpp`

### 4. `Qt::SkipEmptyParts` (Qt 5.14+)
- **引入版本**: Qt 5.14 (替代 `QString::SkipEmptyParts`)
- **涉及文件数**: ~85
- **影响**: 所有 `QString::split()` 调用都迁移到了新枚举
- **示例文件**:
  - `src/plugins/docker/dockerdevice.cpp`
  - `src/plugins/clearcase/clearcaseplugin.cpp`
  - `src/plugins/android/androidrunnerworker.cpp`

---

## 🟠 高 — 中等规模使用

### 5. `QVersionNumber` (Qt 5.6+)
- **引入版本**: Qt 5.6
- **涉及文件数**: ~51
- **影响**: 版本号比较逻辑广泛使用
- **示例文件**:
  - `src/plugins/webassembly/webassemblytoolchain.h`
  - `src/plugins/webassembly/webassemblyqtversion.cpp`
  - `src/tools/iostool/iosdevicemanager.cpp`

### 6. `QMultiHash` (独立类, Qt 5.14+ 行为变更)
- **引入版本**: 独立类自 Qt 4 就有，但 Qt 5.14 将其从 QHash 继承改为独立实现
- **涉及文件数**: ~40
- **影响**: 在 Qt 5.5.1 中 QMultiHash 存在但 API 有差异，5.14+ 的独立类行为可能导致编译问题
- **示例文件**:
  - `src/libs/modelinglib/qmt/model_controller/modelcontroller.h`
  - `src/libs/qmljs/qmljsmodelmanagerinterface.h`
  - `src/tools/iostool/iosdevicemanager.cpp`

### 7. `qEnvironmentVariable()` (Qt 5.10+)
- **引入版本**: Qt 5.10 (返回 QString 的版本)
- **涉及文件数**: ~13
- **说明**: `qEnvironmentVariableIsSet()` 和 `qEnvironmentVariableIntValue()` 是 Qt 5.1+ 的，Qt 5.5.1 可用；但 `qEnvironmentVariable()` 是 5.10 新增
- **示例文件**:
  - `src/plugins/cmakeprojectmanager/cmaketoolsettingsaccessor.cpp`
  - `src/plugins/mcusupport/mcusupportsdk.cpp`
  - `src/plugins/clangtools/clangtoolsutils.cpp`

### 8. `qScopeGuard` / `QScopeGuard` (Qt 5.12+)
- **引入版本**: Qt 5.12
- **涉及文件数**: ~7
- **示例文件**:
  - `src/app/main.cpp`
  - `src/plugins/android/androidrunnerworker.cpp`
  - `src/plugins/qmldesigner/components/stateseditor/stateseditorview.cpp`

### 9. `QRandomGenerator` (Qt 5.10+)
- **引入版本**: Qt 5.10
- **涉及文件数**: ~6
- **影响**: 替代了 `qrand()` / `qsrand()`
- **示例文件**:
  - `src/plugins/docker/dockerdevice.cpp`
  - `src/plugins/valgrind/callgrindhelper.cpp`
  - `src/plugins/coreplugin/dialogs/externaltoolconfig.cpp`

### 10. `readLineInto` (Qt 5.11+)
- **引入版本**: Qt 5.11 (`QTextStream::readLineInto`)
- **涉及文件数**: ~5
- **示例文件**:
  - `src/plugins/webassembly/webassemblyrunconfigurationaspects.cpp`
  - `src/plugins/git/gerrit/authenticationdialog.cpp`
  - `src/plugins/coreplugin/fileutils.cpp`

### 11. `QOperatingSystemVersion` (Qt 5.9+)
- **引入版本**: Qt 5.9
- **涉及文件数**: ~3
- **示例文件**:
  - `src/libs/utils/theme/theme_mac.mm`
  - `src/libs/utils/fileutils.cpp`
  - `src/libs/utils/filepath.cpp`

---

## 🟡 低 — 少量使用

### 12. `QDeadlineTimer` (Qt 5.8+)
- **引入版本**: Qt 5.8
- **涉及文件数**: ~3
- **示例文件**:
  - `src/plugins/android/androidqmlpreviewworker.cpp`
  - `src/libs/utils/launchersocket.h`
  - `src/libs/utils/launchersocket.cpp`

### 13. `QThread::create` (Qt 5.10+)
- **引入版本**: Qt 5.10
- **涉及文件数**: 2
- **示例文件**:
  - `src/plugins/ctfvisualizer/ctfvisualizertool.cpp`
  - `src/plugins/qmldesigner/designercore/imagecache/imagecachegenerator.cpp`

### 14. `QCborValue` (Qt 5.12+)
- **引入版本**: Qt 5.12
- **涉及文件数**: 2 (在 3rdparty/syntax-highlighting 中)
- **示例文件**:
  - `src/libs/3rdparty/syntax-highlighting/src/lib/repository.cpp`
  - `src/libs/3rdparty/syntax-highlighting/src/indexer/katehighlightingindexer.cpp`

### 15. `QRecursiveMutex` (Qt 5.14+)
- **引入版本**: Qt 5.14
- **涉及文件数**: 1
- **示例文件**:
  - `src/tools/iostool/iostool.h`

### 16. `QT_NO_JAVA_STYLE_ITERATORS` (Qt 5.15+/6.0 define)
- **引入版本**: Qt 5.15+ 引入该宏
- **涉及文件数**: 2 (CMakeLists.txt / .qmake.conf，非源码)
- **示例文件**:
  - `src/libs/qlitehtml/src/CMakeLists.txt`

---

## ⚪ 未使用 / 未发现

| API | 引入版本 | 状态 |
|-----|---------|------|
| `QCalendar` | Qt 5.14+ | 仅在 shared/qbs 测试 BIC 数据中出现，非实际代码使用 |
| `QColorSpace` | Qt 5.14+ | **未发现** |
| `QSslDiffieHellmanParameters` | Qt 5.8+ | **未发现** |
| `setTransferTimeout` | Qt 5.15+ | **未发现** |
| `Q_NAMESPACE` / `Q_ENUM_NS` | Qt 5.8+ | **未发现**（仅 shared/qbs scanner 令牌定义） |
| `Q_NAMESPACE_EXPORT` | Qt 5.14+ | **未发现** |

---

## 按 Qt 版本的破坏性影响分层

### 如果使用 Qt 5.5.1 编译
**全部以上 API 都不可用**，预计 680+ 个文件无法编译。

### 需要的最低 Qt 版本推断

| 最低 Qt 版本 | 额外解锁的 API | 额外可编译文件 |
|-------------|---------------|--------------|
| Qt 5.6 | `QVersionNumber` | +51 |
| Qt 5.7 | `qAsConst`, `QOverload` | +~495 |
| Qt 5.8 | `QDeadlineTimer` | +3 |
| Qt 5.9 | `QOperatingSystemVersion` | +3 |
| Qt 5.10 | `QRandomGenerator`, `QStringView`, `QThread::create`, `qEnvironmentVariable()` | +~118 |
| Qt 5.11 | `readLineInto` | +5 |
| Qt 5.12 | `qScopeGuard`, `QCborValue` | +9 |
| Qt 5.14 | `Qt::SkipEmptyParts`, `QRecursiveMutex` | +~86 |

### 实际最低要求
Qt Creator 6.0.2 官方要求 **Qt 5.15.2+**，本审计确认 Qt 5.5.1 完全无法编译。最大的障碍是 `qAsConst` (320 文件)、`QOverload` (175 文件)、`QStringView` (97 文件) 和 `Qt::SkipEmptyParts` (85 文件)。
