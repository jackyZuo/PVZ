@tool
class_name AdobeAnimateSprite extends Node2D


const SHADER_TOWER_DEFENSE_CHARACTER = preload("uid://bbit4jhs4p0ww")
const EMPTY_MEDIA_ID: = 65535

signal animeCompleted(clip: String)
signal animeStoped(clip: String)
signal animeStarted(clip: String)
signal animeEvent(command: String, argument: Variant)
signal animeBlendCompleted(clip: String)

@export var flashAnimeData: AdobeAnimateData:
    set(_flashAnimeData):
        if flashAnimeData != _flashAnimeData:
            flashAnimeData = _flashAnimeData
            FileChange()
            if !flashAnimeData.changed.is_connected(FileChange):
                flashAnimeData.changed.connect(FileChange)
            queue_redraw()
            CanRun()
@export var preview: bool = true:
    set(_preview):
        preview = _preview
        CanRun()
@export_group("Preset")
@export var invisible: bool = false:
    set(_invisible):
        invisible = _invisible
        CanRun()
@export var normalAlpha: bool = false
@export var offset: Vector2 = Vector2.ZERO
@export var offsetRotate: float = 0.0
@export var timeScale: float = 1.0
@export var trueFrameRate: float = 30.0
@export var skipLastFrame: bool = true
@export var usePos: bool = true
@export var useRotate: bool = true
@export var useFollowVisible: bool = false
@export_group("Animation")
@export var blendTimeInit: float = 0.0
@export_group("", "")

@export var pause: bool = false:
    set(_pause):
        var prev_pause: bool = pause
        pause = _pause
        if prev_pause && !pause:
            _is_visible_in_tree = is_visible_in_tree()
        CanRun()
        if !pause && canRun && !_process_enabled:
            _SetProcessEnabled(true)
        queue_redraw()
@export var playBack: bool = false
var onlyDraw: bool = false
var elapsedTimer: float = 0.0
var refreshTimer: float = 0.0
var blend: bool = false
var blendTime: float = 0.0
var blendTimer: float = 0.0
var frameIndex: int = 0
var frameRate: float
var refreshEveryFlame: bool = false

var loop: bool = true

var clip: String = "":
    set = SetClip
var clipRange: Vector2i = Vector2i.ZERO
var clipOver: bool = false
var layerVisible: Array[bool] = []
var mediaReplaceAtlas: Texture2D
var mediaReplaceRect: Array[Rect2] = []
var mediaReplace: Array[Texture2D] = []
var mediaReplaceUse: Array[bool] = []
var track: Array[AdobeAnimateTrack] = []

var canvasItem: RID

var canRun: bool = true

var initClip: bool = false

@export var parentSprite: AdobeAnimateSprite:
    set(_parentSprite):
        parentSprite = _parentSprite
var followParentSpriteLayerId: int = 0

var meshTexture: RID
var _current_mesh_rid: RID
var _last_draw_frame: int = -1
@export var meshColor: Color = Color.WHITE:
    set(_meshColor):
        meshColor = _meshColor
        if !is_node_ready():
            await ready
        SetMultimeshModulate(self)
        if !onlyDraw && is_instance_valid(material):
            material.set_shader_parameter("modulate", meshColor)
var meshBlend: ArrayMesh
var mesh: ArrayMesh

var needMediaPeplaceUpdate: bool = false

var _slot_children: Array[AdobeAnimateSlot] = []
var _sprite_children: Array[AdobeAnimateSprite] = []
var _has_children: bool = false
var _last_update_frame: int = -1
var _is_visible_in_tree: bool = true
var _process_enabled: bool = true

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    if flashAnimeData == null:
        return properties

    if flashAnimeData.clips.size() > 0:
        properties.append(
            {
                "name": "Animation/Clip", 
                "type": TYPE_STRING, 
                "hint": PROPERTY_HINT_ENUM, 
                "hint_string": "Null," + ",".join(flashAnimeData.clips.keys()), 
            }
        )
    for layerName in flashAnimeData.layerDictionary.keys():
        properties.append({
            "name": "Animation/LayerVisible/" + layerName, 
            "type": TYPE_BOOL
        })
    for mediaName in flashAnimeData.mediaDictionary.keys():
        properties.append({
            "name": "Animation/MediaReplace/" + mediaName, 
            "type": TYPE_OBJECT, 
            "hint": PROPERTY_HINT_RESOURCE_TYPE, 
            "hint_string": "Texture2D"
        })
    if is_instance_valid(parentSprite):
        if parentSprite.flashAnimeData.layerDictionary.size() > 0:
            properties.append({
                "name": "Layer", 
                "type": TYPE_INT, 
                "hint": PROPERTY_HINT_ENUM, 
                "hint_string": ",".join(parentSprite.flashAnimeData.layerList), 
            })
    return properties

