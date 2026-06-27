

class_name DismemberComponent extends ComponentBase


static var dismemberEnabled: bool = false


var parent: TowerDefenseCharacter


var velocityXRange: Vector2 = Vector2(-150.0, 150.0)
var velocityYRange: Vector2 = Vector2(-450.0, -200.0)


var heightOffset: float = 0.0


var _dismembered: bool = false

func GetName() -> String:
    return "DismemberComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready
    parent.characterNearDie.connect(_OnCharacterNearDie)
    parent.destroy.connect(_OnCharacterDestroy)

func _exit_tree() -> void :
    if is_instance_valid(parent):
        if parent.characterNearDie.is_connected(_OnCharacterNearDie):
            parent.characterNearDie.disconnect(_OnCharacterNearDie)
        if parent.destroy.is_connected(_OnCharacterDestroy):
            parent.destroy.disconnect(_OnCharacterDestroy)


func _OnCharacterNearDie(_character: TowerDefenseCharacter) -> void :
    if !dismemberEnabled || !alive || _dismembered:
        return
    if !(parent is TowerDefenseZombie):
        return
    if !is_instance_valid(parent.sprite) || !parent.sprite.flashAnimeData:
        return
    _dismembered = true
    Dismember()


func _OnCharacterDestroy(_character: TowerDefenseCharacter) -> void :
    if !dismemberEnabled || !alive:
        return
    if !(parent is TowerDefenseZombie):
        return

    parent.isExplode = false
    parent.isSmash = false
    if _dismembered:
        return
    if !is_instance_valid(parent.sprite) || !parent.sprite.flashAnimeData:
        return
    _dismembered = true
    Dismember()


func Dismember() -> void :
    var animeSprite: AdobeAnimateSprite = parent.sprite
    var animeData: AdobeAnimateData = animeSprite.flashAnimeData
    var layerDict: Dictionary = animeData.layerDictionary
    var timelineData = animeData.timelineData
    var frameIdx: int = animeSprite.frameIndex

    if frameIdx < 0 || frameIdx >= timelineData.size():
        return

    var frameData = timelineData[frameIdx]
    var charcaterNode: Node2D = TowerDefenseManager.GetCharacterNode()


    for layerName in layerDict.keys():
        var layerId: int = layerDict[layerName]
        if !animeSprite.layerVisible[layerId]:
            continue

        var mediaId: int = frameData[0][layerId]
        if mediaId == AdobeAnimateSlot.EMPTY_MEDIA_ID:
            continue


        var mediaRect: Rect2 = animeData.mediaList[mediaId]
        var mediaSize: Vector2 = mediaRect.size


        var part: AdobeAnimatePart = AdobeAnimatePart.new()
        part.flashAnimeData = animeData
        part.mediaReplace = animeSprite.mediaReplace.duplicate()
        part.offset = Vector2.ZERO



        var layerTransform: Transform2D = frameData[1][layerId]
        var centeredTransform: Transform2D = layerTransform.translated( - layerTransform.origin).translated_local( - mediaSize / 2.0)

        var element: Array = []
        element.append(mediaId)
        element.append(centeredTransform)
        element.append(Color.WHITE)
        part.elementList = [element]


        var damagePartInstance: DamagePartDrop = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.DAMAGEPART, charcaterNode) as DamagePartDrop
        if !damagePartInstance:
            part.queue_free()
            continue

        var velocity: Vector2 = Vector2(randf_range(velocityXRange.x, velocityXRange.y), randf_range(velocityYRange.x, velocityYRange.y))

        var contentCenterLocal: Vector2 = layerTransform * (mediaSize / 2.0) + animeSprite.offset
        var layerGlobalPos: Vector2 = animeSprite.to_global(contentCenterLocal)

        damagePartInstance.Init(part, parent.GetGroundHeight(layerGlobalPos.y) - parent.groundHeight + parent.shadowSprite.position.y + heightOffset, velocity)
        damagePartInstance.scale *= parent.scale * parent.transformPoint.scale * animeSprite.scale
        damagePartInstance.global_position = layerGlobalPos
        damagePartInstance.gridPos = parent.gridPos


    animeSprite.visible = false
    animeSprite.pause = true
    if is_instance_valid(parent.shadowSprite):
        parent.shadowSprite.visible = false

    var tween = parent.create_tween()
    tween.set_parallel(true)
    tween.tween_property(parent, "modulate:a", 0.0, 0.5)
    tween.tween_property(animeSprite, "meshColor:a", 0.0, 0.5)
    tween.chain().tween_callback(parent.Destroy)


func SetAlive(_alive: bool) -> void :
    super.SetAlive(_alive)




static func InjectToCharacter(character: TowerDefenseCharacter) -> void :
    if !is_instance_valid(character) || !is_instance_valid(character.componentManager):
        return
    if !(character is TowerDefenseZombie):
        return
    if character.componentManager.GetComponentFromType("DismemberComponent") != null:
        return
    var comp: = DismemberComponent.new()
    comp.name = "DismemberComponent"
    character.componentManager.add_child(comp)
    character.componentManager.componentList.append(comp)
    if !character.componentManager.componentDictionary.has("DismemberComponent"):
        character.componentManager.componentDictionary["DismemberComponent"] = []
    character.componentManager.componentDictionary["DismemberComponent"].append(comp)
    character.dismemberComponent = comp


static func RemoveFromCharacter(character: TowerDefenseCharacter) -> void :
    if !is_instance_valid(character) || !is_instance_valid(character.componentManager):
        return
    var comp: ComponentBase = character.componentManager.GetComponentFromType("DismemberComponent")
    if comp == null:
        return
    character.componentManager.componentList.erase(comp)
    if character.componentManager.componentDictionary.has("DismemberComponent"):
        character.componentManager.componentDictionary["DismemberComponent"].erase(comp)
    character.dismemberComponent = null
    comp.queue_free()


static func InjectAll() -> void :
    var tree: SceneTree = Engine.get_main_loop() as SceneTree
    for character in tree.get_nodes_in_group("Zombie"):
        if is_instance_valid(character) && character is TowerDefenseZombie:
            InjectToCharacter(character)


static func RemoveAll() -> void :
    var tree: SceneTree = Engine.get_main_loop() as SceneTree
    for character in tree.get_nodes_in_group("Zombie"):
        if is_instance_valid(character) && character is TowerDefenseZombie:
            RemoveFromCharacter(character)
