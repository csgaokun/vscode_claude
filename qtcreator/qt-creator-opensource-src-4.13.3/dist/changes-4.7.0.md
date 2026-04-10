Qt Hldplugin version 4.7 contains bug fixes and new features.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/4.6..v4.7.0

General

* Added option for enabling and disabling HiDPI scaling on Windows and Linux
  (QTHLDPLUGINBUG-20232)
* Added `Properties` item to context menu on files (QTHLDPLUGINBUG-19588)
* Added `New Search` button to search results pane (QTHLDPLUGINBUG-17870)
* Added option to show only icons in mode selector (QTHLDPLUGINBUG-18845)
* File System View
    * Added `New Folder` (QTHLDPLUGINBUG-17358)
    * Added `Collapse All` (QTHLDPLUGINBUG-19212)
    * Added option to show folders on top (QTHLDPLUGINBUG-7818)
    * Made synchronization of root directory with current document optional
      (QTHLDPLUGINBUG-19322)
* Fixed that external tools did not expand variables for environment changes

Editing

* Made replacement with regular expression search more perl-like (`$<number>`
  and `$&` are supported, whereas `&` is no longer used for captures)
  (QTHLDPLUGINBUG-9602, QTHLDPLUGINBUG-15175)
* Added `Context Help` to editor context menu (QTHLDPLUGINBUG-55)
* Added previous and next buttons to bookmarks view, and polished their
  behavior (QTHLDPLUGINBUG-9859, QTHLDPLUGINBUG-20061)
* Added support for `WordDetect` in Kate highlighting files
* Fixed that extra editor windows were not restored when opening session
  (QTHLDPLUGINBUG-13840)
* Fixed that editor could stay busy repainting annotations (QTHLDPLUGINBUG-20422)
* FakeVim
    * Added `:<range>sor[t][!]`

Help

* Improved performance impact on start up

All Projects

* Moved kit settings to separate options category
* Made it easier to abort builds by changing build button to stop button while
  building (QTHLDPLUGINBUG-20155)
* Added project type specific warnings and errors for kits, and made them
  visible in `Projects` mode
* Added shortcut for showing current document in project tree
  (QTHLDPLUGINBUG-19625)
* Added global option for `Add linker library search paths to run environment`
  (QTHLDPLUGINBUG-20240)
* Added `%{CurrentBuild:Env}` Qt Hldplugin variable

QMake Projects

* Added support for `-isystem` in `QMAKE_CXXFLAGS`
* Added deployment rules for devices to widget and console application wizards
  (QTHLDPLUGINBUG-20358)
* Fixed that arguments for QMake step did not expand variables
* Fixed `lupdate` and `lrelease` external tools for Qt 5.9 and later
  (QTHLDPLUGINBUG-19892)

C++ Support

* Improved resize behavior of editor tool bar
  (QTHLDPLUGINBUG-15218, QTHLDPLUGINBUG-19386)
* Fixed auto-insertion of closing brace and semicolon after classes
  (QTHLDPLUGINBUG-19726)
* Fixed location information of macros (QTHLDPLUGINBUG-19905)
* Clang Code Model
    * Enabled by default
    * Switched to Clang 6.0
    * Implemented outline pane, outline dropdown and
      `C++ Symbols in Current Document` locator filter
    * Implemented `Follow Symbol` for single translation unit
    * Added type highlighting for Objective-C/C++
    * Added errors and warnings of current editor to Issues pane
      (category `Clang Code Model`)
    * Added highlighting style for overloaded operators (QTHLDPLUGINBUG-19659)
    * Added option to use `.clang-tidy` configuration file or checks string
    * Added default configurations for Clang-Tidy and Clazy checks
    * Added link to the documentation in tooltip for Clang-Tidy and Clazy
      diagnostics
    * Improved reparse performance and memory usage
    * Improved selecting and deselecting specific Clang-Tidy checks
    * Fixed slow completion in case Clang-Tidy or Clazy checks were enabled
    * Fixed crashes when closing documents fast
* Built-in Code Model
    * Added support for nested namespaces (QTHLDPLUGINBUG-16774)

QML Support

* Updated parser to Qt 5.10, adding support for user-defined enums
* Fixed that linter warning `M127` was shown as error (QTHLDPLUGINBUG-19534)
* Fixed that reformatting incorrectly removed quotes (QTHLDPLUGINBUG-17455)
* Fixed that `.pragma` and `.import` were removed when reformatting
  (QTHLDPLUGINBUG-13038)
