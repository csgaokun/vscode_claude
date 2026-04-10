TEMPLATE = app
TARGET = qthldplugin.sh

include(../qthldplugin.pri)

OBJECTS_DIR =

PRE_TARGETDEPS = $$PWD/qthldplugin.sh

QMAKE_LINK = cp $$PWD/qthldplugin.sh $@ && : IGNORE REST OF LINE:
QMAKE_STRIP =
CONFIG -= qt separate_debug_info gdb_dwarf_index

QMAKE_CLEAN = qthldplugin.sh

target.path  = $$INSTALL_BIN_PATH
INSTALLS    += target

DISTFILES = $$PWD/qthldplugin.sh
