Qt Hldplugin 4.12.1
=================

Qt Hldplugin version 4.12.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.12.0..v4.12.1

General
-------

* Fixed crash when changing font settings (QTHLDPLUGINBUG-14385)
* Fixed availability of `Link with Qt` information on startup (QTHLDPLUGINBUG-23900)

Editing
-------

### C++

* Fixed crash when loading settings from Qt Hldplugin < 4.11 (QTHLDPLUGINBUG-23916)

### QML

* Fixed semantic highlighting (QTHLDPLUGINBUG-23729, QTHLDPLUGINBUG-23777)
* Fixed wrong symbol highlighting (QTHLDPLUGINBUG-23830)
* Fixed warning for `palette` property (QTHLDPLUGINBUG-23830)

Projects
--------

### qmake

* Fixed that run button could stay disabled after parsing

### CMake

* Fixed issue with JOM (QTHLDPLUGINBUG-22645)

### Qbs

* Fixed crash when updating project (QTHLDPLUGINBUG-23924)

### Compilation Database

* Fixed issues with symbolic links (QTHLDPLUGINBUG-23511)

Debugging
---------

* Fixed startup when Python's JSON module is missing (QTHLDPLUGINBUG-24004)
* Fixed pretty printing of `std::unique_ptr` with custom deleter (QTHLDPLUGINBUG-23885)

### GDB

* Fixed handling of register addresses with lowercase characters
* Fixed issue with GDB reporting zero array size in some cases (QTHLDPLUGINBUG-23998)

Qt Quick Designer
-----------------

* Fixed crash after building emulation layer (QTHLDPLUGINBUG-20364)
* Fixed crash when opening `.qml` file instead of `.qml.ui` file (QDS-2011)

Test Integration
----------------

* Fixed handling of test output (QTHLDPLUGINBUG-23939)

Platforms
---------

### Android

* Fixed crash at startup when Qt is missing in Kit (QTHLDPLUGINBUG-23963)
* Fixed `Always use this device for this project` (QTHLDPLUGINBUG-23918)
* Fixed issue with "side by side" NDK installation (QTHLDPLUGINBUG-23903)

### OpenBSD

* Fixed Qt ABI detection (QTHLDPLUGINBUG-23818)

### MCU

* Fixed various issues with Kit creation and cleanup

Credits for these changes go to:
--------------------------------
Alessandro Portale  
André Pönitz  
Assam Boudjelthia  
Brook Cronin  
Christian Kandeler  
Christian Stenger  
Cristian Adam  
David Schulz  
Eike Ziller  
Friedemann Kleint  
Henning Gruendl  
Jeremy Ephron  
Johanna Vanhatapio  
Leander Schulten  
Leena Miettinen  
Nikolai Kosjar  
Robert Löhning  
Sebastian Verling  
Sergey Belyashov  
Thiago Macieira  
Thomas Hartmann  
Tim Jenssen  
Venugopal Shivashankar  
Vikas Pachdha  
