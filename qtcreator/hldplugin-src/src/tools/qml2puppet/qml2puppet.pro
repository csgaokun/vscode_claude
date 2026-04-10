TEMPLATE = subdirs
CONFIG += ordered

include(../../../qthldplugin.pri)

greaterThan(QT_MAJOR_VERSION, 4) {
    SUBDIRS += qml2puppet
}

