@tool
extends TowerDefensePlant

const VASE_PLANT_CHUNKS = preload("uid://drx6wjsp5hkv7")

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready

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

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage1", "Damage2":
            AudioManager.AudioPlay("VaseBreaking", AudioManagerEnum.TYPE.SFX)
            var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(VASE_PLANT_CHUNKS, gridPos)
            effect.global_position = transformPoint.global_position - Vector2(0, 30.0)
            characterNode.add_child(effect)
            TowerDefenseExplode.CreateExplode(global_position, Vector2(0.5, 1.5), eventList, [], camp, -1)
    match damangePointName:
        "Damage1":
            fireComponent.fireCheckList[0].projectile.projectileName = "PeaVase"
            fireComponent.fireCheckList[0].projectile.projectileData.baseDamage = 40.0
        "Damage2":
            fireComponent.fireCheckList[0].projectile.projectileName = "PeaVase"
            fireComponent.fireCheckList[0].projectile.projectileData.baseDamage = 40.0
            fireNum = 2

func DestroySet() -> void :
    AudioManager.AudioPlay("VaseBreaking", AudioManagerEnum.TYPE.SFX)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(VASE_PLANT_CHUNKS, gridPos)
    effect.global_position = transformPoint.global_position - Vector2(0, 30.0)
    characterNode.add_child(effect)
    TowerDefenseExplode.CreateExplode(global_position, Vector2(0.5, 1.5), eventList, [], camp, -1)

    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantPeaShooterSingle")
    if instance.hypnoses:
        packetConfig.overrideHypnoses = true
    TowerDefenseManager.SpawnPacket(packetConfig, global_position + Vector2(0, - groundHeight), 15.0, false)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Pea")
    fireInterval = data.get("fireInterval", 1.5)
