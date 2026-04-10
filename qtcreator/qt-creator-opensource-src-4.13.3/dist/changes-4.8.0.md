Qt Hldplugin version 4.8 contains bug fixes and new features.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/4.7..v4.8.0

General

* Added `HostOs:PathListSeparator` and `HostOs:ExecutableSuffix` Qt Hldplugin
  variables
* Added `Create Folder` to context menu of path choosers if the path does not
  exist
* Fixed menu items shown in menu locator filter (QTHLDPLUGINBUG-20071,
  QTHLDPLUGINBUG-20626)
* Fixed crash at shutdown when multiple windows are open (QTHLDPLUGINBUG-21221)
* Fixed that items could appear empty in `Issues` pane (QTHLDPLUGINBUG-20542)
* Fixed Qt Quick wizards when building Qt Hldplugin with Qt 5.12

Editing

* Added experimental plugin `LanguageClient` for supporting the [language server
  protocol](https://microsoft.github.io/language-server-protocol)
  (QTHLDPLUGINBUG-20284)
* Added support for the pastecode.xyz code pasting service
* Made it possible to change default editors in MIME type settings
* Fixed issue with input methods (QTHLDPLUGINBUG-21483)

All Projects

* Added option for parallel jobs to `make` step, which is enabled by default
  if `MAKEFLAGS` are not set (QTHLDPLUGINBUG-18414)
* Added auto-detection of the Clang compiler shipped with Qt Hldplugin
* Added option for disabling automatic creation of run configurations
  (QTHLDPLUGINBUG-18578)
* Added option to open terminal with build or run environment to project tree
  and the corresponding configuration widgets in `Projects` mode
  (QTHLDPLUGINBUG-19692)
* Improved handling of relative file paths for custom error parsers
  (QTHLDPLUGINBUG-20605)
* Fixed that `make` step required C++ tool chain
* Fixed that many very long lines in application or build output could lead to
  out of memory exception (QTHLDPLUGINBUG-18172)

QMake Projects

* Made it possible to add libraries for other target platforms in
  `Add Library` wizard (QTHLDPLUGINBUG-17995)
* Fixed crash while parsing (QTHLDPLUGINBUG-21416)
* Fixed that `make qmake_all` was run in top-level project directory even when
  building sub-project (QTHLDPLUGINBUG-20823)

Qbs Projects

* Added `qmlDesignerImportPaths` property for specifying QML import paths for
  Qt Quick Designer (QTHLDPLUGINBUG-20810)

C++ Support

* Added experimental plugin `CompilationDatabaseProjectManager` that opens a
  [compilation database](https://clang.llvm.org/docs/JSONCompilationDatabase.html)
  for code editing
* Added experimental plugin `ClangFormat` that bases auto-indentation on
  Clang Format
* Added experimental plugin `Cppcheck` for integration of
  [cppcheck](http://cppcheck.sourceforge.net) diagnostics
* Added highlighting style for punctuation tokens (QTHLDPLUGINBUG-20666)
* Fixed issues with detecting language version (QTHLDPLUGINBUG-20884)
* Fixed crash when code model prints message about too large files
  (QTHLDPLUGINBUG-21481)
* Fixed function extraction from nested classes (QTHLDPLUGINBUG-7271)
* Fixed handling of `-B` option (QTHLDPLUGINBUG-21424)
* Clang Code Model
    * Switched to Clang 7.0
    * Added `Follow Symbol` for `auto` keyword (QTHLDPLUGINBUG-17191)
    * Added function overloads to tooltip in completion popup
    * Added `Build` > `Generate Compilation Database`
    * Fixed that braced initialization did not provide constructor completion
      (QTHLDPLUGINBUG-20957)
    * Fixed local references for operator arguments (QTHLDPLUGINBUG-20966)
    * Fixed support for generated UI headers (QTHLDPLUGINBUG-15187,
      QTHLDPLUGINBUG-17002)
    * Fixed crash when removing diagnostics configuration (QTHLDPLUGINBUG-21273)

QML Support

* Fixed indentation in object literals with ternary operator (QTHLDPLUGINBUG-7103)
* Fixed that symbols from closed projects were still shown in Locator
  (QTHLDPLUGINBUG-13459)
* Fixed crash when building Qt Hldplugin with Qt 5.12 (QTHLDPLUGINBUG-21510)
* Fixed that `.mjs` files were not opened in JavaScript editor
  (QTHLDPLUGINBUG-21517)

Debugging

* Added support for multiple simultaneous debugger runs
* Added pretty printing of `QEvent` and `QKeyEvent`
* Fixed automatic detection of debugging information for Qt from binary
  installer (QTHLDPLUGINBUG-20693)
* Fixed display of short unsigned integers (QTHLDPLUGINBUG-21038)
* GDB
    * Fixed startup issue with localized debugger output (QTHLDPLUGINBUG-20765)
    * Fixed disassembler view for newer GCC
* CDB
    * Added option to suppress task entries for exceptions (QTHLDPLUGINBUG-20915)
* LLDB
    * Fixed instruction-wise stepping
    * Fixed startup with complex command line arguments (QTHLDPLUGINBUG-21433)
    * Fixed pretty printing of bitfields

Qt Quick Designer

* Added support for enums in `.metainfo` files
* Fixed wrong property propagation from parent to child
* Fixed invalid access to network paths (QTHLDPLUGINBUG-21372)

Version Control Systems

* Git
    * Added navigation pane that shows branches
    * Added option for copy/move detection to `git blame` (QTHLDPLUGINBUG-20462)
    * Added support for GitHub and GitLab remotes
    * Improved behavior if no merge tool is configured
    * Fixed that `git pull` blocked Qt Hldplugin (QTHLDPLUGINBUG-13279)
    * Fixed handling of `file://` remotes (QTHLDPLUGINBUG-20618)
    * Fixed search for `gitk` executable (QTHLDPLUGINBUG-1577)

Test Integration

* Google Test
    * Fixed that not all failure locations were shown (QTHLDPLUGINBUG-20967)
    * Fixed that `GTEST_*` environment variables could break test execution
      and output parsing (QTHLDPLUGINBUG-21012)

Model Editor

* Fixed that selections and text cursors where exported (QTHLDPLUGINBUG-16689)

Platform Specific

Linux

* Added detection of Intel C compiler (QTHLDPLUGINBUG-18302)
* Fixed `Open Terminal Here` for `konsole` (QTHLDPLUGINBUG-20900)

macOS

* Fixed light themes for macOS Mojave (10.14)

Android

* Added support for command line arguments
* Added support for environment variables
* Added support for API level 28
* Added auto-detection of Clang toolchains (QTHLDPLUGINBUG-11846)
* Removed auto-detection of GCC toolchains
* Fixed connecting to debugger for API level 24 and later

Remote Linux

* Updated to Botan 2.8
* Fixed SSH connections in AES-CBC mode (QTHLDPLUGINBUG-21387)

Credits for these changes go to:  
Alessandro Portale  
Alexandru Croitor  
Alexis Jeandet  
Allan Sandfeld Jensen  
Andre Hartmann  
André Pönitz  
Benjamin Balga  
BogDan Vatra  
Christian Kandeler  
Christian Stenger  
Daniel Levin  
Daniel Trevitz  
David Schulz  
Eike Ziller  
Frank Meerkoetter  
Hannes Domani  
Ivan Donchevskii  
Jaroslaw Kobus  
Jochen Becher  
Jörg Bornemann  
Knud Dollereder  
Laurent Montel  
Leena Miettinen  
Marco Benelli  
Marco Bubke  
Michael Weghorn  
Morten Johan Sørvig  
Nicolas Ettlin  
Nikolai Kosjar  
Oliver Wolff  
Orgad Shaneh  
Razi Alavizadeh  
Robert Löhning  
Sergey Belyashov  
Sergey Morozov  
Tasuku Suzuki  
Thiago Macieira  
Thomas Hartmann  
Tim Jenssen  
Tobias Hunger  
Uladzimir Bely  
Ulf Hermann  
Venugopal Shivashankar  
Vikas Pachdha  
