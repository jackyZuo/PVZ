@tool
extends TowerDefensePlant

var hpNext: float = 0
var hpNextInterval: float = 0

var over: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

    hpNextInterval = instance.hitpoints / 6.0
    hpNext = instance.hitpoints - hpNextInterval

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    while (instance.hitpoints <= hpNext):
        hpNext -= hpNextInterval
        Fire(1)

func DestroySet() -> void :
    if isShovel:
        return
    if over:
        return
    over = true

    var i: int = 0
    while (hpNext >= 0):
        hpNext -= hpNextInterval
        i += 1
    Fire(i)

func Fire(fireScale: int = 1) -> void :
    var gatlingTXPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ItemGatlingTX")
    for i in fireScale:
        var gatlingTX = gatlingTXPacket.Plant(gridPos, false, true)
        if instance.hypnoses:
            gatlingTX.Hypnoses()


func ExportVariantSave() -> Dictionary:
    return {
        "hpNext": hpNext, 
        "hpNextInterval": hpNextInterval, 
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    hpNext = data.get("hpNext", 0)
    hpNextInterval = data.get("hpNextInterval", 0)
    over = data.get("over", false)