func _set(property: StringName, value: Variant) -> bool:
    if property == "Animation/Clip" && flashAnimeData.clips.size() > 0:
        clip = value
        return true
    if property.begins_with("Animation/LayerVisible"):
        if flashAnimeData.layerDictionary.has(property.trim_prefix("Animation/LayerVisible/")):
            var id = flashAnimeData.layerDictionary[property.trim_prefix("Animation/LayerVisible/")]
            if id < layerVisible.size():
                layerVisible[id] = value
            queue_redraw()
            if !onlyDraw:
                if is_instance_valid(material):
                    material.set_shader_parameter("layerVisible", layerVisible)

            return true
    if property.begins_with("Animation/MediaReplace"):
        if flashAnimeData.mediaDictionary.has(property.trim_prefix("Animation/MediaReplace/")):
            var id = flashAnimeData.mediaDictionary[property.trim_prefix("Animation/MediaReplace/")]
            if id < layerVisible.size():
                mediaReplace[id] = value
                mediaReplaceUse[id] = is_instance_valid(value)
            queue_redraw()
            if !onlyDraw:
                if is_instance_valid(material):
                    QueueUpdateMediaPeplace()

            return true
    if property == "Layer":
        followParentSpriteLayerId = value
        return true
    return false

func _get(property: StringName) -> Variant:
    if !flashAnimeData:
        return null
    if property.begins_with("Animation/Clip"):
        return clip
    if property.begins_with("Animation/LayerVisible"):
        return layerVisible[flashAnimeData.layerDictionary[property.trim_prefix("Animation/LayerVisible/")]]
    if property.begins_with("Animation/MediaReplace"):
        return mediaReplace[flashAnimeData.mediaDictionary[property.trim_prefix("Animation/MediaReplace/")]]
    if parentSprite && parentSprite.flashAnimeData:
        if property == "Layer":
            return followParentSpriteLayerId
    return null

func _property_can_revert(property: StringName) -> bool:
    if property == "Animation/Clip":
        if flashAnimeData.clips.size() > 0:
            return clip != flashAnimeData.clips.keys()[0]
    if property.begins_with("Animation/LayerVisible"):
        return true
    if property.begins_with("Animation/MediaReplace"):
        return true

    if property == "Layer":
        return true
    return false

func _property_get_revert(property: StringName) -> Variant:
    if property == "Animation/Clip":
        if flashAnimeData.clips.size() > 0:
            return flashAnimeData.clips.keys()[0]
    if property.begins_with("Animation/LayerVisible"):
        return true
    if property.begins_with("Animation/MediaReplace"):
        return null

    if property == "Layer":
        return 0
    return null

func CanRun() -> bool:
    var prev_canRun: bool = canRun
    canRun = false
    if !invisible && !_is_visible_in_tree:
        _TryDisableProcess(prev_canRun)
        return false
    if !flashAnimeData || !flashAnimeData.animeFile:
        _TryDisableProcess(prev_canRun)
        return false
    if Engine.is_editor_hint():
        if !preview:
            _TryDisableProcess(prev_canRun)
            return false
    if pause:
        _TryDisableProcess(prev_canRun)
        return false
    canRun = true
    if prev_canRun != canRun && is_node_ready() && !clipOver:
        _SetProcessEnabled(true)
    return true

func _TryDisableProcess(prev_canRun: bool) -> void :
    if prev_canRun && is_node_ready():
        _SetProcessEnabled(false)

func _UpdateVisibilityCache() -> void :
    var new_visible: bool = is_visible_in_tree()
    if _is_visible_in_tree != new_visible:
        _is_visible_in_tree = new_visible
        CanRun()

func _SetProcessEnabled(enabled: bool) -> void :
    if _process_enabled == enabled:
        return
    _process_enabled = enabled
    if onlyDraw:
        set_physics_process(enabled)
    else:
        set_process(enabled)

