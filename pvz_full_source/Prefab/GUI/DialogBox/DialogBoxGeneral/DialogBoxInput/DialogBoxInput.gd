extends DialogPopup

@onready var titleLabel: RichTextLabel = %TitleLabel
@onready var inputLineEdit: LineEdit = %InputLineEdit
@onready var confirmButton: MainButton = %ConfirmButton
@onready var cancelButton: MainButton = %CancelButton

signal confirmButtonPressed()

var titleText: String = "":
    set(_titleText):
        titleText = _titleText
        if is_node_ready():
            titleLabel.text = _titleText

var inputMaxLength: int = 10:
    set(_inputMaxLength):
        inputMaxLength = _inputMaxLength
        if is_node_ready():
            inputLineEdit.max_length = _inputMaxLength

var inputDefaultText: String = "":
    set(_inputDefaultText):
        inputDefaultText = _inputDefaultText
        if is_node_ready():
            inputLineEdit.text = _inputDefaultText

var inputPlaceholder: String = "":
    set(_inputPlaceholder):
        inputPlaceholder = _inputPlaceholder
        if is_node_ready():
            inputLineEdit.placeholder_text = _inputPlaceholder

var inputText: String:
    get:
        return inputLineEdit.text

func _ready() -> void :
    super._ready()
    titleLabel.text = titleText
    inputLineEdit.max_length = inputMaxLength
    inputLineEdit.text = inputDefaultText
    inputLineEdit.placeholder_text = inputPlaceholder

func ConfirmButtonPressed() -> void :
    confirmButtonPressed.emit()
    Close()

func CancelButtonPressed() -> void :
    Close()
