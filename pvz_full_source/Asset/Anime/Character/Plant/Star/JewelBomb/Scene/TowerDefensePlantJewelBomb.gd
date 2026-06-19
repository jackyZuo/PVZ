@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var collisionShape: CollisionShape2D = %CollisionShape

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75


func Explode() -> void :
    var characterDictionary: Dictionary = {}
    var charcterList: Array = attackComponent.GetCharcterList()
    for character: TowerDefenseCharacter in charcterList:
        if character is TowerDefenseZombie:
            if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                continue

        var characterName: String = character.config.name
        if !characterDictionary.has(characterName):
            characterDictionary[characterName] = {
                "Num": 0, 
                "Type": "Plant" if character is TowerDefensePlant else "Zombie", 
                "CharacterList": []
            }
        characterDictionary[characterName]["Num"] += 1
        characterDictionary[characterName]["CharacterList"].append(character)

    for characterData in characterDictionary.values():
        if characterData["Num"] < 3:
            continue
        match characterData["Type"]:
            "Plant":
                for character: TowerDefenseCharacter in characterData["CharacterList"]:
                    character.SunCreate(character.global_position, int(character.cost))
                    character.Destroy()
            "Zombie":
                for character: TowerDefenseCharacter in characterData["CharacterList"]:
                    character.SunCreate(character.global_position, 25)
                    character.Destroy()
