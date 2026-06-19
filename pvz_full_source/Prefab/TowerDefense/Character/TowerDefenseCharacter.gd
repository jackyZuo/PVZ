@tool
class_name TowerDefenseCharacter extends TowerDefenseGroundItemBase

var sync_id: int = -1

const FIRE = preload("uid://c4fjg42kgeupv")
const ICE_FIRE = preload("uid://bvuvd1ircxhxn")
const MEGA_FIRE = preload("uid://c61k0gdy05vo4")
const PURIFY_FIRE = preload("uid://cxmk8jiq0nkjg")
const WHITE_FIRE = preload("uid://dsxnymbe4mghd")

const SNOW_FLAKES = preload("uid://b1ba7ajcvcgj8")
const HEALTH = preload("uid://b8c40r4tk45sf")

const FRAME_CHECK_INTERVAL: = 5
const NEAR_DEATH_DAMAGE_DIVISOR: = 3.0

@warning_ignore("unused_signal")
signal destroy(character: TowerDefenseCharacter)
@warning_ignore("unused_signal")
signal bodyHurt(num: int)
@warning_ignore("unused_signal")
signal armorHurt(num: int)
@warning_ignore("unused_signal")
signal riseOver()

@warning_ignore("unused_signal")
signal componentChange()

@onready var backEffectNode: Node2D = %BackEffectNode
@onready var frontEffectNode: Node2D = %FrontEffectNode

@onready var spriteGroup: Node2D = %SpriteGroup
@onready var transformPoint: Marker2D = $SpriteGroup / TransformPoint

@onready var shadowSprite: Sprite2D = %ShadowSprite
@onready var icetrapSprite: Sprite2D = %IcetrapSprite
@onready var hitBox: Area2D = %HitBox

@onready var state: StateChart = %StateChart
@onready var showHealthComponent: ShowHealthComponent = %ShowHealthComponent
@onready var componentManager: ComponentManager = %ComponentManager
var buff: BuffComponent
var shadowComponent: ShadowComponent
var targetRegistrationComponent: TargetRegistrationComponent
var riseComponent: RiseComponent
var destroyComponent: DestroyComponent
var hitFlashComponent: HitFlashComponent
var shaderEffectComponent: ShaderEffectComponent
var blowBackComponent: BlowBackComponent
var sleepComponent: SleepComponent
var resourceSpawnComponent: ResourceSpawnComponent
var groundHeightComponent: GroundHeightComponent
var damagePartComponent: DamagePartComponent
var hurtComponent: HurtComponent
var hypnosesComponent: HypnosesComponent
var armorVisualComponent: ArmorVisualComponent
var customVisualComponent: CustomVisualComponent
var recycleComponent: RecycleComponent
var effectCreateComponent: EffectCreateComponent

@export var invisible: bool = false:
    set(_invisible):
        if invisible != _invisible:
            invisible = _invisible
            if !is_node_ready():
                await ready
            if invisible:
                sprite.invisible = true
                sprite.visible = false
                shadowSprite.visible = false
                if is_instance_valid(shadowComponent):
                    shadowComponent.SetVisible(false)
                showHealthComponent.visible = false
            else:
                sprite.invisible = false
                sprite.visible = true
                shadowSprite.visible = !inWater
                if is_instance_valid(shadowComponent):
                    shadowComponent.SetVisible( !inWater)
                showHealthComponent.visible = true
@export var idleAnimeClip: String = "Idle"
@export var sleepAnimeClip: String = "Idle"

@export var config: TowerDefenseCharacterConfig:
    set(_config):
        config = _config
        currentCustom = []
        DamagePartInit()
        notify_property_list_changed()
@export var sprite: AdobeAnimateSprite:
    set(_sprite):
        sprite = _sprite
        if config && config.customData && sprite:
            SetCustoms(currentCustom)
        DamagePartInit()
        notify_property_list_changed()
@export var headSlot: AdobeAnimateSlot:
    set(_headSlot):
        headSlot = _headSlot
        DamagePartInit()
        notify_property_list_changed()
@export var camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.PLANT
@export var damagePartClip: String = "particles":
    set(_damagePartClip):
        damagePartClip = _damagePartClip
        DamagePartInit()
        notify_property_list_changed()

@export var damagePart: Dictionary = {}
var damagePartList: Array[String] = []
var damagePartSlot: Dictionary = {}

var previewDamagePointPersontage: float = 1.0:
    set(_previewDamagePointPersontage):
        previewDamagePointPersontage = _previewDamagePointPersontage
        if config && config.damagePointData && sprite:
            PreviewDamagePoint(previewDamagePointPersontage)
            pass

var currentArmor: Array[String] = []:
    set(armor):
        currentArmor = armor
        if config && config.armorData && sprite:
            SetArmors(currentArmor)

var currentCustom: Array[String] = []:
    set(custom):
        currentCustom = custom
        if config && config.customData && sprite:
            SetCustoms(currentCustom)

var instance: TowerDefenseCharacterInstance

var componentAlive: bool = true
var componentRunning: bool = false

var characterFilter: bool = false

var timeScaleInit: float = 1.0
var timeScale: float = 1.0
var timeScaleSave: float = 1.0

var dieEvent: Array[TowerDefenseCharacterEventBase] = []

var inGame: bool = true
var isShow: bool = false
var packet: TowerDefensePacketConfig
var cost: float = 0.0
var nearDie: bool = false
var die: bool = false

var canMowerMove: bool = false

var baseSpriteScale: Vector2

var isRise: bool = false

var isShovel: bool = false
var isSmash: bool = false
var isExplode: bool = false
var isChomp: bool = false
var skipDestroySet: bool = false

