; Made by Ahk_user
; Based on AHK window info, but in V2 and with more features
; 2022-07-12 Added ChildGuis to handle different view options, included Function section to quickly run functions

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
    WinList:1,
    SectWindow: true,
    SectControl: true,
    SectMouse: true,
    SectFunction: true,
    SectWinList: true,
    SectControlList: true,
    ControlPar: "ClassNN",
    WindowPar: "Title",
    MouseGrid: 1
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
aoWinStyles.Push(Styles("WS_POPUP", "0x80000000","Creates a pop-up window. This style cannot be used with the WS_CHILD style."))
aoWinStyles.Push(Styles("WS_CAPTION", "0xC00000","+/-Caption. Creates a window that has a title bar. This style is a numerical combination of WS_BORDER and WS_DLGFRAME.", "Caption","-Border -0x400000 +E0x10000 -E0x100")) 
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
aoWinStyles.Push(Styles("WS_SIZEBOX", "0x40000", "+/-Resize. Creates a window that has a sizing border. Same as the WS_THICKFRAME style.","Resize","+MaximizeBox +E0x10000"))
aoWinStyles.Push(Styles("WS_SYSMENU", "0x80000", "+/-SysMenu. Creates a window that has a window menu on its title bar. The WS_CAPTION style must also be specified.","SysMenu"," +E0x10000"))
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
aoWinExStyles.Push(Styles("WS_EX_TOOLWINDOW", "0x80", 'The window is intended to be used as a floating toolbar. A tool window has a title bar that is shorter than a normal title bar, and the window title is drawn using a smaller font. A tool window does not appear in the taskbar or in the dialog that appears when the user presses ALT+TAB. If a tool window has a system menu, its icon is not displayed on the title bar. However, you can display the system menu by right-clicking or by typing ALT+SPACE.',"ToolWindow","+E0x10000"))
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
aoDefaultStyles.progress := {style:0x50000000, exStyle:0x0}
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
ogButton_Selector := MyGui.addButton("xm y0 w60 vbtnSelector BackgroundTrans h24 w24 +0x4000", "+")
ogButton_Selector.SetFont("s20", "Times New Roman")
ogButton_Selector.statusbar := "Rclick and drag to select a specific control or window"

ChildOpt := "+Parent" myGui.hwnd " -Resize +AlwaysOnTop -Border -Caption -ToolWindow"
; ChildOpt := "+Parent" myGui.hwnd " +Resize +AlwaysOnTop -Border -Caption +ToolWindow" ; Borders visible for testing

; Child guis or sections
oGui2 := Gui(, "Window")
oGui3 := Gui(, "Control")
oGui4 := Gui(, "Mouse")
oGui5 := Gui(, "Function")
oGui6 := Gui(, "WinList")
oGui7 := Gui(, "ControlList")

myGui.aSections := [oGui2, oGui3, oGui4, oGui5, oGui6, oGui7]

for index, oSection in myGui.aSections {
    ; Adding a visible property to the guis
    oSection.DefineProp("Visible", { Get: ((oSection, *) => ((WinGetStyle(oSection) & 0x10000000) != 0)).bind(oSection), set: ((oSection, this, value) => (value ? oSection.Show() : oSection.Hide())).bind(oSection) })
    ; Apply section options
    oSection.Opt(ChildOpt)
    oSection.OnEvent("Size", GuiSection_Size)
    oSection.MarginX := 2
    oSection.MarginY := 2
}

; Window Section

ogGB_Window := oGui2.AddGroupBox("w300 h145 Section", "Window")
ogGB_Window.LeftMargin := 2
ogGB_Window.BottomMargin := 2
oGui2.AddText("xp+3 yp+18", "Title")
ogEdit_wTitle := oGui2.AddEdit("x42 yp-3 w255", "")
ogEdit_wTitle.StatusBar := "WinGetTitle(WinTitle, WinText, ExcludeTitle, ExcludeText)"
oGui2.AddText("x6 yp+26", "Class")
ogEdit_wClass := oGui2.AddEdit("x42 yp-3 w178 vwClass +ReadOnly")
ogEdit_wClass.StatusBar := "WinGetClass(WinTitle, WinText, ExcludeTitle, ExcludeText)"
oGui2.AddText("x+4 yp+3", "ID")
ogEdit_wID := oGui2.AddEdit("x237 yp-3 Right vwID w60 +ReadOnly")
ogEdit_wID.StatusBar := "WinGetID(WinTitle, WinText, ExcludeTitle, ExcludeText)"
oGui2.AddText("x4 yp+26", "Process")
ogEdit_wProcess := oGui2.AddEdit("x42 yp-3 w135 vwProcess +ReadOnly")
oGui2.AddText("x+3 yp+3", "Process_ID")
ogEdit_wProcess_ID := oGui2.AddEdit("x237 yp-3 w60 Right vwProcess_ID +ReadOnly")

oGui2.AddText("x30 yp+26", "X")
ogEdit_wXPos := oGui2.AddEdit("x42 yp-3 Right Number vwXPos w40")
oGui2.AddText("x+5 yp+3", "Y")
ogEdit_wYPos := oGui2.AddEdit("x+2 yp-3 Right Number vwYPos w40")
ogEdit_wYPos.StatusBar := "Y position of window"
oGui2.AddText("x+5 yp+3", "W")
ogEdit_wWidth := oGui2.AddEdit("x+2 yp-3 Right Number vwWPos w40")
oGui2.AddText("x+5 yp+3", "H")
ogEdit_wHeight := oGui2.AddEdit("x+2 yp-3 Right Number vwHPos w40")
ogButton_Move := oGui2.AddButton("x258 yp-1 w40", "Move")
ogButton_Move.OnEvent("Click", (*) => (WinExist("ahk_id " ogEdit_wID.value) ? WinMove(ogEdit_wXPos.value, ogEdit_wYPos.value, ogEdit_wWidth.value, ogEdit_wHeight.value, "ahk_id " ogEdit_wID.value) : ""))
oGui2.AddText("x8 y+4", "Transparent:")
ogSlider_Transparent := oGui2.AddSlider("xp+60 vTransparent  Range0-255 ToolTip", "255")
ogSlider_Transparent.OnEvent("Change", (*) => (WinExist("ahk_id " ogEdit_wID.value) ? WinSetTransparent(ogSlider_Transparent.value, "ahk_id " ogEdit_wID.value) : ""))

; Control Section

