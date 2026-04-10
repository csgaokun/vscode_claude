Qt Hldplugin version 3.5.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline v3.5.0..v3.5.1

General

* Fixed dark theme for wizards (QTHLDPLUGINBUG-13395)
* Fixed that cancel button was ignored when wizards ask about overwriting files
  (QTHLDPLUGINBUG-15022)
* Added support for MSYS2 compilers and debuggers

Editing

* Fixed crashes with code completion (QTHLDPLUGINBUG-14991, QTHLDPLUGINBUG-15020)

Project Management

* Fixed that some context actions were wrongly enabled
  (QTHLDPLUGINBUG-14768, QTHLDPLUGINBUG-14728)

C++ Support

* Improved performance for Boost (QTHLDPLUGINBUG-14889, QTHLDPLUGINBUG-14741)
* Fixed that adding defines with compiler flag did not work with space after `-D`
  (QTHLDPLUGINBUG-14792)

QML Support

* Fixed that `.ui.qml` warnings accumulated when splitting (QTHLDPLUGINBUG-14923)

QML Profier

* Fixed that notes were saved but not loaded (QTHLDPLUGINBUG-15077)

Version Control Systems

* Git
    * Fixed encoding of log output
* Mercurial
    * Fixed crash when annotating (QTHLDPLUGINBUG-14975)

Diff Editor

* Fixed handling of mode changes (QTHLDPLUGINBUG-14963)

Platform Specific

Remote Linux

* Fixed wrong SSH key compatibility check

BareMetal

* Fixed that GDB server provider list did not update on host change
