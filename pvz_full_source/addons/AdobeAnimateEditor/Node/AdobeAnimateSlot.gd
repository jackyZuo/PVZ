@tool
class_name AdobeAnimateSlot extends Node2D

const EMPTY_MEDIA_ID: = 65535

var sprite: AdobeAnimateSprite
@export_enum("Follow", "Drive") var mode: int = 0
@export_storage var followSlotId: int = 0

@export var offset: Vector2 = Vector2.ZERO
@export var useRotate: bool = true
@export var useScale: bool = true
@export var useSkew: bool = true
@export var useFollowVisible: bool = false
@export var updateAllFrame: bool = false

func _ready() -> void :
    var parent = get_parent()
    if parent is AdobeAnimateSprite:
        sprite = parent

func Update() -> void :
    match mode:
        0:
            var data = sprite.flashAnimeData.timelineData[sprite.frameIndex]
            var mediaId: int = data[0][followSlotId - 1]
            if mediaId != EMPTY_MEDIA_ID:
                var mediaTransform: Transform2D = data[1][followSlotId - 1].translated(sprite.offset)
                if mediaTransform != Transform2D.IDENTITY:
                    var offsetTransform: Transform2D = mediaTransform.translated_local(offset)
                    if !useRotate:
                        offsetTransform = offsetTransform.rotated_local( - offsetTransform.get_rotation())
                    if !useScale:
                        offsetTransform = offsetTransform.scaled_local(Vector2.ONE / offsetTransform.get_scale())
                    transform = offsetTransform
                    if !useSkew:
                        skew = 0.0

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    if !sprite || sprite.flashAnimeData == null:
        return properties

    if sprite.flashAnimeData.layerDictionary.size() > 0:
        properties.append({
            "name": "Layer", 
            "type": TYPE_INT, 
            "hint": PROPERTY_HINT_ENUM, 
            "hint_string": "Noone," + ",".join(sprite.flashAnimeData.layerList), 
        })

    return properties

func _set(property: StringName, value: Variant) -> bool:
    if property == "Layer":
        followSlotId = value
        return true
    return false

func _get(property: StringName) -> Variant:
    if sprite && sprite.flashAnimeData:
        if property == "Layer":
            return followSlotId
    return null

func _property_can_revert(property: StringName) -> bool:
    if property == "Layer":
        return true
    return false

func _property_get_revert(property: StringName) -> Variant:
    if property == "Layer":
        return 0
    return null

func CreatePart(layerList: Array[StringName]) -> AdobeAnimatePart:
    Update()
    var layerCheckList: Array[int] = []
    for layerName in layerList:
        if sprite.flashAnimeData.layerDictionary.has(layerName):
            layerCheckList.append(sprite.flashAnimeData.layerDictionary[layerName])


    if !sprite:
        return
    var instance: AdobeAnimatePart = AdobeAnimatePart.new()
    instance.flashAnimeData = sprite.flashAnimeData
    instance.mediaReplace = sprite.mediaReplace.duplicate()
    instance.offset = offset
    var timelineData = sprite.flashAnimeData.timelineData
    var elementOutputList: Array[Array] = []
    var saveOffset: Vector2 = timelineData[sprite.frameIndex][1][followSlotId - 1].origin

    for layerId in layerCheckList:
        if !sprite.layerVisible[layerId]:
            continue
        var data = timelineData[sprite.frameIndex]
        var element: Array = []
        element.append(data[0][layerId])
        element.append(data[1][layerId].translated( - saveOffset))
        element.append(Color.WHITE)
        elementOutputList.append(element)
    instance.elementList = elementOutputList
    return instance