func _ready() -> void :
    visibility_changed.connect(_UpdateVisibilityCache)
    _is_visible_in_tree = is_visible_in_tree()
    canvasItem = get_canvas_item()
    CanRun()
    var parent = get_parent()
    if parent is AdobeAnimateSprite:
        parentSprite = parent


    if parent is CanvasItem:
        RenderingServer.canvas_item_set_parent(canvasItem, parent.get_canvas_item())
        RenderingServer.canvas_item_set_z_as_relative_to_parent(canvasItem, true)
    frameIndex = clipRange.x
    elapsedTimer = randf_range(0.1, 1.0)
    clipOver = false

    if clip != "":
        queue_redraw()
        var clipRangeGet = flashAnimeData.GetClip(clip)
        clipRange = clipRangeGet
        frameIndex = clipRange.x
    onlyDraw = flashAnimeData.onlyDraw

    meshTexture = flashAnimeData.imageAtlas.get_rid()
    meshBlend = ArrayMesh.new()
    mesh = flashAnimeData.initMesh.duplicate(true)
    _init_material()
    _cache_children()


func CreateMediaPeplaceAtlas() -> void :
    var mediaSizeList: Array[Vector2] = []
    var mediaList: Array[Image] = []
    var mediaIdList: Array[int] = []
    for mediaReplaceId in mediaReplace.size():
        if mediaReplaceUse[mediaReplaceId]:
            mediaSizeList.append(mediaReplace[mediaReplaceId].get_size())
            mediaList.append(mediaReplace[mediaReplaceId].get_image())
            mediaIdList.append(mediaReplaceId)

    mediaReplaceRect.clear()
    mediaReplaceRect.resize(flashAnimeData.mediaDictionary.size())
    mediaReplaceRect.fill(Rect2())

    if mediaSizeList.size() > 0:
        var atlas = Geometry2D.make_atlas(mediaSizeList)
        var points = atlas["points"]
        var atlasSize = Vector2(atlas["size"])

        var imageAtlasData = Image.create(atlasSize.x, atlasSize.y, false, Image.FORMAT_RGBA8)

        for id in range(mediaIdList.size()):
            var pos = points[id]
            var size = mediaSizeList[id]
            var mediaId = mediaIdList[id]
            var mediaImage = mediaList[id]
            var rect = Rect2(Vector2i.ZERO, size)
            mediaReplaceRect[mediaId] = Rect2(pos, size)
            imageAtlasData.blit_rect(mediaImage, rect, pos)

        mediaReplaceAtlas = ImageTexture.create_from_image(imageAtlasData)

func FileChange() -> void :
    frameIndex = 0
    frameRate = flashAnimeData.frameRate
    if flashAnimeData.layerDictionary.size() != layerVisible.size():
        layerVisible.clear()
        layerVisible.resize(flashAnimeData.layerDictionary.size())
        layerVisible.fill(true)
        mediaReplace.clear()
        mediaReplace.resize(flashAnimeData.mediaDictionary.size())
        mediaReplace.fill(null)
        mediaReplaceUse.clear()
        mediaReplaceUse.resize(flashAnimeData.mediaDictionary.size())
        mediaReplaceUse.fill(false)
    onlyDraw = flashAnimeData.onlyDraw
    meshTexture = flashAnimeData.imageAtlas.get_rid()
    mesh = flashAnimeData.initMesh.duplicate(true)
    _init_material()


    clip = flashAnimeData.clips.keys()[0]
    notify_property_list_changed()