var inWater: bool = false:
    set(_inWater):
        if inWater != _inWater:
            inWater = _inWater
            if inGame:
                if _inWater:
                    InWater()
                else:
                    OutWater()

var iceSpeedDown: bool = false

var useIdleAnimeReset: bool = true

var _sync_applying_animation: bool = false

var isUnlimitedFire: bool = false

var randFreshIndex: int = 0

var groundRight: float

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    if config:
        if config.damagePointData:
            properties.append(
                {
                    "name": "PreviewDamagePointPersontage", 
                    "type": TYPE_FLOAT, 
                    "hint": PROPERTY_HINT_RANGE, 
                    "hint_string": "0.0,1.0,0.01", 
                }
            )
        if config.armorData:
            properties.append(
                {
                    "name": "Armor", 
                    "type": TYPE_ARRAY, 
                    "hint": PROPERTY_HINT_ENUM, 
                    "hint_string": "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM, ",".join(config.armorData.armorDictionary.keys())], 
                }
            )
        if config.customData:
            properties.append(
                {
                    "name": "Custom", 
                    "type": TYPE_ARRAY, 
                    "hint": PROPERTY_HINT_ENUM, 
                    "hint_string": "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM, ",".join(config.customData.customDictionary.keys())], 
                }
            )

    if damagePartList.size() > 0:
        for damagePartName in damagePartList:
            properties.append(
                {
                    "name": "DamagePartSlot/" + damagePartName, 
                    "type": TYPE_NODE_PATH, 
                    "hint": PROPERTY_HINT_NODE_PATH_VALID_TYPES, 
                    "hint_string": "AdobeAnimateSlot"
                }
            )
    return properties

func _set(property: StringName, value: Variant) -> bool:
    match property:
        "PreviewDamagePointPersontage":
            previewDamagePointPersontage = value
            return true
        "Armor":
            var armorArray: Array[String] = []
            for item in value:
                armorArray.append(str(item))
            currentArmor = armorArray
            return true
        "Custom":
            var customArray: Array[String] = []
            for item in value:
                customArray.append(str(item))
            currentCustom = customArray
            return true
    if property.begins_with("DamagePartSlot"):
        damagePartSlot[property.trim_prefix("DamagePartSlot/")] = value
        return true
    return false

func _get(property: StringName) -> Variant:
    match property:
        "PreviewDamagePointPersontage":
            return previewDamagePointPersontage
        "Armor":
            return currentArmor
        "Custom":
            return currentCustom
    if property.begins_with("DamagePartSlot"):
        return damagePartSlot.get(property.trim_prefix("DamagePartSlot/"))
    return null

func _property_can_revert(property: StringName) -> bool:
    match property:
        "PreviewDamagePointPersontage":
            return true
        "Armor":
            return true
        "Custom":
            return true
    if property.begins_with("DamagePartSlot"):
        return true
    return false

func _property_get_revert(property: StringName) -> Variant:
    match property:
        "PreviewDamagePointPersontage":
            return 1.0
        "Custom":
            return Array([], TYPE_STRING, "", null)
        "Armor":
            return Array([], TYPE_STRING, "", null)
    if property.begins_with("DamagePartSlot"):
        return null
    return null

func _ready() -> void :
    super._ready()
    randFreshIndex = randi()
    groundRight = TowerDefenseManager.GetMapGroundRight()

    if is_instance_valid(componentManager):
        buff = componentManager.GetComponentFromType("BuffComponent")
        shadowComponent = componentManager.GetComponentFromType("ShadowComponent")
        targetRegistrationComponent = componentManager.GetComponentFromType("TargetRegistrationComponent")
        riseComponent = componentManager.GetComponentFromType("RiseComponent")
        destroyComponent = componentManager.GetComponentFromType("DestroyComponent")
        hitFlashComponent = componentManager.GetComponentFromType("HitFlashComponent")
        shaderEffectComponent = componentManager.GetComponentFromType("ShaderEffectComponent")
        blowBackComponent = componentManager.GetComponentFromType("BlowBackComponent")
        sleepComponent = componentManager.GetComponentFromType("SleepComponent")
        resourceSpawnComponent = componentManager.GetComponentFromType("ResourceSpawnComponent")
        groundHeightComponent = componentManager.GetComponentFromType("GroundHeightComponent")
        damagePartComponent = componentManager.GetComponentFromType("DamagePartComponent")
        hurtComponent = componentManager.GetComponentFromType("HurtComponent")
        hypnosesComponent = componentManager.GetComponentFromType("HypnosesComponent")
        armorVisualComponent = componentManager.GetComponentFromType("ArmorVisualComponent")
        customVisualComponent = componentManager.GetComponentFromType("CustomVisualComponent")
        recycleComponent = componentManager.GetComponentFromType("RecycleComponent")
        effectCreateComponent = componentManager.GetComponentFromType("EffectCreateComponent")
        if is_instance_valid(shadowComponent):
            shadowComponent.Init()
        if is_instance_valid(shaderEffectComponent):
            shaderEffectComponent.Init()

    if inGame:
        state.process_mode = Node.PROCESS_MODE_INHERIT
    else:
        if is_instance_valid(showHealthComponent):
            showHealthComponent.visible = false
    if !TowerDefenseManager.IsGameRunning():
        state.process_mode = Node.PROCESS_MODE_DISABLED
        if is_instance_valid(shadowComponent):
            shadowComponent.UpdateShadow()

    instance = TowerDefenseCharacterInstance.new(self, config)
    instance.damagePointReach.connect(DamagePointReach)
    instance.hitpointsNearDie.connect(HitpointsNearDie)
    instance.hitpointsEmpty.connect(HitpointsEmpty)
    instance.armorDamagePointReach.connect(ArmorDamagePointReach)
    instance.armorHitpointsEmpty.connect(ArmorHitpointsEmpty)
    sprite.animeCompleted.connect(AnimeCompleted)
    sprite.animeEvent.connect(AnimeEvent)
    sprite.animeStarted.connect(_on_anime_started)

    spriteGroup.position.y = - z

    add_to_group("Character", true)
    TowerDefenseManager.CharacterRegister(self)
    add_to_group(config.name, true)
    if is_instance_valid(config.customData) && packet:
        var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue(packet.saveKey)
        if packetValue.get_or_add("Key", {}).get_or_add("Custom", "") != "":
            var customKey: String = packetValue["Key"]["Custom"]
            if config.customData.customDictionary.has(customKey):
                currentCustom = [customKey]
            else:
                packetValue["Key"]["Custom"] = ""
                GameSaveManager.SetTowerDefensePacketValue(packet.saveKey, packetValue)

    if CanSleep():
        Sleep()

    isUnlimitedFire = TowerDefenseManager.IsUnlimitedFire()
    if isUnlimitedFire:
        UnlimitedFireInit.call_deferred()

    targetRegistrationComponent.RegisterTarget()

    BattleEventBus.characterSkinSwitched.connect(_OnCharacterSkinSwitched)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    if sprite.meshColor != Color.WHITE:
        sprite.meshColor = Color.WHITE
    var is_client_zombie: bool = Global.isMultiplayerMode and !MultiPlayerManager.isHost and self is TowerDefenseZombie
    if is_instance_valid(blowBackComponent) && blowBackComponent.blowBack:
        if global_position.x <= groundRight:
            global_position.x += blowBackComponent.blowBackNum * delta
    if (Engine.get_physics_frames() + randFreshIndex) % FRAME_CHECK_INTERVAL == 0:
        if ShouldUpdateGridPos():
            if inGame:
                gridPos = TowerDefenseManager.GetMapGridPos(global_position)
        if !is_instance_valid(hitBox):
            hitBox = null

    timeScale = timeScaleInit
    buff.BuffUpdate(delta)
    if !IsDie():
        if nearDie:
            if !is_client_zombie:
                instance.DealHurt(config.hitpointsNearDeath * delta / NEAR_DEATH_DAMAGE_DIVISOR, false)



