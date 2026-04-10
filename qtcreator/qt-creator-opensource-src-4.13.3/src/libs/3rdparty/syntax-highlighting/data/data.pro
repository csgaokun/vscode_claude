TEMPLATE = aux

include(../../../../../qthldplugin.pri)

STATIC_BASE = $$PWD
STATIC_OUTPUT_BASE = $$IDE_DATA_PATH/generic-highlighter
STATIC_INSTALL_BASE = $$INSTALL_DATA_PATH/generic-highlighter

STATIC_FILES += $$files($$PWD/syntax/*, true)

include(../../../../../qthldplugindata.pri)
