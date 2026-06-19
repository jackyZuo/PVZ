@tool
extends TowerDefensePlant

const VASE_ZOMBIE_CHUNKS = preload("uid://djs8ytienucdy")

@onready var squashComponent: SquashComponent = %SquashComponent
@onready var attackComponent: AttackComponent = %AttackComponent

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.invincible = true
    await get_tree().create_timer(0.5, false).timeout
    if !squashComponent.IsRunning():
        instance.invincible = false

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale

func HitAliveCharacters(charcterList: Array) -> void :
    var characterList: Array = charcterList.filter(
        func(checkCharacter: TowerDefenseCharacter):
            if checkCharacter is TowerDefenseZombie:
                if checkCharacter.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                    return false
            return true
    )

    if characterList.size() > 0:
        if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
            Destroy()
            return
        var vase = CreateCharacter("VaseSquashBlack", global_position, TowerDefenseManager.GetMapGridPos(global_position), groundHeight)
        if is_instance_valid(vase):
            vase.characterList = characterList
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, vase)
                MultiPlayerManager.SendSpawnCharacterAt("VaseSquashBlack", gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, false, 0.0, true, global_position.x, global_position.y, false, groundHeight)
    Destroy()
