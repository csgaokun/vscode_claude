@echo off
REM ============================================================================
REM  Qt Creator 4.13.3 发布部署脚本
REM  Qt版本: 5.12.12    编译器: MSVC2017 x64
REM  功能: 收集所有依赖DLL，打包为可分发目录或7z包
REM ============================================================================
setlocal enabledelayedexpansion

REM --- 配置区 ---
set "QT_DIR=C:\Qt\Qt5.12.12\5.12.12\msvc2017_64"
set "BUILD_DIR=%~dp0build"
set "INSTALL_DIR=%~dp0install"
set "DEPLOY_DIR=%~dp0deploy\QtCreator-4.13.3"
set "LOG_DIR=%~dp0logs"
set "ARCHIVE_NAME=QtCreator-4.13.3-win64"

REM --- 解析命令行参数 ---
set "CREATE_ARCHIVE=1"
set "CREATE_ZIP=0"

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
if /i "%~1"=="--output" (
    set "DEPLOY_DIR=%~2"
    shift & shift
    goto :parse_args
)
if /i "%~1"=="--no-archive" (
    set "CREATE_ARCHIVE=0"
    shift
    goto :parse_args
)
if /i "%~1"=="--zip" (
    set "CREATE_ZIP=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
shift
goto :parse_args

:show_help
echo.
echo 用法: deploy.bat [选项]
echo.
echo 选项:
echo   --qt-dir PATH      指定Qt安装路径
echo   --build-dir PATH   指定构建输出路径
echo   --output PATH      指定发布输出路径
echo   --no-archive       不创建压缩包，只复制文件
echo   --zip              额外创建zip压缩包
echo   --help, -h         显示此帮助
echo.
echo 输出:
echo   deploy\QtCreator-4.13.3\     可分发的完整目录
echo   deploy\QtCreator-4.13.3-win64.7z   7z压缩包
echo.
exit /b 0

:done_args

REM --- 时间戳 ---
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "DATE_STAMP=%%a%%b%%c"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "TIME_STAMP=%%a%%b"
set "TIMESTAMP=%DATE_STAMP%_%TIME_STAMP%"

REM --- 日志 ---
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "DEPLOY_LOG=%LOG_DIR%\deploy_%TIMESTAMP%.log"

echo ============================================================================
echo  Qt Creator 4.13.3 发布部署
echo  Qt路径:   %QT_DIR%
echo  构建路径: %BUILD_DIR%
echo  发布路径: %DEPLOY_DIR%
echo  日志文件: %DEPLOY_LOG%
echo ============================================================================
echo.

(
    echo === 部署开始: %DATE% %TIME% ===
) > "%DEPLOY_LOG%"

REM ============================================================================
REM  Step 1: 检查环境
REM ============================================================================
echo [Step 1/6] 检查环境...

REM --- 检查构建输出 ---
set "SOURCE_BIN="
if exist "%BUILD_DIR%\bin\qtcreator.exe" (
    set "SOURCE_BIN=%BUILD_DIR%"
    echo   [OK] 找到构建输出: %BUILD_DIR%\bin\qtcreator.exe
) else if exist "%INSTALL_DIR%\bin\qtcreator.exe" (
    set "SOURCE_BIN=%INSTALL_DIR%"
    echo   [OK] 找到安装输出: %INSTALL_DIR%\bin\qtcreator.exe
) else (
    echo [错误] 找不到编译输出。请先运行 build.bat
    echo        检查过的路径:
    echo          %BUILD_DIR%\bin\qtcreator.exe
    echo          %INSTALL_DIR%\bin\qtcreator.exe
    exit /b 1
)

REM --- 检查windeployqt ---
set "WINDEPLOYQT=%QT_DIR%\bin\windeployqt.exe"
if not exist "%WINDEPLOYQT%" (
    echo [错误] 未找到 windeployqt.exe: %WINDEPLOYQT%
    exit /b 1
)
echo   [OK] 找到 windeployqt: %WINDEPLOYQT%
echo.

REM ============================================================================
REM  Step 2: 创建发布目录
REM ============================================================================
echo [Step 2/6] 创建发布目录结构...

if exist "%DEPLOY_DIR%" (
    echo   [INFO] 清理旧的发布目录...
    rmdir /s /q "%DEPLOY_DIR%"
)
mkdir "%DEPLOY_DIR%"
mkdir "%DEPLOY_DIR%\bin"
mkdir "%DEPLOY_DIR%\lib"
mkdir "%DEPLOY_DIR%\share"

echo   [OK] 发布目录已创建: %DEPLOY_DIR%
echo.

REM ============================================================================
REM  Step 3: 复制Qt Creator文件
REM ============================================================================
echo [Step 3/6] 复制 Qt Creator 文件...

REM --- 复制bin目录 ---
echo   复制 bin 目录...
xcopy /E /Y /Q "%SOURCE_BIN%\bin\*" "%DEPLOY_DIR%\bin\" >> "%DEPLOY_LOG%" 2>&1
echo   [OK] bin 目录已复制

REM --- 复制lib目录 ---
if exist "%SOURCE_BIN%\lib" (
    echo   复制 lib 目录...
    xcopy /E /Y /Q "%SOURCE_BIN%\lib\*" "%DEPLOY_DIR%\lib\" >> "%DEPLOY_LOG%" 2>&1
    echo   [OK] lib 目录已复制
)

REM --- 复制share目录 ---
if exist "%SOURCE_BIN%\share" (
    echo   复制 share 目录...
    xcopy /E /Y /Q "%SOURCE_BIN%\share\*" "%DEPLOY_DIR%\share\" >> "%DEPLOY_LOG%" 2>&1
    echo   [OK] share 目录已复制
)

REM --- 复制plugins ---
if exist "%SOURCE_BIN%\lib\qtcreator\plugins" (
    echo   复制 plugins 目录...
    if not exist "%DEPLOY_DIR%\lib\qtcreator\plugins" mkdir "%DEPLOY_DIR%\lib\qtcreator\plugins"
    xcopy /E /Y /Q "%SOURCE_BIN%\lib\qtcreator\plugins\*" "%DEPLOY_DIR%\lib\qtcreator\plugins\" >> "%DEPLOY_LOG%" 2>&1
    echo   [OK] plugins 目录已复制
)

echo.

REM ============================================================================
REM  Step 4: 使用 windeployqt 收集 Qt 依赖
REM ============================================================================
echo [Step 4/6] 使用 windeployqt 收集 Qt 依赖库...
echo   这可能需要几分钟...

set "PATH=%QT_DIR%\bin;%PATH%"

"%WINDEPLOYQT%" ^
    --release ^
    --no-translations ^
    --no-system-d3d-compiler ^
    --no-opengl-sw ^
    --dir "%DEPLOY_DIR%\bin" ^
    "%DEPLOY_DIR%\bin\qtcreator.exe" >> "%DEPLOY_LOG%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    echo [警告] windeployqt 对 qtcreator.exe 处理有警告，继续...
)

