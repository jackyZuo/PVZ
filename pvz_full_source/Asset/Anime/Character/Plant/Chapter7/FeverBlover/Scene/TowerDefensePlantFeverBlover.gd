@tool
extends TowerDefensePlant

@onready var bloverComponent: BloverComponent = %BloverComponent
@onready var magnetCoinComponent: MagnetCoinComponent = %MagnetCoinComponent
@onready var fireComponent: FireComponent = %FireComponent

var projectileName: String = "Spike":
    set(_projectileName):
        projectileName = _projectileName
        var data: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projectileName))
        data.skinName = StringName(skinName)
        bloverComponent.projectileDataList = [data]

var skinName: String = "Default":
    set(_skinName):
        skinName = _skinName
        var data: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projectileName))
        data.skinName = StringName(skinName)
        bloverComponent.projectileDataList = [data]

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    add_to_group("GoldMagnet")
    if currentCustom.has("Custom0"):
        skinName = "Knife"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Knife"
    else:
        skinName = "Default"

var run: bool = false

func IdleEntered() -> void :
    if !inGame:
        return
    if !TowerDefenseManager.currentControl.isGameRunning:
        return
    Run()

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale * 2.0
    if !inGame:
        return
    if !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !run:
        Run()
    else:
        if magnetCoinComponent.CanCoinDraw():
            magnetCoinComponent.CoinDraw()

func Run() -> void :
    sprite.SetAnimation("Blow", false, 0.2)
    sprite.AddAnimation("Loop", 0.0, true, 0.0)
    instance.invincible = true
    run = true
    get_tree().create_timer(5.0, false).timeout.connect(_SafetyDestroy)

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "blow":
            bloverComponent.Execult()
            for i in range(1, TowerDefenseManager.GetMapGridNum().y + 1):
                CreateJalapenoFire(camp, Vector2(gridPos.x, i), 500, [], [], "Fire")

func ExplodeHurt(num: float, type: String = "Bomb", playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    instance.invincible = false
    return super (num, type, playSplatAudio, velocity)

func BlowOver() -> void :
    Destroy()

func _SafetyDestroy() -> void :
    if !isDestroy:
        Destroy()

func CoinGet(num: int) -> void :
    var projectile: TowerDefenseProjectile
    match num:
        10:
            var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinSilver")
            _projectileData.baseDamage = 100.0
            _projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), _projectileData, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
        50:
            var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinGold")
            _projectileData.baseDamage = 500.0
            _projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), _projectileData, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
        1000:
            var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinDiamond")
            _projectileData.baseDamage = 1000.0
            _projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), _projectileData, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos

func ExportVariantSave() -> Dictionary:
    return {
        "projectileName": projectileName, 
        "skinName": skinName, 
        "run": run, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    projectileName = data.get("projectileName", "Spike")
    skinName = data.get("skinName", "Default")
    run = data.get("run", false)
