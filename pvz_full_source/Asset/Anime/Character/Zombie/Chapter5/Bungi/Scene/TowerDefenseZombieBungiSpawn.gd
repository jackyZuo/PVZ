@tool
extends TowerDefenseZombie

@export var characterName: String
@export var override: TowerDefenseCharacterOverride
var canBlock: bool = true

var dropTween: Tween

var character: TowerDefenseCharacter

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    targetRegistrationComponent.canCarry = false
    add_to_group("Bungi", true)
    z = 600.0
    isGround = false

    await get_tree().physics_frame
    shadowSprite.visible = !invisible
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Walk()
        return
    if characterName != "":
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(characterName)
        if is_instance_valid(packetConfig):
            character = packetConfig.Create(global_position, gridPos, 0.0)
            character.z = 600
            character.isGround = false
            add_child(character)
            if instance.hypnoses:
                character.scale.x = - character.scale.x
            character.instance.canBeCollection = false
            character.shadowSprite.visible = false
            character.PreSpawn()
            if character is TowerDefenseZombie:
                if is_instance_valid(character.attackComponent):
                    character.attackComponent.alive = false
                character.instance.collisionFlags = 0
                character.instance.maskFlags = 0
                if character.inWater:
                    if is_instance_valid(character.waterInteractionComponent):
                        if is_instance_valid(character.waterInteractionComponent.activeTween):
                            character.waterInteractionComponent.activeTween.kill()
                        character.waterInteractionComponent.isInWater = false
                    character.SetSpriteGroupShaderParameter("discardDownPos", 10000.0)
                    if is_instance_valid(character.waterLineSprite):
                        character.waterLineSprite.visible = false
                    if is_instance_valid(character.duckytobeSprite):
                        character.duckytobeSprite.visible = false
            if is_instance_valid(override):
                override.ExecuteCharacter(character)
            character.global_position = global_position
            if character is TowerDefenseZombie:
                TowerDefenseBattleFeatureWave.instance.AddSpawnCharacter(character)
    Walk()

func HitpointsNearDie() -> void :
    super.HitpointsNearDie()
    Destroy()

func HitpointsEmpty() -> void :
    super.HitpointsEmpty()
    Destroy()

func Walk() -> void :
    state.send_event("ToDrop")

func DropEntered() -> void :
    AudioManager.AudioPlay("BungeeScream", AudioManagerEnum.TYPE.SFX)
    z = 600.0
    isGround = false
    if is_instance_valid(character):
        character.z = 600
        character.isGround = false
    dropTween = create_tween()
    dropTween.set_parallel(true)
    dropTween.set_ease(Tween.EASE_OUT)
    dropTween.set_trans(Tween.TRANS_CUBIC)
    var height = 0
    if is_instance_valid(cell):
        height = cell.GetGroundHeight()
    dropTween.tween_property(self, ^"z", height, 0.75)
    dropTween.tween_property(character, ^"z", height, 0.75)

    sprite.SetAnimation("Drop", true, 0.2)
    await dropTween.finished
    isGround = true
    PutCharacter()
    state.send_event("ToRise")

@warning_ignore("unused_parameter")
func DropProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func DropExited() -> void :
    pass

func RiseEntered() -> void :
    sprite.SetAnimation("Rise", true, 0.2)
    var time: float = 1.5
    if !canBlock:
        time = 0.75
    var tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(self, ^"z", 600, time)
    if !canBlock:
        tween.tween_property(character, ^"z", 600, time)
    await tween.finished
    Destroy()

@warning_ignore("unused_parameter")
func RiseProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func RiseExited() -> void :
    pass

func CanBlock() -> bool:
    return canBlock && z <= 50

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    if is_instance_valid(dropTween):
        dropTween.kill()
    canBlock = false
    instance.invincible = true
    state.send_event("ToRise")

func PutCharacter() -> void :
    if !is_instance_valid(character):
        return
    character.gridPos = gridPos
    character.reparent(characterNode)
    character.isGround = true
    if is_instance_valid(character.cell):
        character.groundHeight = character.cell.GetGroundHeight()
        character.z = character.groundHeight
    if instance.hypnoses:
        character.scale.x = abs(character.scale.x)
        character.Hypnoses()
    if is_instance_valid(cell):
        if !cell.IsWater():
            character.shadowSprite.visible = !character.invisible
    character.instance.canBeCollection = true
    if character is TowerDefenseZombie:
        if is_instance_valid(character.attackComponent):
            character.attackComponent.alive = true
        character.instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
        character.instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
    character.global_position = TowerDefenseManager.GetMapCellPlantPos(gridPos)
    character.shadowSprite.scale = character.shadowComponent.saveShadowScale
    character.shadowComponent.saveShadowPosition = character.global_position + Vector2(12, 36)
    character.shadowSprite.global_position = character.global_position + Vector2(12, 36)
    if is_instance_valid(cell) && cell.IsWater() && character is TowerDefenseZombie && character.inWater:
        if is_instance_valid(character.waterInteractionComponent):
            character.waterInteractionComponent.InWaterDiscardSet()
        if is_instance_valid(character.waterLineSprite):
            character.waterLineSprite.visible = true
        if is_instance_valid(character.duckytobeSprite):
            character.duckytobeSprite.visible = true
    if is_instance_valid(cell):
        if character is TowerDefensePlant:
            cell.CharacterPlant(character.packet, character)
    if TowerDefenseManager.IsGameRunning():
        if character is TowerDefenseZombie:
            character.Walk()