* Fixed that import completion did not offer `QtWebEngine` (QTHLDPLUGINBUG-20723)

Python Support

* Added stack traces in application output to Issues pane (category `Python`)

Debugging

* Added `Leave Debug Mode` button to toolbar
* Fixed updating of memory view
* Fixed issue with restoring debugger views (QTHLDPLUGINBUG-20721)
* QML
    * Added support for nested properties (QTBUG-68474)
    * Fixed issue with different endianness (QTBUG-68721)
* Fixed Qt namespace detection with GDB 8 (QTHLDPLUGINBUG-19620)

Qt Quick Designer

* Fixed crash when adding quotes to text (QTHLDPLUGINBUG-20684)
* Fixed that meta data could move in source code even when no changes occurred
  (QTHLDPLUGINBUG-20686)

Clang Static Analyzer

* Renamed plugin to `ClangTools`
* Replaced Clang static analyzer by tool that runs Clang-Tidy and Clazy over
  whole project or a subset of the project's files

QML Profiler

* Improved performance of timeline
* Added zooming into flame graph items

Version Control Systems

* Git
    * Added `-git-show <ref>` command line parameter
* Gerrit
    * Added warning when pushing to wrong branch (QTHLDPLUGINBUG-20062)
    * Fixed updating after settings change (QTHLDPLUGINBUG-20536)

Image Viewer

* Added option to export SVGs in multiple resolutions simultaneously

Test Integration

* Added `Run Test Under Cursor` to C++ editor
* Added editor marks for failed test locations (QTHLDPLUGINBUG-20328)
* Google Test
    * Added support for filters
    * Fixed issue with jumping to file and line of failing test
      (QTHLDPLUGINBUG-18725)
* Qt Quick
    * Fixed parsing issue with non-ASCII characters (QTHLDPLUGINBUG-20105)
    * Fixed detection of test name (QTHLDPLUGINBUG-20642)
    * Fixed detection when `quick_test_main()` is used directly
      (QTHLDPLUGINBUG-20746)

Welcome

* Rather than open project do nothing when right-clicking recent projects
* Open session mini menu when right-clicking sessions

Platform Specific

Windows

* Improved parsing of MSVC error messages (QTHLDPLUGINBUG-20297)
* Fixed that querying MSVC tool chains at startup could block Qt Hldplugin
* Fixed issue with writing to network drives (QTHLDPLUGINBUG-20560)
* Fixed issue with Clang and Qt 5.8 and later (QTHLDPLUGINBUG-20021)
* Fixed handling of Windows debug stream which could lead to freezes
  (QTHLDPLUGINBUG-20640)

Android

* Improved behavior when emulator cannot be started (QTHLDPLUGINBUG-20160)
* Fixed QML debugger connection issue from macOS client (QTHLDPLUGINBUG-20730)

Credits for these changes go to:  
Aaron Barany  
Aleix Pol  
Alessandro Portale  
Alexander Drozdov  
Alexandru Croitor  
Andre Hartmann  
André Pönitz  
Antonio Di Monaco  
Arnold Dumas  
Benjamin Balga  
Christian Kandeler  
Christian Stenger  
Claus Steuer  
Colin Duquesnoy  
David Schulz  
Eike Ziller  
Filipe Azevedo  
Friedemann Kleint  
Hugo Holgersson  
Ivan Donchevskii  
Jaroslaw Kobus  
Jay Gupta  
José Tomás Tocino  
Jörg Bornemann  
Kai Köhne  
Kari Oikarinen  
Kimmo Linnavuo  
Leena Miettinen  
Lorenz Haas  
Marco Benelli  
Marco Bubke  
Mitch Curtis  
Nikita Baryshnikov  
Nikolai Kosjar  
Orgad Shaneh  
Oswald Buddenhagen  
Pawel Rutka  
Przemyslaw Gorszkowski  
Razi Alavizadeh  
Robert Löhning  
Rune Espeseth  
scootergrisen  
Sergey Belyashov  
Sergey Morozov  
Tasuku Suzuki  
Thiago Macieira  
Thomas Hartmann  
Tim Jenssen  
Tobias Hunger  
Ulf Hermann  
Vikas Pachdha  