oGui3.posRef := oGui2
oGui3.posRule := "Xx Yyh Ww"
ogGB_Control := oGui3.AddGroupBox("xm w300 h88", "Control")
ogGB_Control.LeftMargin := 2
ogGB_Control.BottomMargin := 2
oGui3.AddText("xp+3 yp+18", "Text")
ogEdit_cText := oGui3.AddEdit("x42 yp-3 w255", "")
ogEdit_cText.StatusBar := "ControlGetText(Control, WinTitle, WinText, ExcludeTitle, ExcludeText)"
oGui3.AddText("x6 yp+26", "Class")
ogEdit_cClass := oGui3.AddEdit("x42 yp-3 w178 vccClass +ReadOnly")
ogEdit_cClass.StatusBar := "ControlGetClassNN(Control , WinTitle, WinText, ExcludeTitle, ExcludeText)"
oGui3.AddText("x+4 yp+3", "ID")
ogEdit_cID := oGui3.AddEdit("x237 yp-3 w60 Right vcID +ReadOnly")
ogEdit_cID.StatusBar := "ControlGetHwnd(Control, WinTitle, WinText, ExcludeTitle, ExcludeText)"

oGui3.AddText("x30 yp+26", "X")
ogEdit_cXPos := oGui3.AddEdit("x42 yp-3 Right Number vcXPos w40")
oGui3.AddText("x+5 yp+3", "Y")
ogEdit_cYPos := oGui3.AddEdit("x+2 yp-3 Right Number vcYPos w40")
oGui3.AddText("x+5 yp+3", "W")
ogEdit_cWidth := oGui3.AddEdit("x+2 yp-3 Right Number vcWPos w40")
oGui3.AddText("x+5 yp+3", "H")
ogEdit_cHeight := oGui3.AddEdit("x+2 yp-3 Right Number vcHPos w40")
ogButton_cMove := oGui3.AddButton("x258 yp-1 w40", "Move")
ogButton_cMove.OnEvent("Click", (*) => (ControlMove(ogEdit_cXPos.value, ogEdit_cYPos.value, ogEdit_cWidth.value, ogEdit_cHeight.value, ogEdit_cID.value + 0)))

; Mouse Section

oGui4.posRef := oGui3
oGui4.posRule := "Xx Yyh Ww"
ogGB_Mouse := ogGB_Mouse := oGui4.AddGroupBox("xm w300", "Mouse")
ogGB_Mouse.LeftMargin := 2
ogGB_Mouse.BottomMargin := 2
oGui4.AddText("xp+3 yp+18", "Pos")
ogEdit_mPos := oGui4.AddEdit("x42 yp-3 w70", "")
ogDDL_MouseCoordMode := oGui4.AddDropDownList("x+3 yp w70 vDDL_MouseCoordMode Choose1", ["Screen", "Window", "Client"])
ogBut_MouseMove := oGui4.AddButton("x+3 yp w50", "Move")
ogBut_MouseMove.OnEvent("Click", (*) => (CoordMode("Mouse", ogDDL_MouseCoordMode.Text), MouseMove(oGui4.MouseX+0,oGui4.MouseY+0)))
ogBut_MouseClick := oGui4.AddButton("x+3 yp w50", "Click")
ogBut_MouseClick.OnEvent("Click", (*) => (CoordMode("Mouse", ogDDL_MouseCoordMode.Text), Mouseclick(,oGui4.MouseX+0,oGui4.MouseY+0)))
oGui4.AddText("x6 yp+26", "RGB")
ogEdit_mColor := oGui4.AddEdit("x42 yp-3 w70", "")
ogText_mColor := oGui4.AddText("x+3 yp w21 h21 BackgroundWhite +Border")

ogDDL_GridSize := oGui4.AddDropDownList("x+3 yp w60 vDDL_GridSize" , ["1x1", "3x3","5x5", "9x9", "15x15"])

ogDDL_GridSize.text := oSet.MouseGrid "x" oSet.MouseGrid
ogDDL_GridSize.OnEvent("Change", GridSize_Change)
oGui4.Grid := oSet.MouseGrid

ogPic_Grid := oGui4.AddPicture("x42 y+2 w" oGui4.Grid*16 " h" oGui4.Grid*16 " +0x40 +0xE +Border Section")
ogText_Line1 := oGui4.AddText("xs+" (oGui4.Grid-1) * 16/2 " ys+1 w1 h" oGui4.Grid * 16-2 " backgroundWhite")
ogText_Line2 := oGui4.AddText("xs+" (oGui4.Grid+1) * 16/2 " ys+1 w1 h" oGui4.Grid * 16-2 " backgroundWhite")
ogText_Line3 := oGui4.AddText("xs+1 ys+" (oGui4.Grid - 1) * 16 / 2 " w" oGui4.Grid * 16-2 " h1 backgroundWhite")
ogText_Line4 := oGui4.AddText("xs+1 ys+" (oGui4.Grid + 1) * 16 / 2 " w" oGui4.Grid * 16-2 " h1 backgroundWhite")
GridSize_Change()


; Function Section

oGui5.posRef := oGui4
oGui5.posRule := "Xx Yyh Ww"
ogGBFunction := oGui5.addGroupBox(,"Function")
ogGBFunction.LeftMargin := 2
ogGBFunction.BottomMargin := 2

moFunctions := Map()
moFunctions["SendMessage"] := {var1:"Msg", var1Default: "", var2: "wParam", var2Default: "0", var3: "lParam", var3Default: "0", result:true, description:"Sends a message to a window or control and waits for acknowledgement."}
moFunctions["PostMessage"] := {var1:"Msg", var1Default: "", var2: "wParam", var2Default: "0", var3: "lParam", var3Default: "0", result:true, description:"Places a message in the message queue of a window or control."}
moFunctions["ControlAddItem"] := {var1:"String", var1Default: "", description:"Adds the specified string as a new entry at the bottom of a ListBox or ComboBox."}
moFunctions["ControlClick"] := {description:"Sends a mouse button or mouse wheel event to a control."}
moFunctions["ControlFocus"] := {description:"Sets input focus to a given control on a window."}
moFunctions["ControlSetText"] := {var1:"NewText", var1Default: "", description:"Changes the text of a control."}
moFunctions["ControlSend"] := {var1:"Keys", var1Default: "", description:"Sends simulated keystrokes to a window or control."}
moFunctions["ControlSendText"] := {var1:"Keys", var1Default: "", description: "Sends text to a window or control."}

aFunctionList := Array()
For Key, Value in moFunctions{
    aFunctionList.Push(Key)
}
DDLFunction := oGui5.Add("DropDownList", "x60 yp+18 Choose1", aFunctionList)
DDLFunction.OnEvent("Change", UpdateControls)
BtnRun := oGui5.Add("Button", "x+10 yp-1 w60", "Run")
BtnRun.OnEvent("Click",ClickRun)
BtnCopy := oGui5.Add("Button", "x+10 yp w20", "Copy")
BtnCopy.OnEvent("Click",ClickCopy)

