class_name TowerDefenseInGamePacketShow extends Control

const FZKT = preload("uid://coqskwlqtnypf")
const PC_FONT = preload("uid://dww00k8yk5k72")
const MOBILE_PROGRESS_TEXTURE = preload("uid://cy8jc6hsspvfy")

const PACKET_COLOUR = preload("uid://dricqt0scm3sm")
const PACKET_DIAMOND = preload("uid://eutur83nlbar")
const PACKET_GOLD = preload("uid://dfihegby6yat6")
const PACKET_NORMAL = preload("uid://bwksngvkn16cd")
const PACKET_STAR = preload("uid://bwnw5thitfc8e")
const PACKET_ZOMBIE = preload("uid://btgdkkg66xc8d")
const PACKET_COVER = preload("uid://dbkcwpq2ie7t0")
const PACKET_GRAY = preload("uid://dfy7jg4c8v30x")

const PACKET_COLOUR_MOBILE = preload("uid://cdrj5bkubm7la")
const PACKET_COVER_MOBILE = preload("uid://3k84w2g5d10r")
const PACKET_DIAMOND_MOBILE = preload("uid://1242bw5k8uwq")
const PACKET_GOLD_MOBILE = preload("uid://2smnyulcahs3")
const PACKET_NORMAL_MOBILE = preload("uid://bwfy3kman4ich")
const PACKET_STAR_MOBILE = preload("uid://dxa7vky1ueb2o")
const PACKET_ZOMBIE_MOBILE = preload("uid://csgt5dkel0xeb")

signal pressed(packet: TowerDefenseInGamePacketShow)
signal loveChange(packet: TowerDefenseInGamePacketShow)

@onready var tempViewportContainer: SubViewportContainer = %TempViewportContainer
@onready var tempSubViewport: SubViewport = %TempSubViewport
@onready var tempBackgroundTexture: TextureRect = %TempBackgroundTexture

@onready var backgroundTexture: TextureRect = %BackgroundTexture
@onready var selectTexture: NinePatchRect = %SelectTexture


@onready var layout: Control = %Layout
@onready var body: Control = %Body
@onready var itemCostLabel: Label = %ItemCostLabel


@onready var button: Button = %Button

@onready var coldDownProgressBar: TextureProgressBar = %ColdDownProgressBar
@onready var loveButton: TextureButton = %LoveButton

@onready var moveComponent: MoveComponent = %MoveComponent

var config: TowerDefensePacketConfig = null:
    set(_config):
        config = _config
        if backgroundTexture:
            backgroundTexture.visible = config != null

@export var showLove: bool = false:
    set(_showLove):
        showLove = _showLove
        if is_node_ready():
            loveButton.visible = showLove
            if config != null:
                var packetData: Dictionary = GameSaveManager.GetTowerDefensePacketValue(config.saveKey)
                loveButton.button_pressed = packetData.get_or_add("Love", false)

@export var showCost: bool = true:
    set(_showCost):
        showCost = _showCost
        if !is_node_ready():
            await ready
        itemCostLabel.visible = showCost

@export var onlyDraw: bool = false

@export var alive: bool = true:
    set(_alive):
        alive = _alive
        ColorSet()

@export var lock: bool = false:
    set(_lock):
        lock = _lock
        ColorSet()

@export var plantOnce: bool = false

@export var useCost: bool = true

@export var openShadow: bool = false:
    set(_openShadow):
        openShadow = _openShadow
        ColorSet()

var start: bool = false

var select: bool = false:
    set(_select):
        select = _select
        selectTexture.visible = select

var coldDown: float = 0.0
var coldDownOpen: bool = false
var coldDownTimer: float = 0.0

@export var setMobileLayout: bool = false
@export var setPcLayout: bool = false
@export var canPressPutBack: bool = true

var isMobile: bool = false
var pcProgressTexture: Texture2D = null

