Qt Hldplugin version 4.7.2 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.7.1..v4.7.2

General

* Fixed crash when pressing wrong shortcut for recent projects in Welcome mode
  (QTHLDPLUGINBUG-21302)
* Fixed rare crash in file system view

Editing

* Fixed that collapsed text no longer showed up in tooltip (QTHLDPLUGINBUG-21040)
* Fixed crash with generic text completion (QTHLDPLUGINBUG-21192)

Generic Projects

* Fixed crash when adding file to sub-folder (QTHLDPLUGINBUG-21342)

C++ Support

* Fixed wrong value of `__cplusplus` define (QTHLDPLUGINBUG-20884)
* Clang Code Model
    * Fixed possible crash in `Follow Symbol Under Cursor`
    * Fixed crash when using `Select Block Up/Down` with lambda
      (QTHLDPLUGINBUG-20994)

Debugging

* CDB
    * Fixed pretty printing of `std::vector` without Python (QTHLDPLUGINBUG-21074)

Platform Specific

Windows

* Fixed saving of files when another application blocks atomic save operation
  (QTHLDPLUGINBUG-7668)
* Fixed wrongly added empty lines in application output (QTHLDPLUGINBUG-21215)

iOS

* Fixed issue with detecting iPhone XS (QTHLDPLUGINBUG-21291)

Remote Linux

* Fixed superfluous empty lines in application output (QTHLDPLUGINBUG-19367)

Credits for these changes go to:  
David Schulz  
Eike Ziller  
Friedemann Kleint  
Hannes Domani  
Ivan Donchevskii  
Jonathan Liu  
Kai Köhne  
Nikolai Kosjar  
Sergey Belyashov  