func DamagePartInit() -> void :
    damagePartList = []
    damagePart = {}
    if sprite:
        if config:
            if config.damagePointData:
                var damagePointList: Array[CharacterDamagePointConfig] = config.damagePointData.damagePointList
                for damagePoint: CharacterDamagePointConfig in damagePointList:
                    if !damagePoint.isDrop:
                        continue
                    var damagePointName: String = damagePoint.damagePointName
                    damagePart[damagePointName] = damagePoint
                    damagePartList.append(damagePointName)
            if config.armorData:
                var armorList: Array[CharacterArmorConfig] = config.armorData.armorList
                for armor: CharacterArmorConfig in armorList:
                    if !armor.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.DROPABLE:
                        continue
                    var armorName: String = armor.armorName
                    damagePart[armorName] = armor
                    damagePartList.append(armorName)

func PreviewDamagePoint(persontage: float) -> void :
    config.damagePointData.ClearDamagePointFliters(sprite)
    for damagePointName: String in config.damagePointData.damagePointDictionary.keys():
        var damagePointConfig: CharacterDamagePointConfig = config.damagePointData.damagePointDictionary[damagePointName]["Config"]
        if persontage <= damagePointConfig.damagePersontage:
            config.damagePointData.SetDamagePointFliters(sprite, damagePointConfig.damagePointName)
            if config.customData:
                for customName: String in currentCustom:
                    config.customData.SetDamagePoint(sprite, customName, config.damagePointData.damagePointDictionary.keys().find(damagePointName))

func ClearArmor(armor: String) -> void :
    if is_instance_valid(armorVisualComponent):
        armorVisualComponent.ClearArmor(armor)
        return
    config.armorData.ClearArmorFliters(sprite, armor)

func ClearArmorAll() -> void :
    if is_instance_valid(armorVisualComponent):
        armorVisualComponent.ClearArmorAll()
        return
    config.armorData.ClearArmorFlitersAll(sprite)

func SetArmor(armor: String, stage: int) -> void :
    if is_instance_valid(armorVisualComponent):
        armorVisualComponent.SetArmor(armor, stage)
        return
    ClearArmor(armor)
    config.armorData.OpenArmorFliters(sprite, armor)
    config.armorData.SetArmorReplace(sprite, armor, stage)

func SetArmors(armorList: Array[String]) -> void :
    if is_instance_valid(armorVisualComponent):
        armorVisualComponent.SetArmors(armorList)
        return
    ClearArmorAll()
    for armor: String in armorList:
        if armor != "":
            SetArmor(armor, 0)

func ClearCustom() -> void :
    if is_instance_valid(customVisualComponent):
        customVisualComponent.ClearCustom()
        return
    config.customData.ClearCustomFliters(sprite)

func SetCustom(custom: String) -> void :
    if is_instance_valid(customVisualComponent):
        customVisualComponent.SetCustom(custom)
        return
    config.customData.SetCustomFliters(sprite, custom)

func SetCustoms(customList: Array[String]) -> void :
    if is_instance_valid(customVisualComponent):
        customVisualComponent.SetCustoms(customList)
        return
    ClearCustom()
    for custom: String in customList:
        if custom != "":
            SetCustom(custom)

func _OnCharacterSkinSwitched(packetSaveKey: String, customKey: String) -> void :
    if !is_instance_valid(packet):
        return
    if packet.saveKey != packetSaveKey:
        return
    SwitchCustom(customKey)

