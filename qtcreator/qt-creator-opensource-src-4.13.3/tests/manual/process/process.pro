#-------------------------------------------------
#
# Project created by QtHldplugin 2010-03-01T11:08:57
#
#-------------------------------------------------

# Utils lib requires gui, too.
QT       += core
QT       += gui

QTC_LIB_DEPENDS += utils
include(../../../qthldplugin.pri)

# -- Add hldplugin 'utils' lib
macx:QMAKE_LFLAGS += -Wl,-rpath,\"$$IDE_BIN_PATH/..\"

TARGET = process
CONFIG   += console
CONFIG   -= app_bundle
TEMPLATE = app
SOURCES += main.cpp \
    mainwindow.cpp

HEADERS += \
    mainwindow.h
