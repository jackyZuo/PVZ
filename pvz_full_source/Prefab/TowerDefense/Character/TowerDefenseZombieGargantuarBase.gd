@tool
class_name TowerDefenseZombieGargantuarBase extends TowerDefenseZombie

@export var fireAnimeClip: String = "Fire"
@export var smashAnimeEvent: String = "smash"
@export var impFireEvent: String = "fire"
@export var impName: String = ""
@export var impSpawnSlot: AdobeAnimateSlot
@export_multiline var impFilter: String:
    set(_impFliter):
        impFilter = _impFliter
        impFliters = Array(Array(impFilter.split("&", false)), TYPE_STRING, "", null)

@export_storage var impFliters: Array[String] = []

@export var impThrowDamagePointName: String = "ThrowImp"

var impThrowFlag: bool = false
var throwImpComponent: ThrowImpComponent

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if is_instance_valid(componentManager):
        throwImpComponent = componentManager.GetComponentFromType("ThrowImpComponent")

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if impThrowFlag:
        Fire()

func WalkProcessing(delta: float) -> void :
    super.WalkProcessing(delta)
    if impThrowFlag:
        Fire()

func AttackEntered():
    sprite.SetAnimation(attackAnimeClip, true, 0.2)

@warning_ignore("unused_parameter")
func AttackProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func FireEntered():
    sprite.SetAnimation(fireAnimeClip, false, 0.2)

@warning_ignore("unused_parameter")
func FireProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func FireExited() -> void :
    pass

func Fire():
    state.send_event("ToFire")

@warning_ignore("unused_parameter")
func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        attackAnimeClip:
            if !attackComponent.CanAttack():
                Walk()
        fireAnimeClip:
            Walk()
        dieAnimeClip:
            AudioManager.AudioPlay("GargantuarThump", AudioManagerEnum.TYPE.SFX)

@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        smashAnimeEvent:
            throwImpComponent.SmashAttack()
        impFireEvent:
            impThrowFlag = false
            throwImpComponent.ImpFliterSet()
            throwImpComponent.ImpSpawn()

func ImpFliterSet(open: bool = false):
    throwImpComponent.ImpFliterSet(open)

func DamagePointReach(damangePointName: String):
    super.DamagePointReach(damangePointName)
    match damangePointName:
        impThrowDamagePointName:
            var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
            if mapFeature:
                if global_position.x > mapFeature.config.edge.x + TowerDefenseManager.GetMapGridSize().x * 5.0:
                    impThrowFlag = true
        dieAnimeClip:
            AudioManager.AudioPlay("GargantuarDeath", AudioManagerEnum.TYPE.SFX)

func ExportVariantSave() -> Dictionary:
    return {
        "impThrowFlag": impThrowFlag, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    impThrowFlag = data.get("impThrowFlag", false)
