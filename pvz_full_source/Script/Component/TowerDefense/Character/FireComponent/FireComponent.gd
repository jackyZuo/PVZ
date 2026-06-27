
class_name FireComponent extends ComponentBase


const TOWER_DEFENSE_PROJECTILE: PackedScene = preload("uid://dyrv5jg4hiu2l")


signal fireReady()

signal confirmProjectile(projectileId: int, projectileData: TowerDefenseProjectileCreateData)

signal fireProjectile(projectile: TowerDefenseProjectile)

signal fireOver()

signal restore()


@onready var state: StateChart = %StateChart


@export var firePosMarker: Array[Marker2D]

@export var checkRayList: Array[RayCast2D]

@export var checkArea: Area2D

@export var checkUse: bool = true
@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var fireAudioName: String = "ProjectileThrow"

@export var fireEventName: String = "fire"

@export var fireOverEventName: String = ""

@export var fireAnimeClipsArray: Array[String] = ["Fire"]

@export var fireAnimeClips: String = "Fire"

@export var fireAnimeTimeScale: float = 1.0

@export var restoreAnimeClips: String = ""

@export var restoreTime: float = 10.0

@export var spliceIdleAnimeClips: String = ""

@export var spliceIdleAnimeTimeScale: float = 1.0

@export var isSpliceSprite: bool = false

@export var spliceSpriteList: Array[AdobeAnimateSprite]

@export var spliceSpriteFireAnimeClipsList: Array[String]

@export var spliceSpriteIdleAnimeClipsList: Array[String]
@export_subgroup("FireSetting")

@export var onlyEmitSignal: bool = false

@export var preExtend: FireComponentExtendBase

@export var fireLength: float = -1

@export var fireDirect: bool = false

@export var fireIntervalBase: float = 1.5

@export var fireInterval: float = 1.5

@export var fireIntervalOffset: float = 0.1

@export var fireNum: int = 1

@export var fireCheckList: Array[FireComponentCheckConfig]

@export var fireProjectileList: Array[FireComponentFireProjectileConfig]

@export var useCollisionEveryPos: bool = false

@export var readyConfirmProjectile: bool = false
@export_subgroup("Setting")

@export var checkAllLine: bool = false

@export var checkLength: float = -1:
    set = SetCheckLength

@export var checkIntervalMax: int = 2

@export var checkHeight: bool = true

@export var airFirst: bool = false

@export var catapultFirstFar: bool = false

@export var randomChoose: bool = false
@export var canTargetGargantuar: bool = true


var mapControl: TowerDefenseMapControl


var parent: TowerDefenseCharacter

var timeScale: float = 1.0

var timer: float = 0.25


var isCheck: bool = false

var checkIntreval: int = 0


var groundRight: float = 0.0


var hasCatPumpkin: bool = false


var firstCharacter: TowerDefenseCharacter



var runningCheck: FireComponentCheckConfig

var runningCheckId: int = 0

var currentFireNum: int = 0

var currentFireEvent: String = ""


var _catPumpkinCheckFrame: int = 0


func GetName() -> String:
    return "FireComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    groundRight = TowerDefenseManager.GetMapGroundRight() + TowerDefenseManager.GetMapGridSize().x

    if is_instance_valid(sprite) && ( !fireCheckList.is_empty() || is_instance_valid(checkArea)):
        state.process_mode = Node.PROCESS_MODE_INHERIT
        sprite.animeCompleted.connect(AnimeCompleted)
        sprite.animeEvent.connect(AnimeEvent)
        if isSpliceSprite:
            parent.useIdleAnimeReset = false
            for spriteId in spliceSpriteList.size():
                spliceSpriteList[spriteId].animeCompleted.connect(AnimeCompleted)

    SetCheckLength(checkLength)

    fireCheckList = fireCheckList.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)
    fireProjectileList = fireProjectileList.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)


func _physics_process(delta: float) -> void :
    if !alive:
        return
    var runScale: float = parent.timeScale * timeScale
    if TowerDefenseManager.IsIZMMode():
        runScale = 1.0
    var frame: int = Engine.get_physics_frames()
    if frame - _catPumpkinCheckFrame >= 30:
        _catPumpkinCheckFrame = frame
        if parent.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.CAT:
            hasCatPumpkin = parent.cell.HasCharacter("PlantCatPumpkin")
    if hasCatPumpkin:
        runScale *= 2.0
    if timer > 0:
        timer -= delta * runScale

    if isCheck:
        checkIntreval -= 1
        isCheck = false



