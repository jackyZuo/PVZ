@tool
extends TowerDefenseGravestone

const SURROUND_OFFSETS: Array[Vector2i] = [
    Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), 
    Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), 
    Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), 
]

const HEAL_PERCENTAGE: float = 0.3

var entryAnimationComponent: EntryAnimationComponent

var over: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if is_instance_valid(componentManager):
        entryAnimationComponent = componentManager.GetComponentFromType("EntryAnimationComponent")
        if is_instance_valid(entryAnimationComponent):
            if !(Global.isEditor && SceneManager.currentScene == "LevelEditorStage"):
                if !TowerDefenseManager.currentControl.hasProgress:
                    entryAnimationComponent.PlayFallBounce(900.0, randf_range(0.25, 1.0), 0.25)

func AttackDeal(attacker: TowerDefenseCharacter, attackType: String, num: float) -> void :
    super.AttackDeal(attacker, attackType, num)
    if attacker is TowerDefenseZombie:
        if attacker.instance.hitpoints >= attacker.instance.hitpointsSave:
            return
        attacker.Health(num)
        if attacker.instance.hitpoints > attacker.instance.hitpointsSave:
            attacker.instance.hitpoints = attacker.instance.hitpointsSave
        if is_instance_valid(attacker.showHealthComponent):
            attacker.showHealthComponent.MarkDirty()

func DestroySet() -> void :
    if over:
        return
    over = true
    for offset: Vector2i in SURROUND_OFFSETS:
        @warning_ignore("shadowed_variable_base_class")
        var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos + offset)
        if !is_instance_valid(cell):
            continue
        for character: TowerDefenseCharacter in cell.GetCharacterList():
            if !is_instance_valid(character):
                continue
            if character is not TowerDefensePlant:
                continue
            if character is TowerDefensePlantBowlingBase:
                continue
            if character.die || character.nearDie:
                continue
            if character.instance.hitpoints >= character.instance.hitpointsSave:
                continue
            var healNum: float = character.instance.hitpointsSave * HEAL_PERCENTAGE
            character.Health(healNum)
            if character.instance.hitpoints > character.instance.hitpointsSave:
                character.instance.hitpoints = character.instance.hitpointsSave
    await get_tree().physics_frame

func ExportVariantSave() -> Dictionary:
    return {
        "over": over
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
