@tool
extends TowerDefenseZombie

var dancingComponent: DancingComponent

@export var dancerPacketName: String = "":
    set(value):
        dancerPacketName = value
        if value != "" && is_instance_valid(dancingComponent):
            dancingComponent.dancerPacketName = value

func RemoveDancer(dancer: TowerDefenseCharacter) -> void :
    if is_instance_valid(dancingComponent):
        dancingComponent.RemoveDancer(dancer)

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    dancingComponent = componentManager.GetComponentFromType("DancingComponent") as DancingComponent
    if is_instance_valid(dancingComponent):
        if dancerPacketName != "":
            dancingComponent.dancerPacketName = dancerPacketName
        else:
            for armor in instance.armorList:
                if armor.config.armorName == "BlackHelmet" || armor.config.armorName == "SpecialHelmet":
                    dancingComponent.dancerPacketName = "ZombieDancerCone"
                    break

func WalkEntered() -> void :
    super.WalkEntered()
    if is_instance_valid(dancingComponent):
        dancingComponent.OnWalkEntered()

func WalkProcessing(delta: float) -> void :
    if is_instance_valid(dancingComponent):
        groundMoveComponent.alive = dancingComponent.CanWalk()
    super.WalkProcessing(delta)

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    if is_instance_valid(dancingComponent):
        dancingComponent.OnAttackProcessing(delta)

func Walk() -> void :
    if die:
        state.send_event("ToDie")
        return
    if is_instance_valid(dancingComponent):
        if dancingComponent.OnWalk():
            return
    state.send_event("ToWalk")

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    if is_instance_valid(dancingComponent):
        dancingComponent.OnDieProcessing()

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    if is_instance_valid(dancingComponent):
        dancingComponent.OnHypnoses()
