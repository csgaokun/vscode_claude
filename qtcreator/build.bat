@echo off
REM ============================================================================
REM  Qt Creator 4.13.3 编译脚本
REM  Qt版本: 5.12.12    编译器: MSVC2017 x64
REM  Qt安装路径: C:\Qt\Qt5.12.12\5.12.12\msvc2017_64
REM ============================================================================
setlocal enabledelayedexpansion

REM --- 配置区 (可按需修改) ---
set "QT_DIR=C:\Qt\Qt5.12.12\5.12.12\msvc2017_64"
set "SOURCE_DIR=%~dp0qt-creator-opensource-src-4.13.3"
set "BUILD_DIR=%~dp0build"
set "INSTALL_DIR=%~dp0install"
set "LOG_DIR=%~dp0logs"
set "JOMEXE="

REM --- 编译配置 ---
set "BUILD_TYPE=release"
set "PARALLEL_JOBS=%NUMBER_OF_PROCESSORS%"

REM --- 解析命令行参数 ---
:parse_args
if "%~1"=="" goto :done_args
if /i "%~1"=="debug" (
    set "BUILD_TYPE=debug"
    shift
    goto :parse_args
)
if /i "%~1"=="release" (
    set "BUILD_TYPE=release"
    shift
    goto :parse_args
)
if /i "%~1"=="clean" (
    echo [INFO] 清理构建目录...
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
    if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
    echo [INFO] 清理完成。
    exit /b 0
)
if /i "%~1"=="--qt-dir" (
    set "QT_DIR=%~2"
    shift & shift
    goto :parse_args
)
if /i "%~1"=="--jobs" (
    set "PARALLEL_JOBS=%~2"
    shift & shift
    goto :parse_args
)
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
shift
goto :parse_args

:show_help
echo.
echo 用法: build.bat [选项]
echo.
echo 选项:
echo   debug          编译Debug版本
echo   release        编译Release版本 (默认)
echo   clean          清理构建目录
echo   --qt-dir PATH  指定Qt安装路径 (默认: C:\Qt\Qt5.12.12\5.12.12\msvc2017_64)
echo   --jobs N       并行编译数 (默认: CPU核心数)
echo   --help, -h     显示此帮助
echo.
exit /b 0

:done_args

REM --- 时间戳 ---
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "DATE_STAMP=%%a%%b%%c"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "TIME_STAMP=%%a%%b"
set "TIMESTAMP=%DATE_STAMP%_%TIME_STAMP%"

REM --- 创建日志目录 ---
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "BUILD_LOG=%LOG_DIR%\build_%BUILD_TYPE%_%TIMESTAMP%.log"
set "ERROR_LOG=%LOG_DIR%\build_%BUILD_TYPE%_errors_%TIMESTAMP%.log"

echo ============================================================================
echo  Qt Creator 4.13.3 编译
echo  编译类型: %BUILD_TYPE%
echo  Qt路径:   %QT_DIR%
echo  源码路径: %SOURCE_DIR%
echo  构建路径: %BUILD_DIR%
echo  安装路径: %INSTALL_DIR%
echo  日志文件: %BUILD_LOG%
echo  并行数:   %PARALLEL_JOBS%
echo ============================================================================
echo.

REM ============================================================================
REM  Step 1: 检查环境
REM ============================================================================
echo [Step 1/5] 检查编译环境...

REM --- 检查Qt ---
if not exist "%QT_DIR%\bin\qmake.exe" (
    echo [错误] 未找到 qmake.exe: %QT_DIR%\bin\qmake.exe
    echo        请检查Qt安装路径是否正确。
    echo        可通过 --qt-dir 参数指定正确路径。
    exit /b 1
)
echo   [OK] 找到 qmake: %QT_DIR%\bin\qmake.exe

REM --- 检查源码 ---
if not exist "%SOURCE_DIR%\qtcreator.pro" (
    echo [错误] 未找到源码: %SOURCE_DIR%\qtcreator.pro
    echo        请确保源码已解压到正确位置。
    exit /b 1
)
echo   [OK] 找到源码: %SOURCE_DIR%\qtcreator.pro

REM --- 检查MSVC环境 ---
where cl.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [警告] 未检测到MSVC编译器环境。
    echo        正在尝试自动初始化 VS2017 x64 编译环境...
    
    REM 尝试各种VS2017安装路径
    set "VCVARS_FOUND=0"
    
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
        call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
        set "VCVARS_FOUND=1"
    )
    if "!VCVARS_FOUND!"=="0" if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvars64.bat" (
        call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvars64.bat"
        set "VCVARS_FOUND=1"
    )
    if "!VCVARS_FOUND!"=="0" if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat" (
        call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"
        set "VCVARS_FOUND=1"
    )
    if "!VCVARS_FOUND!"=="0" if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
        call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
        set "VCVARS_FOUND=1"
    )
    
    if "!VCVARS_FOUND!"=="0" (
        echo [错误] 无法找到 VS2017 vcvars64.bat
        echo        请先运行 "x64 Native Tools Command Prompt for VS 2017"
        echo        或手动调用 vcvars64.bat 后再运行此脚本。
        exit /b 1
    )
    
    where cl.exe >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [错误] 初始化MSVC环境后仍找不到 cl.exe
        exit /b 1
    )
)
echo   [OK] 找到 MSVC 编译器: & where cl.exe

