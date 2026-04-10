TARGET = qml2puppet

TEMPLATE = app

include(../../../../qthldplugin.pri)

osx:  DESTDIR = $$IDE_LIBEXEC_PATH/qmldesigner
else: DESTDIR = $$IDE_LIBEXEC_PATH

RPATH_BASE = $$DESTDIR
include(../../../rpath.pri)

include(../../../../share/qthldplugin/qml/qmlpuppet/qml2puppet/qml2puppet.pri)

isEmpty(PRECOMPILED_HEADER):PRECOMPILED_HEADER = $$PWD/../../../shared/qthldplugin_pch.h