var aliveTime: float = -1
var aliveTimer: float = 0.0
var blinkTimer: float = 0.0
var blink: bool = false

var height: float = -1
var savePos: Vector2 = Vector2.ZERO
var originalSaveKey: String = ""



var sprite: AdobeAnimateSprite

static var _thumbnail_cache: Dictionary = {}

func _get_cache_key(save_key: String) -> String:
    return save_key + ("_m" if isMobile else "_p")

var thumbnailMode: bool = false
var _thumbnail_rect: TextureRect = null
var baseItemCost: int = 0
var itemCost: int = 100:
    set(_itemCost):
        itemCost = _itemCost
        if riseCost != -1:
            itemCostLabel.text = str(itemCost) + "+"
        else:
            itemCostLabel.text = str(itemCost)
var riseCost: int = -1
var costMultiple: float = -1

func ColorSet() -> void :
    if alive && !openShadow && !lock && !blink:
        layout.modulate = Color.WHITE
        if is_instance_valid(sprite):
            sprite.meshColor = Color.WHITE
    else:
        layout.modulate = Color.DIM_GRAY
        if !thumbnailMode && is_instance_valid(sprite):
            await ready
            sprite.meshColor = Color.DIM_GRAY

func MobilePreset() -> void :
    backgroundTexture.size = Vector2(96.0, 60.0)
    backgroundTexture.position = - backgroundTexture.size / 2.0
    tempBackgroundTexture.size = backgroundTexture.size
    tempBackgroundTexture.position = Vector2(-24, -24)
    tempViewportContainer.position = Vector2(6, 6)
    tempViewportContainer.size = Vector2(82.0, 46.0) * 4.0
    itemCostLabel.size = Vector2(48.0, 25.0)
    itemCostLabel.position = Vector2(45.0, 32.0)
    itemCostLabel.texture_filter = TextureFilter.TEXTURE_FILTER_PARENT_NODE
    itemCostLabel.add_theme_color_override("font_color", Color.WHITE)
    itemCostLabel.add_theme_constant_override("outline_size", 5)
    itemCostLabel.add_theme_font_override("font", FZKT)
    itemCostLabel.add_theme_font_size_override("font_size", 24)
    selectTexture.size = Vector2(312.0, 198.0)
    selectTexture.position = Vector2(-48.0, -30.0)
    button.size = Vector2(94.0, 60.0)
    button.position = Vector2(-48.0, -30.0)
    coldDownProgressBar.size = Vector2(95.0, 59.0)
    coldDownProgressBar.position = Vector2(-48.0, -30.0)
    coldDownProgressBar.texture_progress = MOBILE_PROGRESS_TEXTURE
    loveButton.position = Vector2(26.0, -34.0)

func SetPcPreset() -> void :
    backgroundTexture.size = Vector2(50.0, 70.0)
    backgroundTexture.position = Vector2(-24.0, -32.0)
    tempBackgroundTexture.size = Vector2(50.0, 70.0)
    tempBackgroundTexture.position = Vector2(-12.0, -24.0)
    tempViewportContainer.position = Vector2(3.0, 6.0)
    tempViewportContainer.size = Vector2(176.0, 188.0)
    itemCostLabel.texture_filter = TextureFilter.TEXTURE_FILTER_LINEAR
    itemCostLabel.add_theme_color_override("font_color", Color(0, 0, 0, 1))
    itemCostLabel.remove_theme_constant_override("outline_size")
    itemCostLabel.add_theme_font_override("font", PC_FONT)
    itemCostLabel.add_theme_font_size_override("font_size", 12)
    itemCostLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    itemCostLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    itemCostLabel.position = Vector2(2.0, 52.0)
    itemCostLabel.size = Vector2(35.0, 17.0)
    selectTexture.size = Vector2(170.0, 237.0)
    selectTexture.position = Vector2(-25.0, -33.0)
    button.position = Vector2(-24.0, -32.0)
    button.size = Vector2(50.0, 70.0)
    coldDownProgressBar.position = Vector2(-24.0, -32.0)
    coldDownProgressBar.size = Vector2(50.0, 70.0)
    if pcProgressTexture != null:
        coldDownProgressBar.texture_progress = pcProgressTexture
    loveButton.position = Vector2(4.0, -35.0)

