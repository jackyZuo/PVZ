@tool
class_name TowerDefenseProjectile extends TowerDefenseGroundItemBase

@onready var projectileBodyNode: Node2D = %ProjectileBodyNode
@onready var shadowSprite: Sprite2D = %ShadowSprite
@onready var hitBox: Area2D = %HitBox

var over: bool = false

var rememberPos: Vector2 = Vector2.ZERO

var metaData: Variant = null
var checkAll: bool = false
var useFall: bool = false:
    set(_useFall):
        useFall = _useFall
        if useFall:
            isGround = false
            projectileBodyNode.rotation = Vector2(velocity.x, ySpeed).angle()
            shadowSprite.position.y = height
            shadowSprite.scale = Vector2.ZERO
var useGravity: bool = false:
    set(_useGravity):
        useGravity = _useGravity
        if useGravity:
            projectileBodyNode.rotation = Vector2(velocity.x, ySpeed).angle()
            shadowSprite.position.y = height
            shadowSprite.scale = Vector2.ZERO
var fireCharacter: TowerDefenseCharacter = null
var velocity: Vector2 = Vector2.ZERO
var speed: float = 0.0
var config: TowerDefenseProjectileConfig
var camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL
var damage: float = 20.0
var collisionFlags: int = 0
var damageFlags: int = 0
var fireMethodFlags: int = 0
var projectileHeight: TowerDefenseEnum.CHARACTER_HEIGHT = TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL
var checkHeight: bool = false
var height: float = 0.0
var target: TowerDefenseCharacter = null
var magneticTarget: TowerDefenseCharacter = null

var catapultTime: float = 0.0
var catapultTimer: float = 0.0
var catapultTargetPos: Vector2 = Vector2.ZERO
var catapultControlPoint: Vector2 = Vector2.ZERO
var catapulCheckLast: bool = false

var penetrateNum: int = 0

var projectileSprite: Node2D

var hitOver: bool = false

var savePos: Vector2 = Vector2.ZERO
var checkDistance: float = 0.0

var fireLength: float = -1

var rect: Rect2

var trackOpen: bool = false
var catapultOpen: bool = false

var shadowScaleSave: Vector2 = Vector2.ONE

var initSet: bool = false
var initHitList: Array[Area2D]

var setZInterval: int = 2

var moveTween: Tween

var randFreshIndex: int = 0

var fireDirX: int = 1

var isShooter: bool = false
var extId: int = -1
var blocked: bool = false

var methodList: Array[TowerDefenseProjectileMethod] = []

static var _projectileServer: Node = null


var _track_cache_frame: int = -1
var _track_cache_target: TowerDefenseCharacter = null
var _track_cache_valid: bool = false
var _track_search_interval: int = 15
var _track_no_target_interval: int = 60
var _track_consecutive_no_target: int = 0
var _track_force_search: bool = false


static var _track_search_budget: int = 10
static var _track_search_budget_used: int = 0
static var _track_search_budget_frame: int = -1

signal landOver(pos: Vector2, gridPos: Vector2i)

func Refresh() -> void :
    reset_physics_interpolation()
    set_physics_process(true)
    add_to_group("Projectile", true)
    metaData = null
    over = false
    for key in get_meta_list():
        remove_meta(key)
    gravityUse = true
    ySpeed = 0
    z = 0
    scale = Vector2.ONE
    checkAll = false
    useFall = false
    useGravity = false
    fireCharacter = null
    projectileHeight = TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL
    target = null
    magneticTarget = null

    projectileSprite = null

    fireLength = -1
    scale = Vector2.ONE
    projectileBodyNode.rotation = 0.0
    projectileBodyNode.scale.x = 1.0
    projectileBodyNode.position = Vector2.ZERO

    shadowSprite.visible = true
    shadowSprite.scale = Vector2.ZERO
    shadowSprite.position.y = 20
    hitBox.scale = Vector2.ONE
    hitBox.set_deferred("monitoring", false)
    hitBox.set_deferred("monitorable", true)
    trackOpen = false
    catapultOpen = false
    isShooter = false
    extId = -1
    blocked = false
    methodList.clear()

    _track_cache_frame = -1
    _track_cache_target = null
    _track_cache_valid = false
    _track_consecutive_no_target = 0
    for connection in landOver.get_connections():
        landOver.disconnect(connection.callable)

    hitOver = false

    for node in projectileBodyNode.get_children():
        if node.has_meta(TowerDefenseProjectilePool.META_SCENE_KEY):
            TowerDefenseProjectilePool.Push(node)
        elif config != null && config.projectileObject != ObjectManagerConfig.OBJECT.NOONE:
            ObjectManager.PoolPush(config.projectileObject, node)
        else:
            node.queue_free()
    hitBox.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)

