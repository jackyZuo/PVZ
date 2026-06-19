@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 6.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 8:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum



var skinName: String = "Default":
    set(_skinName):
        skinName = _skinName
        var data: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(skinName))
        data.skinName = StringName(skinName)
        fireComponent.fireCheckList[0].projectile.projectileData.skinName = skinName
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileData.skinName = skinName
        fireComponent.fireCheckList[0].projectile.projectileWeight[1].projectileResource.projectileData.skinName = skinName
        fireComponent.fireCheckList[0].projectile.projectileWeight[2].projectileResource.projectileData.skinName = skinName

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if currentCustom.has("Custom0"):
        skinName = "Sycee"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Sycee"
    else:
        skinName = "Default"

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale

    if fireComponent.CanFireByData(fireComponent.fireCheckList[0].projectile.GetProjetile()):
        fireComponent.Refresh()
        var projectileData = fireComponent.fireCheckList[0].projectile.GetProjetile()
        for i in fireNum:
            var angle: float = deg_to_rad(360.0 / fireNum * float(i))
            var posOffset: Vector2 = Vector2.from_angle(angle)
            var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(0, Vector2(600, 0), projectileData, -1, camp, Vector2.ZERO)
            var tween = projectile.create_tween()
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_QUART)
            tween.tween_property(projectile, ^"global_position", projectile.global_position + posOffset * 50.0, 0.5)
            await get_tree().create_timer(0.1, false).timeout

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "skinName": skinName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 8)
    skinName = data.get("skinName", "Default")
    fireInterval = data.get("fireInterval", 6.0)
