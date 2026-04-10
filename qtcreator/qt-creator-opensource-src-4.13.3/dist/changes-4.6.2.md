Qt Hldplugin version 4.6.2 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline v4.6.1..v4.6.2

General

QMake Projects

* Fixed reparsing after changes (QTHLDPLUGINBUG-20113)

Qt Support

* Fixed detection of Qt Quick Compiler in Qt 5.11 (QTHLDPLUGINBUG-19993)

C++ Support

* Fixed flags for C files with MSVC (QTHLDPLUGINBUG-20198)

Debugging

* Fixed crash when attaching to remote process (QTHLDPLUGINBUG-20331)

Platform Specific

macOS

* Fixed signature of pre-built binaries (QTHLDPLUGINBUG-20370)

Android

* Fixed path to C++ includes (QTHLDPLUGINBUG-20340)

QNX

* Fixed restoring deploy steps (QTHLDPLUGINBUG-20248)

Credits for these changes go to:  
Alessandro Portale  
André Pönitz  
Christian Stenger  
Eike Ziller  
Ivan Donchevskii  
Oswald Buddenhagen  
Robert Löhning  
Ulf Hermann  
Vikas Pachdha  
