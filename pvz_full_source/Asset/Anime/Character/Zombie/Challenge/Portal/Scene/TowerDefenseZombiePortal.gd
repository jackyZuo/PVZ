@tool
extends TowerDefenseZombie

var halfHp: bool = false
var isAttack: bool = false
var timer: float = 0.0
var time: float = 20.0
var over: bool = false
var audioPlay: bool = false

var projectileConfigList: Array[TowerDefenseProjectileConfig]

@onready var checkArea: Area2D = %Area2D

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    sprite.SetFliters(["light1", "light2", "light3"], true)
    if randf() > 0.5:
        sprite.SetFliter("anim_tongue", true)
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)
    add_to_group("ZombiePortalGroup")

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.currentControl || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if global_position.x <= groundRight:
        if !audioPlay:
            AudioManager.AudioPlay("Portal", AudioManagerEnum.TYPE.SFX)
            audioPlay = true
        if !over:
            if !sprite.pause:
                if timer < time:
                    timer += delta * timeScale
                else:
                    over = true
                    if nearDie || die:
                        return
                    AudioManager.AudioPlay("Portal", AudioManagerEnum.TYPE.SFX)
                    ToPortal()
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if is_instance_valid(checkArea) && checkArea.has_overlapping_areas():
        for area: Area2D in checkArea.get_overlapping_areas():
            AreaEntered(area)

func AttackEntered():
    super.AttackEntered()
    isAttack = true
    if over:
        sprite.SetFliters(["light1", "light2", "light3"], false)
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func AttackExited() -> void :
    super.AttackExited()
    isAttack = false
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper", "Zombie_outerarm_hand", "Zombie_outerarm_lower"], false)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":
            halfHp = true
            sprite.SetFliters(["Zombie_outerarm_upper"], true)

func ArmorDamagePointReach(armorName: String, stage: int) -> void :
    super.ArmorDamagePointReach(armorName, stage)
    if armorName == "Portal" && over:
        sprite.SetFliters(["light1", "light2", "light3"], false)
    if isAttack && HasShield() && stage > 0:
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func AreaEntered(area: Area2D) -> void :
    var character = area.get_parent()
    if character is TowerDefenseProjectile:
        if character.over:
            return
        if character.camp == camp:
            return
        if character.has_meta("zombie_portal_projectile"):
            return
        if character.config.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.CATAPULT:
            return
        projectileConfigList.append(character.config)
        character.Over()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Portal":
            over = true
            ToPortal()

func DieEntered() -> void :
    super.DieEntered()
    over = true
    ToPortal()

func ToPortal() -> void :
    if is_instance_valid(checkArea):
        checkArea.queue_free()
    remove_from_group("ZombiePortalGroup")
    if !nearDie && !die && GetHasArmor("Portal"):
        if inWater:
            sprite.SetAnimation("WaterClose", false)
        else:
            sprite.SetAnimation("Close", false)
    else:
        Portal()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Close", "WaterClose":
            Portal()

func Portal() -> void :
    if !nearDie && !die:
        if isAttack:
            if inWater && attackWaterAnimeClip != "":
                sprite.SetAnimation(attackWaterAnimeClip, true, 0.2)
            else:
                sprite.SetAnimation(attackAnimeClip, true, 0.2)
        else:
            sprite.SetAnimation(walkAnimeClip, true, 0.2)
    sprite.SetFliters(["light1", "light2", "light3"], false)
    var zombiePortalList = get_tree().get_nodes_in_group("ZombiePortalGroup")
    if zombiePortalList.is_empty():
        return
    var zombie = zombiePortalList.pick_random()
    if !is_instance_valid(zombie):
        return
    for projectileConfig: TowerDefenseProjectileConfig in projectileConfigList:
        var _camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.PLANT
        if instance.hypnoses:
            _camp = TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE
        projectileConfig.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.SHOOTER
        var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePositionByConfig(null, null, GetGroundHeight(global_position.y) + randf_range(0, 70), zombie.global_position + Vector2(50 if instance.hypnoses else -50, 20), Vector2(randf_range(250, 500), 0) if instance.hypnoses else Vector2(randf_range(-500, -250), 0), projectileConfig, -1, _camp)
        projectile.set_meta("zombie_portal_projectile", true)
        projectile.checkAll = true
        projectile.projectileBodyNode.scale.x = - zombie.scale.x
        projectile.gridPos = zombie.gridPos
    projectileConfigList.clear()

@warning_ignore("shadowed_variable")
func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    projectileConfigList.clear()

func ExportVariantSave() -> Dictionary:
    return {
        "timer": timer, 
        "time": time, 
        "over": over, 
        "audioPlay": audioPlay
    }

func ImportVariantSave(data: Dictionary) -> void :
    timer = data.get("timer", 0.0)
    time = data.get("time", 20.0)
    over = data.get("over", false)
    audioPlay = data.get("audioPlay", false)
