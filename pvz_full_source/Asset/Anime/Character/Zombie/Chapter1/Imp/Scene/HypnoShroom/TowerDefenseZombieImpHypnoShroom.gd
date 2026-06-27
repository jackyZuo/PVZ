@tool
extends TowerDefenseZombieImpBase

var over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliter("Zombie_duckytube", true)
    if TowerDefenseManager.IsIZMMode():
        instance.hitpointScale *= 140.0 / 270.0
    if !TowerDefenseManager.GetMapIsNight():
        walkSpeedScale *= 0.5
    else:
        walkSpeedScale *= 1.0

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
    if sprite.clip != inSwimAnimeClip:
        if global_position.x > groundRight:
            sprite.timeScale = timeScale * walkSpeedScale * 2.0
        else:
            sprite.timeScale = timeScale * walkSpeedScale
    else:
        sprite.timeScale = timeScale * inSwimAnimeClipScale
    if die || nearDie:
        return
    if instance.sleep:
        return
    if over:
        return
    if !sprite.pause && attackComponent.CanAttack():
        var characterList = attackComponent.GetTargetList()
        characterList.sort_custom( func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
            return abs(a.global_position.x - global_position.x) < abs(b.global_position.x - global_position.x)
        )
        for character: TowerDefenseCharacter in characterList:
            if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES:
                if attackComponent.CanAttack():
                    Attack()
                return
            sprite.head.visible = false
            character.Hypnoses()
            over = true
            Die()
            return

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func InWater() -> void :
    super.InWater()
    sprite.SetFliter("Zombie_whitewater", true)

func OutWater() -> void :
    super.OutWater()
    sprite.SetFliter("Zombie_whitewater", false)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantHypnoShroom")
    if cell.CanPacketPlant(packetConfig):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos)
        character.WakeUp()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt("PlantHypnoShroom", gridPos.x, gridPos.y, _sync_id)
    Destroy()