REM --- 检查jom (可选，加速编译) ---
where jom.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "JOMEXE=jom.exe"
    echo   [OK] 找到 jom (将使用jom加速编译)
) else (
    if exist "%QT_DIR%\..\..\Tools\QtCreator\bin\jom.exe" (
        set "JOMEXE=%QT_DIR%\..\..\Tools\QtCreator\bin\jom.exe"
        echo   [OK] 找到 jom: !JOMEXE!
    ) else (
        echo   [提示] 未找到 jom，将使用 nmake (编译会较慢)
    )
)

REM --- 设置PATH ---
set "PATH=%QT_DIR%\bin;%PATH%"

echo.
echo   Qt版本信息:
qmake -query QT_VERSION
echo.

REM ============================================================================
REM  Step 2: 创建构建目录
REM ============================================================================
echo [Step 2/5] 创建构建目录...
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
echo   [OK] 构建目录: %BUILD_DIR%
echo.

REM ============================================================================
REM  Step 3: 执行 qmake
REM ============================================================================
echo [Step 3/5] 执行 qmake 配置...
echo   命令: qmake "%SOURCE_DIR%\qtcreator.pro" CONFIG+=%BUILD_TYPE% QTC_PREFIX="%INSTALL_DIR%"
echo.

cd /d "%BUILD_DIR%"

(
    echo === qmake 开始: %DATE% %TIME% ===
    echo 命令: qmake "%SOURCE_DIR%\qtcreator.pro" CONFIG+=%BUILD_TYPE% QTC_PREFIX="%INSTALL_DIR%"
    echo.
) > "%BUILD_LOG%" 2>&1

qmake "%SOURCE_DIR%\qtcreator.pro" CONFIG+=%BUILD_TYPE% QTC_PREFIX="%INSTALL_DIR%" >> "%BUILD_LOG%" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] qmake 配置失败！
    echo.
    echo ===== 错误详情 =====
    type "%BUILD_LOG%"
    echo ====================
    echo.
    echo 详细日志: %BUILD_LOG%
    exit /b 1
)
echo   [OK] qmake 配置成功
echo.

REM ============================================================================
REM  Step 4: 编译
REM ============================================================================
echo [Step 4/5] 开始编译 (%BUILD_TYPE%)...
echo   编译日志: %BUILD_LOG%
echo   错误日志: %ERROR_LOG%

(
    echo.
    echo === 编译开始: %DATE% %TIME% ===
) >> "%BUILD_LOG%" 2>&1

if defined JOMEXE (
    echo   使用 jom -j%PARALLEL_JOBS% 编译...
    "%JOMEXE%" -j%PARALLEL_JOBS% >> "%BUILD_LOG%" 2> "%ERROR_LOG%"
) else (
    echo   使用 nmake 编译...
    nmake >> "%BUILD_LOG%" 2> "%ERROR_LOG%"
)

set "BUILD_RESULT=%ERRORLEVEL%"

(
    echo.
    echo === 编译结束: %DATE% %TIME% ===
    echo === 返回码: %BUILD_RESULT% ===
) >> "%BUILD_LOG%" 2>&1

if %BUILD_RESULT% NEQ 0 (
    echo.
    echo [错误] 编译失败！返回码: %BUILD_RESULT%
    echo.
    echo ===== 编译错误 =====
    REM 显示包含 error 关键字的行
    findstr /i /n "error fatal" "%ERROR_LOG%" 2>nul
    if %ERRORLEVEL% NEQ 0 (
        REM 如果error log为空，从build log中查找
        findstr /i /n "error fatal" "%BUILD_LOG%" 2>nul
    )
    echo ====================
    echo.
    echo 完整编译日志: %BUILD_LOG%
    echo 错误日志:     %ERROR_LOG%
    exit /b 1
)

echo   [OK] 编译成功！
echo.

REM ============================================================================
REM  Step 5: 安装
REM ============================================================================
echo [Step 5/5] 安装到 %INSTALL_DIR% ...

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

if defined JOMEXE (
    "%JOMEXE%" install INSTALL_ROOT="%INSTALL_DIR%" >> "%BUILD_LOG%" 2>&1
) else (
    nmake install INSTALL_ROOT="%INSTALL_DIR%" >> "%BUILD_LOG%" 2>&1
)

if %ERRORLEVEL% NEQ 0 (
    echo [错误] 安装失败！
    echo 详细日志: %BUILD_LOG%
    exit /b 1
)

echo   [OK] 安装完成
echo.

REM ============================================================================
REM  完成
REM ============================================================================
echo ============================================================================
echo  编译完成！
echo  编译类型: %BUILD_TYPE%
echo  输出路径: %BUILD_DIR%\bin
echo  安装路径: %INSTALL_DIR%
echo  编译日志: %BUILD_LOG%
echo ============================================================================
echo.
echo 下一步:
echo   运行程序:  debug.bat
echo   发布部署:  deploy.bat
echo.

endlocal
exit /b 0