func GetTarget() -> TowerDefenseCharacter:
    return TowerDefenseManager.GetCharacterTargetNearestFromArea(parent, checkArea, TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION, true)





func CanFire(projectileData: TowerDefenseProjectileCreateData, collectionFlag: int = -1) -> bool:
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return false
    if timer > 0:
        return false
    if parent.global_position.x > groundRight:
        return false
    isCheck = true
    if checkIntreval > 0:
        return false
    set_deferred("checkIntreval", checkIntervalMax)
    return _CheckTarget(projectileData, collectionFlag, true)





func CanFireCheckOnce(projectileData: TowerDefenseProjectileCreateData, collectionFlag: int = -1) -> bool:
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return false
    if parent.global_position.x > groundRight:
        return false
    isCheck = true
    return _CheckTarget(projectileData, collectionFlag, false)






func _CheckTarget(projectileData: TowerDefenseProjectileCreateData, collectionFlag: int, checkInterval: bool) -> bool:
    if collectionFlag == -1:
        collectionFlag = parent.instance.collisionFlags
    if !checkRayList.is_empty():
        for ray: RayCast2D in checkRayList:
            if is_instance_valid(CheckRayHit(ray, collectionFlag)):
                return true
    elif checkArea:
        return _CheckAreaTarget(collectionFlag, checkInterval)
    elif projectileData:
        if projectileData.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK || checkAllLine:
            return _CheckTrackTarget(collectionFlag)
    return false





@warning_ignore("unused_parameter")
func _CheckAreaTarget(collectionFlag: int, checkInterval: bool) -> bool:
    if !checkArea.has_overlapping_areas():
        return false
    var areas: Array = TowerDefenseManager.GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var character = area.get_parent()
        if !(character is TowerDefenseCharacter):
            continue

        if character.instance.invincible:
            continue
        if !character.targetRegistrationComponent.canProjectileCheck:
            continue

        if !canTargetGargantuar && character is TowerDefenseZombie && character.instance.zombiePhysique > TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE:
            continue
        if !is_instance_valid(mapControl) || (is_instance_valid(mapControl) && character.global_position.x <= groundRight):
            if !(collectionFlag & character.instance.maskFlags):
                continue
            if !parent.CanTarget(character):
                continue

            if !(checkAllLine || parent.CheckSameLine(character.gridPos.y) || character.targetRegistrationComponent.allLineCheck):
                continue

            if checkHeight:
                if character.instance.height >= mini(TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL, parent.instance.height) || character.instance.height > parent.instance.height:
                    return true
            else:
                return true
    return false




func _CheckTrackTarget(collectionFlag: int) -> bool:
    var characterList: Array = TowerDefenseManager.GetCharacterTarget(parent)
    for character in characterList:
        if !(character is TowerDefenseCharacter):
            continue
        if !character.targetRegistrationComponent.canProjectileCheck:
            continue
        if !canTargetGargantuar && character is TowerDefenseZombie && character.instance.zombiePhysique >= TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE:
            continue
        if character.global_position.x > groundRight:
            continue
        if collectionFlag & character.instance.maskFlags:
            return true
    return false





func CheckRayHit(ray: RayCast2D, collectionFlag: int = -1) -> TowerDefenseCharacter:
    ray.clear_exceptions()
    while (true):
        ray.force_raycast_update()
        if !ray.is_colliding():
            return null
        var area = ray.get_collider()
        if area is Area2D:
            ray.add_exception(area)
            var character = area.get_parent()
            if !(character is TowerDefenseCharacter):
                continue
            if character.instance.invincible:
                continue
            if !character.targetRegistrationComponent.canProjectileCheck:
                continue
            if !parent.CanTarget(character):
                continue
            if !canTargetGargantuar && character is TowerDefenseZombie && character.instance.zombiePhysique >= TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE:
                continue
            if character.global_position.x > groundRight:
                continue
            if !(collectionFlag & character.instance.maskFlags):
                continue
            if !(checkAllLine || parent.CheckSameLine(character.gridPos.y) || character.targetRegistrationComponent.allLineCheck):
                continue
            if checkHeight:
                if !(character.instance.height >= mini(TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL, parent.instance.height) || character.instance.height > parent.instance.height):
                    continue
            firstCharacter = character
            return character
    return null


