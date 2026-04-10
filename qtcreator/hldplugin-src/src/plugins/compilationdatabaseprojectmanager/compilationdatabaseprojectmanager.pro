include(../../qthldpluginplugin.pri)

COMPILATIONDATABASEPROJECTMANAGER_SOURCE_ROOT = $$PWD

INCLUDEPATH += $$COMPILATIONDATABASEPROJECTMANAGER_SOURCE_ROOT

COMPILATIONDATABASEPROJECTMANAGER_SOURCE_FILES = \
    compilationdatabaseproject.cpp \
    compilationdatabaseprojectmanagerplugin.cpp \
    compilationdatabaseutils.cpp \
    compilationdbparser.cpp
for(fileName, COMPILATIONDATABASEPROJECTMANAGER_SOURCE_FILES) {
    SOURCES += $$COMPILATIONDATABASEPROJECTMANAGER_SOURCE_ROOT/$$fileName
}

COMPILATIONDATABASEPROJECTMANAGER_HEADER_FILES = \
    compilationdatabaseproject.h \
    compilationdatabaseprojectmanagerplugin.h \
    compilationdatabaseconstants.h \
    compilationdatabaseutils.h \
    compilationdbparser.h
for(fileName, COMPILATIONDATABASEPROJECTMANAGER_HEADER_FILES) {
    HEADERS += $$COMPILATIONDATABASEPROJECTMANAGER_SOURCE_ROOT/$$fileName
}

equals(TEST, 1) {
    HEADERS += \
        $$COMPILATIONDATABASEPROJECTMANAGER_SOURCE_ROOT/compilationdatabasetests.h

    SOURCES += \
        $$COMPILATIONDATABASEPROJECTMANAGER_SOURCE_ROOT/compilationdatabasetests.cpp

    RESOURCES += $$COMPILATIONDATABASEPROJECTMANAGER_SOURCE_ROOT/compilationdatabasetests.qrc
}
