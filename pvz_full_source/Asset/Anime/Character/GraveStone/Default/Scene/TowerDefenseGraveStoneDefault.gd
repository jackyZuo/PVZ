@tool
extends TowerDefenseGravestone

var over: bool = false

func _ready() -> void :
    super._ready()
    idleAnimeClip = "&".join(PackedStringArray(sprite.flashAnimeData.clips.keys()))
    HitBoxDestroy()

func IdleEntered() -> void :
    if over:
        return
    over = true
    super.IdleEntered()
