# Qt Hldplugin 4.10.1

Qt Hldplugin version 4.10.1 contains bug fixes.

The most important changes are listed in this document. For a complete
list of changes, see the Git log for the Qt Hldplugin sources that
you can check out from the public Git repository. For example:

    git clone git://code.qt.io/qt-hldplugin/qt-hldplugin.git
    git log --cherry-pick --pretty=oneline origin/v4.10.0..v4.10.1

## Editing

* Fixed file saving with some text encodings
* Fixed `Preserve case` in advanced search and replace (QTHLDPLUGINBUG-19696)
* Fixed crash when changing editor font (QTHLDPLUGINBUG-22933)

## Help

* Fixed that text moved around when resizing and zooming (QTHLDPLUGINBUG-4756)

## All Projects

* Fixed `Qt Hldplugin Plugin` wizard (QTHLDPLUGINBUG-22945)

## Debugging

* Fixed more layout restoration issues (QTHLDPLUGINBUG-22286, QTHLDPLUGINBUG-22415, QTHLDPLUGINBUG-22938)

### LLDB

* Fixed wrong empty command line argument when debugging (QTHLDPLUGINBUG-22975)

## Qt Quick Designer

* Removed transformations from list of unsupported types
* Fixed update of animation curve editor

## Platform Specific

### macOS

* Fixed debugging with Xcode 11 (QTHLDPLUGINBUG-22955)
* Fixed window stacking order after closing file dialog (QTHLDPLUGINBUG-22906)
* Fixed window size after exiting fullscreen

### QNX

* Fixed that QNX compiler could not be selected for C

## Credits for these changes go to:

Aleksei German  
Alexander Akulich  
Andre Hartmann  
André Pönitz  
Christian Kandeler  
Christian Stenger  
Cristian Adam  
David Schulz  
Eike Ziller  
Knud Dollereder  
Leena Miettinen  
Lisandro Damián Nicanor Pérez Meyer  
Nikolai Kosjar  
Orgad Shaneh  
Richard Weickelt  
Sergey Belyashov  
Thomas Hartmann  
