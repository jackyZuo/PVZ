@tool
extends TowerDefenseZombieImpBase

@onready var hackTimer: Timer = $HackTimer

var isHack: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !isHack && hackTimer.is_stopped():
        hackTimer.start(10.0)

    if !instance.canBeCollection:
        sprite.meshColor.a *= 0.5

func HackEntered() -> void :
    sprite.SetAnimation("Hack", false, 0.2)
    isHack = true

@warning_ignore("unused_parameter")
func HackProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func HackExited() -> void :
    isHack = false

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func InWater() -> void :
    super.InWater()
    sprite.SetFliter("Zombie_whitewater", true)

func OutWater() -> void :
    super.OutWater()
    sprite.SetFliter("Zombie_whitewater", false)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Hack":
            Walk()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "hack":
            Hack()

func Hack() -> void :
    instance.canBeCollection = false
    instance.collisionFlags = 0
    SetPacket()
    await get_tree().create_timer(4.0, false).timeout
    instance.canBeCollection = true
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE

func SetPacket() -> void :
    var seedBank: TowerDefenseInGameSeedBank = TowerDefenseManager.GetSeedBank()
    var impPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieImp")
    if instance.hypnoses || TowerDefenseManager.IsIZMMode():
        impPacket.overrideCost = -50

    match TowerDefenseManager.currentLevelConfig.packetBankMethod:
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE, TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET:
            if seedBank.packetList.size() <= 1:
                return
            var seedBankPacket: TowerDefenseInGamePacketShow = seedBank.packetList.pick_random()
            seedBankPacket.Cover(impPacket)
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR:
            var conveyorFeature: TowerDefenseBattleFeatureConveyorBelt = TowerDefenseManager.GetConveyorBeltFeature()
            if is_instance_valid(conveyorFeature):
                conveyorFeature.SpawnPacket(impPacket)
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
            var _rainModeFeature: TowerDefenseBattleFeatureRainMode = TowerDefenseManager.GetRainModeFeature()
            if is_instance_valid(_rainModeFeature):
                _rainModeFeature.SpawnPacket(impPacket)

func HackTimerTimeout() -> void :
    if die || nearDie:
        return
    state.send_event("ToHack")