ogTxtVar1 := oGui5.Add("Text", "xm w50", "Msg:")
ogEdtVar1 := oGui5.Add("Edit", "x60 yp-3 w200 right", "")
ogTxtVar2 := oGui5.Add("Text", "xm y+6 w50", "wParam:")
ogEdtVar2 := oGui5.Add("Edit", "x60 yp-3 w60 right", 0)
ogTxtVar3 := oGui5.Add("Text", "x140 yp+3 w50", "lParam:")
ogEdtVar3 := oGui5.Add("Edit", "yp-3 xp+60 w60 right", 0)
oGui5.Add("Text", "xm y+6 ", "Control:")
ogEdtControl := oGui5.Add("Edit", "yp-3 x60 w200 right", )

oGui5.Add("Text", "xm y+6 ", "Window:")
oWinIDs := WinGetList()

ogEdtWindow := oGui5.Add("Edit", "yp-3 x60 w200 right", "")

; ogEdtWindow.text := Window

ogGbResult := oGui5.Add("GroupBox", "xm+3 w294 r2 Section", "Result")
ogEdtResult := oGui5.Add("Edit", "xs+10 ys+18 w280", "")

ogGbMsgList := oGui5.Add("GroupBox", "xm+3 w294 h258 Section", "MsgList")
ogEdtSearch := oGui5.Add("Edit", "xs+10 ys+18", "")
ogEdtSearch.OnEvent("Change",UpdateLVMessages)
ogLvMessages := oGui5.Add("ListView", "w280 r10", ["Message","Value"])
UpdateLVMessages()
ogLvMessages.OnEvent("Click", DClickMsgList)

; WinList Section

oGui6.posRef := oGui2
oGui6.posRule := "Xxw Yy"
ogGBWinList := oGui6.addGroupBox("h311","WinList")
ogGBWinList.LeftMargin := 2
ogGBWinList.BottomMargin := 2
oGui6.LeftDistance := 0
oGui6.HeigthMultiplier := 0.5

xList := 310
ogText_WinSearch := oGui6.AddText("xp+3  yp+18", "WinSearch:") ; "xp+3 yp+18"
ogText_WinSearch.GroupBox := "List"
ogEdit_win_search := oGui6.AddEdit("yp-3 x+10 w200 vwin_seach")
ogEdit_win_search.statusbar := "Type to filter the windows on specific words"
ogEdit_win_search.OnEvent("Change",UpdateWinList)
ogEdit_win_search.GroupBox := "List"
ogCB_FilterWinVisible := oGui6.AddCheckbox("xp+210 yp+3 vfilter_win_visible Checked", "Visible") 
ogCB_FilterWinVisible.OnEvent("Click",UpdateWinList)
ogCB_FilterWinVisible.GroupBox := "List"
ogCB_FilterWinVisible.Statusbar := "Filter on only visible windows"
ogCB_FilterWinTitle := oGui6.AddCheckbox("xp+60 yp vfilter_win_title Checked", "Title") 
ogCB_FilterWinTitle.OnEvent("Click", UpdateWinList)
ogCB_FilterWinTitle.GroupBox := "List"
ogCB_FilterWinTitle.Statusbar := "Filter on windows with a title"

ogLV_WinList := oGui6.AddListView("xm+5 y+8 r14 w" (myGui.Width - 8 * 3) / 2 " vWinList section AltSubmit", ["Title", "Process", "ID", "Visible", "X", "Y", "W", "H"])
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
ogLV_WinList.BottomMargin := 8

; ControlList Section

oGui7.posRef := oGui6
oGui7.posRule := "Xx Yyh Ww"
oGui7.LeftDistance := 0
oGui7.BottomDistance := 0
ogGBControlList := oGui7.addGroupBox(, "ControlList")
ogGBControlList.LeftMargin := 2
ogGBControlList.BottomMargin := 23

ogText_CtrlSearch := oGui7.AddText("xp+3 yp+18", "ControlSearch:")
ogText_CtrlSearch.GroupBox := "List"
ogEdit_ctrl_search := oGui7.AddEdit("yp-3 x+10 w200 vctrl_search")
ogEdit_ctrl_search.OnEvent("Change", UpdateCtrlList)
ogEdit_ctrl_search.statusbar := "Type to filter the controls on specific words"
ogEdit_ctrl_search.GroupBox := "List"
ogCB_FilterCtrlVisible := oGui7.AddCheckbox("xp+210 yp+3 vfilter_ctrl_visible", "Visible")
ogCB_FilterCtrlVisible.OnEvent("Click", UpdateCtrlList)
ogCB_FilterCtrlVisible.GroupBox := "List"
ogCB_FilterCtrlVisible.Statusbar := "Filter on only visible controls"

ogCB_FilterCtrlText := oGui7.AddCheckbox("xp+60 yp vfilter_ctrl_text", "Text visible") 
ogCB_FilterCtrlText.OnEvent("Click", UpdateCtrlList)
ogCB_FilterCtrlText.GroupBox := "List"
ogCB_FilterCtrlText.statusbar := "Filter on controls with text"
ogLV_CtrlList := oGui7.AddListView("xm+5 y+8 r15 w" (myGui.Width-8*3)/2 " vCtrlList section AltSubmit", ["Class(NN)", "Hwnd", "Text", "X", "Y", "W", "H","Visible"])
ogLV_CtrlList.Opt("Count100 -Multi")
ogLV_CtrlList.OnEvent("Click", DClickCtrlList)
ogLV_CtrlList.OnNotify(NM_RCLICK := -5, RClickCtrlList)
ogLV_CtrlList.LeftMargin := 3
ogLV_CtrlList.BottomMargin := 28
ogLV_CtrlList.GroupBox := "List"

; Menu definitions

SettingsMenu := Menu()
SettingsMenu.Add("Resize", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinResize:= !oSet.WinResize, oSet.WinResize ? myGui.Opt("+Resize") :  myGui.Opt("-Resize")))
oSet.WinResize=1 ? SettingsMenu.Check("Resize") : ""
SettingsMenu.Add("AlwaysOnTop", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinAlwaysOnTop:= !oSet.WinAlwaysOnTop, oSet.WinAlwaysOnTop ? myGui.Opt("+AlwaysOnTop") :  myGui.Opt("-AlwaysOnTop")))
oSet.WinAlwaysOnTop=1 ? SettingsMenu.Check("AlwaysOnTop") : ""
SettingsMenu.Add()
SettingsMenu.Add("Highlight", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinHighlight:= !oSet.WinHighlight))
oSet.WinHighlight=1 ? SettingsMenu.Check("Highlight") : ""
SettingsMenu.Add()
ControlMenu := Menu()
ControlMenu.Add("ClassNN", (ItemName, ItemPos, ItemMenu) => (ItemMenu.Check(ItemName),ItemMenu.UnCheck("hwnd"), ItemMenu.UnCheck("Text"), oSet.ControlPar := "ClassNN"))
ControlMenu.Add("hwnd", (ItemName, ItemPos, ItemMenu) => (ItemMenu.Check(ItemName), ItemMenu.UnCheck("ClassNN"), ItemMenu.UnCheck("Text"), oSet.ControlPar := "hwnd"))
ControlMenu.Add("Text", (ItemName, ItemPos, ItemMenu) => (ItemMenu.Check(ItemName), ItemMenu.UnCheck("hwnd"), ItemMenu.UnCheck("ClassNN"), oSet.ControlPar := "Text"))
(oSet.ControlPar = "ClassNN") ? ControlMenu.Check("ClassNN") : ""
(oSet.ControlPar = "hwnd") ? ControlMenu.Check("hwnd") : ""
(oSet.ControlPar = "Text") ? ControlMenu.Check("Text") : ""
SettingsMenu.Add("Control", ControlMenu)

