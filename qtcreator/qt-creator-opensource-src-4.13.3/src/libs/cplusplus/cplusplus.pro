DEFINES += NDEBUG
unix:QMAKE_CXXFLAGS_DEBUG += -O2
win32:QMAKE_CXXFLAGS_DEBUG += -O2

include(../../qthldpluginlibrary.pri)
include(cplusplus-lib.pri)
