@tool
class_name TowerDefenseEffectSpriteOnce extends TowerDefenseEffectBase

const TOWER_DEFENSE_EFFECT_SPRITE_ONCE = preload("uid://dwvgduivkprow")

@export var objectId: ObjectManagerConfig.OBJECT = ObjectManagerConfig.OBJECT.NOONE
@export var sprite: AdobeAnimateSprite
@export var clipsList: PackedStringArray
var currentIndex: int = 0

static func Create() -> TowerDefenseEffectSpriteOnce:
    return TOWER_DEFENSE_EFFECT_SPRITE_ONCE.instantiate()

func Refresh() -> void :
    add_to_group("Effect")
    currentIndex = 0
    sprite.SetAnimation(clipsList[currentIndex], false, 0.0)

func Recycle() -> void :
    remove_from_group("Effect")

func _ready() -> void :
    if sprite:
        if !sprite.animeCompleted.is_connected(AnimeCompleted):
            sprite.animeCompleted.connect(AnimeCompleted)

func InitScene(_sprite: AdobeAnimateSprite, _clip: String = "") -> void :
    sprite = _sprite
    if _clip != "":
        currentIndex = 0
        clipsList = _clip.split("|", false)
        sprite.SetAnimation(clipsList[currentIndex], false, 0.0)
    add_child(sprite)
    sprite.animeCompleted.connect(AnimeCompleted)

func Init(spriteScene: PackedScene, _clip: String = "") -> void :
    sprite = spriteScene.instantiate()
    InitScene(sprite, _clip)

@warning_ignore("unused_parameter")
func AnimeCompleted(clip: String) -> void :
    if clipsList.size() > 0:
        if currentIndex < clipsList.size() - 1:
            currentIndex += 1
            sprite.SetAnimation(clipsList[currentIndex], false, 0.1)
            return

    if objectId == ObjectManagerConfig.OBJECT.NOONE:
        queue_free()
    else:
        ObjectManager.PoolPush(objectId, self)
