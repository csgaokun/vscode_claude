include(../../shared/registryaccess/registryaccess.pri)
include(../../qthldplugintool.pri)
CONFIG -= console
QT += widgets
TARGET = qtcdebugger
SOURCES += main.cpp

app_info.input = $$PWD/../../app/app_version.h.in
app_info.output = $$OUT_PWD/app_version.h
QMAKE_SUBSTITUTES += app_info