func SetMobileMode(enabled: bool) -> void :
    if setMobileLayout || setPcLayout:
        return
    if isMobile == enabled:
        return
    var old_cache_key: String = _get_cache_key(config.saveKey) if config != null else ""
    isMobile = enabled
    if isMobile:
        MobilePreset()
    else:
        SetPcPreset()
    _update_background_texture()
    if thumbnailMode:
        if config != null:
            _thumbnail_cache.erase(old_cache_key)
        _update_sprite_layout()
        _refresh_thumbnail()
        return
    _update_sprite_layout()
    _refresh_sub_viewport()

func _refresh_sub_viewport() -> void :
    if !is_inside_tree() || config == null:
        return
    if thumbnailMode:
        _thumbnail_cache.erase(_get_cache_key(config.saveKey))
        _sync_thumbnail_rect_size()
        return
    if is_instance_valid(sprite):
        sprite.visible = true
        sprite.pause = false
        sprite.process_mode = Node.PROCESS_MODE_INHERIT
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    await RenderingServer.frame_post_draw
    if is_instance_valid(sprite):
        sprite.ResetAnimation()
        sprite.pause = true
        sprite.process_mode = Node.PROCESS_MODE_DISABLED
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
    await RenderingServer.frame_post_draw
    if is_instance_valid(sprite):
        sprite.visible = false

func _update_background_texture() -> void :
    if config == null:
        return
    if isMobile:
        match config.GetType():
            TowerDefenseEnum.PACKET_TYPE.WHITE:
                backgroundTexture.texture = PACKET_NORMAL_MOBILE
            TowerDefenseEnum.PACKET_TYPE.GOLD:
                backgroundTexture.texture = PACKET_GOLD_MOBILE
            TowerDefenseEnum.PACKET_TYPE.DIAMOND:
                backgroundTexture.texture = PACKET_DIAMOND_MOBILE
            TowerDefenseEnum.PACKET_TYPE.COLOUR:
                backgroundTexture.texture = PACKET_COLOUR_MOBILE
            TowerDefenseEnum.PACKET_TYPE.STAR:
                backgroundTexture.texture = PACKET_STAR_MOBILE
            TowerDefenseEnum.PACKET_TYPE.ORIGINAL:
                backgroundTexture.texture = PACKET_NORMAL_MOBILE
            TowerDefenseEnum.PACKET_TYPE.ZOMBIE:
                backgroundTexture.texture = PACKET_ZOMBIE_MOBILE
            TowerDefenseEnum.PACKET_TYPE.COVER:
                backgroundTexture.texture = PACKET_COVER_MOBILE
            TowerDefenseEnum.PACKET_TYPE.GRAY:
                backgroundTexture.texture = PACKET_GRAY
    else:
        match config.GetType():
            TowerDefenseEnum.PACKET_TYPE.WHITE:
                backgroundTexture.texture = PACKET_NORMAL
            TowerDefenseEnum.PACKET_TYPE.GOLD:
                backgroundTexture.texture = PACKET_GOLD
            TowerDefenseEnum.PACKET_TYPE.DIAMOND:
                backgroundTexture.texture = PACKET_DIAMOND
            TowerDefenseEnum.PACKET_TYPE.COLOUR:
                backgroundTexture.texture = PACKET_COLOUR
            TowerDefenseEnum.PACKET_TYPE.STAR:
                backgroundTexture.texture = PACKET_STAR
            TowerDefenseEnum.PACKET_TYPE.ORIGINAL:
                backgroundTexture.texture = PACKET_NORMAL
            TowerDefenseEnum.PACKET_TYPE.ZOMBIE:
                backgroundTexture.texture = PACKET_ZOMBIE
            TowerDefenseEnum.PACKET_TYPE.COVER:
                backgroundTexture.texture = PACKET_COVER
            TowerDefenseEnum.PACKET_TYPE.GRAY:
                backgroundTexture.texture = PACKET_GRAY
    tempBackgroundTexture.texture = backgroundTexture.texture

