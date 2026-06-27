class_name GoldShardDropItemHandler extends DropItemHandler

var goldShardNum: int = 0

@warning_ignore("unused_parameter")
func OnCollect(pos: Vector2, value: int) -> void :
    goldShardNum += 1
    if goldShardNum >= 4 && goldShardNum % 4 == 0:
        for i in range(float(goldShardNum) / 4):
            var packetBankData: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData("GeneralPlant")
            var packetList: Array = packetBankData.GetCategory("Gold")
            var packetRandom: String = packetList.pick_random()
            TowerDefenseManager.SpawnPacket(TowerDefenseManager.GetPacketConfig(packetRandom), pos, 15, false)
        Reset()

func Reset() -> void :
    goldShardNum = 0
