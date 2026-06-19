@tool
extends TowerDefensePlant

@onready var collisionShape: CollisionShape2D = %CollisionShape

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 4

func BlockCharacter() -> void :
    itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.EFFECT
    sprite.SetAnimation("Block", false, 0.1)
    sprite.AddAnimation("Idle", 0.0, true, 0.0)
    await get_tree().physics_frame
    var targetList: Array = TowerDefenseManager.GetCharacterTargetNear(self, TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION)
    if targetList.size() <= 0:
        return
    var target: TowerDefenseCharacter = targetList[0]
    var _cell = TowerDefenseManager.GetMapCell(target.gridPos)
    var height: float = 0
    if is_instance_valid(_cell):
        height = - _cell.GetGroundHeight() + 30
    var projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName("MeteorStar"))
    projectileData.baseDamage = 100
    projectileData.damageFlags = TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY
    if randf() < 0.2:
        projectileData.projectileName = "MeteorStarS"
        projectileData.baseDamage = 200
        projectileData.damageFlags = TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY
        Health(100)
    var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePositionByData(null, null, height, target.global_position, Vector2.ZERO, projectileData, -1, camp)
    projectile.gridPos = target.gridPos
    projectile.z = 600
    projectile.ySpeed = 800
    projectile.useFall = true

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Block":
            itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.PLANT
