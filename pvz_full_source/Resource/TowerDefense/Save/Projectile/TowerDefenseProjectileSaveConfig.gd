class_name TowerDefenseProjectileSaveConfig extends Resource

@export var nodeName: StringName
@export var configName: String
@export var pos: Vector2
@export var velocity: Vector2
@export var speed: float
@export var camp: int
@export var damage: float
@export var collisionFlags: int
@export var damageFlags: int
@export var fireMethodFlags: int
@export var gridPos: Vector2i
@export var height: float
@export var z: float
@export var groundHeight: float
@export var isGround: bool
@export var over: bool
@export var checkAll: bool
@export var fireCharacterName: StringName
@export var targetName: StringName
@export var catapultTime: float
@export var catapultTimer: float
@export var catapultTargetPos: Vector2
@export var catapultControlPoint: Vector2
@export var catapulCheckLast: bool
@export var penetrateNum: int
@export var hitOver: bool
@export var checkDistance: float
@export var fireLength: float
@export var trackOpen: bool
@export var catapultOpen: bool
@export var fireDirX: int
@export var isShooter: bool
@export var spriteSave: Dictionary = {}
@export var useFall: bool
@export var useGravity: bool
@export var ySpeed: float
@export var gravityUse: bool
@export var gravity: float
@export var gravityScale: float

func SaveProjectile(projectile: TowerDefenseProjectile) -> void :
    nodeName = projectile.name.validate_node_name()
    configName = projectile.config.name
    print("[Save] 保存投射物: %s (%s) pos=(%.1f, %.1f) camp=%d damage=%.1f" % [nodeName, configName, projectile.global_position.x, projectile.global_position.y, projectile.camp, projectile.damage])
    pos = projectile.global_position
    velocity = projectile.velocity
    speed = projectile.speed
    camp = projectile.camp
    damage = projectile.damage
    collisionFlags = projectile.collisionFlags
    damageFlags = projectile.damageFlags
    fireMethodFlags = projectile.fireMethodFlags
    gridPos = projectile.gridPos
    height = projectile.height
    z = projectile.z
    groundHeight = projectile.groundHeight
    isGround = projectile.isGround
    over = projectile.over
    checkAll = projectile.checkAll
    fireCharacterName = projectile.fireCharacter.name.validate_node_name() if is_instance_valid(projectile.fireCharacter) else ""
    targetName = projectile.target.name.validate_node_name() if is_instance_valid(projectile.target) else ""
    catapultTime = projectile.catapultTime
    catapultTimer = projectile.catapultTimer
    catapultTargetPos = projectile.catapultTargetPos
    catapultControlPoint = projectile.catapultControlPoint
    catapulCheckLast = projectile.catapulCheckLast
    penetrateNum = projectile.penetrateNum
    hitOver = projectile.hitOver
    checkDistance = projectile.checkDistance
    fireLength = projectile.fireLength
    trackOpen = projectile.trackOpen
    catapultOpen = projectile.catapultOpen
    fireDirX = projectile.fireDirX
    isShooter = projectile.isShooter
    useFall = projectile.useFall
    useGravity = projectile.useGravity
    ySpeed = projectile.ySpeed
    gravityUse = projectile.gravityUse
    gravity = projectile.gravity
    gravityScale = projectile.gravityScale
    if is_instance_valid(projectile.projectileSprite) and projectile.projectileSprite is AdobeAnimateSprite:
        spriteSave = projectile.projectileSprite.ExportSpriteSave()
    print("[Save] 投射物保存完成: %s (%s) 动画=%s fireCharacter=%s target=%s" % [nodeName, configName, "有" if spriteSave.size() > 0 else "无", fireCharacterName, targetName])

