include(../../qthldpluginplugin.pri)

MESONPROJECTMANAGER_SOURCE_ROOT = $$PWD

INCLUDEPATH += $$MESONPROJECTMANAGER_SOURCE_ROOT

MESONPROJECTMANAGER_HEADER_FILES = \
      exewrappers/mesontools.h \
      exewrappers/mesonwrapper.h \
      exewrappers/ninjawrapper.h \
      exewrappers/toolwrapper.h \
      kithelper/kitdata.h \
      kithelper/kithelper.h \
      machinefiles/machinefilemanager.h \
      machinefiles/nativefilegenerator.h \
      mesonactionsmanager/mesonactionsmanager.h \
      mesoninfoparser/buildoptions.h \
      mesoninfoparser/mesoninfo.h \
      mesoninfoparser/mesoninfoparser.h \
      mesoninfoparser/parsers/buildoptionsparser.h \
      mesoninfoparser/parsers/buildsystemfilesparser.h \
      mesoninfoparser/parsers/common.h \
      mesoninfoparser/parsers/infoparser.h \
      mesoninfoparser/parsers/targetparser.h \
      mesoninfoparser/target.h \
      project/buildoptions/optionsmodel/arrayoptionlineedit.h \
      project/buildoptions/optionsmodel/buildoptionsmodel.h \
      project/buildoptions/mesonbuildsettingswidget.h \
      project/buildoptions/mesonbuildstepconfigwidget.h \
      project/outputparsers/mesonoutputparser.h \
      project/outputparsers/ninjaparser.h \
      project/projecttree/mesonprojectnodes.h \
      project/projecttree/projecttree.h \
      project/mesonbuildconfiguration.h \
      project/mesonbuildsystem.h \
      project/mesonprocess.h \
      project/mesonproject.h \
      project/mesonprojectimporter.h \
      project/mesonprojectparser.h \
      project/mesonrunconfiguration.h \
      project/ninjabuildstep.h \
      settings/general/generalsettingspage.h \
      settings/general/generalsettingswidget.h \
      settings/general/settings.h \
      settings/tools/kitaspect/mesontoolkitaspect.h \
      settings/tools/kitaspect/ninjatoolkitaspect.h \
      settings/tools/kitaspect/toolkitaspectwidget.h \
      settings/tools/toolitemsettings.h \
      settings/tools/toolsmodel.h \
      settings/tools/toolssettingsaccessor.h \
      settings/tools/toolssettingspage.h \
      settings/tools/toolssettingswidget.h \
      settings/tools/tooltreeitem.h \
      mesonpluginconstants.h \
      mesonprojectplugin.h \
      versionhelper.h
for(fileName, MESONPROJECTMANAGER_HEADER_FILES) {
    HEADERS += $$MESONPROJECTMANAGER_SOURCE_ROOT/$$fileName
}

MESONPROJECTMANAGER_SOURCE_FILES = \
    exewrappers/mesonwrapper.cpp  \
    exewrappers/toolwrapper.cpp  \
    exewrappers/mesontools.cpp \
    machinefiles/machinefilemanager.cpp  \
    machinefiles/nativefilegenerator.cpp  \
    mesonactionsmanager/mesonactionsmanager.cpp  \
    project/buildoptions/optionsmodel/arrayoptionlineedit.cpp  \
    project/buildoptions/optionsmodel/buildoptionsmodel.cpp  \
    project/buildoptions/mesonbuildsettingswidget.cpp  \
    project/buildoptions/mesonbuildstepconfigwidget.cpp  \
    project/outputparsers/mesonoutputparser.cpp  \
    project/outputparsers/ninjaparser.cpp  \
    project/projecttree/mesonprojectnodes.cpp  \
    project/projecttree/projecttree.cpp  \
    project/mesonbuildconfiguration.cpp  \
    project/mesonbuildsystem.cpp  \
    project/mesonprocess.cpp  \
    project/mesonproject.cpp  \
    project/mesonprojectimporter.cpp  \
    project/mesonprojectparser.cpp  \
    project/mesonrunconfiguration.cpp  \
    project/ninjabuildstep.cpp  \
    settings/general/generalsettingspage.cpp  \
    settings/general/generalsettingswidget.cpp  \
    settings/general/settings.cpp  \
    settings/tools/kitaspect/mesontoolkitaspect.cpp  \
    settings/tools/kitaspect/ninjatoolkitaspect.cpp  \
    settings/tools/kitaspect/toolkitaspectwidget.cpp  \
    settings/tools/toolitemsettings.cpp  \
    settings/tools/toolsmodel.cpp  \
    settings/tools/toolssettingsaccessor.cpp  \
    settings/tools/toolssettingspage.cpp  \
    settings/tools/toolssettingswidget.cpp  \
    settings/tools/tooltreeitem.cpp  \
    mesonprojectplugin.cpp
for(fileName, MESONPROJECTMANAGER_SOURCE_FILES) {
    SOURCES += $$MESONPROJECTMANAGER_SOURCE_ROOT/$$fileName
}

RESOURCES += resources.qrc

MESONPROJECTMANAGER_FORMS = \
    $$MESONPROJECTMANAGER_SOURCE_ROOT/project/buildoptions/mesonbuildsettingswidget.ui \
    $$MESONPROJECTMANAGER_SOURCE_ROOT/project/buildoptions/mesonbuildstepconfigwidget.ui \
    $$MESONPROJECTMANAGER_SOURCE_ROOT/settings/general/generalsettingswidget.ui \
    $$MESONPROJECTMANAGER_SOURCE_ROOT/settings/tools/toolitemsettings.ui \
    $$MESONPROJECTMANAGER_SOURCE_ROOT/settings/tools/toolssettingswidget.ui

mesonprojectmanager_uic.input = MESONPROJECTMANAGER_FORMS
mesonprojectmanager_uic.output = $$OUT_PWD/ui_${QMAKE_FILE_BASE}.h
isEmpty(vcproj):mesonprojectmanager_uic.variable_out = PRE_TARGETDEPS
win32:mesonprojectmanager_uic.commands = $$shell_path($$[QT_INSTALL_BINS]/uic.exe) "${QMAKE_FILE_IN}" -o "${QMAKE_FILE_OUT}"
unix:mesonprojectmanager_uic.commands = $$shell_path($$[QT_INSTALL_BINS]/uic) ${QMAKE_FILE_IN} -o ${QMAKE_FILE_OUT}
mesonprojectmanager_uic.name = UIC ${QMAKE_FILE_IN}
mesonprojectmanager_uic.CONFIG += no_link
QMAKE_EXTRA_COMPILERS += mesonprojectmanager_uic

HEADERS += \
    $$OUT_PWD/ui_mesonbuildsettingswidget.h \
    $$OUT_PWD/ui_mesonbuildstepconfigwidget.h \
    $$OUT_PWD/ui_generalsettingswidget.h \
    $$OUT_PWD/ui_toolitemsettings.h \
    $$OUT_PWD/ui_toolssettingswidget.h

QMAKE_DISTCLEAN += \
    $$OUT_PWD/ui_mesonbuildsettingswidget.h \
    $$OUT_PWD/ui_mesonbuildstepconfigwidget.h \
    $$OUT_PWD/ui_generalsettingswidget.h \
    $$OUT_PWD/ui_toolitemsettings.h \
    $$OUT_PWD/ui_toolssettingswidget.h

