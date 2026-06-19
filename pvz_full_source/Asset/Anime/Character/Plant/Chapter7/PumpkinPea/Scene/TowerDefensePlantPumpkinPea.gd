@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 2.0:
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

@export var projectileName: String = "Pea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

@export var level: int = 1

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if !inGame:
        sprite.back.z_index = 0

func Cover(character: TowerDefenseCharacter) -> void :
    if character.config.name == "PlantPumpkinPea":
        level = clampi(character.level + 1, 1, 3)
        LevelSet(level)

func LevelSet(lv: int) -> void :
    match lv:
        2:
            sprite.SetFliters(["Upgrade1_eyebrow", "Upgrade1_helmet", "Upgrade2_barrel"], true)
            instance.hitpoints += 2000
            instance.hitpointsSave += 2000
            fireComponent.fireEventName = "fire&fire2"
        3:
            sprite.SetFliters(["Upgrade1_eyebrow", "Upgrade1_eyebrow2", "Upgrade1_helmet", "Upgrade2_helmet", "Upgrade2_barrel", "Upgrade2_barrel2", "Upgrade2_face"], true)
            instance.hitpoints += 4000
            instance.hitpointsSave += 4000
            fireComponent.fireEventName = "fire&fire2&fire3"

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "level": level, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Pea")
    level = data.get("level", 1)
    if level > 1:
        LevelSet(level)
    fireInterval = data.get("fireInterval", 2.0)
