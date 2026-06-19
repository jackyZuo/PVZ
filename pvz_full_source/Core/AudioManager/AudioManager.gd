extends Node

@export var audioMemberDictionary: Dictionary = {}

var audioStack: Array[Dictionary] = []

func _ready() -> void :
    audioMemberDictionary[AudioManagerEnum.TYPE.MUSIC] = {}
    audioMemberDictionary[AudioManagerEnum.TYPE.SFX] = {}

    _setup_buses()

    VolumSet(AudioManagerEnum.TYPE.MUSIC, GameSaveManager.GetConfigValue("MusicVolum"))
    VolumSet(AudioManagerEnum.TYPE.SFX, GameSaveManager.GetConfigValue("SfxVolum"))

func _setup_buses() -> void :
    if AudioServer.get_bus_index("Music") == -1:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
        AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
    if AudioServer.get_bus_index("SFX") == -1:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
        AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")

func _get_bus_name(type: AudioManagerEnum.TYPE) -> String:
    match type:
        AudioManagerEnum.TYPE.MUSIC:
            return "Music"
        AudioManagerEnum.TYPE.SFX:
            return "SFX"
    return "Master"

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if Engine.get_physics_frames() % 4 == 0:
        return
    if audioStack.size() > 0:
        var audioPlayList: Array[String] = []
        for audioDictionary: Dictionary in audioStack:
            if audioPlayList.has(audioDictionary["Stream"]):
                continue
            audioPlayList.append(audioDictionary["Stream"])

            var player = MemberFind(audioDictionary["Stream"], audioDictionary["Type"])
            if is_instance_valid(player):
                player.play(audioDictionary["Pos"])
                if audioDictionary["PauseAlive"]:
                    player.process_mode = Node.PROCESS_MODE_ALWAYS
                else:
                    player.process_mode = Node.PROCESS_MODE_PAUSABLE

        audioStack.clear()

func MemberFind(stream: String, type: AudioManagerEnum.TYPE = AudioManagerEnum.TYPE.SFX) -> AudioStreamPlayerMember:
    var streamRes: AudioStream
    if audioMemberDictionary[type].has(stream) && is_instance_valid(audioMemberDictionary[type][stream]):
        return audioMemberDictionary[type][stream]
    if ResourceManager.AUDIOS.has(stream):
        streamRes = ResourceManager.AUDIOS[stream]
    var modAudioFind: AudioStream = ModManager.FindAudio(stream)
    if modAudioFind != null:
        streamRes = modAudioFind
    if is_instance_valid(streamRes):
        var player = AudioStreamPlayerMember.new()
        player.type = type
        player.bus = _get_bus_name(type)
        player.stream = streamRes
        player.process_mode = Node.PROCESS_MODE_PAUSABLE
        match type:
            AudioManagerEnum.TYPE.SFX:
                player.max_polyphony = 10
        add_child(player)
        audioMemberDictionary[type][stream] = player
        return audioMemberDictionary[type][stream]
    return null

func VolumSet(type: AudioManagerEnum.TYPE = AudioManagerEnum.TYPE.SFX, valum: float = 1.0) -> void :
    var bus_idx: int = AudioServer.get_bus_index(_get_bus_name(type))
    if bus_idx != -1:
        AudioServer.set_bus_volume_db(bus_idx, linear_to_db(valum))
        AudioServer.set_bus_mute(bus_idx, valum <= 0.0)

func VolumGet(type: AudioManagerEnum.TYPE = AudioManagerEnum.TYPE.SFX) -> float:
    var bus_idx: int = AudioServer.get_bus_index(_get_bus_name(type))
    if bus_idx != -1:
        return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
    return 1.0

func AudioStopAll() -> void :
    for memberDictionary: Dictionary in audioMemberDictionary.values():
        for member: String in memberDictionary.keys():
            if !memberDictionary[member]:
                memberDictionary[member] = null
            if memberDictionary[member]:
                memberDictionary[member].queue_free()
                memberDictionary[member] = null
    for node in get_children():
        node.queue_free()

func AudioPlay(stream: String, type: AudioManagerEnum.TYPE = AudioManagerEnum.TYPE.SFX, pos: float = 0.0, once: bool = true, pauseAlive: bool = false) -> AudioStreamPlayerMember:
    var modAudioFind: AudioStream = ModManager.FindAudio(stream)
    if !ResourceManager.AUDIOS.has(stream) && modAudioFind == null:
        return null
    var player: AudioStreamPlayerMember = null
    match type:
        AudioManagerEnum.TYPE.SFX:
            var audioDictionary: Dictionary = {
                "Stream": stream, 
                "Type": type, 
                "Pos": pos, 
                "Once": once, 
                "PauseAlive": pauseAlive
            }
            audioStack.append(audioDictionary)
        AudioManagerEnum.TYPE.MUSIC:
            player = MemberFind(stream, type)
            if pauseAlive:
                player.process_mode = Node.PROCESS_MODE_ALWAYS
            else:
                player.process_mode = Node.PROCESS_MODE_PAUSABLE
            player.play(pos)
    return player
