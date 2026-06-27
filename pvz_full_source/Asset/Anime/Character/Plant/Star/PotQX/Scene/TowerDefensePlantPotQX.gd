@tool
extends TowerDefensePlant

@onready var timerComponent: TimerComponent = %TimerComponent

var createCharacterList: Array[TowerDefenseCharacter]

var open: bool = false

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if !inGame:
        return
    if !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !open:
        state.send_event("ToOpen")
        open = true

func OpenEntered() -> void :
    sprite.SetAnimation("Open", false)

@warning_ignore("unused_parameter")
func OpenProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func OpenExited() -> void :
    pass

func CloseEntered() -> void :
    sprite.SetAnimation("Close", false)

@warning_ignore("unused_parameter")
func CloseProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func CloseExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Open":
            CreateHologramCharacter()
            Idle()
            timerComponent.Run("Close", 30.0)
        "Close":
            ClearHologramCharacter()
            Destroy()

func CreateHologramCharacter() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetList: Array[TowerDefensePacketConfig] = []
    for charcter: TowerDefenseCharacter in cell.GetCharacterListSave(true):
        if charcter == self:
            continue
        if !charcter.config.canCopy:
            continue
        if charcter.camp != camp:
            continue
        if charcter.config.plantGridOverrideType != TowerDefenseEnum.PLANTGRIDTYPE.NOONE:
            continue
        packetList.append(charcter.packet)

    for y in range(1, TowerDefenseManager.GetMapGridNum().y + 1):
        if y == gridPos.y:
            continue
        var _gridPos: Vector2i = Vector2i(gridPos.x, y)
        var cellGet: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(_gridPos)
        for packetConfig: TowerDefensePacketConfig in packetList:
            if cellGet.CanPacketPlant(packetConfig):
                var character: TowerDefenseCharacter = packetConfig.Plant(_gridPos)
                if !is_instance_valid(character):
                    continue
                character.SetSpriteGroupShaderParameter("hologram", true)
                character.instance.hologram = true
                character.instance.canBeCollection = false
                if instance.hypnoses:
                    character.Hypnoses()
                createCharacterList.append(character)
                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, character)
                        MultiPlayerManager.SendSpawnCharacterAt(packetConfig.saveKey, _gridPos.x, _gridPos.y, _sync_id)

func ClearHologramCharacter() -> void :
    for character: TowerDefenseCharacter in createCharacterList:
        if is_instance_valid(character):
            character.destroy.emit(character)
            TowerDefenseManager.CharacterUnregister(character)
            character.remove_from_group("Character")
            character.queue_free()

func Timeout(timerName: String) -> void :
    match timerName:
        "Close":
            state.send_event("ToClose")

func DestroySet() -> void :
    super.DestroySet()
    ClearHologramCharacter()
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantPot")
    var pot: TowerDefenseCharacter = packetConfig.Plant(gridPos)
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control) and is_instance_valid(pot):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, pot)
            MultiPlayerManager.SendSpawnCharacterAt("PlantPot", gridPos.x, gridPos.y, _sync_id)

func ExportVariantSave() -> Dictionary:
    return {
        "open": open, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    open = data.get("open", false)