func Recycle() -> void :
    if is_instance_valid(moveTween):
        if moveTween.is_running():
            moveTween.kill()
    hitBox.set_deferred("monitoring", false)
    hitBox.set_deferred("monitorable", false)
    hitBox.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
    hitOver = true
    if extId >= 0 && _projectileServer:
        _projectileServer.unregister_projectile(extId)
        extId = -1
    for node in projectileBodyNode.get_children():
        if node.has_meta(TowerDefenseProjectilePool.META_SCENE_KEY):
            TowerDefenseProjectilePool.Push(node)
        elif config.projectileObject != ObjectManagerConfig.OBJECT.NOONE:
            ObjectManager.PoolPush(config.projectileObject, node)
        else:
            node.queue_free()
    remove_from_group("Projectile")
    ySpeed = 0

func Init(_fireCharacter: TowerDefenseCharacter, _velocity: Vector2, _config: TowerDefenseProjectileConfig, _collisionFlags: int = -1, _camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL, _height: float = height, _target: TowerDefenseCharacter = target, isChange: bool = false) -> void :
    config = _config
    if config == null:
        Over()
        return

    projectileSprite = TowerDefenseProjectilePool.Pop(config.projectileScene, projectileBodyNode)
    projectileSprite.scale = config.scale

    fireCharacter = _fireCharacter

    camp = _camp
    velocity = _velocity
    speed = velocity.length()
    target = _target

    fireDirX = sign(velocity.x)

    shadowSprite.scale = config.size / Vector2(65, 65)
    shadowScaleSave = shadowSprite.scale

    if !isChange:
        rememberPos = global_position
        height = _height
        if _collisionFlags == -1:
            if is_instance_valid(fireCharacter):
                collisionFlags = fireCharacter.instance.collisionFlags
            else:
                collisionFlags = config.collisionFlags
        else:
            collisionFlags = _collisionFlags
        projectileBodyNode.rotation = 0
        if is_instance_valid(fireCharacter):
            shadowSprite.position.y = - fireCharacter.GetGroundHeight(global_position.y)
        else:
            shadowSprite.position.y = 20
        projectileBodyNode.position.y = - height
        hitBox.position.y = -20

        savePos = shadowSprite.global_position

        if is_instance_valid(fireCharacter):
            projectileHeight = min(TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL, fireCharacter.instance.height)

        checkHeight = false
    else:
        projectileBodyNode.position.y = - height
        hitBox.position.y = -20

    damage = config.baseDamage
    damageFlags = config.damageFlags
    fireMethodFlags = config.fireMethodFlags

    isShooter = fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.SHOOTER && !useGravity && !useFall

    if fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK:
        SetTrack(isChange)

    if fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.PENETRATE:
        penetrateNum = config.penetrateNum

    if fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.CATAPULT:
        var targePos = Vector2(TowerDefenseManager.GetMapGroundRight(), global_position.y)
        if is_instance_valid(target):
            catapultTargetPos = target.global_position + Vector2(-10 * target.scale.x * target.spriteGroup.scale.x, 0)
        else:
            catapultTargetPos = targePos + Vector2(60, 0)
        shadowSprite.visible = true
        shadowSprite.scale = Vector2.ZERO
        var catapult_gravity: float = 2000.0
        var arc_height: float = config.catapultHeight
        var initial_height: float = max(height, 0.0)
        ySpeed = - sqrt(2.0 * catapult_gravity * arc_height)
        var t_up: float = sqrt(2.0 * arc_height / catapult_gravity)
        var t_down: float = sqrt(2.0 * (initial_height + arc_height) / catapult_gravity)
        var flight_time: float = t_up + t_down
        velocity = (catapultTargetPos - global_position) / flight_time
        z = initial_height
        isGround = false
        catapultTime = flight_time
        catapultTimer = 0.0
        catapultControlPoint = Vector2.ZERO
        catapulCheckLast = false
        catapultOpen = true

    await get_tree().physics_frame
    if fireLength != -1:
        checkDistance = TowerDefenseManager.GetMapGridSize().x * fireLength

    methodList.clear()
    for method: TowerDefenseProjectileMethod in config.methods:
        method = method.duplicate_deep()
        method.projectile = self
        method.Ready()
        methodList.append(method)

    if is_instance_valid(target) || useFall || useGravity:
        hitBox.set_deferred("monitoring", false)
    else:
        hitBox.set_deferred("monitoring", true)
    hitBox.set_deferred("monitorable", true)

