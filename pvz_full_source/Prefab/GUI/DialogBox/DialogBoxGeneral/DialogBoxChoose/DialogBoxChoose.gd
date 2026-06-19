extends DialogPopup

signal chooseTrue()
signal chooseFalse()

var text: String = ""

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if textLabel.text != text:
        textLabel.clear()
        textLabel.append_text(text)

func TrueButtonPressed() -> void :
    chooseTrue.emit()
    Close()

func FalseButtonPressed() -> void :
    chooseFalse.emit()
    Close()
