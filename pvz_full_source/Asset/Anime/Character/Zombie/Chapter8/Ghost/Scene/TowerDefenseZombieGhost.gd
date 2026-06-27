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
var timer: float = 0.0
var time: float = 40.0

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
        if carryCharacter.isDestroy:
            if carryCharacter.global_position.x > carryCharacter.groundRight + 150 || carryCharacter.global_position.x < TowerDefenseManager.GetMapGroundLeft() - 150:
                DetachGhost()
            else:
                Die()
            return
        groundHeight = carryCharacter.groundHeight
        z = 40
        global_position.y = carryCharacter.global_position.y
        gridPos.y = carryCharacter.gridPos.y
        if is_instance_valid(carryCharacter.instance) && carryCharacter.instance.hypnoses:
            global_position.x = carryCharacter.global_position.x - 5
        else:
            global_position.x = carryCharacter.global_position.x + 5
    else:
        if carryCharacter != null:
            DetachGhost()
            return
    ghost = CheckGhost()
    if instance.hypnoses && !sprite.pause:
        if timer < time:
            timer += delta * timeScale
        elif !is_instance_valid(carryCharacter):
            Die()

func WalkProcessing(delta: float) -> void :
    super.WalkProcessing(delta)
    if ghost && !nearDie && !sprite.pause && sprite.timeScale > 0 && useAttackDps && attackComponent.target != null:
        attackComponent.AttackDps(delta, config.attack)

func HitBoxEntered(area: Area2D) -> void :
    var flag: bool = true
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if nearDie || die:
        return
    if is_instance_valid(carryCharacter):
        flag = false
    var character = area.get_parent()
    if character is TowerDefenseZombie:
        if character.isRise:
            flag = false
        if character.config.name == config.name:
            flag = false
        if character.hasGhost:
            flag = false
        if character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND != 0 && character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE == 0:
            flag = false
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            flag = false
        if character.camp != camp:
            flag = false
        if !character.targetRegistrationComponent.canCarry:
            flag = false
        if flag:
            hitBox.disconnect("area_entered", HitBoxEntered)
            Carry(character)
        if ghost && character.config.name == config.name && character.camp != camp:
            if attackComponent.target == null:
                attackComponent.target = character

func HitBoxExited(area: Area2D) -> void :
    if ghost:
        var character: TowerDefenseCharacter = area.get_parent() as TowerDefenseCharacter
        if attackComponent.target == character:
            attackComponent.target = null

func Carry(character: TowerDefenseZombie) -> void :
    carryCharacter = character
    carryCharacter.hasGhost = true
    carryCharacter.ghostCharacter = self
    groundHeight = carryCharacter.groundHeight
    z = 40
    carryCharacter.Health(instance.hitpoints)
    ghostTimeScaleSave = carryCharacter.timeScaleInit
    carryCharacter.timeScaleInit *= 2.0

func DetachGhost() -> void :
    if is_instance_valid(carryCharacter):
        carryCharacter.timeScaleInit = ghostTimeScaleSave
        carryCharacter.hasGhost = false
        carryCharacter.ghostCharacter = null
    carryCharacter = null
    groundHeight = 0
    z = 0
    _ReconnectHitBox()

func _ReconnectHitBox() -> void :
    if is_instance_valid(hitBox):
        if !hitBox.area_entered.is_connected(HitBoxEntered):
            hitBox.connect("area_entered", HitBoxEntered)
        hitBox.process_mode = Node.PROCESS_MODE_INHERIT
        for area in hitBox.get_overlapping_areas():
            if is_instance_valid(carryCharacter):
                break
            HitBoxEntered(area)

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

@warning_ignore("shadowed_variable")
func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    if is_instance_valid(carryCharacter):
        carryCharacter.timeScaleInit = ghostTimeScaleSave
        carryCharacter.hasGhost = false
        carryCharacter.ghostCharacter = null
        carryCharacter = null
        groundHeight = 0
        z = 0
        _ReconnectHitBox()

func DestroySet() -> void :
    if is_instance_valid(carryCharacter):
        carryCharacter.timeScaleInit = ghostTimeScaleSave
        carryCharacter.hasGhost = false
        carryCharacter.ghostCharacter = null
        carryCharacter = null
        groundHeight = 0
        z = 0
    await get_tree().physics_frame

func ExportVariantSave() -> Dictionary:
    return {
        "ghost": ghost, 
        "ghostTimeScaleSave": ghostTimeScaleSave, 
        "timer": timer, 
        "time": time
    }

func ImportVariantSave(data: Dictionary) -> void :
    ghost = data.get("ghost", true)
    ghostTimeScaleSave = data.get("ghostTimeScaleSave", 1.0)
    timer = data.get("timer", 40.0)
    time = data.get("time", 0.0)