func SwitchCustom(customKey: String) -> void :
    if !is_instance_valid(config) || !is_instance_valid(config.customData):
        return
    if customKey == "":
        currentCustom = []
        OnCustomSwitched("")
        return
    if !config.customData.customDictionary.has(customKey):
        return
    currentCustom = [customKey]
    if is_instance_valid(packet):
        var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue(packet.saveKey)
        packetValue.get_or_add("Key", {})["Custom"] = customKey
        GameSaveManager.SetTowerDefensePacketValue(packet.saveKey, packetValue)
    OnCustomSwitched(customKey)

@warning_ignore("unused_parameter")
func OnCustomSwitched(customKey: String) -> void :
    pass





func IdleEntered() -> void :
    sprite.timeScale = timeScale
    if useIdleAnimeReset && idleAnimeClip != "":
        sprite.SetAnimation(idleAnimeClip, true, 0.2)

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    if CanSleep():
        Sleep()

func IdleExited() -> void :
    pass

func SleepEntered() -> void :
    sleepComponent.SleepEntered()

@warning_ignore("unused_parameter")
func SleepProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    sleepComponent.SleepProcessing(delta)

func SleepExited() -> void :
    sleepComponent.SleepExited()

func ComponentEntered() -> void :
    componentRunning = true

func ComponentExited() -> void :
    componentRunning = false

func Idle() -> void :
    state.send_event("ToIdle")

func Sleep() -> void :
    state.send_event("ToSleep")

func Component() -> void :
    state.send_event("ToComponent")

func IsDie() -> bool:
    return die

func CanSleep() -> bool:
    return sleepComponent.CanSleep()

func IsSleep() -> bool:
    return instance.sleep





func GetTotalHitPoint() -> float:
    var hitPoint: float = config.hitpoints + config.hitpointsNearDeath
    var armorList: Array[TowerDefenseArmorInstance] = GetArmor()
    for armor: TowerDefenseArmorInstance in armorList:
        hitPoint += armor.config.damagePoint
    return hitPoint * instance.hitpointScale

func GetCurrentHitPoint() -> float:
    var hitPoint: float = instance.hitpoints
    var armorList: Array[TowerDefenseArmorInstance] = GetArmor()
    for armor: TowerDefenseArmorInstance in armorList:
        hitPoint += armor.hitPoints
    return hitPoint

func DamagePartCreate(damagePointName: StringName, node: Node2D, velocity: Vector2 = Vector2(randf_range(-100, 100), -300), keepSlotScale: bool = true, offset: Vector2 = Vector2.ZERO, from_sync: bool = false) -> void :
    damagePartComponent.DamagePartCreate(damagePointName, node, velocity, keepSlotScale, offset, from_sync)

func MagnetCreate(armorInstance: TowerDefenseArmorInstance, node: Node2D) -> TowerDefenseMagnet:
    return damagePartComponent.MagnetCreate(armorInstance, node)

func ArmorDraw(armor: TowerDefenseArmorInstance) -> TowerDefenseMagnet:
    return damagePartComponent.ArmorDraw(armor)

func HasShield() -> bool:
    return instance.armorShield.size() > 0

func HasHelm() -> bool:
    return instance.armorHelm.size() > 0

func GetHasArmor(armorName: String) -> bool:
    for armor: TowerDefenseArmorInstance in GetArmor():
        if armor.config.armorName == armorName:
            return true
    return false

func GetArmorFromName(armorName: String) -> TowerDefenseArmorInstance:
    for armor: TowerDefenseArmorInstance in GetArmor():
        if armor.config.armorName == armorName:
            return armor
    return null

func GetArmor() -> Array[TowerDefenseArmorInstance]:
    return instance.armorList

func GetArmorShield() -> Array[TowerDefenseArmorInstance]:
    return instance.armorShield

func GetArmorHelment() -> Array[TowerDefenseArmorInstance]:
    return instance.armorHelm

func GetArmorHeadCover() -> Array[TowerDefenseArmorInstance]:
    return instance.armorHeadCover

func CanCollision(maskFlags: int) -> bool:
    return maskFlags & instance.collisionFlags

func CanTarget(character: TowerDefenseCharacter) -> bool:
    return CheckDifferentCamp(character.camp)

func CheckDifferentCamp(_camp: TowerDefenseEnum.CHARACTER_CAMP) -> bool:
    return camp != _camp

func CheckSameLine(line: int) -> bool:
    return line == gridPos.y

func GetGroundHeight(posHieght: float) -> float:
    return global_position.y - posHieght + groundHeight

func SetSpriteGroupShaderParameter(property: String, value: Variant) -> void :
    shaderEffectComponent.SetSpriteGroupShaderParameter(property, value)

const SHADER_EFFECT_FLAGS: Dictionary = {
    "ash": 1, 
    "iceSpeedDown": 2, 
    "cover": 4, 
    "hypnoses": 8, 
    "imitater": 16, 
    "redHeat": 32, 
    "puzzle": 64, 
    "poisoning": 128, 
    "blink": 256, 
    "hologram": 512, 
}

var _shaderNodes: Array[AdobeAnimateSpriteBase] = []

func _CollectShaderNodes() -> void :
    _shaderNodes.clear()
    _CollectShaderNodesRecursive(sprite)

func _CollectShaderNodesRecursive(parent: Node2D) -> void :
    if parent is AdobeAnimateSpriteBase:
        _shaderNodes.append(parent)
    for child in parent.get_children():
        _CollectShaderNodesRecursive(child)