REM --- 对所有DLL也运行windeployqt ---
echo   处理额外的DLL依赖...
for %%F in ("%DEPLOY_DIR%\bin\*.dll") do (
    "%WINDEPLOYQT%" --release --no-translations --dir "%DEPLOY_DIR%\bin" "%%F" >> "%DEPLOY_LOG%" 2>&1
)
for %%F in ("%DEPLOY_DIR%\lib\qtcreator\*.dll") do (
    "%WINDEPLOYQT%" --release --no-translations --dir "%DEPLOY_DIR%\bin" "%%F" >> "%DEPLOY_LOG%" 2>&1
)

echo   [OK] Qt 依赖收集完成
echo.

REM ============================================================================
REM  Step 5: 复制MSVC运行时
REM ============================================================================
echo [Step 5/6] 检查 MSVC 运行时...

REM --- 复制MSVC运行时DLL ---
set "VCREDIST_COPIED=0"

REM 尝试从Windows系统目录复制
for %%D in (
    "vcruntime140.dll"
    "vcruntime140_1.dll"
    "msvcp140.dll"
    "msvcp140_1.dll"
    "msvcp140_2.dll"
    "concrt140.dll"
    "vccorlib140.dll"
    "ucrtbase.dll"
) do (
    if exist "C:\Windows\System32\%%~D" (
        copy /Y "C:\Windows\System32\%%~D" "%DEPLOY_DIR%\bin\" >nul 2>&1
        set "VCREDIST_COPIED=1"
    )
)

