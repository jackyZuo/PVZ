@tool
extends TowerDefensePlant

@export var changeCost: TowerDefensePacketChangeCost

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    changeCost = changeCost.duplicate()

func PreSpawn() -> void :
    super.PreSpawn()
    if is_instance_valid(cell):
        var characterList: Array[TowerDefenseCharacter] = cell.GetCharacterList()
        characterList = characterList.filter( func(character: TowerDefenseCharacter):
            return character is TowerDefensePlant && character.config.name != config.name && character.camp == camp
        )
        if !characterList.is_empty():
            for character in characterList:
                if is_instance_valid(character):
                    character.WakeUp()
                    if !instance.hypnoses:
                        character.packet.ChangeCostAdd(changeCost)

func Explode() -> void :
    if is_instance_valid(cell):
        var characterList: Array[TowerDefenseCharacter] = cell.GetCharacterList()
        characterList = characterList.filter( func(character: TowerDefenseCharacter):
            return character is TowerDefensePlant && character.config.name != config.name && character.camp == camp
        )
        if !characterList.is_empty():
            for character in characterList:
                if is_instance_valid(character):
                    character.WakeUp()
                    if !instance.hypnoses && character.packet.ChangeCostAdd(changeCost):
                        pass
                    else:
                        if instance.hypnoses:
                            BrainSunCreate(global_position, 50)
                        else:
                            SunCreate(global_position, 50)
                else:
                    if instance.hypnoses:
                        BrainSunCreate(global_position, 50)
                    else:
                        SunCreate(global_position, 50)
