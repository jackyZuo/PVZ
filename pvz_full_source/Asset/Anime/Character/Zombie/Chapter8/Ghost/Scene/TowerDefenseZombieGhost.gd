@tool
extends TowerDefenseZombie

var carryCharacter: TowerDefenseZombie
var ghostTimeScaleSave: float = 1.0
var ghost: bool = true:
    set(_ghost):
        ghost = _ghost
        if ghost:
            sprite.meshColor.a *= 0.5
            instance.canBeCollection = false
            targetRegistrationComponent.canProjectileCheck = false
        else:
            sprite.meshColor.a *= 1
            instance.canBeCollection = true
            targetRegistrationComponent.canProjectileCheck = true
            instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    targetRegistrationComponent.canCarry = false
    ghost = true
    if is_instance_valid(carryCharacter):
        Carry(carryCharacter)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if die || nearDie:
        return
    if is_instance_valid(carryCharacter):
        if carryCharacter.nearDie || carryCharacter.die:
            Die()
            return
        groundHeight = carryCharacter.groundHeight
        z = 40
        if is_instance_valid(carryCharacter.instance) && carryCharacter.instance.hypnoses:
            global_position.x = carryCharacter.global_position.x - 5
        else:
            global_position.x = carryCharacter.global_position.x + 5
    ghost = CheckGhost()

func HitBoxEntered(area: Area2D) -> void :
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if nearDie || die:
        return
    if is_instance_valid(carryCharacter):
        return
    var character = area.get_parent()
    if character is TowerDefenseZombie:
        if character.isRise:
            return
        if character.config.name == config.name:
            return
        if character.isCarry:
            return
        if character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE == 0:
            return
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            return
        if character.camp != camp:
            return
        if !character.targetRegistrationComponent.canCarry:
            return
        hitBox.disconnect("area_entered", HitBoxEntered)
        Carry(character)

func Carry(character: TowerDefenseZombie) -> void :
    carryCharacter = character
    carryCharacter.isCarry = true
    groundHeight = carryCharacter.groundHeight
    z = 40
    carryCharacter.Health(instance.hitpoints)
    ghostTimeScaleSave = carryCharacter.timeScaleInit
    carryCharacter.timeScaleInit *= 2.0

func CheckGhost() -> bool:
    var flag: bool = true
    for k in range(-1, 2, 1):
        for j in range(-1, 2, 1):
            var checkCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos + Vector2i(k, j))
            if is_instance_valid(checkCell):
                if checkCell.HasLight():
                    flag = false
                    break
        if !flag:
            break
    return flag

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    if is_instance_valid(carryCharacter):
        carryCharacter.timeScaleInit = ghostTimeScaleSave
        carryCharacter = null
        groundHeight = 0
        z = 0
        hitBox.connect("area_entered", HitBoxEntered)

func DestroySet() -> void :
    if is_instance_valid(carryCharacter):
        carryCharacter.timeScaleInit = ghostTimeScaleSave
        carryCharacter = null
        groundHeight = 0
        z = 0
    await get_tree().physics_frame

func ExportVariantSave() -> Dictionary:
    return {
        "ghost": ghost, 
        "ghostTimeScaleSave": ghostTimeScaleSave, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    ghost = data.get("ghost", true)
    ghostTimeScaleSave = data.get("ghostTimeScaleSave", 1.0)
