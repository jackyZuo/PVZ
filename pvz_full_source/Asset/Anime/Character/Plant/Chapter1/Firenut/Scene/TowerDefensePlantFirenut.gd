@tool
extends TowerDefensePlant

@onready var light: PointLight2D = %Light
@onready var attackComponent: AttackComponent = %AttackComponent

var over: bool = false

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    light.visible = TowerDefenseManager.GetMapIsNight() && GameSaveManager.GetConfigValue("MapEffect")

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetFliter("skin2_4", true)

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)

    if !isUnlimitedFire:
        return
    if attackComponent.CanAttack():
        state.send_event("ToAttack")

func AttackEntered() -> void :
    AudioManager.AudioPlay("BowlingImpact", AudioManagerEnum.TYPE.SFX)
    attackComponent.Attack(0.0)
    sprite.SetAnimation("Roll", false, 0.2)

@warning_ignore("unused_parameter")
func AttackProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func AttackExited() -> void :
    pass

func DestroySet() -> void :
    super.DestroySet()
    if over:
        return
    over = true
    if !isUnlimitedFire:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantFirenutBowling")
    var bowling = packetConfig.Create(global_position, gridPos, 0.0)
    characterNode.add_child(bowling)
    bowling.config.damagePointData.SetDamagePointFliters(bowling.sprite, "Damage2")

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Roll":
            Idle()

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
