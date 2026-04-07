@echo off
REM ============================================================================
REM  Qt Creator 4.13.3 一键编译+部署脚本
REM  Qt版本: 5.12.12    编译器: MSVC2017 x64
REM  
REM  此脚本依次执行: 编译 → 部署 → 验证
REM ============================================================================
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"

echo ############################################################################
echo #                                                                          #
echo #  Qt Creator 4.13.3 一键编译部署                                          #
echo #  Qt 5.12.12 + MSVC2017 x64                                              #
echo #                                                                          #
echo ############################################################################
echo.

REM --- 解析参数 ---
set "BUILD_TYPE=release"
set "SKIP_BUILD=0"
set "SKIP_DEPLOY=0"

:parse_args
if "%~1"=="" goto :done_args
if /i "%~1"=="debug" set "BUILD_TYPE=debug"
if /i "%~1"=="release" set "BUILD_TYPE=release"
if /i "%~1"=="--skip-build" set "SKIP_BUILD=1"
if /i "%~1"=="--skip-deploy" set "SKIP_DEPLOY=1"
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
shift
goto :parse_args

:show_help
echo 用法: build_all.bat [选项]
echo.
echo 选项:
echo   debug          编译Debug版本
echo   release        编译Release版本 (默认)
echo   --skip-build   跳过编译，只部署
echo   --skip-deploy  只编译，跳过部署
echo   --help, -h     显示此帮助
echo.
exit /b 0

:done_args

set "START_TIME=%TIME%"

REM ============================================================================
REM  Phase 1: 编译
REM ============================================================================
if "%SKIP_BUILD%"=="0" (
    echo.
    echo ======== Phase 1/3: 编译 ========
    echo.
    call "%SCRIPT_DIR%build.bat" %BUILD_TYPE%
    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo [失败] 编译阶段失败，中止。
        echo        请检查上方错误信息和日志文件。
        exit /b 1
    )
    echo.
    echo [成功] 编译阶段完成
) else (
    echo.
    echo ======== Phase 1/3: 编译 (已跳过) ========
)

REM ============================================================================
REM  Phase 2: 部署
REM ============================================================================
if "%SKIP_DEPLOY%"=="0" (
    echo.
    echo ======== Phase 2/3: 部署 ========
    echo.
    call "%SCRIPT_DIR%deploy.bat" --zip
    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo [失败] 部署阶段失败。
        exit /b 1
    )
    echo.
    echo [成功] 部署阶段完成
) else (
    echo.
    echo ======== Phase 2/3: 部署 (已跳过) ========
)

REM ============================================================================
REM  Phase 3: 快速验证
REM ============================================================================
echo.
echo ======== Phase 3/3: 快速验证 ========
echo.

set "VERIFY_OK=1"

REM 检查编译输出
if exist "%SCRIPT_DIR%build\bin\qtcreator.exe" (
    echo   [OK] 编译输出: build\bin\qtcreator.exe
) else (
    echo   [缺失] 编译输出: build\bin\qtcreator.exe
    set "VERIFY_OK=0"
)

REM 检查部署输出
if exist "%SCRIPT_DIR%deploy\QtCreator-4.13.3\bin\qtcreator.exe" (
    echo   [OK] 部署输出: deploy\QtCreator-4.13.3\bin\qtcreator.exe
) else (
    if "%SKIP_DEPLOY%"=="0" (
        echo   [缺失] 部署输出
        set "VERIFY_OK=0"
    )
)

REM 检查压缩包
if exist "%SCRIPT_DIR%deploy\QtCreator-4.13.3-win64.7z" (
    echo   [OK] 压缩包: deploy\QtCreator-4.13.3-win64.7z
)
if exist "%SCRIPT_DIR%deploy\QtCreator-4.13.3-win64.zip" (
    echo   [OK] 压缩包: deploy\QtCreator-4.13.3-win64.zip
)

echo.
echo ############################################################################
if "%VERIFY_OK%"=="1" (
    echo #  全部完成！
) else (
    echo #  完成，但有警告，请检查上方输出。
)
echo #  开始时间: %START_TIME%
echo #  结束时间: %TIME%
echo #
echo #  输出文件:
echo #    编译目录: %SCRIPT_DIR%build\
echo #    发布目录: %SCRIPT_DIR%deploy\QtCreator-4.13.3\
echo #    日志目录: %SCRIPT_DIR%logs\
echo #
echo #  后续操作:
echo #    运行程序: debug.bat
echo #    只重新部署: build_all.bat --skip-build
echo ############################################################################
echo.

endlocal
exit /b 0
