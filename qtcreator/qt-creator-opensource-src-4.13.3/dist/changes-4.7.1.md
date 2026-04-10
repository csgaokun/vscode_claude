Qt Hldplugin version 4.7.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.7.0..v4.7.1

Editing

* Fixed that generic highlighting could use unreadable colors
  (QTHLDPLUGINBUG-20919)

All Projects

* Fixed jumping text cursor when editing custom executable path

Qbs Projects

* Fixed C++ version passed to code model (QTHLDPLUGINBUG-20909)

C++ Support

* Clang Code Model
    * Fixed include order for Clang headers

QML Support

* Fixed that comments could break reformatting (QTHLDPLUGINBUG-21036)

Debugging

* Fixed remote debugging command line argument (QTHLDPLUGINBUG-20928)
* Fixed environment for `Start and Debug External Application`
  (QTHLDPLUGINBUG-20185)
* GDB
    * Fixed GDB built-in pretty printer handling (QTHLDPLUGINBUG-20770)
* CDB
    * Fixed pretty printing of enums
* QML
    * Fixed re-enabling breakpoints (QTHLDPLUGINBUG-20795)
    * Fixed `Attach to QML Port` (QTHLDPLUGINBUG-20168)

Platform Specific

Windows

* Improved resource consumption of MSVC detection, which prompted some
  Anti-Virus software to block Qt Hldplugin (QTHLDPLUGINBUG-20829)
* Fixed that Qt Hldplugin forced use of ANGLE on user applications
  (QTHLDPLUGINBUG-20808)
* Fixed MSVC toolchain detection for Windows SKD 7 (QTHLDPLUGINBUG-18328)

Remote Linux

* Switched SSH support to use Botan 2 (QTHLDPLUGINBUG-18802)

Credits for these changes go to:  
Andre Hartmann  
André Pönitz  
Christian Kandeler  
Christian Stenger  
David Schulz  
Eike Ziller  
Hannes Domani  
Ivan Donchevskii  
Leena Miettinen  
Marco Benelli  
Orgad Shaneh  
Robert Löhning  
scootergrisen  
Sergey Belyashov  
Thomas Hartmann  
Tobias Hunger  
Ulf Hermann  