func Refresh() -> void :
    timer = fireInterval + randf_range( - fireIntervalOffset * 2.0, - fireIntervalOffset)



func SetCheckLength(_checkLength: float) -> void :
    checkLength = _checkLength
    if checkLength != -1:
        if is_instance_valid(checkArea):
            var shape: CollisionShape2D = checkArea.get_child(0)
            shape.shape.b.x = sign(shape.shape.b.x) * checkLength * TowerDefenseManager.GetMapGridSize().x
        if !checkRayList.is_empty():
            for ray: RayCast2D in checkRayList:
                ray.target_position = ray.target_position.normalized() * checkLength * TowerDefenseManager.GetMapGridSize()
    else:
        if is_instance_valid(checkArea):
            var shape: CollisionShape2D = checkArea.get_child(0)
            shape.shape.b.x = sign(shape.shape.b.x) * 2000.0
        if !checkRayList.is_empty():
            for ray: RayCast2D in checkRayList:
                ray.target_position = ray.target_position.normalized() * 2000.0










func CreateProjectile(posId: int, velocity: Vector2, projectileData: TowerDefenseProjectileCreateData, collisionFlags: int = -1, camp: TowerDefenseEnum.CHARACTER_CAMP = parent.camp, offset: Vector2 = Vector2.ZERO, offsetLine: int = 0, filterByLine: bool = false) -> TowerDefenseProjectile:
    if collisionFlags == -1:
        collisionFlags = parent.instance.collisionFlags
    if projectileData == null:
        return null
    var projectileConfig: TowerDefenseProjectileConfig = projectileData.BuildConfig()
    if projectileConfig == null:
        return null
    var pos: Vector2 = parent.global_position
    if firePosMarker.size() > posId:
        pos = firePosMarker[posId].global_position
    var height: float = parent.GetGroundHeight(pos.y) - parent.groundHeight
    var target: TowerDefenseCharacter = null

    if projectileConfig.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.CATAPULT:
        height -= parent.groundHeight
        if is_instance_valid(checkArea) || checkAllLine:
            target = _FindCatapultTarget(collisionFlags, pos, offsetLine, filterByLine)
        elif is_instance_valid(firstCharacter):
            target = firstCharacter
    var projectile: TowerDefenseProjectile = CreateProjectilePosition(parent, target, height, pos, velocity * sign(parent.scale.x * parent.transformPoint.scale.x * parent.sprite.scale.x), projectileData, collisionFlags, camp, offset)
    projectile.gridPos.y = parent.gridPos.y
    projectile.checkHeight = checkHeight
    if projectileConfig.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK:
        target = TowerDefenseManager.GetProjectileTargetNearestProjectile(projectile, collisionFlags, TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION, false)
        if target != null:
            projectile.target = target
    return projectile







@warning_ignore("unused_parameter")
func _FindCatapultTarget(collisionFlags: int, pos: Vector2, offsetLine: int = 0, filterByLine: bool = false) -> TowerDefenseCharacter:
    var target: TowerDefenseCharacter = null
    if checkAllLine:
        var characterList: Array = TowerDefenseManager.GetCharacterTarget(parent, false, true)
        if filterByLine:
            var targetLine: int = clampi(parent.gridPos.y + offsetLine, 1, TowerDefenseManager.GetMapGridNum().y)
            var lineCharacterList: Array = []
            for character in characterList:
                if character.gridPos.y == targetLine:
                    lineCharacterList.append(character)
            characterList = lineCharacterList
        if catapultFirstFar:
            target = TowerDefenseManager.GetCharacterTargetFarthestFromArrayWithCollisionFlags(parent, collisionFlags, characterList, TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION, false, false)
        else:
            target = TowerDefenseManager.GetCharacterTargetNearestFromArrayWithCollisionFlags(parent, collisionFlags, characterList, TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION, false, false)
    else:
        if catapultFirstFar:
            target = TowerDefenseManager.GetCharacterTargetFarthestFromArrayWithCollisionFlags(parent, collisionFlags, TowerDefenseManager.GetCharacterTargetLineFromAreaWithCollisionFlags(parent, collisionFlags, checkArea, false), TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION, false, false)
        else:
            target = TowerDefenseManager.GetCharacterTargetNearestFromArrayWithCollisionFlags(parent, collisionFlags, TowerDefenseManager.GetCharacterTargetLineFromAreaWithCollisionFlags(parent, collisionFlags, checkArea, false), TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION, false, false)
    if !is_instance_valid(target):
        return null
    if !canTargetGargantuar && target is TowerDefenseZombie && target.instance.zombiePhysique >= TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE:
        return null
    return target