func _register_to_server() -> void :
    if !_projectileServer:
        return
    if catapultOpen:
        return
    if useGravity:
        return
    if trackOpen:
        return
    var proj_type: int = 0
    if useFall:
        proj_type = 1
    elif useGravity:
        proj_type = 2
    elif trackOpen:
        proj_type = 3
    elif catapultOpen:
        proj_type = 4

    var target_id: int = 0
    if is_instance_valid(target):
        target_id = target.get_instance_id()

    extId = _projectileServer.register_projectile(
        get_instance_id(), proj_type, 
        velocity, speed, collisionFlags, camp, gridPos.y, 
        checkAll, height, projectileHeight, checkHeight, 
        fireLength, checkDistance, savePos, 
        height, groundHeight, fireDirX, 
        ySpeed, z, gravity, gravityScale, 
        target_id, 
        catapultTime, catapultTargetPos, catapultControlPoint, 
        config.rotateFollowVelocity, config.rotateScale, config.useRange
    )

    if extId >= 0:
        if !trackOpen:
            set_physics_process(false)

func Change(_config: TowerDefenseProjectileConfig, projectileName: StringName, changeprojectileName: StringName, changeCharacter: TowerDefenseCharacter) -> void :
    if !is_instance_valid(fireCharacter):
        fireCharacter = null
    if !is_instance_valid(target):
        target = null
    for method: TowerDefenseProjectileMethod in methodList:
        method.Change(projectileName, changeprojectileName, changeCharacter)
    for node in projectileBodyNode.get_children():
        if node.has_meta(TowerDefenseProjectilePool.META_SCENE_KEY):
            TowerDefenseProjectilePool.Push(node)
        elif config.projectileObject != ObjectManagerConfig.OBJECT.NOONE:
            ObjectManager.PoolPush(config.projectileObject, node)
        else:
            node.queue_free()
    if extId >= 0 && _projectileServer:
        _projectileServer.unregister_projectile(extId)
    extId = -1
    set_physics_process(true)
    Init(fireCharacter, velocity, _config, collisionFlags, camp, height, target, true)

func _ready() -> void :
    randFreshIndex = randi()
    rect = get_viewport().get_visible_rect()
    rect.position.x = -100
    rect.size.x += 200
    if _projectileServer == null:
        _projectileServer = GlobalTowerDefenseServer

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    for method: TowerDefenseProjectileMethod in methodList:
        method.Process(delta)
    if extId == -1 && _projectileServer && !over && methodList.is_empty():
        _register_to_server()

    if trackOpen && extId >= 0:
        _process_track_check()
        return

    if !config.rotateFollowVelocity:
        if config.rotateScale != 0.0:
            projectileSprite.rotation += delta * config.rotateScale * fireDirX
    else:
        if !catapultOpen:
            projectileBodyNode.rotation = velocity.angle()

    if isShooter && !useFall && !useGravity && extId < 0 && !trackOpen:
        _process_shooter(delta)
        return

    if useGravity:
        super._physics_process(delta)
        hitBox.position.y = - z
        shadowSprite.scale = shadowScaleSave * max(1.0 - z / 600.0, 0.0)
        if config.rotateFollowVelocity:
            var visual_velocity: Vector2 = Vector2(velocity.x, ySpeed)
            if visual_velocity.length() > 0.1:
                projectileBodyNode.rotation = visual_velocity.angle()
        if ySpeed >= 0 && z - groundHeight < 60:
            hitBox.set_deferred("monitoring", true)
        if z <= groundHeight:
            hitBox.set_deferred("monitoring", false)
            Land()
            return

    if useFall:
        if (Engine.get_physics_frames() + randFreshIndex) % 5 == 0:
            gridPos = TowerDefenseManager.GetMapGridPos(global_position)
        if is_instance_valid(cell):
            var cellGroundHeight: float = cell.GetGroundHeight()
            if groundHeight != cellGroundHeight:
                groundHeight = cellGroundHeight
        shadowSprite.position.y = - groundHeight
        if z > groundHeight:
            ySpeed += gravity * gravityScale * delta
            z -= ySpeed * delta
            hitBox.set_deferred("monitoring", false)
            if z - groundHeight <= 100:
                hitBox.set_deferred("monitoring", true)
                hitBox.process_mode = Node.PROCESS_MODE_INHERIT
        else:
            hitBox.set_deferred("monitoring", false)
            gridPos = TowerDefenseManager.GetMapGridPos(global_position)
            Land()
            return

    if trackOpen:
        _process_track(delta)

    if !catapultOpen:
        Move(delta)

    if fireLength != -1:
        if savePos.distance_to(global_position) > checkDistance:
            Over()
            return

    if catapultOpen:
        _process_catapult(delta)

