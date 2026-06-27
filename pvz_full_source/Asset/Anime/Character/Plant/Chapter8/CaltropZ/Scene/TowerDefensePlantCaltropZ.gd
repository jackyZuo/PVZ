@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var timerComponent: TimerComponent = %TimerComponent

@export var attack: float = 20.0

@export var fireInterval: float = 1.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Spawn"):
        timerComponent.Run("Spawn", 25.0)

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !sprite.pause:
                if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
                    timerComponent.Run("Spawn", 25.0)
                    return
                var zombie = CreateCharacter("ZombieImpDiggerSpike", global_position, gridPos, groundHeight)
                zombie.Rise(2.5)
                if !instance.hypnoses:
                    zombie.Hypnoses()
                zombie.digOver = true
                zombie.state.send_event("ToDrill")
                zombie.instance.ArmorDelete("Pick")
                zombie.isRise = false
                zombie.instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
                zombie.instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
                Carry(zombie)
                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, zombie)
                        MultiPlayerManager.SendSpawnCharacterAt("ZombieImpDiggerSpike", gridPos.x, gridPos.y, _sync_id, instance.hitpointScale, transformPoint.scale.x, !instance.hypnoses, 2.5, true, global_position.x, global_position.y, false, groundHeight)
            timerComponent.Run("Spawn", 25.0)

func ComponentAttack() -> void :
    AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
    attackComponent.AttackAllFlag(attack, TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY)

func HitBoxEntered(area: Area2D) -> void :
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if nearDie || die:
        return
    var character = area.get_parent()
    Carry(character)

func Carry(character: TowerDefenseZombie) -> void :
    if character is TowerDefenseZombie:
        if character.isRise:
            return
        if character.hasSpikeball:
            return
        if character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE == 0:
            return
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            return
        if character.camp != camp:
            return
        if !character.targetRegistrationComponent.canCarry:
            return
        var spikeBall = CreateCharacter("ItemSpikeball", global_position, gridPos, groundHeight)
        if !instance.hypnoses:
            spikeBall.Hypnoses()
        spikeBall.targetZombie = character
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, spikeBall)
                MultiPlayerManager.SendSpawnCharacterAt("ItemSpikeball", gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, instance.hypnoses, 0.0, true, global_position.x, global_position.y, false, groundHeight, "Max")

func ExportVariantSave() -> Dictionary:
    return {"attack": attack, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    attack = data.get("attack", 20.0)
    fireInterval = data.get("fireInterval", 1.0)