func _physics_process(delta: float) -> void :
    if !onlyDraw:
        return
    if !canRun:
        return

    var refresh: bool = false

    if !clipOver:
        refreshTimer += delta * max(10, trueFrameRate)
        if refreshTimer >= 1.0:
            refresh = true
            refreshTimer = 0.0
        if clipRange.x != clipRange.y:
            elapsedTimer += delta * abs(timeScale) * frameRate
        else:
            frameIndex = clipRange.x
            refresh = true
        if refreshEveryFlame || elapsedTimer >= 1.0:
            refresh = true
        while elapsedTimer >= 1.0:
            elapsedTimer -= 1.0
            if !playBack:
                _emit_frame_events(frameIndex)
                frameIndex += 1
                if frameIndex >= clipRange.y:
                    _emit_frame_events(frameIndex)
                    if !loop:
                        clipOver = true
                        var saveClip: String = clip
                        frameIndex = clipRange.y
                        NextAnimation()
                        if !Engine.is_editor_hint():
                            animeCompleted.emit(saveClip)
                    else:
                        if !Engine.is_editor_hint():
                            refresh = true
                            animeCompleted.emit(clip)
                        frameIndex = clipRange.x
            else:
                _emit_frame_events(frameIndex)
                frameIndex -= 1
                if frameIndex < clipRange.x:
                    if !loop:
                        clipOver = true
                        var saveClip: String = clip
                        frameIndex = clipRange.x
                        NextAnimation()
                        if !Engine.is_editor_hint():
                            animeCompleted.emit(saveClip)
                    else:
                        if !Engine.is_editor_hint():
                            refresh = true
                            animeCompleted.emit(clip)
                        frameIndex = clipRange.y - 1

        if !clipOver:
            if blend:
                blendTimer = clamp(blendTimer + delta * abs(sign(timeScale)), 0.0, blendTime)
                if blendTimer >= blendTime:
                    animeBlendCompleted.emit(clip)
                    blendTime = 0.0
                    blendTimer = 0.0
                    blend = false

    if clipOver:
        if track.size() <= 0:
            _SetProcessEnabled(false)
        return

    if refresh:
        refreshTimer = 0.0
        var frame_changed: bool = frameIndex != _last_update_frame
        if frame_changed:
            _last_update_frame = frameIndex
        if invisible || _is_visible_in_tree:
            if !is_instance_valid(parentSprite):
                if invisible && frame_changed:
                    UpdateInvisibleChild.call_deferred()
                if frame_changed:
                    queue_redraw()
            elif frame_changed:
                queue_redraw()

func _process(delta: float) -> void :
    if onlyDraw:
        return
    if !canRun:
        return
    var refresh: bool = false

    if !clipOver:
        refreshTimer += delta * max(10, trueFrameRate)
        if refreshTimer >= 1.0:
            refresh = true
            refreshTimer = 0.0
        if !playBack:
            if clipRange.x != clipRange.y:
                elapsedTimer += delta * abs(timeScale) * frameRate
            else:
                frameIndex = clipRange.x
                refresh = true
            if refreshEveryFlame || elapsedTimer >= 1.0:
                refresh = true
            while elapsedTimer >= 1.0:
                elapsedTimer -= 1.0
                _emit_frame_events(frameIndex)
                frameIndex += 1
                if frameIndex >= clipRange.y:
                    _emit_frame_events(frameIndex)
                    if !loop:
                        clipOver = true
                        var saveClip: String = clip
                        frameIndex = clipRange.y - 1
                        elapsedTimer = 0.0
                        set_instance_shader_parameter("frameIndex", frameIndex - clipRange.x - 0.5 + elapsedTimer)
                        NextAnimation()
                        if !Engine.is_editor_hint():
                            animeCompleted.emit(saveClip)
                    else:
                        if !Engine.is_editor_hint():
                            refresh = true
                            animeCompleted.emit(clip)
                        frameIndex = clipRange.x
                        elapsedTimer = 0.0
        else:
            if clipRange.x != clipRange.y:
                elapsedTimer -= delta * abs(timeScale) * frameRate
            else:
                frameIndex = clipRange.y
                refresh = true
            if refreshEveryFlame || elapsedTimer <= -1.0:
                refresh = true
            while elapsedTimer <= -1.0:
                elapsedTimer += 1.0
                _emit_frame_events(frameIndex)
                frameIndex -= 1
                if frameIndex < clipRange.x:
                    if !loop:
                        clipOver = true
                        var saveClip: String = clip
                        frameIndex = clipRange.x
                        elapsedTimer = 0.0
                        set_instance_shader_parameter("frameIndex", frameIndex - clipRange.x + 1.0 - elapsedTimer)
                        NextAnimation()
                        if !Engine.is_editor_hint():
                            animeCompleted.emit(saveClip)
                    else:
                        if !Engine.is_editor_hint():
                            refresh = true
                            animeCompleted.emit(clip)
                        frameIndex = clipRange.y - 1
                        elapsedTimer = 0.0

        if !clipOver:
            if blend:
                blendTimer = clamp(blendTimer + delta * abs(sign(timeScale)), 0.0, blendTime)
                set_instance_shader_parameter("blendWeight", blendTimer / blendTime)
                if blendTimer >= blendTime:
                    animeBlendCompleted.emit(clip)
                    blendTime = 0.0
                    blendTimer = 0.0
                    blend = false
                    material.set_shader_parameter("blend", false)
                    material.set_shader_parameter("imageAnimeBlendData", null)
                    material.set_shader_parameter("imageCustomBlendData", null)
                    refresh = true

    if clipOver:
        if track.size() <= 0:
            _SetProcessEnabled(false)
        return

    if refresh:
        set_instance_shader_parameter("frameIndex", frameIndex - clipRange.x + elapsedTimer)
        var frame_changed: bool = frameIndex != _last_update_frame
        if frame_changed:
            _last_update_frame = frameIndex
        if _has_children:
            UpdataChild()
        refreshTimer = 0.0
        if invisible || _is_visible_in_tree:
            if !is_instance_valid(parentSprite):
                if invisible && frame_changed:
                    UpdateInvisibleChild.call_deferred()
                if frame_changed:
                    queue_redraw()
            elif frame_changed:
                queue_redraw()

