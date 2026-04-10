Qt Hldplugin 4.13.3
=================

Qt Hldplugin version 4.13.3 contains bug fixes.

The most important changes are listed in this document. For a complete list of
changes, see the Git log for the Qt Hldplugin sources that you can check out from
the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.13.2..v4.13.3

General
-------

* Updated prebuilt binaries to Qt 5.15.2 which fixes drag & drop on macOS

Editing
-------

### QML

* Fixed reformatting of required properties (QTHLDPLUGINBUG-24376)
* Fixed importing without specific version for Qt 6 (QTHLDPLUGINBUG-24533)

Projects
--------

* Fixed auto-scrolling of compile output window (QTHLDPLUGINBUG-24728)
* Fixed GitHub Actions for Qt Hldplugin plugin wizard (QTHLDPLUGINBUG-24412)
* Fixed crash with `Manage Sessions` (QTHLDPLUGINBUG-24797)

Qt Quick Designer
-----------------

* Fixed crash when opening malformed `.ui.qml` file (QTHLDPLUGINBUG-24587)

Debugging
---------

### CDB

* Fixed pretty printing of `std::vector` and `std::string` in release mode

Analyzer
--------

### QML Profiler

* Fixed crash with `Analyze Current Range` (QTHLDPLUGINBUG-24730)

Platforms
---------

### Android

* Fixed modified state of manifest editor when changing app icons
  (QTHLDPLUGINBUG-24700)

Credits for these changes go to:
--------------------------------
Alexandru Croitor  
Christian Kandeler  
Christian Stenger  
David Schulz  
Dominik Holland  
Eike Ziller  
Fawzi Mohamed  
Friedemann Kleint  
Ivan Komissarov  
Johanna Vanhatapio  
Leena Miettinen  
Lukasz Ornatek  
Robert Löhning  
Tim Jenssen  
Ville Voutilainen  
Xiaofeng Wang  
