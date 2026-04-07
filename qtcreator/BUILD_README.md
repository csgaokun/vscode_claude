# Qt Creator 4.13.3 编译部署指南

## 环境要求

| 组件 | 版本 | 说明 |
|------|------|------|
| Qt | 5.12.12 | 安装路径: `C:\Qt\Qt5.12.12\5.12.12\msvc2017_64` |
| 编译器 | MSVC2017 (x64) | Visual Studio 2017 |
| 系统 | Windows 10/11 64位 | |

## 脚本说明

| 脚本 | 功能 |
|------|------|
| `env_setup.bat` | 初始化编译环境（双击打开带环境的命令行） |
| `build.bat` | 编译Qt Creator |
| `debug.bat` | 运行/调试Qt Creator |
| `deploy.bat` | 收集依赖并打包发布 |
| `build_all.bat` | 一键执行编译+部署 |

## 快速开始

### 方法一：一键编译部署

1. 双击 `env_setup.bat` 打开编译环境命令行
2. 运行：
   ```bat
   build_all.bat
   ```

### 方法二：分步执行

1. 双击 `env_setup.bat` 打开编译环境命令行
2. 编译：
   ```bat
   build.bat release
   ```
3. 运行测试：
   ```bat
   debug.bat
   ```
4. 部署发布：
   ```bat
   deploy.bat
   ```

## 详细用法

### build.bat - 编译脚本

```bat
build.bat                     # Release编译（默认）
build.bat debug               # Debug编译
build.bat clean               # 清理构建目录
build.bat --qt-dir D:\Qt5     # 指定Qt路径
build.bat --jobs 8            # 指定并行编译数
```

**编译过程：**
1. 自动检测 MSVC2017 编译器环境
2. 自动检测 jom（优先）或 nmake
3. 执行 qmake 配置
4. 并行编译
5. 安装到 `install/` 目录

**编译输出：**
- 构建目录：`build/`
- 安装目录：`install/`
- 编译日志：`logs/build_*.log`
- 错误日志：`logs/build_*_errors_*.log`

### debug.bat - 调试运行脚本

```bat
debug.bat                     # 直接运行
debug.bat --cdb               # 使用CDB调试器（崩溃时输出堆栈）
debug.bat --build-dir D:\out  # 指定构建目录
```

**功能：**
- 自动设置 Qt DLL 路径、插件路径、QML路径
- 检查关键 DLL 是否存在
- 开启 Qt 调试输出（`QT_DEBUG_PLUGINS=1`）
- 运行日志保存到 `logs/run_*.log`
- 程序退出时显示退出码和错误摘要
- 支持 CDB 调试器（崩溃时自动显示调用堆栈）

### deploy.bat - 发布部署脚本

```bat
deploy.bat                    # 完整部署（含7z压缩）
deploy.bat --zip              # 额外创建zip包
deploy.bat --no-archive       # 只复制文件不压缩
deploy.bat --output D:\out    # 指定输出目录
```

**部署过程：**
1. 复制 Qt Creator 可执行文件、库、插件、share资源
2. 使用 `windeployqt` 自动收集 Qt 依赖 DLL
3. 复制 MSVC 运行时 DLL
4. 创建 7z/zip 压缩包
5. 验证部署完整性

**部署输出：**
- 发布目录：`deploy/QtCreator-4.13.3/`
- 压缩包：`deploy/QtCreator-4.13.3-win64.7z`
- 部署日志：`logs/deploy_*.log`

### build_all.bat - 一键脚本

```bat
build_all.bat                 # 编译Release + 部署
build_all.bat debug           # 编译Debug + 部署
build_all.bat --skip-build    # 只部署（跳过编译）
build_all.bat --skip-deploy   # 只编译（跳过部署）
```

## 目录结构（编译后）

```
qtcreator/
├── qt-creator-opensource-src-4.13.3/   # 源码
├── build/                              # 构建输出（编译生成）
│   ├── bin/
│   │   └── qtcreator.exe
│   ├── lib/
│   └── ...
├── install/                            # 安装输出
├── deploy/                             # 部署输出
│   ├── QtCreator-4.13.3/              # 可分发目录
│   │   ├── bin/
│   │   │   ├── qtcreator.exe
│   │   │   ├── Qt5Core.dll
│   │   │   ├── Qt5Gui.dll
│   │   │   ├── platforms/
│   │   │   └── ...
│   │   ├── lib/
│   │   └── share/
│   ├── QtCreator-4.13.3-win64.7z     # 7z压缩包
│   └── QtCreator-4.13.3-win64.zip    # zip压缩包
├── logs/                               # 日志文件
│   ├── build_release_*.log
│   ├── build_release_errors_*.log
│   ├── run_*.log
│   └── deploy_*.log
├── build.bat                           # 编译脚本
├── debug.bat                           # 调试运行脚本
├── deploy.bat                          # 部署发布脚本
├── build_all.bat                       # 一键脚本
├── env_setup.bat                       # 环境初始化
└── BUILD_README.md                     # 本文档
```

## 常见问题

### Q: 找不到 cl.exe / MSVC编译器
**A:** 先运行 `env_setup.bat`，或在 "x64 Native Tools Command Prompt for VS 2017" 中运行脚本。

### Q: qmake 报错 "Cannot build Qt Creator with Qt version..."
**A:** Qt版本不对。确认 Qt 5.12.12 已正确安装到 `C:\Qt\Qt5.12.12\5.12.12\msvc2017_64`。

### Q: 编译时大量 LNK 链接错误
**A:** 确认使用的是 msvc2017_64 版本的Qt（不是 mingw 或 msvc2015）。

### Q: 运行时提示找不到 DLL
**A:** 运行 `debug.bat`（它会自动设置 PATH）。部署时使用 `deploy.bat`（它会用 windeployqt 收集所有依赖）。

### Q: 运行时崩溃
**A:** 使用 `debug.bat --cdb` 用调试器运行，崩溃时会显示调用堆栈。

### Q: 编译很慢
**A:** 安装 jom（Qt附带或从 https://wiki.qt.io/Jom 下载），脚本会自动检测并使用。

### Q: 如何修改Qt路径？
**A:** 所有脚本都支持 `--qt-dir` 参数：
```bat
build.bat --qt-dir "D:\Qt\5.12.12\msvc2017_64"
```
