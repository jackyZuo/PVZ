@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent
@onready var collisionShape2d2: CollisionShape2D = %CollisionShape2D2
@onready var collisionShape2d3: CollisionShape2D = %CollisionShape2D3

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

func _ready() -> void :
    super._ready()
    collisionShape2d2.position.y = TowerDefenseManager.GetMapGridSize().y
    collisionShape2d3.position.y = - TowerDefenseManager.GetMapGridSize().y

@warning_ignore("unused_parameter")
func ConfirmProjectile(projectileId: int, _projectileName: String) -> void :
    match projectileId:
        0:
            match _projectileName:
                "Butter":
                    sprite.SetFliters(["Cornpult_butter"], false)
                    sprite.SetFliters(["Cornpult_kernal"], true)
                "ButterCatapult":
                    sprite.SetFliters(["Cornpult_butter"], true)
                    sprite.SetFliters(["Cornpult_kernal"], false)
        1:
            match _projectileName:
                "Butter":
                    sprite.SetFliters(["Cornpult_butter 复制"], false)
                    sprite.SetFliters(["Cornpult_kernal 复制"], true)
                "ButterCatapult":
                    sprite.SetFliters(["Cornpult_butter 复制"], true)
                    sprite.SetFliters(["Cornpult_kernal 复制"], false)
        2:
            match _projectileName:
                "Butter":
                    sprite.SetFliters(["Cornpult_butter  复制 2"], false)
                    sprite.SetFliters(["Cornpult_kernal  复制 2"], true)
                "ButterCatapult":
                    sprite.SetFliters(["Cornpult_butter  复制 2"], true)
                    sprite.SetFliters(["Cornpult_kernal  复制 2"], false)

func FireOver() -> void :
    sprite.SetFliters(["Cornpult_butter"], false)
    sprite.SetFliters(["Cornpult_butter 复制"], false)
    sprite.SetFliters(["Cornpult_butter  复制 2"], false)
    sprite.SetFliters(["Cornpult_kernal"], true)
    sprite.SetFliters(["Cornpult_kernal 复制"], true)
    sprite.SetFliters(["Cornpult_kernal  复制 2"], true)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    fireInterval = data.get("fireInterval", 3.0)
