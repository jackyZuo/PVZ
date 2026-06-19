@tool
extends TowerDefenseCoinBase

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    remove_from_group("Coin")

func Destroy() -> void :
    pass

func Collection() -> void :
    super.Collection()
    var handler: LuckyBagDropItemHandler = DropItemRegistry.GetLuckyBagHandler()
    if handler:
        handler.OnCollect(global_position, num)
    else:
        TowerDefenseManager.LuckyBagPick(global_position)
