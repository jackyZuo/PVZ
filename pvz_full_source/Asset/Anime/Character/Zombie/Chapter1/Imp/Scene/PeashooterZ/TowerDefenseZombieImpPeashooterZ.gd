@tool
extends TowerDefenseZombieImpBase


@onready var fireComponent: FireComponent = %FireComponent
@onready var timerComponent: TimerComponent = %TimerComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "ZombiePea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !sprite.pause:
                if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
                    timerComponent.Run("Spawn", 10.0)
                    return
                var zombie = CreateCharacter("ZombieImpPeashooterSingle", global_position, gridPos, 0.0)
                zombie.Rise(2.5)
                if instance.hypnoses:
                    zombie.Hypnoses()
                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, zombie)
                        MultiPlayerManager.SendSpawnCharacterAt("ZombieImpPeashooterSingle", gridPos.x, gridPos.y, _sync_id, instance.hitpointScale, transformPoint.scale.x, instance.hypnoses, 2.5, true, global_position.x, global_position.y)
            timerComponent.Run("Spawn", 10.0)

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return

    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliter("Zombie_duckytube", true)
    if TowerDefenseManager.IsIZMMode():
        instance.hitpointScale = 140.0 / 270.0

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func InWater() -> void :
    super.InWater()
    sprite.SetFliter("Zombie_whitewater", true)

func OutWater() -> void :
    super.OutWater()
    sprite.SetFliter("Zombie_whitewater", false)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Spawn"):
        timerComponent.Run("Spawn", 10.0)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantPeashooterZ")
    if cell.CanPacketPlant(packetConfig):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos)
        character.WakeUp()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt("PlantPeashooterZ", gridPos.x, gridPos.y, _sync_id)
    Destroy()
