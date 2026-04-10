Qt Hldplugin version 4.5 contains bug fixes and new features.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/4.4..v4.5.0

General

* Implemented "fuzzy" camel case lookup similar to code completion for locator
  (QTHLDPLUGINBUG-3111)
* Changed `File System` pane to tree view with top level directory selectable
  from `Computer`, `Home`, `Projects`, and individual project root directories
  (QTHLDPLUGINBUG-8305)
* Fixed crash when closing Qt Hldplugin while searching for updates
  (QTHLDPLUGINBUG-19165)

Editing

* Added `Edit` > `Advanced` > `Sort Selected Lines`, replacing `Tools` >
  `External` > `Text` > `Sort Selection`

All Projects

* Added progress indicator to project tree while project is parsed
* Added support for changing the maximum number of lines shown in compile output
  (QTHLDPLUGINBUG-2200)

QMake Projects

* Fixed support of wildcards in `INSTALLS` variable (QTHLDPLUGINBUG-17935)
* Fixed that `QMAKE_CFLAGS` was not passed to code model

CMake Projects

* Added groups to CMake configuration UI
* Added option to change configuration variable types
* Added option to unset configuration variable
* Improved handling of CMake configuration changes on disk (QTHLDPLUGINBUG-17555)
* Improved simplified project tree (QTHLDPLUGINBUG-19040)
* Fixed that value was removed when renaming configuration variable
  (QTHLDPLUGINBUG-17926)
* Fixed that `PATH` environment was unnecessarily modified (QTHLDPLUGINBUG-18714)
* Fixed that QML errors in application output where not linked to the source
  (QTHLDPLUGINBUG-18586)

Qbs Projects

* Fixed that custom `installRoot` was not saved (QTHLDPLUGINBUG-18895)

C++ Support

* Fixed lookup of functions that differ only in const-ness of arguments
  (QTHLDPLUGINBUG-18475)
* Fixed detection of macros defined by tool chain for `C`
* Fixed that `Refactoring` context menu blocked UI while checking for available
  actions
* Fixed crash when refactoring class with errors (QTHLDPLUGINBUG-19180)
* Clang Code Model
    * Added sanity check to `Clang Code Model Warnings` option
      (QTHLDPLUGINBUG-18864)
    * Fixed completion in `std::make_unique` and `std::make_shared` constructors
      (QTHLDPLUGINBUG-18615)
    * Fixed that function argument completion switched selected overload back to
      default after typing comma (QTHLDPLUGINBUG-11688)
* GCC
    * Improved auto-detection to include versioned binaries and cross-compilers

QML Support

* Added wizards with different starting UI layouts
* Fixed that undo history was lost when reformatting file (QTHLDPLUGINBUG-18645)

Python Support

* Added simple code folding

Debugging

* Changed pretty printing of `QFlags` and bitfields to hexadecimal
* Fixed `Run in terminal` for debugging external application
  (QTHLDPLUGINBUG-18912)
* LLDB / macOS
    * Added pretty printing of Core Foundation and Foundation string-like types
      (QTHLDPLUGINBUG-18638)
* CDB
    * Fixed attaching to running process with command line arguments
      (QTHLDPLUGINBUG-19034)
* QML
    * Fixed changing values of ECMAScript strings (QTHLDPLUGINBUG-19032)

QML Profiler

* Improved robustness when faced with invalid data

Qt Quick Designer

* Added option to only show visible items in navigator
* Fixed crash in integrated code editor (QTHLDPLUGINBUG-19079)
* Fixed crash when Ctrl-clicking on newly refactored QML file
  (QTHLDPLUGINBUG-19064)
* Fixed filtering in Library view (QTHLDPLUGINBUG-19054)
* Fixed `Cmd + Left` in integrated code editor on macOS (QTHLDPLUGINBUG-19272)
* Fixed crash with `Become Last Sibling` and multiline expressions
  (QTHLDPLUGINBUG-19284)

Version Control Systems

* Added query for saving modified files before opening commit editor
  (QTHLDPLUGINBUG-3857)
* Git
    * Fixed issues with localized tool output (QTHLDPLUGINBUG-19017)

Test Integration

* Fixed issue with finding test target with CMake projects (QTHLDPLUGINBUG-17882,
  QTHLDPLUGINBUG-18922, QTHLDPLUGINBUG-18932)

Beautifier

* Clang Format
    * Added action `Disable Formatting for Selected Text`
    * Changed formatting without selection to format the syntactic entity
      around the cursor

Model Editor

* Added support for custom relations

SCXML Editor

* Fixed crash after warnings are removed

Platform Specific

Windows

* Fixed detection of Visual Studio Build Tools 2017 (QTHLDPLUGINBUG-19053)
* Fixed that environment variable keys were converted to upper case in build
  and run configurations (QTHLDPLUGINBUG-18915)

macOS

* Fixed several issues when using case sensitive file systems while `File system
  case sensitivity` is set to `Case Insensitive` (QTHLDPLUGINBUG-17929,
  QTHLDPLUGINBUG-18672, QTHLDPLUGINBUG-18678)

Android

* Removed support for local deployment (QTBUG-62995)
* Removed support for Ant
* Added UI for managing Android SDKs (QTHLDPLUGINBUG-18978)
* Improved Android settings
* Improved checks for minimum requirements of Android tools (QTHLDPLUGINBUG-18837)

iOS

* Fixed check for minimum Xcode version (QTHLDPLUGINBUG-18091)
* Fixed switching between simulator device types with Xcode 9
  (QTHLDPLUGINBUG-19270)

Universal Windows Platform

* Fixed deployment on Windows 10 Phone emulator

Credits for these changes go to:  
Alessandro Portale  
Alexander Volkov  
Andre Hartmann  
André Pönitz  
Benjamin Terrier  
Christian Kandeler  
Christian Stenger  
Claus Steuer  
Daniel Trevitz  
David Schulz  
Donald Carr  
Eike Ziller  
Filipe Azevedo  
Friedemann Kleint  
Ivan Donchevskii  
Jake Petroules  
Jaroslaw Kobus  
Jochen Becher  
Kai Köhne  
Knud Dollereder  
Laurent Montel  
Leena Miettinen  
Marco Benelli  
Marco Bubke  
Mitch Curtis  
Nikita Baryshnikov  
Nikolai Kosjar  
Oliver Wolff  
Orgad Shaneh  
Robert Löhning  
Ryuji Kakemizu  
Samuel Gaist  
scootergrisen  
Sergey Belyashov  
Serhii Moroz  
Thiago Macieira  
Thomas Hartmann  
Tim Jenssen  
Tobias Hunger  
Ulf Hermann  
Vikas Pachdha  
Viktor Kireev
