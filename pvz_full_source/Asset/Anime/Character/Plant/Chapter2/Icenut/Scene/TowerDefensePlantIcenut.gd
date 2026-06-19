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

@export var projectileName: String = "SnowPea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName


@export var eventList: Array[TowerDefenseCharacterEventBase] = []

func DestroySet() -> void :
    ViewManager.FullScreenColorBlink(Color(0.117647, 0.564706, 1, 0.5), 0.1)
    AudioManager.AudioPlay("Frozen", AudioManagerEnum.TYPE.SFX)
    await get_tree().physics_frame
    TowerDefenseExplode.CreateExplode(global_position, Vector2(1.5, 1.5), eventList, [], camp, -1)
    var effect = TowerDefenseManager.CreateEffectParticlesOnce(SNOW_FLAKES, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 2)
    projectileName = data.get("projectileName", "SnowPea")
    fireInterval = data.get("fireInterval", 1.5)
