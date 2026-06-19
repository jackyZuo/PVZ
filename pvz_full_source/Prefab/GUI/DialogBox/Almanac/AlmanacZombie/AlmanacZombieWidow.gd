extends Control

signal pressed(_config: TowerDefensePacketConfig)

@onready var spriteNode: Control = %SpriteNode
@onready var tempSubViewport: SubViewport = %TempSubViewport

var config: TowerDefensePacketConfig = null

var sprite: AdobeAnimateSprite

static var _zombie_thumbnail_cache: Dictionary = {}
var _thumbnail_rect: TextureRect = null
var _viewport_container: SubViewportContainer = null

func Init(_config: TowerDefensePacketConfig):
    config = _config

    if _zombie_thumbnail_cache.has(config.saveKey):
        _ensure_thumbnail_rect()
        var vc = _get_viewport_container()
        if vc != null:
            vc.visible = false
        if _thumbnail_rect != null:
            _thumbnail_rect.texture = _zombie_thumbnail_cache[config.saveKey]
            _thumbnail_rect.visible = true
        return

    _create_sprite()
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
    sprite.UpdataChild()
    sprite.position = (config.packetAnimeOffset + Vector2(5, 0)) * 4.0
    sprite.scale = config.packetAnimeScale * 4.0
    if characterConfig.armorData:
        if config.initArmor.size() > 0:
            for armorName: String in config.initArmor:
                var armor: CharacterArmorConfig = characterConfig.armorData.armorDictionary[armorName]
                match armor.replaceMethod:
                    "Media":
                        characterConfig.armorData.OpenArmorFliters(sprite, armorName)
                        characterConfig.armorData.SetArmorReplace(sprite, armorName, 0)
                    "Sprite":
                        var slotNode: AdobeAnimateSlot = sprite.get_node(armor.replaceSpriteSlotPath)
                        var _sprite: Sprite2D = Sprite2D.new()
                        _sprite.texture = armor.stageAnimeTexture[0]
                        _sprite.position = armor.replaceSpriteOffset
                        _sprite.rotation = armor.replaceSpriteRotation
                        _sprite.scale = armor.replaceSpriteScale
                        slotNode.add_child(_sprite)

func VisibilityChanged() -> void :
    if !is_inside_tree():
        return
    await get_tree().physics_frame
    if !is_visible_in_tree():
        return
    if _thumbnail_rect != null && _thumbnail_rect.texture != null:
        return
    if is_instance_valid(sprite):
        sprite.visible = true
        sprite.pause = false
        sprite.process_mode = Node.PROCESS_MODE_INHERIT
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    await RenderingServer.frame_post_draw
    _ensure_thumbnail_rect()
    var image = tempSubViewport.get_texture().get_image()
    var texture = ImageTexture.create_from_image(image)
    _zombie_thumbnail_cache[config.saveKey] = texture
    _thumbnail_rect.texture = texture
    if is_instance_valid(sprite):
        sprite.visible = false
        sprite.pause = true
        sprite.process_mode = Node.PROCESS_MODE_DISABLED
    var vc = _get_viewport_container()
    if vc != null:
        vc.visible = false
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
    _thumbnail_rect.visible = true

func _get_viewport_container() -> SubViewportContainer:
    if _viewport_container != null:
        return _viewport_container
    var node = tempSubViewport.get_parent()
    if node is SubViewportContainer:
        _viewport_container = node
    return _viewport_container

func _ensure_thumbnail_rect() -> void :
    if _thumbnail_rect != null:
        return
    if !is_inside_tree():
        return
    var vc = _get_viewport_container()
    if vc == null:
        return
    _thumbnail_rect = TextureRect.new()
    _thumbnail_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _thumbnail_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _thumbnail_rect.visible = false
    var parent = vc.get_parent()
    parent.add_child(_thumbnail_rect)
    parent.move_child(_thumbnail_rect, vc.get_index() + 1)
    _thumbnail_rect.position = vc.position
    _thumbnail_rect.size = vc.size
    _thumbnail_rect.scale = vc.scale

func Pressed() -> void :
    if config == null:
        return
    AudioManager.AudioPlay("PacketPick", AudioManagerEnum.TYPE.SFX)
    pressed.emit(config)

func MouseEntered() -> void :
    if _thumbnail_rect != null:
        _thumbnail_rect.visible = false
    var vc = _get_viewport_container()
    if vc != null:
        vc.visible = true
    if !is_instance_valid(sprite):
        _create_sprite()
    if is_instance_valid(sprite):
        sprite.visible = true
        sprite.pause = false
        sprite.process_mode = Node.PROCESS_MODE_INHERIT
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

func MouseExited() -> void :
    Reset()

func Reset() -> void :
    if is_instance_valid(sprite):
        sprite.ResetAnimation()
        sprite.visible = false
        sprite.pause = true
        sprite.process_mode = Node.PROCESS_MODE_DISABLED
    var vc = _get_viewport_container()
    if vc != null:
        vc.visible = false
    tempSubViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
    tempSubViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
    if _thumbnail_rect != null:
        _thumbnail_rect.visible = true
