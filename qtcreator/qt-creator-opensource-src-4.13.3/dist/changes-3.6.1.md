Qt Hldplugin version 3.6.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline v3.6.0..v3.6.1

Editing

* Fixed issues with setting font size (QTHLDPLUGINBUG-15608, QTHLDPLUGINBUG-15609)

Help

* Fixed opening external links (QTHLDPLUGINBUG-15491)

C++ Support

* Clang code model
    * Fixed crash when closing many documents fast (QTHLDPLUGINBUG-15532)
    * Fixed that HTML code was shown in completion tool tip (QTHLDPLUGINBUG-15630)
    * Fixed highlighting for using a namespaced type (QTHLDPLUGINBUG-15271)
    * Fixed highlighting of current parameter in function signature tool tip
      (QTHLDPLUGINBUG-15108)
    * Fixed that template parameters were not shown in function signature tool
      tip (QTHLDPLUGINBUG-15286)

Qt Support

* Fixed crash when updating code model for `.ui` files (QTHLDPLUGINBUG-15672)

QML Support

* Added Qt 5.6 as an option to the wizards

Debugging

* LLDB
    * Fixed that switching thread did not update stack view (QTHLDPLUGINBUG-15587)
* GDB/MinGW
    * Fixed editing values while debugging

Beautifier

* Fixed formatting with `clang-format`

Platform Specific

Windows

* Added detection of Microsoft Visual C++ Build Tools
* Fixed issue with console applications that run only for a short time
  `Cannot obtain a handle to the inferior: The parameter is incorrect`
  (QTHLDPLUGINBUG-13042)
* Fixed that debug messages could get lost after the application finished
  (QTHLDPLUGINBUG-15546)

Android

* Fixed issues with Gradle wrapper (QTHLDPLUGINBUG-15568)