static func CreateProjectilePosition(character: TowerDefenseCharacter, target: TowerDefenseCharacter, height: float, pos: Vector2, velocity: Vector2, projectileData: TowerDefenseProjectileCreateData, collisionFlags = -1, camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL, offset: Vector2 = Vector2.ZERO) -> TowerDefenseProjectile:
    if projectileData == null:
        return null
    var projectileConfig: TowerDefenseProjectileConfig = projectileData.BuildConfig()
    if projectileConfig == null:
        return null
    return CreateProjectilePositionWithConfig(character, target, height, pos, velocity, projectileConfig, collisionFlags, camp, offset)












static func CreateProjectilePositionWithConfig(character: TowerDefenseCharacter, target: TowerDefenseCharacter, height: float, pos: Vector2, velocity: Vector2, projectileConfig: TowerDefenseProjectileConfig, collisionFlags = -1, camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL, offset: Vector2 = Vector2.ZERO) -> TowerDefenseProjectile:
    if projectileConfig == null:
        return null
    var charcaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var projectile: TowerDefenseProjectile = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.PROJECTILE, charcaterNode) as TowerDefenseProjectile
    if is_instance_valid(character):
        projectile.global_position = character.global_position + Vector2(pos.x - character.global_position.x, 20.0)
    else:
        projectile.global_position = pos
    projectile.Init(character, velocity, projectileConfig, collisionFlags, camp, height + offset.y + 20, target)
    return projectile






func CanFireByName(projectileName: String, collectionFlag: int = -1, skinName: String = "Default") -> bool:
    var data: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projectileName))
    data.skinName = StringName(skinName)
    return CanFire(data, collectionFlag)


func CanFireByData(projectileData: TowerDefenseProjectileCreateData, collectionFlag: int = -1) -> bool:
    return CanFire(projectileData, collectionFlag)


func CanFireCheckOnceByName(projectileName: String, collectionFlag: int = -1, skinName: String = "Default") -> bool:
    var data: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projectileName))
    data.skinName = StringName(skinName)
    return CanFireCheckOnce(data, collectionFlag)


func CanFireCheckOnceByData(projectileData: TowerDefenseProjectileCreateData, collectionFlag: int = -1) -> bool:
    return CanFireCheckOnce(projectileData, collectionFlag)


func CreateProjectileByName(posId: int, velocity: Vector2, projectileName: String, collisionFlags: int = -1, camp: TowerDefenseEnum.CHARACTER_CAMP = parent.camp, offset: Vector2 = Vector2.ZERO, skinName: String = "Default") -> TowerDefenseProjectile:
    var data: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projectileName))
    data.skinName = StringName(skinName)
    return CreateProjectile(posId, velocity, data, collisionFlags, camp, offset)


func CreateProjectileByData(posId: int, velocity: Vector2, projectileData: TowerDefenseProjectileCreateData, collisionFlags: int = -1, camp: TowerDefenseEnum.CHARACTER_CAMP = parent.camp, offset: Vector2 = Vector2.ZERO) -> TowerDefenseProjectile:
    return CreateProjectile(posId, velocity, projectileData, collisionFlags, camp, offset)


