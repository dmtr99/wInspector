#Requires AutoHotKey v2.0-beta.3
#SingleInstance Force
#DllLoad "Gdiplus.dll"
#Include lib\SetSystemCursor.ahk
#Include lib\Gdip_All.ahk

DetectHiddenWindows true
SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

; Set the tray icon
TraySetIcon("imageres.dll",145)

; Settings initiation
oSettings_Default := Object()
oSettings_Default.MainGui := { 
    WinX: 100, 
    WinY: 100,
    WinW: 645, 
    WinH: 645,
    WinAlwaysOnTop: 1,
    WinGetClientPos: true,
    WinResize: 1,
    WinHighlight: 1,
    WinWindow:1,
    WinControl:1,
    WinMouse:1,
    WinList:1
}

Class Styles {
    __New(Style, Hex, Description, OptionText:="",SkipHex := "", Skip := "") {
        this.Style := Style
        this.Hex := Hex

        this.OptionText := OptionText
        this.Description := Description
        this.SkipHex := SkipHex ; used to skip this option if SkipHex applies in the option definition
        this.Skip := Skip ; used to skip this option always in the option definition
    }
}
Global aoWinStyles := Array()
aoWinStyles.Push(Styles("WS_BORDER", "0x800000","+/-Border. Creates a window that has a thin-line border.", "Border","0xC00000"))
aoWinStyles.Push(Styles("WS_POPUP", "0x80000000","Creates a pop-up window. This style cannot be used with the WS_CHILD style.",,true))
aoWinStyles.Push(Styles("WS_CAPTION", "0xC00000","+/-Caption. Creates a window that has a title bar. This style is a numerical combination of WS_BORDER and WS_DLGFRAME.", "Caption")) 
aoWinStyles.Push(Styles("WS_CLIPSIBLINGS", "0x4000000","Clips child windows relative to each other; that is, when a particular child window receives a WM_PAINT message, the WS_CLIPSIBLINGS style clips all other overlapping child windows out of the region of the child window to be updated. If WS_CLIPSIBLINGS is not specified and child windows overlap, it is possible, when drawing within the client area of a child window, to draw within the client area of a neighboring child window.")) 
aoWinStyles.Push(Styles("WS_DISABLED", "0x8000000","+/-Disabled. Creates a window that is initially disabled.","Disabled")) 
aoWinStyles.Push(Styles("WS_DLGFRAME", "0x400000","Creates a window that has a border of a style typically used with dialog boxes.")) 
aoWinStyles.Push(Styles("WS_HSCROLL", "0x100000", "Creates a window that has a horizontal scroll bar."))
aoWinStyles.Push(Styles("WS_MAXIMIZE", "0x1000000", "Creates a window that is initially maximized."))
aoWinStyles.Push(Styles("WS_MAXIMIZEBOX", "0x10000", "+/-MaximizeBox. Creates a window that has a maximize button. Cannot be combined with the WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.","MaximizeBox"))
aoWinStyles.Push(Styles("WS_MINIMIZE", "0x20000000", "Creates a window that is initially minimized."))
aoWinStyles.Push(Styles("WS_MINIMIZEBOX", "0x20000", "+/-MinimizeBox. Creates a window that has a minimize button. Cannot be combined with the WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.","MinimizeBox"))
aoWinStyles.Push(Styles("WS_OVERLAPPED", "0x0", "Creates an overlapped window. An overlapped window has a title bar and a border. Same as the WS_TILED style."))
aoWinStyles.Push(Styles("WS_OVERLAPPEDWINDOW", "0xCF0000", "Creates an overlapped window with the WS_OVERLAPPED, WS_CAPTION, WS_SYSMENU, WS_THICKFRAME, WS_MINIMIZEBOX, and WS_MAXIMIZEBOX styles. Same as the WS_TILEDWINDOW style.",,, true))
aoWinStyles.Push(Styles("WS_POPUPWINDOW", "0x80880000", "Creates a pop-up window with WS_BORDER, WS_POPUP, and WS_SYSMENU styles. The WS_CAPTION and WS_POPUPWINDOW styles must be combined to make the window menu visible.",,,true))
aoWinStyles.Push(Styles("WS_SIZEBOX", "0x40000", "+/-Resize. Creates a window that has a sizing border. Same as the WS_THICKFRAME style.","Resize"))
aoWinStyles.Push(Styles("WS_SYSMENU", "0x80000", "+/-SysMenu. Creates a window that has a window menu on its title bar. The WS_CAPTION style must also be specified.","SysMenu"))
aoWinStyles.Push(Styles("WS_VSCROLL", "0x200000", "Creates a window that has a vertical scroll bar."))
aoWinStyles.Push(Styles("WS_VISIBLE", "0x10000000", "Creates a window that is initially visible."))
aoWinStyles.Push(Styles("WS_CHILD", "0x40000000", "Creates a child window. A window with this style cannot have a menu bar. This style cannot be used with the WS_POPUP style."))

Global aoControlStyles := Array()
; stylest that seem double, for controls
aoControlStyles.Push(Styles("WS_DISABLED", "0x8000000", "+/-Disabled. Creates a window that is initially disabled.", "Disabled"))
aoControlStyles.Push(Styles("WS_TABSTOP", "0x10000", "+/-Tabstop. Specifies a control that can receive the keyboard focus when the user presses Tab. Pressing Tab changes the keyboard focus to the next control with the WS_TABSTOP style.","Tabstop"))
aoControlStyles.Push(Styles("WS_GROUP", "0x20000", '+/-Group. Indicates that this control is the first one in a group of controls. This style is automatically applied to manage the " only one at a time " behavior of radio buttons. In the rare case where two groups of radio buttons are added consecutively (with no other control types in between them), this style may be applied manually to the first control of the second radio group, which splits it off from the first.', "Group"))
aoControlStyles.Push(Styles("WS_THICKFRAME", "0x40000", "Creates a window that has a sizing border. Same as the WS_SIZEBOX style.",,"0x40000",true))

Global aoWinExStyles := Array()
aoWinExStyles.Push(Styles("WS_EX_ACCEPTFILES", "0x10", 'The window accepts drag-drop files.'))
aoWinExStyles.Push(Styles("WS_EX_APPWINDOW", "0x40000", 'Forces a top-level window onto the taskbar when the window is visible.'))
aoWinExStyles.Push(Styles("WS_EX_CLIENTEDGE", "0x200", 'The window has a border with a sunken edge.'))
aoWinExStyles.Push(Styles("WS_EX_COMPOSITED", "0x2000000", 'Paints all descendants of a window in bottom-to-top painting order using double-buffering. Bottom-to-top painting order allows a descendent window to have translucency (alpha) and transparency (color-key) effects, but only if the descendent window also has the WS_EX_TRANSPARENT bit set. Double-buffering allows the window and its descendents to be painted without flicker. This cannot be used if the window has a class style of either CS_OWNDC or CS_CLASSDC. Windows 2000: This style is not supported.'))
aoWinExStyles.Push(Styles("WS_EX_CONTEXTHELP", "0x400", 'The title bar of the window includes a question mark. When the user clicks the question mark, the cursor changes to a question mark with a pointer. If the user then clicks a child window, the child receives a WM_HELP message. The child window should pass the message to the parent window procedure, which should call the WinHelp function using the HELP_WM_HELP command. The Help application displays a pop-up window that typically contains help for the child window. WS_EX_CONTEXTHELP cannot be used with the WS_MAXIMIZEBOX or WS_MINIMIZEBOX styles.'))
aoWinExStyles.Push(Styles("WS_EX_CONTROLPARENT", "0x10000", 'The window itself contains child windows that should take part in dialog box navigation. If this style is specified, the dialog manager recurses into children of this window when performing navigation operations such as handling the TAB key, an arrow key, or a keyboard mnemonic.'))
aoWinExStyles.Push(Styles("WS_EX_DLGMODALFRAME", "0x1", 'The window has a double border; the window can, optionally, be created with a title bar by specifying the WS_CAPTION style in the dwStyle parameter.'))
aoWinExStyles.Push(Styles("WS_EX_LAYERED", "0x80000", 'The window is a layered window. This style cannot be used if the window has a class style of either CS_OWNDC or CS_CLASSDC. Windows 8: The WS_EX_LAYERED style is supported for top-level windows and child windows. Previous Windows versions support WS_EX_LAYERED only for top-level windows.'))
aoWinExStyles.Push(Styles("WS_EX_LAYOUTRTL", "0x400000", 'If the shell language is Hebrew, Arabic, or another language that supports reading order alignment, the horizontal origin of the window is on the right edge. Increasing horizontal values advance to the left.'))
aoWinExStyles.Push(Styles("WS_EX_LEFT", "0x0", 'The window has generic left-aligned properties. This is the default.'))
aoWinExStyles.Push(Styles("WS_EX_LEFTSCROLLBAR", "0x4000", 'If the shell language is Hebrew, Arabic, or another language that supports reading order alignment, the vertical scroll bar (if present) is to the left of the client area. For other languages, the style is ignored.'))
aoWinExStyles.Push(Styles("WS_EX_LTRREADING", "0x0", 'The window text is displayed using left-to-right reading-order properties. This is the default.'))
aoWinExStyles.Push(Styles("WS_EX_MDICHILD", "0x40", 'The window is a MDI child window.'))
aoWinExStyles.Push(Styles("WS_EX_NOACTIVATE", "0x8000000", 'A top-level window created with this style does not become the foreground window when the user clicks it. The system does not bring this window to the foreground when the user minimizes or closes the foreground window. The window should not be activated The window does not appear on the taskbar by default. To force the window to appear on the taskbar, use the WS_EX_APPWINDOW style. To activate the window, use the SetActiveWindow or SetForegroundWindow function. through programmatic access or via keyboard navigation by accessible technology, such as Narrator.'))
aoWinExStyles.Push(Styles("WS_EX_NOINHERITLAYOUT", "0x100000", 'The window does not pass its window layout to its child windows.'))
aoWinExStyles.Push(Styles("WS_EX_NOPARENTNOTIFY", "0x4", 'The child window created with this style does not send the WM_PARENTNOTIFY message to its parent window when it is created or destroyed.'))
aoWinExStyles.Push(Styles("WS_EX_NOREDIRECTIONBITMAP", "0x200000", 'The window does not render to a redirection surface. This is for windows that do not have visible content or that use mechanisms other than surfaces to provide their visual.'))
aoWinExStyles.Push(Styles("WS_EX_RIGHT", "0x1000", 'The window has generic "right-aligned" properties. This depends on the window class. This style has an effect only if the shell language is Hebrew, Arabic, or another language that supports reading-order alignment; otherwise, the style is ignored. Using the WS_EX_RIGHT style for static or edit controls has the same effect as using the SS_RIGHT or ES_RIGHT style, respectively. Using this style with button controls has the same effect as using BS_RIGHT and BS_RIGHTBUTTON styles.'))
aoWinExStyles.Push(Styles("WS_EX_RIGHTSCROLLBAR", "0x0", 'The vertical scroll bar (if present) is to the right of the client area. This is the default.'))
aoWinExStyles.Push(Styles("WS_EX_RTLREADING", "0x2000", 'If the shell language is Hebrew, Arabic, or another language that supports reading-order alignment, the window text is displayed using right-to-left reading-order properties. For other languages, the style is ignored.'))
aoWinExStyles.Push(Styles("WS_EX_STATICEDGE", "0x20000", 'The window has a three-dimensional border style intended to be used for items that do not accept user input.'))
aoWinExStyles.Push(Styles("WS_EX_TOOLWINDOW", "0x80", 'The window is intended to be used as a floating toolbar. A tool window has a title bar that is shorter than a normal title bar, and the window title is drawn using a smaller font. A tool window does not appear in the taskbar or in the dialog that appears when the user presses ALT+TAB. If a tool window has a system menu, its icon is not displayed on the title bar. However, you can display the system menu by right-clicking or by typing ALT+SPACE.'))
aoWinExStyles.Push(Styles("WS_EX_TOPMOST", "0x8", 'The window should be placed above all non-topmost windows and should stay above them, even when the window is deactivated. To add or remove this style, use the SetWindowPos function.'))
aoWinExStyles.Push(Styles("WS_EX_TRANSPARENT", "0x20", 'The window should not be painted until siblings beneath the window (that were created by the same thread) have been painted. The window appears transparent because the bits of underlying sibling windows have already been painted. To achieve transparency without these restrictions, use the SetWindowRgn function.'))
aoWinExStyles.Push(Styles("WS_EX_WINDOWEDGE", "0x100", 'The window has a border with a raised edge.'))

