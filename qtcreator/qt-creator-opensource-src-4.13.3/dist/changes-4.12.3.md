Qt Hldplugin 4.12.3
=================

Qt Hldplugin version 4.12.3 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.12.2..v4.12.3

Editing
-------

* Fixed missing update of completions after cursor navigation (QTHLDPLUGINBUG-24071)

### QML

* Fixed line number for string literals (QTHLDPLUGINBUG-23777)

### GLSL

* Fixed freeze (QTHLDPLUGINBUG-24070)

Projects
--------

### CMake

* Fixed issue with `Add build library search path` and older CMake versions (QTHLDPLUGINBUG-23997)
* Fixed that projects without name were considered invalid (QTHLDPLUGINBUG-24044)

Debugging
---------

* Fixed QDateTime pretty printer for Qt 5.14 and newer
* Fixed QJson pretty printer for Qt 5.15 and newer (QTHLDPLUGINBUG-23827)

Platforms
---------

### Android

* Fixed that installing OpenSSL for Android in the settings could delete current working directory
  (QTHLDPLUGINBUG-24173)

### MCU

* Fixed issue with saving settings (QTHLDPLUGINBUG-24048)

Credits for these changes go to:
--------------------------------
Alessandro Portale  
André Pönitz  
Assam Boudjelthia  
Christian Stenger  
Cristian Adam  
David Schulz  
Eike Ziller  
Leena Miettinen  
Tobias Hunger  
