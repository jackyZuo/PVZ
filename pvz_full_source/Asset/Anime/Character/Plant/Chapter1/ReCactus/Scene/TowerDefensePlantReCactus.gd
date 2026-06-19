@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 2:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Spike":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    shadowSprite.scale = transformPoint.scale - Vector2.ONE * (z - groundHeight) / 100.0
    if sprite.clip == "Jump":
        sprite.timeScale = timeScale * 2.0
    else:
        sprite.timeScale = timeScale * 1.0

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Jump":
            sprite.SetAnimation(idleAnimeClip, true, 0.2)

func FireReady() -> void :
    if fireComponent.runningCheckId == 0 && ySpeed >= 0:
        ySpeed = -200.0
        sprite.SetAnimation("Jump", true, 0.2 * (fireInterval + 4.5) / 6.0)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 2)
    projectileName = data.get("projectileName", "Spike")
    fireInterval = data.get("fireInterval", 1.5)
