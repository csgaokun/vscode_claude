QTC_LIB_DEPENDS += qmljs
include(../../../qttest.pri)

DEFINES+=QTHLDPLUGINDIR=\\\"$$IDE_SOURCE_TREE\\\"
DEFINES+=TESTSRCDIR=\\\"$$PWD\\\"

TARGET = tst_codemodel_check

SOURCES += \
    tst_check.cpp
