class_name TowerDefenseLevelLookStarCheckConfig extends Resource

@export var packetName: String = ""
@export var gridPos: Vector2i

func Init(data: Dictionary) -> void :
    packetName = data.get("PacketName", "")
    var gridPosGet = data.get_or_add("GridPos", Vector2i.ZERO)
    gridPos = Vector2i(gridPosGet[0], gridPosGet[1])

func Export() -> Dictionary:
    var data: Dictionary = {
        "PacketName": packetName, 
        "GridPos": [gridPos.x, gridPos.y]
    }
    return data