func UpdateInvisibleChild() -> void :
    RenderingServer.canvas_item_clear(canvasItem)
    if !_has_children:
        return
    var data = flashAnimeData.timelineData[frameIndex]
    for child in _slot_children:
        if child == null:
            continue
        if !child.updateAllFrame:
            if !Engine.is_editor_hint():
                if child.get_child_count() <= 0:
                    continue
        match child.mode:
            0:
                var mediaId: int = data[0][child.followSlotId - 1]
                if mediaId == EMPTY_MEDIA_ID:
                    continue
                var offsetTransform: Transform2D = data[1][child.followSlotId - 1].translated(offset).translated_local(child.offset)
                if !child.useRotate:
                    offsetTransform = offsetTransform.rotated_local( - offsetTransform.get_rotation())
                if !child.useScale:
                    offsetTransform = offsetTransform.scaled_local(Vector2.ONE / offsetTransform.get_scale())
                child.transform = offsetTransform
                if !child.useSkew:
                    child.skew = 0.0
    for child in _sprite_children:
        if child != null:
            RenderingServer.canvas_item_clear(child.canvasItem)

func QueueUpdateMediaPeplace() -> void :
    needMediaPeplaceUpdate = true
    UpdateMediaPeplace.call_deferred()

func UpdateMediaPeplace() -> void :
    if !needMediaPeplaceUpdate:
        return
    needMediaPeplaceUpdate = false
    UpdataMediaPeplaceData()

func UpdataMediaPeplaceData() -> void :
    CreateMediaPeplaceAtlas()
    if is_instance_valid(material):
        material.set_shader_parameter("mediaReplaceAtlas", mediaReplaceAtlas)
        material.set_shader_parameter("mediaReplaceRect", mediaReplaceRect)
        material.set_shader_parameter("mediaReplaceUse", mediaReplaceUse)

func _draw() -> void :
    if !flashAnimeData:
        return
    if onlyDraw:
        if frameIndex < 0 || frameIndex >= flashAnimeData.meshData.size():
            return
        if frameIndex != _last_draw_frame:
            _current_mesh_rid = flashAnimeData.meshData[frameIndex].get_rid()
            _last_draw_frame = frameIndex
        RenderingServer.canvas_item_add_mesh(canvasItem, _current_mesh_rid, Transform2D.IDENTITY.translated(offset), Color.WHITE, meshTexture)
    else:
        if !mesh:
            return
        RenderingServer.canvas_item_add_mesh(canvasItem, mesh.get_rid(), Transform2D.IDENTITY.translated(offset), Color.WHITE, meshTexture)

