@tool
extends TowerDefenseVase

var characterList: Array

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    await get_tree().physics_frame
    for character: TowerDefenseCharacter in characterList:
        character.global_position.x = global_position.x
        character.targetRegistrationComponent.canProjectileCheck = false
        character.process_mode = Node.PROCESS_MODE_DISABLED
        character.visible = false
        if character is TowerDefenseZombie:
            character.remove_from_group("Zombie")
        if character is TowerDefensePlant:
            character.remove_from_group("Plant")

func DestroySet() -> void :
    if over:
        return
    over = true
    AudioManager.AudioPlay("VaseBreaking", AudioManagerEnum.TYPE.SFX)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(chunkParticles, gridPos)
    effect.global_position = transformPoint.global_position - Vector2(0, 30.0)
    characterNode.add_child(effect)

    for character: TowerDefenseCharacter in characterList:
        character.process_mode = Node.PROCESS_MODE_INHERIT
        character.visible = true
        character.targetRegistrationComponent.canProjectileCheck = true
        if character is TowerDefenseZombie:
            character.add_to_group("Zombie")
            character.WalkReady()
        if character is TowerDefensePlant:
            character.add_to_group("Plant")
