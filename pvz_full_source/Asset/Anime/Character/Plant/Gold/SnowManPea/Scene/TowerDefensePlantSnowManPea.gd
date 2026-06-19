@tool
extends TowerDefensePlant

@onready var timerComponent: TimerComponent = %TimerComponent
@onready var fireComponent: FireComponent = %FireComponent

var fireProjectileNum: int = 0
var isPower: bool = false:
    set = SetPower

var over: bool = false

@export var projectileName: String = "SnowBullet":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func SetPower(_isPower: bool) -> void :
    isPower = _isPower
    if isPower:
        fireComponent.fireCheckList[0].projectile.projectileData.baseDamage = 60
        fireComponent.fireCheckList[0].projectile.projectileData.scale = Vector2(1.0, 1.0)
        fireComponent.fireInterval = 0.3
        fireComponent.checkLength = -1
        sprite.SetFliters(["shoot_blink2", "mouth2", "head2", "ice1", "body2", "ice2"], true)
    else:
        fireComponent.fireInterval = 0.5
        fireComponent.checkLength = 6.0
        sprite.SetFliters(["shoot_blink2", "mouth2", "head2", "ice1", "body2", "ice2"], false)

func DestroySet() -> void :
    if over:
        return
    over = true
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var ball = CreateCharacter("ItemSnowBall", global_position, gridPos, groundHeight)
    if instance.hypnoses:
        ball.Hypnoses()
    ball.SetSize("Max")
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, ball)
            MultiPlayerManager.SendSpawnCharacterAt("ItemSnowBall", gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, instance.hypnoses, 0.0, true, global_position.x, global_position.y, false, groundHeight, "Max")

@warning_ignore("unused_parameter")
func FireProjectile(projectile: TowerDefenseProjectile) -> void :
    if isPower:
        return
    if fireProjectileNum < 100:
        fireProjectileNum += 1
    else:
        timerComponent.Run("Power", 30)
        isPower = true

func Timeout(timerName: String) -> void :
    match timerName:
        "Power":
            isPower = false

func ExportVariantSave() -> Dictionary:
    return {
        "fireProjectileNum": fireProjectileNum, 
        "isPower": isPower, 
        "projectileName": projectileName, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    fireProjectileNum = data.get("fireProjectileNum", 0)
    isPower = data.get("isPower", false)
    projectileName = data.get("projectileName", "SnowBullet")
