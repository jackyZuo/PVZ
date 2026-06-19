class_name CatapultComponent extends ComponentBase

signal fire_event()
signal projectile_depleted()
signal damage_point_reached(damagePointName: String)

@export_group("Movement")
@export var speed: float = 50.0
@export var damageSpeedReduction: float = 40.0
@export var lowHealthThreshold: float = 0.2

@export_group("Fire")
@export var fireInterval: float = 3.0
@export var fireNum: int = 1
@export var projectileNum: int = 20
@export var projectileName: String = "Basketball"
@export var fireSpeedMultiplier: float = 3.0
@export var fireAudioName: String = "Basketball"
@export var useCanFireCheck: bool = true
@export var refreshInFireEntered: bool = true

@export_group("Animation")
@export var walkAnimeClip: String = "Walk"
@export var fireAnimeClip: String = "Fire"

@export_group("Effect")
@export var explosionEffect: Resource

@export_group("References")
@export var smokeParticle: GPUParticles2D
@export var fireSlot: AdobeAnimateSlot

var parent: TowerDefenseZombie
var fireComponent: FireComponent
var attackComponent: AttackComponent
var currentProjectileNum: int
var currentFireNum: int = 0
var fireOver: bool = false
var isFire: bool = false

func GetName() -> String:
    return "CatapultComponent"

func _ready() -> void :
    parent = get_parent().parent as TowerDefenseZombie
    if !is_instance_valid(parent):
        return
    if !parent.is_node_ready():
        await parent.ready
    fireComponent = parent.componentManager.GetComponentFromType("FireComponent") as FireComponent
    attackComponent = parent.componentManager.GetComponentFromType("AttackComponent") as AttackComponent
    currentProjectileNum = projectileNum
    if is_instance_valid(fireComponent):
        fireComponent.fireInterval = fireInterval
        fireComponent.fireNum = fireNum
        if !fireComponent.fireCheckList.is_empty():
            fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func PhysicsProcess(delta: float) -> void :
    if !isFire:
        if !parent.sprite.pause:
            if parent.global_position.x > TowerDefenseManager.GetMapGroundRight():
                parent.global_position.x -= speed * delta * parent.timeScale * parent.sprite.timeScale * parent.transformPoint.scale.x * parent.scale.x * 2.0 * (-1 if parent.sprite.playBack else 1)
            else:
                parent.global_position.x -= speed * delta * parent.timeScale * parent.sprite.timeScale * parent.transformPoint.scale.x * parent.scale.x * (-1 if parent.sprite.playBack else 1)
    if is_instance_valid(attackComponent):
        if attackComponent.CanAttack():
            if is_instance_valid(attackComponent.target.cell):
                if attackComponent.target.cell.HasSpike():
                    attackComponent.target = attackComponent.target.cell.GetSpike()
            if !attackComponent.target.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE:
                attackComponent.SmashAttackCell(parent.config.smashAttack)
            else:
                if attackComponent.target.instance.spikeHurt != -1:
                    attackComponent.target.Hurt(attackComponent.target.instance.spikeHurt)
                parent.Die()
    if parent.instance.hitpoints < (parent.config.hitpoints + parent.config.hitpointsNearDeath) * lowHealthThreshold:
        if speed > 5:
            speed -= delta * 1.0
        parent.sprite.shake = true

func IdleProcessing(delta: float) -> void :
    if !parent.sprite.pause:
        if parent.global_position.x > TowerDefenseManager.GetMapGroundRight() - TowerDefenseManager.GetMapGridSize().x / 2:
            if parent.global_position.x > TowerDefenseManager.GetMapGroundRight():
                parent.global_position.x -= speed * delta * parent.timeScale * parent.sprite.timeScale * parent.transformPoint.scale.x * parent.scale.x * 2.0 * (-1 if parent.sprite.playBack else 1)
            else:
                parent.global_position.x -= speed * delta * parent.timeScale * parent.sprite.timeScale * parent.transformPoint.scale.x * parent.scale.x * (-1 if parent.sprite.playBack else 1)
    if !fireOver && isFire:
        if useCanFireCheck:
            if is_instance_valid(fireComponent) && fireComponent.CanFireByData(fireComponent.fireCheckList[0].projectile.GetProjetile(), -1):
                parent.state.send_event("ToFire")
            else:
                if fireComponent.timer <= 0 && fireComponent.checkIntreval <= 0:
                    isFire = false
                    parent.Walk()
        else:
            if is_instance_valid(fireComponent) && fireComponent.timer <= 0:
                parent.state.send_event("ToFire")
    else:
        isFire = false
        parent.Walk()