func SetChildShaderParameter(parent: Node2D, property: String, value: Variant) -> void :
    if is_instance_valid(shaderEffectComponent):
        shaderEffectComponent.SetChildShaderParameter(parent, property, value)
        return
    if !is_instance_valid(parent):
        return
    if SHADER_EFFECT_FLAGS.has(property):
        var flag: int = SHADER_EFFECT_FLAGS[property]
        if parent is AdobeAnimateSpriteBase:
            var _material: ShaderMaterial = parent.material as ShaderMaterial
            if _material:
                var current: int = _material.get_shader_parameter("effectFlags") if _material.get_shader_parameter("effectFlags") != null else 0
                if value:
                    current |= flag
                else:
                    current &= ~ flag
                _material.set_shader_parameter("effectFlags", current)
        for child in parent.get_children():
            SetChildShaderParameter(child, property, value)
        return
    if parent is AdobeAnimateSpriteBase:
        var _material: ShaderMaterial = parent.material as ShaderMaterial
        if _material:
            _material.set_shader_parameter(property, value)
    for child in parent.get_children():
        SetChildShaderParameter(child, property, value)

func SetZ() -> void :
    super.SetZ()
    if is_instance_valid(spriteGroup):
        spriteGroup.position.y = - z





func ShovelDestroy() -> void :
    destroyComponent.ShovelDestroy()

func Destroy(freeInstance: bool = true) -> void :
    destroyComponent.Destroy(freeInstance)

func AshDestroy() -> void :
    destroyComponent.AshDestroy()

func SmashDestroy() -> void :
    destroyComponent.SmashDestroy()

func DestroyReplace() -> void :
    pass

func DestroySet() -> void :
    await get_tree().physics_frame

func HitBoxDestroy() -> void :
    destroyComponent.HitBoxDestroy()

var isDestroy: bool = false





func HurtWithAttackConfig(attackConfig: AttackConfig, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    return hurtComponent.HurtWithAttackConfig(attackConfig, playSplatAudio, velocity, createDamagePart)

func Hurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    return hurtComponent.Hurt(num, playSplatAudio, velocity, createDamagePart)

func SkipInvincibleHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    return hurtComponent.SkipInvincibleHurt(num, playSplatAudio, velocity, createDamagePart)

func Health(num: float) -> void :
    hurtComponent.Health(num)

func BowlingHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, hitShield: bool = true, createDamagePart: bool = true) -> float:
    return hurtComponent.BowlingHurt(num, playSplatAudio, velocity, hitShield, createDamagePart)

func SmashHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    return hurtComponent.SmashHurt(num, playSplatAudio, velocity)

