Qt Hldplugin version 4.4 contains bug fixes and new features.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/4.3..v4.4.0

General

* Added highlighting of search term in Locator results
* Added larger icons to `New` dialog
* Added locator input to extra editor and help windows (QTHLDPLUGINBUG-9696)
* Fixed theming of Debugger Console and TODO pane (QTHLDPLUGINBUG-17532)

Help

* QtWebEngine backend
    * Fixed that wait cursor was sometimes never restored (QTHLDPLUGINBUG-17758)

Editing

* Added optional inline annotations for Clang code model errors and warnings,
  and bookmarks
* Added optional smooth scrolling when navigating within the same file
  (for example with Locator or `Follow Symbol Under Cursor`)
* Added overridable `DeleteStartOfLine` and `DeleteEndOfLine` actions
  (QTHLDPLUGINBUG-18095)
* Added support for relative path to active project to `Advanced Find` >
  `Files in File System` (QTHLDPLUGINBUG-18139)
* Added colors to default text editor scheme (the previous default is
  available as `Default Classic`)
* FakeVim
    * Fixed `gt`/`gT`/`:tabnext`/`:tabprevious`

All Projects

* Improved detection of cross-compilers

CMake Projects

* Added option to filter for CMake variables in build configuration
  (QTHLDPLUGINBUG-17973)
* Added warning when detecting `CMakeCache.txt` in source directory even though
  build is configured for out-of-source build (QTHLDPLUGINBUG-18381)
* Fixed `CMake configuration has changed on disk` dialog (QTHLDPLUGINBUG-18292)
* CMake >= 3.7
    * Improved handling of `CMAKE_RUNTIME_OUTPUT_DIRECTORY` (QTHLDPLUGINBUG-18158)
    * Removed `<Source Directory>` node from project tree
    * Fixed that headers from top level directory were not shown in project tree
      (QTHLDPLUGINBUG-17760)
    * Fixed progress information (QTHLDPLUGINBUG-18624)

Qbs Projects

* Re-added `Qbs install` deploy step (QTHLDPLUGINBUG-17958)
* Added `rebuild` and `clean` actions to products and subprojects
  (QTHLDPLUGINBUG-15919)

C++ Support

* Added option to rename files when renaming symbol using same name
  (QTHLDPLUGINBUG-14696)
* Added auto-insertion of matching curly brace (QTHLDPLUGINBUG-15073)
* Fixed that C++ and Qt keywords were considered keywords in C files
  (QTHLDPLUGINBUG-2818, QTHLDPLUGINBUG-18004)
* Fixed highlighting of raw string literals (QTHLDPLUGINBUG-17720)
* Fixed `Add #include` refactoring action for static functions
* Fixed crash when parsing invalid C++ code (QTHLDPLUGINBUG-18499)
* Clang Code Model
    * Added highlighting of identifier under cursor, which was still
      delegated to built-in code model
    * Improved order of items in completion list
      (QTHLDPLUGINBUG-18319, QTHLDPLUGINBUG-15445)
    * Fixed function signature hint when completing constructors and functors
      (QTHLDPLUGINBUG-14882)
    * Fixed that completing function pointer was adding parentheses
      (QTHLDPLUGINBUG-17578)
    * Fixed completion inside function template (QTHLDPLUGINBUG-17222)
    * Fixed wrong column number with non-ASCII characters (QTHLDPLUGINBUG-16775)
    * Fixed highlighting of primitive types and operators (QTHLDPLUGINBUG-17867)
    * Fixed highlighting of partial template specializations
    * Fixed highlighting of functions in `using` declarations
    * Fixed that keywords were highlighted in preprocessor directives
      (QTHLDPLUGINBUG-15516)
* Built-in Code Model
    * Fixed completion of STL containers (QTHLDPLUGINBUG-1892)

QML Support

* Updated QML parser to newer QML version (QTHLDPLUGINBUG-17842)
* Fixed crash in QML `Outline` pane
* Fixed that auto-completion could overwrite text (QTHLDPLUGINBUG-18449)

Debugging