func CreateProjectilePositionById(id: int, target: TowerDefenseCharacter, height: float, pos: Vector2, velocity: Vector2, collisionFlags: int = -1, camp: TowerDefenseEnum.CHARACTER_CAMP = parent.camp, offset: Vector2 = Vector2.ZERO) -> TowerDefenseProjectile:
    var projectileData: TowerDefenseProjectileCreateData = fireCheckList[id].projectile.GetProjetile()
    return CreateProjectilePosition(parent, target, height, pos, velocity, projectileData, collisionFlags, camp, offset)


static func CreateProjectilePositionByName(character: TowerDefenseCharacter, target: TowerDefenseCharacter, height: float, pos: Vector2, velocity: Vector2, projectileName: String, collisionFlags = -1, camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL, offset: Vector2 = Vector2.ZERO, skinName: String = "Default") -> TowerDefenseProjectile:
    var data: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projectileName))
    data.skinName = StringName(skinName)
    return CreateProjectilePosition(character, target, height, pos, velocity, data, collisionFlags, camp, offset)


static func CreateProjectilePositionByData(character: TowerDefenseCharacter, target: TowerDefenseCharacter, height: float, pos: Vector2, velocity: Vector2, projectileData: TowerDefenseProjectileCreateData, collisionFlags = -1, camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL, offset: Vector2 = Vector2.ZERO) -> TowerDefenseProjectile:
    return CreateProjectilePosition(character, target, height, pos, velocity, projectileData, collisionFlags, camp, offset)


static func CreateProjectilePositionByConfig(character: TowerDefenseCharacter, target: TowerDefenseCharacter, height: float, pos: Vector2, velocity: Vector2, projectileConfig: TowerDefenseProjectileConfig, collisionFlags = -1, camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL, offset: Vector2 = Vector2.ZERO) -> TowerDefenseProjectile:
    return CreateProjectilePositionWithConfig(character, target, height, pos, velocity, projectileConfig, collisionFlags, camp, offset)




func IdleEntered() -> void :
    if !alive:
        return
    if is_instance_valid(sprite):
        if spliceIdleAnimeClips != "":
            sprite.SetAnimation(spliceIdleAnimeClips, true, 0.2)
        if isSpliceSprite:
            for spriteId in spliceSpriteList.size():
                if spliceSpriteList[spriteId].HasClip(spliceSpriteIdleAnimeClipsList[spriteId]):
                    if spliceSpriteList[spriteId].clip != spliceSpriteIdleAnimeClipsList[spriteId]:
                        spliceSpriteList[spriteId].SetAnimation(spliceSpriteIdleAnimeClipsList[spriteId], true, 0.2)
    if parent.componentRunning:
        if parent is TowerDefensePlant:
            parent.Idle()


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if is_instance_valid(sprite):
        if spliceIdleAnimeClips != "":
            sprite.timeScale = parent.timeScale * spliceIdleAnimeTimeScale
        if isSpliceSprite:
            for spriteId in spliceSpriteList.size():
                spliceSpriteList[spriteId].timeScale = parent.timeScale * spliceIdleAnimeTimeScale
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if !parent.componentAlive:
        return
    if parent.componentRunning:
        return
    if parent.die || parent.nearDie:
        return
    if is_instance_valid(preExtend):
        if !preExtend.CanRun():
            return
    for checkId in fireCheckList.size():
        var check: FireComponentCheckConfig = fireCheckList[checkId]
        if !checkUse || (checkUse && check.CanFire(self)):
            runningCheck = check
            runningCheckId = checkId
            if !fireDirect:
                if parent is TowerDefensePlant:
                    parent.Component()
                state.send_event("ToAttack")
            else:
                Refresh()
                fireReady.emit()
                Fire()
            return


func IdleExited() -> void :
    pass


func AttackEntered() -> void :
    if readyConfirmProjectile:
        for projectileConfigId in fireProjectileList.size():
            var projectileConfig: FireComponentFireProjectileConfig = fireProjectileList[projectileConfigId]
            if projectileConfig.fireNumSkip != -1:
                if currentFireNum >= projectileConfig.fireNumSkip:
                    continue
            var projectile: FireComponentProjectileResource = fireCheckList[projectileConfig.checkProjectileId].projectile
            if projectile is FireComponentProjectileWeight:
                projectile.RefreshProjectile()
                confirmProjectile.emit(projectileConfigId, projectile.readyProjectile.projectileName)

    Refresh()
    fireReady.emit()
    sprite.SetAnimation(fireAnimeClips, true, 0.2)
    if isSpliceSprite:
        for spriteId in spliceSpriteList.size():
            if spliceSpriteList[spriteId].HasClip(spliceSpriteFireAnimeClipsList[spriteId]):
                spliceSpriteList[spriteId].SetAnimation(spliceSpriteFireAnimeClipsList[spriteId], true, 0.2)