WindowMenu := Menu()
WindowMenu.Add("Class", (ItemName, ItemPos, ItemMenu) => (ItemMenu.Check(ItemName),ItemMenu.UnCheck("hwnd"), ItemMenu.UnCheck("Title"), ItemMenu.UnCheck("Process"), oSet.WindowPar := "Class"))
WindowMenu.Add("hwnd", (ItemName, ItemPos, ItemMenu) => (ItemMenu.Check(ItemName), ItemMenu.UnCheck("Class"), ItemMenu.UnCheck("Title"), ItemMenu.UnCheck("Process"), oSet.WindowPar := "hwnd"))
WindowMenu.Add("Title", (ItemName, ItemPos, ItemMenu) => (ItemMenu.Check(ItemName), ItemMenu.UnCheck("hwnd"), ItemMenu.UnCheck("Class"), ItemMenu.UnCheck("Process"), oSet.WindowPar := "Title"))
WindowMenu.Add("Process", (ItemName, ItemPos, ItemMenu) => (ItemMenu.Check(ItemName), ItemMenu.UnCheck("hwnd"), ItemMenu.UnCheck("Class"), ItemMenu.UnCheck("Title"), oSet.WindowPar := "Process"))
(oSet.WindowPar = "Class") ? WindowMenu.Check("Class") : ""
(oSet.WindowPar = "hwnd") ? WindowMenu.Check("hwnd") : ""
(oSet.WindowPar = "Title") ? WindowMenu.Check("Title") : ""
(oSet.WindowPar = "Process") ? WindowMenu.Check("Process") : ""
SettingsMenu.Add("Window", WindowMenu)

; Define the menus
ViewMenu := Menu()
for oSection in myGui.aSections{
    SectionTitle := oSection.Title
    ViewMenu.Add(SectionTitle, ((oSection, SectionTitle, ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.Sect%SectionTitle% := !oSet.Sect%SectionTitle%, oSection.Visible := oSet.Sect%SectionTitle%, SectionCorrections(SectionTitle) GuiUpdate())).Bind(oSection, SectionTitle))
    (oSet.Sect%SectionTitle% = true && ViewMenu.Check(SectionTitle))
}

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

for index, oSection in myGui.aSections {
    SectionTitle := oSection.Title
    ; Show the sections
    oSection.Show("x0 y24")
    (oSet.Sect%SectionTitle% = 0 && oSection.Visible := 0)
}

UpdateWinList()

MyGui.Show("x" oSet.WinX " y" oSet.WinY " w" oSet.WinW " h" oSet.WinH)

GuiUpdate()

; Reset Cursor in case previous script gave error
SetSystemCursor("Default")
OnMessage(WM_LBUTTONDOWN := 0x0201, CheckButtonClick)
OnMessage(0x200, WM_MOUSEMOVE)


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
        
        UpdateWinList()
        UpdateCtrlList()
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
    
    ogEdtWindow.text := (oSet.WindowPar = "Class") ? WinGetClass(win_id) : (oSet.WindowPar = "hwnd") ? win_id : (oSet.WindowPar = "Process") ? "ahk_exe " WinGetProcessName(win_id) : WinGetTitle(win_id)
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
    
    ogEdtControl.text := (oSet.ControlPar = "text" && ControlGetText(ctrl_id)!="") ? ControlGetText(ctrl_id) : (oSet.ControlPar = "hwnd") ? ctrl_id : ControlGetClassNN(ctrl_id)
}

SetSelectedMouse(MouseX, MouseY) {
    CoordMode("Mouse", ogDDL_MouseCoordMode.Text)
    CoordMode("Pixel", ogDDL_MouseCoordMode.Text)
    ogEdit_mPos.value := "x" MouseX " y" MouseY
    ogEdit_mColor.value := PixelGetColor(MouseX, MouseY)
    ogText_mColor.Opt(" +Background" ogEdit_mColor.value)
    ogText_mColor.Redraw()
}

SetSelectedMouseGrid(MouseX, MouseY){
    global oSet
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    Grid := oGui4.Grid
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
    oGui4.Show("AutoSize")
    GuiUpdate()
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
        (IsSet(GuiBox) && WinExist(GuiBox) && GuiBox.Hide())
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
        (IsSet(GuiBox) && WinExist(GuiBox) && GuiBox.Hide())
    }
      
}

SectionCorrections(Section){
    myGui.GetPos(&xWin,&yWin,&wWin,&hWin)
    if (Section~="WinList|ControlList"){
        if (oSet.SectWinList && oSet.SectControlList){
            WinGetClientPos(&XcmyGui, &YcmyGui, &WcmyGui, &HcmyGui, myGui)
            oGui6.move(,,,HcmyGui/2)
            oGui6.HeigthMultiplier := 0.5
            oGui6.BottomDistance := ""
        } else if (oSet.SectWinList && !oSet.SectControlList){
            WinGetClientPos(&XcmyGui, &YcmyGui, &WcmyGui, &HcmyGui, myGui)
            oGui6.move(,,,HcmyGui)
            oGui6.HeigthMultiplier := ""
            oGui6.BottomDistance := 23
        }
        if((oSet.SectWinList | oSet.SectControlList) and wWin <700){
            MyGui.move(,,700)
        }
    }
    if (!oSet.SectWinList && !oSet.SectControlList){
        MyGui.move(,,320)
    }

    GuiUpdate()
    Gui_Size(myGui)
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
    ;SetSelectedControl(isSet(Hwnd_selected) ? Hwnd_selected : "")
    ogLV_CtrlList.ModifyCol()
    ogLV_CtrlList.ModifyCol(3,200)
    ogLV_CtrlList.Opt("+Redraw")
}

