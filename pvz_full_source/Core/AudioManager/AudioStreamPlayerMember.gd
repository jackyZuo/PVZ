class_name AudioStreamPlayerMember extends AudioStreamPlayer

@export var type: AudioManagerEnum.TYPE = AudioManagerEnum.TYPE.SFX
@export var volumeScale: float = 1.0:
    set(_volumeScale):
        volumeScale = _volumeScale
        VolumRefresh()

func _ready() -> void :
    VolumRefresh()

func VolumRefresh() -> void :
    volume_db = linear_to_db(volumeScale)