func _update_sprite_layout() -> void :
    if !is_instance_valid(sprite) || config == null:
        return
    var characterConfig: TowerDefenseCharacterConfig = config.characterConfig
    if isMobile:
        if characterConfig is TowerDefenseZombieConfig:
            sprite.position = config.packetAnimeOffset * 1.2 * 4.0
            sprite.scale = config.packetAnimeScale * 1.25 * 4.0
        else:
            sprite.position = config.packetAnimeOffset * 4.0
            sprite.scale = config.packetAnimeScale * 1.25 * 4.0
    else:
        sprite.position = config.packetAnimeOffset * 4.0
        sprite.scale = config.packetAnimeScale * 4.0
    if config.packetFlip:
        sprite.scale.x = - sprite.scale.x

func Clear() -> void :
    if is_instance_valid(config):
        BattleEventBus.characterSkinSwitched.disconnect(_OnCharacterSkinSwitched)
    config = null
    backgroundTexture.texture = PACKET_NORMAL
    if is_instance_valid(sprite):
        sprite.queue_free()
        sprite = null
    baseItemCost = 0
    itemCost = 0
    riseCost = -1
    coldDown = 0
    if _thumbnail_rect != null:
        _thumbnail_rect.visible = false
        _thumbnail_rect.texture = null
    tempViewportContainer.visible = true

func ResetForPool() -> void :
    Clear()
    sprite = null
    showLove = false
    alive = true
    lock = false
    select = false
    onlyDraw = false
    plantOnce = false
    useCost = true
    start = false
    coldDownOpen = false
    coldDownTimer = 0.0
    aliveTime = -1
    aliveTimer = 0.0
    blinkTimer = 0.0
    blink = false
    height = -1
    costMultiple = -1
    originalSaveKey = ""
    thumbnailMode = false

func Init(_config: TowerDefensePacketConfig) -> void :
    config = _config
    if originalSaveKey == "":
        originalSaveKey = config.saveKey
    _update_background_texture()
    baseItemCost = config.GetCost()
    itemCost = baseItemCost

    riseCost = config.GetCostRise()
    costMultiple = config.GetCostMultiple()

    if thumbnailMode:
        _ensure_thumbnail_rect()
        _sync_thumbnail_rect_size()
        if _thumbnail_cache.has(_get_cache_key(config.saveKey)):
            _thumbnail_rect.texture = _thumbnail_cache[_get_cache_key(config.saveKey)]
            _thumbnail_rect.visible = true
            tempViewportContainer.visible = false
            if !BattleEventBus.characterSkinSwitched.is_connected(_OnCharacterSkinSwitched):
                BattleEventBus.characterSkinSwitched.connect(_OnCharacterSkinSwitched)
            coldDown = config.GetPacketCooldown()
            coldDownProgressBar.max_value = coldDown
            coldDownProgressBar.value = coldDownProgressBar.max_value
            return

    _create_sprite()

    if !BattleEventBus.characterSkinSwitched.is_connected(_OnCharacterSkinSwitched):
        BattleEventBus.characterSkinSwitched.connect(_OnCharacterSkinSwitched)

    coldDown = config.GetPacketCooldown()
    coldDownProgressBar.max_value = coldDown
    coldDownProgressBar.value = coldDownProgressBar.max_value

    VisibilityChanged()

