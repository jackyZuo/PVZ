@tool
extends TowerDefenseCrater

@onready var timerComponent: TimerComponent = %TimerComponent

var over: bool = false

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !sprite.pause:
                var rand: float = randf()
                if rand < 0.45:
                    SunCreate(spriteGroup.global_position, 15)
                elif rand < 0.65:
                    SunCreate(spriteGroup.global_position, 25)
                elif rand < 0.7:
                    SunCreate(spriteGroup.global_position, 50)
                elif rand < 0.94:
                    var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_SILVER, global_position, GetGroundHeight(global_position.y), Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                    item.gridPos = gridPos
                elif rand < 0.99:
                    var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_GOLD, global_position, GetGroundHeight(global_position.y), Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                    item.gridPos = gridPos
                else:
                    var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_DIAMOND, global_position, GetGroundHeight(global_position.y), Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                    item.gridPos = gridPos
            timerComponent.Run("Spawn", 3.0)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Spawn"):
        timerComponent.Run("Spawn", 3.0)

func DestroySet() -> void :
    if over:
        return
    over = true
    var rand: float = randf()
    if rand < 0.8:
        SpawnPacket(TowerDefenseManager.GetPacketConfig("PlantSunBomb"), spriteGroup.global_position, 15, false)
    else:
        var packetBankData: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData("GeneralPlant")
        var packetList: Array = packetBankData.GetCategory("Gold")
        var packetRandom: String = packetList.pick_random()
        SpawnPacket(TowerDefenseManager.GetPacketConfig(packetRandom), spriteGroup.global_position, 15, false)
    Destroy()
