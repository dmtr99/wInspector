; Made by Ahk_user
; Based on AHK window info, but in V2 and with more features
; 2022-07-12 Added ChildGuis to handle different view options, included Function section to quickly run functions
; 2022-07-15 Added more functions and improved the function commands
; 2023-01-03 Added PID filtering

#Requires AutoHotKey v2.0-
#SingleInstance Force
#DllLoad "Gdiplus.dll"
#Include lib\SetSystemCursor.ahk
#Include lib\Gdip_All.ahk
#Include lib\_GuiCtlExt.ahk
#Include lib\ObjectGui.ah2
#Include lib\Toolbar.ah2


DetectHiddenWindows true
SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

; Set the tray icon
TraySetIcon("imageres.dll",145)

A_TrayMenu.Add()  ; Creates a separator line.
A_TrayMenu.Add("Inspect", Gui_wInspector)  ; Creates a new menu item.
A_TrayMenu.Default := "Inspect"

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
    SectWindow: true,
    SectControl: true,
    SectAcc: true,
    SectMouse: true,
    SectFunction: true,
    SectWindowList: true,
    SectControlList: true,
    SectProcessList: true,
    ControlPar: "ClassNN",
    WindowPar: "Title",
    MouseGrid: 1,
    Function: "ControlClick",
    IDHex: true
}

global IconLib := "Images.icl"
global GuiBox
Global oImageControls := {
    ActiveX: -33,
    Button: -9,
    CheckBox: -10,
    ComboBox: -11,
    DateTime: -12,
    DropDownList: -13,
    Edit: -14,
    GroupBox: -15,
    Hotkey: -16,
    Link: -17,
    ListBox:  -18,
    ListView:  -19,
    MonthCal:  -21,
    Picture: -22,
    Progress: -23,
    Radio: -24,
    Separator: -25,
    Slider: -26,
    StatusBar:27,
    Tab3: -28,
    Text: -29,
    ToolBar: -30,
    TreeView: -31,
    UpDown: -32,
    Custom: -34,
    CommandLink: -35,
    MenuBar: -35,
    ScrollBar: -32
}
index := 1
for property, value in oImageControls.OwnProps(){
    index++
}

ImageCtrlList := IL_Create(index+1)
mILControls := Map()
IconIndex1 := IL_Add(ImageCtrlList, "shell32.dll", 50) ; add empty image
index := 1
for property, value in oImageControls.OwnProps(){
    index++
    mILControls[Property] := IL_Add(ImageCtrlList, "Images.icl", value)
}
    
