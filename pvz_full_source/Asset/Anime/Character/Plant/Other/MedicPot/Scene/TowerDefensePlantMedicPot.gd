@tool
extends TowerDefensePlant

@onready var timerComponent: TimerComponent = %TimerComponent

func _ready() -> void :
    super._ready()

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
        timerComponent.Run("Spawn", 1.0)

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !sprite.pause && !instance.sleep:
                if is_instance_valid(cell):
                    var healed: Dictionary = {}
                    for character: TowerDefenseCharacter in cell.GetCharacterList():
                        if character.die || character.nearDie:
                            continue
                        if character is TowerDefenseCrater:
                            continue
                        if character is TowerDefenseItem:
                            continue
                        if character is TowerDefenseGravestone:
                            continue
                        if character is TowerDefensePlantBowlingBase:
                            continue
                        if CheckDifferentCamp(character.camp):
                            continue
                        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                            continue
                        if character.instance.hitpoints >= character.instance.hitpointsSave:
                            continue
                        character.Health(0.01 * character.instance.hitpointsSave)
                        if character.instance.hitpoints >= character.instance.hitpointsSave:
                            character.instance.hitpoints = character.instance.hitpointsSave
                        healed[character] = true
                    for character: TowerDefenseCharacter in cell.GetCharacterList():
                        if healed.has(character):
                            continue
                        if character.instance.hitpoints >= character.instance.hitpointsSave:
                            continue
                        var plantConfig: TowerDefensePlantConfig = character.config as TowerDefensePlantConfig
                        if plantConfig == null || plantConfig.extendGrid.is_empty():
                            continue
                        for offset: Vector2i in plantConfig.extendGrid:
                            var extendCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(character.gridPos + offset)
                            if extendCell == cell:
                                character.Health(0.01 * character.instance.hitpointsSave)
                                if character.instance.hitpoints >= character.instance.hitpointsSave:
                                    character.instance.hitpoints = character.instance.hitpointsSave
                                healed[character] = true
                                break
            timerComponent.Run("Spawn", 1.0)
