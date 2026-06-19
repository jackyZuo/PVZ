@tool
extends TowerDefensePlant
const BLOW = preload("uid://j7kll4h65yex")

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
        Blow(1.0)

func DestroySet() -> void :
    if isShovel:
        return
    if over:
        return
    over = true

    var i: float = 0.0
    while (hpNext >= 0):
        hpNext -= hpNextInterval
        i += 1.0
    Blow(i)

func Blow(blowScale: float = 1.0) -> void :
    BattleEventBus.blowAllEffectEmit.emit()
    var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(BLOW, gridPos, "Idle")
    effect.global_position = transformPoint.global_position - Vector2(0, 30)
    characterNode.add_child(effect)
    var targetList = TowerDefenseManager.GetCharacterTarget(self, false, false)
    for target: TowerDefenseCharacter in targetList:
        if target is TowerDefenseZombie:
            if target.instance.zombiePhysique >= TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE:
                target.BlowBack(0.25 * blowScale, 0.25)
                continue
        if target.instance.unUseBuffFlags == TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ALL:
            continue
        if target.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.BLOW:
            continue
        if target is TowerDefensePlant || target is TowerDefenseGravestone || target is TowerDefenseItem:
            continue
        if target.instance.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND:
            continue
        if target.instance.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER:
            continue
        if target.instance.collisionFlags != 0:
            target.BlowBack(0.5 * blowScale, 0.25)
        if target.instance.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
            target.Blow()
    AudioManager.AudioPlay("Blover", AudioManagerEnum.TYPE.SFX)

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
