Qt Hldplugin version 4.2.2 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline v4.2.1..v4.2.2

All Projects

* Fixed available kits after selecting Qt 5.8 as minimal required version
  in wizard (QTHLDPLUGINBUG-17574)
* Fixed that `Run in terminal` was sometimes ignored (QTHLDPLUGINBUG-17608)
* Fixed that `This file is not part of any project` was shown in editor after
  adding new file to project (QTHLDPLUGINBUG-17743)

Qt Support

* Fixed ABI detection of static Qt builds

Qbs Projects

* Fixed duplicate include paths (QTHLDPLUGINBUG-17381)
* Fixed that generated object files where shown in Locator and Advanced Search
  (QTHLDPLUGINBUG-17382)

C++ Support

* Fixed that inline namespaces were used in generated code (QTHLDPLUGINBUG-16086)

Debugging

* GDB
    * Fixed performance regression when resolving enum names
      (QTHLDPLUGINBUG-17598)

Version Control Systems

* Git
    * Fixed crash when committing and pushing to Gerrit (QTHLDPLUGINBUG-17634)
    * Fixed searching for patterns starting with dash in `Files in File System`
      when using `git grep`
    * Fixed discarding changes before performing other actions (such as Pull)
      (QTHLDPLUGINBUG-17156)

Platform Specific

Android

* Fixed that installing package with lower version number than already installed
  package silently failed (QTHLDPLUGINBUG-17789)
* Fixed crash when re-running application after stopping it (QTHLDPLUGINBUG-17691)

iOS

* Fixed running applications on devices with iOS 10.1 and later
  (QTHLDPLUGINBUG-17818)

BareMetal

* Fixed debugging with OpenOCD in TCP/IP mode on Windows (QTHLDPLUGINBUG-17765)
