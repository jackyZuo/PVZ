class_name MowerHitComponent extends ComponentBase

const MOWER_HIT: PackedScene = preload("uid://dtuc07xfk33qc")
const MOWER_PUFF = preload("uid://cv2sh3upqkd27")

var parent: TowerDefenseMower

func GetName() -> String:
    return "MowerHitComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func HitCheck(area: Area2D) -> void :
    var character = area.get_parent()
    if character is TowerDefenseCharacter:
        if character.instance.die || character.instance.nearDie:
            return
        if character is TowerDefenseGravestone:
            return
        if character is TowerDefenseCrater:
            return
        if character is TowerDefensePlantBowlingBase:
            return
        if character is TowerDefenseZombie:
            if !parent.run && character.scale.x < 0:
                return
            if character.instance.hypnoses:
                return
            if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                return
        if !parent.CanCollision(character.instance.maskFlags):
            return
        if parent.CheckDifferentCamp(character.camp) && (parent.CheckSameLine(character.gridPos.y) || character.targetRegistrationComponent.allLineCheck):
            if !parent.run:
                parent.Run()
                parent.run = true
            Hit(character)

func Hit(character: TowerDefenseCharacter) -> void :
    if character.die || character.nearDie:
        return
    if is_instance_valid(character.hitBox):
        parent.config.mowerConfig.Execute(character)
        character.HitBoxDestroy()
    var puff = TowerDefenseManager.CreateEffectSpriteOnce(MOWER_PUFF, parent.gridPos)
    puff.global_position = parent.transformPoint.global_position
    TowerDefenseGroundItemBase.characterNode.add_child(puff)
    if character.config is TowerDefenseZombieConfig:
        if character.config.physique >= TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE:
            if character.instance.zombiePhysique != TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                character.Bright()
                character.instance.DealHurt(100000, false)
                _send_mower_kill_sync(character)
                _start_mower_run()
                return
    if character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.VASE:
        character.die = true
        character.nearDie = true
        character.instance.DealHurt(1000000000.0, true, Vector2.ZERO)
        _send_mower_kill_sync(character)
        _start_mower_run()
        return
    var hit = MOWER_HIT.instantiate()
    TowerDefenseGroundItemBase.characterNode.add_child(hit)
    character.die = true
    character.nearDie = true
    hit.global_position = parent.sprite.global_position + Vector2(0, 0)
    hit.Init(character)
    _send_mower_kill_sync(character)
    _start_mower_run()

func _start_mower_run() -> void :
    parent.moveComponent.SetVelocity(Vector2.RIGHT * 100.0)
    await parent.get_tree().create_timer(0.25, false).timeout
    parent.moveComponent.SetVelocity(Vector2.RIGHT * 200.0)
    if parent.attackAnimeClips != "":
        if !parent.inWater:
            parent.sprite.SetAnimation(parent.attackAnimeClips, false)
            parent.sprite.AddAnimation(parent.runAnimeClips, 0, true, 0.1)
    if parent.attackWaterAnimeClips != "":
        if parent.inWater:
            parent.sprite.SetAnimation(parent.attackWaterAnimeClips, false)
            parent.sprite.AddAnimation(parent.runWaterAnimeClips, 0, true, 0.1)

func _send_mower_kill_sync(character: TowerDefenseCharacter) -> void :
    if !Global.isMultiplayerMode or !MultiPlayerManager.isHost:
        return
    if character.sync_id >= 0:
        MultiPlayerManager.SendCharacterDestroy(character.sync_id)
