Qt Hldplugin 4.12.2
=================

Qt Hldplugin version 4.12.2 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.12.1..v4.12.2

General
-------

* Fixed line and column support for opening files with Locator

Editing
-------

### C++

* Fixed persistence of license template setting (QTHLDPLUGINBUG-24024)
* Fixed persistence of diagnostics configurations (QTHLDPLUGINBUG-23717)

### QML

* Fixed crash with QML Preview (QTHLDPLUGINBUG-24056)

Projects
--------

### Compilation Database

* Fixed that Kit's toolchain could change (QTHLDPLUGINBUG-24047)

Analyzer
--------

### Clang

* Fixed issue with Clazy 1.6 (QTHLDPLUGINBUG-23585)

Version Control Systems
-----------------------

### Git

* Fixed upstream status for branches with slash

Platforms
---------

### Android

* Fixed possible crash when Qt is missing in Kit

### WebAssembly

* Fixed running applications with Qt 5.15 (QTHLDPLUGINBUG-24072)

### MCU

* Added support for Qt for MCUs 1.2 (UL-1708, UL-2390, QTHLDPLUGINBUG-24063, QTHLDPLUGINBUG-24052,
  QTHLDPLUGINBUG-24079)
* Removed support for Qt for MCUs 1.1

Credits for these changes go to:
--------------------------------
Alessandro Portale  
André Pönitz  
Christian Kandeler  
Christian Stenger  
Eike Ziller  
Leena Miettinen  
Nikolai Kosjar  
Orgad Shaneh  
Tim Jenssen  
Ulf Hermann  