REM 尝试从MSVC redist目录复制
for /d %%V in ("C:\Program Files (x86)\Microsoft Visual Studio\2017\*") do (
    for /r "%%V\VC\Redist\MSVC" %%F in (vcruntime140.dll) do (
        if exist "%%F" (
            echo %%F | findstr /i "x64\\Microsoft" >nul 2>&1
            if !ERRORLEVEL! EQU 0 (
                for %%P in ("%%~dpF") do (
                    copy /Y "%%~dpF\vcruntime140.dll" "%DEPLOY_DIR%\bin\" >nul 2>&1
                    copy /Y "%%~dpF\msvcp140.dll" "%DEPLOY_DIR%\bin\" >nul 2>&1
                    copy /Y "%%~dpF\concrt140.dll" "%DEPLOY_DIR%\bin\" >nul 2>&1
                    set "VCREDIST_COPIED=1"
                )
            )
        )
    )
)

if "%VCREDIST_COPIED%"=="1" (
    echo   [OK] MSVC运行时DLL已复制
) else (
    echo   [提示] 未自动复制MSVC运行时DLL
    echo          目标机器需要安装 Visual C++ 2017 Redistributable (x64)
    echo          下载地址: https://aka.ms/vs/15/release/vc_redist.x64.exe
)

echo.

REM ============================================================================
REM  Step 6: 创建压缩包
REM ============================================================================
if "%CREATE_ARCHIVE%"=="1" (
    echo [Step 6/6] 创建压缩包...
    
    set "ARCHIVE_PATH=%~dp0deploy\%ARCHIVE_NAME%"
    
    REM --- 尝试7z ---
    where 7z.exe >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo   使用 7z 创建压缩包...
        7z a -t7z -mx=9 "!ARCHIVE_PATH!.7z" "%DEPLOY_DIR%\*" >> "%DEPLOY_LOG%" 2>&1
        if !ERRORLEVEL! EQU 0 (
            echo   [OK] 7z压缩包: !ARCHIVE_PATH!.7z
        ) else (
            echo   [错误] 7z压缩失败
        )
    ) else (
        echo   [提示] 未找到 7z.exe，跳过7z压缩
        echo          安装7z后可手动压缩: 7z a -t7z "%ARCHIVE_NAME%.7z" "%DEPLOY_DIR%\*"
    )
    
    REM --- 创建zip (如果请求) ---
    if "%CREATE_ZIP%"=="1" (
        where 7z.exe >nul 2>&1
        if !ERRORLEVEL! EQU 0 (
            echo   使用 7z 创建 zip 包...
            7z a -tzip "!ARCHIVE_PATH!.zip" "%DEPLOY_DIR%\*" >> "%DEPLOY_LOG%" 2>&1
            if !ERRORLEVEL! EQU 0 (
                echo   [OK] zip压缩包: !ARCHIVE_PATH!.zip
            )
        ) else (
            REM 使用PowerShell创建zip
            echo   使用 PowerShell 创建 zip 包...
            powershell -NoProfile -Command "Compress-Archive -Path '%DEPLOY_DIR%\*' -DestinationPath '!ARCHIVE_PATH!.zip' -Force" >> "%DEPLOY_LOG%" 2>&1
            if !ERRORLEVEL! EQU 0 (
                echo   [OK] zip压缩包: !ARCHIVE_PATH!.zip
            ) else (
                echo   [警告] zip压缩失败
            )
        )
    )
) else (
    echo [Step 6/6] 跳过压缩包创建 (--no-archive)
)