func _create_sprite() -> void :
    if config == null:
        return
    var characterConfig: TowerDefenseCharacterConfig = config.characterConfig
    if is_instance_valid(sprite):
        sprite.queue_free()
    sprite = TowerDefenseManager.GetCharacterSprite(characterConfig.name)
    sprite.SetAnimation(config.packetAnimeClip, true)
    sprite.pause = true
    sprite.light_mask = 0
    tempSubViewport.add_child(sprite)
    if config.overrideHypnoses:
        var _current: int = sprite.get_instance_shader_parameter("effectFlags") if sprite.get_instance_shader_parameter("effectFlags") != null else 0
        sprite.set_instance_shader_parameter("effectFlags", _current | 8)
    _update_sprite_layout()
    if characterConfig.armorData:
        if config.initArmor.size() > 0:
            for armorName: String in config.initArmor:
                var slotConfig: ArmorSlotConfig = characterConfig.armorData.GetSlotConfig(armorName)
                var typeData: TowerDefenseArmorTypeData = characterConfig.armorData.GetTypeData(armorName)
                if typeData:
                    match slotConfig.replaceMethod:
                        "Media":
                            characterConfig.armorData.OpenArmorFliters(sprite, armorName)
                            characterConfig.armorData.SetArmorReplace(sprite, armorName, 0)
                        "Sprite":
                            var slotNode: AdobeAnimateSlot = sprite.get_node(slotConfig.slotPath)
                            var _sprite: Sprite2D = Sprite2D.new()
                            _sprite.texture = typeData.stageAnimeTexture[0]
                            _sprite.position = slotConfig.offset
                            _sprite.rotation = slotConfig.rotation
                            _sprite.scale = slotConfig.scale
                            slotNode.add_child(_sprite)
    if characterConfig.customData:
        var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue(config.saveKey)
        if packetValue.get_or_add("Key", {}).get_or_add("Custom", "") != "":
            characterConfig.customData.SetCustomFliters(sprite, packetValue["Key"]["Custom"])
    sprite.UpdataChild()

func _OnCharacterSkinSwitched(packetSaveKey: String, customKey: String) -> void :
    _thumbnail_cache.erase(packetSaveKey + "_p")
    _thumbnail_cache.erase(packetSaveKey + "_m")
    if !is_instance_valid(config):
        return
    if config.saveKey != packetSaveKey:
        return
    var characterConfig: TowerDefenseCharacterConfig = config.characterConfig
    if !is_instance_valid(characterConfig) || !is_instance_valid(characterConfig.customData):
        return
    if thumbnailMode:
        _create_sprite()
        if customKey == "":
            characterConfig.customData.ClearCustomFliters(sprite)
        else:
            if !characterConfig.customData.customDictionary.has(customKey):
                return
            characterConfig.customData.ClearCustomFliters(sprite)
            characterConfig.customData.SetCustomFliters(sprite, customKey)
        if is_instance_valid(sprite):
            sprite.UpdataChild()
        _refresh_thumbnail()
        return
    if !is_instance_valid(sprite):
        return
    if customKey == "":
        characterConfig.customData.ClearCustomFliters(sprite)
    else:
        if !characterConfig.customData.customDictionary.has(customKey):
            return
        characterConfig.customData.ClearCustomFliters(sprite)
        characterConfig.customData.SetCustomFliters(sprite, customKey)
    sprite.UpdataChild()

func VisibilityChanged() -> void :
    if !is_inside_tree():
        return
    await get_tree().physics_frame
    if !is_visible_in_tree():
        return
    if thumbnailMode && _thumbnail_rect != null && _thumbnail_rect.texture != null:
        return
    if is_instance_valid(sprite):
        sprite.visible = true
        sprite.pause = false
        sprite.process_mode = Node.PROCESS_MODE_INHERIT
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    await RenderingServer.frame_post_draw
    if thumbnailMode:
        _ensure_thumbnail_rect()
        _capture_thumbnail()
        _activate_thumbnail()
        return
    Reset()

