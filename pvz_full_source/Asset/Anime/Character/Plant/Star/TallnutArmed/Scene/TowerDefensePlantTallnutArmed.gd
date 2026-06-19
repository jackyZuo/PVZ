@tool
extends TowerDefensePlant

const TALLNUT_ARMED = preload("uid://dw1omhgw0ymw6")

@export var eventList: Array[TowerDefenseCharacterEventBase]

var dieNum: int = 0

func IdleEntered() -> void :
    super.IdleEntered()
    match dieNum:
        0:
            sprite.SetAnimation("IdleA", true, 0.0)
        1:
            sprite.SetAnimation("CrakedA", false, 0.0)
            sprite.AddAnimation("IdleB", 0.0, true)
            instance.hitpointsSave -= 2000
            instance.hitpoints -= 2000
        2:
            sprite.SetAnimation("CrakedB", false, 0.0)
            sprite.AddAnimation("IdleC", 0.0, true)
            instance.hitpointsSave -= 4000
            instance.hitpoints -= 4000
        3:
            sprite.SetAnimation("CrakedC", false, 0.0)
            sprite.AddAnimation("IdleD", 0.0, true)
            instance.hitpointsSave -= 6000
            instance.hitpoints -= 6000

func DestroySet() -> void :
    super.DestroySet()
    TowerDefenseExplode.CreateExplode(global_position, Vector2(1.25, 0.25), eventList, [], camp, -1)

    if dieNum == 3:
        var effect = TowerDefenseManager.CreateEffectSpriteOnce(TALLNUT_ARMED, gridPos, "CrakedD")
        effect.global_position = global_position + Vector2(0, groundHeight)
        characterNode.add_child(effect)
        return

    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantTallnutArmed")
    var plant: TowerDefensePlant = packetConfig.Plant(gridPos, true, true)
    if is_instance_valid(plant):
        plant.dieNum = dieNum + 1
        if instance.hypnoses:
            plant.Hypnoses()

func ExportVariantSave() -> Dictionary:
    return {
        "dieNum": dieNum, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    dieNum = data.get("dieNum", 0)
