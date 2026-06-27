@tool
extends TowerDefenseZombie

var halfHp: bool = false
var isAttack: bool = false

var over = false
var spawn: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)

    sprite.head.animeCompleted.connect(HeadAnimeCompleted)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !over:
        if !TowerDefenseManager.IsGameRunning():
            return
        if !inGame:
            return
        if global_position.x < TowerDefenseManager.GetMapGroundRight() - 50:
            var flag: bool = false
            for character: TowerDefenseCharacter in TowerDefenseManager.GetZombie():
                if !character.config.canImitate:
                    continue
                if instance.hypnoses != character.instance.hypnoses:
                    continue
                flag = true
                break
            if flag:
                over = true
                Idle()
                if die || nearDie:
                    return
                sprite.head.SetAnimation("Explode", false)

func AttackEntered() -> void :
    super.AttackEntered()
    isAttack = true
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func AttackExited() -> void :
    super.AttackExited()
    isAttack = false
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper", "Zombie_outerarm_hand", "Zombie_outerarm_lower"], false)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":
            halfHp = true
            sprite.SetFliters(["Zombie_outerarm_upper"], true)
        "Head":
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))

func ArmorDamagePointReach(armorName: String, stage: int) -> void :
    super.ArmorDamagePointReach(armorName, stage)
    if isAttack && HasShield() && stage > 0:
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func HeadAnimeCompleted(clip: String) -> void :
    match clip:
        "Explode":
            if spawn:
                return
            spawn = true
            var characterList = TowerDefenseManager.GetZombie()
            var maxHp: float = -10000
            var maxHpCharacter: TowerDefenseCharacter = null
            for character: TowerDefenseCharacter in characterList:
                if !character.config.canImitate:
                    continue
                if instance.hypnoses != character.instance.hypnoses:
                    continue
                if character.instance.hitpoints > maxHp:
                    maxHpCharacter = character
                    maxHp = character.instance.hitpoints
            if !is_instance_valid(maxHpCharacter):
                Walk()
                sprite.head.SetAnimation("Idle", false)
                spawn = false
                over = false
                return
            if is_instance_valid(maxHpCharacter.packet):
                var zombie = maxHpCharacter.packet.Plant(gridPos, true)
                zombie.global_position = Vector2(global_position.x, TowerDefenseManager.GetMapCellPlantPos(gridPos).y)
                if instance.hypnoses:
                    zombie.Hypnoses()
                zombie.SetSpriteGroupShaderParameter("imitater", true)
                if is_instance_valid(TowerDefenseBattleFeatureWave.instance):
                    TowerDefenseBattleFeatureWave.instance.currentHpPointTotal += zombie.GetTotalHitPoint() / 3
                    TowerDefenseBattleFeatureWave.instance.currentHpPoint += zombie.GetTotalHitPoint() / 3
            Destroy.call_deferred()

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantLmitater")
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
                MultiPlayerManager.SendSpawnCharacterAt("PlantLmitater", gridPos.x, gridPos.y, _sync_id)
    Destroy()
