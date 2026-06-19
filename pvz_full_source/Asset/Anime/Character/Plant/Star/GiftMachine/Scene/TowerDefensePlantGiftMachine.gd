@tool
extends TowerDefensePlant

@onready var magnetCoinComponent: MagnetCoinComponent = %MagnetCoinComponent

var hasCoin: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

func IdleEntered() -> void :
    super.IdleEntered()
    hasCoin = false
    add_to_group("GoldMagnet")

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if magnetCoinComponent.CanCoinDraw():
        state.send_event("ToMagnet")

func IdleExited() -> void :
    super.IdleExited()
    remove_from_group("GoldMagnet")

func MagnetEntered() -> void :
    sprite.SetAnimation("Attract", false, 0.2)

@warning_ignore("unused_parameter")
func MagnetProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func MagnetExited() -> void :
    pass

func ActionEntered() -> void :
    sprite.SetAnimation("Loop", false, 0.2)
    AudioManager.AudioPlay("Gift", AudioManagerEnum.TYPE.SFX)

@warning_ignore("unused_parameter")
func ActionProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func ActionExited() -> void :
    pass

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "action":
            magnetCoinComponent.CoinDraw()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Attract":
            if hasCoin:
                state.send_event("ToAction")
            else:
                Idle()
        "Loop":
            AwardCreate()
            Idle()

func AwardCreate() -> void :
    var rand: float = randf()
    if rand < 0.5:
        if instance.hypnoses:
            BrainSunCreate(spriteGroup.global_position, 15)
        else:
            SunCreate(spriteGroup.global_position, 15)
    elif rand < 0.75:
        if instance.hypnoses:
            BrainSunCreate(spriteGroup.global_position, 25)
        else:
            SunCreate(spriteGroup.global_position, 25)
    elif rand < 0.85:
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantBYWZ")
        if instance.hypnoses:
            packetConfig.overrideHypnoses = true
        SpawnPacket(packetConfig, spriteGroup.global_position, 15, false)
    else:
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantPresentBox")
        if instance.hypnoses:
            packetConfig.overrideHypnoses = true
        SpawnPacket(packetConfig, spriteGroup.global_position, 15, false)

@warning_ignore("unused_parameter")
func CoinGet(num: int) -> void :
    hasCoin = true

func ExportVariantSave() -> Dictionary:
    return {
        "hasCoin": hasCoin, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    hasCoin = data.get("hasCoin", false)