; Styles data
{
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
    aoControlStyles.Push(Styles("WS_BORDER", "0x800000","+/-Border. Creates a window that has a thin-line border.", "Border","0xC00000"))
    aoControlStyles.Push(Styles("WS_DISABLED", "0x8000000", "+/-Disabled. Creates a window that is initially disabled.", "Disabled"))
    aoControlStyles.Push(Styles("WS_TABSTOP", "0x10000", "+/-Tabstop. Specifies a control that can receive the keyboard focus when the user presses Tab. Pressing Tab changes the keyboard focus to the next control with the WS_TABSTOP style.","Tabstop"))
    aoControlStyles.Push(Styles("WS_GROUP", "0x20000", '+/-Group. Indicates that this control is the first one in a group of controls. This style is automatically applied to manage the " only one at a time " behavior of radio buttons. In the rare case where two groups of radio buttons are added consecutively (with no other control types in between them), this style may be applied manually to the first control of the second radio group, which splits it off from the first.', "Group"))
    aoControlStyles.Push(Styles("WS_THICKFRAME", "0x40000", "Creates a window that has a sizing border. Same as the WS_SIZEBOX style.",,"0x40000",true))
    aoControlStyles.Push(Styles("WS_VSCROLL", "0x200000", "Creates a window that has a vertical scroll bar.","VScroll"))
    aoControlStyles.Push(Styles("WS_HSCROLL", "0x100000", "Creates a window that has a horizontal scroll bar.","HScroll"))

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
    aoWinExStyles.Push(Styles("WS_EX_TOPMOST", "0x8", 'The window should be placed above all non-topmost windows and should stay above them, even when the window is deactivated. To add or remove this style, use the SetWindowPos function.',"AlwaysOnTop"))
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

    global aoUpDownStyles := Array()
    aoUpDownStyles.Push(Styles("UDS_WRAP", "0x1",'Named option "Wrap". Causes the control to wrap around to the other end of its range when the user attempts to go beyond the minimum or maximum. Without Wrap, the control stops when the minimum or maximum is reached.',"Wrap"))
    aoUpDownStyles.Push(Styles("UDS_SETBUDDYINT", "0x2",'Causes the UpDown control to set the text of the buddy control (using the WM_SETTEXT message) when the position changes. However, if the buddy is a ListBox, the ListBox`'s current selection is changed instead.',""))
    aoUpDownStyles.Push(Styles("UDS_ALIGNRIGHT", "0x4",'Named option "Right" (default). Positions UpDown on the right side of its buddy control.',"Right"))
    aoUpDownStyles.Push(Styles("UDS_ALIGNLEFT", "0x8",'Named option "Left". Positions UpDown on the left side of its buddy control.',"Left"))
    aoUpDownStyles.Push(Styles("UDS_AUTOBUDDY", "0x10",'Automatically selects the previous control in the z-order as the UpDown control`'s buddy control.',""))
    aoUpDownStyles.Push(Styles("UDS_ARROWKEYS", "0x20",'Allows the user to press ↑ or ↓ on the keyboard to increase or decrease the UpDown control`'s position.',""))
    aoUpDownStyles.Push(Styles("UDS_HORZ", "0x40",'Named option "Horz". Causes the control`'s arrows to point left and right instead of up and down.',"Horz"))
    aoUpDownStyles.Push(Styles("UDS_NOTHOUSANDS", "0x80",'Does not insert a thousands separator between every three decimal digits in the buddy control.',""))
    aoUpDownStyles.Push(Styles("UDS_HOTTRACK", "0x100",'Causes the control to exhibit "hot tracking" behavior. That is, it highlights the control`'s buttons as the mouse passes over them. This flag may be ignored if the desktop theme overrides it.',""))

    global aoPicStyles := Array()
    aoPicStyles.Push(Styles("SS_REALSIZECONTROL", "0x40",'Adjusts the bitmap to fit the size of the control.',""))
    aoPicStyles.Push(Styles("SS_CENTERIMAGE", "0x200",'Centers the bitmap in the control. If the bitmap is too large, it will be clipped. For text controls, if the control contains a single line of text, the text is centered vertically within the available height of the control.',""))
    aoPicStyles.Push(Styles("SS_BLACKFRAME", "0x7",'Specifies a box with a frame drawn in the same color as the window frames. This color is black in the default color scheme.'))
    aoPicStyles.Push(Styles("SS_BLACKRECT", "0x4",'Specifies a rectangle filled with the current window frame color. This color is black in the default color scheme.'))
    aoPicStyles.Push(Styles("SS_CENTER", "0x1",'+/-Center. Specifies a simple rectangle and centers the text in the rectangle. The control automatically wraps words that extend past the end of a line to the beginning of the next centered line.', 'Center'))
    aoPicStyles.Push(Styles("SS_ETCHEDFRAME", "0x12",'Draws the frame of the static control using the EDGE_ETCHED edge style.'))
    aoPicStyles.Push(Styles("SS_ETCHEDHORZ", "0x10",'Draws the top and bottom edges of the static control using the EDGE_ETCHED edge style.'))
    aoPicStyles.Push(Styles("SS_ETCHEDVERT", "0x11",'Draws the left and right edges of the static control using the EDGE_ETCHED edge style.'))
    aoPicStyles.Push(Styles("SS_GRAYFRAME", "0x8",'Specifies a box with a frame drawn with the same color as the screen background (desktop). This color is gray in the default color scheme.'))
    aoPicStyles.Push(Styles("SS_GRAYRECT", "0x5",'Specifies a rectangle filled with the current screen background color. This color is gray in the default color scheme.'))
    aoPicStyles.Push(Styles("SS_LEFT", "0x0",'+/-Left. This is the default. It specifies a simple rectangle and left-aligns the text in the rectangle. The text is formatted before it is displayed. Words that extend past the end of a line are automatically wrapped to the beginning of the next left-aligned line. Words that are longer than the width of the control are truncated.', 'Left'))
    aoPicStyles.Push(Styles("SS_LEFTNOWORDWRAP", "0xC",'+/-Wrap. Specifies a rectangle and left-aligns the text in the rectangle. Tabs are expanded, but words are not wrapped. Text that extends past the end of a line is clipped.', 'Wrap'))
    aoPicStyles.Push(Styles("SS_NOPREFIX", "0x80","Prevents interpretation of any ampersand (&) characters in the control's text as accelerator prefix characters. This can be useful when file names or other strings that might contain an ampersand (&) must be displayed within a text control."))
    aoPicStyles.Push(Styles("SS_NOTIFY", "0x100",'Sends the parent window the STN_CLICKED notification when the user clicks the control.'))
    aoPicStyles.Push(Styles("SS_RIGHT", "0x2",'+/-Right. Specifies a rectangle and right-aligns the specified text in the rectangle.', 'Right'))
    aoPicStyles.Push(Styles("SS_SUNKEN", "0x1000",'Draws a half-sunken border around a static control.'))
    aoPicStyles.Push(Styles("SS_WHITEFRAME", "0x9",'Specifies a box with a frame drawn with the same color as the window background. This color is white in the default color scheme.'))
    aoPicStyles.Push(Styles("SS_WHITERECT", "0x6",'Specifies a rectangle filled with the current window background color. This color is white in the default color scheme.'))

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

    global aoCBBStyles := Array()
    aoCBBStyles.Push(Styles("CBS_AUTOHSCROLL", "0x40", '+/-Limit. Automatically scrolls the text in an edit control to the right when the user types a character at the end of the line. If this style is not set, only text that fits within the rectangular boundary is enabled.', "Limit"))
    aoCBBStyles.Push(Styles("CBS_DISABLENOSCROLL", "0x800", 'Shows a disabled vertical scroll bar in the drop-down list when it does not contain enough items to scroll. Without this style, the scroll bar is hidden when the drop-down list does not contain enough items.', ""))
    aoCBBStyles.Push(Styles("CBS_DROPDOWN", "0x2", 'Similar to CBS_SIMPLE, except that the list box is not displayed unless the user selects an icon next to the edit control.', ""))
    aoCBBStyles.Push(Styles("CBS_DROPDOWNLIST", "0x3", 'Similar to CBS_DROPDOWN, except that the edit control is replaced by a static text item that displays the current selection in the list box.', ""))
    aoCBBStyles.Push(Styles("CBS_LOWERCASE", "0x4000", '+/-Lowercase. Converts to lowercase any uppercase characters that are typed into the edit control of a combo box.', "Lowercase"))
    aoCBBStyles.Push(Styles("CBS_NOINTEGRALHEIGHT", "0x400", 'Specifies that the combo box will be exactly the size specified by the application when it created the combo box. Usually, Windows CE sizes a combo box so that it does not display partial items.', ""))
    aoCBBStyles.Push(Styles("CBS_OEMCONVERT", "0x80", 'Converts text typed in the combo box edit control from the Windows CE character set to the OEM character set and then back to the Windows CE set. This style is most useful for combo boxes that contain file names. It applies only to combo boxes created with the CBS_DROPDOWN style.', ""))
    aoCBBStyles.Push(Styles("CBS_SIMPLE", "0x1", '+/-Simple (ComboBox only). Displays the drop-down list at all times. The current selection in the list is displayed in the edit control.', "Simple"))
    aoCBBStyles.Push(Styles("CBS_SORT", "0x100", '+/-Sort. Sorts the items in the drop-list alphabetically.', "Sort"))
    aoCBBStyles.Push(Styles("CBS_UPPERCASE", "0x2000", '+/-Uppercase. Converts to uppercase any lowercase characters that are typed into the edit control of a ComboBox.', "Uppercase"))

    global aoLBStyles := Array()
    aoLBStyles.Push(Styles("LBS_DISABLENOSCROLL", "0x1000", 'Shows a disabled vertical scroll bar for the list box when the box does not contain enough items to scroll. If you do not specify this style, the scroll bar is hidden when the list box does not contain enough items.', ""))
    aoLBStyles.Push(Styles("LBS_NOINTEGRALHEIGHT", "0x100", 'Specifies that the list box will be exactly the size specified by the application when it created the list box.', ""))
    aoLBStyles.Push(Styles("LBS_EXTENDEDSEL", "0x800", '+/-Multi. Allows multiple selections via control-click and shift-click.', "Multi"))
    aoLBStyles.Push(Styles("LBS_MULTIPLESEL", "0x8", 'A simplified version of multi-select in which control-click and shift-click are not necessary because normal left clicks serve to extend the selection or de-select a selected item.', ""))
    aoLBStyles.Push(Styles("LBS_NOSEL", "0x4000", '+/-ReadOnly. Specifies that the user can view list box strings but cannot select them.', "ReadOnly"))
    aoLBStyles.Push(Styles("LBS_NOTIFY", "0x1", 'Causes the list box to send a notification code to the parent window whenever the user clicks a list box item (LBN_SELCHANGE), double-clicks an item (LBN_DBLCLK), or cancels the selection (LBN_SELCANCEL).', ""))
    aoLBStyles.Push(Styles("LBS_SORT", "0x2", '+/-Sort. Sorts the items in the list box alphabetically.', "Sort"))
    aoLBStyles.Push(Styles("LBS_USETABSTOPS", "0x80", 'Enables a ListBox to recognize and expand tab characters when drawing its strings. The default tab positions are 32 dialog box units apart. A dialog box unit is equal to one-fourth of the current dialog box base-width unit.', ""))

    global aoLVStyles := Array()
    aoLVStyles.Push(Styles("LVS_ALIGNLEFT", "0x800",'Items are left-aligned in icon and small icon view.',""))
    aoLVStyles.Push(Styles("LVS_ALIGNTOP", "0x0",'Items are aligned with the top of the list-view control in icon and small icon view. This is the default.',""))
    aoLVStyles.Push(Styles("LVS_AUTOARRANGE", "0x100",'Icons are automatically kept arranged in icon and small icon view.',""))
    aoLVStyles.Push(Styles("LVS_EDITLABELS", "0x200",'+/-ReadOnly. Specifying -ReadOnly (or +0x200) allows the user to edit the first field of each row in place.',"ReadOnly"))
    aoLVStyles.Push(Styles("LVS_ICON", "0x0",'+Icon. Specifies large-icon view.',"Icon"))
    aoLVStyles.Push(Styles("LVS_LIST", "0x3",'+List. Specifies list view.',"List"))
    aoLVStyles.Push(Styles("LVS_NOCOLUMNHEADER", "0x4000",'+/-Hdr. Avoids displaying column headers in report view.',"-Hdr"))
    aoLVStyles.Push(Styles("LVS_NOLABELWRAP", "0x80",'Item text is displayed on a single line in icon view. By default, item text may wrap in icon view.',""))
    aoLVStyles.Push(Styles("LVS_NOSCROLL", "0x2000",'Scrolling is disabled. All items must be within the client area. This style is not compatible with the LVS_LIST or LVS_REPORT styles.',""))
    aoLVStyles.Push(Styles("LVS_NOSORTHEADER", "0x8000",'+/-NoSortHdr. Column headers do not work like buttons. This style can be used if clicking a column header in report view does not carry out an action, such as sorting.',"NoSortHdr"))
    aoLVStyles.Push(Styles("LVS_OWNERDATA", "0x1000",'This style specifies a virtual list-view control (not directly supported by AutoHotkey).',""))
    aoLVStyles.Push(Styles("LVS_OWNERDRAWFIXED", "0x400",'The owner window can paint items in report view in response to WM_DRAWITEM messages (not directly supported by AutoHotkey).',""))
    aoLVStyles.Push(Styles("LVS_REPORT", "0x1",'+Report. Specifies report view.',"Report"))
    aoLVStyles.Push(Styles("LVS_SHAREIMAGELISTS", "0x40",'The image list will not be deleted when the control is destroyed. This style enables the use of the same image lists with multiple list-view controls.',""))
    aoLVStyles.Push(Styles("LVS_SHOWSELALWAYS", "0x8",'The selection, if any, is always shown, even if the control does not have keyboard focus.',""))
    aoLVStyles.Push(Styles("LVS_SINGLESEL", "0x4",'+/-Multi. Only one item at a time can be selected. By default, multiple items can be selected.',"Multi"))
    aoLVStyles.Push(Styles("LVS_SMALLICON", "0x2",'+IconSmall. Specifies small-icon view.',"IconSmall"))
    aoLVStyles.Push(Styles("LVS_SORTASCENDING", "0x10",'+/-Sort. Rows are sorted in ascending order based on the contents of the first field.',"Sort"))
    aoLVStyles.Push(Styles("LVS_SORTDESCENDING", "0x20",'+/-SortDesc. Same as above but in descending order.',"SortDesc."))

    global aoLVExStyles := Array()
    aoLVExStyles.Push(Styles("LVS_EX_BORDERSELECT", "LV0x8000",'When an item is selected, the border color of the item changes rather than the item being highlighted (might be non-functional in recent operating systems).',""))
    aoLVExStyles.Push(Styles("LVS_EX_CHECKBOXES", "LV0x4",'+/-Checked. Displays a checkbox with each item. When set to this style, the control creates and sets a state image list with two images using DrawFrameControl. State image 1 is the unchecked box, and state image 2 is the checked box. Setting the state image to zero removes the check box altogether.',"Checked"))
    aoLVExStyles.Push(Styles("LVS_EX_DOUBLEBUFFER", "LV0x10000",'Paints via double-buffering, which reduces flicker. This extended style also enables alpha-blended marquee selection on systems where it is supported.',""))
    aoLVExStyles.Push(Styles("LVS_EX_FLATSB", "LV0x100",'Enables flat scroll bars in the list view.',""))
    aoLVExStyles.Push(Styles("LVS_EX_FULLROWSELECT", "LV0x20",'When a row is selected, all its fields are highlighted. This style is available only in conjunction with the LVS_REPORT style.',""))
    aoLVExStyles.Push(Styles("LVS_EX_GRIDLINES", "LV0x1",'+/-Grid. Displays gridlines around rows and columns. This style is available only in conjunction with the LVS_REPORT style.',"Grid"))
    aoLVExStyles.Push(Styles("LVS_EX_HEADERDRAGDROP", "LV0x10",'Enables drag-and-drop reordering of columns in a list-view control. This style is only available to list-view controls that use the LVS_REPORT style.',""))
    aoLVExStyles.Push(Styles("LVS_EX_INFOTIP", "LV0x400",'When a list-view control uses this style, the LVN_GETINFOTIP notification message is sent to the parent window before displaying an item`'s ToolTip.',""))
    aoLVExStyles.Push(Styles("LVS_EX_LABELTIP", "LV0x4000",'If a partially hidden label in any list-view mode lacks ToolTip text, the list-view control will unfold the label. If this style is not set, the list-view control will unfold partly hidden labels only for the large icon mode. Note: On some versions of Windows, this style might not work properly if the GUI window is set to be always-on-top.',""))
    aoLVExStyles.Push(Styles("LVS_EX_MULTIWORKAREAS", "LV0x2000",'If the list-view control has the LVS_AUTOARRANGE style, the control will not autoarrange its icons until one or more work areas are defined (see LVM_SETWORKAREAS). To be effective, this style must be set before any work areas are defined and any items have been added to the control.',""))
    aoLVExStyles.Push(Styles("LVS_EX_ONECLICKACTIVATE", "LV0x40",'The list-view control sends an LVN_ITEMACTIVATE notification message to the parent window when the user clicks an item. This style also enables hot tracking in the list-view control. Hot tracking means that when the cursor moves over an item, it is highlighted but not selected.',""))
    aoLVExStyles.Push(Styles("LVS_EX_REGIONAL", "LV0x200",'Sets the list-view window region to include only the item icons and text using SetWindowRgn. Any area that is not part of an item is excluded from the window region. This style is only available to list-view controls that use the LVS_ICON style.',""))
    aoLVExStyles.Push(Styles("LVS_EX_SIMPLESELECT", "LV0x100000",'In icon view, moves the state image of the item to the top right of the large icon rendering. In views other than icon view there is no change. When the user changes the state by using the space bar, all selected items cycle over, not the item with the focus.',""))
    aoLVExStyles.Push(Styles("LVS_EX_SUBITEMIMAGES", "LV0x2",'Allows images to be displayed for fields beyond the first. This style is available only in conjunction with the LVS_REPORT style.',""))
    aoLVExStyles.Push(Styles("LVS_EX_TRACKSELECT", "LV0x8",'Enables hot-track selection in a list-view control. Hot track selection means that an item is automatically selected when the cursor remains over the item for a certain period of time. The delay can be changed from the default system setting with a LVM_SETHOVERTIME message. This style applies to all styles of list-view control. You can check whether hot-track selection is enabled by calling SystemParametersInfo.',""))
    aoLVExStyles.Push(Styles("LVS_EX_TWOCLICKACTIVATE", "LV0x80",'The list-view control sends an LVN_ITEMACTIVATE notification message to the parent window when the user double-clicks an item. This style also enables hot tracking in the list-view control. Hot tracking means that when the cursor moves over an item, it is highlighted but not selected.',""))
    aoLVExStyles.Push(Styles("LVS_EX_UNDERLINECOLD", "LV0x1000",'Causes those non-hot items that may be activated to be displayed with underlined text. This style requires that LVS_EX_TWOCLICKACTIVATE be set also.',""))
    aoLVExStyles.Push(Styles("LVS_EX_UNDERLINEHOT", "LV0x800",'Causes those hot items that may be activated to be displayed with underlined text. This style requires that LVS_EX_ONECLICKACTIVATE or LVS_EX_TWOCLICKACTIVATE also be set.',""))


    global aoTreeViewStyles := Array()
    aoTreeViewStyles.Push(Styles("TVS_CHECKBOXES", "0x100",'+/-Checked. Displays a checkbox next to each item.',"Checked"))
    aoTreeViewStyles.Push(Styles("TVS_DISABLEDRAGDROP", "0x10",'Prevents the tree-view control from sending TVN_BEGINDRAG notification messages.',""))
    aoTreeViewStyles.Push(Styles("TVS_EDITLABELS", "0x8",'+/-ReadOnly. Allows the user to edit the names of tree-view items.',"ReadOnly"))
    aoTreeViewStyles.Push(Styles("TVS_FULLROWSELECT", "0x1000",'Enables full-row selection in the tree view. The entire row of the selected item is highlighted, and clicking anywhere on an item`'s row causes it to be selected. This style cannot be used in conjunction with the TVS_HASLINES style.',""))
    aoTreeViewStyles.Push(Styles("TVS_HASBUTTONS", "0x1",'+/-Buttons. Displays plus (+) and minus (-) buttons next to parent items. The user clicks the buttons to expand or collapse a parent item`'s list of child items. To include buttons with items at the root of the tree view, TVS_LINESATROOT must also be specified.',"Buttons"))
    aoTreeViewStyles.Push(Styles("TVS_HASLINES", "0x2",'+/-Lines. Uses lines to show the hierarchy of items.',"Lines"))
    aoTreeViewStyles.Push(Styles("TVS_INFOTIP", "0x800",'Obtains ToolTip information by sending the TVN_GETINFOTIP notification.',""))
    aoTreeViewStyles.Push(Styles("TVS_LINESATROOT", "0x4",'+/-Lines. Uses lines to link items at the root of the tree-view control. This value is ignored if TVS_HASLINES is not also specified.',"Lines"))
    aoTreeViewStyles.Push(Styles("TVS_NOHSCROLL", "0x8000",'+/-HScroll. Disables horizontal scrolling in the control. The control will not display any horizontal scroll bars.',"Hscroll"))
    aoTreeViewStyles.Push(Styles("TVS_NONEVENHEIGHT", "0x4000",'Sets the height of the items to an odd height with the TVM_SETITEMHEIGHT message. By default, the height of items must be an even value.',""))
    aoTreeViewStyles.Push(Styles("TVS_NOSCROLL", "0x2000",'Disables both horizontal and vertical scrolling in the control. The control will not display any scroll bars.',""))
    aoTreeViewStyles.Push(Styles("TVS_NOTOOLTIPS", "0x80",'Disables tooltips.',""))
    aoTreeViewStyles.Push(Styles("TVS_RTLREADING", "0x40",'Causes text to be displayed from right-to-left (RTL). Usually, windows display text left-to-right (LTR).',""))
    aoTreeViewStyles.Push(Styles("TVS_SHOWSELALWAYS", "0x20",'Causes a selected item to remain selected when the tree-view control loses focus.',""))
    aoTreeViewStyles.Push(Styles("TVS_SINGLEEXPAND", "0x400",'Causes the item being selected to expand and the item being unselected to collapse upon selection in the tree-view. If the user holds down Ctrl while selecting an item, the item being unselected will not be collapsed.',""))
    aoTreeViewStyles.Push(Styles("TVS_TRACKSELECT", "0x200",'Enables hot tracking of the mouse in a tree-view control.',""))


    global aoDateTimeStyles := Array()
    aoDateTimeStyles.Push(Styles("DTS_UPDOWN", "0x1",'Provides an up-down control to the right of the control to modify date-time values, which replaces the of the drop-down month calendar that would otherwise be available.',""))
    aoDateTimeStyles.Push(Styles("DTS_SHOWNONE", "0x2",'Displays a checkbox inside the control that users can uncheck to make the control have no date/time selected. Whenever the control has no date/time, Gui.Submit and GuiCtrl.Value will retrieve a blank value (empty string).',""))
    aoDateTimeStyles.Push(Styles("DTS_SHORTDATEFORMAT", "0x0",'Displays the date in short format. In some locales, it looks like 6/1/05 or 6/1/2005. On older operating systems, a two-digit year might be displayed. This is why DTS_SHORTDATECENTURYFORMAT is the default and not DTS_SHORTDATEFORMAT.',""))
    aoDateTimeStyles.Push(Styles("DTS_LONGDATEFORMAT", "0x4",'Format option "LongDate". Displays the date in long format. In some locales, it looks like Wednesday, June 01, 2005.',""))
    aoDateTimeStyles.Push(Styles("DTS_SHORTDATECENTURYFORMAT", "0xC",'Format option blank/omitted. Displays the date in short format with four-digit year. In some locales, it looks like 6/1/2005. If the system`'s version of Comctl32.dll is older than 5.8, this style is not supported and DTS_SHORTDATEFORMAT is automatically substituted.',""))
    aoDateTimeStyles.Push(Styles("DTS_TIMEFORMAT", "0x9",'Format option "Time". Displays only the time, which in some locales looks like 5:31:42 PM.',""))
    aoDateTimeStyles.Push(Styles("DTS_APPCANPARSE", "0x10",'Not yet supported. Allows the owner to parse user input and take necessary action. It enables users to edit within the client area of the control when they press F2. The control sends DTN_USERSTRING notification messages when users are finished.',""))
    aoDateTimeStyles.Push(Styles("DTS_RIGHTALIGN", "0x20",'+/-Right. The calendar will drop down on the right side of the control instead of the left.',"Right"))


    global aoMonthCalStyles := Array()
    aoMonthCalStyles.Push(Styles("MCS_DAYSTATE", "0x1",'Makes the control send MCN_GETDAYSTATE notifications to request information about which days should be displayed in bold. [Not yet supported]',""))
    aoMonthCalStyles.Push(Styles("MCS_WEEKNUMBERS", "0x4",'Displays week numbers (1-52) to the left of each row of days. Week 1 is defined as the first week that contains at least four days.',""))
    aoMonthCalStyles.Push(Styles("MCS_NOTODAYCIRCLE", "0x8",'Prevents the circling of today`'s date within the control.',""))
    aoMonthCalStyles.Push(Styles("MCS_NOTODAY", "0x10",'Prevents the display of today`'s date at the bottom of the control.',""))


    global aoSliderStyles := Array()
    aoSliderStyles.Push(Styles("TBS_VERT", "0x2",'+/-Vertical. The control is oriented vertically.',"Vertical"))
    aoSliderStyles.Push(Styles("TBS_LEFT", "0x4",'+/-Left. The control displays tick marks at the top of the control (or to its left if TBS_VERT is present). Same as TBS_TOP.',"Left"))
    aoSliderStyles.Push(Styles("TBS_TOP", "0x4",'same as TBS_LEFT.',""))
    aoSliderStyles.Push(Styles("TBS_BOTH", "0x8",'+/-Center. The control displays tick marks on both sides of the control. This will be both top and bottom when used with TBS_HORZ or both left and right if used with TBS_VERT.',"Center"))
    aoSliderStyles.Push(Styles("TBS_AUTOTICKS", "0x1",'The control has a tick mark for each increment in its range of values. Use +/-TickInterval to have more flexibility.',""))
    aoSliderStyles.Push(Styles("TBS_ENABLESELRANGE", "0x20",'The control displays a selection range only. The tick marks at the starting and ending positions of a selection range are displayed as triangles (instead of vertical dashes), and the selection range is highlighted (highlighting might require that the theme be removed via GuiObj.Opt("-Theme")).',""))
    aoSliderStyles.Push(Styles("TBS_FIXEDLENGTH", "0x40",'+/-Thick. Allows the thumb`'s size to be changed.',"Thick"))
    aoSliderStyles.Push(Styles("TBS_NOTHUMB", "0x80",'The control does not display the moveable bar.',""))
    aoSliderStyles.Push(Styles("TBS_NOTICKS", "0x10",'+/-NoTicks. The control does not display any tick marks.',"NoTicks"))
    aoSliderStyles.Push(Styles("TBS_TOOLTIPS", "0x100",'+/-ToolTip. The control supports tooltips. When a control is created using this style, it automatically creates a default ToolTip control that displays the slider`'s current position. You can change where the tooltips are displayed by using the TBM_SETTIPSIDE message.',"ToolTip"))
    aoSliderStyles.Push(Styles("TBS_REVERSED", "0x200",'Unfortunately, this style has no effect on the actual behavior of the control, so there is probably no point in using it (instead, use +Invert in the control`'s options to reverse it). Depending on OS version, this style might require Internet Explorer 5.0 or greater.',""))
    aoSliderStyles.Push(Styles("TBS_DOWNISLEFT", "0x400",'Unfortunately, this style has no effect on the actual behavior of the control, so there is probably no point in using it. Depending on OS version, this style might require Internet Explorer 5.01 or greater.',""))


    global aoProgressStyles := Array()
    aoProgressStyles.Push(Styles("PBS_SMOOTH", "0x1",'+/-Smooth. The progress bar displays progress status in a smooth scrolling bar instead of the default segmented bar. When this style is present, the control automatically reverts to the Classic Theme appearance.',"Smooth"))
    aoProgressStyles.Push(Styles("PBS_VERTICAL", "0x4",'+/-Vertical. The progress bar displays progress status vertically, from bottom to top.',"Vertical"))
    aoProgressStyles.Push(Styles("PBS_MARQUEE", "0x8",'The progress bar moves like a marquee; that is, each change to its position causes the bar to slide further along its available length until it wraps around to the other side. A bar with this style has no defined position. Each attempt to change its position will instead slide the bar by one increment. This style is typically used to indicate an ongoing operation whose completion time is unknown.',""))
    
    global aoTabStyles := Array()
    aoTabStyles.Push(Styles("TCS_SCROLLOPPOSITE", "0x1", 'Unneeded tabs scroll to the opposite side of the control when a tab is selected.', ""))
    aoTabStyles.Push(Styles("TCS_BOTTOM", "0x2", '+/-Bottom. Tabs appear at the bottom of the control instead of the top.', "Bottom"))
    aoTabStyles.Push(Styles("TCS_RIGHT", "0x2", 'Tabs appear vertically on the right side of controls that use the TCS_VERTICAL style.', ""))
    aoTabStyles.Push(Styles("TCS_MULTISELECT", "0x4", 'Multiple tabs can be selected by holding down Ctrl when clicking. This style must be used with the TCS_BUTTONS style.', ""))
    aoTabStyles.Push(Styles("TCS_FLATBUTTONS", "0x8", 'Selected tabs appear as being indented into the background while other tabs appear as being on the same plane as the background. This style only affects tab controls with the TCS_BUTTONS style.', ""))
    aoTabStyles.Push(Styles("TCS_FORCEICONLEFT", "0x10", 'Icons are aligned with the left edge of each fixed-width tab. This style can only be used with the TCS_FIXEDWIDTH style.', ""))
    aoTabStyles.Push(Styles("TCS_FORCELABELLEFT", "0x20", 'Labels are aligned with the left edge of each fixed-width tab; that is, the label is displayed immediately to the right of the icon instead of being centered. This style can only be used with the TCS_FIXEDWIDTH style, and it implies the TCS_FORCEICONLEFT style.', ""))
    aoTabStyles.Push(Styles("TCS_HOTTRACK", "0x40", 'Items under the pointer are automatically highlighted.', ""))
    aoTabStyles.Push(Styles("TCS_VERTICAL", "0x80", '+/-Left or +/-Right. Tabs appear at the left side of the control, with tab text displayed vertically. This style is valid only when used with the TCS_MULTILINE style. To make tabs appear on the right side of the control, also use the TCS_RIGHT style.', "Left"))
    aoTabStyles.Push(Styles("TCS_BUTTONS", "0x100", '+/-Buttons. Tabs appear as buttons, and no border is drawn around the display area.', "Buttons"))
    aoTabStyles.Push(Styles("TCS_SINGLELINE", "0x0", '+/-Wrap. Only one row of tabs is displayed. The user can scroll to see more tabs, if necessary. This style is the default.', "Wrap"))
    aoTabStyles.Push(Styles("TCS_MULTILINE", "0x200", '+/-Wrap. Multiple rows of tabs are displayed, if necessary, so all tabs are visible at once.', "Wrap"))
    aoTabStyles.Push(Styles("TCS_RIGHTJUSTIFY", "0x0", 'This is the default. The width of each tab is increased, if necessary, so that each row of tabs fills the entire width of the tab control. This style will not correctly display the tabs if a custom background color or text color is in effect. To workaround this, specify -Background and/or cDefault in the tab control`'s options. This window style is ignored unless the TCS_MULTILINE style is also specified.', ""))
    aoTabStyles.Push(Styles("TCS_FIXEDWIDTH", "0x400", 'All tabs are the same width. This style cannot be combined with the TCS_RIGHTJUSTIFY style.', ""))
    aoTabStyles.Push(Styles("TCS_RAGGEDRIGHT", "0x800", 'Rows of tabs will not be stretched to fill the entire width of the control. This style is the default.', ""))
    aoTabStyles.Push(Styles("TCS_FOCUSONBUTTONDOWN", "0x1000", 'The tab control receives the input focus when clicked.', ""))
    aoTabStyles.Push(Styles("TCS_OWNERDRAWFIXED", "0x2000", 'The parent window is responsible for drawing tabs.', ""))
    aoTabStyles.Push(Styles("TCS_TOOLTIPS", "0x4000", 'The tab control has a tooltip control associated with it.', ""))
    aoTabStyles.Push(Styles("TCS_FOCUSNEVER", "0x8000", 'The tab control does not receive the input focus when clicked.', ""))

    global aoStatusbarStyles := Array()
    aoStatusbarStyles.Push(Styles("SBARS_TOOLTIPS", "0x800",'Displays a tooltip when the mouse hovers over a part of the status bar that: 1) has too much text to be fully displayed; or 2) has an icon but no text. The text of the tooltip can be set via: SendMessage 0x0410, 0, "Text to display", "msctls_statusbar321", MyGui The bold 0 above is the zero-based part number. To use a part other than the first, specify 1 for second, 2 for the third, etc. NOTE: The tooltip might never appear on certain OS versions.',""))
    aoStatusbarStyles.Push(Styles("SBARS_SIZEGRIP", "0x100",'Includes a sizing grip at the right end of the status bar. A sizing grip is similar to a sizing border; it is a rectangular area that the user can click and drag to resize the parent window.',""))

    Global aoDefaultStyles := Object()
    aoDefaultStyles.window := {style:0xffffffff94ca0000, exStyle:0x100}
    aoDefaultStyles.gui := {style:0xffffffff94ca0000, exStyle:0x100}
    aoDefaultStyles.edit := {style:0x50010080, exStyle:0x200}
    aoDefaultStyles.editmultiLine := {style:0x50211040, exStyle:0x200}
    aoDefaultStyles.button := {style:0x50010000, exStyle:0x0}
    aoDefaultStyles.checkbox := {style:0x50010003, exStyle:0x0}
    aoDefaultStyles.hotkey := {style:0x50010000, exStyle:0x200}
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
    aoDefaultStyles.listview := {style:0x50010009, exStyle:0x0}
    aoDefaultStyles.statusbar := {style:0x50000800, exStyle:0x0}
    aoDefaultStyles.separator := {style:0x50000000, exStyle:0x0}
}

global SettingsFile := Regexreplace(A_scriptName, "(.*)\..*", "$1.ini")
;Load the existing settings 
global oSettings := FileExist(SettingsFile) ? ReadINI(SettingsFile, oSettings_Default) : oSettings_Default
global oSet := oSettings.MainGui

try FileInstall("Images.icl", "Images.icl")

If !pToken := Gdip_Startup() {
    MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system"
    ExitApp
}
OnExit((ExitReason, ExitCode) => Gdip_Shutdown(pToken))

Gui_wInspector()

Gui_wInspector(*){
    global
    if (IsSet(MyGui) and WinExist("wInspector ahk_exe autohotkey.exe")){
        return
    }

    MyGui := Gui("+AlwaysOnTop +MinSize304x114", "wInspector")
    MyGui.OnEvent("Close",(*)=>(myGui.Destroy()))
    oSet.WinResize=1 ? myGui.Opt("+Resize") : myGui.Opt("-Resize")
    oSet.WinAlwaysOnTop=1 ? myGui.Opt("+AlwaysOnTop") : myGui.Opt("-AlwaysOnTop")
    MyGui.MarginX := 2
    MyGui.MarginY := 2
    MyGui.Width := 1200
    MyGui.win_hwnd := 0
    MyGui.ctrl_hwnd := 0
    ogButton_Selector := MyGui.addButton("xm y0 w60 vbtnSelector BackgroundTrans h24 w24 +0x4000", "+")
    ogButton_Selector.SetFont("s20", "Times New Roman")
    ogButton_Selector.statusbar := "Click and drag to select a specific control or window"

    ChildOpt := "+Parent" myGui.hwnd " -Resize +AlwaysOnTop -Border -Caption -ToolWindow"
    ; ChildOpt := "+Parent" myGui.hwnd " +Resize +AlwaysOnTop -Border -Caption +ToolWindow" ; Borders visible for testing

    ; Child guis or sections
    oGuiWindow := Gui(, "Window")
    oGuiControl := Gui(, "Control")
    oGuiAcc := Gui(, "Acc")
    oGuiMouse := Gui(, "Mouse")
    oGuiFunction := Gui(, "Function")
    oGuiWindowList := Gui(, "WindowList")
    oGuiControlList := Gui(, "ControlList")
    oGuiProcessList := Gui(, "ProcessList")

    myGui.aSections := [oGuiWindow, oGuiControl, oGuiAcc, oGuiMouse, oGuiFunction, oGuiProcessList, oGuiWindowList, oGuiControlList]

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

    ogGB_Window := oGuiWindow.AddGroupBox("w300 h145 Section", "Window")
    ogGB_Window.LeftMargin := 2
    ogGB_Window.BottomMargin := 2
    oGuiWindow.AddText("xp+3 yp+18", "Title")
    ogEdit_wTitle := oGuiWindow.AddEdit("x42 yp-3 w255", "")
    ogEdit_wTitle.StatusBar := "WinGetTitle(WinTitle, WinText, ExcludeTitle, ExcludeText)"
    oGuiWindow.AddText("x6 y+5", "Class")
    ogEdit_wClass := oGuiWindow.AddEdit("x42 yp-3 w170 vwClass +ReadOnly")
    ogEdit_wClass.StatusBar := "WinGetClass(WinTitle, WinText, ExcludeTitle, ExcludeText)"
    oGuiWindow.AddText("x+4 yp+3", "ID")
    ogEdit_wID := oGuiWindow.AddEdit("x237 yp-3 Right vwID w60 +ReadOnly")
    ogEdit_wID.StatusBar := "WinGetID(WinTitle, WinText, ExcludeTitle, ExcludeText)"
    oGuiWindow.AddText("x4 y+5", "Process")
    ogEdit_wProcess := oGuiWindow.AddEdit("x42 yp-3 w170 vwProcess +ReadOnly")
    oGuiWindow.AddText("x+3 yp+3", "PID")
    ogEdit_wPID := oGuiWindow.AddEdit("x237 yp-3 w60 Right vwPID +ReadOnly")

    oGuiWindow.AddText("x30 y+5", "X")
    ogEdit_wXPos := oGuiWindow.AddEdit("x42 yp-3 Right Number vwXPos w40")
    oGuiWindow.AddText("x+5 yp+3", "Y")
    ogEdit_wYPos := oGuiWindow.AddEdit("x+2 yp-3 Right Number vwYPos w40")
    ogEdit_wYPos.StatusBar := "Y position of window"
    oGuiWindow.AddText("x+5 yp+3", "W")
    ogEdit_wWidth := oGuiWindow.AddEdit("x+2 yp-3 Right Number vwWPos w40")
    oGuiWindow.AddText("x+5 yp+3", "H")
    ogEdit_wHeight := oGuiWindow.AddEdit("x+2 yp-3 Right Number vwHPos w40")
    ogButton_Move := oGuiWindow.AddButton("x258 yp-1 w40", "Move")
    ogButton_Move.OnEvent("Click", (*) => (WinExist("ahk_id " ogEdit_wID.value) ? WinMove(ogEdit_wXPos.value, ogEdit_wYPos.value, ogEdit_wWidth.value, ogEdit_wHeight.value, "ahk_id " ogEdit_wID.value) : ""))
    oGuiWindow.AddText("x8 y+4", "Transparent:")
    ogSlider_Transparent := oGuiWindow.AddSlider("xp+60 vTransparent  Range0-255 ToolTip", "255")
    ogSlider_Transparent.OnEvent("Change", (*) => (WinExist("ahk_id " ogEdit_wID.value) ? WinSetTransparent(ogSlider_Transparent.value, "ahk_id " ogEdit_wID.value) : ""))

    ; Control Section

    oGuiControl.posRef := oGuiWindow
    oGuiControl.posRule := "Xx Yyh Ww"
    ogGB_Control := oGuiControl.AddGroupBox("xm w300 h88", "Control")
    ogGB_Control.LeftMargin := 2
    ogGB_Control.BottomMargin := 2
    oGuiControl.AddText("xp+3 yp+18", "Text")
    ogEdit_cText := oGuiControl.AddEdit("x42 yp-3 w255", "")
    ogEdit_cText.StatusBar := "ControlGetText(Control, WinTitle, WinText, ExcludeTitle, ExcludeText)"
    oGuiControl.AddText("x6 y+5", "Class")
    ogEdit_cClass := oGuiControl.AddEdit("x42 yp-3 w178 vccClass +ReadOnly")
    ogEdit_cClass.StatusBar := "ControlGetClassNN(Control , WinTitle, WinText, ExcludeTitle, ExcludeText)"
    oGuiControl.AddText("x+4 yp+3", "ID")
    ogEdit_cID := oGuiControl.AddEdit("x237 yp-3 w60 Right vcID +ReadOnly")
    ogEdit_cID.StatusBar := "ControlGetHwnd(Control, WinTitle, WinText, ExcludeTitle, ExcludeText)"

    oGuiControl.AddText("x30 y+5", "X")
    ogEdit_cXPos := oGuiControl.AddEdit("x42 yp-3 Right Number vcXPos w40")
    oGuiControl.AddText("x+5 yp+3", "Y")
    ogEdit_cYPos := oGuiControl.AddEdit("x+2 yp-3 Right Number vcYPos w40")
    oGuiControl.AddText("x+5 yp+3", "W")
    ogEdit_cWidth := oGuiControl.AddEdit("x+2 yp-3 Right Number vcWPos w40")
    oGuiControl.AddText("x+5 yp+3", "H")
    ogEdit_cHeight := oGuiControl.AddEdit("x+2 yp-3 Right Number vcHPos w40")
    ogButton_cMove := oGuiControl.AddButton("x258 yp-1 w40", "Move")
    ogButton_cMove.OnEvent("Click", (*) => (ControlMove(ogEdit_cXPos.value, ogEdit_cYPos.value, ogEdit_cWidth.value, ogEdit_cHeight.value, ogEdit_cID.value + 0)))

    ; Acc Section

    oGuiAcc.posRef := oGuiControl
    oGuiAcc.posRule := "Xx Yyh Ww"
    ogGB_Acc := oGuiAcc.AddGroupBox("xm w300", "Acc")
    ogGB_Acc.LeftMargin := 2
    ogGB_Acc.BottomMargin := 2
    ogLV_AccProps := oGuiAcc.Add("ListView", "xp+3 yp+18 h220 w293", ["Property", "Value"])
    ogLV_AccProps.ModifyCol(1, 100)
    for i, v in ["RoleText", "Role", "Value", "Name", "Location", "StateText", "State", "DefaultAction", "Description", "KeyboardShortcut", "Help", "ChildId"]
        ogLV_AccProps.Add(, v, "")

    ogLV_AccProps.OnNotify(NM_RCLICK := -5, RClickAccList)

    ; Mouse Section

    oGuiMouse.posRef := oGuiAcc
    oGuiMouse.posRule := "Xx Yyh Ww"
    ogGB_Mouse := oGuiMouse.AddGroupBox("xm w300", "Mouse")
    ogGB_Mouse.LeftMargin := 2
    ogGB_Mouse.BottomMargin := 2
    oGuiMouse.AddText("xp+3 yp+18", "Pos")
    ogEdit_mPos := oGuiMouse.AddEdit("x42 yp-3 w70", "")
    ogDDL_MouseCoordMode := oGuiMouse.AddDropDownList("x+3 yp w70 vDDL_MouseCoordMode Choose1", ["Screen", "Window", "Client"])
    ogBut_MouseMove := oGuiMouse.AddButton("x+3 yp-1 w50", "Move")
    ogBut_MouseMove.OnEvent("Click", (*) => (CoordMode("Mouse", ogDDL_MouseCoordMode.Text), MouseMove(MyGui.MouseX+0,MyGui.MouseY+0)))
    ogBut_MouseClick := oGuiMouse.AddButton("x+3 yp w50", "Click")
    ogBut_MouseClick.OnEvent("Click", (*) => (CoordMode("Mouse", ogDDL_MouseCoordMode.Text), Mouseclick(,MyGui.MouseX+0,MyGui.MouseY+0)))
    oGuiMouse.AddText("x6 y+4", "RGB")
    ogEdit_mColor := oGuiMouse.AddEdit("x42 yp-3 w70", "")
    ogText_mColor := oGuiMouse.AddText("x+3 yp w21 h21 BackgroundWhite +Border")

    ogDDL_GridSize := oGuiMouse.AddDropDownList("x+3 yp w60 vDDL_GridSize" , ["1x1", "3x3","5x5", "9x9", "15x15"])

    ogDDL_GridSize.text := oSet.MouseGrid "x" oSet.MouseGrid
    ogDDL_GridSize.OnEvent("Change", GridSize_Change)
    oGuiMouse.Grid := oSet.MouseGrid

    ogPic_Grid := oGuiMouse.AddPicture("x42 y+2 w" oGuiMouse.Grid*16 " h" oGuiMouse.Grid*16 " +0x40 +0xE +Border Section")
    ogText_Line1 := oGuiMouse.AddText("xs+" (oGuiMouse.Grid-1) * 16/2 " ys+1 w1 h" oGuiMouse.Grid * 16-2 " backgroundWhite")
    ogText_Line2 := oGuiMouse.AddText("xs+" (oGuiMouse.Grid+1) * 16/2 " ys+1 w1 h" oGuiMouse.Grid * 16-2 " backgroundWhite")
    ogText_Line3 := oGuiMouse.AddText("xs+1 ys+" (oGuiMouse.Grid - 1) * 16 / 2 " w" oGuiMouse.Grid * 16-2 " h1 backgroundWhite")
    ogText_Line4 := oGuiMouse.AddText("xs+1 ys+" (oGuiMouse.Grid + 1) * 16 / 2 " w" oGuiMouse.Grid * 16-2 " h1 backgroundWhite")
    GridSize_Change()

    ; Function Section

    oGuiFunction.posRef := oGuiMouse
    oGuiFunction.posRule := "Xx Yyh Ww"
    ogGBFunction := oGuiFunction.addGroupBox(,"Function")
    ogGBFunction.LeftMargin := 2
    ogGBFunction.BottomMargin := 2

    moFunctions := Map()
    moFunctions["ControlAddItem"] := {var1:"String", var1Default: "", control:true, description:"Adds the specified string as a new entry at the bottom of a ListBox or ComboBox."}
    moFunctions["ControlChooseIndex"] := {var1:"N", var1Default: "0", control:true, description:"Sets the selection in a ListBox, ComboBox or Tab control to be the specified entry or tab number."}
    moFunctions["ControlChooseString"] := {var1:"String", var1Default: "0", control:true, description:"Sets the selection in a ListBox or ComboBox to be the first entry whose leading part matches the specified string."}
    moFunctions["ControlClick"] := {control:true, description:"Sends a mouse button or mouse wheel event to a control."}
    moFunctions["ControlFocus"] := {control:true, description:"Sets input focus to a given control on a window."}
    moFunctions["ControlGetChecked"] := {control:true, description: "Returns a non-zero value if the checkbox or radio button is checked.", result: true}
    moFunctions["ControlGetChoice"] := {control:true, description: "Returns the name of the currently selected entry in a ListBox or ComboBox.", result: true}
    moFunctions["ControlGetText"] := {control:true, description: "Retrieves text from a control.", result: true}
    moFunctions["ControlGetItems"] := {control:true, description: "Returns an array of items/rows from a ListBox, ComboBox, or DropDownList.", result: true}
    moFunctions["ControlGetIndex"] := {control:true, description: "Returns the index of the currently selected entry or tab in a ListBox, ComboBox or Tab control.", result: true}
    moFunctions["ControlSend"] := {var1:"Keys", var1Default: "", control:true, description:"Sends simulated keystrokes to a window or control."}
    moFunctions["ControlSendText"] := {var1:"Keys", var1Default: "", control:true, description: "Sends text to a window or control."}
    moFunctions["ControlSetText"] := {var1:"NewText", var1Default: "", control:true, description:"Changes the text of a control."}
    moFunctions["ControlSetEnabled"] := {var1:"Value", var1Default: "1", control:true, description:"Enables or disables the specified control."}
    moFunctions["ListViewGetContent"] := {var1: "Options", var1Default: "", control:true, description:"Returns a list of items/rows from a ListView.", result: true}
    moFunctions["SendMessage"] := {var1:"Msg", var1Default: "", var2: "wParam", var2Default: "0", var3: "lParam", var3Default: "0", control:true, result:true, description:"Sends a message to a window or control and waits for acknowledgement."}
    moFunctions["PostMessage"] := {var1:"Msg", var1Default: "", var2: "wParam", var2Default: "0", var3: "lParam", var3Default: "0", control:true, result:true, description:"Places a message in the message queue of a window or control."}
    moFunctions["WinClose"] := {description: "Closes the specified window."}
    moFunctions["WinGetControls"] := {description: "Returns the control names for all controls in the specified window.", result: true}
    moFunctions["WinGetCount"] := {description: "Returns the number of existing windows that match the specified criteria.", result: true}
    moFunctions["WinGetClass"] := {description: "Retrieves the specified window`'s class name.", result: true}
    moFunctions["WinGetPID"] := {description: "Returns the Process ID number of the specified window.", result: true}
    moFunctions["WinGetTitle"] := {description: "Retrieves the title of the specified window.", result: true}
    moFunctions["WinGetText"] := {description: "Retrieves the text from the specified window.", result: true}
    moFunctions["WinGetStyle"] := {description: "Returns the style of the specified window.", result: true}
    moFunctions["WinGetExStyle"] := {description: "Returns the extended style of the specified window.", result: true}
    moFunctions["WinGetMinMax"] := {description: "Returns the state whether the specified window is maximized or minimized.", result: true}
    moFunctions["WinGetList"] := {description: "Returns the unique ID numbers of all existing windows that match the specified criteria.", result: true}
    moFunctions["WinGetProcessName"] := {description: "Returns the name of the process that owns the specified window.", result: true}
    moFunctions["WinGetProcessPath"] := {description: "Returns the full path and name of the process that owns the specified window.", result: true}

    aFunctionList := Array()
    For Key, Value in moFunctions{
        aFunctionList.Push(Key)
    }
    DDLFunction := oGuiFunction.AddComboBox("x60 yp+15 w130 Choose", aFunctionList)
    DDLFunction.AutoComplete := true
    DDLFunction.text := oSet.Function
    DDLFunction.OnEvent("Change", (*)=> (UpdateFunctionControls(), Gui_Autosize(), Gui_Size(MyGui)))

    BtnRun := oGuiFunction.AddPicButton("x+8 yp-1 w23 h23", "mmcndmgr.dll","icon33 w16 h16")
    BtnRun.StatusBar := "Run the selected function"
    BtnRun.OnEvent("Click",ClickRun)

    BtnCopy := oGuiFunction.AddPicButton("x+6 yp w23 h23", "shell32.dll","icon135 w16 h16")
    BtnCopy.StatusBar := "Copy the Code"
    BtnCopy.OnEvent("Click",ClickCopy)
    BtnInfo := oGuiFunction.AddPicButton("x+6 yp w23 h23", "shell32.dll","icon278 w14 h14")
    BtnInfo.StatusBar := "Open the documentation of the function."
    BtnInfo.OnEvent("Click",(*)=>(run("https://lexikos.github.io/v2/docs/search.htm?q=" DDLFunction.text "&m=2")))

    ogTxtVar1 := oGuiFunction.AddText("xm+2 y+4 w50", "Msg")
    ogEdtVar1 := oGuiFunction.AddEdit("x60 yp-3 w237 right", "")
    ogTxtVar2 := oGuiFunction.AddText("xm+2 y+6 w50 Hidden", "wParam")
    ogTxtVar2.posRef := ogTxtVar1
    ogTxtVar2.yMargin := 10
    ogEdtVar2 := oGuiFunction.AddEdit("x60 yp-4 w86 right Hidden", 0)
    ogEdtVar2.posRef := ogEdtVar1
    ogEdtVar2.yMargin := 2

    ogTxtVar3 := oGuiFunction.AddText("x+5 yp+3 w50 Hidden", "lParam")
    ogEdtVar3 := oGuiFunction.AddEdit("xp+60 yp-3 w86 right Hidden", 0)
    ogTxtControl := oGuiFunction.AddText("xm+2 y+6 ", "Control")
    ogTxtControl.posRef := ogTxtVar2
    ogTxtControl.yMargin := 10

    ogEdtControl := oGuiFunction.AddEdit("yp-3 x60 w237 right", )
    ogEdtControl.posRef := ogEdtVar2
    ogEdtControl.yMargin := 2

    ogTxtWindow := oGuiFunction.AddText("xm+2 y+6 ", "Window")
    ogTxtWindow.posRef := ogTxtControl
    ogTxtWindow.yMargin := 10

    ogEdtWindow := oGuiFunction.AddEdit("yp-3 x60 w237 right", "")
    ogEdtWindow.posRef := ogEdtControl
    ogEdtWindow.yMargin := 2

    ogGbResult := oGuiFunction.Add("GroupBox", "xm+3 w294 h40 Section Hidden", "Result")
    ogGbResult.posRef := ogEdtWindow
    ogGbResult.yMargin := 3
    ogEdtResult := oGuiFunction.AddEdit("xs+3 ys+15 w288 r1 Hidden +Multi -VScroll", "")
    ogEdtResult.posRef := ogGbResult
    ogEdtResult.yOffset := 15

    ogGbMsgList := oGuiFunction.Add("GroupBox", "xm+3 w294 h245 Section Hidden", "MsgList")
    ogGbMsgList.posRef := ogGbResult
    ogGbMsgList.yMargin := 2
    ogEdtSearch := oGuiFunction.AddEdit("xs+10 ys+15 Hidden", "")
    ogEdtSearch.posRef := ogGbMsgList
    ogEdtSearch.yOffset := 15
    ogEdtSearch.SetCueText("Search")
    ogEdtSearch.OnEvent("Change",UpdateLVMessages)
    ogLvMessages := oGuiFunction.Add("ListView", "w280 r10 Hidden", ["Message","Value"])
    ogLvMessages.posRef := ogEdtSearch
    ogLvMessages.yMargin := 4
    UpdateLVMessages()
    ogLvMessages.OnEvent("Click", DClickMsgList)


    ; ProcessList Section

    oGuiProcessList.posRef := oGuiWindow
    oGuiProcessList.posRule := "Xxw Yy" 
    ogGBProcessList := oGuiProcessList.addGroupBox("h311","ProcessList")
    ogGBProcessList.LeftMargin := 2
    ogGBProcessList.BottomMargin := 2
    oGuiProcessList.LeftDistance := 0
    oGuiProcessList.HeigthMultiplier := 0.3

    ogEdit_Process_search := oGuiProcessList.AddEdit("xp+4 yp+15 w200 vProcess_seach")
    ogEdit_Process_search.SetCueText("Search")
    ogEdit_Process_search.statusbar := "Type to filter the Processes on specific words"
    ogEdit_Process_search.OnEvent("Change",UpdateProcessList)

    ogLV_ProcessList := oGuiProcessList.AddListView("xm+4 y+2 r14 w" (myGui.Width - 8 * 3) / 2 " vProcessList section AltSubmit", ["Process", "PID","Path"])
    ogLV_ProcessList.Opt("Count400 -Multi")
    ogLV_ProcessList.ModifyCol()
    ogLV_ProcessList.ModifyCol(1, 300)
    ogLV_ProcessList.ModifyCol(2, 100)
    ogLV_ProcessList.ModifyCol(2, "Integer")

    ogLV_ProcessList.OnEvent("Click", DClickProcessList)
    ogLV_ProcessList.OnNotify(NM_RCLICK := -5, RClickProcessList)
    ogLV_ProcessList.LeftMargin := 5
    ogLV_ProcessList.BottomMargin := 8
    UpdateProcessList()

    ; WinList Section
    oGuiWindowList.posRef := oGuiProcessList
    oGuiWindowList.posRule := "Xx Yyh Ww"
    ogGBWinList := oGuiWindowList.addGroupBox("h311","WinList")
    ogGBWinList.LeftMargin := 2
    ogGBWinList.BottomMargin := 2
    oGuiWindowList.LeftDistance := 0
    oGuiWindowList.HeigthMultiplier := 0.3

    ogEdit_win_search := oGuiWindowList.AddEdit("xp+4 yp+15 w200 vwin_seach")
    ogEdit_win_search.SetCueText("Search")
    ogEdit_win_search.statusbar := "Type to filter the windows on specific words"
    ogEdit_win_search.OnEvent("Change",UpdateWinList)
    ogCB_FilterWinVisible := oGuiWindowList.AddCheckbox("xp+210 yp+3 vfilter_win_visible Checked", "Visible") 
    ogCB_FilterWinVisible.OnEvent("Click",UpdateWinList)
    ogCB_FilterWinVisible.Statusbar := "Filter on only visible windows"
    ogCB_FilterWinTitle := oGuiWindowList.AddCheckbox("xp+60 yp vfilter_win_title Checked", "Title")
    ogCB_FilterWinTitle.OnEvent("Click", UpdateWinList)
    ogCB_FilterWinTitle.Statusbar := "Filter on windows with a title"
    ogCB_FilterWinPID := oGuiWindowList.AddCheckbox("xp+60 yp vfilter_win_PID", "Process PID") 
    ogCB_FilterWinPID.OnEvent("Click", UpdateWinList)
    ogCB_FilterWinPID.Statusbar := "Filter on by selected PID in ProcessList"
    ogLV_WinList := oGuiWindowList.AddListView("xm+4 y+7 r14 w" (myGui.Width - 8 * 3) / 2 " vWinList section AltSubmit", ["Title", "Process", "ID", "Visible", "X", "Y", "W", "H", "Class"])
    ogLV_WinList.Opt("Count400 -Multi")

    ogLV_WinList.ModifyCol()
    ogLV_WinList.ModifyCol(1, 300)
    ogLV_WinList.ModifyCol(2, 100)
    ogLV_WinList.ModifyCol(3, 60)
    ogLV_WinList.ModifyCol(4, 50)
    ogLV_WinList.ModifyCol(3, "Integer")
    ogLV_WinList.ModifyCol(4, "SortDesc")

    ogLV_WinList.OnEvent("Click", DClickWinList)
    ogLV_WinList.OnNotify(NM_RCLICK := -5, RClickWinList)
    ogLV_WinList.LeftMargin := 5
    ogLV_WinList.BottomMargin := 8

    ; ControlList Section

    oGuiControlList.posRef := oGuiWindowList
    oGuiControlList.posRule := "Xx Yyh Ww"
    oGuiControlList.LeftDistance := 0
    oGuiControlList.BottomDistance := 0
    ogGBControlList := oGuiControlList.addGroupBox(, "ControlList")
    ogGBControlList.LeftMargin := 2
    ogGBControlList.BottomMargin := 24

    ogEdit_ctrl_search := oGuiControlList.AddEdit("xp+4 yp+15 w200 vctrl_search")
    ogEdit_ctrl_search.SetCueText("Search")
    ogEdit_ctrl_search.OnEvent("Change", UpdateCtrlList)
    ogEdit_ctrl_search.statusbar := "Type to filter the controls on specific words"

    ogCB_FilterCtrlVisible := oGuiControlList.AddCheckbox("xp+210 yp+3 vfilter_ctrl_visible", "Visible")
    ogCB_FilterCtrlVisible.OnEvent("Click", UpdateCtrlList)
    ogCB_FilterCtrlVisible.Statusbar := "Filter on only visible controls"

    ogCB_FilterCtrlText := oGuiControlList.AddCheckbox("xp+60 yp vfilter_ctrl_text", "Text visible") 
    ogCB_FilterCtrlText.OnEvent("Click", UpdateCtrlList)
    ogCB_FilterCtrlText.statusbar := "Filter on controls with text"
    ogLV_CtrlList := oGuiControlList.AddListView("xm+4 y+7 r15 w" (myGui.Width-8*3)/2 " vCtrlList section AltSubmit", ["Class(NN)", "Hwnd", "Text", "Type", "X", "Y", "W", "H","Visible"])
    ogLV_CtrlList.Opt("Count100 -Multi")
    ogLV_CtrlList.OnEvent("Click", DClickCtrlList)
    ogLV_CtrlList.OnNotify(NM_RCLICK := -5, RClickCtrlList)
    ogLV_CtrlList.LeftMargin := 5
    ogLV_CtrlList.BottomMargin := 28


    ; Menu definitions
    SettingsMenu := Menu()
    SettingsMenu.Add("Resize", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinResize:= !oSet.WinResize, oSet.WinResize ? myGui.Opt("+Resize") :  myGui.Opt("-Resize")))
    oSet.WinResize=1 ? SettingsMenu.Check("Resize") : ""
    SettingsMenu.Add("AlwaysOnTop", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.WinAlwaysOnTop:= !oSet.WinAlwaysOnTop, oSet.WinAlwaysOnTop ? myGui.Opt("+AlwaysOnTop") :  myGui.Opt("-AlwaysOnTop")))
    oSet.WinAlwaysOnTop=1 ? SettingsMenu.Check("AlwaysOnTop") : ""
    SettingsMenu.Add("ID Hex", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.IDHex:= !oSet.IDHex))
    oSet.IDHex=1 ? SettingsMenu.Check("ID Hex") : ""
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

    HelpMenu := Menu()
    HelpMenu.Add("Report Issue", (*)=>Run("https://github.com/dmtr99/wInspector/issues/new"))
    HelpMenu.Add("Open Github", (*)=>Run("https://github.com/dmtr99/wInspector"))
    HelpMenu.Add()
    HelpMenu.Add("About wInspector",(*)=>(Gui_About()))

    Menus := MenuBar()
    Menus.Add("&Settings", SettingsMenu)
    Menus.Add("&Help", HelpMenu)
    Menus.Add( "&Reload", (*) => (Gui_Close(myGui), Reload()))
    MyGui.MenuBar := Menus

    ; Toolbar
    oToolbar := Toolbar("Flat List Tooltips +0x2")

    oTbWindow := oToolbar.Add("", "Window", (*) => (ToggleSection("Window")), "shell32.dll", 3)
    oTbControl := oToolbar.Add("", "Control", (*) => (ToggleSection("Control")), "shell32.dll", 134)
    oTbAcc := oToolbar.Add("", "Acc", (*) => (ToggleSection("Acc")), "shell32.dll", 85)
    oTbMouse := oToolbar.Add("", "Mouse", (*) => (ToggleSection("Mouse")), "ddores.dll", 30)
    oTbFunction := oToolbar.Add("", "Function", (*) => (ToggleSection("Function")), "shell32.dll", 25)
    oToolbar.Add()
    oTbProcessList := oToolbar.Add("", "ProcessList", (*) => (ToggleSection("ProcessList")), "shell32.dll", 13)
    oTbWindowList := oToolbar.Add("", "WindowList", (*) => (ToggleSection("WindowList")), "shell32.dll", 3)
    oTbControlList := oToolbar.Add("", "ControlList", (*) => (ToggleSection("ControlList")), "shell32.dll", 96)

    for Section in ["Window","Control","Acc","Mouse","Function","ProcessList","WindowList","ControlList"]{
        oTb%Section%.Styles := "Check"
        SectionTitle := oGui%Section%.Title
        (oSet.Sect%SectionTitle% = 1 && oTb%Section%.States := "Checked")
    }

    AddToolbar(oToolbar, MyGui, "0x2", "x30 y1 h24")

    ; Create a Status Bar to give info about the number of files and their total size:
    SB := MyGui.Add("StatusBar")
    MyGui.OnEvent("Size",Gui_Size)
    MyGui.OnEvent("Close",Gui_Close)

ControlGetPos( , , , &ToolbarHeight, oToolbar)
    for index, oSection in myGui.aSections {
        SectionTitle := oSection.Title
        ; Show the sections
        ; oSection.Show("x0 y24")
        oSection.Show("x0 y" ToolbarHeight)
        (oSet.Sect%SectionTitle% = 0 && oSection.Visible := 0)
    }

    UpdateWinList()
    MyGui.Show("x" oSet.WinX " y" oSet.WinY " w" oSet.WinW " h" oSet.WinH)

    GroupBoxAutosize(ogGB_Mouse)
    GroupBoxAutosize(ogGB_Acc)
    UpdateFunctionControls()
    SectionCorrections()
    Gui_Size(MyGui)

    ; Reset Cursor in case previous script gave error
    SetSystemCursor("Default")
    OnMessage(WM_LBUTTONDOWN := 0x0201, CheckButtonClick)
    OnMessage(0x200, WM_MOUSEMOVE)
}

~LButton::{
    if (isSet(GuiBox) and !WinActive("wInspector")){
        GuiBox.hide()
    }
}

ToggleSection(SectionTitle){
    oSet.Sect%SectionTitle% := !oSet.Sect%SectionTitle%
    oGui%SectionTitle%.Visible := oSet.Sect%SectionTitle%
    INI_File := Regexreplace(A_scriptName, "(.*)\..*", "$1.ini")
    IniWrite(oSet.Sect%SectionTitle%, INI_File, "MainGui", "Sect" SectionTitle)
    SectionCorrections() 
    ; GuiUpdate()
    Gui_Size(MyGui)
    return
}

^i::
{
    MouseGetPos(&MouseX, &MouseY, &MouseWinHwnd, &MouseControlHwnd, 2)

    Gui_wInspector()
    SetSelectedWindow(MouseWinHwnd)
    SetSelectedControl(MouseControlHwnd)
    SetSelectedMouse(MouseX, MouseY)
    SetSelectedMouseGrid(MouseX, MouseY)
    UpdateProcessList()
    UpdateWinList()
    UpdateCtrlList()
    return
}

CheckButtonClick(wParam :=0, lParam := 0, msg := 0, hwnd := 0){
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
	MyGui.PID := WinGetPID(MouseWinHwnd)
        SetSelectedWindow(MouseWinHwnd)
        SetSelectedControl(MouseControlHwnd)
        UpdateProcessList()
        UpdateWinList()
        UpdateCtrlList()
        ogButton_Selector.text := "+"
        SetSystemCursor("Default")
        SetSelectedMouseGrid(MouseX, MouseY)
        if (oGuiAcc.Visible){
            ; MsgBox("Text")
            oAccp := Acc.ObjectFromPoint(MouseX, MouseY)
            ogLV_AccProps.Delete()
            Location := { x: 0, y: 0, w: 0, h: 0 }, RoleText := "", Role := "", Value := "", Name := "", StateText := "", State := "", DefaultAction := "", Description := "", KeyboardShortcut := "", Help := "", ChildId := ""
            for _, v in ["RoleText", "Role", "Value", "Name", "Location", "StateText", "State", "DefaultAction", "Description", "KeyboardShortcut", "Help", "ChildId"] {
                try %v% := oAccp.%v%
                ogLV_AccProps.Add(, v, v = "Location" ? ("x: " %v%.x " y: " %v%.y " w: " %v%.w " h: " %v%.h) : %v%)
            }
        }
        
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
    MyGui.win_hwnd := ogLV_WinList.GetText(ogLV_WinList.GetNext(), 3)
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
    ogEdit_wPID.text := format("{:#x}",WinGetPID(win_id))
    Win_Transparent := WinGetTransparent(win_id)
    ogSlider_Transparent.value := Win_Transparent="" ? 255 : Win_Transparent
    WinGetClientPos(&win_x, &win_y, &win_w, &win_h, win_id)
    ogEdit_wXPos.value := win_x
    ogEdit_wYPos.value := win_y
    ogEdit_wWidth.value := win_w
    ogEdit_wHeight.value := win_h

    ogEdtWindow.text := (oSet.WindowPar = "Class") ? "ahk_class " WinGetClass(win_id) : (oSet.WindowPar = "hwnd") ? "ahk_id " win_id : (oSet.WindowPar = "Process") ? "ahk_exe " WinGetProcessName(win_id) : WinGetTitle(win_id)
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
    Grid := oGuiMouse.Grid
    pBitmap := Gdip_BitmapFromScreen(MouseX - (Grid-1)/2 "|" MouseY -(Grid - 1) / 2 "|" Grid "|" Grid)
    hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)

    SetImage(ogPic_Grid.hwnd, hBitmap)
    Gdip_DisposeImage(pBitmap)

    ogText_Line1.Redraw()
    ogText_Line2.Redraw()
    ogText_Line3.Redraw()
    ogText_Line4.Redraw()
    if (oGuiMouse.Visible){
        oGuiMouse.Show("AutoSize")
    }

    WinRedraw(oGuiMouse)
}

RClickAccList(*){
    if ogLV_AccProps.GetNext(, "F") = 0 {
        return
    }
    Property := ogLV_AccProps.GetText(ogLV_AccProps.GetNext(, "F"), 1)
    Value := ogLV_AccProps.GetText(ogLV_AccProps.GetNext(, "F"), 2)
    myMenu := Menu()
    if (Value!=""){
        myMenu.Add("Copy " Property, (*) => (A_Clipboard := Value, Tooltip2("Copied [" A_Clipboard "]")))
        myMenu.SetIcon("Copy " Property, "shell32.dll", 135)
    }
    myMenu.Show()
}

RClickProcessList(*){
    if ogLV_ProcessList.GetNext(, "F") = 0 {
        return
    }
    Process := ogLV_ProcessList.GetText(ogLV_ProcessList.GetNext(, "F"), 1)
    Process_PID := ogLV_ProcessList.GetText(ogLV_ProcessList.GetNext(, "F"), 2)
    Process_Path := ogLV_ProcessList.GetText(ogLV_ProcessList.GetNext(, "F"), 3)

    myMenu := Menu()
    myMenu.Add("Copy Process", (*) => (A_Clipboard := Process, Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.SetIcon("Copy Process", "shell32.dll", 135)
    myMenu.Add("Copy ProcessPath", (*) => (A_Clipboard := Process_Path, Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.SetIcon("Copy ProcessPath", "shell32.dll", 135)
    myMenu.Add()
    myMenu.Add("ProcessClose", (*) => (ProcessClose(Process_PID),UpdateProcessList(), Tooltip2("ProcessClose(" Process_PID ")")))
    myMenu.SetIcon("ProcessClose", "shell32.dll", 132)
    ; Disable the closing of known critical processes.
    if (process~="i)NTOSKrnl.exe|SMSS.exe|CSRSS.exe|WinLogon.exe|WinInit.exe|LogonUI.exe|lsass.exe|Services.exe|svchost.exe|DWM.exe"){
        myMenu.Disable("ProcessClose")
    }
    myMenu.Show()
}

RClickWinList(*){
    if ogLV_WinList.GetNext(, "F") = 0 {
        return
    }
    win_hwnd := GetSelectedWindow()
    State_AlwaysOnTop := WinGetExStyle('ahk_id ' win_hwnd) & 0x8

    myMenu := Menu()
    myMenu.Add("Copy Title", (*) => (A_Clipboard := WinGetTitle('ahk_id ' win_hwnd), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.SetIcon("Copy Title", "shell32.dll", 135)
    myMenu.Add("Copy Process", (*) => (A_Clipboard := WinGetProcessName('ahk_id ' win_hwnd), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.SetIcon("Copy Process", "shell32.dll", 135)
    myMenu.Add("Copy ProcessPath", (*) => (A_Clipboard := WinGetProcessPath('ahk_id ' win_hwnd), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.SetIcon("Copy ProcessPath", "shell32.dll", 135)
    myMenu.Add("Copy WinClass", (*) => (A_Clipboard := WinGetClass('ahk_id ' win_hwnd), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.SetIcon("Copy WinClass", "shell32.dll", 135)
    myMenu.Add("Styles", (*) => (GuiStyles_Create(win_hwnd, "Window")))
    myMenu.Add("Acc Viewer", (*) => (GuiAccViewer("ahk_id " win_hwnd)))
    myMenu.SetIcon("Acc Viewer", "shell32.dll", 85)
    myMenu.Add()
    myMenu.Add("Activate", (*) => (WinActivate("ahk_id " win_hwnd), Tooltip2("WinActivate('ahk_id '" win_hwnd ")")))
    myMenu.Add("AlwaysOnTop", (*) => (WinSetAlwaysOnTop(!State_AlwaysOnTop,"ahk_id " win_hwnd), Tooltip2('WinSetAlwaysOnTop(' State_AlwaysOnTop '", ahk_id "' win_hwnd ')')))
    if (State_AlwaysOnTop){
        myMenu.Check("AlwaysOnTop")
    }
   
    if( WinGetStyle("ahk_id " win_hwnd) & 0x10000000){
        myMenu.Add("Visible", (*) => (WinHide("ahk_id " win_hwnd),UpdateWinList(), Tooltip2("WinHide('ahk_id '" win_hwnd ")")))
        myMenu.Check("Visible")
    } else{
        myMenu.Add("Visible", (*) => (WinShow("ahk_id " win_hwnd),UpdateWinList(), Tooltip2("WinHide('ahk_id '" win_hwnd ")")))
    }
    myMenu.Add("Close", (*) => (WinClose("ahk_id " win_hwnd), UpdateWinList(), Tooltip2("WinClose('ahk_id '" win_hwnd ")")))
    myMenu.SetIcon("Close", "shell32.dll", 132)
    ; myMenu.Add("GetPID", (*) => (Tooltip2(WinGetPID("ahk_id " win_hwnd))))
    
    myMenu.Show()
}

RClickCtrlList(*){
    win_hwnd := GetSelectedWindow()
    if ogLV_CtrlList.GetNext(, "F")=0{
        return
    }
    MyGui.ctrl_hwnd := ogLV_CtrlList.GetText(ogLV_CtrlList.GetNext(, "F"), 2) + 0
    ctrl_ClassNN := ControlGetClassNN(MyGui.ctrl_hwnd + 0)
    Ctrl_Visible := ControlGetVisible(MyGui.ctrl_hwnd+0)
    Ctrl_Enabled := ControlGetEnabled(MyGui.ctrl_hwnd+0)
    ObjectType := ControlGetType(MyGui.ctrl_hwnd + 0)
    myMenu := Menu()
    myMenu.Add("Copy Text", (*) => (A_Clipboard:= ControlGetText(MyGui.ctrl_hwnd+0), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.SetIcon("Copy Text", "shell32.dll", 135)
    myMenu.Add("Copy ClassNN", (*) => (A_Clipboard:= ControlGetClassNN(MyGui.ctrl_hwnd+0), Tooltip2("Copied [" A_Clipboard "]")))
    myMenu.SetIcon("Copy ClassNN", "shell32.dll", 135)
    if (InStr(ctrl_ClassNN,"Listview")){
        myMenu.Add("Copy ListViewGetContent", (*) => (A_Clipboard:= ListViewGetContent(,MyGui.ctrl_hwnd+0), Tooltip2("Copied [" A_Clipboard "]")))
    }
    myMenu.Add("Styles", (*) => (GuiStyles_Create(MyGui.ctrl_hwnd, ObjectType)))
    myMenu.Add("Acc Viewer", (*) => (GuiAccViewer("ahk_id " win_hwnd, MyGui.ctrl_hwnd)))
    myMenu.SetIcon("Acc Viewer", "shell32.dll", 85)
    myMenu.Add()
    myMenu.Add("SendMessage", (*) => (SendMessage( 0x0115, 0, 0, ogEdit_cClass.text, MyGui.win_hwnd )))
    myMenu.Add("ControlClick", (*) => (ControlClick(ogEdit_cClass.text, MyGui.win_hwnd), Tooltip2("ControlClick(" MyGui.win_hwnd ")")))
    myMenu.SetIcon("ControlClick", "shell32.dll", 101)
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

DClickProcessList(LV,RowNumber){
    if (RowNumber = 0) {
        return
    }
    MyGui.PID := ogLV_ProcessList.GetText(ogLV_ProcessList.GetNext(, "F"), 2) + 0
    PID := MyGui.PID+0
    if (ogCB_FilterWinPID.value=1){
        UpdateWinList()
    }
        
}

DClickWinList(LV,RowNumber) {
    if (RowNumber = 0) {
        return
    }
    MyGui.win_hwnd := ogLV_WinList.GetText(ogLV_WinList.GetNext(, "F"), 3) + 0
    win_hwnd := MyGui.win_hwnd+0

    if !WinExist("ahk_id " win_hwnd){
        (IsSet(GuiBox) && WinExist(GuiBox) && GuiBox.Hide())
        UpdateWinList()
        UpdateProcessList()
        UpdateCtrlList()
        return
    }

    winPID := MyGui.win_hwnd !=0 and WinExist("ahk_id " MyGui.win_hwnd) ? WinGetPID("ahk_id " MyGui.win_hwnd) : 0
    Loop ogLV_ProcessList.GetCount()
    {
        rowPID := ogLV_ProcessList.GetText(A_Index, 2)
        if (rowPID = winPID)
            ogLV_ProcessList.Modify(A_Index, "Select Vis")
    }

    SetSelectedWindow(win_hwnd)
    UpdateCtrlList()
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

DClickCtrlList(LV, RowNumber){
    if (RowNumber=0){
        return
    }
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
    WinMoveTop("ahk_id " win_hwnd)
}


SectionCorrections(){
    myGui.GetPos(&xWin,&yWin,&wWin,&hWin)
    WinGetClientPos(&XcmyGui, &YcmyGui, &WcmyGui, &HcmyGui, myGui)
    ScreenScale := A_ScreenDPI / 96
    HcmyGui := HcmyGui/ScreenScale
    WcmyGui := WcmyGui/ScreenScale
    if (oSet.SectWindowList|oSet.SectControlList){
        oGuiProcessList.BottomDistance := ""
        ogGBProcessList.BottomMargin := 2
        ogLV_ProcessList.BottomMargin := 8
    } else{
        oGuiProcessList.BottomDistance := 24
        ogGBProcessList.BottomMargin := 24
        ogLV_ProcessList.BottomMargin := 28
        oGuiProcessList.HeigthMultiplier := ""
    }
    if (oSet.SectControlList){
        oGuiWindowList.BottomDistance := ""
        ogGBWinList.BottomMargin := 2
        ogLV_WinList.BottomMargin := 8
    } else {
        oGuiWindowList.BottomDistance := 24
        ogGBWinList.BottomMargin := 24
        ogLV_WinList.BottomMargin := 28
        oGuiWindowList.HeigthMultiplier := ""
    }
    if (oSet.SectProcessList && oSet.SectWindowList && oSet.SectControlList){
        ControlMove(, , ,HcmyGui/3,oGuiProcessList)
        ControlMove(, , ,HcmyGui/3,oGuiWindowList)
        ; oGuiProcessList.move(,,,HcmyGui/3)
        ; oGuiWindowList.move(,,,HcmyGui/3)
        oGuiProcessList.HeigthMultiplier := 0.3
        oGuiWindowList.HeigthMultiplier := 0.3
        
    } else if (!oSet.SectProcessList && oSet.SectWindowList && oSet.SectControlList){
        oGuiWindowList.move(,,,HcmyGui/2)
        oGuiWindowList.HeigthMultiplier := 0.4
    } else if (oSet.SectProcessList && (oSet.SectWindowList | oSet.SectControlList)){
        oGuiProcessList.move(,,,HcmyGui/2)
        oGuiProcessList.HeigthMultiplier := 0.4
    }
    if((oSet.SectProcessList | oSet.SectWindowList | oSet.SectControlList) and wWin <700){
        MyGui.move(,,700)
    }
    
    if (!oSet.SectWindowList && !oSet.SectControlList  && !oSet.SectProcessList){
        MyGui.move(,,320)
    }
    GroupBoxAutosize(ogGB_Acc)
    GroupBoxAutosize(ogGB_Mouse)
    GroupBoxAutosize(ogGBFunction)
    GuiUpdate()
    Gui_Size(myGui)
    WinRedraw(myGui)
}

Gui_Autosize(){
    WinGetPos(&XmyGui, &YmyGui, &WmyGui, &HmyGui, myGui)
    maxHeight := 0
    For Hwnd, ogSection in myGui.aSections {
        if (ogSection.Visible) {
            WinGetPos(&XSection, &YSection, &WSection, &HSection, ogSection)
            WinGetClientPos(&XcSection, &YcSection, &WcSection, &HcSection, ogSection)
            maxHeight := Max(maxHeight, (YcSection + HcSection) - YmyGui + 30)
        }
    }
    MyGui.move(, , , maxHeight)
}

UpdateProcessList(p*){
    ogLV_ProcessList.Delete()
    
    ogLV_ProcessList.Opt("-Redraw")
    oProcessList := ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")

    winPID := MyGui.win_hwnd !=0 and WinExist("ahk_id " MyGui.win_hwnd) ? WinGetPID("ahk_id " MyGui.win_hwnd) : 0
    index:=0
    for oProcess in oProcessList{
        index++
    }
    static ImageProcessList := IL_Create(index+1)
    static mapIL := Map()
    ogLV_ProcessList.SetImageList(ImageProcessList)
    IconIndex1 := IL_Add(ImageProcessList, "shell32.dll", 50) ; add empty image
    for oProcess in oProcessList
    {
        
        if (ogEdit_Process_search.value="" or InStrSuffled(oProcess.Name oProcess.ExecutablePath,ogEdit_Process_search.value)){
            if (mapIL.Has(oProcess.Name)){
                IconIndex := mapIL[oProcess.Name]
            } else{
                ;ProcessHIcon := WinGetHIcon(oProcess.Handle)
                if (oProcess.ExecutablePath = "") {
                    mapIL[oProcess.Name] := 1
                } else{
                    mapIL[oProcess.Name] := IL_Add(ImageProcessList, oProcess.ExecutablePath)
                }
            }
            
            ; NewRowNumber :=ogLV_ProcessList.Add("Icon" mapIL[oProcess.Name], win_title, win_process, format("{:#x}", win_id), win_visible, win_x, win_y, win_w, win_h)
            NewRowNumber :=ogLV_ProcessList.Add("Icon" mapIL[oProcess.Name], oProcess.Name, oSet.IDHex ? format("{:#x}", oProcess.Handle) : oProcess.Handle, oProcess.ExecutablePath)
            if(oProcess.Handle = winPID){
                ogLV_ProcessList.Modify(NewRowNumber, "Select Vis")
            }
        }
    }
    ogLV_ProcessList.ModifyCol(1)
    ogLV_ProcessList.ModifyCol(2)
    ogLV_ProcessList.ModifyCol(3)
    ogLV_ProcessList.Opt("+Redraw")
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
    IconIndex1 := IL_Add(ImageWinList, "shell32.dll", 3)
    for win_id in oWinList
    {
        win_class := WinGetClass(win_id)
        win_title := WinGetTitle(win_id)
        win_process := ""
        try win_process := WinGetProcessName(win_id) ; Seems to fail in some situations
        win_PID := WinGetPID(win_id)
        WinGetClientPos(&win_x, &win_y, &win_w, &win_h, win_id)
        
        win_visible := WinGetStyle(win_id) & 0x10000000 "" ? "Visible" : "Hidden"
        if (ogCB_FilterWinTitle.value=1 and win_title=""){
            continue
        }
        if (ogCB_FilterWinPID.value=1 and MyGui.PID != "" and MyGui.PID != win_PID+0){
            continue
        }
        if (ogEdit_win_search.value="" or InStrSuffled(win_title " " win_process " " (oSet.IDHex ? format("{:#x}", win_PID) : win_PID),ogEdit_win_search.value)){
            if (mapIL.Has(win_id)){
                IconIndex := mapIL[win_id]
            } else{
                WinHIcon := WinGetHIcon(win_id)
                if (WinHIcon != 0) {
                    mapIL[win_id] := IL_Add(ImageWinList, "HICON:" WinHIcon)
                } else{
                    ProcessPath := ""
                    try ProcessPath := WinGetProcessPath(win_id)
                    mapIL[win_id] := IL_Add(ImageWinList, ProcessPath)
                }
            }
            
            NewRowNumber :=ogLV_WinList.Add("Icon" mapIL[win_id], win_title, win_process, oSet.IDHex ? format("{:#x}", win_id) : win_id, win_visible, win_x, win_y, win_w, win_h, win_class)
            if(win_id = MyGui.win_hwnd){
                ogLV_WinList.Modify(NewRowNumber, "Select Vis")
            }
        }
    }
    
    ogLV_WinList.ModifyCol(5)
    ogLV_WinList.ModifyCol(6)
    ogLV_WinList.ModifyCol(7)
    ogLV_WinList.ModifyCol(8)
    ogLV_WinList.ModifyCol(9)
    ogLV_WinList.Opt("+Redraw")

}

UpdateCtrlList(*){
    ;IconLib
    ogLV_CtrlList.Delete()
    ogLV_CtrlList.SetImageList(ImageCtrlList)

    win_hwnd := MyGui.win_hwnd
    ogLV_CtrlList.Opt("-Redraw")
    selectedCtrl_hwnd := MyGui.ctrl_hwnd
    if WinExist("ahk_id " win_hwnd){
        for n, ctrl_hwnd in WinGetControlsHwnd("ahk_id " win_hwnd){
            if (A_Index=1){
                Hwnd_selected := ctrl_hwnd
            }
            ctrl_text := ControlGetText(ctrl_hwnd)
            ControlGetPos(&ctrl_x, &ctrl_y, &ctrl_w, &ctrl_h, ctrl_hwnd)
            ctrl_ClassNN := ControlGetClassNN(ctrl_hwnd)
            ; ctrl_AhkName := TranslateClassName(ctrl_ClassNN)
            ; ControlType := ControlGetStyle(ctrl_hwnd) & 0xF

            ctrl_Type := ControlGetType(ctrl_hwnd)
            
            ctrl_Visible := ControlGetVisible(ctrl_hwnd)
            if ((ogCB_FilterCtrlText.value = 1 and ctrl_text = "") or (ogCB_FilterCtrlVisible.value = 1 and !ctrl_Visible)){
                 continue
            }
            if (ogEdit_ctrl_search.value="" or InStrSuffled(ctrl_ClassNN " " ctrl_hwnd " " ctrl_text,ogEdit_ctrl_search.value)){
                NewRowNumber:= ogLV_CtrlList.Add((mILControls.Has(ctrl_Type) ? "Icon" mILControls[ctrl_Type] : "" ) , ctrl_ClassNN, oSet.IDHex ? format("{:#x}", ctrl_hwnd) : ctrl_hwnd, ctrl_text, ctrl_Type, ctrl_x, ctrl_y, ctrl_w, ctrl_h, ctrl_Visible ? "Visible" : "Hidden")
                if (selectedCtrl_hwnd=ctrl_hwnd){
                    ogLV_CtrlList.Modify(NewRowNumber, "Select Vis")
                }
            }
        }
    }
    ; 
    ;SetSelectedControl(isSet(Hwnd_selected) ? Hwnd_selected : "")
    ogLV_CtrlList.ModifyCol()
    ogLV_CtrlList.ModifyCol(3,200)
    ogLV_CtrlList.Opt("+Redraw")
}

GridSize_Change(*){
    mGrid := [0, 3, 5, 9, 15]
    oGuiMouse.Grid := mGrid[ogDDL_GridSize.value]
    oSet.MouseGrid := (oGuiMouse.Grid=0) ? 1 : oGuiMouse.Grid
    ogPic_Grid.Move(,,oGuiMouse.Grid * 16, oGuiMouse.Grid * 16)
    ogPic_Grid.GetPos(&cx,&cy,&cw,&ch)
    ogText_Line1.Move(cx+ (oGuiMouse.Grid - 1) * 16 / 2, cy+1 ,1, oGuiMouse.Grid * 16 - 2 )
    ogText_Line2.Move(cx+ (oGuiMouse.Grid + 1) * 16 / 2, cy+1, 1, oGuiMouse.Grid * 16 - 2 )
    ogText_Line3.Move(cx+1, cy+ (oGuiMouse.Grid - 1) * 16 / 2, oGuiMouse.Grid * 16 - 2 )
    ogText_Line4.Move(cx+1, cy+ (oGuiMouse.Grid + 1) * 16 / 2, oGuiMouse.Grid * 16 - 2)
    aControls := [ogPic_Grid,ogText_Line1,ogText_Line2,ogText_Line3,ogText_Line4]
    for oControl in aControls{
        oControl.visible := (oGuiMouse.Grid = 0) ? false : true
    }
    GroupBoxAutosize(ogGB_Mouse)
    Gui_Size(myGui)
    Gui_Autosize()
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
            ScreenScale := A_ScreenDPI / 96
            if (posRule = "Xx Yyh Ww"){
                ogSection.move((X2 - XcmyGui)/ScreenScale, (H2 + Y2 - YcmyGui)/ScreenScale,W2/ScreenScale)
            } else if (posRule = "Xxw Yy"){
                ogSection.move((X2 - XcmyGui+W2)/ScreenScale, (Y2 - YcmyGui)/ScreenScale)
            } else if (posRule = "Xx Yy"){
                ogSection.move((X2 - XcmyGui)/ScreenScale, (Y2 - YcmyGui)/ScreenScale)
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
GuiSection_Size(thisGui, MinMax:=1, Width:="", Height:= "") {
    if MinMax = -1	; The window has been minimized. No action needed.
        return
    ;DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
    (Width="" && WinGetPos(, , &Width, &Height, thisGui)) ; autocollect missing parameters

    For Hwnd, GuiCtrlObj in thisGui {
        GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
        if (GuiCtrlObj.HasProp("LeftMargin") && GuiCtrlObj.LeftMargin!="") {
            GuiCtrlObj.Move(, , Width - cX - GuiCtrlObj.LeftMargin, )
        }
        if (GuiCtrlObj.HasProp("LeftDistance") && GuiCtrlObj.LeftDistance!="") {
            GuiCtrlObj.Move(Width - cWidth - GuiCtrlObj.LeftDistance, , , )
        }
        if (GuiCtrlObj.HasProp("BottomDistance") && GuiCtrlObj.BottomDistance!="") {
            GuiCtrlObj.Move(, Height - cHeight - GuiCtrlObj.BottomDistance, , )
        }
        if (GuiCtrlObj.HasProp("BottomMargin") && GuiCtrlObj.BottomMargin!="") {
            GuiCtrlObj.Move(, , , Height - cY - GuiCtrlObj.BottomMargin)
        }
        if (GuiCtrlObj.HasProp("PosRef") && GuiCtrlObj.PosRef!="") {
            GuiCtrlPosRef := GuiCtrlObj.PosRef
            
            loop{
                if (GuiCtrlPosRef.Visible){
                    break
                } else{
                    if (GuiCtrlPosRef.hasProp("PosRef")){
                        GuiCtrlPosRef := GuiCtrlPosRef.PosRef
                    } else{
                        
                        Break
                    }
                }
            }
            GuiCtrlPosRef.GetPos(&rX, &rY, &rW, &rH)
            if (!GuiCtrlPosRef.Visible){
                GuiCtrlObj.Move(, rY, , )
            }
            else{
                GuiCtrlObj.Move(, rY+(GuiCtrlObj.HasProp("yOffset") ? GuiCtrlObj.yOffset : 0)+(GuiCtrlObj.HasProp("yMargin") ? rH+GuiCtrlObj.yMargin : 0), , )
            }
        }
    }

}

; Automatically change Sections positions
Gui_Size(thisGui, MinMax:=1, Width:= 1, Height:= 1) {
    
    if (WinExist("Highlight")){
        ; Hide the rectangle if window is moved
        WinHide("Highlight")
    }

    if MinMax = -1	; The window has been minimized. No action needed.
        return
    DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)

    WinGetPos(&XmyGui, &YmyGui, &WmyGui, &HmyGui, myGui)
    WinGetClientPos(&XcmyGui, &YcmyGui, &WcmyGui, &HcmyGui, myGui)
    ScreenScale := A_ScreenDPI / 96

    For Hwnd, ogSection in myGui.aSections{
        WinGetPos(&XSection, &YSection, &WSection, &HSection, ogSection)
        WinGetClientPos(&XcSection, &YcSection, &WcSection, &HcSection, ogSection)
        if (ogSection.HasProp("LeftDistance") && ogSection.LeftDistance!=""){
            ogSection.move((XSection - XcmyGui)/ScreenScale, (YSection - YcmyGui)/ScreenScale,((XcmyGui+WcmyGui)-XSection-ogSection.LeftDistance)/ScreenScale)
        }
        if (ogSection.HasProp("BottomDistance") && ogSection.BottomDistance != ""){
            ogSection.move((XSection - XcmyGui)/ScreenScale, (YSection - YcmyGui)/ScreenScale,,(((YcmyGui+HcmyGui)-YcSection)/ScreenScale-ogSection.BottomDistance))
        } else if (ogSection.HasProp("HeigthMultiplier") && ogSection.HeigthMultiplier != ""){
            
            ogSection.move((XSection - XcmyGui)/ScreenScale, (YSection - YcmyGui)/ScreenScale,,(HcmyGui*ogSection.HeigthMultiplier)/ScreenScale)
        }
    }

    DllCall("LockWindowUpdate", "Uint", 0)

    GuiUpdate()
    
}

GuiStyles_Create(hwnd, ObjectType) {
    object_Style := WinGetStyle("ahk_id " hwnd)
    object_ExStyle := WinGetExStyle("ahk_id " hwnd)
    Try{
        Object_ClassNN := ControlGetClassNN(hwnd)
    }Catch{
        Object_ClassNN := WinGetTitle("ahk_id " hwnd)
    }
    
    ObjectType := (ObjectType="Edit" and object_Style & 0x4) ? "editmultiLine" : ObjectType

    if !aoDefaultStyles.HasProp(ObjectType){
        return
    }
    defaultStyle :=aoDefaultStyles.%ObjectType%.style
    defaultExStyle :=aoDefaultStyles.%ObjectType%.exStyle

    GuiStyles := Gui("Resize", "Styles - " Object_ClassNN " - " ObjectType " - " format("0x{:X}",object_Style))
    GuiStyles.OnEvent("Size",GuiSection_Size)
    ogTab := GuiStyles.AddTab3("w400 h400",["Styles","Extended Styles"])
    ogTab.LeftMargin := 10
    ogTab.BottomMargin := 40
    ogEditStyle := GuiStyles.AddEdit("w150",format("0x{:X}", object_Style))
    ogLVStyles := GuiStyles.Add("ListView", " h332 w375 Checked", ["Style", "Hex", "Default","Description"])
    ogLVStyles.LeftMargin := 20
    ogLVStyles.BottomMargin := 50
    ogTab.UseTab("Extended Styles")
    ogEditExStyle := GuiStyles.AddEdit("w150", format("0x{:X}", object_ExStyle))
    ogLVExStyles := GuiStyles.Add("ListView", "h332 w375 Checked", ["Style", "Hex", "Default", "Description"])
    ogLVExStyles.LeftMargin := 20
    ogLVExStyles.BottomMargin := 50
    ogTab.UseTab()
    ogEditOptions := GuiStyles.AddEdit("xm y410 w300")
    ogEditOptions.BottomDistance := 10
    Options := ""
    SkipOptions := "" ;Styles to be skipped because of set options
    aoStyles := (ObjectType = "window") ? aoWinStyles : aoControlStyles

    aoStyles_extra := ""
    aoStyles_extra := (ObjectType = "text") ? aoTextStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Edit") ? aoEditStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "EditMultiline") ? aoEditMultilineStyles : aoStyles_extra
    aoStyles_extra := (ObjectType ~= "Button|CheckBox|Radio|GroupBox") ? aoButtonStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "text") ? aoTextStyles : aoStyles_extra

    aoStyles_extra := (ObjectType = "updown") ? aoUpDownStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "picture") ? aoPicStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Combobox") ? aoCBBStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "DropDownList") ? aoCBBStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "ListBox") ? aoLBStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "ListView") ? aoLVStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "TreeView") ? aoTreeViewStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "DateTime") ? aoDateTimeStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "MonthCal") ? aoMonthCalStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Slider") ? aoSliderStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Progress") ? aoProgressStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Tab3") ? aoTabStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Statusbar") ? aoStatusbarStyles : aoStyles_extra


    ; general style
    for index, oStyle in aoStyles{
        ogLVStyles.Add(((object_Style & oStyle.Hex) ? "Check" : ""),oStyle.Style,oStyle.Hex,(defaultStyle & oStyle.Hex) ? "true" : "false", oStyle.Description)
        ; Options .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " ((defaultStyle & oStyle.Hex) ? "-" : "+") (oStyle.OptionText="" ? oStyle.Hex : oStyle.OptionText) 
        ; SkipOptions .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " (oStyle.SkipHex)
    }

    

    ; object specific styles
    if (aoStyles_extra!=""){
        for index, oStyle in aoStyles_extra{
            ogLVStyles.Add(((object_Style & oStyle.Hex)? "Check" : ""),oStyle.Style,oStyle.Hex,(defaultStyle & oStyle.Hex) ? "true" : "false",oStyle.Description)
            ; Options .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " ((defaultStyle & oStyle.Hex) ? "-" : "+") (oStyle.OptionText="" ? oStyle.Hex : oStyle.OptionText) 
            ; SkipOptions .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " (oStyle.SkipHex)
        }
    }
    
    for index, oExStyle in aoWinExStyles{
        ogLVExStyles.Add(((object_ExStyle & oExStyle.Hex)? "Check" : ""),oExStyle.Style,oExStyle.Hex, (defaultExStyle & oExStyle.Hex) ? "true" : "false",oExStyle.Description)
        ; Options .= (((defaultExStyle & oExStyle.Hex) && (object_ExStyle & oExStyle.Hex)) | (!(defaultExStyle & oExStyle.Hex) && !(object_ExStyle & oExStyle.Hex))) ? "" : " " ((defaultExStyle & oExStyle.Hex) ? "-" : "+") (oExStyle.OptionText="" ? "E" oExStyle.Hex : oExStyle.OptionText) 
        ; SkipOptions .= (((defaultExStyle & oExStyle.Hex) && (object_ExStyle & oExStyle.Hex)) | (!(defaultStyle & oExStyle.Hex) && !(object_ExStyle & oExStyle.Hex))) ? "" : " " (oExStyle.SkipHex)
    }

    ogEditOptions.Value := ControlGetAHKOptions(ObjectType,object_Style,object_ExStyle)
    ogLVStyles.ModifyCol
    ogLVStyles.ModifyCol(2, "Integer")
    ogLVExStyles.ModifyCol
    ogLVExStyles.ModifyCol(2, "Integer")
    
    GuiStyles.Show("")

    ControlGetAHKOptions(ObjectType, object_Style, object_ExStyle){
        Options := ""
        SkipOptions := "" ;Styles to be skipped because of set options
        optionsBuffer := ""
        aoStyles := (ObjectType = "window") ? aoWinStyles : aoControlStyles

        defaultStyle :=aoDefaultStyles.%ObjectType%.style
        defaultExStyle :=aoDefaultStyles.%ObjectType%.exStyle

        if (ObjectType="Checkbox"){
            ; Correction on Check3 Checkbox
            if(object_Style & 0xF== 6){
                optionsBuffer .= "Check3 "
                defaultStyle := 0x50010006
            }
        }

        aoStyles_extra := ""
        aoStyles_extra := (ObjectType = "text") ? aoTextStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "Edit") ? aoEditStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "EditMultiline") ? aoEditMultilineStyles : aoStyles_extra
        aoStyles_extra := (ObjectType ~= "Button|CheckBox|Radio|GroupBox") ? aoButtonStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "text") ? aoTextStyles : aoStyles_extra

        aoStyles_extra := (ObjectType = "updown") ? aoUpDownStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "picture") ? aoPicStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "Combobox") ? aoCBBStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "DropDownList") ? aoCBBStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "ListBox") ? aoLBStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "ListView") ? aoLVStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "TreeView") ? aoTreeViewStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "DateTime") ? aoDateTimeStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "MonthCal") ? aoMonthCalStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "Slider") ? aoSliderStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "Progress") ? aoProgressStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "Tab3") ? aoTabStyles : aoStyles_extra
        aoStyles_extra := (ObjectType = "Statusbar") ? aoStatusbarStyles : aoStyles_extra

        ; general style
        for index, oStyle in aoStyles{
            Options .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " ((defaultStyle & oStyle.Hex) ? "-" : "+") (oStyle.OptionText="" ? oStyle.Hex : oStyle.OptionText) 
            SkipOptions .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " (oStyle.SkipHex)
        }

        ; object specific styles
        if (aoStyles_extra!=""){
            for index, oStyle in aoStyles_extra{
                Options .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " ((defaultStyle & oStyle.Hex) ? "-" : "+") (oStyle.OptionText="" ? oStyle.Hex : oStyle.OptionText) 
                SkipOptions .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " (oStyle.SkipHex)
            }
        }
        
        for index, oExStyle in aoWinExStyles{
            Options .= (((defaultExStyle & oExStyle.Hex) && (object_ExStyle & oExStyle.Hex)) | (!(defaultExStyle & oExStyle.Hex) && !(object_ExStyle & oExStyle.Hex))) ? "" : " " ((defaultExStyle & oExStyle.Hex) ? "-" : "+") (oExStyle.OptionText="" ? "E" oExStyle.Hex : oExStyle.OptionText) 
            SkipOptions .= (((defaultExStyle & oExStyle.Hex) && (object_ExStyle & oExStyle.Hex)) | (!(defaultStyle & oExStyle.Hex) && !(object_ExStyle & oExStyle.Hex))) ? "" : " " (oExStyle.SkipHex)
        }

        
        Loop parse, Options, A_space{
            if !InStr(" " SkipOptions " ", " " A_LoopField " ",){
                optionsBuffer .= A_LoopField " "
            }
        }
        optionsBuffer :=StrReplace(optionsBuffer,"+-", "-")
        

        return optionsBuffer
    }
    Return

}

GuiRectangle(x:= 0, y:= 0 ,w:= 100 ,h:=100 , Color:="Blue",Thickness := 2){
    Static GuiBox := "" 
    if IsObject(GuiBox){
        try GuiBox.Destroy()
    }
    GuiBox := Gui(" +ToolWindow -Caption +AlwaysOnTop +E0x20 -DPIScale", "Highlight")
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

Tooltip2(Text:="" , X:= "", Y:= "", WhichToolTip:= "1"){
    ; ToolTip(Text, X, Y, WhichToolTip)
    ToolTip(Text)
    SetTimer () => ToolTip(), -3000
}

GetButtonType(hwndButton){
    static types := ["Button"	;BS_PUSHBUTTON 1
        , "Button"	;BS_DEFPUSHBUTTON 2
        , "Checkbox"	;BS_CHECKBOX 3
        , "Checkbox"	;BS_AUTOCHECKBOX 4
        , "Radio"	;BS_RADIOBUTTON 5
        , "Checkbox"	;BS_3STATE 6
        , "Checkbox"	;BS_AUTO3STATE 7
        , "Groupbox"	;BS_GROUPBOX 8
        , "NotUsed"	;BS_USERBUTTON 9
        , "Radio"	;BS_AUTORADIOBUTTON 10
        , "Button"	;BS_PUSHBOX 11
        , "AppSpecific"	;BS_OWNERDRAW 12
        , "SplitButton"	;BS_SPLITBUTTON    (vista+) 13
        , "SplitButton"	;BS_DEFSPLITBUTTON (vista+) 14
        , "CommandLink"	;BS_COMMANDLINK    (vista+) 15
        , "CommandLink"]	;BS_DEFCOMMANDLINK (vista+) 16

    btnStyle := WinGetStyle("ahk_id " hwndButton)
    return types[1 + (btnStyle & 0xF)]
}

ControlGetType(ctrl_hwnd){
    ctrl_ClassNN := ControlGetClassNN(ctrl_hwnd)
    ctrl_text := ControlGetText(ctrl_hwnd)
    ctrl_AhkName := TranslateClassName(ctrl_ClassNN)
    ControlType := ControlGetStyle(ctrl_hwnd) & 0xF
    ControlGetPos(&ctrl_x, &ctrl_y, &ctrl_w, &ctrl_h, ctrl_hwnd)
    If (ctrl_AhkName = "Button") {
        ; 1: BS_DEFPUSHBUTTON
        ; 2: BS_CHECKBOX
        ; 3: BS_AUTOCHECK
        ; 4: BS_RADIOBUTTON
        ; 5: BS_3STATE
        ; 6: BS_AUTO3STATE
        ; 9: BS_AUTORADIOBUTTON
        If (ControlType == 1) {
            ctrl_AhkName := "Button"
        } Else if (ControlType ~= "^(?i:2|3|5|6)$")
            ctrl_AhkName := "CheckBox"
        Else if (ControlType ~= "^(?i:4|9)$")
            ctrl_AhkName := "Radio"
        Else If (ControlType == 7)
            ctrl_AhkName := "GroupBox"

    } Else If (ctrl_AhkName == "Text") {
        If (ControlType == 3 || ControlType == 14) {
            ; 3:  SS_ICON
            ; 14: SS_BITMAP
            ctrl_AhkName := "Picture"
        }
        If (ctrl_text == "" && ctrl_h == 2) {
            ctrl_AhkName := "Separator"
        }
    } Else If (ctrl_AhkName == "ComboBox") {
        If (ControlType == 3) {
            ctrl_AhkName := "DropDownList"
        } Else {
            ctrl_AhkName := "ComboBox"
        }
    }
    return ctrl_AhkName
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
    } Else If (InStr(ClassName, "msctls_hotkey")) {
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
    } Else If (InStr(ClassName, "toolbar")) {
        AhkName := "ToolBar"
    } Else If (InStr(ClassName, "ScrollBar")) {
        AhkName := "ScrollBar"
    } Else If (InStr(ClassName, "AutoHotkeyGui")) {
        AhkName := "Gui"
    }
    Return AhkName
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

; Function Section handlers
{
    DClickMsgList(LV, RowNumber) {
        ogEdtVar1.text := ogLvMessages.GetText(RowNumber, 2)	; convert to number
    }

    ClickRun(*){
        KeyWait("Lbutton")
        SelFunction := DDLFunction.text
        ogEdtResult.text := ""
        oFunct := moFunctions[SelFunction]
        if !moFunctions.has(SelFunction){ ; Not recognized
            return
        }
        aPar := []

        if (oFunct.HasProp("var1")){
            aPar.Push(ogEdtVar1.text)
        }
        if (oFunct.HasProp("var2")){
            aPar.Push(ogEdtVar2.text)
        }
        if (oFunct.HasProp("var3")){
            if (InStr(SelFunction,"Message") and type(ogEdtVar3.text)="String" and !IsNumber(ogEdtVar3.text)){
                aPar.Push(StrPtr(ogEdtVar3.text))
            }
            else{
                aPar.Push(ogEdtVar3.text)
            }
        }
        if (oFunct.HasProp("Control") and oFunct.Control){
            aPar.Push(ogEdtControl.text)
        }

        if !WinExist(ogEdtWindow.text){
            MsgBox("No window was found for [" ogEdtWindow.text "]",,"Iconx 262144") ; AlwaysOnTop := 262144
            return
        }

        ; Display tooltip if more than one window found
        if (SelFunction != "WinGetCount" && WinGetCount(ogEdtWindow.text)>1){
            Tooltip2("WARNING: " WinGetCount(ogEdtWindow.text) " windows found")
        }

        aPar.Push(ogEdtWindow.text)
        
        Result := %SelFunction%(aPar*)
        if (Type(Result)="Array"){
            EditGui(Result)
            return
        } else if (IsObject(Result)) {
            ObjectGui(Result)
            return
        }else if InStr(Result,"`n"){
            ogEdtResult.Opt("+VScroll")
            ogEdtResult.Move(,,,7+5*13)
            ogGbResult.Move(,,,26+5*13)
        } else{
            ogEdtResult.Opt("-VScroll")
            ogEdtResult.Move(,,,7+1*13)
            ogGbResult.Move(,,,26+1*13)
        }
        
        ogEdtResult.text := Result
        GroupBoxAutosize(ogGBFunction)
        Gui_Size(myGui)
        
    }

    ClickCopy(*){
        SelFunction := DDLFunction.text

        if !moFunctions.has(SelFunction){ ; Not recognized
            return
        }

        oFunct := moFunctions[SelFunction]
        
        Clipboard := (oFunct.HasProp("result") && oFunct.result) ? "Result := " : ""
        aPar := []
        if (oFunct.HasProp("var1")){
            aPar.Push('"' ogEdtVar1.text '"')
        }
        if (oFunct.HasProp("var2")){
            aPar.Push('"' ogEdtVar2.text '"')
        }
        if (oFunct.HasProp("var3")){
            if (InStr(SelFunction,"Message") and type(ogEdtVar3.text)="String" and !IsNumber(ogEdtVar3.text)){
                aPar.Push('StrPtr("' ogEdtVar3.text '")')
            }
            else{
                aPar.Push('"' ogEdtVar3.text '"')
            }
        }
        if (oFunct.HasProp("Control") and oFunct.Control){
            aPar.Push('"' ogEdtControl.text '"')
        }
        aPar.Push('"' ogEdtWindow.text '"')
        Clipboard .= SelFunction "("
        for index, value in aPar{
            Clipboard .= (index=1) ? value : ', ' value
        }
        Clipboard .= ")"

        Clipboard := StrReplace(Clipboard, ', "")',')')
        Clipboard := StrReplace(Clipboard, ', "")',')')
        Clipboard := StrReplace(Clipboard, ', "")',')')
        Clipboard := StrReplace(Clipboard, '"")', ')')

        A_Clipboard := Clipboard
        ToolTip("Copied to clipboard:`n" Clipboard)
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

    ; Update controls of function section to see what should be visible
    UpdateFunctionControls(*){

        SelFunction := DDLFunction.text
        oSet.Function := SelFunction
        if !moFunctions.has(SelFunction){ ; Not recognized
            return
        }
        oFunct := moFunctions[SelFunction]
        DDLFunction.Statusbar := oFunct.Hasprop("Description") ? oFunct.Description : ""
        ogTxtVar1.Visible := oFunct.HasProp("var1")
        ogEdtVar1.Visible := oFunct.HasProp("var1")
        if (oFunct.HasProp("var1")){
            ogTxtVar1.text := oFunct.var1
            ogEdtVar1.Value := oFunct.HasProp("var1Default") ? oFunct.var1Default : ""
        }
        ogTxtVar2.Visible := oFunct.HasProp("var2")
        ogEdtVar2.Visible := oFunct.HasProp("var2")
        if (oFunct.HasProp("var2")){
            ogTxtVar2.text := oFunct.var2
            ogEdtVar2.Value := oFunct.HasProp("var2Default") ? oFunct.var2Default : ""
        }
        ogTxtVar3.Visible := oFunct.HasProp("var3")
        ogEdtVar3.Visible := oFunct.HasProp("var3")
        if (oFunct.HasProp("var3")){
            ogTxtVar3.text := oFunct.var3
            ogEdtVar3.Value := oFunct.HasProp("var3Default") ? oFunct.var3Default : ""
        }
        ogTxtControl.Visible := oFunct.HasProp("Control")
        ogEdtControl.Visible := oFunct.HasProp("Control")

        ogGbResult.Visible := (oFunct.HasProp("result") && oFunct.result)
        ogEdtResult.Visible := (oFunct.HasProp("result") && oFunct.result)

        ogGbMsgList.Visible := oFunct.HasProp("var1") && oFunct.var1 = "msg"
        ogEdtSearch.Visible := oFunct.HasProp("var1") && oFunct.var1 = "msg"
        ogLvMessages.Visible := oFunct.HasProp("var1") && oFunct.var1 = "msg"

        GuiSection_Size(oGuiFunction)
        GroupBoxAutosize(ogGBFunction)
        
        Gui_Size(myGui)
    }

}

; Resize size of GroupBox based on visible controls
GroupBoxAutosize(ogGB){
    ; Autosize Groupbox
    ; Skip if gui is not visible
    if ((WinGetStyle(ogGB.gui) & 0x10000000) = 0){
        return
    }

    yMax := 0
    ; ogGB.GetPos(&xGB,&yGB,&wGB,&hGB)
    ControlGetPos(&xGB,&yGB,&wGB,&hGB, ogGB)
    for index, oControl in ogGB.gui{
        if !oControl.visible{
            continue
        }
        if (ogGB.hwnd=oControl.hwnd){
            continue
        }
        oControl.GetPos(&xC,&yC,&wC,&hC)
        ControlGetPos(&xC,&yC,&wC,&hC, oControl)
        yMax := Max(yMax,yC+hC)
    }
    
    WinGetPos(&xWin,&yWin,&wWin,&hWin, ogGB.Gui)
    
    ControlMove(, , , yMax-yGB+5,ogGB)
    ogGB.gui.Show("Autosize")
}

Gui_About(){
    MyGui.Opt("+Disabled")	; Disable main window.
    ogAbout := Gui(, "About wInspector")
    ogAbout.Opt("-MaximizeBox -MinimizeBox AlwaysOnTop +OwnDialogs" )
    ogAbout.Add("Picture", "x11 w32 h33 +0x40 +E0x4 Icon145", "imageres.dll")
    ogAbout.Add("Text", "x53 y10 w345 h16 +0x7 +0x4 +0x8 +0x5 +Wrap +0x80 +0x9 +0x6 +E0x4", "wInspector")
    ogAbout.Add("Text", "x15 y45 w426 h2 +0x12 +0x10 +0x11 +E0x4 +E0x20000", "") ; Line
    ogAbout.Add("Text", "x53 +0x80 +E0x4", "wInpector is a multifunctional tool to verify what data can be retrieved form windows.`n`nWritten by Ahk_user.`n© All rights reserved.")
    ButtonOK := ogAbout.Add("Button", "x375 w75 +0x3 +0x9 +Default +0x7 +E0x4", "OK")
    ogAbout.OnEvent("Close", About_Close)
	ogAbout.OnEvent("Escape", About_Close)
    ButtonOK.OnEvent("Click", About_Close)
    ogAbout.Show()
    MyGui.Opt("+OwnDialogs")
    Return

    About_Close(*){
        MyGui.Opt("-Disabled")	; Re-enable the main window (must be done prior to the next step).
        ogAbout.Destroy()	; Destroy the about box.
    }
}

#include Lib\Acc.ahk

GuiAccViewer(Wintitle:="A", ControlHwnd:=""){

    ; Setting the Icon seems not to work
    hIcon := LoadPicture("shell32.dll", "Icon85 w32 h32" , &imgtype)
    ; Create the window:
    myAccGui := Gui(,"Acc Viewer")
    SendMessage(0x0080, 1, hIcon, myAccGui)
    myAccGui.Opt("+Resize")
    myAccGui.OnEvent("Size", GuiAcc_Size)
    ; myAccGui.OnEvent("Close", (*)=>(ExitApp))
    ogButton_AccSelector := MyAccGui.addButton("xm y2 w60 vbtnSelector BackgroundTrans h24 w24 +0x4000", "+")
    ogButton_AccSelector.SetFont("s20", "Times New Roman")
    ogButton_AccSelector.statusbar := "Click and drag to select a specific control or window"

    ; Create the ListView with two columns, Name and Size:
    ogEditSearch := myAccGui.AddText("ym x+10","Search:")
    ogEditSearch := myAccGui.AddEdit("yp-2 x+10")
    ogEditSearch.SetCueText("Search")
    ogEditSearch.OnEvent("Change",(*)=>(LVAcc_Update()))
    ogEditSearch.Tooltip := "Filter the lines"

    ogCB_Control := myAccGui.AddCheckbox("x+10 yp+3 " (ControlHwnd="" ? "" : "Checked"), "Control")
    ogCB_Control.Tooltip := "Collect Acc data from control or from hole window"
    ogCB_Value := myAccGui.AddCheckbox("x+10 yp", "Value")
    ogCB_Value.Tooltip := "Filter lines with filled values"
    ogCB_Value.OnEvent("Click", (*) => (LVAcc_Update()))
    ogCB_Visible := myAccGui.AddCheckbox("x+10 yp", "Visible")
    ogCB_Visible.Tooltip := "Filter visible lines"
    ogCB_Visible.OnEvent("Click", (*) => (LVAcc_Update()))

    LVAcc := myAccGui.Add("ListView", "xm yp+21 r25 w800", ["Path","Name","RoleText","Role","x","y","w","h","Value", "StateText", "State", "Description", "KeyboardShortcut", "Help", "ChildId"])
    LVAcc.OnEvent("ContextMenu", LVAcc_ContextMenu)
    ; Notify the script whenever the user double clicks a row:
    LVAcc.OnEvent("DoubleClick", LVAcc_DoubleClick)

    SB := MyAccGui.AddStatusBar(,)
    LVAcc_Update(Wintitle, ControlHwnd)
    LVAcc.ModifyCol  ; Auto-size each column to fit its contents.
    LVAcc.ModifyCol(2, "Integer")  ; For sorting purposes, indicate that column 2 is an integer.
    OnMessage(WM_LBUTTONDOWN := 0x0201, CheckAccButtonClick)

    HotIf (*) => (LVAcc.Focused)
    Hotkey("~^c", LVAcc_Copy)

    MyAccGui.Show

    LVAcc_Copy(ThisHotkey){
        Headers := ""
        Loop LVAcc.GetCount("Column") {
            Headers .= ((A_Index = 1) ? "" : "`t") LVAcc.GetText(0, A_Index)
        }
        A_Clipboard := Headers "`n" ListViewGetContent("Selected", LVAcc)
    }

    LVAcc_Update(WinTitle:="", ControlID:=""){
        global Acc_Content
        
        LVAcc.Delete()
        SearchText := ogEditSearch.text
        LVAcc.Opt("-Redraw")
        SB.SetText("Reading acc data...")

        TooltipTimer :=  Tooltip.Bind("Reading acc data...")
        SetTimer(TooltipTimer,100)
        if (WinTitle != "") {

            Title := WinGetTitle(Wintitle)
            
            if (ControlID!="" and ogCB_Control.Value){
                ControlClass := ControlGetClassNN(ControlID)
                Title := (ControlClass = "" ? "Control" : ControlClass) "] - [" Title
                oAcc := Acc.ObjectFromWindow("ahk_id " ControlID)
            } else {
                oAcc := Acc.ObjectFromWindow(WinTitle)
            }

            myAccGui.Title := "Acc Viewer - [" Title "]"
            
            global Acc_Content := oAcc.DumpAll()
            myAccGui.WinTitle := Wintitle
        }
        SetTimer(TooltipTimer, 0)
        TooltipTimer := Tooltip.Bind("Generating list...")
        SetTimer(TooltipTimer, 100)
        SB.SetText("Generating list...")

        Counter := 0
        CounterTotal:=0

        Loop Parse, Acc_Content, "`n","`r"
            {
                ; 4,1: RoleText: pane Role: 16 [Location: {x:3840,y:0,w:3840,h:2100}] [Name: ] [Value: ] [StateText: normal]
                CounterTotal++
                Path := RegExReplace(A_LoopField,"^([\d,]*):.*","$1", &OutputVarCount )
                Path := OutputVarCount=0 ? "" : Path
                RoleText := RegExReplace(A_LoopField,".*\QRoleText: \E(.*)\Q Role: \E.*","$1")
                Role := RegExReplace(A_LoopField,".*\Q Role: \E(.*)\Q [Location: \E.*","$1")
                x := RegExReplace(A_LoopField,".*\Q [Location: {x:\E(.*)\Q,y:\E.*","$1")
                y := RegExReplace(A_LoopField,".*\Q,y:\E(.*)\Q,w:\E.*","$1")
                w := RegExReplace(A_LoopField,".*\Q,w:\E(.*)\Q,h:\E.*","$1")
                h := RegExReplace(A_LoopField,".*\Q,h:\E(.*)\Q}] \E.*","$1")
                name := RegExReplace(A_LoopField,".*\Q}] [Name:\E(.*?)\Q] [\E.*","$1", &OutputVarCount)
                name := OutputVarCount=0 ? "" : name
                value := RegExReplace(A_LoopField,".*\Q] [Value:\E(.*?)\Q] [\E.*","$1", &OutputVarCount)
                value := OutputVarCount=0 ? "" : value
                description := RegExReplace(A_LoopField,".*\Q] [Description: \E(.*?)\Q]\E.*","$1", &OutputVarCount)
                description := OutputVarCount=0 ? "" : description
                StateText := RegExReplace(A_LoopField,".*\Q] [StateText: \E(.*?)(\Q] [\E.*|\Q]\E)$","$1", &OutputVarCount)
                StateText := OutputVarCount=0 ? "" : StateText
                State := RegExReplace(A_LoopField,".*\Q] [State: \E(.*?)(\Q] [\E.*|\Q]\E)$","$1", &OutputVarCount)
                State := OutputVarCount=0 ? "" : State
                KeyboardShortcut := RegExReplace(A_LoopField,".*\Q] [KeyboardShortcut: \E(.*?)(\Q] [\E.*|\Q]\E)$","$1", &OutputVarCount)
                KeyboardShortcut := OutputVarCount=0 ? "" : KeyboardShortcut
                Help := RegExReplace(A_LoopField,".*\Q] [Help: \E(.*?)(\Q] [\E.*|\Q]\E)$","$1", &OutputVarCount)
                Help := OutputVarCount=0 ? "" : Help
                ChildId := RegExReplace(A_LoopField,".*\Q ChildId: \E(.*?)(\Q [\E.*|\Q\E)$","$1", &OutputVarCount)
                ChildId := OutputVarCount=0 ? "" : ChildId

                if (ogEditSearch.text != "" and !InStrSuffled(Path "." RoleText "." Role "." Name "." value "." Description "." StateText "." State "." KeyboardShortcut "." Help ,ogEditSearch.text )){
                    continue
                }
                if ((ogCB_Value.Value and value!="") or (ogCB_Visible.Value and x=0 and y=0 and w=0 and h=0)){
                    continue
                }
                RowNumber := LVAcc.Add(, Path, name, RoleText, Role, x, y, w, h,  value, StateText, State, Description, KeyboardShortcut, Help, ChildId)
                if (myAccGui.HasProp("ElID") and myAccGui.ElID = x "-" y "-" w "-" h "-" Role){
                    LVAcc.Modify(RowNumber, "Select Focus Vis")
                }
                Counter++
            }
        SetTimer(TooltipTimer, 0)
        Tooltip("")

        SB.SetText((Counter=Countertotal) ? "Found " Counter " elements." : "Filtered " Counter "/" CounterTotal)
        LVAcc.Opt("+Redraw")
    }

    LVAcc_DoubleClick(LVAcc, RowNumber){
        RowText := LVAcc.GetText(RowNumber)  ; Get the text from the row's first field.
        ; ToolTip("You double-clicked row number " RowNumber ". Text: '" RowText "'")
        ChildPath := LVAcc.GetText(RowNumber)
        oAccp := Acc.ObjectFromPath(ChildPath, myAccGui.WinTitle)
        oAccp.Highlight(0)
    }

    GuiAcc_Size(thisGui, MinMax, Width, Height) {
        if MinMax = -1	; The window has been minimized. No action needed.
            return
        DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
        LVAcc.GetPos(&cX, &cY, &cWidth, &cHeight)
        LVAcc.Move(, , Width - cX - 10, Height -cY -26)
        DllCall("LockWindowUpdate", "Uint", 0)
    }

    LVAcc_ContextMenu(LVAcc, RowNumber, IsRightClick, X, Y){
        RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
        Counter:=0
        Loop{
            RowNumber := LVAcc.GetNext(RowNumber)  ; Resume the search at the row after that found by the previous iteration.
            if not RowNumber
                break
            Counter++
        }
        if (Counter=1){
            path := LVAcc.GetText(RowNumber)
            MyMenu := Menu()
            MyMenu.add "Copy Path", (*) =>(A_Clipboard :=path, Tooltip2("Copied [" A_Clipboard "]"))
            MyMenu.Show
        }

    }

    CheckAccButtonClick(wParam := 0, lParam := 0, msg := 0, hwnd := 0) {
        ; global MyAccGui
        MouseGetPos(, , , &OutputVarControlHwnd, 2)

        if (ogButton_AccSelector.hwnd = OutputVarControlHwnd) {
            ogButton_AccSelector.text := ""
            SetSystemCursor("Cross")
            CoordMode "Mouse", "Screen"
            While (GetKeyState("LButton")) {
                MouseGetPos(&MouseX, &MouseY, &MouseWinHwnd, &MouseControlHwnd, 2)
                Sleep(100)
                if ( MouseControlHwnd != "") {
                    MouseGetPos(&MouseX, &MouseY, &MouseWinHwnd, &MouseControlHwnd, 2)
                    oAccp := Acc.ObjectFromPoint(MouseX, MouseY)
                    myAccGui.oAccp := oAccp
                    myAccGui.ElID := oAccp.location.x "-" oAccp.location.y "-" oAccp.location.w "-" oAccp.location.h "-" oAccp.Role
                    oAccp.Highlight(0)
                }
            }
    
            SetSystemCursor("Default")
            ; LVAcc_Update("ahk_id " MouseWinHwnd)
            LVAcc_Update("ahk_id " MouseWinHwnd, MouseControlHwnd)
            ogButton_AccSelector.text := "+"
        }
    }

    ;     CopyAcc(ThisHotkey) {
    ;     if (ControlGetFocus()=LVAcc.hwnd){
    ;         Loop LVAcc.GetCount("Column") {
    ;             Headers .= ((A_Index = 1) ? "" : "`t") LVAcc.GetText(0, A_Index)
    ;         }
    ;         A_Clipboard := Headers "`n" ListViewGetContent("Selected", LVAcc)
    ;     }
    ; }
 
}

InStrSuffled(Haystack, Needles){
	Arr_Needle := StrSplit(Needles, " ")
	Value := "1"
	loop Arr_Needle.Length
	{
        if (Arr_Needle[A_Index]!=""){
            Value := Value * InStr(Haystack, Arr_Needle[A_Index])
		; Value := Value * RegExMatch(Haystack, "i)^(.*[^a-z]|)\Q" Arr_Needle[A_Index] "\E")
        }
		
	}
	return Value
}
