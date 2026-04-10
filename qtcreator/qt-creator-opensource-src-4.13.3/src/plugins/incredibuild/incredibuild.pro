TARGET = IncrediBuild
TEMPLATE = lib

include(../../qthldpluginplugin.pri)

DEFINES += INCREDIBUILD_LIBRARY

# IncrediBuild files

SOURCES += incredibuildplugin.cpp \
    buildconsolebuildstep.cpp \
    buildconsolestepfactory.cpp \
    buildconsolestepconfigwidget.cpp \
    commandbuilder.cpp \
    makecommandbuilder.cpp \
    ibconsolebuildstep.cpp \
    ibconsolestepconfigwidget.cpp \
    ibconsolestepfactory.cpp

HEADERS += incredibuildplugin.h \
    buildconsolestepconfigwidget.h \
    buildconsolestepfactory.h \
    commandbuilder.h \
    ibconsolestepconfigwidget.h \
    incredibuild_global.h \
    incredibuildconstants.h \
    buildconsolebuildstep.h \
    makecommandbuilder.h \
    ibconsolebuildstep.h \
    ibconsolestepfactory.h

FORMS += \
    buildconsolebuildstep.ui \
    ibconsolebuildstep.ui
