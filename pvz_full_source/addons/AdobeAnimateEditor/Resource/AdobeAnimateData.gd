@tool
class_name AdobeAnimateData extends Resource

@export_file("*.dat") var animeFile: String:
    set(str):
        animeFile = str
        if str != "":
            Init()
        else:
            Clear()
        emit_changed()
        notify_property_list_changed()
@export var onlyDraw: bool = false:
    set(_onlyDraw):
        onlyDraw = _onlyDraw
        if animeFile != "":
            Init()
        emit_changed()
        notify_property_list_changed()
@export var frameRate: float = 30.0
@export var frameScale: int = 1:
    set(_frameScale):
        frameScale = _frameScale
        if animeFile != "":
            Init()
        emit_changed()
        notify_property_list_changed()
@export var frameMax: int = 0
@export var imageAtlas: PortableCompressedTexture2D
@export var imageCustomDictionary: Dictionary[StringName, ImageTexture]
@export var imageAnimeDictionary: Dictionary[StringName, ImageTexture]
@export var timelineData: Array[Array]
@export var mediaList: Array[Rect2]
@export var layerList: PackedStringArray
@export var events: Array[Array]
@export var clips: Dictionary[StringName, Vector2i]
@export var mediaDictionary: Dictionary[StringName, int]
@export_storage var layerDictionary: Dictionary[StringName, int]
@export var maxElement: int = 0
@export_storage var initMesh: ArrayMesh
@export var meshData: Array[ArrayMesh]

