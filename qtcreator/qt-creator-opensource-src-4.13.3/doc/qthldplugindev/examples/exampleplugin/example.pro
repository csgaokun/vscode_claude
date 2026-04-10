#! [1]
DEFINES += EXAMPLE_LIBRARY
#! [1]

# Example files

#! [2]
SOURCES += exampleplugin.cpp

HEADERS += exampleplugin.h \
        example_global.h \
        exampleconstants.h
#! [2]

# Qt Hldplugin linking

#! [3]
## set the QTC_SOURCE environment variable to override the setting here
QTHLDPLUGIN_SOURCES = $$(QTC_SOURCE)
isEmpty(QTHLDPLUGIN_SOURCES):QTHLDPLUGIN_SOURCES=/Users/example/qthldplugin-src

## set the QTC_BUILD environment variable to override the setting here
IDE_BUILD_TREE = $$(QTC_BUILD)
isEmpty(IDE_BUILD_TREE):IDE_BUILD_TREE=/Users/example/qthldplugin-build
#! [3]

#! [4]
## uncomment to build plugin into user config directory
## <localappdata>/plugins/<ideversion>
##    where <localappdata> is e.g.
##    "%LOCALAPPDATA%\QtProject\qthldplugin" on Windows Vista and later
##    "$XDG_DATA_HOME/data/QtProject/qthldplugin" or "~/.local/share/data/QtProject/qthldplugin" on Linux
##    "~/Library/Application Support/QtProject/Qt Hldplugin" on Mac
# USE_USER_DESTDIR = yes
#! [4]

#! [5]
###### If the plugin can be depended upon by other plugins, this code needs to be outsourced to
###### <dirname>_dependencies.pri, where <dirname> is the name of the directory containing the
###### plugin's sources.

QTC_PLUGIN_NAME = Example
QTC_LIB_DEPENDS += \
    # nothing here at this time

QTC_PLUGIN_DEPENDS += \
    coreplugin

QTC_PLUGIN_RECOMMENDS += \
    # optional plugin dependencies. nothing here at this time

###### End _dependencies.pri contents ######
#! [5]

#![6]
include($$QTHLDPLUGIN_SOURCES/src/qthldpluginplugin.pri)

#![6]

