Qt Hldplugin version 4.8.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.8.0..v4.8.1

General

* Fixed too large minimum size of preferences dialog (QTHLDPLUGINBUG-21678)

Editing

* Fixed that text marks could vanish (QTHLDPLUGINBUG-21628)
* Fixed wrong background color for some text highlighting items
  (QTHLDPLUGINBUG-21661)
* Fixed handling of system text encoding on Windows (QTHLDPLUGINBUG-21622)
* Language Client
    * Fixed crash after failed server restarts (QTHLDPLUGINBUG-21635)

All Projects

* Fixed crash when renaming file in file system view (QTHLDPLUGINBUG-21741)
* Fixed that `Create suitable run configurations automatically` setting was not
  saved (QTHLDPLUGINBUG-21796)

QMake Projects

* Fixed handling of `unversioned_libname` (QTHLDPLUGINBUG-21687)

C++ Support

* Clang Code Model
    * Fixed Clang backend crashes when `bugprone-suspicious-missing-comma` check
      is enabled (QTHLDPLUGINBUG-21605)
    * Fixed that `Follow Symbol` could be triggered after already moving to a
      different location
    * Fixed tooltip for pointer variables (QTHLDPLUGINBUG-21523)
    * Fixed issue with multi-line completion items (QTHLDPLUGINBUG-21600)
    * Fixed include order issue that could lead to issues with C++ standard
      headers and intrinsics
    * Fixed highlighting of lambda captures (QTHLDPLUGINBUG-15271)
    * Fixed issues with parsing Boost headers
      (QTHLDPLUGINBUG-16439, QTHLDPLUGINBUG-21685)

* Clang Format
    * Fixed handling of tab size (QTHLDPLUGINBUG-21280)

Debugging

* Fixed `Switch to previous mode on debugger exit` (QTHLDPLUGINBUG-21415)
* Fixed infinite loop that could happen when adding breaking on non-source line
  (QTHLDPLUGINBUG-21611, QTHLDPLUGINBUG-21616)
* Fixed that debugger tooltips were overridden by editor tooltips
  (QTHLDPLUGINBUG-21825)
* Fixed pretty printing of multi-dimensional C-arrays (QTHLDPLUGINBUG-19356,
  QTHLDPLUGINBUG-20639, QTHLDPLUGINBUG-21677)
* Fixed issues with pretty printing and typedefs (QTHLDPLUGINBUG-21602,
  QTHLDPLUGINBUG-18450)
* Fixed updating of breakpoints when code changes
* CDB
    * Fixed `Step Into` after toggling `Operate by Instruction`
      (QTHLDPLUGINBUG-21708)

Test Integration

* Fixed display of UTF-8 characters (QTHLDPLUGINBUG-21782)
* Fixed issues with custom test macros (QTHLDPLUGINBUG-19910)
* Fixed source code links for test failures on Windows (QTHLDPLUGINBUG-21744)

Platform Specific

Android

* Fixed `ANDROID_NDK_PLATFORM` setting for ARMv8 (QTHLDPLUGINBUG-21536)
* Fixed debugging on ARMv8
* Fixed crash while detecting supported ABIs (QTHLDPLUGINBUG-21780)

Credits for these changes go to:  
Aaron Barany  
Andre Hartmann  
André Pönitz  
Andy Shaw  
Christian Kandeler  
Christian Stenger  
David Schulz  
Eike Ziller  
Haxor Leet  
Ivan Donchevskii  
Knud Dollereder  
Leena Miettinen  
Marco Benelli  
Nikolai Kosjar  
Orgad Shaneh  
Robert Löhning  
Thomas Hartmann  
Tim Jenssen  
Vikas Pachdha  