func LoadProjectile(owner: TowerDefenseLevelSaveConfig) -> TowerDefenseProjectile:
    print("[Load] 加载投射物: %s (%s) pos=(%.1f, %.1f) camp=%d damage=%.1f" % [nodeName, configName, pos.x, pos.y, camp, damage])
    var charcaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var projectile: TowerDefenseProjectile = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.PROJECTILE, charcaterNode) as TowerDefenseProjectile
    projectile.global_position = pos
    var fireCharacter: TowerDefenseCharacter = null
    if fireCharacterName != "" and owner.charcterDicionary.has(fireCharacterName):
        fireCharacter = owner.charcterDicionary[fireCharacterName]
    var targetCharacter: TowerDefenseCharacter = null
    if targetName != "" and owner.charcterDicionary.has(targetName):
        targetCharacter = owner.charcterDicionary[targetName]
    var projectileConfig: TowerDefenseProjectileConfig = TowerDefenseManager.GetProjectileConfig(configName)
    if projectileConfig == null:
        var projectileData: TowerDefenseProjectileData = TowerDefenseProjectileRegistry.GetProjectile(StringName(configName))
        if projectileData:
            projectileConfig = TowerDefenseProjectileConfig.new()
            projectileConfig.name = projectileData.name
            projectileConfig.size = projectileData.size
            projectileConfig.scale = projectileData.scale
            projectileConfig.projectileScene = projectileData.projectileScene
            projectileConfig.splatAudio = projectileData.splatAudio
            projectileConfig.splatScene = projectileData.splatScene
            projectileConfig.hitEffect = projectileData.hitEffect
            projectileConfig.hitTargetEventList = projectileData.hitTargetEventList
            projectileConfig.hitCharacterEventList = projectileData.hitCharacterEventList
            projectileConfig.hitGroundEventList = projectileData.hitGroundEventList
            projectileConfig.blockHurt = projectileData.blockHurt
            projectileConfig.rotateFollowVelocity = projectileData.rotateFollowVelocity
            projectileConfig.rotateScale = projectileData.rotateScale
            projectileConfig.hitBody = projectileData.hitBody
            projectileConfig.rangeType = projectileData.rangeType
            projectileConfig.useRange = projectileData.useRange
            projectileConfig.rangeSize = projectileData.rangeSize
            projectileConfig.hitPesontage = projectileData.hitPesontage
            var baseConfig: TowerDefenseProjectileConfig = TowerDefenseManager.GetProjectileConfig(configName)
            if baseConfig:
                projectileConfig.damageFlags = baseConfig.damageFlags
                projectileConfig.fireMethodFlags = baseConfig.fireMethodFlags
                projectileConfig.collisionFlags = baseConfig.collisionFlags
                projectileConfig.penetrateNum = baseConfig.penetrateNum
                projectileConfig.penetrateOverBack = baseConfig.penetrateOverBack
                projectileConfig.backOutGround = baseConfig.backOutGround
                projectileConfig.backDuration = baseConfig.backDuration
                projectileConfig.catapultHeight = baseConfig.catapultHeight
                projectileConfig.splatSceneType = baseConfig.splatSceneType
                projectileConfig.hitChestsScale = baseConfig.hitChestsScale
                projectileConfig.hitNutScale = baseConfig.hitNutScale
                projectileConfig.hitFrozenScale = baseConfig.hitFrozenScale
                if !projectileConfig.projectileScene:
                    projectileConfig.projectileScene = baseConfig.projectileScene
                if !projectileConfig.splatScene:
                    projectileConfig.splatScene = baseConfig.splatScene
    projectile.Init(fireCharacter, velocity, projectileConfig, collisionFlags, camp, height, targetCharacter)
    projectile.speed = speed
    projectile.damage = damage
    projectile.fireMethodFlags = fireMethodFlags
    projectile.gridPos = gridPos
    projectile.z = z
    projectile.groundHeight = groundHeight
    projectile.isGround = isGround
    projectile.over = over
    projectile.checkAll = checkAll
    projectile.catapultTime = catapultTime
    projectile.catapultTimer = catapultTimer
    projectile.catapultTargetPos = catapultTargetPos
    projectile.catapultControlPoint = catapultControlPoint
    projectile.catapulCheckLast = catapulCheckLast
    projectile.penetrateNum = penetrateNum
    projectile.hitOver = hitOver
    projectile.checkDistance = checkDistance
    projectile.fireLength = fireLength
    projectile.trackOpen = trackOpen
    projectile.catapultOpen = catapultOpen
    projectile.fireDirX = fireDirX
    projectile.isShooter = isShooter
    projectile.useFall = useFall
    projectile.useGravity = useGravity
    projectile.ySpeed = ySpeed
    projectile.gravityUse = gravityUse
    projectile.gravity = gravity
    projectile.gravityScale = gravityScale
    if is_instance_valid(projectile.projectileSprite) and projectile.projectileSprite is AdobeAnimateSprite and spriteSave.size() > 0:
        projectile.projectileSprite.ImportSpriteSave(spriteSave)
    print("[Load] 投射物加载完成: %s (%s) 动画=%s fireCharacter=%s target=%s" % [nodeName, configName, "已恢复" if spriteSave.size() > 0 else "无", fireCharacterName, targetName])
    return projectile
