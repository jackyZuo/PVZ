@tool
extends TowerDefensePlant

const CHERRY_BOMB_EXPLOSION = preload("uid://cibtjjjomdxnh")

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

var hpNext: float = 0
var hpNextInterval: float = 0

var over: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

    hpNextInterval = instance.hitpoints / 6.0
    hpNext = instance.hitpoints - hpNextInterval

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    while (instance.hitpoints <= hpNext):
        hpNext -= hpNextInterval
        explodeComponent.Explode()

func DestroySet() -> void :
    if isShovel:
        return
    if over:
        return
    over = true
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(CHERRY_BOMB_EXPLOSION, gridPos)
    effect.global_position = transformPoint.global_position - Vector2(0, 30)
    characterNode.add_child(effect)
    while (hpNext >= 0):
        hpNext -= hpNextInterval
        AudioManager.AudioPlay("ExplodeCherrybomb", AudioManagerEnum.TYPE.SFX)
        explodeComponent.Explode()

func ExportVariantSave() -> Dictionary:
    return {
        "hpNext": hpNext, 
        "hpNextInterval": hpNextInterval, 
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    hpNext = data.get("hpNext", 0)
    hpNextInterval = data.get("hpNextInterval", 0)
    over = data.get("over", false)
