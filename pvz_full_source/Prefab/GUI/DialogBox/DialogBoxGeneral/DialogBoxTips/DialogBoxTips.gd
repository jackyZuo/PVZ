extends DialogPopup

var text: String = ""

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if textLabel.text != text:
        textLabel.clear()
        textLabel.append_text(text)

func ConfirmButtonPressed() -> void :
    Close()
