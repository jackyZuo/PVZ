class_name RemoteCursor extends Node2D

const PLAYER_COLORS: Array[Color] = [
    Color(0.3, 0.7, 1.0), 
    Color(1.0, 0.5, 0.3), 
    Color(0.5, 1.0, 0.5), 
    Color(1.0, 1.0, 0.3), 
]

@onready var _cursorSprite: Sprite2D = %CursorSprite
@onready var _label: RichTextLabel = %Label
var _pickNode: Node
var _currentPickType: String = ""
var _currentPickName: String = ""
var _targetPosition: Vector2 = Vector2(-100, -100)
var _currentPosition: Vector2 = Vector2(-100, -100)

func _ready() -> void :
    _label.add_theme_font_size_override("normal_font_size", 14)
    _label.add_theme_color_override("font_outline_color", Color.BLACK)
    _label.add_theme_constant_override("outline_size", 3)

func SetPlayerInfo(player_index: int, player_name: String = "") -> void :
    var color: Color = PLAYER_COLORS[player_index % PLAYER_COLORS.size()]
    _cursorSprite.modulate = color
    var display_name: String = player_name if player_name != "" else "P%d" % (player_index + 1)
    var color_hex: String = color.to_html(false)
    _label.text = "[color=#%s]%s[/color]" % [color_hex, display_name]
    _label.visible = true

func UpdatePosition(posX: float, posY: float) -> void :
    _targetPosition = Vector2(posX, posY)
    _cursorSprite.visible = true

func UpdatePick(pickType: String, pickName: String) -> void :
    if pickType == _currentPickType and pickName == _currentPickName:
        return
    _currentPickType = pickType
    _currentPickName = pickName
    _UpdatePickSprite()

func _UpdatePickSprite() -> void :
    if is_instance_valid(_pickNode):
        _pickNode.queue_free()
        _pickNode = null
    if _currentPickType == "" or _currentPickName == "":
        return
    match _currentPickType:
        "plant":
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfigReadOnly(_currentPickName)
            if !is_instance_valid(packetConfig):
                return
            var packetScene: PackedScene = load("uid://bhqecss20rwpb")
            var packetShow: TowerDefenseInGamePacketShow = packetScene.instantiate()
            packetShow.modulate.a = 0.7
            packetShow.z_index = 1900
            packetShow.z_as_relative = false
            packetShow.mouse_filter = Control.MOUSE_FILTER_IGNORE
            _pickNode = packetShow
            add_child(_pickNode)
            packetShow.Init(packetConfig)
            packetShow.button.mouse_filter = Control.MOUSE_FILTER_IGNORE
        "shovel":
            var shovelConfig: ShovelConfig = TowerDefenseManager.GetShovel(_currentPickName)
            if is_instance_valid(shovelConfig) and is_instance_valid(shovelConfig.texture):
                var sprite: Sprite2D = Sprite2D.new()
                sprite.texture = shovelConfig.texture
                sprite.modulate.a = 0.5
                sprite.z_index = 1900
                sprite.z_as_relative = false
                sprite.scale = Vector2.ONE * 80.0 / shovelConfig.texture.get_width()
                _pickNode = sprite
                add_child(_pickNode)
        "glove":
            var gloveTex: Texture2D = load("res://Asset/Texture/GUI/General/Glove/Glove.png")
            if is_instance_valid(gloveTex):
                var sprite: Sprite2D = Sprite2D.new()
                sprite.texture = gloveTex
                sprite.modulate.a = 0.5
                sprite.z_index = 1900
                sprite.z_as_relative = false
                sprite.scale = Vector2.ONE * 80.0 / gloveTex.get_width()
                _pickNode = sprite
                add_child(_pickNode)

func _process(_delta: float) -> void :
    if _cursorSprite.visible:
        _currentPosition = _currentPosition.lerp(_targetPosition, minf(1.0, _delta * 20.0))
        _cursorSprite.position = _currentPosition
        _label.position = _currentPosition + Vector2(16.0, -8.0)
        if is_instance_valid(_pickNode):
            _pickNode.set("position", _currentPosition - Vector2(0.0, 30.0))

func Hide() -> void :
    _cursorSprite.visible = false
    _label.visible = false
    if is_instance_valid(_pickNode):
        _pickNode.visible = false