func UpdataChild() -> void :
    if !_has_children:
        return
    var data = flashAnimeData.timelineData[frameIndex]
    var dataNext = flashAnimeData.timelineData[(frameIndex + 1) % flashAnimeData.frameMax]
    var _elapsedTimer: float = elapsedTimer
    var _offset: Vector2 = offset
    var _playBack: bool = playBack
    for child in _slot_children:
        if child == null:
            continue
        if !child.updateAllFrame:
            if !Engine.is_editor_hint():
                if child.get_child_count() <= 0:
                    continue
        match child.mode:
            0:
                var slot_idx: int = child.followSlotId - 1
                var mediaId: int = data[0][slot_idx]
                if mediaId == EMPTY_MEDIA_ID:
                    if child.useFollowVisible:
                        child.visible = false
                    continue
                var next_transform: Transform2D = dataNext[1][slot_idx]
                if next_transform != Transform2D.IDENTITY && data[1][slot_idx] != Transform2D.IDENTITY:
                    var mediaTransform: Transform2D
                    if !_playBack:
                        mediaTransform = data[1][slot_idx].interpolate_with(next_transform, _elapsedTimer)
                    else:
                        mediaTransform = data[1][slot_idx].interpolate_with(next_transform, 1.0 + _elapsedTimer)
                    var offsetTransform: Transform2D = mediaTransform.translated(_offset).translated_local(child.offset)
                    if !child.useRotate:
                        offsetTransform = offsetTransform.rotated_local( - offsetTransform.get_rotation())
                    if !child.useScale:
                        offsetTransform = offsetTransform.scaled_local(Vector2.ONE / offsetTransform.get_scale())
                    child.transform = offsetTransform
                    if !child.useSkew:
                        child.skew = 0.0
                    if child.useFollowVisible:
                        child.visible = true
                else:
                    if child.useFollowVisible:
                        child.visible = false
    for child in _sprite_children:
        if child == null:
            continue
        var layer_idx: int = child.followParentSpriteLayerId
        var cur_transform: Transform2D = data[1][layer_idx]
        var next_transform: Transform2D = dataNext[1][layer_idx]
        if cur_transform != Transform2D.IDENTITY && next_transform != Transform2D.IDENTITY:
            var mediaTransform: Transform2D
            if !_playBack:
                mediaTransform = cur_transform.interpolate_with(next_transform, _elapsedTimer)
            else:
                mediaTransform = cur_transform.interpolate_with(next_transform, 1.0 + _elapsedTimer)
            if child.useFollowVisible:
                child.visible = true
            if child.usePos:
                child.position = mediaTransform.get_origin() + _offset
                if child.useRotate:
                    child.rotation = mediaTransform.get_rotation() + child.offsetRotate
                child.queue_redraw()
        else:
            if child.useFollowVisible:
                child.visible = false
func _emit_frame_events(frame_idx: int) -> void :
    if !flashAnimeData || frame_idx < 0 || frame_idx >= flashAnimeData.events.size():
        return
    if !flashAnimeData.events[frame_idx].is_empty():
        for eventDictionary: Dictionary in flashAnimeData.events[frame_idx]:
            animeEvent.emit(eventDictionary["Command"], eventDictionary["Argument"])

func _init_material() -> void :
    if !onlyDraw:
        QueueUpdateMediaPeplace()
        material = ShaderMaterial.new()
        material.shader = SHADER_TOWER_DEFENSE_CHARACTER
        if clip != "":
            if flashAnimeData.clips.has(clip):
                material.set_shader_parameter("imageAnimeData", flashAnimeData.imageAnimeDictionary[clip])
                material.set_shader_parameter("imageCustomData", flashAnimeData.imageCustomDictionary[clip])
        material.set_shader_parameter("imageAtlasSize", flashAnimeData.imageAtlas.get_size())
        material.set_shader_parameter("layerVisible", layerVisible)
        material.set_shader_parameter("uvs", flashAnimeData.mediaList)
    else:
        material = null

func _cache_children() -> void :
    _slot_children.clear()
    _sprite_children.clear()
    for child in get_children():
        if child is AdobeAnimateSlot:
            _slot_children.append(child)
        elif child is AdobeAnimateSprite:
            _sprite_children.append(child)
    _has_children = _slot_children.size() > 0 || _sprite_children.size() > 0

func SetMultimeshModulate(parent: Node) -> void :
    modulate = meshColor
    for child in parent.get_children(true):
        if child is AdobeAnimateSprite:
            child.meshColor = meshColor


        if child.get_child_count() > 0:
            SetMultimeshModulate(child)

func HasClip(_clip: String) -> bool:
    return flashAnimeData.HasClip(_clip)

