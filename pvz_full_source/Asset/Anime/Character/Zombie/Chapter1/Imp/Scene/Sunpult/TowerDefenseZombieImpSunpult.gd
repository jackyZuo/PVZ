@tool
extends TowerDefenseZombieImpBase
@onready var fireComponent: FireComponent = %FireComponent
@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var growUpComponent: GrowUpComponent = %GrowUpComponent

@export var produceInterval: float = 10.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if !is_node_ready():
            await ready
        produceComponent.produceInterval = produceInterval

@export var sunNum: int = 15:
    set(_sunNum):
        sunNum = _sunNum
        if !is_node_ready():
            await ready
        produceComponent.num = sunNum

@export var growUpTime: float = 25.0:
    set(_growUpTime):
        growUpTime = _growUpTime
        if !is_node_ready():
            await ready
        growUpComponent.growUpTime[0] = growUpTime

@export var fireInterval: float = 3.0:
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

@export var projectileName: String = "Sunshroom":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return

    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliter("Zombie_duckytube", true)
    if TowerDefenseManager.IsIZMMode():
        instance.hitpointScale = 140.0 / 270.0
    if !TowerDefenseManager.GetMapIsNight():
        fireComponent.timeScale *= 0.5
        walkSpeedScale *= 0.5
    else:
        fireComponent.timeScale *= 1.0
        walkSpeedScale *= 1.0

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

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "Sun" if instance.hypnoses else "BrainSun"

func GrowUp(reach: int) -> void :
    match reach:
        0:
            sunNum = 25
            produceComponent.num = sunNum
            fireComponent.fireCheckList[0].projectile.projectileData.SetBaseDamage(80.0)
            fireComponent.fireCheckList[0].projectile.projectileData.SetScale(Vector2(1.5, 1.5))

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantSunpult")
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
                MultiPlayerManager.SendSpawnCharacterAt("PlantSunpult", gridPos.x, gridPos.y, _sync_id)
    Destroy()
