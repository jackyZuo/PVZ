@tool
extends TowerDefensePlant

var over: bool = false
var timer: float = 0.0
var time: float = 30.0

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "CoinDiamond":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return

func PrepareEntered() -> void :
    fireComponent.alive = false
    sprite.SetAnimation("Prepare", true, 0.2)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.currentControl || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !over:
        if !sprite.pause:
            if timer < time:
                timer += delta * timeScale
            else:
                over = true
                sprite.SetAnimation("Grow", true, 0.2)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Grow":
            Idle()

func Idle() -> void :
    if over:
        state.send_event("ToIdle")
    else:
        state.send_event("ToPrepare")

func IdleEntered() -> void :
    super.IdleEntered()
    fireComponent.alive = true

func ExportVariantSave() -> Dictionary:
    return {"over": over, 
        "timer": timer, 
        "time": time, 
        "fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
    timer = data.get("timer", 0.0)
    time = data.get("time", 30.0)
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "CoinDiamond")
    fireInterval = data.get("fireInterval", 5)
