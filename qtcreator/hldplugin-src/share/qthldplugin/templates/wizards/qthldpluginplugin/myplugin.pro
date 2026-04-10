DEFINES += %{LibraryDefine}

# %{PluginName} files

SOURCES += \\
        %{SrcFileName}

HEADERS += \\
        %{HdrFileName} \\
        %{GlobalHdrFileName} \\
        %{ConstantsHdrFileName}


# Qt Hldplugin linking

## Either set the IDE_SOURCE_TREE when running qmake,
## or set the QTC_SOURCE environment variable, to override the default setting
isEmpty(IDE_SOURCE_TREE): IDE_SOURCE_TREE = $$(QTC_SOURCE)
isEmpty(IDE_SOURCE_TREE): IDE_SOURCE_TREE = "%{QtHldpluginSources}"

## Either set the IDE_BUILD_TREE when running qmake,
## or set the QTC_BUILD environment variable, to override the default setting
isEmpty(IDE_BUILD_TREE): IDE_BUILD_TREE = $$(QTC_BUILD)
isEmpty(IDE_BUILD_TREE): IDE_BUILD_TREE = "%{QtHldpluginBuild}"

## uncomment to build plugin into user config directory
## <localappdata>/plugins/<ideversion>
##    where <localappdata> is e.g.
##    "%LOCALAPPDATA%\QtProject\qthldplugin" on Windows Vista and later
##    "$XDG_DATA_HOME/data/QtProject/qthldplugin" or "~/.local/share/data/QtProject/qthldplugin" on Linux
##    "~/Library/Application Support/QtProject/Qt Hldplugin" on OS X
%{DestDir}USE_USER_DESTDIR = yes

###### If the plugin can be depended upon by other plugins, this code needs to be outsourced to
###### <dirname>_dependencies.pri, where <dirname> is the name of the directory containing the
###### plugin's sources.

QTC_PLUGIN_NAME = %{PluginName}
QTC_LIB_DEPENDS += \\
    # nothing here at this time

QTC_PLUGIN_DEPENDS += \\
    coreplugin

QTC_PLUGIN_RECOMMENDS += \\
    # optional plugin dependencies. nothing here at this time

###### End _dependencies.pri contents ######

include($$IDE_SOURCE_TREE/src/qthldpluginplugin.pri)
