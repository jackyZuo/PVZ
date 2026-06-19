@tool
extends TowerDefensePlant

func Explode() -> void :
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ItemMegaFire")
    for i in TowerDefenseManager.GetMapGridNum().y:
        var flag: bool = true
        var megaFire: TowerDefenseCharacter
        if i == 0:
            megaFire = packetConfig.Plant(gridPos)
            flag = false
        else:
            if gridPos.y - i > 0:
                megaFire = packetConfig.Plant(gridPos - Vector2i(0, i))
                flag = false
            if gridPos.y + i <= TowerDefenseManager.GetMapGridNum().y:
                megaFire = packetConfig.Plant(gridPos + Vector2i(0, i))
                flag = false
        if is_instance_valid(megaFire):
            if instance.hypnoses:
                megaFire.Hypnoses()
        if flag:
            break
