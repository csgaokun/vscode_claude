Qt Hldplugin version 4.0.3 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline v4.0.2..v4.0.3

All Projects

* Fixed disabled run button on FreeBSD and macOS 10.8
  (QTHLDPLUGINBUG-16462, QTHLDPLUGINBUG-16421)

QMake Projects

* Fixed ABI detection on NetBSD and OpenBSD

CMake Projects

* Fixed issues with opening projects from symbolic links

C++ Support

* Clang code model
    * Fixed dot-to-arrow conversion being incorrectly done for
      floating point literals and file suffixes (QTHLDPLUGINBUG-16188)

Test Integration

* Fixed crash when editing code while parsing for tests
