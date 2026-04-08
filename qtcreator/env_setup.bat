@echo off
REM ============================================================================
REM  MSVC2017 x64 + Qt 5.12.12 编译环境初始化脚本
REM  
REM  用法: 双击此脚本打开一个已配置好的命令行窗口，然后在其中运行:
REM    build.bat          编译
REM    debug.bat          运行/调试
REM    deploy.bat         部署发布
REM    build_all.bat      一键全部执行
REM ============================================================================
setlocal

set "QT_DIR=C:\Qt\Qt5.12.12\5.12.12\msvc2017_64"

echo ============================================================================
echo  正在初始化 MSVC2017 x64 编译环境...
echo ============================================================================
echo.

REM --- 查找并调用vcvars64.bat ---
set "VCVARS_FOUND=0"

for %%E in (Enterprise Professional Community BuildTools) do (
    set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2017\%%E\VC\Auxiliary\Build\vcvars64.bat"
    if exist "!VCVARS!" (
        echo 找到 VS2017 %%E
        call "!VCVARS!"
        set "VCVARS_FOUND=1"
        goto :vcvars_done
    )
)

:vcvars_done
if "%VCVARS_FOUND%"=="0" (
    echo [错误] 未找到 Visual Studio 2017
    echo        请安装 Visual Studio 2017 或手动调用 vcvars64.bat
    pause
    exit /b 1
)

REM --- 设置Qt路径 ---
set "PATH=%QT_DIR%\bin;%PATH%"

echo.
echo ============================================================================
echo  环境已就绪！
echo.
echo  MSVC: & where cl.exe
echo  Qt:   & qmake -query QT_VERSION
echo.
echo  可用命令:
echo    build.bat          编译 (默认Release)
echo    build.bat debug    编译Debug版本
echo    build.bat clean    清理构建
echo    debug.bat          运行Qt Creator
echo    debug.bat --cdb    用CDB调试器运行
echo    deploy.bat         部署发布
echo    build_all.bat      一键编译+部署
echo ============================================================================
echo.

REM --- 打开交互式shell ---
cmd /k "cd /d %~dp0"