func Init():
    if !Engine.is_editor_hint():
        return
    Clear()
    if !FileAccess.file_exists(animeFile):
        return
    var file: FileAccess = FileAccess.open(animeFile, FileAccess.READ)

    frameRate = file.get_float()
    if frameRate <= 0.01:
        frameRate = 24.0
    frameMax = file.get_16()


    var imageAtlasSize: Vector2i = Vector2i(file.get_16(), file.get_16())
    var imageAtlasDataBufferLength: int = file.get_64()
    var imageAtlasDataBuffer: PackedByteArray = file.get_buffer(imageAtlasDataBufferLength)
    var imageAtlasData: Image = Image.create_from_data(imageAtlasSize.x, imageAtlasSize.y, false, Image.FORMAT_RGBA8, imageAtlasDataBuffer)
    imageAtlas = PortableCompressedTexture2D.new()
    imageAtlas.create_from_image(imageAtlasData, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)



    var mediaSize: int = file.get_16()
    for mediaId in mediaSize:
        var mediaName: String = file.get_pascal_string()
        var mediaRect: Rect2 = Rect2(file.get_float(), file.get_float(), file.get_float(), file.get_float())
        mediaDictionary[mediaName] = mediaId
        mediaList.append(mediaRect)

    var timelineGet: Array[Array] = []
    var layerSize: int = file.get_16()
    for layerId in layerSize:
        var layerName: String = file.get_pascal_string()
        layerDictionary[layerName] = layerId
        layerList.append(layerName)
        var layerFrameList: Array = []
        for index in frameMax:
            var elementSize: int = file.get_16()
            var elementList: Array = []
            for elementId in elementSize:
                var element: Array = []
                var mediaId: int = file.get_16()
                var transform: Transform2D = Transform2D(Vector2(file.get_float(), file.get_float()), Vector2(file.get_float(), file.get_float()), Vector2(file.get_float(), file.get_float()))
                var color: Color = Color.hex(file.get_32())
                element.append(mediaId)
                element.append(transform)
                element.append(color)
                elementList.append(element)
            layerFrameList.append(elementList)
        timelineGet.append(layerFrameList)

    var clipSize: int = file.get_16()
    for clipId in clipSize:
        var clipName: String = file.get_pascal_string()
        var _range: Vector2i = Vector2i(file.get_16(), file.get_16()) * frameScale
        clips[clipName] = _range


    var eventSize: int = file.get_16()
    events.resize((frameMax * frameScale) - frameScale + 1)
    for eventId in eventSize:
        var eventPos: int = file.get_16() * frameScale
        var eventListSize: int = file.get_16()
        var eventList: Array[Dictionary] = []
        for eventDictionaryId in eventListSize:
            var eventDictionary: Dictionary = {}
            eventDictionary["Command"] = file.get_pascal_string()
            eventDictionary["Argument"] = file.get_pascal_string()
            eventList.append(eventDictionary)
        events[eventPos] = eventList

    file.close()

    var timeline: Array[Array] = []
    var layerFrameSizeList: Array[int] = []
    maxElement = 0

    for layerId in timelineGet.size():
        var layerFrameListGet: Array = timelineGet[layerId]
        var layerFrameList: Array = []
        var maxElementNum: int = max(0, layerFrameListGet[layerFrameListGet.size() - 1].size())
        for index in layerFrameListGet.size() - 1:
            var elementGetList: Array = layerFrameListGet[index]
            var elementGetNextList: Array = layerFrameListGet[index + 1]
            layerFrameList.append(elementGetList)
            maxElementNum = max(maxElementNum, elementGetList.size())
            for i in frameScale - 1:
                var elemenList: Array = []
                for elementId in elementGetList.size():
                    var element: Array = []
                    var weight: float = float(i + 1) / frameScale
                    element.append(elementGetList[elementId][0])
                    if elementGetNextList.size() == elementGetList.size():
                        if elementGetNextList[elementId][0] != 65535:
                            element.append(Transform2D(elementGetList[elementId][1].x.lerp(elementGetNextList[elementId][1].x, weight), elementGetList[elementId][1].y.lerp(elementGetNextList[elementId][1].y, weight), elementGetList[elementId][1].origin.lerp(elementGetNextList[elementId][1].origin, weight)))
                            element.append(lerp(elementGetList[elementId][2], elementGetNextList[elementId][2], weight))
                        else:
                            element.append(elementGetList[elementId][1])
                            element.append(elementGetList[elementId][2])
                    else:
                        element.append(elementGetList[elementId][1])
                        element.append(elementGetList[elementId][2])
                    elemenList.append(element)

                layerFrameList.append(elemenList)
        layerFrameList.append(layerFrameListGet[layerFrameListGet.size() - 1])
        layerFrameSizeList.append(maxElementNum)
        maxElement += maxElementNum
        timeline.append(layerFrameList)

    frameMax = (frameMax * frameScale) - frameScale + 1

    frameRate = frameRate * frameScale

    if !onlyDraw:
        var xMin: float = 100000.0
        var yMin: float = 100000.0
        var xMax: float = -100000.0
        var yMax: float = -100000.0

        var st = SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)

        for index in frameMax:
            timelineData.append([PackedInt32Array(), []])
            for layerId in timeline.size():
                var layer = timeline[layerId][index]
                for elementId in layerFrameSizeList[layerId]:
                    if elementId == 0:
                        if elementId < layer.size():
                            var element = layer[elementId]
                            timelineData[index][0].append(element[0])
                            timelineData[index][1].append(element[1])
                        else:
                            timelineData[index][0].append(65535)
                            timelineData[index][1].append(Transform2D.IDENTITY)
                    if index == 0:
                        st.set_uv(Vector2(0.0, 0.0))
                        st.set_color(Color.WHITE)
                        st.add_vertex(Vector3(0.0, 0.0, 0.0))

                        st.set_uv(Vector2(0.0, 1.0))
                        st.set_color(Color.WHITE)
                        st.add_vertex(Vector3(0.0, 0.0, 0.0))

                        st.set_uv(Vector2(1.0, 1.0))
                        st.set_color(Color.WHITE)
                        st.add_vertex(Vector3(0.0, 0.0, 0.0))

                        st.set_uv(Vector2(1.0, 1.0))
                        st.set_color(Color.WHITE)
                        st.add_vertex(Vector3(0.0, 0.0, 0.0))

                        st.set_uv(Vector2(1.0, 0.0))
                        st.set_color(Color.WHITE)
                        st.add_vertex(Vector3(0.0, 0.0, 0.0))

                        st.set_uv(Vector2(0.0, 0.0))
                        st.set_color(Color.WHITE)
                        st.add_vertex(Vector3(0.0, 0.0, 0.0))
        initMesh = st.commit()
        initMesh.custom_aabb = AABB(Vector3(xMin, yMin, 0.0), Vector3(xMax - xMin, yMax - yMin, 0.0))

        for clipName: String in clips.keys():
            var clipRange = clips[clipName]
            var frameNum: int = clipRange.y - clipRange.x + 1
            var customDataImage = Image.create(maxElement, frameNum, false, Image.FORMAT_RGBAF)
            var dataImage = Image.create(maxElement * 3, frameNum, false, Image.FORMAT_RGBAF)
            for index in range(clipRange.x, clipRange.y + 1, 1):
                var currentFrame: int = 0
                var y: int = index - clipRange.x
                for layerId in timeline.size():
                    var layer = timeline[layerId][index]
                    for elementId in layerFrameSizeList[layerId]:
                        var x_base: int = currentFrame * 3
                        if elementId < layer.size():
                            var element = layer[elementId]
                            var mediaId: int = element[0]
                            if mediaId != 65535:
                                var tranform: Transform2D = element[1]
                                var color: Color = element[2]
                                customDataImage.set_pixel(currentFrame, y, Color(mediaId, layerId, 0.0, 0.0))
                                dataImage.set_pixel(x_base, y, Color(tranform.x.x, tranform.x.y, tranform.y.x, tranform.y.y))
                                dataImage.set_pixel(x_base + 1, y, Color(tranform.origin.x, tranform.origin.y, 0.0, 0.0))
                                dataImage.set_pixel(x_base + 2, y, color)
                            else:
                                customDataImage.set_pixel(currentFrame, y, Color(65535.0, layerId, 0.0, 0.0))
                                dataImage.set_pixel(x_base, y, Color(1.0, 0.0, 0.0, 1.0))
                                dataImage.set_pixel(x_base + 1, y, Color(0.0, 0.0, 0.0, 0.0))
                                dataImage.set_pixel(x_base + 2, y, Color(1.0, 1.0, 1.0, 0.0))
                        else:
                            customDataImage.set_pixel(currentFrame, y, Color(65535.0, layerId, 0.0, 0.0))
                            dataImage.set_pixel(x_base, y, Color(1.0, 0.0, 0.0, 1.0))
                            dataImage.set_pixel(x_base + 1, y, Color(0.0, 0.0, 0.0, 0.0))
                            dataImage.set_pixel(x_base + 2, y, Color(1.0, 1.0, 1.0, 0.0))
                        currentFrame += 1
            imageCustomDictionary[clipName] = ImageTexture.create_from_image(customDataImage)
            imageAnimeDictionary[clipName] = ImageTexture.create_from_image(dataImage)
    else:
        for index in frameMax:
            var st = SurfaceTool.new()
            st.begin(Mesh.PRIMITIVE_TRIANGLES)
            for layerId in timeline.size():
                var layer = timeline[layerId][index]
                for elementId in layerFrameSizeList[layerId]:
                    if elementId < layer.size():
                        var element = layer[elementId]
                        var mediaId: int = element[0]
                        var tranform: Transform2D = element[1]
                        if mediaId != 65535:
                            var mediaRect: Rect2 = mediaList[mediaId]
                            var color: Color = element[2]
                            var pos1: Vector2 = tranform * Vector2(0.0, 0.0)
                            var pos2: Vector2 = tranform * Vector2(0.0, mediaRect.size.y)
                            var pos3: Vector2 = tranform * Vector2(mediaRect.size.x, mediaRect.size.y)
                            var pos4: Vector2 = tranform * Vector2(mediaRect.size.x, 0.0)
                            var uvRect: Rect2 = Rect2((mediaRect.position + Vector2.ONE * 0.5) / Vector2(imageAtlasSize), (mediaRect.position + mediaRect.size - Vector2.ONE * 0.5) / Vector2(imageAtlasSize))
                            st.set_color(color)
                            st.set_uv(Vector2(uvRect.position.x, uvRect.position.y))
                            st.add_vertex(Vector3(pos1.x, pos1.y, 0.0))

                            st.set_color(color)
                            st.set_uv(Vector2(uvRect.position.x, uvRect.size.y))
                            st.add_vertex(Vector3(pos2.x, pos2.y, 0.0))

                            st.set_color(color)
                            st.set_uv(Vector2(uvRect.size.x, uvRect.size.y))
                            st.add_vertex(Vector3(pos3.x, pos3.y, 0.0))

                            st.set_color(color)
                            st.set_uv(Vector2(uvRect.size.x, uvRect.size.y))
                            st.add_vertex(Vector3(pos3.x, pos3.y, 0.0))

                            st.set_color(color)
                            st.set_uv(Vector2(uvRect.size.x, uvRect.position.y))
                            st.add_vertex(Vector3(pos4.x, pos4.y, 0.0))

                            st.set_color(color)
                            st.set_uv(Vector2(uvRect.position.x, uvRect.position.y))
                            st.add_vertex(Vector3(pos1.x, pos1.y, 0.0))
                        else:
                            for i in 6:
                                st.set_color(Color.WHITE)
                                st.set_uv(Vector2(0.0, 0.0))
                                st.add_vertex(Vector3(0.0, 0.0, 0.0))
                    else:
                        for i in 6:
                            st.set_color(Color.WHITE)
                            st.set_uv(Vector2(0.0, 0.0))
                            st.add_vertex(Vector3(0.0, 0.0, 0.0))

            meshData.append(st.commit())

func Clear():
    imageAtlas = null
    imageCustomDictionary.clear()
    imageAnimeDictionary.clear()
    mediaList.clear()
    layerList.clear()
    clips.clear()
    events.clear()
    mediaDictionary.clear()
    layerDictionary.clear()
    meshData.clear()
    timelineData.clear()

func HasClip(clipName: StringName) -> bool:
    return clips.has(clipName)

func GetClip(clipName: StringName) -> Vector2i:
    if clips.has(clipName):
        return clips[clipName]
    return Vector2i.ONE * -1