func _ready() -> void :
    savePos = global_position
    button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
    pcProgressTexture = coldDownProgressBar.texture_progress
    isMobile = setMobileLayout || ( !setPcLayout && GameSaveManager.GetConfigValue("MobilePreset") && SceneManager.currentScene != "LevelEditorStage")
    if isMobile:
        MobilePreset()
    coldDownProgressBar.visible = false
    if !setMobileLayout && !setPcLayout:
        BattleEventBus.uiSwitched.connect(SetMobileMode)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if onlyDraw:
        return
    button.visible = config != null
    if is_instance_valid(moveComponent):
        if height != -1:
            if global_position.y > savePos.y + height && moveComponent.velocity.y >= 0:
                moveComponent.queue_free()

    if aliveTime != -1:
        if aliveTimer < aliveTime:
            aliveTimer += delta
            if aliveTimer > aliveTime - 5:
                if blinkTimer < 0.25:
                    blinkTimer += delta
                else:
                    if !select:
                        blink = !blink
                        if blink:
                            layout.modulate = Color.DIM_GRAY
                            if is_instance_valid(sprite):
                                sprite.meshColor = Color.DIM_GRAY
                        else:
                            layout.modulate = Color.WHITE
                            if is_instance_valid(sprite):
                                sprite.meshColor = Color.WHITE
                    blinkTimer = 0
        else:
            if !select:
                if Global.isMultiplayerMode and has_meta("packet_sync_id"):
                    var sync_id: int = get_meta("packet_sync_id")
                    MultiPlayerManager.SendPacketPick(sync_id, "remove")
                queue_free()
            return

    var isUpgradePacket: bool = has_meta("is_upgrade_packet")
    if start || isUpgradePacket:
        if Engine.get_physics_frames() % 10 == 0 && !isUpgradePacket:
            baseItemCost = config.GetCost()
            var finalCost: int = baseItemCost
            if !TowerDefenseManager.GetMapFeature().config.isHeaven || config.GetType() != TowerDefenseEnum.PACKET_TYPE.GOLD:
                if costMultiple != -1:
                    var num: int = TowerDefenseManager.GetCharacterNum(config.saveKey)
                    finalCost = floor(finalCost * costMultiple ** num)
                if riseCost != -1:
                    var num: int = TowerDefenseManager.GetCharacterNum(config.saveKey)
                    finalCost = finalCost + num * riseCost
            itemCost = finalCost

        var aliveFlag = true
        if !isUpgradePacket:
            if coldDownOpen:
                if !TowerDefenseManager.pausePacket:
                    if !TowerDefenseManager.backPacket:
                        if coldDownTimer > 0:
                            coldDownTimer -= delta
                        else:
                            coldDownOpen = false
                    else:
                        if coldDownTimer < coldDown:
                            coldDownTimer += delta
                coldDownProgressBar.visible = true
                coldDownProgressBar.value = coldDownTimer
                aliveFlag = false
            else:
                coldDownProgressBar.visible = false

        if TowerDefenseManager.GetSun() < itemCost:
            aliveFlag = false

        if aliveFlag && !isUpgradePacket:
            if config.GetPlantCover().size() > 0:
                var coverFlag: bool = false
                for coverCheckName in config.GetPlantCover():
                    if TowerDefenseManager.GetCharacterNum(coverCheckName) > 0:
                        coverFlag = true
                        break
                if config.GetCoverCanDirectPlant():
                    coverFlag = true
                aliveFlag = coverFlag
            elif config.characterConfig is TowerDefensePlantConfig:
                var _plantConfig: TowerDefensePlantConfig = config.characterConfig
                if !_plantConfig.extendCoverDictionary.is_empty():
                    var coverFlag: bool = false
                    var _coverNames: Array = _plantConfig.extendCoverDictionary.values()
                    for _character: TowerDefenseCharacter in TowerDefenseManager.GetCharacter():
                        if !is_instance_valid(_character) || !is_instance_valid(_character.cell):
                            continue
                        if _coverNames.has(_character.config.name):
                            if _character.cell.CanPacketPlant(config):
                                coverFlag = true
                                break
                    aliveFlag = coverFlag
        alive = aliveFlag

