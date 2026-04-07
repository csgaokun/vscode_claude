@echo off
REM ============================================================================
REM  Qt Creator 4.13.3 调试/运行脚本
REM  Qt版本: 5.12.12    编译器: MSVC2017 x64
REM ============================================================================
setlocal enabledelayedexpansion

REM --- 配置区 ---
set "QT_DIR=C:\Qt\Qt5.12.12\5.12.12\msvc2017_64"
set "BUILD_DIR=%~dp0build"
set "LOG_DIR=%~dp0logs"

REM --- 解析命令行参数 ---
set "RUN_MODE=run"
set "USE_CDB=0"

:parse_args
if "%~1"=="" goto :done_args
if /i "%~1"=="--qt-dir" (
    set "QT_DIR=%~2"
    shift & shift
    goto :parse_args
)
if /i "%~1"=="--build-dir" (
    set "BUILD_DIR=%~2"
    shift & shift
    goto :parse_args
)
if /i "%~1"=="--cdb" (
    set "USE_CDB=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
shift
goto :parse_args

:show_help
echo.
echo 用法: debug.bat [选项]
echo.
echo 选项:
echo   --qt-dir PATH      指定Qt安装路径
echo   --build-dir PATH   指定构建输出路径
echo   --cdb              使用CDB调试器启动 (需要Windows SDK)
echo   --help, -h         显示此帮助
echo.
echo 说明:
echo   此脚本设置好运行时环境后启动Qt Creator。
echo   运行时错误会输出到控制台和日志文件。
echo   崩溃时会显示调用堆栈信息（如果使用--cdb）。
echo.
exit /b 0

:done_args

REM --- 时间戳 ---
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "DATE_STAMP=%%a%%b%%c"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "TIME_STAMP=%%a%%b"
set "TIMESTAMP=%DATE_STAMP%_%TIME_STAMP%"

REM --- 创建日志目录 ---
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "RUN_LOG=%LOG_DIR%\run_%TIMESTAMP%.log"

echo ============================================================================
echo  Qt Creator 4.13.3 调试运行
echo ============================================================================
echo.

REM ============================================================================
REM  Step 1: 查找可执行文件
REM ============================================================================
echo [Step 1/3] 查找 Qt Creator 可执行文件...

set "EXE_PATH="

REM 优先查找build目录
if exist "%BUILD_DIR%\bin\qtcreator.exe" (
    set "EXE_PATH=%BUILD_DIR%\bin\qtcreator.exe"
    echo   [OK] 找到: %BUILD_DIR%\bin\qtcreator.exe
    goto :found_exe
)

REM 查找install目录
if exist "%~dp0install\bin\qtcreator.exe" (
    set "EXE_PATH=%~dp0install\bin\qtcreator.exe"
    echo   [OK] 找到: !EXE_PATH!
    goto :found_exe
)

REM 查找deploy目录
if exist "%~dp0deploy\QtCreator-4.13.3\bin\qtcreator.exe" (
    set "EXE_PATH=%~dp0deploy\QtCreator-4.13.3\bin\qtcreator.exe"
    echo   [OK] 找到: !EXE_PATH!
    goto :found_exe
)

echo [错误] 找不到 qtcreator.exe
echo        请先运行 build.bat 编译项目。
echo        检查过的路径:
echo          %BUILD_DIR%\bin\qtcreator.exe
echo          %~dp0install\bin\qtcreator.exe
echo          %~dp0deploy\QtCreator-4.13.3\bin\qtcreator.exe
exit /b 1

:found_exe
echo.

REM ============================================================================
REM  Step 2: 设置运行时环境
REM ============================================================================
echo [Step 2/3] 设置运行时环境...

REM --- Qt DLL路径 ---
set "PATH=%QT_DIR%\bin;%PATH%"
echo   [OK] Qt bin 路径已添加: %QT_DIR%\bin

REM --- Qt Creator lib路径 ---
for %%F in ("%EXE_PATH%") do set "EXE_DIR=%%~dpF"
set "LIB_DIR=%EXE_DIR%..\lib\qtcreator"
if exist "%LIB_DIR%" (
    set "PATH=%LIB_DIR%;%LIB_DIR%\plugins;%PATH%"
    echo   [OK] Qt Creator lib 路径已添加
)

REM --- 设置Qt插件路径 ---
set "QT_PLUGIN_PATH=%QT_DIR%\plugins"
echo   [OK] Qt插件路径: %QT_PLUGIN_PATH%

REM --- 设置QML路径 ---
set "QML2_IMPORT_PATH=%QT_DIR%\qml"
echo   [OK] QML路径: %QML2_IMPORT_PATH%

REM --- 显示关键DLL检查 ---
echo.
echo   DLL依赖检查:
if exist "%QT_DIR%\bin\Qt5Core.dll" (
    echo     [OK] Qt5Core.dll
) else (
    echo     [缺失] Qt5Core.dll - 请检查Qt安装
)
if exist "%QT_DIR%\bin\Qt5Gui.dll" (
    echo     [OK] Qt5Gui.dll
) else (
    echo     [缺失] Qt5Gui.dll
)
if exist "%QT_DIR%\bin\Qt5Widgets.dll" (
    echo     [OK] Qt5Widgets.dll
) else (
    echo     [缺失] Qt5Widgets.dll
)
if exist "%QT_DIR%\bin\Qt5Network.dll" (
    echo     [OK] Qt5Network.dll
) else (
    echo     [缺失] Qt5Network.dll
)

echo.

REM ============================================================================
REM  Step 3: 启动程序
REM ============================================================================
echo [Step 3/3] 启动 Qt Creator...
echo   可执行文件: %EXE_PATH%
echo   运行日志:   %RUN_LOG%
echo.

REM --- 开启Qt调试输出 ---
set "QT_DEBUG_PLUGINS=1"
set "QT_LOGGING_RULES=*.debug=true;qt.*.debug=false"
set "QT_FATAL_WARNINGS=0"

(
    echo ============================================================================
    echo  Qt Creator 运行日志
    echo  启动时间: %DATE% %TIME%
    echo  可执行文件: %EXE_PATH%
    echo  Qt路径: %QT_DIR%
    echo ============================================================================
    echo.
) > "%RUN_LOG%"

if "%USE_CDB%"=="1" (
    echo [INFO] 使用CDB调试器启动...
    echo        崩溃时将自动输出调用堆栈。
    echo.
    
    where cdb.exe >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [错误] 未找到 cdb.exe
        echo        请安装 Windows SDK 调试工具:
        echo        https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/
        echo.
        echo        或检查以下路径:
        echo        C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe
        
        REM 尝试自动查找
        set "CDB_FOUND=0"
        for /d %%D in ("C:\Program Files (x86)\Windows Kits\10\Debuggers\x64") do (
            if exist "%%D\cdb.exe" (
                set "PATH=%%D;!PATH!"
                set "CDB_FOUND=1"
                echo   [OK] 自动找到: %%D\cdb.exe
            )
        )
        if "!CDB_FOUND!"=="0" exit /b 1
    )
    
    echo ====================================================================
    echo  CDB调试器已启动。常用命令:
    echo    g          - 继续运行
    echo    k          - 显示调用堆栈
    echo    !analyze   - 自动分析崩溃
    echo    q          - 退出调试器
    echo ====================================================================
    echo.
    
    cdb -g -G -lines "%EXE_PATH%" 2>&1 | tee "%RUN_LOG%"
    
) else (
    echo [INFO] 直接启动 Qt Creator...
    echo        控制台将显示运行时输出和错误信息。
    echo        关闭 Qt Creator 后此窗口会显示退出码。
    echo.
    echo ====================================================================
    echo  Qt Creator 运行输出:
    echo ====================================================================
    
    REM 启动程序，stderr和stdout都输出到控制台和日志文件
    "%EXE_PATH%" 2>&1 | tee "%RUN_LOG%"
    
    REM 如果tee不可用（Windows通常没有tee），使用备用方案
    if %ERRORLEVEL% NEQ 0 (
        REM 备用：直接运行，同时输出到日志
        echo.
        echo [INFO] 备用启动方式（日志仅保存到文件）...
        "%EXE_PATH%" > "%RUN_LOG%" 2>&1
    )
)

set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo ====================================================================
echo  Qt Creator 已退出
echo  退出码: %EXIT_CODE%
echo  运行日志: %RUN_LOG%
echo ====================================================================

if %EXIT_CODE% NEQ 0 (
    echo.
    echo [警告] 程序异常退出 (退出码: %EXIT_CODE%)
    echo.
    echo ===== 运行时错误摘要 =====
    findstr /i /n "error warning fatal exception crash" "%RUN_LOG%" 2>nul
    echo ===========================
    echo.
    
    if %EXIT_CODE% LSS 0 (
        echo [提示] 负数退出码通常表示程序崩溃。
        echo        使用 --cdb 参数重新运行可获取崩溃调用堆栈:
        echo        debug.bat --cdb
    )
)

echo.
endlocal
exit /b %EXIT_CODE%