func WalkEntered() -> void :
    parent.sprite.SetAnimation(walkAnimeClip, true, 0.0)

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
    parent.sprite.timeScale = parent.timeScale * 0.5
    if !fireOver && !isFire:
        if parent.global_position.x < TowerDefenseManager.GetMapGroundRight() - TowerDefenseManager.GetMapGridSize().x / 2:
            if CanStartFire():
                isFire = true
                parent.Idle()
    else:
        if isFire:
            isFire = false
            parent.Idle()

func FireEntered() -> void :
    if refreshInFireEntered && is_instance_valid(fireComponent):
        fireComponent.Refresh()
    parent.sprite.SetAnimation(fireAnimeClip, true, 0.2 * (fireInterval + 4.5) / 6.0)

@warning_ignore("unused_parameter")
func FireProcessing(delta: float) -> void :
    parent.sprite.timeScale = parent.timeScale * fireSpeedMultiplier * (1.75 / (fireInterval + 0.25))

func OnFireAnimeEvent() -> void :
    if !refreshInFireEntered && is_instance_valid(fireComponent):
        fireComponent.Refresh()
    AudioManager.AudioPlay(fireAudioName, AudioManagerEnum.TYPE.SFX)
    if is_instance_valid(fireSlot):
        fireSlot.Update()
    fire_event.emit()
    currentProjectileNum -= 1
    currentFireNum += 1
    if currentProjectileNum <= 0:
        isFire = false
        fireOver = true
        projectile_depleted.emit()
    if currentProjectileNum <= 0 || currentFireNum == fireNum:
        currentFireNum = 0
    else:
        parent.sprite.SetAnimation(fireAnimeClip, true, 0.1)

func OnFireAnimeCompleted() -> void :
    if currentFireNum == 0:
        parent.Idle()

func OnDamagePoint(damagePointName: String) -> void :
    match damagePointName:
        "DamagePoint2":
            speed = damageSpeedReduction
            if is_instance_valid(smokeParticle):
                smokeParticle.visible = true
    damage_point_reached.emit(damagePointName)

func CreateDeathEffect() -> void :
    AudioManager.AudioPlay("ZamboniExplosion", AudioManagerEnum.TYPE.SFX)
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    if explosionEffect:
        var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(explosionEffect, parent.gridPos)
        effect.global_position = parent.global_position
        TowerDefenseGroundItemBase.characterNode.add_child(effect)

func CanStartFire() -> bool:
    if fireOver || isFire:
        return false
    if parent.global_position.x >= TowerDefenseManager.GetMapGroundRight() - TowerDefenseManager.GetMapGridSize().x / 2:
        return false
    if !is_instance_valid(fireComponent):
        return false
    if useCanFireCheck:
        return fireComponent.CanFireByData(fireComponent.fireCheckList[0].projectile.GetProjetile())
    else:
        return fireComponent.timer <= 0

func GetDepletionLevel(numLevels: int = 4) -> int:
    if currentProjectileNum <= 0:
        return numLevels
    for i: int in numLevels:
        if currentProjectileNum < float(projectileNum) / numLevels * (i + 1):
            return i + 1
    return 0

func ExportComponentSave() -> Dictionary:
    return {
        "currentProjectileNum": currentProjectileNum, 
        "currentFireNum": currentFireNum, 
        "fireOver": fireOver, 
        "isFire": isFire, 
        "speed": speed, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    currentProjectileNum = _data.get("currentProjectileNum", projectileNum)
    currentFireNum = _data.get("currentFireNum", 0)
    fireOver = _data.get("fireOver", false)
    isFire = _data.get("isFire", false)
    speed = _data.get("speed", 50.0)
