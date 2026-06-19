@tool
extends TowerDefenseZombie

const RIVIVE = preload("uid://dbgw1lmiiyypp")

var speed: float = 10.0
var isRevive: bool = false
var isReviveOver: bool = false
var isBlow: bool = false

var spawnTimer: float = 15.0

var invincible: bool = false
var invincibleTimer: float = 8.0

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if invincible:
        if invincibleTimer > 0.0 && global_position.x > TowerDefenseManager.GetMapCellPos(Vector2(4, 0)).x:
            invincibleTimer -= delta
        else:
            sprite.SetFliters(["wing2_1", "wing2_2"], false)
            instance.unUseBuffFlags = TowerDefenseEnum.CHARACTER_BUFF_FLAGS.BUTTER | TowerDefenseEnum.CHARACTER_BUFF_FLAGS.FROZEN
            instance.invincible = false
            invincible = false

func ShootingAttackEntered():
    sprite.SetAnimation("Shooting", false, 0.2)

@warning_ignore("unused_parameter")
func ShootingAttackProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func ShootingAttackExited() -> void :
    pass

func ReviveAttackEntered():
    sprite.SetAnimation("Revive", false, 0.2)
    sprite.SetFliters(["wing2_1", "wing2_2"], true)
    instance.unUseBuffFlags = TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ALL
    instance.invincible = true
    invincible = true
    invincibleTimer = 8.0

@warning_ignore("unused_parameter")
func ReviveAttackProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func ReviveAttackExited() -> void :
    pass

func Walk() -> void :
    if isRevive && !isReviveOver:
        isReviveOver = true
        state.send_event("ToRevive")
    else:
        super.Walk()

func WalkProcessing(delta: float) -> void :
    super.WalkProcessing(delta)
    sprite.timeScale = timeScale
    if !sprite.pause:
        global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)
    if spawnTimer > 0.0:
        spawnTimer -= delta
    else:
        var deathList: Array[Dictionary] = TowerDefenseManager.deathList.duplicate(true)
        deathList = deathList.filter( func(characterData):
            return characterData.has("Camp") && camp == characterData["Camp"]
        )
        if deathList.size() > 0:
            spawnTimer = 15.0
            state.send_event("ToShooting")

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func Blow() -> void :
    if instance.invincible:
        BlowBack(1.0, 1.0)
    isBlow = true
    HitBoxDestroy()
    var tween = create_tween()
    tween.tween_property(self, ^"global_position:x", global_position.x + TowerDefenseManager.GetMapGridSize().y * TowerDefenseManager.GetMapGridNum().y * 2.0, 1.0)
    await tween.finished
    Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "speed": speed, 
        "isRevive": isRevive, 
        "isReviveOver": isReviveOver, 
        "isBlow": isBlow, 
        "spawnTimer": spawnTimer, 
        "invincible": invincible, 
        "invincibleTimer": invincibleTimer, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    speed = data.get("speed", 10.0)
    isRevive = data.get("isRevive", false)
    isReviveOver = data.get("isReviveOver", false)
    isBlow = data.get("isBlow", false)
    spawnTimer = data.get("spawnTimer", 15.0)
    invincible = data.get("invincible", false)
    invincibleTimer = data.get("invincibleTimer", 8.0)

func DestroySet() -> void :
    if isRevive:
        return
    if isBlow:
        CreateSelf(Vector2(groundRight, global_position.y))
    else:
        CreateSelf(global_position)
    await get_tree().physics_frame

func CreateSelf(pos: Vector2) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var zombie = packet.Create(pos, gridPos, groundHeight)
    zombie.isRevive = true
    characterNode.add_child(zombie)
    if instance.hypnoses:
        zombie.Hypnoses.call_deferred()
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    ( func():
        if is_instance_valid(zombie):
            if is_instance_valid(zombie.instance):
                zombie.instance.hitpointScale = _hitpointScale
            if is_instance_valid(zombie.transformPoint):
                zombie.transformPoint.scale = _scale).call_deferred()
    zombie.invisible = invisible
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt(packet.saveKey, gridPos.x, gridPos.y, _sync_id, _hitpointScale, _scale.x, instance.hypnoses, 0.0, true, pos.x, pos.y, true, groundHeight)
    await get_tree().physics_frame
    zombie.Walk()

func CreateDeathCharacter() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var deathList: Array[Dictionary] = []
    for _characterData in TowerDefenseManager.deathList:
        if _characterData.has("Camp") && camp == _characterData["Camp"]:
            deathList.append(_characterData)
    if deathList.size() <= 0:
        return
    var characterData = deathList.pop_back()
    TowerDefenseManager.deathList.erase(characterData)

    var effect = TowerDefenseManager.CreateEffectSpriteOnce(RIVIVE, characterData["GridPos"])
    effect.global_position = characterData["Pos"]
    characterNode.add_child(effect)
    var _packet: TowerDefensePacketConfig = characterData["Packet"]
    var character = _packet.Create(characterData["Pos"], characterData["GridPos"], 0.0)
    character.invisible = invisible
    characterNode.add_child(character)
    if is_instance_valid(character.transformPoint):
        character.transformPoint.scale = characterData["Scale"] * Vector2.ONE
    if is_instance_valid(character.instance):
        character.instance.hitpointScale = characterData["HitpointScale"]
    if instance.hypnoses:
        character.Hypnoses()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, character)
            MultiPlayerManager.SendSpawnCharacterAt(_packet.saveKey, characterData["GridPos"].x, characterData["GridPos"].y, _sync_id, characterData["HitpointScale"], characterData["Scale"], instance.hypnoses, 0.0, true, characterData["Pos"].x, characterData["Pos"].y, true)

    await get_tree().physics_frame
    character.Walk()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "shooting":
            CreateDeathCharacter()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Revive":
            Walk()
        "Shooting":
            Walk()
