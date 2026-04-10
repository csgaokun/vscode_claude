include(../../qthldpluginplugin.pri)
include(clangrefactoring-source.pri)
include(../../shared/clang/clang_installation.pri)

include(../../shared/clang/clang_defines.pri)

requires(!isEmpty(LIBTOOLING_LIBS))

HEADERS += \
    clangrefactoringplugin.h \
    baseclangquerytexteditorwidget.h \
    clangqueryexampletexteditorwidget.h \
    clangqueryhoverhandler.h \
    clangqueryprojectsfindfilterwidget.h \
    clangquerytexteditorwidget.h \
    qthldpluginclangqueryfindfilter.h \
    qthldpluginsearch.h \
    qthldpluginsearchhandle.h \
    qthldpluginsymbolsfindfilter.h \
    querysqlitestatementfactory.h \
    sourcelocations.h \
    symbolsfindfilterconfigwidget.h \
    symbolquery.h \
    qthldplugineditormanager.h \
    qthldpluginrefactoringprojectupdater.h

SOURCES += \
    clangrefactoringplugin.cpp \
    baseclangquerytexteditorwidget.cpp \
    clangqueryexampletexteditorwidget.cpp \
    clangqueryhoverhandler.cpp \
    clangqueryprojectsfindfilterwidget.cpp \
    clangquerytexteditorwidget.cpp \
    qthldpluginclangqueryfindfilter.cpp \
    qthldpluginsearch.cpp \
    qthldpluginsearchhandle.cpp \
    qthldpluginsymbolsfindfilter.cpp \
    symbolsfindfilterconfigwidget.cpp \
    qthldplugineditormanager.cpp \
    qthldpluginrefactoringprojectupdater.cpp

FORMS += \
    clangqueryprojectsfindfilter.ui