func SetClip(_clip: String) -> void :
    var saveClip: String = clip
    var saveRange: Vector2i = clipRange
    clip = _clip
    if is_instance_valid(flashAnimeData):
        if Engine.is_editor_hint():
            blendTime = blendTimeInit
        if !onlyDraw:
            if flashAnimeData.clips.has(clip):
                if is_instance_valid(material):
                    material.set_shader_parameter("imageAnimeData", flashAnimeData.imageAnimeDictionary[clip])
                    material.set_shader_parameter("imageCustomData", flashAnimeData.imageCustomDictionary[clip])
        var clipRangeGet = flashAnimeData.GetClip(clip)
        clipRangeGet.y = clampf(clipRangeGet.y, -1, flashAnimeData.frameMax)
        if clipRangeGet != Vector2i.ONE * -1:
            var frameBlend = clamp(frameIndex, clipRange.x, clipRange.y)
            if initClip:
                if !skipLastFrame || (skipLastFrame && frameBlend != clipRange.x && frameBlend != clipRange.y):
                    blendTimer = 0.0
                    if !onlyDraw:
                        if loop && blendTime != 0.0:
                            set_instance_shader_parameter("blendWeight", 0.0)
                            if is_instance_valid(material):
                                material.set_shader_parameter("frameBlend", frameIndex - saveRange.x + elapsedTimer)
                                if flashAnimeData.clips.has(saveClip):
                                    material.set_shader_parameter("imageAnimeBlendData", flashAnimeData.imageAnimeDictionary[saveClip])
                                    material.set_shader_parameter("imageCustomBlendData", flashAnimeData.imageCustomDictionary[saveClip])
                                material.set_shader_parameter("blend", true)
                            blend = true
                        else:
                            if is_instance_valid(material):
                                material.set_shader_parameter("frameBlend", -1)
                                if flashAnimeData.clips.has(saveClip):
                                    material.set_shader_parameter("imageAnimeBlendData", null)
                                    material.set_shader_parameter("imageCustomBlendData", null)
                                material.set_shader_parameter("blend", false)
                            blend = false
                clipRange = clipRangeGet
                frameIndex = clipRange.x
                elapsedTimer = 0.0
                _last_update_frame = -1
                if !onlyDraw:
                    set_instance_shader_parameter("frameIndex", frameIndex - clipRange.x + elapsedTimer)
                set_deferred("clipOver", false)
                if !_process_enabled:
                    _SetProcessEnabled(true)
            else:
                if !onlyDraw:
                    set_instance_shader_parameter("frameIndex", frameIndex - clipRange.x + elapsedTimer)
    initClip = true
    if !is_instance_valid(parentSprite):
        queue_redraw()

func ResetAnimation() -> void :
    elapsedTimer = 0.0
    frameIndex = clipRange.x
    _last_update_frame = -1
    UpdataChild()
    if !onlyDraw:
        set_instance_shader_parameter("frameIndex", frameIndex - clipRange.x + elapsedTimer - 0.1)
    if !is_instance_valid(parentSprite):
        queue_redraw()
    if !_process_enabled:
        _SetProcessEnabled(true)

func SetAnimation(_clip: String, _loop: bool = true, _blendTime: float = 0.0) -> void :
    track.clear()
    AddAnimation(_clip, 0.0, _loop, _blendTime)
    clipOver = false
    if !_process_enabled:
        _SetProcessEnabled(true)
    NextAnimation()

func AddAnimation(_clip: String, _delay: float, _loop: bool = true, _blendTime: float = 0.0) -> void :
    track.insert(0, AdobeAnimateTrack.new(Array(_clip.split("&", false)).pick_random(), _delay, _loop, _blendTime))

func NextAnimation() -> AdobeAnimateTrack:
    if track.size() <= 0:
        return null
    var trackConfig: AdobeAnimateTrack = track.pop_back()
    if trackConfig:
        if trackConfig.delay != 0.0:
            await get_tree().create_timer(trackConfig.delay, false).timeout
            if !is_instance_valid(self):
                return null
        if clip != trackConfig.clip:
            clipOver = false
        blendTime = trackConfig.blendTime
        if Engine.is_editor_hint():
            blendTime = blendTimeInit
        clip = trackConfig.clip
        loop = trackConfig.loop

        if !Engine.is_editor_hint():
            animeStarted.emit(clip)
            clipOver = false
            if !_process_enabled:
                _SetProcessEnabled(true)
    else:
        if !Engine.is_editor_hint():
            animeStoped.emit(clip)
    return trackConfig

func GetProgress() -> float:
    var range_size: = clipRange.y - clipRange.x + 1.0
    if range_size <= 0.0:
        return 0.0
    return (frameIndex - clipRange.x) / range_size

func SetFliter(layerName: StringName, open: bool) -> void :
    if flashAnimeData.layerDictionary.has(layerName):
        layerVisible[flashAnimeData.layerDictionary[layerName]] = open
    if !onlyDraw:
        if is_instance_valid(material):
            material.set_shader_parameter("layerVisible", layerVisible)
    if !is_instance_valid(parentSprite):
        queue_redraw()

