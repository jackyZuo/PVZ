@tool
extends Control

@export_tool_button("Play") var playButton = Storm

@onready var white: ColorRect = %White
@onready var black: ColorRect = %Black
@onready var blink: ColorRect = %Blink

var timer: float = 0.0
var nextTime: float = 5.0

func _ready() -> void :
    black.color.a = 1.0
    white.color.a = 0.0
    blink.color.a = 0.0
    timer = 0.0
    nextTime = randf_range(4.0, 6.0)

func _physics_process(delta: float) -> void :
    if timer < nextTime:
        timer += delta
    else:
        Storm()

func Storm() -> void :
    if !Engine.is_editor_hint():
        AudioManager.AudioPlay("Thunder", AudioManagerEnum.TYPE.SFX)
    timer = 0
    nextTime = randf_range(4.0, 6.0)
    black.color.a = 0.2
    var tween = create_tween()
    tween.tween_property(white, ^"color:a", 0.0, 0.5).from(1.0)
    await tween.finished
    tween = create_tween()
    tween.tween_property(black, ^"color:a", 1.0, 3.0).from(0.2)
    for i in 5:
        blink.color.a = randf_range(0.2, 0.4)
        await get_tree().create_timer(randf_range(0.1, 0.15), false).timeout
    for i in 5:
        blink.color.a = randf_range(0.5, 0.8)
        await get_tree().create_timer(randf_range(0.1, 0.15), false).timeout
