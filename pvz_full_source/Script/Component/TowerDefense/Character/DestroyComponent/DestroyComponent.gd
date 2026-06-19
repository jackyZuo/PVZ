class_name DestroyComponent extends ComponentBase

const DESTROY_DELAY: = 1.0
const SMASH_SCALE_Y: = 0.25

var parent: TowerDefenseCharacter
var is_remote_destroy: bool = false

func GetName() -> String:
    return "DestroyComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func ShovelDestroy() -> void :
    parent.isShovel = true
    Destroy()

func Destroy(freeInstance: bool = true) -> void :
    if parent.isDestroy:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost and !is_remote_destroy:
        if parent is TowerDefensePlant:
            return
        if parent is TowerDefenseZombie and parent.sync_id >= 0:
            return
    parent.isDestroy = true
    parent.targetRegistrationComponent.UnregisterTarget()
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        parent.destroy.emit(parent)
        TowerDefenseManager.CharacterUnregister(parent)
        parent.remove_from_group("Character")
        parent.queue_free()
        return
    var _scale: float = 1.0
    var _hitpointScale: float = 1.0
    if is_instance_valid(parent.instance):
        _hitpointScale = parent.instance.hitpointScale
    if is_instance_valid(parent.transformPoint):
        _scale = parent.transformPoint.scale.x
    HitBoxDestroy()
    parent.destroy.emit(parent)
    BattleEventBus.characterDestroy.emit(parent.packet, parent.global_position, parent.gridPos, parent.camp, _scale, _hitpointScale)
    if freeInstance:
        for event: TowerDefenseCharacterEventBase in parent.dieEvent:
            event.Execute(parent.global_position, parent)
    if parent.isExplode && !parent.config.ashScene:
        AshDestroy()
        return
    if parent.isSmash:
        SmashDestroy()
        return
    if freeInstance:
        TowerDefenseManager.CharacterUnregister(parent)
        parent.remove_from_group("Character")
    if !parent.instance.hologram:
        if !parent.skipDestroySet:
            await parent.DestroySet()
    if freeInstance:
        parent.queue_free()

func AshDestroy() -> void :
    parent.die = true
    parent.destroy.emit(parent)
    TowerDefenseManager.CharacterUnregister(parent)
    parent.remove_from_group("Character")
    if !parent.instance.hologram:
        await parent.DestroySet()
    if parent.inWater:
        parent.queue_free()
        return
    parent.SetSpriteGroupShaderParameter("ash", true)
    parent.sprite.pause = true
    await parent.get_tree().create_timer(DESTROY_DELAY, false).timeout
    parent.queue_free()

func SmashDestroy() -> void :
    parent.die = true
    parent.destroy.emit(parent)
    TowerDefenseManager.CharacterUnregister(parent)
    parent.remove_from_group("Character")
    if !parent.instance.hologram:
        await parent.DestroySet()
    if parent.inWater:
        parent.queue_free()
        return
    if parent.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.VASE:
        parent.queue_free()
        return
    parent.sprite.pause = true
    parent.shadowSprite.visible = false
    parent.transformPoint.scale.y = SMASH_SCALE_Y
    await parent.get_tree().create_timer(DESTROY_DELAY, false).timeout
    parent.queue_free()

func HitBoxDestroy() -> void :
    if is_instance_valid(parent.hitBox):
        parent.hitBox.queue_free()
