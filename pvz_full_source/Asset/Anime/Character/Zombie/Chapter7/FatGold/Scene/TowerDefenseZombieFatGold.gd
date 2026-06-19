@tool
extends TowerDefenseZombie

@onready var fireComponent: FireComponent = %FireComponent

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
@export var projectileName: String = "CoinSilver"

var currentFireNum: int = 0

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    fireComponent.fireInterval = fireInterval
    fireComponent.fireEventName = ""
    fireComponent.fireAnimeClipsArray = []
    fireComponent.fireAnimeClips = ""
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if die || nearDie:
        return
    fireComponent.fireInterval = fireInterval
    if fireComponent.CanFireByData(fireComponent.fireCheckList[0].projectile.GetProjetile()):
        state.send_event("ToThrow")

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func ThrowEntered() -> void :
    fireComponent.Refresh()
    if inWater:
        sprite.SetAnimation("SwimFire", false, 0.2)
    else:
        sprite.SetAnimation("Fire", false, 0.2)

@warning_ignore("unused_parameter")
func ThrowProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func ThrowExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "SwimFire", "Fire":
            if currentFireNum == 0:
                Walk()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "fire":
            var rand = randf()
            var data: TowerDefenseProjectileCreateData
            if rand < 0.05:
                projectileName = "CoinDiamond"
                data = TowerDefenseProjectileCreateData.new(StringName(projectileName))
                data.baseDamage = 1000.0
            elif rand < 0.25:
                projectileName = "CoinGold"
                data = TowerDefenseProjectileCreateData.new(StringName(projectileName))
                data.baseDamage = 500.0
            else:
                projectileName = "CoinSilver"
                data = TowerDefenseProjectileCreateData.new(StringName(projectileName))
                data.baseDamage = 100.0
            data.damageFlags = 3
            data.fireMethodFlags = 1
            data.collisionFlags = 1
            var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(0, Vector2(-500, 0), data, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos

            currentFireNum += 1
            if currentFireNum == fireNum:
                currentFireNum = 0
            else:
                if inWater:
                    sprite.SetAnimation("SwimFire", false, 0.1)
                else:
                    sprite.SetAnimation("Fire", false, 0.1)