func Pressed() -> void :
    if onlyDraw:
        return
    if config == null:
        return
    if lock:
        return
    if !alive:
        return
    AudioManager.AudioPlay("PacketPick", AudioManagerEnum.TYPE.SFX)
    select = !select
    if !canPressPutBack:
        button.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if select:
        config.ExecuteEventPress(self)
    pressed.emit(self)

func MouseEntered() -> void :
    if onlyDraw:
        return
    if config == null:
        return
    if lock:
        return
    if !alive:
        return
    if thumbnailMode:
        _thumbnail_rect.visible = false
        tempViewportContainer.visible = true
        if !is_instance_valid(sprite):
            _create_sprite()
        if is_instance_valid(sprite):
            sprite.visible = true
            sprite.pause = false
            sprite.process_mode = Node.PROCESS_MODE_INHERIT
        tempSubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
        return
    if is_instance_valid(sprite):
        sprite.visible = true
        sprite.pause = false
        sprite.process_mode = Node.PROCESS_MODE_INHERIT
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

func MouseExited() -> void :
    if onlyDraw:
        return
    if config == null:
        return
    if lock:
        return
    if !alive:
        return
    if select:
        return
    if thumbnailMode:
        if is_instance_valid(sprite):
            sprite.ResetAnimation()
            sprite.visible = false
            sprite.pause = true
            sprite.process_mode = Node.PROCESS_MODE_DISABLED
        tempViewportContainer.visible = false
        tempSubViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
        tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
        _thumbnail_rect.visible = true
        return
    Reset()

func Reset() -> void :
    if onlyDraw:
        return
    if config == null:
        return
    select = false
    if thumbnailMode:
        if is_instance_valid(sprite):
            sprite.ResetAnimation()
            sprite.visible = false
            sprite.pause = true
            sprite.process_mode = Node.PROCESS_MODE_DISABLED
        tempViewportContainer.visible = false
        tempSubViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
        tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
        _thumbnail_rect.visible = true
        return
    if is_instance_valid(sprite):
        sprite.ResetAnimation()
        sprite.visible = true
        sprite.pause = true
        sprite.process_mode = Node.PROCESS_MODE_DISABLED
    if !canPressPutBack:
        button.mouse_filter = Control.MOUSE_FILTER_PASS
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
    await RenderingServer.frame_post_draw
    if is_instance_valid(sprite):
        sprite.visible = false

func StartInit() -> void :
    alive = false
    if !plantOnce && !CommandManager.debugPacketColdDown && TowerDefenseManager.currentControl.levelConfig.packetColdDownStart && TowerDefenseManager.currentControl.levelConfig.packetColdDownUse:
        var startingCooldown: float = config.GetStartingCooldown()
        if startingCooldown > 0.0:
            coldDownOpen = true
            coldDownTimer = startingCooldown
    VisibilityChanged()

func Plant(gridPos: Vector2i, useSun: bool = true, executeEvent: bool = true) -> TowerDefenseCharacter:
    if !alive:
        return
    if Global.isMultiplayerMode and has_meta("packet_sync_id"):
        set_meta("packet_planted", true)
    var character = config.Plant(gridPos)
    if !(Global.isEditor && SceneManager.currentScene == "LevelEditorStage"):
        Use(useSun)
    if executeEvent:
        config.ExecuteEventPlant(self)
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return character
    if plantOnce:
        return character
    return character

func PlantOnZombie(zombie: TowerDefenseCharacter, hypnoses: bool = false, useSun: bool = true, executeEvent: bool = true) -> TowerDefenseCharacter:
    if !alive:
        return
    if Global.isMultiplayerMode and has_meta("packet_sync_id"):
        set_meta("packet_planted", true)
    var character = config.PlantOnZombie(zombie, hypnoses)
    if !(Global.isEditor && SceneManager.currentScene == "LevelEditorStage"):
        Use(useSun)
    if executeEvent:
        config.ExecuteEventPlant(self)
    return character

