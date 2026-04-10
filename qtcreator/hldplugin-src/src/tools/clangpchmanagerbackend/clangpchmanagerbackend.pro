QTC_LIB_DEPENDS += \
    clangsupport

include(../../qthldplugintool.pri)
include(../../shared/clang/clang_installation.pri)
include(source/clangpchmanagerbackend-source.pri)

requires(!isEmpty(LIBTOOLING_LIBS))

QT += core network
QT -= gui

LIBS += $$LIBTOOLING_LIBS
INCLUDEPATH += $$LLVM_INCLUDEPATH

QMAKE_CXXFLAGS_WARN_ON *= $$LLVM_CXXFLAGS_WARNINGS
QMAKE_CXXFLAGS *= $$LLVM_CXXFLAGS

INCLUDEPATH += ../clangrefactoringbackend/source

SOURCES += \
    clangpchmanagerbackendmain.cpp \
    ../clangrefactoringbackend/source/clangtool.cpp \
    ../clangrefactoringbackend/source/refactoringcompilationdatabase.cpp

DEFINES += CLANG_COMPILER_PATH=\"R\\\"xxx($${LLVM_BINDIR}/clang)xxx\\\"\"
