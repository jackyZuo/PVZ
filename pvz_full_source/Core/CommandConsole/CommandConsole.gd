extends CanvasLayer





signal consoleOpened()
signal consoleClosed()

var _history: Array[String] = []
var _historyIndex: int = -1
var _isOpen: bool = false
var _autocompleteIndex: int = -1
var _autocompleteList: Array[String] = []
var _welcomeShown: bool = false

@onready var _consolePanel: PanelContainer = %ConsolePanel
@onready var _outputLog: RichTextLabel = %OutputLog
@onready var _inputLine: LineEdit = %InputLine

func _ready() -> void :
    layer = 200
    _consolePanel.visible = false
    _outputLog.bbcode_enabled = true
    _outputLog.scroll_following = true
    _inputLine.text_submitted.connect(_OnInputSubmitted)
    _inputLine.text_changed.connect(_OnInputChanged)

func _input(event: InputEvent) -> void :
    if event is InputEventKey && event.pressed:
        if _isOpen:
            match event.keycode:
                KEY_ESCAPE:
                    Close()
                    get_viewport().set_input_as_handled()
                KEY_UP:
                    if _inputLine.has_focus() && _history.size() > 0:
                        _historyIndex = mini(_historyIndex + 1, _history.size() - 1)
                        _inputLine.text = _history[_historyIndex]
                        _inputLine.caret_column = _inputLine.text.length()
                        get_viewport().set_input_as_handled()
                KEY_DOWN:
                    if _inputLine.has_focus() && _history.size() > 0:
                        _historyIndex = maxi(_historyIndex - 1, -1)
                        if _historyIndex == -1:
                            _inputLine.text = ""
                        else:
                            _inputLine.text = _history[_historyIndex]
                        _inputLine.caret_column = _inputLine.text.length()
                        get_viewport().set_input_as_handled()
                KEY_TAB:
                    if _inputLine.has_focus():
                        _HandleAutocomplete()
                        get_viewport().set_input_as_handled()
        else:
            if event.keycode == KEY_ENTER || event.keycode == KEY_KP_ENTER:
                var focused: Control = get_viewport().gui_get_focus_owner()
                if focused is LineEdit || focused is TextEdit:
                    return
                Open()
                get_viewport().set_input_as_handled()



func Open() -> void :
    if _isOpen:
        return
    _isOpen = true
    _consolePanel.visible = true
    _inputLine.grab_focus()
    _autocompleteIndex = -1
    _autocompleteList.clear()
    if !_welcomeShown:
        _ShowWelcome()
        _welcomeShown = true
    consoleOpened.emit()

func Close() -> void :
    if !_isOpen:
        return
    _isOpen = false
    _consolePanel.visible = false
    _inputLine.text = ""
    _inputLine.release_focus()
    _historyIndex = -1
    _autocompleteIndex = -1
    _autocompleteList.clear()
    consoleClosed.emit()

func IsOpen() -> bool:
    return _isOpen

func GetHistory() -> Array[String]:
    return _history

func PrintLine(text: String) -> void :
    _outputLog.append_text(text + "\n")

func PrintInfo(text: String) -> void :
    _outputLog.append_text("[color=gray]%s[/color]\n" % text)

func PrintSuccess(text: String) -> void :
    _outputLog.append_text("[color=green]%s[/color]\n" % text)

func PrintWarning(text: String) -> void :
    _outputLog.append_text("[color=yellow]%s[/color]\n" % text)

func PrintError(text: String) -> void :
    _outputLog.append_text("[color=red]%s[/color]\n" % text)

func ClearLog() -> void :
    _outputLog.clear()





func _ShowWelcome() -> void :
    PrintLine("[color=cyan]═══════════════════════════════════════[/color]")
    PrintLine("[color=cyan]  指令控制台 v1.0[/color]")
    PrintLine("[color=gray]  输入 /help 查看所有指令[/color]")
    PrintLine("[color=gray]  按 Esc 关闭控制台[/color]")
    PrintLine("[color=cyan]═══════════════════════════════════════[/color]")

func _OnInputSubmitted(text: String) -> void :
    _inputLine.text = ""
    if text.strip_edges() == "":
        return
    _history.push_front(text)
    if _history.size() > 50:
        _history.pop_back()
    _historyIndex = -1
    _autocompleteIndex = -1
    _autocompleteList.clear()
    PrintLine("[color=white]> %s[/color]" % text)
    CommandRegistry.ExecuteCommand(text, PrintError)
    _inputLine.grab_focus()

func _OnInputChanged(_newText: String) -> void :
    _autocompleteIndex = -1
    _autocompleteList.clear()

func _HandleAutocomplete() -> void :
    var text: String = _inputLine.text.strip_edges()
    if text == "":
        return
    if _autocompleteIndex == -1:
        _autocompleteList.clear()
        var searchPrefix: String = text
        if searchPrefix.begins_with("/"):
            searchPrefix = searchPrefix.substr(1)
        searchPrefix = searchPrefix.to_lower()
        for cmdName in CommandRegistry.GetAllCommands():
            if cmdName.begins_with(searchPrefix):
                _autocompleteList.append(cmdName)
        if _autocompleteList.size() == 0:
            return
        _autocompleteIndex = 0
    else:
        _autocompleteIndex = (_autocompleteIndex + 1) % _autocompleteList.size()
    if _autocompleteList.size() > 0:
        var selected: String = _autocompleteList[_autocompleteIndex]
        _inputLine.text = "/" + selected + " "
        _inputLine.caret_column = _inputLine.text.length()
