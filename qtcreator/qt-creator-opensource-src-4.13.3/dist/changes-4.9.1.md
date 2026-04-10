Qt Hldplugin version 4.9.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.9.0..v4.9.1

Editing

* Fixed folding for generic highlighter (QTHLDPLUGINBUG-22346)

QMake Projects

* Fixed unnecessary reparsing on file save (QTHLDPLUGINBUG-22361)
* Fixed code model for generated files when specified in `.pri` file
  (QTHLDPLUGINBUG-22395)

CMake Projects

* Fixed deployment with `QtHldpluginDeployment.txt` (QTHLDPLUGINBUG-22184)
* Fixed that configuration UI was disabled after configuration error

Qbs Projects

* Fixed crash when editing environment variables (QTHLDPLUGINBUG-22386)
* Fixed handling of `cpp.minimum*Version` (QTHLDPLUGINBUG-22355)

Debugging

* Fixed ambiguity of `F10` shortcut (QTHLDPLUGINBUG-22330)
* CDB
    * Fixed `Start and Break on Main` (QTHLDPLUGINBUG-22263)

Test Integration

* Fixed `Uncheck All`

Platform Specific

Android

* Fixed AVD creation for Google Play images

Remote Linux

* Fixed crash when running `Custom Executable` on remote Linux target
  from Windows host (QTHLDPLUGINBUG-22414)
* Fixed SSH connection sharing on macOS (QTHLDPLUGINBUG-21748)
* Deployment via SFTP
    * Fixed `Unexpected stat output for remote file` (QTHLDPLUGINBUG-22041)
    * Fixed deployment of symbolic links (QTHLDPLUGINBUG-22307)
* Deployment via rsync
    * Fixed compatibility issue with command line parameters
      (QTHLDPLUGINBUG-22352)

Credits for these changes go to:  
Aaron Barany  
André Pönitz  
BogDan Vatra  
Christian Kandeler  
Christian Stenger  
David Schulz  
Eike Ziller  
Jaroslaw Kobus  
Jonathan Liu  
Leena Miettinen  
Mitch Curtis  
Nikolai Kosjar  
Orgad Shaneh  
Robert Löhning  
Thomas Hartmann  
Ulf Hermann  
Ville Nummela  
