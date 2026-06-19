@tool
extends TowerDefensePlant

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

@warning_ignore("unused_parameter")
func ConfirmProjectile(projectileId: int, _projectileName: String) -> void :
    match _projectileName:
        "Butter":
            sprite.SetFliters(["Cornpult_butter"], false)
            sprite.SetFliters(["Cornpult_kernal"], true)
        "ButterCatapult":
            sprite.SetFliters(["Cornpult_butter"], true)
            sprite.SetFliters(["Cornpult_kernal"], false)


func FireOver() -> void :
    sprite.SetFliters(["Cornpult_butter"], false)
    sprite.SetFliters(["Cornpult_kernal"], true)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    fireInterval = data.get("fireInterval", 3.0)
