@tool
extends TowerDefenseZombieGargantuarBase

const ZOMBIE_GARGANTUAR_HEAD_2 = preload("uid://cfx6iqy08xujv")

const ZOMBIE_BACKUP_GARGANTUAR_BODY_1 = preload("uid://cse5dugps3y17")
const ZOMBIE_BACKUP_GARGANTUAR_BODY_1_2 = preload("uid://c53wvxn6c14gs")
const ZOMBIE_BACKUP_GARGANTUAR_BODY_1_3 = preload("uid://0f6e278qdym4")

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
    if is_instance_valid(dancingComponent) && dancerPacketName != "":
        dancingComponent.dancerPacketName = dancerPacketName

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

func DamagePointReach(damangePointName: String):
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":
            sprite.SetReplace("Zombie_BackupGargantuar_body1.png", ZOMBIE_BACKUP_GARGANTUAR_BODY_1_2)
        "Head":
            sprite.SetReplace("Zombie_BackupGargantuar_body1.png", ZOMBIE_BACKUP_GARGANTUAR_BODY_1_3)
