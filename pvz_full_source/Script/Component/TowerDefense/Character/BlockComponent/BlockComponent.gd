
class_name BlockComponent extends ComponentBase


signal block()

signal projectileRebound()


@export_enum("General", "Jump") var blockType: Array[String] = ["General"]

@export var extendGrid: Vector2 = Vector2(1, 1)

@export var checkArea: Area2D

@export var checkLadder: bool = false


@export var reboundProjectile: bool = false

@export var reboundProjectileArea: Area2D


@export var parent: TowerDefenseCharacter


var timer: float = 0.0


func GetName() -> String:
    return "BlockComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    if reboundProjectile:
        reboundProjectileArea.area_entered.connect(ProjectileCheck)


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if is_instance_valid(parent.cell):
        if is_instance_valid(parent.cell.characterLadder):
            parent.cell.characterLadder.Block(parent)
            block.emit()
    if checkArea.has_overlapping_areas():
        for area in checkArea.get_overlapping_areas():
            BlockCheck(area)



func BlockCheck(area: Area2D) -> void :
    if !alive:
        return
    if parent.die || parent.nearDie:
        return
    var character = area.get_parent()
    if character is TowerDefenseProjectile:
        if character.catapultOpen:
            if parent.camp == character.camp:
                return
            if is_instance_valid(character.target):
                if !(character.target.gridPos.y >= parent.gridPos.y - extendGrid.y && character.target.gridPos.y <= parent.gridPos.y + extendGrid.y):
                    return
                if !(character.target.gridPos.x >= parent.gridPos.x - extendGrid.x && character.target.gridPos.x <= parent.gridPos.x + extendGrid.x):
                    return
            else:
                if !(character.gridPos.y >= parent.gridPos.y - extendGrid.y && character.gridPos.y <= parent.gridPos.y + extendGrid.y):
                    return
            if character.catapultTimer > character.catapultTime * 0.75:
                if character.config.blockHurt != -1:
                    parent.Hurt(character.config.blockHurt)
                character.BlockedBounce()
                block.emit()

    if character is TowerDefenseCharacter:
        if parent.camp == character.camp:
            return
        if character.CanBlock():
            if !(character.gridPos.y >= parent.gridPos.y - extendGrid.y && character.gridPos.y <= parent.gridPos.y + extendGrid.y):
                return
            if !(character.gridPos.x >= parent.gridPos.x - extendGrid.x && character.gridPos.x <= parent.gridPos.x + extendGrid.x):
                return
            if blockType.has(character.BlockType()):
                character.Block(parent)
                block.emit()



func ProjectileCheck(area: Area2D) -> void :
    if !reboundProjectile:
        return
    if !alive:
        return
    if parent.die || parent.nearDie:
        return
    var character = area.get_parent()
    if character is TowerDefenseProjectile:
        if parent.camp != character.camp:
            return
        if character.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.SHOOTER:
            character.velocity.x = - character.velocity.x
            character.projectileBodyNode.scale.x = - character.projectileBodyNode.scale.x
            character.fireDirX = - character.fireDirX
            character.target = null
            character.fireCharacter = null
            if character.extId >= 0 && character._projectileServer:
                character._projectileServer.unregister_projectile(character.extId)
                character.extId = -1
                character.set_physics_process(true)
            projectileRebound.emit()
