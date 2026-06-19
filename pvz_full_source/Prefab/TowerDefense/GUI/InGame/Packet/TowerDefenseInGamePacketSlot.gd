extends Control
@onready var textureRect: TextureRect = $TextureRect
const PACKET_SILHOUETTE_PC = preload("uid://d131d07o455pm")
const PACKET_SILHOUETTE_MOBILE = preload("uid://celgn60f027kl")

var isMobileSlot: bool = false

func SetMobileMode(enabled: bool) -> void :
    isMobileSlot = enabled
    if is_node_ready():
        _apply_style()

func _apply_style() -> void :
    if isMobileSlot:
        textureRect.texture = PACKET_SILHOUETTE_MOBILE
        textureRect.size = Vector2(96, 60)
        textureRect.position = Vector2(-48, -30)
        textureRect.modulate.a = 0.5
    else:
        textureRect.texture = PACKET_SILHOUETTE_PC
        textureRect.size = Vector2(50, 70)
        textureRect.position = Vector2(-25, -33)
        textureRect.modulate.a = 1.0

func _ready() -> void :
    _apply_style()
