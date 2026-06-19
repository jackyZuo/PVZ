
class_name MousePressComponent extends ComponentBase


signal pressed(pos: Vector2)

signal doublePressed(pos: Vector2)

signal released(pos: Vector2)

signal finishPressed(pos: Vector2)


@export var inputControl: Control

@export var toogle: bool = false

@export var toggleTarget: Node2D


var parent: TowerDefenseCharacter


var isMoseIn: bool = false

var isPressed: bool = false

var waitPress: bool = true

var doublePressBuffer: bool = false


var targetPos: Vector2


var open: bool = false


func GetName() -> String:
    return "MousePressComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    if is_instance_valid(inputControl):
        inputControl.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
        inputControl.mouse_entered.connect(MouseEntered)
        inputControl.mouse_exited.connect(MouseExited)
        await get_tree().physics_frame
        waitPress = false


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        isPressed = false
        isMoseIn = false
        parent.SetSpriteGroupShaderParameter("brightStrength", 0.0)
        return


@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    if !alive:
        return
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if toogle:
        if toggleTarget.visible:
            toggleTarget.global_position = get_global_mouse_position()
    if waitPress:
        if isMoseIn:
            if doublePressBuffer:
                if Input.is_action_just_pressed("Press"):
                    doublePressed.emit(get_global_mouse_position())
                    doublePressBuffer = false
        return

    if !isPressed:
        if isMoseIn:
            if Input.is_action_just_pressed("Press"):
                if toogle:
                    isPressed = true
                    toggleTarget.visible = true
                    toggleTarget.global_position = get_global_mouse_position()
                pressed.emit(get_global_mouse_position())
                waitPress = true
                doublePressBuffer = true
                await get_tree().create_timer(0.25, false).timeout
                waitPress = false
                doublePressBuffer = false
    elif toogle:
        toggleTarget.visible = true
        if Input.is_action_just_pressed("Press"):
            targetPos = toggleTarget.global_position
            toggleTarget.visible = false
            isPressed = false
            if !TowerDefenseManager.GetGroundRect().has_point(get_global_mouse_position()):
                released.emit(get_global_mouse_position())
                waitPress = true
                await get_tree().create_timer(0.1, false).timeout
                waitPress = false
                return
            finishPressed.emit(get_global_mouse_position())
            parent.SetSpriteGroupShaderParameter("brightStrength", 0.0)
            waitPress = true
            await get_tree().create_timer(0.1, false).timeout
            waitPress = false
            return
        if !Global.isMobile:
            if Input.is_action_just_pressed("Release"):
                toggleTarget.visible = false
                isPressed = false
                waitPress = true
                released.emit()
                await get_tree().create_timer(0.1, false).timeout
                waitPress = false


func MouseEntered() -> void :
    if !alive:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    parent.SetSpriteGroupShaderParameter("brightStrength", 0.3)
    isMoseIn = true


func MouseExited() -> void :
    if !alive:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    parent.SetSpriteGroupShaderParameter("brightStrength", 0.0)
    isMoseIn = false



func SetAlive(_alive: bool) -> void :
    super.SetAlive(_alive)
    if is_instance_valid(inputControl):
        if !_alive:
            inputControl.mouse_default_cursor_shape = Control.CURSOR_ARROW
        else:
            inputControl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