GridSize_Change(*){
    mGrid := [0, 3, 5, 9, 15]
    oGui4.Grid := mGrid[ogDDL_GridSize.value]
    oSet.MouseGrid := (oGui4.Grid=0) ? 1 : oGui4.Grid
    ogPic_Grid.Move(,,oGui4.Grid * 16, oGui4.Grid * 16)
    ogPic_Grid.GetPos(&cx,&cy,&cw,&ch)
    ogText_Line1.Move(cx+ (oGui4.Grid - 1) * 16 / 2, cy+1 ,1, oGui4.Grid * 16 - 2 )
    ogText_Line2.Move(cx+ (oGui4.Grid + 1) * 16 / 2, cy+1, 1, oGui4.Grid * 16 - 2 )
    ogText_Line3.Move(cx+1, cy+ (oGui4.Grid - 1) * 16 / 2, oGui4.Grid * 16 - 2 )
    ogText_Line4.Move(cx+1, cy+ (oGui4.Grid + 1) * 16 / 2, oGui4.Grid * 16 - 2)
    ogGB_Mouse.Move(,,,67+oGui4.Grid * 16)
    oGui4.Show("AutoSize")
    GuiUpdate()
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

; Updates the visibility and position of the sections of the gui
GuiUpdate(*){
    WinGetPos(&XmyGui, &YmyGui, &WmyGui, &HmyGui, myGui)
    WinGetClientPos(&XcmyGui, &YcmyGui, &WcmyGui, &HcmyGui, myGui)
    wMax := 0
    hMax := 0
    For Hwnd, ogSection in myGui.aSections
    {
        ogSection.replacement := ""
        if (ogSection.HasProp("posRef")){
            posRule := ogSection.posRule
            GuiRef := ogSection.posRef
            loop{
                if GuiRef.Visible{
                    WinGetPos(&X2, &Y2, &W2, &H2, GuiRef)
                    break
                } else if(GuiRef.HasProp("replacement")){
                    if (GuiRef.replacement = ""){
                        WinGetPos(&X2, &Y2, &W2, &H2, GuiRef)
                        posRule := "Xx Yy"
                        GuiRef.Replacement := ogSection
                        break
                    }
                    GuiRef := GuiRef.replacement
                } else if(GuiRef.HasProp("posRef")){
                    posRule := GuiRef.posRule
                    GuiRef := GuiRef.posRef
                } else {
                    WinGetPos(&X2, &Y2, &W2, &H2, GuiRef)
                    posRule := "Xx Yy"
                    GuiRef.Replacement := ogSection
                    break
                }
            }

            if (posRule = "Xx Yyh Ww"){
                ogSection.move(X2 - XcmyGui, H2 + Y2 - YcmyGui,W2)
            } else if (posRule = "Xxw Yy"){
                ogSection.move(X2 - XcmyGui+W2, Y2 - YcmyGui)
            } else if (posRule = "Xx Yy"){
                ogSection.move(X2 - XcmyGui, Y2 - YcmyGui)
            }
            
        }
        if (ogSection.Visible){
            WinGetClientPos(&x, &y, &w, &h, ogSection)
            wMax := Max(wMax,x+w-XcmyGui)
            hMax := Max(hMax,y+h-YcmyGui)
        }
    }
}

; Automatically change size of controls based on properties
GuiSection_Size(thisGui, MinMax, Width, Height) {
    if MinMax = -1	; The window has been minimized. No action needed.
        return
    ;DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
    ; SendMessage(0xB, false,,thisGui.Hwnd)
    For Hwnd, GuiCtrlObj in thisGui {
        if (GuiCtrlObj.HasProp("LeftMargin") && GuiCtrlObj.LeftMargin!="") {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(, , Width - cX - GuiCtrlObj.LeftMargin, )
        }
        if (GuiCtrlObj.HasProp("LeftDistance") && GuiCtrlObj.LeftDistance!="") {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(Width - cWidth - GuiCtrlObj.LeftDistance, , , )
        }
        if (GuiCtrlObj.HasProp("BottomDistance") && GuiCtrlObj.BottomDistance!="") {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(, Height - cHeight - GuiCtrlObj.BottomDistance, , )
        }
        if (GuiCtrlObj.HasProp("BottomMargin") && GuiCtrlObj.BottomMargin!="") {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(, , , Height - cY - GuiCtrlObj.BottomMargin)
        }
    }
    ;DllCall("LockWindowUpdate", "Uint", 0)
    ; SendMessage(0xB, true,,thisGui.Hwnd)
    ;WinRedraw(thisGui)
}

; Automatically change Sections
Gui_Size(thisGui, MinMax:=1, Width:= 1, Height:= 1) {
    if MinMax = -1	; The window has been minimized. No action needed.
        return
    DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)

    ;oGui6.BottomDistance := oGui7.Visible ? 23 : ""

    WinGetPos(&XmyGui, &YmyGui, &WmyGui, &HmyGui, myGui)
    WinGetClientPos(&XcmyGui, &YcmyGui, &WcmyGui, &HcmyGui, myGui)
    For Hwnd, ogSection in myGui.aSections{
        WinGetPos(&XSection, &YSection, &WSection, &HSection, ogSection)
        WinGetClientPos(&XcSection, &YcSection, &WcSection, &HcSection, ogSection)
        if (ogSection.HasProp("LeftDistance") && ogSection.LeftDistance!=""){
            ogSection.move(XSection - XcmyGui, YSection - YcmyGui,(XcmyGui+WcmyGui)-XSection-ogSection.LeftDistance)
        }
        if (ogSection.HasProp("BottomDistance") && ogSection.BottomDistance != ""){
            ogSection.move(XSection - XcmyGui, YSection - YcmyGui,,(YcmyGui+HcmyGui)-YSection-ogSection.LeftDistance )
        }
        if (ogSection.HasProp("HeigthMultiplier") && ogSection.HeigthMultiplier != ""){
            ogSection.move(XSection - XcmyGui, YSection - YcmyGui,,HcmyGui*ogSection.HeigthMultiplier)
        }
    }
    ;WinRedraw(thisGui)
    DllCall("LockWindowUpdate", "Uint", 0)
    GuiUpdate()
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
    SkipOptions := "" ;Styles to be skipped because of set options
    aoStyles := (ObjectType = "window") ? aoWinStyles : aoControlStyles

    ; general style
    for index, oStyle in aoStyles{
        ogLVStyles.Add(((object_Style & oStyle.Hex) ? "Check" : ""),oStyle.Style,oStyle.Hex,(defaultStyle & oStyle.Hex) ? "true" : "false", oStyle.Description)
        Options .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " ((defaultStyle & oStyle.Hex) ? "-" : "+") (oStyle.OptionText="" ? oStyle.Hex : oStyle.OptionText) 
        SkipOptions .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " (oStyle.SkipHex)
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
            SkipOptions .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " (oStyle.SkipHex)
        }
    }
    
    for index, oExStyle in aoWinExStyles{
        ogLVExStyles.Add(((object_ExStyle & oExStyle.Hex)? "Check" : ""),oExStyle.Style,oExStyle.Hex, (defaultExStyle & oExStyle.Hex) ? "true" : "false",oExStyle.Description)
        Options .= (((defaultExStyle & oExStyle.Hex) && (object_ExStyle & oExStyle.Hex)) | (!(defaultExStyle & oExStyle.Hex) && !(object_ExStyle & oExStyle.Hex))) ? "" : " " ((defaultExStyle & oExStyle.Hex) ? "-" : "+") (oExStyle.OptionText="" ? "E" oExStyle.Hex : oExStyle.OptionText) 
        SkipOptions .= (((defaultExStyle & oExStyle.Hex) && (object_ExStyle & oExStyle.Hex)) | (!(defaultStyle & oExStyle.Hex) && !(object_ExStyle & oExStyle.Hex))) ? "" : " " (oExStyle.SkipHex)
    }

    optionsBuffer := ""
    Loop parse, Options, A_space{
        if !InStr(" " SkipOptions " ", " " A_LoopField " ",){
            optionsBuffer .= A_LoopField " "
        }
    }
    ogEditOptions.Value := optionsBuffer
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


