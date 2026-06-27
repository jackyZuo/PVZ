@tool
extends TowerDefensePlant

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if !inGame:
        sprite.back.z_index = 0
    if currentCustom.has("Custom0"):
        sprite.back.SetFliter("Pumpkin_back", false)
        sprite.back.SetFliter("skin1_4", true)
    sprite.animeStarted.connect(AnimeStarted)

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        sprite.back.SetFliter("Pumpkin_back", false)
        sprite.back.SetFliter("skin1_4", true)
    else:
        sprite.back.SetFliter("Pumpkin_back", true)
        sprite.back.SetFliter("skin1_4", false)

func AnimeStarted(clip: String) -> void :
    match clip:
        explodeComponent.explodeAnimeClips:
            if is_instance_valid(cell):
                for character in cell.characterList:
                    if character is not TowerDefensePlant:
                        continue
                    if character is TowerDefensePlantBowlingBase:
                        continue
                    if character.instance.hologram:
                        continue
                    if character.config.name != config.name && character.instance.hypnoses == instance.hypnoses:
                        character.instance.invincible = true
                        character.componentAlive = false
                        character.HitBoxDestroy()
                        var tween = create_tween()
                        tween.set_ease(Tween.EASE_IN_OUT)
                        tween.set_trans(Tween.TRANS_SINE)
                        tween.tween_property(character.transformPoint, "scale", Vector2.ZERO, 0.5)

func Explode() -> void :
    if is_instance_valid(cell):
        for character in cell.characterList.duplicate():
            if character is not TowerDefensePlant:
                continue
            if character is TowerDefensePlantBowlingBase:
                continue
            if character.instance.hologram:
                continue
            if character.config.name != config.name && character.instance.hypnoses == instance.hypnoses:
                character.Recycle(1.0, true)
