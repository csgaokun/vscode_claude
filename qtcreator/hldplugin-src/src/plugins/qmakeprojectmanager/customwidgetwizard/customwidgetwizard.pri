CUSTOMWIDGETWIZARD_SOURCE_ROOT = $$PWD

CUSTOMWIDGETWIZARD_SOURCE_FILES = \
 plugingenerator.cpp \
 classlist.cpp \
 classdefinition.cpp \
 customwidgetwidgetswizardpage.cpp \
 customwidgetpluginwizardpage.cpp \
 customwidgetwizarddialog.cpp \
 customwidgetwizard.cpp
for(fileName, CUSTOMWIDGETWIZARD_SOURCE_FILES) {
	SOURCES += $$CUSTOMWIDGETWIZARD_SOURCE_ROOT/$$fileName
}

CUSTOMWIDGETWIZARD_HEADER_FILES = \
 classlist.h \
 plugingenerator.h \
 pluginoptions.h \
 classdefinition.h \
 customwidgetwizarddialog.h \
 customwidgetwidgetswizardpage.h \
 customwidgetpluginwizardpage.h \
 customwidgetwizard.h \
 filenamingparameters.h
for(fileName, CUSTOMWIDGETWIZARD_HEADER_FILES) {
	HEADERS += $$CUSTOMWIDGETWIZARD_SOURCE_ROOT/$$fileName
}

CUSTOMWIDGETWIZARD_FORMS = \
 $$CUSTOMWIDGETWIZARD_SOURCE_ROOT/classdefinition.ui \
 $$CUSTOMWIDGETWIZARD_SOURCE_ROOT/customwidgetwidgetswizardpage.ui \
 $$CUSTOMWIDGETWIZARD_SOURCE_ROOT/customwidgetpluginwizardpage.ui

customwidgetwizard_uic.input = CUSTOMWIDGETWIZARD_FORMS
customwidgetwizard_uic.output = $$OUT_PWD/ui_${QMAKE_FILE_BASE}.h
isEmpty(vcproj):customwidgetwizard_uic.variable_out = PRE_TARGETDEPS
win32:customwidgetwizard_uic.commands = $$shell_path($$[QT_INSTALL_BINS]/uic.exe) "${QMAKE_FILE_IN}" -o "${QMAKE_FILE_OUT}"
unix:customwidgetwizard_uic.commands = $$shell_path($$[QT_INSTALL_BINS]/uic) ${QMAKE_FILE_IN} -o ${QMAKE_FILE_OUT}
customwidgetwizard_uic.name = UIC ${QMAKE_FILE_IN}
customwidgetwizard_uic.CONFIG += no_link
QMAKE_EXTRA_COMPILERS += customwidgetwizard_uic

HEADERS += \
 $$OUT_PWD/ui_classdefinition.h \
 $$OUT_PWD/ui_customwidgetwidgetswizardpage.h \
 $$OUT_PWD/ui_customwidgetpluginwizardpage.h

QMAKE_DISTCLEAN += \
 $$OUT_PWD/ui_classdefinition.h \
 $$OUT_PWD/ui_customwidgetwidgetswizardpage.h \
 $$OUT_PWD/ui_customwidgetpluginwizardpage.h