func ExplodeHurt(num: float, type: String = "Bomb", playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    return hurtComponent.ExplodeHurt(num, type, playSplatAudio, velocity)

func FlagHurt(num: float, damageFlags: int, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    return hurtComponent.FlagHurt(num, damageFlags, playSplatAudio, velocity)

func ProjectileHurt(projectile: TowerDefenseProjectile, projectileConfig: TowerDefenseProjectileConfig, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, isRange: bool = false) -> float:
    return hurtComponent.ProjectileHurt(projectile, projectileConfig, playSplatAudio, velocity, isRange)

func Bright(init: float = 0.5, delay: float = 0.0, rise: float = 0.5, riseDuration: float = 0.0, duration: float = 0.2) -> void :
    if is_instance_valid(hitFlashComponent):
        hitFlashComponent.Bright(init, delay, rise, riseDuration, duration)

func White(init: float = 1.0, delay: float = 0.0, duration: float = 0.5) -> void :
    if is_instance_valid(hitFlashComponent):
        hitFlashComponent.White(init, delay, duration)

func SpawnPacket(packetConfig: TowerDefensePacketConfig, pos: Vector2, aliveTime: float, isFall: bool, useCost: bool = false) -> TowerDefenseInGamePacketShow:
    return resourceSpawnComponent.SpawnPacket(packetConfig, pos, aliveTime, isFall, useCost)

func YBCreate(pos: Vector2, num: int, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _collect: bool = false) -> void :
    resourceSpawnComponent.YBCreate(pos, num, _velocity, _gravity, _collect)

func CoinCreate(pos: Vector2, num: int, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _collect: bool = false) -> void :
    resourceSpawnComponent.CoinCreate(pos, num, _velocity, _gravity, _collect)

func LuckyBagCreate(pos: Vector2, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0) -> void :
    resourceSpawnComponent.LuckyBagCreate(pos, _velocity, _gravity)

func SunCreate(pos: Vector2, sunNum: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _moveStopTime: float = -1) -> TowerDefenseSunBase:
    return resourceSpawnComponent.SunCreate(pos, sunNum, movingMethod, _velocity, _gravity, _moveStopTime)

func BrainSunCreate(pos: Vector2, sunNum: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _moveStopTime: float = -1) -> TowerDefenseSunBase:
    return resourceSpawnComponent.BrainSunCreate(pos, sunNum, movingMethod, _velocity, _gravity, _moveStopTime)

func JalapenoSunCreate(pos: Vector2, sunNum: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _moveStopTime: float = -1) -> TowerDefenseSunBase:
    return resourceSpawnComponent.JalapenoSunCreate(pos, sunNum, movingMethod, _velocity, _gravity, _moveStopTime)

func ExplodeSunCreate(pos: Vector2, sunNum: int, sunOnce: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, _speed: float = 0.0, _gravity: float = 0.0, _moveStopTime: float = -1) -> void :
    resourceSpawnComponent.ExplodeSunCreate(pos, sunNum, sunOnce, movingMethod, _speed, _gravity, _moveStopTime)

func CraterCreate(nolimit: bool = false, craterName: String = "CraterDayGround") -> void :
    if self is TowerDefensePlant:
        if nolimit:
            Destroy(true)
    if is_instance_valid(cell):
        if nolimit || cell.CanCraterCreate():
            var craterPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(craterName)
            craterPacket.Plant(gridPos, false, true)
            if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                MultiPlayerManager.SendCraterCreate(gridPos.x, gridPos.y, craterName)

func BlowBack(num: float, time: float = 1.0) -> void :
    blowBackComponent.BlowBack(num, time)

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    hypnosesComponent.Hypnoses(time, canFliter)

func Rise(duration: float = randf_range(0.4, 0.6), delay: float = 0.0, createDirt: bool = true, changeState: bool = true, from: float = 150.0) -> void :
    riseComponent.Rise(duration, delay, createDirt, changeState, from)

func Recycle(percentage: float = 0.2, _destroy: bool = true) -> void :
    recycleComponent.Recycle(percentage, _destroy)

func CreateDirt() -> TowerDefenseEffectParticlesOnce:
    return effectCreateComponent.CreateDirt()

func CreateSplash() -> TowerDefenseEffectSpriteOnce:
    return effectCreateComponent.CreateSplash()

func CreateIceTrap() -> TowerDefenseEffectParticlesOnce:
    return effectCreateComponent.CreateIceTrap()

func WeakUp() -> void :
    instance.wakeUp = true






@warning_ignore("unused_parameter")
func AnimeCompleted(clip: String) -> void :
    pass

@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    pass

@warning_ignore("unused_parameter")
func DamagePointReach(damagePointName: String) -> void :
    if Global.isMultiplayerMode and MultiPlayerManager.isHost and sync_id >= 0:
        MultiPlayerManager.SendDamagePointReach(sync_id, damagePointName)
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        if instance.damagePointData:
            instance.damagePointData.SetDamagePointFliters(sprite, damagePointName)

@warning_ignore("unused_parameter")
func ArmorDamagePointReach(armorName: String, stage: int) -> void :
    if Global.isMultiplayerMode and MultiPlayerManager.isHost and sync_id >= 0:
        MultiPlayerManager.SendArmorDamagePointReach(sync_id, armorName, stage)
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        var armorInstance: TowerDefenseArmorInstance = GetArmorFromName(armorName)
        if armorInstance:
            armorInstance.stageIndex = stage
            match armorInstance.config.replaceMethod:
                "Media":
                    SetArmor(armorName, stage)
                "Sprite":
                    if armorInstance.sprite and stage < armorInstance.config.stageAnimeTexture.size():
                        armorInstance.sprite.texture = armorInstance.config.stageAnimeTexture[stage]

@warning_ignore("unused_parameter")
func ArmorHitpointsEmpty(armorName: String) -> void :
    if Global.isMultiplayerMode and MultiPlayerManager.isHost and sync_id >= 0:
        MultiPlayerManager.SendArmorHitpointsEmpty(sync_id, armorName)
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        var armorInstance: TowerDefenseArmorInstance = GetArmorFromName(armorName)
        if armorInstance and !armorInstance.isRemove:
            if armorInstance.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.DROPABLE and !armorInstance.damagePartDropped:
                DamagePartCreate(StringName(armorName), null, Vector2(randf_range(-100, 100), -300), true, Vector2.ZERO, true)
            armorInstance.Remove()
            armorInstance.isRemove = true

@warning_ignore("unused_parameter")
func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    pass

func UnlimitedFireInit() -> void :
    pass

@warning_ignore("unused_parameter")
func Cover(character: TowerDefenseCharacter) -> void :
    pass

func Spawn() -> void :
    pass

func PreSpawn() -> void :
    pass

func Blow() -> void :
    pass

func Garlic() -> void :
    pass

func CanBlock() -> bool:
    return false

func ShouldUpdateGridPos() -> bool:
    return true

func OnRiseStart() -> void :
    pass

func OnRiseEnd() -> void :
    pass

func BlockType() -> String:
    return "General"

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    pass

@warning_ignore("unused_parameter")
func BlockDigger(target: TowerDefenseCharacter) -> void :
    pass

func Purify() -> void :
    pass





func _on_anime_started(_clipName: String) -> void :
    pass

func SyncAnimation(clipName: String, loopAnim: bool, blendTimeVal: float) -> void :
    _sync_applying_animation = true
    sprite.SetAnimation(clipName, loopAnim, blendTimeVal)
    _sync_applying_animation = false

func HitpointsNearDie() -> void :
    nearDie = true
    targetRegistrationComponent.SyncTargetToServer()

func HitpointsEmpty() -> void :
    die = true
    targetRegistrationComponent.SyncTargetToServer()

func InWater() -> void :
    shadowComponent.SetVisible(false)

func OutWater() -> void :
    shadowComponent.SetVisible( !invisible)





static func GetFireAnime(type: String) -> Variant:
    match type:
        "Fire":
            return FIRE
        "IceFire":
            return ICE_FIRE
        "MegaFire":
            return MEGA_FIRE
        "PurifyFire":
            return PURIFY_FIRE
        "WhiteFire":
            return WHITE_FIRE
    return FIRE

static func CreateFireEventLists(num: float, _eventTarget: Array[TowerDefenseCharacterEventBase], _allEventList: Array[TowerDefenseCharacterEventBase]) -> Dictionary:
    var eventList: Array[TowerDefenseCharacterEventBase] = _eventTarget.duplicate(true)
    var explodeEvent: TowerDefenseCharacterEventExplodeHurt = TowerDefenseCharacterEventExplodeHurt.new()
    explodeEvent.num = num
    explodeEvent.type = "Jala"
    eventList.push_front(explodeEvent)
    var allEventList: Array[TowerDefenseCharacterEventBase] = _allEventList.duplicate(true)
    var addBuffEvent: TowerDefenseCharacterEventAddBuff = TowerDefenseCharacterEventAddBuff.new()
    addBuffEvent.buffList.push_front(TowerDefenseCharacterBuffFireHit.new())
    allEventList.append(addBuffEvent)
    return {"event_list": eventList, "all_event_list": allEventList}

static func CreateFireEffectAtCell(fireAnime: Variant, cellPos: Vector2i) -> void :
    var getCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(cellPos)
    var effect = TowerDefenseManager.CreateEffectSpriteOnce(fireAnime, cellPos, "Flame|Done")
    effect.global_position = TowerDefenseManager.GetMapCellPlantPos(cellPos) + Vector2(0, 30)
    if is_instance_valid(getCell):
        effect.global_position.y -= getCell.GetGroundHeight(0.5)
    characterNode.add_child(effect)

static func PlayFireExplodeEffects() -> void :
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    AudioManager.AudioPlay("ExplodeJalapeno", AudioManagerEnum.TYPE.SFX)

static func CreateSnowEventList(_addEventList: Array[TowerDefenseCharacterEventBase]) -> Array[TowerDefenseCharacterEventBase]:
    var snowEventList: Array[TowerDefenseCharacterEventBase] = _addEventList.duplicate(true)
    var forzenEvent = TowerDefenseCharacterEventForzen.new()
    forzenEvent.time = 3.0
    var hurtEvent = TowerDefenseCharacterEventHurt.new()
    hurtEvent.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS_MAX
    hurtEvent.num = 20.0
    snowEventList.push_front(hurtEvent)
    snowEventList.push_front(forzenEvent)
    return snowEventList

static func CreateJalapenoFire(_camp: TowerDefenseEnum.CHARACTER_CAMP, _gridPos: Vector2i, num: float = -1, _eventTarget: Array[TowerDefenseCharacterEventBase] = [], _allEventList: Array[TowerDefenseCharacterEventBase] = [], type: String = "Fire") -> void :
    var fireAnime = GetFireAnime(type)
    var lists: Dictionary = CreateFireEventLists(num, _eventTarget, _allEventList)
    var eventList: Array[TowerDefenseCharacterEventBase] = lists["event_list"]
    var allEventList: Array[TowerDefenseCharacterEventBase] = lists["all_event_list"]
    BattleEventBus.jalaLineEffectEmit.emit(_gridPos.y)
    TowerDefenseExplode.CreateExplodeLine(_gridPos.y, eventList, [], _camp, -1)
    TowerDefenseExplode.CreateExplodeLine(_gridPos.y, allEventList, [], TowerDefenseEnum.CHARACTER_CAMP.ALL, -1)
    if is_instance_valid(TowerDefenseManager.GetMapIceCapList()[_gridPos.y]):
        TowerDefenseManager.GetMapIceCapList()[_gridPos.y].queue_free()
    PlayFireExplodeEffects()
    for i in TowerDefenseManager.GetMapGridNum().x:
        var flag: bool = true
        if i == 0:
            CreateFireEffectAtCell(fireAnime, _gridPos)
            flag = false
        else:
            if _gridPos.x - i > 0:
                CreateFireEffectAtCell(fireAnime, _gridPos - Vector2i(i, 0))
                flag = false
            if _gridPos.x + i <= TowerDefenseManager.GetMapGridNum().x:
                CreateFireEffectAtCell(fireAnime, _gridPos + Vector2i(i, 0))
                flag = false
        if flag:
            break
        await TowerDefenseManager.currentControl.get_tree().create_timer(0.025, false).timeout

static func CreateJalapenoFireColumn(_camp: TowerDefenseEnum.CHARACTER_CAMP, _gridPos: Vector2i, num: float = -1, _eventTarget: Array[TowerDefenseCharacterEventBase] = [], _allEventList: Array[TowerDefenseCharacterEventBase] = [], type: String = "Fire") -> void :
    var fireAnime = GetFireAnime(type)
    var lists: Dictionary = CreateFireEventLists(num, _eventTarget, _allEventList)
    var eventList: Array[TowerDefenseCharacterEventBase] = lists["event_list"]
    var allEventList: Array[TowerDefenseCharacterEventBase] = lists["all_event_list"]
    BattleEventBus.jalaRowEffectEmit.emit(_gridPos.x)
    TowerDefenseExplode.CreateExplodeColumn(_gridPos.x, eventList, [], _camp, -1)
    TowerDefenseExplode.CreateExplodeColumn(_gridPos.x, allEventList, [], TowerDefenseEnum.CHARACTER_CAMP.ALL, -1)
    PlayFireExplodeEffects()
    for i in TowerDefenseManager.GetMapGridNum().y:
        var flag: bool = true
        if i == 0:
            CreateFireEffectAtCell(fireAnime, _gridPos)
            flag = false
        else:
            if _gridPos.y - i > 0:
                CreateFireEffectAtCell(fireAnime, _gridPos - Vector2i(0, i))
                flag = false
            if _gridPos.y + i <= TowerDefenseManager.GetMapGridNum().y:
                CreateFireEffectAtCell(fireAnime, _gridPos + Vector2i(0, i))
                flag = false
        if flag:
            break
        await TowerDefenseManager.currentControl.get_tree().create_timer(0.025, false).timeout

static func CreateJalapenoFireSlash(_camp: TowerDefenseEnum.CHARACTER_CAMP, _gridPos: Vector2i, num: float = -1, _eventTarget: Array[TowerDefenseCharacterEventBase] = [], _allEventList: Array[TowerDefenseCharacterEventBase] = [], type: String = "Fire") -> void :
    var fireAnime = GetFireAnime(type)
    var lists: Dictionary = CreateFireEventLists(num, _eventTarget, _allEventList)
    var eventList: Array[TowerDefenseCharacterEventBase] = lists["event_list"]
    var allEventList: Array[TowerDefenseCharacterEventBase] = lists["all_event_list"]
    var mapGridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var cells: Array[Vector2i] = []
    var maxGrid = max(mapGridNum.x, mapGridNum.y)
    for i in range(0, maxGrid + 1):
        var _cells: Array[Vector2i] = [
            _gridPos + Vector2i(i, i), 
            _gridPos + Vector2i(i, - i), 
            _gridPos + Vector2i( - i, i), 
            _gridPos + Vector2i( - i, - i)
        ]
        for _cellPos in _cells:
            if _cellPos.x >= 1 and _cellPos.x <= mapGridNum.x and _cellPos.y >= 1 and _cellPos.y <= mapGridNum.y:
                if i == 0:
                    if !cells.has(_cellPos):
                        cells.append(_cellPos)
                        cells.append(_cellPos)
                else:
                    cells.append(_cellPos)
    PlayFireExplodeEffects()
    for cellPos in cells:
        BattleEventBus.jalaGridEffectEmit.emit(cellPos)
        TowerDefenseExplode.CreateExplode(TowerDefenseManager.GetMapCellPlantPos(cellPos), Vector2(0.5, 0.5), eventList, [], _camp, -1)
        TowerDefenseExplode.CreateExplode(TowerDefenseManager.GetMapCellPlantPos(cellPos), Vector2(0.5, 0.5), allEventList, [], TowerDefenseEnum.CHARACTER_CAMP.ALL, -1)
        CreateFireEffectAtCell(fireAnime, cellPos)
        await TowerDefenseManager.currentControl.get_tree().create_timer(0.025, false).timeout

static func CreateColdEffect(_camp: TowerDefenseEnum.CHARACTER_CAMP, _gridPos: Vector2i, _addEventList: Array[TowerDefenseCharacterEventBase] = []) -> void :
    BattleEventBus.coldEffectEmit.emit()
    ViewManager.FullScreenColorBlink(Color(0.117647, 0.564706, 1, 0.5), 0.2)
    AudioManager.AudioPlay("Frozen", AudioManagerEnum.TYPE.SFX)
    var effect = TowerDefenseManager.CreateEffectParticlesOnce(SNOW_FLAKES, _gridPos)
    effect.global_position = TowerDefenseManager.GetMapCellPlantPos(_gridPos)
    characterNode.add_child(effect)
    var snowEventList: Array[TowerDefenseCharacterEventBase] = CreateSnowEventList(_addEventList)
    var targetList = TowerDefenseManager.GetCampTarget(_camp)
    for target: TowerDefenseCharacter in targetList:
        for event: TowerDefenseCharacterEventBase in snowEventList:
            event.Execute(target.global_position, target)

static func CreateColdEffectRange(_camp: TowerDefenseEnum.CHARACTER_CAMP, _gridPos: Vector2i, _range: Vector2, _addEventList: Array[TowerDefenseCharacterEventBase] = []) -> void :
    ViewManager.FullScreenColorBlink(Color(0.117647, 0.564706, 1, 0.5), 0.2)
    AudioManager.AudioPlay("Frozen", AudioManagerEnum.TYPE.SFX)
    var effect = TowerDefenseManager.CreateEffectParticlesOnce(SNOW_FLAKES, _gridPos)
    effect.global_position = TowerDefenseManager.GetMapCellPlantPos(_gridPos)
    characterNode.add_child(effect)
    var snowEventList: Array[TowerDefenseCharacterEventBase] = CreateSnowEventList(_addEventList)
    TowerDefenseExplode.CreateExplode(effect.global_position, _range, snowEventList, [], _camp, -1)

static func CreateCharacter(packetName: String, pos: Vector2, _gridPos: Vector2i, _groundHeight: float) -> TowerDefenseCharacter:
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetName)
    var character: TowerDefenseCharacter = packetConfig.Create(pos, _gridPos, _groundHeight)
    character.groundHeight = _groundHeight
    characterNode.add_child(character)
    return character





func BuffAdd(buffConfig: TowerDefenseCharacterBuffConfig) -> void :
    buff.BuffAdd(buffConfig)

func BuffDelete(key: String) -> void :
    buff.BuffDelete(key)

func BuffGet(key: String) -> TowerDefenseCharacterBuffConfig:
    return buff.BuffGet(key)





func RestoreFromSave(saveConfig: TowerDefenseCharacterSaveConfig) -> void :
    instance.ImportSave(saveConfig.instanceSave)
    nearDie = instance.nearDie
    die = instance.die
    timeScaleInit = saveConfig.timeScaleInit
    timeScale = saveConfig.timeScale
    timeScaleSave = saveConfig.timeScaleSave
    if instance.nearDie:
        showHealthComponent.alive = true
    if saveConfig.buffSave.size() > 0:
        buff.ImportSave(saveConfig.buffSave)
    if instance.damagePointIndex > 0 && instance.damagePointData:
        for i in instance.damagePointIndex:
            if i < instance.damagePoints.size():
                var damagePointName: String = instance.damagePoints[i]["Name"]
                instance.damagePointData.SetDamagePointFliters(sprite, damagePointName)
                if config.customData:
                    for customName: String in currentCustom:
                        config.customData.SetDamagePoint(sprite, customName, i)

func ExportVariantSave() -> Dictionary:
    return {}

func ImportVariantSave(_data: Dictionary) -> void :
    pass
