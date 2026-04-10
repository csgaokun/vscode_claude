Qt Hldplugin version 4.2 contains bug fixes and new features.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/4.1..v4.2.0

General

* Added experimental editor for Qt SCXML
* Added pattern substitution for variable expansion
  `%{variable/pattern/replacement}` (and `%{variable//pattern/replacement}`
  for replacing multiple matches)
* Added default values for variable expansion (`%{variable:-default}`)
* Added Help > System Information for bug reporting purposes
  (QTHLDPLUGINBUG-16135)
* Added option to hide the central widget in Debug mode
* Fixed issues with output pane height
  (QTHLDPLUGINBUG-15986, QTHLDPLUGINBUG-16829)

Welcome

* Added keyboard shortcuts for opening recent sessions and projects
* Improved performance when many sessions are shown
* Fixed dropping files on Qt Hldplugin when Welcome screen was visible
  (QTHLDPLUGINBUG-14194)

Editing

* Added action for selecting word under cursor (QTHLDPLUGINBUG-641)
* Fixed highlighting of Markdown files
  (QTHLDPLUGINBUG-16304)
* Fixed performance of cleaning whitespace (QTHLDPLUGINBUG-16420)
* Fixed selection color in help viewer for dark theme (QTHLDPLUGINBUG-16375)

Help

* Added option to open link and current page in window (QTHLDPLUGINBUG-16842)
* Fixed that no results could be shown in Locator (QTHLDPLUGINBUG-16753)

All Projects

* Reworked Projects mode UI
* Grouped all device options into one options category
* Added support for toolchains for different languages (currently C and C++)

QMake Projects

* Removed Qt Labs Controls wizard which is superseded by Qt Quick Controls 2
* Fixed that run button could spuriously stay disabled
  (QTHLDPLUGINBUG-16172, QTHLDPLUGINBUG-15583)
* Fixed `Open with Designer` and `Open with Linguist` for mobile and embedded Qt
  (QTHLDPLUGINBUG-16558)
* Fixed Add Library wizard when selecting library from absolute path or
  different drive (QTHLDPLUGINBUG-8413, QTHLDPLUGINBUG-15732, QTHLDPLUGINBUG-16688)
* Fixed issue with make steps in deploy configurations (QTHLDPLUGINBUG-16795)

CMake Projects

* Added support for CMake specific snippets
* Added support for platforms and toolsets
* Added warning for unsupported CMake versions
* Added drop down for selecting predefined values for properties
* Improved performance of opening project (QTHLDPLUGINBUG-16930)
* Made it possible to select CMake application on macOS
* Fixed that all unknown build target types were mapped to `ExecutableType`

Qbs Projects

* Made generated files available in project tree (QTHLDPLUGINBUG-15978)
* Fixed handling of generated files (QTHLDPLUGINBUG-16976)

C++ Support

* Added preview of images to tool tip on Qt resource URLs
* Added option to skip big files when indexing (QTHLDPLUGINBUG-16712)
* Fixed random crash in LookupContext (QTHLDPLUGINBUG-14911)
* Fixed `Move Definition to Class` for functions in template class and
  template member functions (QTHLDPLUGINBUG-14354)
* Fixed issues with `Add Declaration`, `Add Definition`, and
  `Move Definition Outside Class` for template functions
* Clang Code Model
    * Added notification for parsing errors in headers
    * Improved responsiveness of completion and highlighting

QML Support

* Fixed handling of circular dependencies (QTHLDPLUGINBUG-16585)

Debugging

* Added pretty printing of `QRegExp` captures, `QStaticStringData`,
  `QStandardItem`, `std::weak_ptr`, `std::__1::multiset`,
  and `std::pair`
* Added display of QObject hierarchy and properties in release builds
* Added support to pretty-print custom types without debug info
* Enhanced display of function pointers
* Improved pretty printing of QV4 types
* Made display of associative containers, pairs, and various smart
  pointers more compact
* Made creation of custom pretty printers easier
* Fixed pretty printing of `QFixed`
* Fixed scrolling in memory editor (QTHLDPLUGINBUG-16751)
* Fixed expansion of items in tool tip (QTHLDPLUGINBUG-16947)
* GDB
    * Fixed handling of built-in pretty printers from new versions of GDB
      (QTHLDPLUGINBUG-16758)
    * Fixed that remote working directory was used for local process
      (QTHLDPLUGINBUG-16211)
* LLDB
    * Added support for Qt Hldplugin variables `%{...}` in startup commands
