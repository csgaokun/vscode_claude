Qt Hldplugin version 4.5.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline v4.5.0..v4.5.1

Help

* Fixed that mouse cursor got stuck in waiting state when jumping to
  anchor within open help page (QTHLDPLUGINBUG-19649)

All Projects

* Fixed predefined macro setting for custom toolchains (QTHLDPLUGINBUG-19714)

QMake Projects

* Fixed crash when importing build (QTHLDPLUGINBUG-19391)
* Fixed crash when switching file while project is parsing (QTHLDPLUGINBUG-19428)

Qbs Projects

* Fixed issue with toolchain setup (QTHLDPLUGINBUG-19467)
* Fixed reparsing after switching build configuration

Qt Quick Designer

* Fixed painting artifacts while resizing

Nim Support

* Fixed debugging (QTHLDPLUGINBUG-19414)

Debugging

* CDB
    * Improved performance when stepping (QTHLDPLUGINBUG-18613)

QML Profiler

* Fixed `Analyze Current Range` (QTHLDPLUGINBUG-19456)
* Fixed attaching to running application (QTHLDPLUGINBUG-19496)

Version Control Systems

* Gerrit
    * Fixed that dialog could use wrong repository (QTHLDPLUGINBUG-19562)

Platform Specific

Windows

* Fixed issue with `PATH` when running QMake project
* Fixed issue with `PATH` when debugging with GDB
* Fixed multiple registration of MSVC 2015 Build Tools

Universal Windows Platform

* Fixed that changes to deployment steps did not persist

Credits for these changes go to:  
Alessandro Portale  
Alexandru Croitor  
André Pönitz  
Christian Kandeler  
Christian Stenger  
David Schulz  
Eike Ziller  
Friedemann Kleint  
Ivan Donchevskii  
Jaroslaw Kobus  
Leena Miettinen  
Nikolai Kosjar  
Orgad Shaneh  
Oswald Buddenhagen  
Robert Löhning  
Samuel Gaist  
Sergey Belyashov  
Thomas Hartmann  
Tim Jenssen  
Tobias Hunger  
Ulf Hermann