@warning_ignore("unused_parameter")
func AttackProcessing(delta: float) -> void :
    if !is_instance_valid(parent):
        return
    if !is_instance_valid(sprite):
        return
    if parent.die || parent.nearDie:
        return
    if !alive || !parent.componentAlive:
        state.send_event("ToIdle")
    var timeScaleValue: float = parent.timeScale * fireAnimeTimeScale * (fireIntervalBase + fireIntervalBase / 3) / (fireInterval + fireIntervalBase / 3)
    sprite.timeScale = timeScaleValue
    for spliceSprite: AdobeAnimateSprite in spliceSpriteList:
        spliceSprite.timeScale = timeScaleValue


func AttackExited() -> void :
    pass


func RestoreEntered() -> void :
    if !alive:
        return
    if is_instance_valid(sprite):
        if restoreAnimeClips != "":
            sprite.SetAnimation(restoreAnimeClips, true, 0.2)

    restore.emit()


@warning_ignore("unused_parameter")
func RestoreProcessing(delta: float) -> void :
    if !is_instance_valid(parent):
        return
    if !is_instance_valid(sprite):
        return
    if parent.die || parent.nearDie:
        return
    if !alive || !parent.componentAlive:
        state.send_event("ToIdle")
    var animeTime: float = ((sprite.clipRange.y - sprite.clipRange.x) / sprite.flashAnimeData.frameRate)
    sprite.timeScale = parent.timeScale * (animeTime / restoreTime)


func RestoreExited() -> void :
    pass


@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    if !alive:
        return
    if parent.die || parent.nearDie:
        return
    if fireEventName.split("&").has(command):
        currentFireEvent = command
        Fire()
        if fireOverEventName == "":
            currentFireNum += 1
            if currentFireNum == fireNum:
                currentFireNum = 0
            else:
                sprite.SetAnimation(fireAnimeClips, true, 0.1)

    if fireOverEventName != "" && command == fireOverEventName:
        currentFireNum += 1
        if currentFireNum == fireNum:
            currentFireNum = 0
        else:
            sprite.SetAnimation(fireAnimeClips, true, 0.1)


func Fire() -> void :
    AudioManager.AudioPlay(fireAudioName, AudioManagerEnum.TYPE.SFX)
    var hasOffsetLine: bool = false
    for config in fireProjectileList:
        if config.offsetLine != 0:
            hasOffsetLine = true
            break
    for projectileConfigId in fireProjectileList.size():
        var projectileConfig: FireComponentFireProjectileConfig = fireProjectileList[projectileConfigId]
        if projectileConfig.fireEventNeed != "" && currentFireEvent != projectileConfig.fireEventNeed:
            continue
        if projectileConfig.fireNumSkip != -1:
            if currentFireNum >= projectileConfig.fireNumSkip:
                continue
        if onlyEmitSignal:
            fireProjectile.emit(null)
            continue
        var velocity: Vector2 = projectileConfig.speed * Vector2.from_angle(deg_to_rad(projectileConfig.dir))
        var checkConfig: FireComponentCheckConfig = fireCheckList[projectileConfig.checkProjectileId]
        var projectileData: TowerDefenseProjectileCreateData
        if readyConfirmProjectile && currentFireNum == 0 && checkConfig.projectile is FireComponentProjectileWeight:
            projectileData = checkConfig.projectile.readyProjectile
        else:
            projectileData = checkConfig.projectile.GetProjetile()
        if projectileData == null:
            continue
        var collisionFlags: int = 0
        if useCollisionEveryPos:
            if !checkConfig.useParentCollision:
                collisionFlags = checkConfig.collisionFlags
        else:
            collisionFlags = runningCheck.GetCollisionFlags() if is_instance_valid(runningCheck) else checkConfig.GetCollisionFlags()
        var projectile: TowerDefenseProjectile = CreateProjectile(projectileConfig.firePosId, velocity, projectileData, collisionFlags, parent.camp, Vector2.ZERO, projectileConfig.offsetLine, hasOffsetLine)
        projectile.projectileSprite.rotation = deg_to_rad(projectileConfig.dir)
        projectile.projectileBodyNode.scale.x = parent.scale.x
        projectile.gridPos = parent.gridPos
        projectile.checkAll = checkAllLine && !hasOffsetLine
        projectile.fireLength = fireLength
        if projectileConfig.projectileFlip:
            projectile.projectileBodyNode.scale.x = - projectile.projectileBodyNode.scale.x
        var offsetLine: int = clampi(projectile.gridPos.y + projectileConfig.offsetLine, 1, TowerDefenseManager.GetMapGridNum().y)
        var transLine: int = offsetLine - projectile.gridPos.y
        if transLine != 0:
            projectile.gridPos.y += transLine
            if !(projectile.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.CATAPULT):
                projectile.moveTween = create_tween()
                projectile.moveTween.set_ease(Tween.EASE_OUT)
                projectile.moveTween.set_trans(Tween.TRANS_QUAD)
                projectile.moveTween.tween_property(projectile, ^"global_position:y", projectile.global_position.y + TowerDefenseManager.GetMapGridSize().y * transLine, 0.15)
        elif projectileConfig.offsetLine != 0:
            projectile.global_position.x -= 25

        fireProjectile.emit(projectile)


