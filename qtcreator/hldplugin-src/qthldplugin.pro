include(qthldplugin.pri)

#version check qt
!minQtVersion(5, 6, 0) {
    message("Cannot build $$IDE_DISPLAY_NAME with Qt version $${QT_VERSION}.")
    error("Use at least Qt 5.6.0.")
}

include(doc/doc.pri)

TEMPLATE  = subdirs
CONFIG   += ordered

SUBDIRS = src share
unix:!macx:!isEmpty(copydata):SUBDIRS += bin
!isEmpty(BUILD_TESTS):SUBDIRS += tests
