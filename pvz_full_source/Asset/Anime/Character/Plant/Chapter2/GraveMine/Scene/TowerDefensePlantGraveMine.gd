@tool
extends TowerDefensePlant

func GravebusterOver() -> void :
    var sunMinePacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantSunMine")
    if cell.CanPacketPlant(sunMinePacket):
        var sunMine = sunMinePacket.Plant(gridPos)
        if instance.hypnoses:
            sunMine.Hypnoses()
        await get_tree().physics_frame
        sunMine.ReadyRise()