global aoTextStyles := Array()
aoTextStyles.Push(Styles("SS_BLACKFRAME", "0x7",'Specifies a box with a frame drawn in the same color as the window frames. This color is black in the default color scheme.'))
aoTextStyles.Push(Styles("SS_BLACKRECT", "0x4",'Specifies a rectangle filled with the current window frame color. This color is black in the default color scheme.'))
aoTextStyles.Push(Styles("SS_CENTER", "0x1",'+/-Center. Specifies a simple rectangle and centers the text in the rectangle. The control automatically wraps words that extend past the end of a line to the beginning of the next centered line.', 'Center'))
aoTextStyles.Push(Styles("SS_ETCHEDFRAME", "0x12",'Draws the frame of the static control using the EDGE_ETCHED edge style.'))
aoTextStyles.Push(Styles("SS_ETCHEDHORZ", "0x10",'Draws the top and bottom edges of the static control using the EDGE_ETCHED edge style.'))
aoTextStyles.Push(Styles("SS_ETCHEDVERT", "0x11",'Draws the left and right edges of the static control using the EDGE_ETCHED edge style.'))
aoTextStyles.Push(Styles("SS_GRAYFRAME", "0x8",'Specifies a box with a frame drawn with the same color as the screen background (desktop). This color is gray in the default color scheme.'))
aoTextStyles.Push(Styles("SS_GRAYRECT", "0x5",'Specifies a rectangle filled with the current screen background color. This color is gray in the default color scheme.'))
aoTextStyles.Push(Styles("SS_LEFT", "0x0",'+/-Left. This is the default. It specifies a simple rectangle and left-aligns the text in the rectangle. The text is formatted before it is displayed. Words that extend past the end of a line are automatically wrapped to the beginning of the next left-aligned line. Words that are longer than the width of the control are truncated.', 'Left'))
aoTextStyles.Push(Styles("SS_LEFTNOWORDWRAP", "0xC",'+/-Wrap. Specifies a rectangle and left-aligns the text in the rectangle. Tabs are expanded, but words are not wrapped. Text that extends past the end of a line is clipped.', 'Wrap'))
aoTextStyles.Push(Styles("SS_NOPREFIX", "0x80","Prevents interpretation of any ampersand (&) characters in the control's text as accelerator prefix characters. This can be useful when file names or other strings that might contain an ampersand (&) must be displayed within a text control."))
aoTextStyles.Push(Styles("SS_NOTIFY", "0x100",'Sends the parent window the STN_CLICKED notification when the user clicks the control.'))
aoTextStyles.Push(Styles("SS_RIGHT", "0x2",'+/-Right. Specifies a rectangle and right-aligns the specified text in the rectangle.', 'Right'))
aoTextStyles.Push(Styles("SS_SUNKEN", "0x1000",'Draws a half-sunken border around a static control.'))
aoTextStyles.Push(Styles("SS_WHITEFRAME", "0x9",'Specifies a box with a frame drawn with the same color as the window background. This color is white in the default color scheme.'))
aoTextStyles.Push(Styles("SS_WHITERECT", "0x6",'Specifies a rectangle filled with the current window background color. This color is white in the default color scheme.'))

global aoEditStyles := Array()
aoEditStyles.Push(Styles("ES_AUTOHSCROLL", "0x80",'+/-Wrap for multi-line edits, and +/-Limit for single-line edits. Automatically scrolls text to the right by 10 characters when the user types a character at the end of the line. When the user presses Enter, the control scrolls all text back to the zero position.','Limit'))
aoEditStyles.Push(Styles("ES_AUTOVSCROLL", "0x40",'Scrolls text up one page when the user presses Enter on the last line.'))
aoEditStyles.Push(Styles("ES_CENTER", "0x1",'+/-Center. Centers text in a multiline edit control.', 'Center'))
aoEditStyles.Push(Styles("ES_LOWERCASE", "0x10",'+/-Lowercase. Converts all characters to lowercase as they are typed into the edit control.', 'Lowercase'))
aoEditStyles.Push(Styles("ES_NOHIDESEL", "0x100",'Negates the default behavior for an edit control. The default behavior hides the selection when the control loses the input focus and inverts the selection when the control receives the input focus. If you specify ES_NOHIDESEL, the selected text is inverted, even if the control does not have the focus.'))
aoEditStyles.Push(Styles("ES_NUMBER", "0x2000",'+/-Number. Prevents the user from typing anything other than digits in the control.', 'Number'))
aoEditStyles.Push(Styles("ES_OEMCONVERT", "0x400",'This style is most useful for edit controls that contain file names.'))
aoEditStyles.Push(Styles("ES_MULTILINE", "0x4",'+/-Multi. Designates a multiline edit control. The default is a single-line edit control.','Multi'))
aoEditStyles.Push(Styles("ES_PASSWORD", "0x20",'+/-Password. Displays a masking character in place of each character that is typed into the edit control, which conceals the text.', 'Password'))
aoEditStyles.Push(Styles("ES_READONLY", "0x800",'+/-ReadOnly. Prevents the user from typing or editing text in the edit control.', 'ReadOnly'))
aoEditStyles.Push(Styles("ES_RIGHT", "0x2",'+/-Right. Right-aligns text in a multiline edit control.', 'Right'))
aoEditStyles.Push(Styles("ES_UPPERCASE", "0x8",'+/-Uppercase. Converts all characters to uppercase as they are typed into the edit control.', 'Uppercase'))
aoEditStyles.Push(Styles("ES_WANTRETURN", "0x1000","+/-WantReturn. Specifies that a carriage return be inserted when the user presses Enter while typing text into a multiline edit control in a dialog box. If you do not specify this style, pressing Enter has the same effect as pressing the dialog box's default push button. This style has no effect on a single-line edit control.", 'WantReturn'))

global aoEditMultiLineStyles := Array()
aoEditMultiLineStyles.Push(Styles("ES_AUTOHSCROLL", "0x80",'+/-Wrap for multi-line edits, and +/-Limit for single-line edits. Automatically scrolls text to the right by 10 characters when the user types a character at the end of the line. When the user presses Enter, the control scrolls all text back to the zero position.','Wrap'))
aoEditMultiLineStyles.Push(Styles("ES_AUTOVSCROLL", "0x40",'Scrolls text up one page when the user presses Enter on the last line.'))
aoEditMultiLineStyles.Push(Styles("ES_CENTER", "0x1",'+/-Center. Centers text in a multiline edit control.', 'Center'))
aoEditMultiLineStyles.Push(Styles("ES_LOWERCASE", "0x10",'+/-Lowercase. Converts all characters to lowercase as they are typed into the edit control.', 'Lowercase'))
aoEditMultiLineStyles.Push(Styles("ES_NOHIDESEL", "0x100",'Negates the default behavior for an edit control. The default behavior hides the selection when the control loses the input focus and inverts the selection when the control receives the input focus. If you specify ES_NOHIDESEL, the selected text is inverted, even if the control does not have the focus.'))
aoEditMultiLineStyles.Push(Styles("ES_NUMBER", "0x2000",'+/-Number. Prevents the user from typing anything other than digits in the control.', 'Number'))
aoEditMultiLineStyles.Push(Styles("ES_OEMCONVERT", "0x400",'This style is most useful for edit controls that contain file names.'))
aoEditMultiLineStyles.Push(Styles("ES_MULTILINE", "0x4",'+/-Multi. Designates a multiline edit control. The default is a single-line edit control.','Multi'))
aoEditMultiLineStyles.Push(Styles("ES_PASSWORD", "0x20",'+/-Password. Displays a masking character in place of each character that is typed into the edit control, which conceals the text.', 'Password'))
aoEditMultiLineStyles.Push(Styles("ES_READONLY", "0x800",'+/-ReadOnly. Prevents the user from typing or editing text in the edit control.', 'ReadOnly'))
aoEditMultiLineStyles.Push(Styles("ES_RIGHT", "0x2",'+/-Right. Right-aligns text in a multiline edit control.', 'Right'))
aoEditMultiLineStyles.Push(Styles("ES_UPPERCASE", "0x8",'+/-Uppercase. Converts all characters to uppercase as they are typed into the edit control.', 'Uppercase'))
aoEditMultiLineStyles.Push(Styles("ES_WANTRETURN", "0x1000","+/-WantReturn. Specifies that a carriage return be inserted when the user presses Enter while typing text into a multiline edit control in a dialog box. If you do not specify this style, pressing Enter has the same effect as pressing the dialog box's default push button. This style has no effect on a single-line edit control.", 'WantReturn'))