func _process_shooter(delta: float) -> void :
    if (Engine.get_physics_frames() + randFreshIndex) % 5 == 0:
        gridPos = TowerDefenseManager.GetMapGridPos(global_position)

    if is_instance_valid(cell):
        var _checkHeight = cell.GetGroundHeight()
        if projectileHeight < TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL:
            _checkHeight -= 50
        elif projectileHeight == TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL:
            _checkHeight -= 20
        if height < _checkHeight:
            HitEffect(null)
            Over()
            return

    if extId < 0:
        global_position += velocity * delta

        if !rect.has_point(projectileBodyNode.global_position):
            Over()
            return

        if fireLength != -1:
            if savePos.distance_to(global_position) > checkDistance:
                Over()

func _process_track(delta: float) -> void :
    var target_valid: bool = is_instance_valid(target)
    if target_valid:
        if !target.targetRegistrationComponent.canProjectileCheck:
            target_valid = false
    if target_valid:
        if target.nearDie || target.die || !CanTarget(target) || !CanCollision(target.instance.maskFlags):
            target_valid = false
    if target_valid:
        if !is_instance_valid(target.hitBox) || target.hitBox.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
            target_valid = false
    if !target_valid:
        target = null
        find_track_target_cached()


    var current_frame: int = Engine.get_physics_frames()

    var current_interval: int = _track_search_interval if is_instance_valid(target) else _track_no_target_interval
    if current_frame % current_interval == 0:
        gridPos = TowerDefenseManager.GetMapGridPos(global_position)
        find_track_target_cached()

    if is_instance_valid(target):
        var targetAngleVector: Vector2 = (target.global_position - global_position).normalized()
        projectileBodyNode.rotation = lerp_angle(projectileBodyNode.rotation, targetAngleVector.angle(), delta * 5.0)
        velocity = targetAngleVector * speed
        if Geometry2D.is_point_in_circle(global_position, target.global_position, 30):
            HitCharacter(target)
    else:
        velocity = Vector2(cos(projectileBodyNode.rotation), sin(projectileBodyNode.rotation)) * speed
        if !rect.has_point(projectileBodyNode.global_position):
            Over()

func _process_track_check() -> void :
    if over:
        return

    var current_interval: int = _track_search_interval if is_instance_valid(target) else _track_no_target_interval
    if (Engine.get_physics_frames() + randFreshIndex) % current_interval != 0:
        return
    var target_valid: bool = is_instance_valid(target)
    if target_valid:
        if !target.targetRegistrationComponent.canProjectileCheck:
            target_valid = false
    if target_valid:
        if target.nearDie || target.die || !CanTarget(target) || !CanCollision(target.instance.maskFlags):
            target_valid = false
    if target_valid:
        if is_instance_valid(target.hitBox) && target.hitBox.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
            target_valid = false
    if !target_valid:
        target = null
        find_track_target_cached()
    if !is_instance_valid(target):
        if extId >= 0 && _projectileServer:
            _projectileServer.unregister_projectile(extId)
            extId = -1
            set_physics_process(true)
        if !rect.has_point(global_position):
            Over()

