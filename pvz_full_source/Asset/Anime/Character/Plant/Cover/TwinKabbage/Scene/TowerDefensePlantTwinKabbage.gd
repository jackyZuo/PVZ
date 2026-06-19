@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 2:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum



@warning_ignore("unused_parameter")
func ConfirmProjectile(projectileId: int, projectileName: String) -> void :
    sprite.SetFliters(["anim_cabbage", "corn", "anim_butter"], false)
    match projectileName:
        "Butter":
            sprite.SetFliters(["anim_butter"], true)
        "CabbageTrack":
            sprite.SetFliters(["anim_cabbage"], true)
        "KernalTrack":
            sprite.SetFliters(["corn"], true)

@warning_ignore("unused_parameter")
func FireProjectile(projectile: TowerDefenseProjectile) -> void :
    sprite.SetFliters(["anim_cabbage", "corn", "anim_butter"], false)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 2)
    fireInterval = data.get("fireInterval", 1.5)