echo.

REM ============================================================================
REM  部署验证
REM ============================================================================
echo ============================================================================
echo  部署验证
echo ============================================================================
echo.

REM --- 检查关键文件 ---
set "VERIFY_OK=1"

echo   检查关键文件:
if exist "%DEPLOY_DIR%\bin\qtcreator.exe" (
    echo     [OK] qtcreator.exe
) else (
    echo     [缺失] qtcreator.exe
    set "VERIFY_OK=0"
)
if exist "%DEPLOY_DIR%\bin\Qt5Core.dll" (
    echo     [OK] Qt5Core.dll
) else (
    echo     [缺失] Qt5Core.dll
    set "VERIFY_OK=0"
)
if exist "%DEPLOY_DIR%\bin\Qt5Gui.dll" (
    echo     [OK] Qt5Gui.dll
) else (
    echo     [缺失] Qt5Gui.dll
    set "VERIFY_OK=0"
)
if exist "%DEPLOY_DIR%\bin\Qt5Widgets.dll" (
    echo     [OK] Qt5Widgets.dll
) else (
    echo     [缺失] Qt5Widgets.dll
    set "VERIFY_OK=0"
)
if exist "%DEPLOY_DIR%\bin\Qt5Network.dll" (
    echo     [OK] Qt5Network.dll
) else (
    echo     [缺失] Qt5Network.dll
    set "VERIFY_OK=0"
)
if exist "%DEPLOY_DIR%\bin\platforms\qwindows.dll" (
    echo     [OK] platforms\qwindows.dll
) else (
    echo     [缺失] platforms\qwindows.dll
    set "VERIFY_OK=0"
)

echo.

REM --- 统计文件 ---
set "FILE_COUNT=0"
for /r "%DEPLOY_DIR%" %%F in (*) do set /a FILE_COUNT+=1
echo   总文件数: %FILE_COUNT%

REM --- 统计大小 ---
set "TOTAL_SIZE=0"
for /f "tokens=3" %%S in ('dir /s "%DEPLOY_DIR%" 2^>nul ^| findstr "个文件"') do set "TOTAL_SIZE=%%S"
for /f "tokens=3" %%S in ('dir /s "%DEPLOY_DIR%" 2^>nul ^| findstr "File(s)"') do set "TOTAL_SIZE=%%S"
echo   总大小: 约 %TOTAL_SIZE% 字节

echo.

if "%VERIFY_OK%"=="1" (
    echo ============================================================================
    echo  部署完成！
    echo  发布目录: %DEPLOY_DIR%
    if exist "%~dp0deploy\%ARCHIVE_NAME%.7z" echo  7z压缩包: %~dp0deploy\%ARCHIVE_NAME%.7z
    if exist "%~dp0deploy\%ARCHIVE_NAME%.zip" echo  zip压缩包: %~dp0deploy\%ARCHIVE_NAME%.zip
    echo.
    echo  分发说明:
    echo    将 %DEPLOY_DIR% 整个目录复制到目标机器即可运行。
    echo    或解压 %ARCHIVE_NAME%.7z 到任意目录。
    echo    如未包含MSVC运行时，需先安装 VC++ 2017 Redistributable (x64)。
    echo ============================================================================
) else (
    echo ============================================================================
    echo  [警告] 部署可能不完整，请检查以上缺失文件！
    echo  详细日志: %DEPLOY_LOG%
    echo ============================================================================
)

echo.
endlocal
exit /b 0