func Use(useSun: bool = true) -> void :
    if useCost && useSun:
        TowerDefenseManager.UseSun(itemCost)
    if plantOnce:
        queue_free()
    if !CommandManager.debugPacketColdDown && TowerDefenseManager.currentControl.levelConfig.packetColdDownUse:
        coldDownProgressBar.visible = true
        coldDown = config.GetPacketCooldown()
        coldDownProgressBar.max_value = coldDown
        coldDownProgressBar.value = coldDownProgressBar.max_value
        coldDownOpen = true
        coldDownTimer = coldDown
    Reset()

func LoveButtonToggled(toggled: bool) -> void :
    var packetData: Dictionary = GameSaveManager.GetTowerDefensePacketValue(config.saveKey)
    packetData["Love"] = toggled
    loveButton.button_pressed = toggled
    GameSaveManager.SetTowerDefensePacketValue(config.saveKey, packetData)
    GameSaveManager.Save()
    loveChange.emit(self)

func Cover(_config: TowerDefensePacketConfig, override: TowerDefensePacketOverride = null, keepColddown: bool = true, changePacket: bool = true) -> void :
    if !is_instance_valid(override):
        override = TowerDefensePacketOverride.new()
    if changePacket:
        var eventChangePacket: TowerDefensePacketEventChangePacket = TowerDefensePacketEventChangePacket.new()
        eventChangePacket.packetConfig = config
        override.eventPlant.append(eventChangePacket)
    if keepColddown:
        var eventChangeColdDown: TowerDefensePacketEventChangeCurrentColdDown = TowerDefensePacketEventChangeCurrentColdDown.new()
        eventChangeColdDown.value = coldDownTimer
        override.eventPlant.append(eventChangeColdDown)
    _config.override = override
    _config.changeCostList = config.changeCostList
    Init(_config)

func _ensure_thumbnail_rect() -> void :
    if _thumbnail_rect != null:
        return
    if !is_inside_tree():
        return
    _thumbnail_rect = TextureRect.new()
    _thumbnail_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _thumbnail_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _thumbnail_rect.light_mask = 0
    _thumbnail_rect.visible = false
    var parent = tempViewportContainer.get_parent()
    parent.add_child(_thumbnail_rect)
    parent.move_child(_thumbnail_rect, tempViewportContainer.get_index() + 1)

func _sync_thumbnail_rect_size() -> void :
    if _thumbnail_rect == null:
        return
    _thumbnail_rect.position = tempViewportContainer.position
    _thumbnail_rect.size = tempViewportContainer.size
    _thumbnail_rect.scale = tempViewportContainer.scale

func _capture_thumbnail() -> void :
    if !is_instance_valid(tempSubViewport) || config == null:
        return
    var image = tempSubViewport.get_texture().get_image()
    var texture = ImageTexture.create_from_image(image)
    _thumbnail_cache[_get_cache_key(config.saveKey)] = texture
    _thumbnail_rect.texture = texture

func _activate_thumbnail() -> void :
    if is_instance_valid(sprite):
        sprite.visible = false
        sprite.pause = true
        sprite.process_mode = Node.PROCESS_MODE_DISABLED
    tempViewportContainer.visible = false
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
    _thumbnail_rect.visible = true

func _refresh_thumbnail() -> void :
    if !is_inside_tree() || config == null:
        return
    _ensure_thumbnail_rect()
    _sync_thumbnail_rect_size()
    if is_instance_valid(sprite):
        sprite.visible = true
        sprite.pause = false
        sprite.process_mode = Node.PROCESS_MODE_INHERIT
    tempViewportContainer.visible = true
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    await RenderingServer.frame_post_draw
    _capture_thumbnail()
    _activate_thumbnail()