func GetFliter(layerName: StringName) -> bool:
    if flashAnimeData.layerDictionary.has(layerName):
        return layerVisible[flashAnimeData.layerDictionary[layerName]]
    return false

func SetFliters(layerNameList: Array, open: bool) -> void :
    for layerName in layerNameList:
        SetFliter(layerName, open)
    if !onlyDraw:
        if is_instance_valid(material):
            material.set_shader_parameter("layerVisible", layerVisible)
    if !is_instance_valid(parentSprite):
        queue_redraw()

func SetReplace(mediaName: StringName, texture: Texture2D) -> void :
    if flashAnimeData.mediaDictionary.has(mediaName):
        mediaReplace[flashAnimeData.mediaDictionary[mediaName]] = texture
        if is_instance_valid(texture):
            mediaReplaceUse[flashAnimeData.mediaDictionary[mediaName]] = true
        else:
            mediaReplaceUse[flashAnimeData.mediaDictionary[mediaName]] = false
    if !onlyDraw:
        if is_instance_valid(material):
            QueueUpdateMediaPeplace()

    if !is_instance_valid(parentSprite):
        queue_redraw()

func GetReplace(mediaName: StringName) -> Texture2D:
    if flashAnimeData.mediaDictionary.has(mediaName):
        return mediaReplace[flashAnimeData.mediaDictionary[mediaName]]
    return null

func ExportSpriteSave() -> Dictionary:
    var trackData: Array = []
    for t: AdobeAnimateTrack in track:
        trackData.append({"clip": t.clip, "delay": t.delay, "loop": t.loop, "blendTime": t.blendTime})
    return {
        "clip": clip, 
        "clipRangeX": clipRange.x, 
        "clipRangeY": clipRange.y, 
        "frameIndex": frameIndex, 
        "elapsedTimer": elapsedTimer, 
        "loop": loop, 
        "clipOver": clipOver, 
        "timeScale": timeScale, 
        "pause": pause, 
        "playBack": playBack, 
        "blend": blend, 
        "blendTime": blendTime, 
        "blendTimer": blendTimer, 
        "track": trackData, 
        "layerVisible": layerVisible.duplicate(true), 
        "initClip": initClip, 
    }

func ImportSpriteSave(data: Dictionary) -> void :
    if data.is_empty():
        return
    var saveClip: String = data.get("clip", clip)
    var saveRangeX: int = data.get("clipRangeX", clipRange.x)
    var saveRangeY: int = data.get("clipRangeY", clipRange.y)
    var saveFrameIndex: int = data.get("frameIndex", frameIndex)
    var saveElapsedTimer: float = data.get("elapsedTimer", elapsedTimer)
    var saveLoop: bool = data.get("loop", loop)
    var saveClipOver: bool = data.get("clipOver", clipOver)
    var saveTimeScale: float = data.get("timeScale", timeScale)
    var savePause: bool = data.get("pause", pause)
    var savePlayBack: bool = data.get("playBack", playBack)
    var saveBlend: bool = data.get("blend", blend)
    var saveBlendTime: float = data.get("blendTime", blendTime)
    var saveBlendTimer: float = data.get("blendTimer", blendTimer)
    var saveInitClip: bool = data.get("initClip", initClip)
    var saveLayerVisible: Array = data.get("layerVisible", [])
    var saveTrack: Array = data.get("track", [])
    clip = saveClip
    clipRange = Vector2i(saveRangeX, saveRangeY)
    frameIndex = saveFrameIndex
    elapsedTimer = saveElapsedTimer
    loop = saveLoop
    clipOver = saveClipOver
    timeScale = saveTimeScale
    pause = savePause
    playBack = savePlayBack
    blend = saveBlend
    blendTime = saveBlendTime
    blendTimer = saveBlendTimer
    initClip = saveInitClip
    if saveLayerVisible.size() == layerVisible.size():
        layerVisible = saveLayerVisible
    track.clear()
    for t: Dictionary in saveTrack:
        var newTrack: AdobeAnimateTrack = AdobeAnimateTrack.new(t.get("clip", ""), t.get("delay", 0.0), t.get("loop", true), t.get("blendTime", 0.0))
        track.append(newTrack)
    if !onlyDraw:
        set_instance_shader_parameter("frameIndex", frameIndex - clipRange.x + elapsedTimer)
        if is_instance_valid(material):
            material.set_shader_parameter("layerVisible", layerVisible)
    if !clipOver || track.size() > 0:
        _SetProcessEnabled(true)
    queue_redraw()