func AnimeCompleted(clip: String) -> void :
    if !alive:
        return

    if restoreAnimeClips != "":
        if clip == restoreAnimeClips:
            state.send_event("ToIdle")

    if isSpliceSprite:
        if spliceSpriteFireAnimeClipsList.has(clip):
            var id: int = spliceSpriteFireAnimeClipsList.find(clip)
            if is_instance_valid(spliceSpriteList[id]):
                spliceSpriteList[id].SetAnimation(spliceSpriteIdleAnimeClipsList[id], true, 0.2)

    if fireAnimeClipsArray.has(clip):
        if currentFireNum == 0:
            fireOver.emit()
            if restoreAnimeClips == "":
                state.send_event("ToIdle")
            else:
                await get_tree().physics_frame
                state.send_event("ToRestore")

func ExportComponentSave() -> Dictionary:
    return {
        "timer": timer, 
        "isCheck": isCheck, 
        "checkIntreval": checkIntreval, 
        "runningCheckId": runningCheckId, 
        "currentFireNum": currentFireNum, 
        "currentFireEvent": currentFireEvent, 
        "hasCatPumpkin": hasCatPumpkin, 
        "fireInterval": fireInterval, 
        "fireIntervalBase": fireIntervalBase, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    timer = _data.get("timer", 0.0)
    isCheck = _data.get("isCheck", false)
    checkIntreval = _data.get("checkIntreval", 0)
    runningCheckId = _data.get("runningCheckId", 0)
    currentFireNum = _data.get("currentFireNum", 0)
    currentFireEvent = _data.get("currentFireEvent", "")
    hasCatPumpkin = _data.get("hasCatPumpkin", false)
    fireInterval = _data.get("fireInterval", fireInterval)
    fireIntervalBase = _data.get("fireIntervalBase", fireIntervalBase)

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {
        "timer": timer, 
        "isCheck": isCheck, 
        "checkIntreval": checkIntreval, 
        "runningCheckId": runningCheckId, 
        "currentFireNum": currentFireNum, 
        "currentFireEvent": currentFireEvent, 
        "hasCatPumpkin": hasCatPumpkin, 
    }
    return data

func SyncDeserialize(_data: Dictionary) -> void :
    timer = _data.get("timer", timer)
    isCheck = _data.get("isCheck", isCheck)
    checkIntreval = _data.get("checkIntreval", checkIntreval)
    runningCheckId = _data.get("runningCheckId", runningCheckId)
    currentFireNum = _data.get("currentFireNum", currentFireNum)
    currentFireEvent = _data.get("currentFireEvent", currentFireEvent)
    hasCatPumpkin = _data.get("hasCatPumpkin", hasCatPumpkin)
