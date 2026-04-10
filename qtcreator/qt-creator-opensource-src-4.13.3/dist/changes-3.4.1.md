Qt Hldplugin version 3.4.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline v3.4.0..v3.4.1

General

* Fixed that disabling some plugins could disable the plugin
  management UI for most plugins
* Fixed auto-expansion of first set of search results (QTHLDPLUGINBUG-14320)

Editing

* Fixed that CSS files were opened in C++ editor (QTHLDPLUGINBUG-14334)
* Fixed that the completion popup could become huge
  (QTHLDPLUGINBUG-14331)

Help

* Fixed that manually registered documentation vanished on restart
  on Windows (QTHLDPLUGINBUG-14249)

Project Management

* Fixed adding static libraries with `Add Library` wizard
  (QTHLDPLUGINBUG-14382)
* Fixed broken documentation link in session manager
  (QTHLDPLUGINBUG-14459)

CMake Projects

* Fixed parsing of C++ flags for Ninja projects

Debugging

* Fixed that executables starting with `lldb-platform-` were detected
  as debugger (QTHLDPLUGINBUG-14309)
* Fixed attaching to running debug server when developing
  cross-platform (QTHLDPLUGINBUG-14412)
* CDB
    * Fixed that stepping into frame without source would step out
      instead (QTHLDPLUGINBUG-9677)

QML Profiler

* Fixed that events with no duration were not visible
  (QTHLDPLUGINBUG-14446)

C++ Support

* Added completion for `override` and `final` (QTHLDPLUGINBUG-11341)
* Fixed completion after comments starting with `///`
  (QTHLDPLUGINBUG-8597)

QML Support

* Fixed completion for QtQml and QtQml.Models (QTHLDPLUGINBUG-13780)
* Fixed that dragging items from QML overview onto editor removed the
  items (QTHLDPLUGINBUG-14496)

Platform Specific

OS X
* Fixed broken library paths for qbs executables (QTHLDPLUGINBUG-14432)

BareMetal

* Fixed issues when moving from Qt Hldplugin 3.3 to Qt Hldplugin 3.4