func _process_catapult(delta: float) -> void :
    catapultTimer += delta
    var catapult_gravity: float = 2000.0
    ySpeed += catapult_gravity * delta
    z -= ySpeed * delta
    global_position += velocity * delta
    projectileBodyNode.position.y = - z
    shadowSprite.scale = shadowScaleSave * max(1.0 - z / 600.0, 0.0)
    hitBox.position.y = - z
    if config.rotateFollowVelocity:
        var visual_velocity: Vector2 = Vector2(velocity.x, ySpeed)
        if visual_velocity.length() > 0.1:
            projectileBodyNode.rotation = visual_velocity.angle()
    if ySpeed > 0 && z - groundHeight < 100 && !blocked:
        hitBox.set_deferred("monitoring", true)
        if !hitOver && is_instance_valid(target) && !target.die && target.targetRegistrationComponent.canProjectileCheck && target.CheckDifferentCamp(camp):
            if global_position.distance_squared_to(target.global_position) < 625:
                HitCharacter(target)
                return
    if z <= groundHeight && ySpeed >= 0:
        z = groundHeight
        ySpeed = 0
        isGround = true
        Land()
        return
    if !rect.has_point(global_position):
        Over()

func Move(delta: float) -> void :
    global_position += velocity * delta
    if useFall || useGravity:
        return
    if !rect.has_point(projectileBodyNode.global_position):
        Over()
        return

func SetZ() -> void :
    projectileBodyNode.position.y = - z
    shadowSprite.scale = shadowScaleSave * max(1.0 - z / 600.0, 0.0)

func HitCharacter(character: TowerDefenseCharacter) -> void :
    if !is_instance_valid(character):
        return
    if character is TowerDefensePlant:
        var checkCell: TowerDefenseCellInstance = character.cell
        if is_instance_valid(checkCell):
            character = checkCell.GetTarget(collisionFlags, camp, true, catapultOpen)
    if !is_instance_valid(character):
        return
    character.ProjectileHurt(self, config)
    for method: TowerDefenseProjectileMethod in methodList:
        method.HitTarget(character)
        damage = method.SetDamage(damage, character)
    for event: TowerDefenseCharacterEventBase in config.hitTargetEventList:
        event.ExecuteProject(self, character)
    if !(character.HasShield() && (damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD)) || \
(fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.SHOOTER && ((character.scale.x > 0.0 && global_position.x > character.global_position.x + 30) || (character.scale.x < 0.0 && global_position.x < character.global_position.x - 30))) || \
(fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.CATAPULT):
        for event: TowerDefenseCharacterEventBase in config.hitCharacterEventList:
            event.ExecuteProject(self, character)
        if config.useRange:
            var pos: Vector2 = TowerDefenseManager.GetMapCellPosCenter(TowerDefenseManager.GetMapGridPos(character.global_position))
            pos.x = character.global_position.x
            TowerDefenseExplode.CreateProjectileExplode(pos, config, [character], camp)
    HitEffect(character)
    var overFlag: bool = true

    if fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.PENETRATE && !trackOpen:
        if config.penetrateNum != -1:
            penetrateNum -= 1
            if penetrateNum > 0:
                overFlag = false
        else:
            overFlag = false

    if overFlag:
        hitOver = true
        if extId >= 0 && _projectileServer:
            _projectileServer.set_projectile_hit_over(extId, true)
        Over()
        return

func HitCheck(area: Area2D) -> void :
    if hitOver:
        return
    if catapultOpen:
        if ySpeed < 0 || z - groundHeight > 60:
            return
    if trackOpen:
        return
    if hitBox.monitoring == false:
        return
    if useGravity:
        if ySpeed < 0 || z - groundHeight > 60:
            return



    var character = area.get_parent()

    if !(character is TowerDefenseCharacter):
        return
    if !checkAll && !character.CheckSameLine(gridPos.y) && !character.targetRegistrationComponent.allLineCheck:
        return

    if !character.targetRegistrationComponent.canProjectileCheck:
        return

    if !character.instance.canBeCollection:
        return

    if !(collisionFlags & character.instance.maskFlags):
        return

    if !character.CheckDifferentCamp(camp):
        return

    if checkHeight:
        if projectileHeight > character.instance.height:
            return
    HitCharacter(character)

func HitEffect(character: TowerDefenseCharacter) -> void :
    if config.hitEffect:
        var effect = config.hitEffect.instantiate()
        if effect is TowerDefenseProjectileEffectBase:
            if is_instance_valid(character):
                effect.Init(gridPos, camp, collisionFlags, character, character.groundHeight)
            elif is_instance_valid(cell):
                effect.Init(gridPos, camp, collisionFlags, null, cell.GetGroundHeight())
        if effect is GPUParticles2DMerge:
            effect.queue_free()
            if is_instance_valid(character):
                effect = TowerDefenseManager.CreateEffectParticlesOnce(config.hitEffect, character.gridPos)
            else:
                effect = TowerDefenseManager.CreateEffectParticlesOnce(config.hitEffect, Vector2.ZERO)
        effect.global_position = hitBox.global_position
        characterNode.add_child(effect)
    if TowerDefenseManager.GetEffectCount() < 100:
        CreatSplat(character)
    if config.splatAudio != "SplatNormal" || (character && character.instance.armorList.size() <= 0):
        PlaySplat()

