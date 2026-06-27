
class_name ChangeProjectileComponent extends ComponentBase


@export var changeName: StringName

@export var changeAudio: String

@export var checkArea: Area2D

@export var isStar: bool = false

@export var checkAir: bool = false

var parent: TowerDefenseCharacter


var excludeList: Array[TowerDefenseProjectile]


var timer: float = 0.0


func GetName() -> String:
    return "ChangeProjectileComponent"


func _ready():
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    checkArea.area_entered.connect(ChangeProjectile)



func ChangeProjectile(area: Area2D):
    if !alive:
        return
    if parent.die || parent.nearDie:
        return
    var projectile = area.get_parent()
    if projectile is TowerDefenseProjectile:
        if excludeList.has(projectile):
            return
        if projectile.camp != parent.camp:
            return
        if !projectile.checkAll && projectile.gridPos.y != parent.gridPos.y:
            return
        if checkAir && projectile.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.CATAPULT:
            return
        var toProjectileName: StringName = TowerDefenseProjectileRegistry.GetProjectileChange(StringName(projectile.config.name), changeName)
        if toProjectileName != &"":
            var currentData: TowerDefenseProjectileData = TowerDefenseProjectileRegistry.GetProjectile(StringName(projectile.config.name))
            var data: TowerDefenseProjectileData = TowerDefenseProjectileRegistry.GetProjectile(toProjectileName)
            var toProjectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(toProjectileName)
            toProjectileData.skinName = projectile.config.skinName
            var toProjectileConfig: TowerDefenseProjectileConfig = toProjectileData.BuildConfig()
            if currentData && data && toProjectileData.baseDamage != 0 && currentData.baseDamage != 0:
                toProjectileConfig.baseDamage = projectile.damage * (data.baseDamage / currentData.baseDamage)
            elif data:
                toProjectileConfig.baseDamage = data.baseDamage
            if data && data.isFire:
                toProjectileConfig.damageFlags |= TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.FIRE
            if toProjectileConfig:
                projectile.Change(toProjectileConfig, StringName(projectile.config.name), toProjectileName, parent)
                if changeAudio:
                    AudioManager.AudioPlay(changeAudio, AudioManagerEnum.TYPE.SFX)
                return
        if isStar:
            if TowerDefenseProjectileRegistry.HasChangeTarget(StringName(projectile.config.name), changeName):
                return
            if projectile.config.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.CATAPULT:
                return
            var starDir = [330, 270, 180, 90, 30]
            for dir in starDir:
                var starData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"Star")
                var starProjectile = FireComponent.CreateProjectilePosition(null, null, projectile.height, projectile.global_position, Vector2.from_angle(deg_to_rad(dir)) * 500.0, starData, projectile.collisionFlags, projectile.camp)
                starProjectile.projectileBodyNode.rotation_degrees = dir
                starProjectile.checkAll = true
                excludeList.append(starProjectile)
            projectile.Over()
            excludeList.erase(projectile)
            await get_tree().physics_frame
            await get_tree().physics_frame
            if excludeList.size() > 0:
                excludeList.clear()
