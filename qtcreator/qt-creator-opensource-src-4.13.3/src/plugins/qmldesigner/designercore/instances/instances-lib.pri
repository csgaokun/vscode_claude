INCLUDEPATH += $$PWD/

HEADERS += $$PWD/../include/nodeinstance.h \
    $$PWD/baseconnectionmanager.h \
    $$PWD/connectionmanager.h \
    $$PWD/connectionmanagerinterface.h \
    $$PWD/nodeinstanceserverproxy.h \
    $$PWD/puppethldplugin.h \
    $$PWD/puppetbuildprogressdialog.h \
    $$PWD/qprocessuniqueptr.h

SOURCES +=  $$PWD/nodeinstanceserverproxy.cpp \
    $$PWD/baseconnectionmanager.cpp \
    $$PWD/connectionmanager.cpp \
    $$PWD/connectionmanagerinterface.cpp \
    $$PWD/nodeinstance.cpp \
    $$PWD/nodeinstanceview.cpp \
    $$PWD/puppethldplugin.cpp \
    $$PWD/puppetbuildprogressdialog.cpp

FORMS += $$PWD/puppetbuildprogressdialog.ui

