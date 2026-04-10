@echo off

REM test.bat: Test script to launch CDB.exe using the extension
REM with the tests/manual demo project.

REM !qthldplugincdbext.help
REM !qthldplugincdbext.assign local.this.m_w=44
REM !qthldplugincdbext.locals 0

set ROOT=d:\dev\qt4.7-vs8\hldplugin

set _NT_DEBUGGER_EXTENSION_PATH=%ROOT%\lib\qthldplugincdbext32
set EXT=qthldplugincdbext.dll
set EXE=%ROOT%\tests\manual\gdbdebugger\gui\debug\gui.exe

set CDB=D:\Programme\Debugging Tools for Windows (x86)\cdb.exe

echo %CDB%
echo %EXT% %_NT_DEBUGGER_EXTENSION_PATH%

echo "!qthldplugincdbext.pid"

REM Launch emulating cdbengine's setup with idle reporting
"%CDB%" -G -a%EXT% -c ".idle_cmd !qthldplugincdbext.idle" %EXE%