func CreatSplat(character: TowerDefenseCharacter) -> void :


    if !config.splatScene:
        return
    var splatScene = config.splatScene.instantiate()
    var splatEffect: Variant

    if splatScene is GPUParticles2D:
        splatEffect = TowerDefenseManager.CreateEffectParticlesSceneOnce(splatScene, gridPos)
    if splatScene is AdobeAnimateSprite:
        splatEffect = TowerDefenseManager.CreateEffectSpriteSceneOnce(splatScene, gridPos)
    if splatScene is TowerDefenseEffectSpriteOnce:
        splatEffect = splatScene
    if splatScene is TowerDefenseEffectParticlesOnce:
        splatEffect = splatScene
    characterNode.add_child(splatEffect)



    if character:
        splatEffect.gridPos.y = character.gridPos.y
    else:
        splatEffect.gridPos.y = gridPos.y
    if !config.hitBody || !is_instance_valid(character):
        splatEffect.global_position = projectileBodyNode.global_position
    else:
        splatEffect.global_position = character.global_position - Vector2(0, 20)

func PlaySplat() -> void :
    AudioManager.AudioPlay(config.splatAudio, AudioManagerEnum.TYPE.SFX)

func CanCollision(maskFlags: int) -> bool:
    return maskFlags & collisionFlags

func CanTarget(character: TowerDefenseCharacter) -> bool:
    return CheckDifferentCamp(character.camp)

func CheckDifferentCamp(_camp: TowerDefenseEnum.CHARACTER_CAMP) -> bool:
    return camp != _camp

func CheckSameLine(line: int) -> bool:
    return line == gridPos.y

func Land() -> void :
    gridPos = TowerDefenseManager.GetMapGridPos(global_position)
    if !blocked:
        if config.useRange:
            TowerDefenseExplode.CreateProjectileExplode(global_position, config, [], camp)
        HitEffect(null)
        PlaySplat()
    landOver.emit(global_position, gridPos)
    if is_instance_valid(cell):
        if cell.IsWater():
            CreateSplash()
            Over()
            return
    Over()

func Over() -> void :
    if over:
        return
    over = true
    for method: TowerDefenseProjectileMethod in methodList:
        method.Destroy()
    methodList.clear()

    if extId >= 0 && _projectileServer:
        _projectileServer.unregister_projectile(extId)
        extId = -1
    global_position = Vector2(-100, -100)
    ObjectManager.PoolPush(ObjectManagerConfig.OBJECT.PROJECTILE, self)

func over_from_extension() -> void :
    if over:
        return
    extId = -1
    Over()

func hit_target_from_extension() -> void :
    if over:
        return
    if is_instance_valid(target):
        HitCharacter(target)
    else:
        Over()

func land_from_extension() -> void :
    if over:
        return
    extId = -1
    gridPos = TowerDefenseManager.GetMapGridPos(global_position)
    Land()

func update_grid_pos() -> void :
    gridPos = TowerDefenseManager.GetMapGridPos(global_position)

func check_shooter_height() -> void :
    if is_instance_valid(cell):
        var _checkHeight = cell.GetGroundHeight()
        if projectileHeight < TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL:
            _checkHeight -= 50
        elif projectileHeight == TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL:
            _checkHeight -= 20
        if height < _checkHeight:
            if extId >= 0 && _projectileServer:
                _projectileServer.set_projectile_hit_over(extId, true)
            HitEffect(null)
            Over()

func enable_monitoring() -> void :
    hitBox.set_deferred("monitoring", true)
    hitBox.process_mode = Node.PROCESS_MODE_INHERIT

func disable_monitoring() -> void :
    hitBox.set_deferred("monitoring", false)

func target_died_from_extension() -> void :
    target = null
    _track_cache_valid = false
    find_track_target_cached()


