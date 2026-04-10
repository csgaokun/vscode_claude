Qt Hldplugin version 4.2.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline v4.2.0..v4.2.1

General

* Fixed `Open Command Prompt Here` on Windows (QTHLDPLUGINBUG-17439)

Editing

* Fixed that viewport could change unexpectedly when block selection was
  active but not visible in viewport (QTHLDPLUGINBUG-17475)

Help

* Fixed crash when using drag & drop with bookmarks (QTHLDPLUGINBUG-17547)

All Projects

* Fixed issue with upgrading tool chain settings in auto-detected kits
* Fixed crash when setting custom executable (QTHLDPLUGINBUG-17505)
* Fixed MSVC support on Windows Vista and earlier (QTHLDPLUGINBUG-17501)

QMake Projects

* Fixed wrong warning about incompatible compilers
* Fixed various issues with run configurations
  (QTHLDPLUGINBUG-17462, QTHLDPLUGINBUG-17477)
* Fixed that `OTHER_FILES` and `DISTFILES` in subdirs projects were no longer
  shown in project tree (QTHLDPLUGINBUG-17473)
* Fixed crash caused by unnormalized file paths (QTHLDPLUGINBUG-17364)

Qbs Projects

* Fixed that target OS defaulted to host OS if tool chain does not specify
  target OS (QTHLDPLUGINBUG-17452)

Generic Projects

* Fixed that project files were no longer shown in project tree

C++ Support

* Fixed crash that could happen when using `auto` (QTHLDPLUGINBUG-16731)

Debugging

* Fixed issue with infinite message boxes being displayed
  (QTHLDPLUGINBUG-16971)
* Fixed `QObject` property extraction with namespaced Qt builds

Platform Specific

Windows

* Fixed detection of MSVC 2017 RC as MSVC 2017
* Fixed that environment detection could time out with MSVC
  (QTHLDPLUGINBUG-17474)

iOS

* Fixed that starting applications in simulator could fail, especially with
  iOS 10 devices (QTHLDPLUGINBUG-17336)

Android

* Fixed that password prompt was not shown again after entering invalid
  keystore password (QTHLDPLUGINBUG-17317)
