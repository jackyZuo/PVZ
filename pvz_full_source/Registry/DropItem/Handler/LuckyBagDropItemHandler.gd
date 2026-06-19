class_name LuckyBagDropItemHandler extends DropItemHandler

var luckyBagNum: int = 0

@warning_ignore("unused_parameter")
func OnCollect(pos: Vector2, value: int) -> void :
    luckyBagNum += 1
    match luckyBagNum:
        10:
            TowerDefenseManager.SunCreate(pos, 100, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 10.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
        30:
            TowerDefenseManager.SpawnPacket(TowerDefenseManager.GetPacketConfigCostUpper(300, TowerDefenseEnum.PACKET_TYPE.WHITE).pick_random(), pos, 15.0, false)
        60:
            TowerDefenseManager.SpawnPacket(TowerDefenseManager.GetPacketConfigCostUpper(0, TowerDefenseEnum.PACKET_TYPE.GOLD).pick_random(), pos, 15.0, false)
        100:
            TowerDefenseManager.SunCreate(pos, 1000, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 10.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
    if luckyBagNum > 100 && luckyBagNum % 100 == 0:
        for i in range(float(luckyBagNum) / 100):
            TowerDefenseManager.SpawnPacket(TowerDefenseManager.GetPacketConfigCostUpper(0, TowerDefenseEnum.PACKET_TYPE.GOLD).pick_random(), pos, 15.0, false)

func Reset() -> void :
    luckyBagNum = 0