func find_track_target_cached() -> void :
    var current_frame: int = Engine.get_physics_frames()


    var budget_current_frame: int = Engine.get_physics_frames()
    if budget_current_frame != _track_search_budget_frame:
        _track_search_budget_frame = budget_current_frame
        _track_search_budget_used = 0


    if !_track_force_search && _track_search_budget_used >= _track_search_budget:
        return


    if _track_cache_valid && is_instance_valid(_track_cache_target):

        var cache_valid: bool = true
        if !_track_cache_target.targetRegistrationComponent.canProjectileCheck:
            cache_valid = false
        if _track_cache_target.nearDie || _track_cache_target.die || !CanTarget(_track_cache_target) || !CanCollision(_track_cache_target.instance.maskFlags):
            cache_valid = false
        if !is_instance_valid(_track_cache_target.hitBox) || _track_cache_target.hitBox.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
            cache_valid = false
        if cache_valid:
            target = _track_cache_target

            _track_consecutive_no_target = 0
            if is_instance_valid(target) && _projectileServer && extId >= 0:
                _projectileServer.set_projectile_target(extId, target.get_instance_id())
            return


    _find_track_target_internal()

    _track_search_budget_used += 1

    _track_force_search = false

    _track_cache_frame = current_frame
    _track_cache_target = target
    _track_cache_valid = is_instance_valid(target)

    if is_instance_valid(target):
        _track_consecutive_no_target = 0
    else:
        _track_consecutive_no_target += 1


func find_track_target() -> void :
    _find_track_target_internal()

func _find_track_target_internal() -> void :
    if !is_instance_valid(target):
        if is_instance_valid(magneticTarget) && !magneticTarget.nearDie && !magneticTarget.die && CanTarget(magneticTarget) && CanCollision(magneticTarget.instance.maskFlags) && magneticTarget.targetRegistrationComponent.canProjectileCheck:
            if is_instance_valid(magneticTarget.hitBox) && magneticTarget.hitBox.process_mode != ProcessMode.PROCESS_MODE_DISABLED:
                target = magneticTarget
                if is_instance_valid(target) && _projectileServer && extId >= 0:
                    _projectileServer.set_projectile_target(extId, target.get_instance_id())
                return
        var nearest: TowerDefenseCharacter = TowerDefenseManager.GetProjectileTargetNearest(self, collisionFlags)
        if is_instance_valid(nearest):
            target = nearest
            if target is TowerDefensePlant:
                if is_instance_valid(cell):
                    target = cell.GetTarget(collisionFlags, camp)
            if is_instance_valid(target) && _projectileServer && extId >= 0:
                _projectileServer.set_projectile_target(extId, target.get_instance_id())

func BlockedBounce() -> void :
    if over || hitOver:
        return
    blocked = true
    target = null
    hitOver = true
    hitBox.set_deferred("monitoring", false)
    hitBox.set_deferred("monitorable", false)
    if extId >= 0 && _projectileServer:
        _projectileServer.unregister_projectile(extId)
        extId = -1
    set_physics_process(true)
    ySpeed = -500.0
    velocity *= 0.5

func update_catapult_target() -> void :
    if is_instance_valid(target):
        catapultTargetPos = target.transformPoint.global_position + Vector2(-10 * fireDirX * target.scale.x * target.spriteGroup.scale.x, -10)
        catapultTargetPos.y = max(catapultTargetPos.y, target.global_position.y) - 30

func CreateSplash() -> TowerDefenseEffectSpriteOnce:
    if TowerDefenseManager.GetEffectCount() > 100:
        return
    var effect = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.PARTICLES_SPLASH, characterNode)
    effect.gridPos = gridPos
    effect.global_position = shadowSprite.global_position - Vector2(0, 20)
    return effect


func SetTrack(isChange: bool = false) -> void :
    gridPos.y = 10
    trackOpen = true
    checkAll = true
    shadowSprite.visible = false
    penetrateNum = 0
    if !isChange:
        global_position.y = projectileBodyNode.global_position.y
        projectileBodyNode.position.y = 0

    _track_cache_frame = -1
    _track_cache_target = null
    _track_cache_valid = false
    _track_consecutive_no_target = 0
    _track_force_search = true

    if config != null:
        _track_search_interval = config.trackSearchInterval

        _track_no_target_interval = config.trackSearchInterval * 4
    hitBox.position.y = -20
    hitBox.set_deferred(&"position", Vector2(hitBox.position.x, 0.0))
    if extId >= 0 && _projectileServer:
        _projectileServer.unregister_projectile(extId)
        extId = -1
        set_physics_process(true)