global aoButtonStyles := Array()
aoButtonStyles.Push(Styles("BS_AUTO3STATE", "0x6",'Creates a button that is the same as a three-state check box, except that the box changes its state when the user selects it. The state cycles through checked, indeterminate, and cleared.'))
aoButtonStyles.Push(Styles("BS_AUTOCHECKBOX", "0x3",'Creates a button that is the same as a check box, except that the check state automatically toggles between checked and cleared each time the user selects the check box.'))
aoButtonStyles.Push(Styles("BS_AUTORADIOBUTTON", "0x9","Creates a button that is the same as a radio button, except that when the user selects it, the system automatically sets the button's check state to checked and automatically sets the check state for all other buttons in the same group to cleared."))
aoButtonStyles.Push(Styles("BS_LEFT", "0x100",'+/-Left. Left-aligns the text.', 'Left'))
aoButtonStyles.Push(Styles("BS_PUSHBUTTON", "0x0",'Creates a push button that posts a WM_COMMAND message to the owner window when the user selects the button.'))
aoButtonStyles.Push(Styles("BS_PUSHLIKE", "0x1000","Makes a checkbox or radio button look and act like a push button. The button looks raised when it isn't pushed or checked, and sunken when it is pushed or checked."))
aoButtonStyles.Push(Styles("BS_RIGHT", "0x200",'+/-Right. Right-aligns the text.', 'Right'))
aoButtonStyles.Push(Styles("BS_RIGHTBUTTON", "0x20","+Right (i.e. +Right includes both BS_RIGHT and BS_RIGHTBUTTON, but -Right removes only BS_RIGHT, not BS_RIGHTBUTTON). Positions a checkbox square or radio button circle on the right side of the control's available width instead of the left."))
aoButtonStyles.Push(Styles("BS_BOTTOM", "0x800","Places the text at the bottom of the control's available height."))
aoButtonStyles.Push(Styles("BS_CENTER", "0x300",'+/-Center. Centers the text horizontally within the control`'s available width.', 'Center'))
aoButtonStyles.Push(Styles("BS_DEFPUSHBUTTON", "0x1",'+/-Default. Creates a push button with a heavy black border. If the button is in a dialog box, the user can select the button by pressing Enter, even when the button does not have the input focus. This style is useful for enabling the user to quickly select the most likely option.', 'Default'))
aoButtonStyles.Push(Styles("BS_MULTILINE", "0x2000",'+/-Wrap. Wraps the text to multiple lines if the text is too long to fit on a single line in the control`'s available width. This also allows linefeed (``n) to start new lines of text.', 'Wrap'))
aoButtonStyles.Push(Styles("BS_NOTIFY", "0x4000",'Enables a button to send BN_KILLFOCUS and BN_SETFOCUS notification codes to its parent window. Note that buttons send the BN_CLICKED notification code regardless of whether it has this style. To get BN_DBLCLK notification codes, the button must have the BS_RADIOBUTTON or BS_OWNERDRAW style.'))
aoButtonStyles.Push(Styles("BS_TOP", "0x400",'Places text at the top of the control`'s available height.'))
aoButtonStyles.Push(Styles("BS_VCENTER", "0xC00",'Vertically centers text in the control`'s available height.'))
aoButtonStyles.Push(Styles("BS_FLAT", "0x8000",'Specifies that the button is two-dimensional; it does not use the default shading to create a 3-D effect.'))
aoButtonStyles.Push(Styles("BS_GROUPBOX", "0x7",'Creates a rectangle in which other controls can be grouped. Any text associated with this style is displayed in the rectangle`'s upper left corner.'))

Global aoDefaultStyles := Object()
aoDefaultStyles.window := {style:0xffffffff94ca0000, exStyle:0x100}
aoDefaultStyles.edit := {style:0x50010080, exStyle:0x200}
aoDefaultStyles.editmultiLine := {style:0x50211040, exStyle:0x200}
aoDefaultStyles.button := {style:0x50010000, exStyle:0x0}
aoDefaultStyles.checkbox := {style:0x50010003, exStyle:0x0}
aoDefaultStyles.monthcal := {style:0x50010000, exStyle:0x0}
aoDefaultStyles.picture := {style:0x50000003, exStyle:0x0}
aoDefaultStyles.process := {style:0x50000000, exStyle:0x0}
aoDefaultStyles.radio := {style:0x50030009, exStyle:0x0}
aoDefaultStyles.slider := {style:0x50030000, exStyle:0x0}
aoDefaultStyles.tab3 := {style:0x54010240, exStyle:0x0}
aoDefaultStyles.text := {style:0x50000000, exStyle:0x0}
aoDefaultStyles.treeview := {style:0x50010027, exStyle:0x200}
aoDefaultStyles.combobox := {style:0x50010242, exStyle:0x0}
aoDefaultStyles.datetime := {style:0x5201000c, exStyle:0x0}
aoDefaultStyles.dropdownlist := {style:0x50010203, exStyle:0x0}
aoDefaultStyles.groupbox := {style:0x50000007, exStyle:0x0}
aoDefaultStyles.link := {style:0x50010000, exStyle:0x0}
aoDefaultStyles.listbox := {style:0x50010081, exStyle:0x200}
aoDefaultStyles.listview := {style:0x500000c2, exStyle:0x0}
aoDefaultStyles.statusbar := {style:0x50000800, exStyle:0x0}

global SettingsFile := Regexreplace(A_scriptName, "(.*)\..*", "$1.ini")
;Load the existing settings 
global oSettings := FileExist(SettingsFile) ? ReadINI(SettingsFile, oSettings_Default) : oSettings_Default
global oSet := oSettings.MainGui

If !pToken := Gdip_Startup() {
    MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system"
    ExitApp
}
OnExit((ExitReason, ExitCode) => Gdip_Shutdown(pToken))

MyGui := Gui("+AlwaysOnTop", "wInspector")
oSet.WinResize=1 ? myGui.Opt("+Resize") : myGui.Opt("-Resize")
oSet.WinAlwaysOnTop=1 ? myGui.Opt("+AlwaysOnTop") : myGui.Opt("-AlwaysOnTop")
MyGui.MarginX := 2
MyGui.MarginY := 2
MyGui.Width := 1200
MyGui.win_hwnd := 0
MyGui.ctrl_hwnd := 0
ogButton_Selector := MyGui.addButton("xm ym w60 vbtnSelector BackgroundTrans h20 w20 +0x4000", "+")
ogButton_Selector.SetFont("s18", "Times New Roman")
ogButton_Selector.statusbar := "Rclick and drag to select a specific control or window"

ogGB_Window := MyGui.AddGroupBox("w300 h145 Section","Window")
MyGui.AddText("xp+3 yp+18","Title")
ogEdit_wTitle := MyGui.AddEdit("x42 yp-3 w255","")
ogEdit_wTitle.StatusBar := "WinGetTitle(WinTitle, WinText, ExcludeTitle, ExcludeText)"
MyGui.AddText("x6 yp+26", "Class")
ogEdit_wClass := MyGui.AddEdit("x42 yp-3 w178 vwClass +ReadOnly")
ogEdit_wClass.StatusBar := "WinGetClass(WinTitle, WinText, ExcludeTitle, ExcludeText)"
MyGui.AddText("x+4 yp+3", "ID")
ogEdit_wID := MyGui.AddEdit("x237 yp-3 Right vwID w60 +ReadOnly")
ogEdit_wID.StatusBar := "WinGetID(WinTitle, WinText, ExcludeTitle, ExcludeText)"
MyGui.AddText("x4 yp+26", "Process")
ogEdit_wProcess := MyGui.AddEdit("x42 yp-3 w135 vwProcess +ReadOnly")
MyGui.AddText("x+3 yp+3", "Process_ID")
ogEdit_wProcess_ID := MyGui.AddEdit("x237 yp-3 w60 Right vwProcess_ID +ReadOnly")

MyGui.AddText("x30 yp+26", "X")
ogEdit_wXPos := MyGui.AddEdit("x42 yp-3 Right Number vwXPos w40")
MyGui.AddText("x+5 yp+3", "Y")
ogEdit_wYPos := MyGui.AddEdit("x+2 yp-3 Right Number vwYPos w40")
ogEdit_wYPos.StatusBar := "Y position of window"
MyGui.AddText("x+5 yp+3", "W")
ogEdit_wWidth := MyGui.AddEdit("x+2 yp-3 Right Number vwWPos w40")
MyGui.AddText("x+5 yp+3", "H")
ogEdit_wHeight := MyGui.AddEdit("x+2 yp-3 Right Number vwHPos w40")
ogButton_Move := MyGui.AddButton("x258 yp-1 w40", "Move")
ogButton_Move.OnEvent("Click", (*) => (WinExist("ahk_id " ogEdit_wID.value) ? WinMove(ogEdit_wXPos.value, ogEdit_wYPos.value, ogEdit_wWidth.value, ogEdit_wHeight.value, "ahk_id " ogEdit_wID.value):""))
MyGui.AddText("x8 y+4", "Transparent:")
ogSlider_Transparent := MyGui.AddSlider("xp+60 vTransparent  Range0-255 ToolTip", "255")
ogSlider_Transparent.OnEvent("Change", (*) => (WinExist("ahk_id " ogEdit_wID.value) ? WinSetTransparent(ogSlider_Transparent.value, "ahk_id " ogEdit_wID.value):""))

ogGB_Control := MyGui.AddGroupBox("xm  w300 h88", "Control")
MyGui.AddText("xp+3 yp+18", "Text")
ogEdit_cText := MyGui.AddEdit("x42 yp-3 w255", "")
ogEdit_cText.StatusBar := "ControlGetText(Control, WinTitle, WinText, ExcludeTitle, ExcludeText)"
MyGui.AddText("x6 yp+26", "Class")
ogEdit_cClass := MyGui.AddEdit("x42 yp-3 w178 vccClass +ReadOnly")
ogEdit_cClass.StatusBar := "ControlGetClassNN(Control , WinTitle, WinText, ExcludeTitle, ExcludeText)"
MyGui.AddText("x+4 yp+3", "ID")
ogEdit_cID := MyGui.AddEdit("x237 yp-3 w60 Right vcID +ReadOnly")
ogEdit_cID.StatusBar := "ControlGetHwnd(Control, WinTitle, WinText, ExcludeTitle, ExcludeText)"

MyGui.AddText("x30 yp+26", "X")
ogEdit_cXPos := MyGui.AddEdit("x42 yp-3 Right Number vcXPos w40")
MyGui.AddText("x+5 yp+3", "Y")
ogEdit_cYPos := MyGui.AddEdit("x+2 yp-3 Right Number vcYPos w40")
MyGui.AddText("x+5 yp+3", "W")
ogEdit_cWidth := MyGui.AddEdit("x+2 yp-3 Right Number vcWPos w40")
MyGui.AddText("x+5 yp+3", "H")
ogEdit_cHeight := MyGui.AddEdit("x+2 yp-3 Right Number vcHPos w40")
ogButton_cMove := MyGui.AddButton("x258 yp-1 w40", "Move")
ogButton_cMove.OnEvent("Click", (*) => (ControlMove(ogEdit_cXPos.value, ogEdit_cYPos.value, ogEdit_cWidth.value, ogEdit_cHeight.value, ogEdit_cID.value+0)))

ogGB_Mouse := ogGB_Mouse := MyGui.AddGroupBox("xm w300 h307", "Mouse")
MyGui.AddText("xp+3 yp+18", "Pos")
ogEdit_mPos := MyGui.AddEdit("x42 yp-3 w70", "")
ogDDL_MouseCoordMode := MyGui.AddDropDownList("x+3 yp w70 vDDL_MouseCoordMode Choose1", ["Screen", "Window", "Client"])
ogBut_MouseMove := MyGui.AddButton("x+3 yp w50", "Move")
ogBut_MouseMove.OnEvent("Click", (*) => (CoordMode("Mouse", ogDDL_MouseCoordMode.Text), MouseMove(MyGui.MouseX+0,MyGui.MouseY+0)))
ogBut_MouseClick := MyGui.AddButton("x+3 yp w50", "Click")
ogBut_MouseClick.OnEvent("Click", (*) => (CoordMode("Mouse", ogDDL_MouseCoordMode.Text), Mouseclick(,MyGui.MouseX+0,MyGui.MouseY+0)))
MyGui.AddText("x6 yp+26", "RGB")
ogEdit_mColor := MyGui.AddEdit("x42 yp-3 w70", "")
ogText_mColor := MyGui.AddText("x+3 yp w21 h21 BackgroundWhite +Border")
ogDDL_GridSize := MyGui.AddDropDownList("x+3 yp w60 vDDL_GridSize Choose5", ["1x1", "3x3","5x5", "9x9", "15x15"])
ogDDL_GridSize.OnEvent("Change", GridSize_Change)
MyGui.Grid := 15

ogPic_Grid := MyGui.AddPicture("x42 y+2 w" MyGui.Grid*16 " h" MyGui.Grid*16 " +0x40 +0xE +Border Section")
ogText_Line1 := MyGui.AddText("xs+" (MyGui.Grid-1) * 16/2 " ys+1 w1 h" MyGui.Grid * 16-2 " backgroundWhite")
ogText_Line2 := MyGui.AddText("xs+" (MyGui.Grid+1) * 16/2 " ys+1 w1 h" MyGui.Grid * 16-2 " backgroundWhite")
ogText_Line3 := MyGui.AddText("xs+1 ys+" (MyGui.Grid - 1) * 16 / 2 " w" MyGui.Grid * 16-2 " h1 backgroundWhite")
ogText_Line4 := MyGui.AddText("xs+1 ys+" (MyGui.Grid + 1) * 16 / 2 " w" MyGui.Grid * 16-2 " h1 backgroundWhite")

xList := 310
ogText_WinSearch := MyGui.AddText("x" xList+20 " ym+7", "WinSearch:")
ogText_WinSearch.GroupBox := "List"
ogEdit_win_search :=MyGui.AddEdit("yp-3 x+10 w200 vwin_seach")
ogEdit_win_search.statusbar := "Type to filter the windows on specific words"
ogEdit_win_search.OnEvent("Change",UpdateWinList)
ogEdit_win_search.GroupBox := "List"
ogCB_FilterWinVisible := MyGui.AddCheckbox("xp+210 yp+3 vfilter_win_visible Checked", "Visible") 
ogCB_FilterWinVisible.OnEvent("Click",UpdateWinList)
ogCB_FilterWinVisible.GroupBox := "List"
ogCB_FilterWinVisible.Statusbar := "Filter on only visible windows"
ogCB_FilterWinTitle := MyGui.AddCheckbox("xp+60 yp vfilter_win_title Checked", "Title") 
ogCB_FilterWinTitle.OnEvent("Click", UpdateWinList)
ogCB_FilterWinTitle.GroupBox := "List"
ogCB_FilterWinTitle.Statusbar := "Filter on windows with a title"

ogLV_WinList := MyGui.AddListView("x" xList " y+8 r15 w" (MyGui.Width - 8 * 3) / 2 " vWinList section AltSubmit", ["Title", "Process", "ID", "Visible", "X", "Y", "W", "H"])
ogLV_WinList.Opt("Count400 -Multi")
ogLV_WinList.GroupBox := "List"
ogLV_WinList.ModifyCol()
ogLV_WinList.ModifyCol(1, 300)
ogLV_WinList.ModifyCol(2, 100)
ogLV_WinList.ModifyCol(3, 60)
ogLV_WinList.ModifyCol(4, 50)
ogLV_WinList.ModifyCol(3, "Integer")
ogLV_WinList.ModifyCol(4, "SortDesc")

ogLV_WinList.OnEvent("Click", DClickWinList)
ogLV_WinList.OnNotify(NM_RCLICK := -5, RClickWinList)
ogLV_WinList.LeftMargin := 3

ogText_CtrlSearch := MyGui.AddText("x" xList+20 " y+6", "ControlSearch:")
ogText_CtrlSearch.GroupBox := "List"
ogEdit_ctrl_search := MyGui.AddEdit("yp-3 x+10 w200 vctrl_search")
ogEdit_ctrl_search.OnEvent("Change", UpdateCtrlList)
ogEdit_ctrl_search.statusbar := "Type to filter the controls on specific words"
ogEdit_ctrl_search.GroupBox := "List"
ogCB_FilterCtrlVisible := MyGui.AddCheckbox("xp+210 yp+3 vfilter_ctrl_visible", "Visible")
ogCB_FilterCtrlVisible.OnEvent("Click", UpdateCtrlList)
ogCB_FilterCtrlVisible.GroupBox := "List"
ogCB_FilterCtrlVisible.Statusbar := "Filter on only visible controls"

ogCB_FilterCtrlText := MyGui.AddCheckbox("xp+60 yp vfilter_ctrl_text", "Text visible") 
ogCB_FilterCtrlText.OnEvent("Click", UpdateCtrlList)
ogCB_FilterCtrlText.GroupBox := "List"
ogCB_FilterCtrlText.statusbar := "Filter on controls with text"
ogLV_CtrlList := MyGui.AddListView("x" xList " y+8 r15 w" (MyGui.Width-8*3)/2 " vCtrlList section AltSubmit", ["Class(NN)", "Hwnd", "Text", "X", "Y", "W", "H","Visible"])
ogLV_CtrlList.Opt("Count100 -Multi")
ogLV_CtrlList.OnEvent("Click", DClickCtrlList)
ogLV_CtrlList.OnNotify(NM_RCLICK := -5, RClickCtrlList)
ogLV_CtrlList.LeftMargin := 3
ogLV_CtrlList.BottomMargin := 26
ogLV_CtrlList.GroupBox := "List"
UpdateWinList()

SettingsMenu := Menu()
SettingsMenu.Add("Resize", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinResize:= !oSet.WinResize, oSet.WinResize ? myGui.Opt("+Resize") :  myGui.Opt("-Resize")))
oSet.WinResize=1 ? SettingsMenu.Check("Resize") : ""
SettingsMenu.Add("AlwaysOnTop", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinAlwaysOnTop:= !oSet.WinAlwaysOnTop, oSet.WinAlwaysOnTop ? myGui.Opt("+AlwaysOnTop") :  myGui.Opt("-AlwaysOnTop")))
oSet.WinAlwaysOnTop=1 ? SettingsMenu.Check("AlwaysOnTop") : ""
SettingsMenu.Add()
SettingsMenu.Add("Highlight", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinHighlight:= !oSet.WinHighlight))
oSet.WinHighlight=1 ? SettingsMenu.Check("Highlight") : ""

ViewMenu := Menu()
ViewMenu.Add("Window", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinWindow:= !oSet.WinWindow, WI_GuiHideAndMove(myGui, "Window", oSet.WinWindow)))
ViewMenu.Add("Control", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinControl:= !oSet.WinControl, WI_GuiHideAndMove(myGui, "Control", oSet.WinControl)))
ViewMenu.Add("Mouse", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinMouse:= !oSet.WinMouse, WI_GuiHideAndMove(myGui, "Mouse", oSet.WinMouse)))
ViewMenu.Add("List", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinList:= !oSet.WinList, WI_GuiHideAndMove(myGui, "List", oSet.WinList)))

Menus := MenuBar()
Menus.Add("&Settings", SettingsMenu)
Menus.Add("&View", ViewMenu)
Menus.Add( "&Reload", (*) => (Gui_Close(myGui), Reload()))
MyGui.MenuBar := Menus

; Create a Status Bar to give info about the number of files and their total size:
SB := MyGui.Add("StatusBar")
; SB.SetParts(300, 300)  ; Create three parts in the bar (the third part fills all the remaining width).
MyGui.OnEvent("Size",Gui_Size)
MyGui.OnEvent("Close",Gui_Close)
GuiAddGroupboxProperty(MyGui) ; Add a Groupbox property to controls

MyGui.Show("x" oSet.WinX " y" oSet.WinY " w" oSet.WinW " h" oSet.WinH " Hide")
oSet.WinWindow=1 ? ViewMenu.Check("Window") : WI_GuiHideAndMove(MyGui, "Window", false)
oSet.WinControl=1 ? ViewMenu.Check("Control") : WI_GuiHideAndMove(MyGui, "Control", false)
oSet.WinMouse=1 ? ViewMenu.Check("Mouse") : WI_GuiHideAndMove(MyGui, "Mouse", false)
oSet.WinList=1 ? ViewMenu.Check("List") : WI_GuiHideAndMove(MyGui, "List", false)

MyGui.Show()

; Reset Cursor in case previous script gave error
SetSystemCursor("Default")
OnMessage(WM_LBUTTONDOWN := 0x0201, CheckButtonClick)
OnMessage(0x200, WM_MOUSEMOVE)

return

CheckButtonClick(wParam , lParam, msg, hwnd){
    global MyGui

    MouseGetPos(,,,&OutputVarControlHwnd, 2)
    MouseControlHwnd_Prev := OutputVarControlHwnd
    MouseX_Prev := -1
    MouseY_Prev := -1
    GuiBox := GuiRectangle()

    if (ogButton_Selector.hwnd=OutputVarControlHwnd){
        ogButton_Selector.text := ""
        SetSystemCursor("Cross")
        While(GetKeyState("LButton")){
            CoordMode("Mouse", ogDDL_MouseCoordMode.Text)
            MouseGetPos(&MouseX, &MouseY, &MouseWinHwnd, &MouseControlHwnd, 2)
            Sleep(100)
            if (MouseControlHwnd_Prev != MouseControlHwnd and MouseControlHwnd!=""){
                
                if oSet.WinHighlight{
                    GuiBox.MoveToControl(MouseControlHwnd, MouseWinHwnd)
                    GuiBox.Show()
                }
                SetSelectedWindow(MouseWinHwnd)
                SetSelectedControl(MouseControlHwnd) 
            }
            if (MouseX_Prev != MouseX or MouseY_Prev != MouseY){
                SetSelectedMouse(MouseX, MouseY)
                SetSelectedMouseGrid(MouseX, MouseY)
            }
            
            MouseControlHwnd_Prev := MouseControlHwnd
            MouseX_Prev := MouseX
            MouseY_Prev := MouseY

        }
        MyGui.win_hwnd := MouseWinHwnd
        MyGui.ctrl_hwnd := MouseControlHwnd
        MyGui.MouseX := MouseX
        MyGui.MouseY := MouseY
        SetSelectedWindow(MouseWinHwnd)
        SetSelectedControl(MouseControlHwnd)
        
        UpdateWinList(MyGui)
        UpdateCtrlList(MyGui)
        ogButton_Selector.text := "+"
        SetSystemCursor("Default")
        SetSelectedMouseGrid(MouseX, MouseY)
    } else if (ogPic_Grid.hwnd = OutputVarControlHwnd){
        ; Hide the cross and get the selected pixel
        ogText_Line1.visible := 0
        ogText_Line2.visible := 0
        ogText_Line3.visible := 0
        ogText_Line4.visible := 0
        MouseGetPos(&MouseX, &MouseY, &MouseWinHwnd, &MouseControlHwnd, 2)
        CoordMode("Mouse", ogDDL_MouseCoordMode.Text)
        CoordMode("Pixel", ogDDL_MouseCoordMode.Text)
        A_Clipboard := PixelGetColor(MouseX, MouseY)
        Tooltip2("Copied [" A_Clipboard "]")
        ogText_Line1.visible := 1
        ogText_Line2.visible := 1
        ogText_Line3.visible := 1
        ogText_Line4.visible := 1
    }
        
}

GetSelectedWindow(*){
    global MyGui
    MyGui.win_hwnd := ogLV_WinList.GetText(ogLV_WinList.GetNext(, "F"), 3)
    return MyGui.win_hwnd
}

SetSelectedWindow(win_id){
    if !WinExist(Win_id){
        UpdateWinList()
        return
    }
    ogEdit_wTitle.text := WinGetTitle(win_id)
    ogEdit_wClass.text := WinGetClass(win_id)
    ogEdit_wID.text := format("{:#x}", win_id)
    ogEdit_wProcess.text := WinGetProcessName(win_id)
    ogEdit_wProcess_ID.text := format("{:#x}",WinGetPID(win_id))
    Win_Transparent := WinGetTransparent(win_id)
    ogSlider_Transparent.value := Win_Transparent="" ? 255 : Win_Transparent
    WinGetClientPos(&win_x, &win_y, &win_w, &win_h, win_id)
    ogEdit_wXPos.value := win_x
    ogEdit_wYPos.value := win_y
    ogEdit_wWidth.value := win_w
    ogEdit_wHeight.value := win_h
}

SetSelectedControl(ctrl_id){
    if (ctrl_id=""){
        ogEdit_cText.value := ""
        ogEdit_cClass.value := ""
        ogEdit_cID.value := ""
        ogEdit_cXPos.value := ""
        ogEdit_cYPos.value := ""
        ogEdit_cWidth.value := ""
        ogEdit_cHeight.value := ""
        return
    }
    ogEdit_cText.value := ControlGetText(ctrl_id)
    ogEdit_cClass.value := ControlGetClassNN(ctrl_id)
    ogEdit_cID.value := format("{:#x}", ctrl_id)
    ControlGetPos(&cX, &cY, &cW, &cH, ctrl_id)
    ogEdit_cXPos.value := cX
    ogEdit_cYPos.value := cY
    ogEdit_cWidth.value := cW
    ogEdit_cHeight.value := cH
}

SetSelectedMouse(MouseX , MouseY) {
    CoordMode("Mouse", ogDDL_MouseCoordMode.Text)
    CoordMode("Pixel", ogDDL_MouseCoordMode.Text)
    ogEdit_mPos.value := "x" MouseX " y" MouseY
    ogEdit_mColor.value := PixelGetColor(MouseX, MouseY)
    ogText_mColor.Opt(" +Background" ogEdit_mColor.value)
    ogText_mColor.Redraw()
}

SetSelectedMouseGrid(MouseX, MouseY){
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    Grid := MyGui.Grid
    pBitmap := Gdip_BitmapFromScreen(MouseX - (Grid-1)/2 "|" MouseY -(Grid - 1) / 2 "|" Grid "|" Grid)
    hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)

    SetImage(ogPic_Grid.hwnd, hBitmap)
    Gdip_DisposeImage(pBitmap)
    ; DeleteObject(pBitmap)
    ; DeleteDC(hBitmap)
    ; Gdip_DeleteGraphics(G)
    ogText_Line1.Redraw()
    ogText_Line2.Redraw()
    ogText_Line3.Redraw()
    ogText_Line4.Redraw()
}

RClickWinList(*){
    win_hwnd := GetSelectedWindow()
    State_AlwaysOnTop := WinGetExStyle('ahk_id ' win_hwnd) & 0x8

    myMenu := Menu()
    myMenu.Add("Copy Title", (*) => (A_Clipboard:= WinGetTitle('ahk_id ' win_hwnd), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.Add("Copy Process", (*) => (A_Clipboard:= WinGetProcessName('ahk_id ' win_hwnd), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.Add("Copy ProcessPath", (*) => (A_Clipboard:= WinGetProcessPath('ahk_id ' win_hwnd), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.Add("Styles", (*) => (GuiStyles_Create(win_hwnd, "Window")))
    myMenu.Add()
    myMenu.Add("Activate", (*) => (WinActivate("ahk_id " win_hwnd), Tooltip2("WinActivate('ahk_id '" win_hwnd ")")))
    myMenu.Add("AlwaysOnTop", (*) => (WinSetAlwaysOnTop(!State_AlwaysOnTop,"ahk_id " win_hwnd), Tooltip2('WinSetAlwaysOnTop(' State_AlwaysOnTop '", ahk_id "' win_hwnd ')')))
    if (State_AlwaysOnTop){
        myMenu.Check("AlwaysOnTop")
    }
   
    myMenu.Add("Close", (*) => (WinClose("ahk_id " win_hwnd),UpdateWinList(), Tooltip2("WinClose('ahk_id '" win_hwnd ")")))
    if( WinGetStyle("ahk_id " win_hwnd) & 0x10000000){
        myMenu.Add("Visible", (*) => (WinHide("ahk_id " win_hwnd),UpdateWinList(), Tooltip2("WinHide('ahk_id '" win_hwnd ")")))
        myMenu.Check("Visible")
    } else{
        myMenu.Add("Visible", (*) => (WinShow("ahk_id " win_hwnd),UpdateWinList(), Tooltip2("WinHide('ahk_id '" win_hwnd ")")))
    }
    
    myMenu.Show()
}

GuiAddGroupboxProperty(GuiObj){
    global
    aGroupbox := Array()
    index:=0
    For Hwnd, GuiCtrlObj in MyGui { 
        if (GuiCtrlObj.Type = "GroupBox") {
            index++
            aGroupbox.Push( Object())
            aGroupbox[index].Text := GuiCtrlObj.Text
            GuiCtrlObj.GetPos(&x,&y,&w,&h)
            aGroupbox[index].x := x
            aGroupbox[index].y := y
            aGroupbox[index].x2 := x+w
            aGroupbox[index].y2 := y+h
            GuiCtrlObj.GroupBox := GuiCtrlObj.Text
            
        }
    }
    For Hwnd, GuiCtrlObj in MyGui {
        GuiCtrlObj.GetPos(&x, &y, &w, &h)
        for key, oGroupBox in aGroupbox
        {
            if (oGroupBox.x < x and oGroupBox.y < y and oGroupBox.x2 > x+w and oGroupBox.y2 > y+h){
                GuiCtrlObj.GroupBox := oGroupBox.text
                break
            }
        }
    }
    return
}

WI_GuiHideAndMove(GuiObj, GroupBox, VisibleValue := false){
    GuiHideGroupbox(GuiObj, GroupBox, VisibleValue)
    if (GroupBox="Window"){
        ogGB_Window.GetPos(&x,&y,&w,&h)
        GuiMoveGroupbox(GuiObj, "Control", 0, VisibleValue ? h : -h)
        GuiMoveGroupbox(GuiObj, "Mouse", 0, VisibleValue ? h : -h)
    } else if (GroupBox = "Control") {
        ogGB_Control.GetPos(&x, &y, &w, &h)
        GuiMoveGroupbox(GuiObj, "Mouse", 0, VisibleValue ? h : -h)
    }
    if (!oSet.WinWindow and !oSet.WinControl and !oSet.WinMouse and oSet.WinList) {
        ogGB_Window.GetPos(&x, &y, &w, &h)
        ogLV_WinList.GetPos(&xLV, &yLV)
        if (xLV>100){
            GuiMoveGroupbox(GuiObj, "List", -w)
        }
    } else if (oSet.WinWindow or oSet.WinControl or oSet.WinMouse and oSet.WinList){
        ogGB_Window.GetPos(&x, &y, &w, &h)
        ogLV_WinList.GetPos(&xLV, &yLV)
        if (xLV < 100) {
            GuiMoveGroupbox(GuiObj, "List", w)
        }
    }

    WinGetClientPos(, , &WinClientW, &WinClientH, GuiObj)
    WinGetPos(, , &WinW, &WinH, GuiObj)
    wCor := WinW - WinClientW + 2
    hCor := WinH - WinClientH + 21 + 3
    if (!oSet.WinList){ 
        if (oSet.WinMouse){
            ogGB_Mouse.GetPos(&x, &y, &w, &h)
            WinMove(, , x+w+wCor, y+h+hCor, GuiObj)
        } else if (oSet.WinControl) {
            ogGB_Control.GetPos(&x, &y, &w, &h)
            WinMove(, , x + w + wCor, y + h + hCor, GuiObj)
        } else if (oSet.WinWindow) {
            ogGB_Window.GetPos(&x, &y, &w, &h)
            WinMove(, , x + w + wCor, y + h + hCor, GuiObj)
        }
    } else if(GroupBox = "List" and oSet.WinList){
        ogLV_CtrlList.GetPos(&x, &y, &w, &h)
        WinMove(, , x + w + wCor+600, y + h + hCor, GuiObj)
    }
    WinRedraw(GuiObj)
}

GuiHideGroupbox(GuiObj,GroupBox, VisibleValue := false){
    For Hwnd, GuiCtrlObj in GuiObj {
        if (GuiCtrlObj.HasProp("GroupBox") and GuiCtrlObj.GroupBox =GroupBox){
            GuiCtrlObj.Visible := VisibleValue
        }
    }
}

GuiMoveGroupbox(GuiObj, GroupBox, xMove:=0, yMove:=0) {
    For Hwnd, GuiCtrlObj in GuiObj {
        if (GuiCtrlObj.HasProp("GroupBox") and GuiCtrlObj.GroupBox = GroupBox) {
            GuiCtrlObj.GetPos(&x, &y)
            GuiCtrlObj.Move(x+xMove, y+yMove)
        }
    }
}

RClickCtrlList(*){
    MyGui.ctrl_hwnd := ogLV_CtrlList.GetText(ogLV_CtrlList.GetNext(, "F"), 2) + 0
    ctrl_ClassNN := ControlGetClassNN(MyGui.ctrl_hwnd + 0)
    Ctrl_Visible := ControlGetVisible(MyGui.ctrl_hwnd+0)
    Ctrl_Enabled := ControlGetEnabled(MyGui.ctrl_hwnd+0)
    ObjectType := TranslateClassName(ctrl_ClassNN)
    myMenu := Menu()
    myMenu.Add("Copy Text", (*) => (A_Clipboard:= ControlGetText(MyGui.ctrl_hwnd+0), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.Add("Copy ClassNN", (*) => (A_Clipboard:= ControlGetClassNN(MyGui.ctrl_hwnd+0), Tooltip2("Copied [" A_Clipboard "]")))
    if (InStr(ctrl_ClassNN,"Listview")){
        myMenu.Add("Copy ListViewGetContent", (*) => (A_Clipboard:= ListViewGetContent(,MyGui.ctrl_hwnd+0), Tooltip2("Copied [" A_Clipboard "]")))
    }
    myMenu.Add("Styles", (*) => (GuiStyles_Create(MyGui.ctrl_hwnd, ObjectType)))
    myMenu.Add()
    myMenu.Add("SendMessage", (*) => (SendMessage( 0x0115, 0, 0, ogEdit_cClass.text, MyGui.win_hwnd )))
    myMenu.Add("ControlClick", (*) => (ControlClick(ogEdit_cClass.text, MyGui.win_hwnd), Tooltip2("ControlClick(" MyGui.win_hwnd ")")))
    myMenu.Add("ControlFocus", (*) => (ControlFocus(ogEdit_cClass.text, MyGui.win_hwnd), Tooltip2("ControlFocus(" MyGui.win_hwnd ")")))
    if (Ctrl_Visible){
        myMenu.Add("Visible", (*) => (ControlHide(MyGui.ctrl_hwnd), Tooltip2("ControlHide('ahk_id '" MyGui.ctrl_hwnd ")")))
        myMenu.Check("Visible")
    } else {
        myMenu.Add("Visible", (*) => (ControlShow(MyGui.ctrl_hwnd), Tooltip2("ControlShow('ahk_id '" MyGui.ctrl_hwnd ")")))
    }
    myMenu.Add("Enabled", (*) => (ControlSetEnabled(-1, MyGui.ctrl_hwnd), Tooltip2("ControlSetEnabled(-1,'ahk_id '" MyGui.ctrl_hwnd ")")))
    if (Ctrl_Enabled){
        myMenu.Check("Enabled")
    }
    myMenu.Show()
}

DClickCtrlList(LV, RowNumber){
    win_hwnd := MyGui.win_hwnd
    MyGui.ctrl_hwnd := ogLV_CtrlList.GetText(RowNumber,2)+0 ; convert to number
    Hwnd_selected := MyGui.ctrl_hwnd+0
    text := ControlGetText(Hwnd_selected)
    if oSet.WinHighlight {
        GuiBox := GuiRectangle()
        GuiBox.MoveToControl(Hwnd_selected, "ahk_id " win_hwnd)
        GuiBox.Opt("+Owner" win_hwnd)
        GuiBox.Show()
    }
    SetSelectedControl(Hwnd_selected)
    WinMoveTop(win_hwnd)
}

DClickWinList(p*) {
    MyGui.win_hwnd := ogLV_WinList.GetText(ogLV_WinList.GetNext(, "F"), 3) + 0
    win_hwnd := MyGui.win_hwnd+0
    if !WinExist(win_hwnd){
        GuiBox.Hide()
        return
    }
    SetSelectedWindow(win_hwnd)
    UpdateCtrlList(p)
    win_style := WinGetStyle(win_hwnd)
    if (win_style & 0x10000000 ){
        if oSet.WinHighlight {
            GuiBox := GuiRectangle()
            GuiBox.MoveToWindow(win_hwnd)
            GuiBox.Opt("+Owner" win_hwnd)
            GuiBox.Show()
        }
        WinMoveTop(win_hwnd)
        WinActivate(MyGui)
    } else{
        if IsSet(GuiBox){
            if WinExist(GuiBox){
                GuiBox.Hide()
            }
        }
    }
    
    
}

UpdateWinList(p*){
    ogLV_WinList.Delete()
    if (ogCB_FilterWinVisible.value = 0) {
        DetectHiddenWindows(true)
    } else {
        DetectHiddenWindows(false)
    }
    ogLV_WinList.Opt("-Redraw")
    oWinList := WinGetList()
    
    static ImageWinList := IL_Create(oWinList.Length)
    static mapIL := Map()
    ogLV_WinList.SetImageList(ImageWinList)
    IconIndex1 := IL_Add(ImageWinList, "shell32.dll", 3 )
    for win_id in oWinList
    {
        win_class := WinGetClass(win_id)
        win_title := WinGetTitle(win_id)
        win_process := WinGetProcessName(win_id)
        WinGetClientPos(&win_x, &win_y, &win_w, &win_h, win_id)
        
        win_visible := WinGetStyle(win_id) & 0x10000000 "" ? "Visible" : "Hidden"
        if (ogCB_FilterWinTitle.value=1 and win_title=""){
            continue
        }
        if (ogEdit_win_search.value="" or InStr(win_title " " win_process,ogEdit_win_search.value)){
            if (mapIL.Has(win_id)){
                IconIndex := mapIL[win_id]
            } else{
                WinHIcon := WinGetHIcon(win_id)
                if (WinHIcon != 0) {
                    mapIL[win_id] := IL_Add(ImageWinList, "HICON:" WinHIcon)
                } else{
                    ProcessPath := WinGetProcessPath(win_id)
                    mapIL[win_id] := IL_Add(ImageWinList, ProcessPath)
                }
            }
            
            NewRowNumber :=ogLV_WinList.Add("Icon" mapIL[win_id], win_title, win_process, format("{:#x}", win_id), win_visible, win_x, win_y, win_w, win_h)
            if(win_id = MyGui.win_hwnd){
                ogLV_WinList.Modify(NewRowNumber, "Select Vis")
            }
        }
    }
    
    ogLV_WinList.ModifyCol(5)
    ogLV_WinList.ModifyCol(6)
    ogLV_WinList.ModifyCol(7)
    ogLV_WinList.ModifyCol(8)
    ogLV_WinList.Opt("+Redraw")

}

UpdateCtrlList(*){
    
    ogLV_CtrlList.Delete()
    win_hwnd := MyGui.win_hwnd
    ogLV_CtrlList.Opt("-Redraw")
    selectedCtrl_hwnd := MyGui.ctrl_hwnd
    if WinExist("ahk_id " win_hwnd){
        for n, ctrl_hwnd in WinGetControlsHwnd("ahk_id " win_hwnd){
            if (A_Index=1){
                Hwnd_selected := ctrl_hwnd
            }
            ctrl_text := ControlGetText(ctrl_hwnd)
            ctrl_ClassNN := ControlGetClassNN(ctrl_hwnd)
            ControlGetPos(&ctrl_x, &ctrl_y, &ctrl_w, &ctrl_h, ctrl_hwnd)
            ctrl_Visible := ControlGetVisible(ctrl_hwnd)
            if ((ogCB_FilterCtrlText.value = 1 and ctrl_text = "") or (ogCB_FilterCtrlVisible.value = 1 and !ctrl_Visible)){
                 continue
            }
            if (ogEdit_ctrl_search.value="" or InStr(ctrl_ClassNN " " ctrl_hwnd " " ctrl_text,ogEdit_ctrl_search.value)){
                NewRowNumber:= ogLV_CtrlList.Add(, ctrl_ClassNN, format("{:#x}", ctrl_hwnd), ctrl_text,ctrl_x , ctrl_y, ctrl_w, ctrl_h, ctrl_Visible ? "Visible" : "Hidden")
                if (selectedCtrl_hwnd=ctrl_hwnd){
                    ogLV_CtrlList.Modify(NewRowNumber, "Select Vis")
                }
            }
        }
    }
    SetSelectedControl(isSet(Hwnd_selected) ? Hwnd_selected : "")
    ogLV_CtrlList.ModifyCol()
    ogLV_CtrlList.ModifyCol(3,200)
    ogLV_CtrlList.Opt("+Redraw")
}

GridSize_Change(*){
    mGrid := [0, 3, 5, 9, 15]
    MyGui.Grid := mGrid[ogDDL_GridSize.value]
    ogPic_Grid.Move(,,MyGui.Grid * 16, MyGui.Grid * 16)
    ogPic_Grid.GetPos(&cx,&cy,&cw,&ch)
    ogText_Line1.Move(cx+ (MyGui.Grid - 1) * 16 / 2, cy+1 ,1, MyGui.Grid * 16 - 2 )
    ogText_Line2.Move(cx+ (MyGui.Grid + 1) * 16 / 2, cy+1, 1, MyGui.Grid * 16 - 2 )
    ogText_Line3.Move(cx+1, cy+ (MyGui.Grid - 1) * 16 / 2, MyGui.Grid * 16 - 2 )
    ogText_Line4.Move(cx+1, cy+ (MyGui.Grid + 1) * 16 / 2, MyGui.Grid * 16 - 2)
    ogGB_Mouse.Move(,,,67+MyGui.Grid * 16)
}

Gui_Close(GuiObj){
    global
    GuiObj.GetPos(&X,&Y)
    GuiObj.GetClientPos(,,&W,&H)
    oSet.WinX := X
    oSet.WinY := Y
    oSet.WinW := W
    oSet.WinH := H
    oSettings.MainGui := oSet
    WriteINI(&oSettings)
    return false
}

Gui_Size(thisGui, MinMax, Width, Height) {
    if MinMax = -1	; The window has been minimized. No action needed.
        return
    DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
    For Hwnd, GuiCtrlObj in thisGui {
        if GuiCtrlObj.HasProp("LeftMargin") {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(, , Width - cX - GuiCtrlObj.LeftMargin, )
        }
        if GuiCtrlObj.HasProp("LeftDistance") {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(Width - cWidth - GuiCtrlObj.LeftDistance, , , )
        }
        if GuiCtrlObj.HasProp("BottomDistance") {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(, Height - cHeight - GuiCtrlObj.BottomDistance, , )
        }
        if GuiCtrlObj.HasProp("BottomMargin") {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(, , , Height - cY - GuiCtrlObj.BottomMargin)
        }
    }
    DllCall("LockWindowUpdate", "Uint", 0)
}

GuiStyles_Create(hwnd, ObjectType) {
    object_Style := WinGetStyle("ahk_id " hwnd)
    object_ExStyle := WinGetExStyle("ahk_id " hwnd)
    
    ObjectType := (ObjectType="Edit" and object_Style & 0x4) ? "editmultiLine" : ObjectType

    defaultStyle :=aoDefaultStyles.%ObjectType%.style
    defaultExStyle :=aoDefaultStyles.%ObjectType%.exStyle

    GuiStyles := Gui(, "Styles - " ObjectType " - " format("0x{:X}",object_Style))

    ogTab := GuiStyles.AddTab3("w400 h400",["Styles","Extended Styles"])
    ogEditStyle := GuiStyles.AddEdit("w150",format("0x{:X}", object_Style))
    ogLVStyles := GuiStyles.Add("ListView", " h332 w375 Checked", ["Style", "Hex", "Default","Description"])
    ogTab.UseTab("Extended Styles")
    ogEditExStyle := GuiStyles.AddEdit("w150", format("0x{:X}", object_ExStyle))
    ogLVExStyles := GuiStyles.Add("ListView", "h332 w375 Checked", ["Style", "Hex", "Default", "Description"])
    ogTab.UseTab()
    ogEditOptions := GuiStyles.AddEdit("xm y410 w300")
    Options := ""

    aoStyles := (ObjectType = "window") ? aoWinStyles : aoControlStyles

    ; general style
    for index, oStyle in aoStyles{
        ogLVStyles.Add(((object_Style & oStyle.Hex) ? "Check" : ""),oStyle.Style,oStyle.Hex,(defaultStyle & oStyle.Hex) ? "true" : "false", oStyle.Description)
        Options .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " ((defaultStyle & oStyle.Hex) ? "-" : "+") (oStyle.OptionText="" ? oStyle.Hex : oStyle.OptionText) 
    }

    aoStyles_extra := ""
    aoStyles_extra := (ObjectType = "text") ? aoTextStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Edit") ? aoEditStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "EditMultiline") ? aoEditMultilineStyles : aoStyles_extra
    aoStyles_extra := (ObjectType ~= "Button|CheckBox|Radio|GroupBox") ? aoButtonStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "text") ? aoTextStyles : aoStyles_extra

    ; object specific styles
    if (aoStyles_extra!=""){
        for index, oStyle in aoStyles_extra{
            ogLVStyles.Add(((object_Style & oStyle.Hex)? "Check" : ""),oStyle.Style,oStyle.Hex,(defaultStyle & oStyle.Hex) ? "true" : "false",oStyle.Description)
            Options .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " ((defaultStyle & oStyle.Hex) ? "-" : "+") (oStyle.OptionText="" ? oStyle.Hex : oStyle.OptionText) 
        }
    }
    
    for index, oExStyle in aoWinExStyles{
        ogLVExStyles.Add(((object_ExStyle & oExStyle.Hex)? "Check" : ""),oExStyle.Style,oExStyle.Hex, (defaultExStyle & oExStyle.Hex) ? "true" : "false",oExStyle.Description)
        ; if (((oExStyle.SkipHex!="") and (object_ExStyle & oExStyle.SkipHex)) or oExStyle.Skip){
        ;     continue ; skip this option
        ; }
        ;Options .= (((!oExStyle.DefaultValue && (win_ExStyle & oExStyle.Hex)) || (oExStyle.DefaultValue && !(win_ExStyle & oExStyle.Hex))) ? ( " " (oExStyle.DefaultValue ? "-" : "+") (oExStyle.OptionText="" ? "E" oExStyle.Hex : oExStyle.OptionText)) : "")
        Options .= (((defaultExStyle & oExStyle.Hex) && (object_ExStyle & oExStyle.Hex)) | (!(defaultExStyle & oExStyle.Hex) && !(object_ExStyle & oExStyle.Hex))) ? "" : " " ((defaultExStyle & oExStyle.Hex) ? "-E" : "+E") (oExStyle.OptionText="" ? oExStyle.Hex : oExStyle.OptionText) 
    }
   
    ogEditOptions.Value := Options
    ogLVStyles.ModifyCol
    ogLVStyles.ModifyCol(2, "Integer")
    ogLVExStyles.ModifyCol
    ogLVExStyles.ModifyCol(2, "Integer")
    GuiStyles.Show("")

    Return

}

GuiRectangle(x:= 0, y:= 0 ,w:= 100 ,h:=100 , Color:="Blue",Thickness := 2){
    Static GuiBox := "" 
    if IsObject(GuiBox){
        GuiBox.Destroy()
    }
    GuiBox := Gui(" +ToolWindow -Caption +AlwaysOnTop +E0x20", "Background Test")
    GuiBox.x := x
    GuiBox.y := y
    GuiBox.w := w
    GuiBox.h := h
    GuiBox.Thickness := Thickness

    if (Thickness <0){
        Thickness:= -Thickness
        x := x-Thickness
        y := y-Thickness
        w := w+Thickness*2
        h := h+Thickness*2
    }
    GuiBox.MarginX := 0
    GuiBox.MarginY := 0
    goColor := GuiBox.AddText("w" w " h" h " Background" Color)
    goTransp := GuiBox.AddText("x" Thickness " y" Thickness " w" w-Thickness*2 " h" h-Thickness*2 " BackgroundEEAA99")
    WinSetTransColor("EEAA99", GuiBox)
    
    GuiBox.SetColor := SetColor
    GuiBox.SetThickness := SetThickness
    GuiBox.MovePos := MovePos
    GuiBox.MoveToControl := MoveToControl
    GuiBox.MoveToWindow := MoveToWindow
    GuiBox.Show("Hide x" x " y" y)
    
    return GuiBox

    ; Set the color
    SetColor(GuiBox, Color := "Blue"){
        goColor.Opt(" +Background" Color)
        goColor.Redraw()
    }

    ; Set the Thickness (simple function)
    SetThickness(GuiBox, Thickness := 1){
        MovePos(GuiBox, , , , , Thickness)
    }

    ; Change the position of the gui without destroying it
    MovePos(GuiBox, x:="", y:="", w:="", h:="",Thickness:=""){
        x := x=""? GuiBox.x : x
        y := y=""? GuiBox.y : y
        w := w=""? GuiBox.w : w
        h := h=""? GuiBox.h : h
        Thickness:= Thickness=""? GuiBox.Thickness : Thickness

        GuiBox.x := x
        GuiBox.y := y
        GuiBox.w := w
        GuiBox.h := h
        GuiBox.Thickness := Thickness

        if (Thickness < 0) {
            Thickness := -Thickness
            x := x - Thickness
            y := y - Thickness
            w := w + Thickness * 2
            h := h + Thickness * 2
        }
        GuiBox.Move(x, y, w, h)
        goColor.Move(,,w,h)
        goTransp.Move(Thickness, Thickness, w-Thickness*2, h-Thickness*2)
        goColor.Redraw()
        goTransp.Redraw()
        
    }

    ; Set the rectangle arround a control
    MoveToControl(GuiBox,Control,Wintitle){
        Try{
            ControlGetPos(&X, &Y, &W, &H, Control, WinTitle)
            WinGetClientPos(&winX, &winY,,, WinTitle)
            MovePos(GuiBox, winX+x, winY+y, w, h)
        } Catch{
            GuiBox.Hide()
        }
    }

    ; Set the rectangle arround a control
    MoveToWindow(GuiBox,Wintitle){
        try{
            WinGetClientPos(&winX, &winY, &winW, &winH, WinTitle)
            if (winY=-8){
                winX:=winX+8
                winY:=winY+8
                winW:=winW-8*2
                winH:=winH-8*2

            }
            MovePos(GuiBox, winX, winY, winW, winH) ; Strangly, WinGetPos returned slightly offset values
        } Catch {
            GuiBox.Hide()
        }
    }
}

WinGetHIcon(Wintitle){
    ICON_BIG := 1

    try {
        IconHwnd := SendMessage(WM_GETICON := 0x007F, ICON_SMALL := 0, 96, , Wintitle)
    }
    Catch{
        ; IconHwnd := DllCall("GetClassLongPtr", "Ptr", Wintitle, "Int", GCLP_HICONSM := -34)
        IconHwnd := DllCall("GetClassLongPtr", "Ptr", Wintitle, "Int", GCLP_HICON := -14)
    }

    return IconHwnd
}

Tooltip2(Text:="" , X:= "", Y:= "", WhichToolTip:= ""){
    ToolTip(Text, X, Y, WhichToolTip)
    SetTimer () => ToolTip(), -3000
}

GetButtonType(hwndButton){
    static types := ["Button"	;BS_PUSHBUTTON
        , "Button"	;BS_DEFPUSHBUTTON
        , "Checkbox"	;BS_CHECKBOX
        , "Checkbox"	;BS_AUTOCHECKBOX
        , "Radio"	;BS_RADIOBUTTON
        , "Checkbox"	;BS_3STATE
        , "Checkbox"	;BS_AUTO3STATE
        , "Groupbox"	;BS_GROUPBOX
        , "NotUsed"	;BS_USERBUTTON
        , "Radio"	;BS_AUTORADIOBUTTON
        , "Button"	;BS_PUSHBOX
        , "AppSpecific"	;BS_OWNERDRAW
        , "SplitButton"	;BS_SPLITBUTTON    (vista+)
        , "SplitButton"	;BS_DEFSPLITBUTTON (vista+)
        , "CommandLink"	;BS_COMMANDLINK    (vista+)
        , "CommandLink"]	;BS_DEFCOMMANDLINK (vista+)

    btnStyle := WinGetStyle("ahk_id " hwndButton)
    return types[1 + (btnStyle & 0xF)]
}

WM_MOUSEMOVE(wParam, lParam, Msg, Hwnd) {
    static PrevHwnd := 0
    currControl := GuiCtrlFromHwnd(Hwnd)

    ; Setting the tooltips for controls with a property tooltip
    if (Hwnd != PrevHwnd) {
        Text := "", ToolTip()	; Turn off any previous tooltip.
        if CurrControl {
            if CurrControl.HasProp("ToolTip"){
                CheckHoverControl := () => hwnd != prevHwnd ? (SetTimer(DisplayToolTip, 0), SetTimer(CheckHoverControl, 0)) : ""
                DisplayToolTip := () => (ToolTip(CurrControl.ToolTip), SetTimer(CheckHoverControl, 0))
                SetTimer(CheckHoverControl, 50)	; Checks if hovered control is still the same
                SetTimer(DisplayToolTip, -500)
            }
            StatusbarText := CurrControl.HasProp("StatusBar") ? CurrControl.StatusBar : ""
            SB.SetText(StatusbarText, 1)
        }

        PrevHwnd := Hwnd
    }
    return
}

;-------------------------------------------------------------------------------
WriteINI(&Array2D, INI_File :="") {	; write 2D-array to INI-file
    ;-------------------------------------------------------------------------------
    INI_File := INI_File="" ? Regexreplace(A_scriptName,"(.*)\..*","$1.ini") : INI_File
    for SectionName, Entry in Array2D.OwnProps() {
        Pairs := ""

        for Key, Value in Entry.OwnProps()
            Pairs .= Key "=" Value "`n"
        IniWrite(Pairs, INI_File, SectionName)
    }
}

;-------------------------------------------------------------------------------
ReadINI(INI_File:="", oResult := "") {	; return 2D-array from INI-file
    INI_File := INI_File = "" ? Regexreplace(A_scriptName, "(.*)\..*", "$1.ini") : INI_File
    oResult := IsObject(oResult) ? oResult : Object()
    if !FileExist(INI_File) {
        return oResult
    }
    oResult.Section := Object()
    SectionNames := IniRead(INI_File)
    for each, Section in StrSplit(SectionNames, "`n") {
        OutputVar_Section := IniRead(INI_File, Section)
        if !oResult.HasOwnProp(Section){
            oResult.%Section% := Object()
        }
        for each, Haystack in StrSplit(OutputVar_Section, "`n"){
            RegExMatch(Haystack, "(.*?)=(.*)", &match)
            ArrayProperty := match[1]
            oResult.%Section%.%ArrayProperty% := match[2]
        }
    }
    return oResult
}

TranslateClassName(ClassName) {
    AhkName := ""
    If (InStr(ClassName, "static")) {
        AhkName := "Text"
    } Else If (InStr(ClassName, "button")) {
        AhkName := "Button"
    } Else If (InStr(ClassName, "edit")) {
        AhkName := "Edit"
    } Else If (InStr(ClassName, "checkbox")) {
        AhkName := "CheckBox"
    } Else If (InStr(ClassName, "group")) {
        AhkName := "GroupBox"
    } Else If (InStr(ClassName, "radio")) {
        AhkName := "Radio"
    } Else If (InStr(ClassName, "combobox")) {
        AhkName := "ComboBox"
    } Else If (InStr(ClassName, "listview")) {
        AhkName := "ListView"
    } Else If (InStr(ClassName, "listbox")) {
        AhkName := "ListBox"
    } Else If (InStr(ClassName, "tree")) {
        AhkName := "TreeView"
    } Else If (InStr(ClassName, "status")) {
        AhkName := "StatusBar"
    } Else If (InStr(ClassName, "tab")) {
        AhkName := "Tab3"
    } Else If (InStr(ClassName, "updown")) {
        AhkName := "UpDown"
    } Else If (InStr(ClassName, "hotkey")) {
        AhkName := "Hotkey"
    } Else If (InStr(ClassName, "progress")) {
        AhkName := "Progress"
    } Else If (InStr(ClassName, "trackbar")) {
        AhkName := "Slider"
    } Else If (InStr(ClassName, "datetime")) {
        AhkName := "DateTime"
    } Else If (InStr(ClassName, "month")) {
        AhkName := "MonthCal"
    } Else If (InStr(ClassName, "link")) {
        AhkName := "Link"
    } Else If (InStr(ClassName, "richedit")) {
        AhkName := "Edit"
    } Else If (InStr(ClassName, "scintilla")) {
        AhkName := "Edit"
    } Else If (InStr(ClassName, "memo")) {
        AhkName := "Edit"
    } Else If (InStr(ClassName, "btn")) {
        AhkName := "Button"
    }
    Return AhkName
}