; Tester functions
{
    DClickMsgList(LV, RowNumber) {
        ogEdtVar1.text := ogLvMessages.GetText(RowNumber, 2)	; convert to number
    }

    ClickRun(*){
        SelFunction := DDLFunction.text
        oFunct := moFunctions[SelFunction]
        ToolTip("[" ogEdtControl.text "]")
        if (!oFunct.HasProp("var1")){
            ogEdtResult.text := %SelFunction%(ogEdtControl.text, ogEdtWindow.text)
        } else if (!oFunct.HasProp("var2")){
            ogEdtResult.text := %SelFunction%(ogEdtVar1.text, ogEdtControl.text, ogEdtWindow.text)
        }else if (!oFunct.HasProp("var3")){
            ogEdtResult.text := %SelFunction%(ogEdtVar1.text, ogEdtVar2.text, ogEdtControl.text, ogEdtWindow.text)
        } else{
            if (InStr(SelFunction,"Message") and type(ogEdtVar3.text)="String" and !IsNumber(ogEdtVar3.text)){
                ogEdtResult.text := %SelFunction%(ogEdtVar1.text, ogEdtVar2.text, StrPtr(ogEdtVar3.text), ogEdtControl.text, ogEdtWindow.text)
            }else{
                ogEdtResult.text := %SelFunction%(ogEdtVar1.text, ogEdtVar2.text, ogEdtVar3.text, ogEdtControl.text, ogEdtWindow.text)
            }
            
        }
        
    }
    ClickCopy(*){
        SelFunction := DDLFunction.text
        oFunct := moFunctions[SelFunction]
        
        Clipboard := (oFunct.HasProp("result") && oFunct.result) ? "Result := " : ""
        if (!oFunct.HasProp("var1")){
            Clipboard .= SelFunction '("' ogEdtControl.text '", "' ogEdtWindow.text '")'
        } else if (!oFunct.HasProp("var2")){
            Clipboard .= SelFunction '("' ogEdtVar1.text '", "' ogEdtControl.text '", "' ogEdtWindow.text '")'
        }else if (!oFunct.HasProp("var3")){
            Clipboard .= SelFunction '("' ogEdtVar1.text '", "' ogEdtVar2.text '", "' ogEdtControl.text '", "' ogEdtWindow.text '")'
        } else{
             if (InStr(SelFunction,"Message") and type(ogEdtVar3.text)="String" and !IsNumber(ogEdtVar3.text)){
                Clipboard .= SelFunction '("' ogEdtVar1.text '", "' ogEdtVar2.text '", StrPtr("' ogEdtVar3.text '"), "' ogEdtControl.text '", "' ogEdtWindow.text '")'
            }else{
                Clipboard .= SelFunction '("' ogEdtVar1.text '", "' ogEdtVar2.text '", "' ogEdtVar3.text '", "' ogEdtControl.text '", "' ogEdtWindow.text '")'
            }
        }
        Clipboard := StrReplace(Clipboard, ', "")',')')
        Clipboard := StrReplace(Clipboard, ', "")',')')
        Clipboard := StrReplace(Clipboard, ', "")',')')
        Clipboard := StrReplace(Clipboard, '"")', ')')

        A_Clipboard := Clipboard
        ToolTip "copied to clipboard:`n" Clipboard
        SetTimer () => ToolTip(), -5000
    }

    UpdateLVMessages(*){
        msgList := "
    (
    WM_NULL	0x0000	
    WM_CREATE	0x0001	
    WM_DESTROY	0x0002	
    WM_MOVE	0x0003	
    WM_SIZE	0x0005	
    WM_ACTIVATE	0x0006	
    WM_SETFOCUS	0x0007	
    WM_KILLFOCUS	0x0008	
    WM_ENABLE	0x000A	
    WM_SETREDRAW	0x000B	
    WM_SETTEXT	0x000C	
    WM_GETTEXT	0x000D	
    WM_GETTEXTLENGTH	0x000E	
    WM_PAINT	0x000F	
    WM_CLOSE	0x0010	
    WM_QUERYENDSESSION	0x0011	
    WM_QUERYOPEN	0x0013	
    WM_ENDSESSION	0x0016	
    WM_QUIT	0x0012	
    WM_ERASEBKGND	0x0014	
    WM_SYSCOLORCHANGE	0x0015	
    WM_SHOWWINDOW	0x0018	
    WM_WININICHANGE	0x001A	
    WM_SETTINGCHANGE	WM_WININICHANGE	
    WM_DEVMODECHANGE	0x001B	
    WM_ACTIVATEAPP	0x001C	
    WM_FONTCHANGE	0x001D	
    WM_TIMECHANGE	0x001E	
    WM_CANCELMODE	0x001F	
    WM_SETCURSOR	0x0020	
    WM_MOUSEACTIVATE	0x0021	
    WM_CHILDACTIVATE	0x0022	
    WM_QUEUESYNC	0x0023	
    WM_GETMINMAXINFO	0x0024	
    WM_PAINTICON	0x0026	
    WM_ICONERASEBKGND	0x0027	
    WM_NEXTDLGCTL	0x0028	
    WM_SPOOLERSTATUS	0x002A	
    WM_DRAWITEM	0x002B	
    WM_MEASUREITEM	0x002C	
    WM_DELETEITEM	0x002D	
    WM_VKEYTOITEM	0x002E	
    WM_CHARTOITEM	0x002F	
    WM_SETFONT	0x0030	
    WM_GETFONT	0x0031	
    WM_SETHOTKEY	0x0032	
    WM_GETHOTKEY	0x0033	
    WM_QUERYDRAGICON	0x0037	
    WM_COMPAREITEM	0x0039	
    WM_GETOBJECT	0x003D	
    WM_COMPACTING	0x0041	
    WM_COMMNOTIFY	0x0044	
    WM_WINDOWPOSCHANGING	0x0046	
    WM_WINDOWPOSCHANGED	0x0047	
    WM_POWER	0x0048	
    WM_COPYDATA	0x004A	
    WM_CANCELJOURNAL	0x004B	
    WM_NOTIFY	0x004E	
    WM_INPUTLANGCHANGEREQUEST	0x0050	
    WM_INPUTLANGCHANGE	0x0051	
    WM_TCARD	0x0052	
    WM_HELP	0x0053	
    WM_USERCHANGED	0x0054	
    WM_NOTIFYFORMAT	0x0055	
    WM_CONTEXTMENU	0x007B	
    WM_STYLECHANGING	0x007C	
    WM_STYLECHANGED	0x007D	
    WM_DISPLAYCHANGE	0x007E	
    WM_GETICON	0x007F	
    WM_SETICON	0x0080	
    WM_NCCREATE	0x0081	
    WM_NCDESTROY	0x0082	
    WM_NCCALCSIZE	0x0083	
    WM_NCHITTEST	0x0084	
    WM_NCPAINT	0x0085	
    WM_NCACTIVATE	0x0086	
    WM_GETDLGCODE	0x0087	
    WM_SYNCPAINT	0x0088	
    WM_NCMOUSEMOVE	0x00A0	
    WM_NCLBUTTONDOWN	0x00A1	
    WM_NCLBUTTONUP	0x00A2	
    WM_NCLBUTTONDBLCLK	0x00A3	
    WM_NCRBUTTONDOWN	0x00A4	
    WM_NCRBUTTONUP	0x00A5	
    WM_NCRBUTTONDBLCLK	0x00A6	
    WM_NCMBUTTONDOWN	0x00A7	
    WM_NCMBUTTONUP	0x00A8	
    WM_NCMBUTTONDBLCLK	0x00A9	
    WM_NCXBUTTONDOWN	0x00AB	
    WM_NCXBUTTONUP	0x00AC	
    WM_NCXBUTTONDBLCLK	0x00AD	
    WM_INPUT_DEVICE_CHANGE	0x00FE	
    WM_INPUT	0x00FF	
    WM_KEYFIRST	0x0100	
    WM_KEYDOWN	0x0100	
    WM_KEYUP	0x0101	
    WM_CHAR	0x0102	
    WM_DEADCHAR	0x0103	
    WM_SYSKEYDOWN	0x0104	
    WM_SYSKEYUP	0x0105	
    WM_SYSCHAR	0x0106	
    WM_SYSDEADCHAR	0x0107	
    WM_UNICHAR	0x0109	
    WM_KEYLAST	0x0109	
    WM_KEYLAST	0x0108	
    WM_IME_STARTCOMPOSITION	0x010D	
    WM_IME_ENDCOMPOSITION	0x010E	
    WM_IME_COMPOSITION	0x010F	
    WM_IME_KEYLAST	0x010F	
    WM_INITDIALOG	0x0110	
    WM_COMMAND	0x0111	
    WM_SYSCOMMAND	0x0112	
    WM_TIMER	0x0113	
    WM_HSCROLL	0x0114	
    WM_VSCROLL	0x0115	
    WM_INITMENU	0x0116	
    WM_INITMENUPOPUP	0x0117	
    WM_GESTURE	0x0119	
    WM_GESTURENOTIFY	0x011A	
    WM_MENUSELECT	0x011F	
    WM_MENUCHAR	0x0120	
    WM_ENTERIDLE	0x0121	
    WM_MENURBUTTONUP	0x0122	
    WM_MENUDRAG	0x0123	
    WM_MENUGETOBJECT	0x0124	
    WM_UNINITMENUPOPUP	0x0125	
    WM_MENUCOMMAND	0x0126	
    WM_CHANGEUISTATE	0x0127	
    WM_UPDATEUISTATE	0x0128	
    WM_QUERYUISTATE	0x0129	
    WM_CTLCOLORMSGBOX	0x0132	
    WM_CTLCOLOREDIT	0x0133	
    WM_CTLCOLORLISTBOX	0x0134	
    WM_CTLCOLORBTN	0x0135	
    WM_CTLCOLORDLG	0x0136	
    WM_CTLCOLORSCROLLBAR	0x0137	
    WM_CTLCOLORSTATIC	0x0138	
    WM_MOUSEFIRST	0x0200	
    WM_MOUSEMOVE	0x0200	
    WM_LBUTTONDOWN	0x0201	
    WM_LBUTTONUP	0x0202	
    WM_LBUTTONDBLCLK	0x0203	
    WM_RBUTTONDOWN	0x0204	
    WM_RBUTTONUP	0x0205	
    WM_RBUTTONDBLCLK	0x0206	
    WM_MBUTTONDOWN	0x0207	
    WM_MBUTTONUP	0x0208	
    WM_MBUTTONDBLCLK	0x0209	
    WM_MOUSEWHEEL	0x020A	
    WM_XBUTTONDOWN	0x020B	
    WM_XBUTTONUP	0x020C	
    WM_XBUTTONDBLCLK	0x020D	
    WM_MOUSEHWHEEL	0x020E	
    WM_MOUSELAST	0x020E	
    WM_MOUSELAST	0x020D	
    WM_MOUSELAST	0x020A	
    WM_MOUSELAST	0x0209	
    WM_PARENTNOTIFY	0x0210	
    WM_ENTERMENULOOP	0x0211	
    WM_EXITMENULOOP	0x0212	
    WM_NEXTMENU	0x0213	
    WM_SIZING	0x0214	
    WM_CAPTURECHANGED	0x0215	
    WM_MOVING	0x0216	
    WM_POWERBROADCAST	0x0218	
    WM_DEVICECHANGE	0x0219	
    WM_MDICREATE	0x0220	
    WM_MDIDESTROY	0x0221	
    WM_MDIACTIVATE	0x0222	
    WM_MDIRESTORE	0x0223	
    WM_MDINEXT	0x0224	
    WM_MDIMAXIMIZE	0x0225	
    WM_MDITILE	0x0226	
    WM_MDICASCADE	0x0227	
    WM_MDIICONARRANGE	0x0228	
    WM_MDIGETACTIVE	0x0229	
    WM_MDISETMENU	0x0230	
    WM_ENTERSIZEMOVE	0x0231	
    WM_EXITSIZEMOVE	0x0232	
    WM_DROPFILES	0x0233	
    WM_MDIREFRESHMENU	0x0234	
    WM_POINTERDEVICECHANGE	0x238	
    WM_POINTERDEVICEINRANGE	0x239	
    WM_POINTERDEVICEOUTOFRANGE	0x23A	
    WM_TOUCH	0x0240	
    WM_NCPOINTERUPDATE	0x0241	
    WM_NCPOINTERDOWN	0x0242	
    WM_NCPOINTERUP	0x0243	
    WM_POINTERUPDATE	0x0245	
    WM_POINTERDOWN	0x0246	
    WM_POINTERUP	0x0247	
    WM_POINTERENTER	0x0249	
    WM_POINTERLEAVE	0x024A	
    WM_POINTERACTIVATE	0x024B	
    WM_POINTERCAPTURECHANGED	0x024C	
    WM_TOUCHHITTESTING	0x024D	
    WM_POINTERWHEEL	0x024E	
    WM_POINTERHWHEEL	0x024F	
    WM_IME_SETCONTEXT	0x0281	
    WM_IME_NOTIFY	0x0282	
    WM_IME_CONTROL	0x0283	
    WM_IME_COMPOSITIONFULL	0x0284	
    WM_IME_SELECT	0x0285	
    WM_IME_CHAR	0x0286	
    WM_IME_REQUEST	0x0288	
    WM_IME_KEYDOWN	0x0290	
    WM_IME_KEYUP	0x0291	
    WM_MOUSEHOVER	0x02A1	
    WM_MOUSELEAVE	0x02A3	
    WM_NCMOUSEHOVER	0x02A0	
    WM_NCMOUSELEAVE	0x02A2	
    WM_WTSSESSION_CHANGE	0x02B1	
    WM_TABLET_FIRST	0x02c0	
    WM_TABLET_LAST	0x02df	
    WM_CUT	0x0300	
    WM_COPY	0x0301	
    WM_PASTE	0x0302	
    WM_CLEAR	0x0303	
    WM_UNDO	0x0304	
    WM_RENDERFORMAT	0x0305	
    WM_RENDERALLFORMATS	0x0306	
    WM_DESTROYCLIPBOARD	0x0307	
    WM_DRAWCLIPBOARD	0x0308	
    WM_PAINTCLIPBOARD	0x0309	
    WM_VSCROLLCLIPBOARD	0x030A	
    WM_SIZECLIPBOARD	0x030B	
    WM_ASKCBFORMATNAME	0x030C	
    WM_CHANGECBCHAIN	0x030D	
    WM_HSCROLLCLIPBOARD	0x030E	
    WM_QUERYNEWPALETTE	0x030F	
    WM_PALETTEISCHANGING	0x0310	
    WM_PALETTECHANGED	0x0311	
    WM_HOTKEY	0x0312	
    WM_PRINT	0x0317	
    WM_PRINTCLIENT	0x0318	
    WM_APPCOMMAND	0x0319	
    WM_THEMECHANGED	0x031A	
    WM_CLIPBOARDUPDATE	0x031D	
    WM_DWMCOMPOSITIONCHANGED	0x031E	
    WM_DWMNCRENDERINGCHANGED	0x031F	
    WM_DWMCOLORIZATIONCOLORCHANGED	0x0320	
    WM_DWMWINDOWMAXIMIZEDCHANGE	0x0321	
    WM_DWMSENDICONICTHUMBNAIL	0x0323	
    WM_DWMSENDICONICLIVEPREVIEWBITMAP	0x0326	
    WM_GETTITLEBARINFOEX	0x033F	
    WM_HANDHELDFIRST	0x0358	
    WM_HANDHELDLAST	0x035F	
    WM_AFXFIRST	0x0360	
    WM_AFXLAST	0x037F	
    WM_PENWINFIRST	0x0380	
    WM_PENWINLAST	0x038F	
    WM_APP	0x8000	
    WM_USER	0x0400
    )"
        ogLvMessages.Delete()
        ogLvMessages.Opt("-Redraw")
    
        loop parse msgList, "`n", "`r"
        {
            if (ogEdtSearch.text="" || InStr(A_LoopField,ogEdtSearch.text)){
                ogLvMessages.Add(, StrSplit(A_LoopField, "`t") * )
            }
        }
        ogLvMessages.ModifyCol(1, 150)
        ogLvMessages.ModifyCol(2, 50)
            
        ;SetSelectedControl(isSet(Hwnd_selected) ? Hwnd_selected : "")

        ogLvMessages.Opt("+Redraw")
    }

    UpdateControls(*){
        SelFunction := DDLFunction.text
       
        oFunct := moFunctions[SelFunction]
        ogTxtVar1.Visible := oFunct.HasProp("var1")
        ogEdtVar1.Visible := oFunct.HasProp("var1")
        if (oFunct.HasProp("var1")){
            ogTxtVar1.text := oFunct.var1 ":"
            ogEdtVar1.Value := oFunct.HasProp("var1Default") ? oFunct.var1Default : ""
        }
        ogTxtVar2.Visible := oFunct.HasProp("var2")
        ogEdtVar2.Visible := oFunct.HasProp("var2")
        if (oFunct.HasProp("var2")){
            ogTxtVar2.text := oFunct.var2 ":"
            ogEdtVar2.Value := oFunct.HasProp("var2Default") ? oFunct.var2Default : ""
        }
        ogTxtVar3.Visible := oFunct.HasProp("var3")
        ogEdtVar3.Visible := oFunct.HasProp("var3")
        if (oFunct.HasProp("var3")){
            ogTxtVar3.text := oFunct.var3 ":"
            ogEdtVar3.Value := oFunct.HasProp("var3Default") ? oFunct.var3Default : ""
        }
        ogGbResult.Visible := (oFunct.HasProp("result") && oFunct.result)
        ogEdtResult.Visible := (oFunct.HasProp("result") && oFunct.result)

        ogGbMsgList.Visible := oFunct.HasProp("var1") && oFunct.var1 = "msg"
        ogEdtSearch.Visible := oFunct.HasProp("var1") && oFunct.var1 = "msg"
        ogLvMessages.Visible := oFunct.HasProp("var1") && oFunct.var1 = "msg"

        ; Autosize Groupbox
        yMax := 0
        ogGBFunction.GetPos(&xGB,&yGB,&wGB,&hGB)
        for index, oControl in oGui5{
            if !oControl.visible{
                continue
            }
            if (ogGBFunction.hwnd=oControl.hwnd){
                continue
            }
            ClassNN := ControlGetClassNN(oControl)
            oControl.GetPos(&xC,&yC,&wC,&hC)
            yMax := Max(yMax,yC+hC)
        }
        
        WinGetPos(&xWin,&yWin,&wWin,&hWin, ogGBFunction.Gui)
        
        ControlMove(, , , yMax-yGB+5,ogGBFunction)
        oGui5.Show("Autosize")
        Gui_Size(myGui)
    }

}