* Added `Alt+V` + letter shortcuts to open views
* Added pretty printing for `qfloat16`, `std::{optional,byte}`, `gsl::{span,byte}`
  and `boost::variant`
* Improved display of enum bitfields
* Fixed support for `long double` (QTHLDPLUGINBUG-18023)
* Fixed editing of strings (QTHLDPLUGINBUG-18681)
* LLDB
    * Fixed disassembly view for code that contains quotes (QTHLDPLUGINBUG-18721)
* CDB
    * Added support for extra debugging helpers and debugging helper
      customization
    * Added warning if run configuration uses unsupported shell command

QML Profiler

* Fixed that timeline could stay empty after analyzing small range
  (QTHLDPLUGINBUG-18354)

Qt Quick Designer

* Fixed context menu items that did not work on macOS (QTHLDPLUGINBUG-18662)

Version Control Systems

* Fixed format of visual whitespace in blame, log and git rebase editors
  (QTHLDPLUGINBUG-17735)
* Git
    * Improved branch listing in `Show` (QTHLDPLUGINBUG-16949)
    * Made `git grep` for file system search recurse into submodules
* Gerrit
    * Added validation of server certificate when using REST API
    * Fixed that non-Gerrit remotes were shown in `Push to Gerrit` dialog
      (QTHLDPLUGINBUG-16367)
* ClearCase
    * Disabled by default

Diff Viewer

* Improved performance
* Fixed state of actions in `Edit` menu
* Fixed that context information for chunks was not shown in side-by-side view
  (QTHLDPLUGINBUG-18289)
* Fixed that UI blocked when showing very large diffs

Test Integration

* Added view with complete, unprocessed test output
* Made it possible to enable and disable all tests using a specific test
  framework
* Fixed wrong location of results for tests with same name (QTHLDPLUGINBUG-18502)
* QTest
    * Added option to run verbose and with logging of signals and slots
      (`-vb` and `-vs`)

Beautifier

* Added option for using a different AStyle configuration file
* Added option for fallback style for `clang-format`

Model Editor

* Fixed crash with invalid files (QTHLDPLUGINBUG-18526)
* Fixed crash when dropping package into itself (QTHLDPLUGINBUG-18262)

Platform Specific

Windows

* Removed support for Windows CE

macOS

* Fixed that some context menu items in Qt Quick Designer did nothing
  (QTHLDPLUGINBUG-18662)

Android

* Added support for API levels 25 and 26 (QTHLDPLUGINBUG-18690)
* Added support for `android-clang` (QTBUG-60455)
* Added option to run commands before app starts and after app stopped
* Fixed state of actions in `Edit` menu in text based manifest editor

iOS

* Added UI for managing simulator devices (QTHLDPLUGINBUG-17602)

Remote Linux

* Added support for `ssh-agent` (QTHLDPLUGINBUG-16245)

Universal Windows Platform

* Fixed deployment to Windows 10 Mobile devices (QTHLDPLUGINBUG-18728)

Credits for these changes go to:  
Alessandro Portale  
Alexander Drozdov  
Andre Hartmann  
André Pönitz  
Christian Kandeler  
Christian Stenger  
Daniel Teske  
David Schulz  
Eike Ziller  
Felix Kälberer  
Florian Apolloner  
Friedemann Kleint  
Ivan Donchevskii  
Jake Petroules  
Jaroslaw Kobus  
Jesus Fernandez  
Jochen Becher  
Jörg Bornemann  
Kai Köhne  
Leandro T. C. Melo  
Leena Miettinen  
Lorenz Haas  
Marco Benelli  
Marco Bubke  
Mitch Curtis  
Montel Laurent  
Nikita Baryshnikov  
Nikolai Kosjar  
Orgad Shaneh  
Przemyslaw Gorszkowski  
Robert Löhning  
Serhii Moroz  
Tasuku Suzuki  
Thiago Macieira  
Thomas Hartmann  
Tim Jenssen  
Tobias Hunger  
Tomasz Olszak  
Tor Arne Vestbø  
Ulf Hermann  
Vikas Pachdha
