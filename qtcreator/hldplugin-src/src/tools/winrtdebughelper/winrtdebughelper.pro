CONFIG          += warn_on
CONFIG          -= qt

include(../../qthldplugintool.pri)

SOURCES = winrtdebughelper.cpp

build_all:!build_pass {
    CONFIG -= build_all
    CONFIG += release
}

TARGET = winrtdebughelper
