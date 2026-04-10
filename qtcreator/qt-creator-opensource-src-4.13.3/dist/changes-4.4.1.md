Qt Hldplugin version 4.4.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline v4.4.0..v4.4.1

FakeVim

* Fixed recognition of shortened `tabnext` and `tabprevious` commands
  (QTHLDPLUGINBUG-18843)

All Projects

* Fixed `Add Existing Files` for top-level project nodes (QTHLDPLUGINBUG-18896)

C++ Support

* Improved handling of parsing failures (QTHLDPLUGINBUG-18864)
* Fixed crash with invalid raw string literal (QTHLDPLUGINBUG-18941)
* Fixed that code model did not use sysroot as reported from the build system
  (QTHLDPLUGINBUG-18633)
* Fixed highlighting of `float` in C files (QTHLDPLUGINBUG-18879)
* Fixed `Convert to Camel Case` (QTHLDPLUGINBUG-18947)

Debugging

* Fixed that custom `solib-search-path` startup commands were ignored
  (QTHLDPLUGINBUG-18812)
* Fixed `Run in terminal` when debugging external application
  (QTHLDPLUGINBUG-18912)
* Fixed pretty printing of `CHAR` and `WCHAR`

Clang Static Analyzer

* Fixed options passed to analyzer on Windows

Qt Quick Designer

* Fixed usage of `shift` modifier when reparenting layouts

SCXML Editor

* Fixed eventless transitions (QTHLDPLUGINBUG-18345)

Test Integration

* Fixed test result output when debugging

Platform Specific

Windows

* Fixed auto-detection of CMake 3.9 and later

Android

* Fixed issues with new Android SDK (26.1.1) (QTHLDPLUGINBUG-18962)
* Fixed search path for QML modules when debugging

QNX

* Fixed debugging (QTHLDPLUGINBUG-18804, QTHLDPLUGINBUG-17901)
* Fixed QML profiler startup (QTHLDPLUGINBUG-18954)
