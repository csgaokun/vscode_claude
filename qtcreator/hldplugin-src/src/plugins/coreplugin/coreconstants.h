/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of Qt Hldplugin.
**
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 as published by the Free Software
** Foundation with exceptions as appearing in the file LICENSE.GPL3-EXCEPT
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
****************************************************************************/

#pragma once

#include <QtGlobal>

namespace Core {
namespace Constants {

// Modes
const char MODE_WELCOME[]          = "Welcome";
const char MODE_EDIT[]             = "Edit";
const char MODE_DESIGN[]           = "Design";
const int  P_MODE_WELCOME          = 100;
const int  P_MODE_EDIT             = 90;
const int  P_MODE_DESIGN           = 89;

// TouchBar
const char TOUCH_BAR[]             = "QtHldplugin.TouchBar";

// Menubar
const char MENU_BAR[]              = "QtHldplugin.MenuBar";

// Menus
const char M_FILE[]                = "QtHldplugin.Menu.File";
const char M_FILE_RECENTFILES[]    = "QtHldplugin.Menu.File.RecentFiles";
const char M_EDIT[]                = "QtHldplugin.Menu.Edit";
const char M_EDIT_ADVANCED[]       = "QtHldplugin.Menu.Edit.Advanced";
const char M_VIEW[]                = "QtHldplugin.Menu.View";
const char M_VIEW_MODESTYLES[]     = "QtHldplugin.Menu.View.ModeStyles";
const char M_VIEW_VIEWS[]          = "QtHldplugin.Menu.View.Views";
const char M_VIEW_PANES[]          = "QtHldplugin.Menu.View.Panes";
const char M_TOOLS[]               = "QtHldplugin.Menu.Tools";
const char M_TOOLS_EXTERNAL[]      = "QtHldplugin.Menu.Tools.External";
const char M_WINDOW[]              = "QtHldplugin.Menu.Window";
const char M_HELP[]                = "QtHldplugin.Menu.Help";

// Contexts
const char C_GLOBAL[]              = "Global Context";
const char C_WELCOME_MODE[]        = "Core.WelcomeMode";
const char C_EDIT_MODE[]           = "Core.EditMode";
const char C_DESIGN_MODE[]         = "Core.DesignMode";
const char C_EDITORMANAGER[]       = "Core.EditorManager";
const char C_NAVIGATION_PANE[]     = "Core.NavigationPane";
const char C_PROBLEM_PANE[]        = "Core.ProblemPane";
const char C_GENERAL_OUTPUT_PANE[] = "Core.GeneralOutputPane";

// Default editor kind
const char K_DEFAULT_TEXT_EDITOR_DISPLAY_NAME[] = QT_TRANSLATE_NOOP("OpenWith::Editors", "Plain Text Editor");
const char K_DEFAULT_TEXT_EDITOR_ID[] = "Core.PlainTextEditor";
const char K_DEFAULT_BINARY_EDITOR_ID[] = "Core.BinaryEditor";

//actions
const char UNDO[]                  = "QtHldplugin.Undo";
const char REDO[]                  = "QtHldplugin.Redo";
const char COPY[]                  = "QtHldplugin.Copy";
const char PASTE[]                 = "QtHldplugin.Paste";
const char CUT[]                   = "QtHldplugin.Cut";
const char SELECTALL[]             = "QtHldplugin.SelectAll";

const char GOTO[]                  = "QtHldplugin.Goto";
const char ZOOM_IN[]               = "QtHldplugin.ZoomIn";
const char ZOOM_OUT[]              = "QtHldplugin.ZoomOut";
const char ZOOM_RESET[]            = "QtHldplugin.ZoomReset";

const char NEW[]                   = "QtHldplugin.New";
const char OPEN[]                  = "QtHldplugin.Open";
const char OPEN_WITH[]             = "QtHldplugin.OpenWith";
const char REVERTTOSAVED[]         = "QtHldplugin.RevertToSaved";
const char SAVE[]                  = "QtHldplugin.Save";
const char SAVEAS[]                = "QtHldplugin.SaveAs";
const char SAVEALL[]               = "QtHldplugin.SaveAll";
const char PRINT[]                 = "QtHldplugin.Print";
const char EXIT[]                  = "QtHldplugin.Exit";

const char OPTIONS[]               = "QtHldplugin.Options";
const char TOGGLE_LEFT_SIDEBAR[]   = "QtHldplugin.ToggleLeftSidebar";
const char TOGGLE_RIGHT_SIDEBAR[]  = "QtHldplugin.ToggleRightSidebar";
const char CYCLE_MODE_SELECTOR_STYLE[] =
                                     "QtHldplugin.CycleModeSelectorStyle";
const char TOGGLE_FULLSCREEN[]     = "QtHldplugin.ToggleFullScreen";
const char THEMEOPTIONS[]          = "QtHldplugin.ThemeOptions";

const char TR_SHOW_LEFT_SIDEBAR[]  = QT_TRANSLATE_NOOP("Core", "Show Left Sidebar");
const char TR_HIDE_LEFT_SIDEBAR[]  = QT_TRANSLATE_NOOP("Core", "Hide Left Sidebar");

const char TR_SHOW_RIGHT_SIDEBAR[] = QT_TRANSLATE_NOOP("Core", "Show Right Sidebar");
const char TR_HIDE_RIGHT_SIDEBAR[] = QT_TRANSLATE_NOOP("Core", "Hide Right Sidebar");

const char MINIMIZE_WINDOW[]       = "QtHldplugin.MinimizeWindow";
const char ZOOM_WINDOW[]           = "QtHldplugin.ZoomWindow";
const char CLOSE_WINDOW[]           = "QtHldplugin.CloseWindow";

const char SPLIT[]                 = "QtHldplugin.Split";
const char SPLIT_SIDE_BY_SIDE[]    = "QtHldplugin.SplitSideBySide";
const char SPLIT_NEW_WINDOW[]      = "QtHldplugin.SplitNewWindow";
const char REMOVE_CURRENT_SPLIT[]  = "QtHldplugin.RemoveCurrentSplit";
const char REMOVE_ALL_SPLITS[]     = "QtHldplugin.RemoveAllSplits";
const char GOTO_PREV_SPLIT[]       = "QtHldplugin.GoToPreviousSplit";
const char GOTO_NEXT_SPLIT[]       = "QtHldplugin.GoToNextSplit";
const char CLOSE[]                 = "QtHldplugin.Close";
const char CLOSE_ALTERNATIVE[]     = "QtHldplugin.Close_Alternative"; // temporary, see QTHLDPLUGINBUG-72
const char CLOSEALL[]              = "QtHldplugin.CloseAll";
const char CLOSEOTHERS[]           = "QtHldplugin.CloseOthers";
const char CLOSEALLEXCEPTVISIBLE[] = "QtHldplugin.CloseAllExceptVisible";
const char GOTONEXTINHISTORY[]     = "QtHldplugin.GotoNextInHistory";
const char GOTOPREVINHISTORY[]     = "QtHldplugin.GotoPreviousInHistory";
const char GO_BACK[]               = "QtHldplugin.GoBack";
const char GO_FORWARD[]            = "QtHldplugin.GoForward";
const char GOTOLASTEDIT[]          = "QtHldplugin.GotoLastEdit";
const char ABOUT_QTHLDPLUGIN[]       = "QtHldplugin.AboutQtHldplugin";
const char ABOUT_PLUGINS[]         = "QtHldplugin.AboutPlugins";
const char S_RETURNTOEDITOR[]      = "QtHldplugin.ReturnToEditor";

// Default groups
const char G_DEFAULT_ONE[]         = "QtHldplugin.Group.Default.One";
const char G_DEFAULT_TWO[]         = "QtHldplugin.Group.Default.Two";
const char G_DEFAULT_THREE[]       = "QtHldplugin.Group.Default.Three";

// Main menu bar groups
const char G_FILE[]                = "QtHldplugin.Group.File";
const char G_EDIT[]                = "QtHldplugin.Group.Edit";
const char G_VIEW[]                = "QtHldplugin.Group.View";
const char G_TOOLS[]               = "QtHldplugin.Group.Tools";
const char G_WINDOW[]              = "QtHldplugin.Group.Window";
const char G_HELP[]                = "QtHldplugin.Group.Help";

// File menu groups
const char G_FILE_NEW[]            = "QtHldplugin.Group.File.New";
const char G_FILE_OPEN[]           = "QtHldplugin.Group.File.Open";
const char G_FILE_PROJECT[]        = "QtHldplugin.Group.File.Project";
const char G_FILE_SAVE[]           = "QtHldplugin.Group.File.Save";
const char G_FILE_EXPORT[]         = "QtHldplugin.Group.File.Export";
const char G_FILE_CLOSE[]          = "QtHldplugin.Group.File.Close";
const char G_FILE_PRINT[]          = "QtHldplugin.Group.File.Print";
const char G_FILE_OTHER[]          = "QtHldplugin.Group.File.Other";

// Edit menu groups
const char G_EDIT_UNDOREDO[]       = "QtHldplugin.Group.Edit.UndoRedo";
const char G_EDIT_COPYPASTE[]      = "QtHldplugin.Group.Edit.CopyPaste";
const char G_EDIT_SELECTALL[]      = "QtHldplugin.Group.Edit.SelectAll";
const char G_EDIT_ADVANCED[]       = "QtHldplugin.Group.Edit.Advanced";

const char G_EDIT_FIND[]           = "QtHldplugin.Group.Edit.Find";
const char G_EDIT_OTHER[]          = "QtHldplugin.Group.Edit.Other";

// Advanced edit menu groups
const char G_EDIT_FORMAT[]         = "QtHldplugin.Group.Edit.Format";
const char G_EDIT_COLLAPSING[]     = "QtHldplugin.Group.Edit.Collapsing";
const char G_EDIT_TEXT[]           = "QtHldplugin.Group.Edit.Text";
const char G_EDIT_BLOCKS[]         = "QtHldplugin.Group.Edit.Blocks";
const char G_EDIT_FONT[]           = "QtHldplugin.Group.Edit.Font";
const char G_EDIT_EDITOR[]         = "QtHldplugin.Group.Edit.Editor";

// View menu groups
const char G_VIEW_VIEWS[]          = "QtHldplugin.Group.View.Views";
const char G_VIEW_PANES[]          = "QtHldplugin.Group.View.Panes";

// Tools menu groups
const char G_TOOLS_OPTIONS[]       = "QtHldplugin.Group.Tools.Options";

// Window menu groups
const char G_WINDOW_SIZE[]         = "QtHldplugin.Group.Window.Size";
const char G_WINDOW_SPLIT[]        = "QtHldplugin.Group.Window.Split";
const char G_WINDOW_NAVIGATE[]     = "QtHldplugin.Group.Window.Navigate";
const char G_WINDOW_LIST[]         = "QtHldplugin.Group.Window.List";
const char G_WINDOW_OTHER[]        = "QtHldplugin.Group.Window.Other";

// Help groups (global)
const char G_HELP_HELP[]           = "QtHldplugin.Group.Help.Help";
const char G_HELP_SUPPORT[]        = "QtHldplugin.Group.Help.Supprt";
const char G_HELP_ABOUT[]          = "QtHldplugin.Group.Help.About";
const char G_HELP_UPDATES[]        = "QtHldplugin.Group.Help.Updates";

// Touchbar groups
const char G_TOUCHBAR_HELP[]       = "QtHldplugin.Group.TouchBar.Help";
const char G_TOUCHBAR_EDITOR[]     = "QtHldplugin.Group.TouchBar.Editor";
const char G_TOUCHBAR_NAVIGATION[] = "QtHldplugin.Group.TouchBar.Navigation";
const char G_TOUCHBAR_OTHER[]      = "QtHldplugin.Group.TouchBar.Other";

const char WIZARD_CATEGORY_QT[] = "R.Qt";
const char WIZARD_TR_CATEGORY_QT[] = QT_TRANSLATE_NOOP("Core", "Qt");
const char WIZARD_KIND_UNKNOWN[] = "unknown";
const char WIZARD_KIND_PROJECT[] = "project";
const char WIZARD_KIND_FILE[] = "file";

const char SETTINGS_CATEGORY_CORE[] = "B.Core";
const char SETTINGS_ID_INTERFACE[] = "A.Interface";
const char SETTINGS_ID_SYSTEM[] = "B.Core.System";
const char SETTINGS_ID_SHORTCUTS[] = "C.Keyboard";
const char SETTINGS_ID_TOOLS[] = "D.ExternalTools";
const char SETTINGS_ID_MIMETYPES[] = "E.MimeTypes";

const char SETTINGS_DEFAULTTEXTENCODING[] = "General/DefaultFileEncoding";
const char SETTINGS_DEFAULT_LINE_TERMINATOR[] = "General/DefaultLineTerminator";

const char SETTINGS_THEME[] = "Core/HldpluginTheme";
const char DEFAULT_THEME[] = "flat";

const char TR_CLEAR_MENU[]         = QT_TRANSLATE_NOOP("Core", "Clear Menu");

const int MODEBAR_ICON_SIZE = 34;
const int MODEBAR_ICONSONLY_BUTTON_SIZE = MODEBAR_ICON_SIZE + 4;
const int DEFAULT_MAX_CHAR_COUNT = 10000000;

} // namespace Constants
} // namespace Core
