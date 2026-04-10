Qt Hldplugin 4.12.4
=================

Qt Hldplugin version 4.12.4 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.12.3..v4.12.4

Editing
-------

* Fixed crash when searching in binary files (QTHLDPLUGINBUG-21473, QTHLDPLUGINBUG-23978)

### QML

* Fixed completion of signals from singletons (QTHLDPLUGINBUG-24124)
* Fixed import scanning after code model reset (QTHLDPLUGINBUG-24082)

Projects
--------

### CMake

* Fixed search for `ninja` when it is installed with the online installer (QTHLDPLUGINBUG-24082)

Platforms
---------

### iOS

* Fixed C++ debugging on devices (QTHLDPLUGINBUG-23995)

### MCU

* Adapted to changes in Qt for MCU 1.3

Credits for these changes go to:
--------------------------------
Alessandro Portale  
André Pönitz  
Christian Kamm  
Christian Stenger  
Eike Ziller  
Fawzi Mohamed  
Friedemann Kleint  
Robert Löhning  
Venugopal Shivashankar  