* CDB
    * Fixed display order of vectors in vectors (QTHLDPLUGINBUG-16813)
    * Fixed display of QList contents (QTHLDPLUGINBUG-16750)
* QML
    * Fixed that expansion state was reset when stepping
    * Fixed `Load QML Stack` with Qt 5.7 and later (QTHLDPLUGINBUG-17097)

QML Profiler

* Added option to show memory usage and allocations as flame graph
* Added option to show vertical orientation lines in timeline
  (click the time ruler)
* Separated compile events from other QML/JS events in statistics and
  flamegraph, since compilation can happen asynchronously

Qt Quick Designer

* Added completion to expression editor
* Added menu for editing `when` condition of states
* Added editor for managing C++ backend objects
* Added reformatting of `.ui.qml` files on save
* Added support for exporting single properties
* Added support for padding (Qt Quick 2.6)
* Added support for elide and various font properties to text items
* Fixed that it was not possible to give extracted components
  the file extension `.ui.qml`
* Fixed that switching from Qt Quick Designer failed to commit pending changes
  (QTHLDPLUGINBUG-14830)
* Fixed issues with pressing escape

Qt Designer

* Fixed that resources could not be selected in new form
  (QTHLDPLUGINBUG-15560)

Diff Viewer

* Added local diff for modified files in Qt Hldplugin (`Tools` > `Diff` >
  `Diff Current File`, `Tools` > `Diff` > `Diff Open Files`)
  (QTHLDPLUGINBUG-9732)
* Added option to diff files when they changed on disk
  (QTHLDPLUGINBUG-1531)
* Fixed that reload prompt was shown when reverting change

Version Control Systems

* Gerrit
    * Fixed pushing to Gerrit when remote repository is empty
      (QTHLDPLUGINBUG-16780)

Test Integration

* Added option to disable crash handler when debugging
* Fixed that results were not shown when debugging (QTHLDPLUGINBUG-16693)
* Fixed that progress indicator sometimes did not stop

Model Editor

* Added zooming
* Added synchronization of selected diagram in diagram browser

Beautifier

* Fixed that beautifier was not enabled for Objective-C/C++ files
  (QTHLDPLUGINBUG-16806)

Platform Specific

Windows

* Added support for MSVC 2017
* Fixed that environment variables containing special characters were not
  passed correctly to user applications (QTHLDPLUGINBUG-17219)

macOS

* Fixed issue with detecting LLDB through `xcrun`

Android

* Added API level 24 for Android 7
* Improved stability of determination if application is running
* Fixed debugging on Android 6+ with NDK r11+ (QTHLDPLUGINBUG-16721)
* Fixed that running without deployment did not start emulator
  (QTHLDPLUGINBUG-10237)
* Fixed that permission model downgrade was not detected as error
  (QTHLDPLUGINBUG-16630)
* Fixed handling of minimum required API level (QTHLDPLUGINBUG-16740)

iOS

* Fixed simulator support with Xcode 8 (QTHLDPLUGINBUG-16942)
* Fixed that standard paths reported by QStandardPaths were wrong when
  running on simulator (QTHLDPLUGINBUG-13655)
* Fixed QML debugging on device (QTHLDPLUGINBUG-15812)

Remote Linux

* Fixed crash when creating SSH key pair (QTHLDPLUGINBUG-17349)

QNX

* Fixed QML debugging (QTHLDPLUGINBUG-17208)

Credits for these changes go to:  
Aaron Barany  
Alessandro Portale  
Alexander Drozdov  
Andre Hartmann  
André Pönitz  
Arnold Dumas  
Christian Kandeler  
Christian Stenger  
Daniel Langner  
Daniel Trevitz  
David Schulz  
Eike Ziller  
Florian Apolloner  
Francois Ferrand  
Friedemann Kleint  
Giuseppe D'Angelo  
Jake Petroules  
Jaroslaw Kobus  
Jochen Becher  
Konstantin Shtepa  
Kudryavtsev Alexander  
Leena Miettinen  
Louai Al-Khanji  
Marc Reilly  
Marco Benelli  
Marco Bubke  
Mitch Curtis  
Nazar Gerasymchuk  
Nikita Baryshnikov  
Nikolai Kosjar  
Orgad Shaneh  
Oswald Buddenhagen  
Øystein Walle  
Robert Löhning  
Serhii Moroz  
Takumi ASAKI  
Tasuku Suzuki  
Thomas Hartmann  
Tim Jenssen  
Tobias Hunger  
Ulf Hermann  
Vikas Pachdha  
