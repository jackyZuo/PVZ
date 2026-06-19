@tool
extends TowerDefensePlant

@export var allEventList: Array[TowerDefenseCharacterEventBase] = []

var carrayCharacter1: TowerDefenseCharacter
var carrayCharacter2: TowerDefenseCharacter

var hitCharacterList: Array[TowerDefenseCharacter] = []

var run: bool = false

var speed: float = 200.0

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if !inGame:
        sprite.back.z_index = 0

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if !run:
        if CheckCanRun():
            Run()
    else:
        global_position.x += speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x
        if is_instance_valid(carrayCharacter1):
            carrayCharacter1.global_position.x = global_position.x
        if is_instance_valid(carrayCharacter2):
            carrayCharacter2.global_position.x = global_position.x + 90
        if global_position.x > TowerDefenseManager.GetMapGroundRight() + 200:
            queue_free()
            if is_instance_valid(carrayCharacter1):
                carrayCharacter1.queue_free()
            if is_instance_valid(carrayCharacter2):
                carrayCharacter2.queue_free()

    if Engine.get_physics_frames() % 2 == 0:
        TowerDefenseExplode.CreateExplode(global_position + Vector2(46, 0), Vector2(0.75, 0.25), allEventList, [], TowerDefenseEnum.CHARACTER_CAMP.ALL, -1)

func Run() -> void :
    run = true
    destroy.emit(self)
    if is_instance_valid(carrayCharacter1):
        carrayCharacter1.Destroy(false)
    if is_instance_valid(carrayCharacter2):
        carrayCharacter2.Destroy(false)

func CheckCanRun() -> bool:
    if CheckIceCap():
        return true
    if CheckSameCharacter():
        return true
    return false

func CheckIceCap() -> bool:
    var iceCap = TowerDefenseManager.GetMapIceCapList()[gridPos.y]
    if is_instance_valid(iceCap):
        if TowerDefenseManager.GetMapGridPos(iceCap.iceCapSprite.global_position).x <= gridPos.x + 1:
            return true
    return false

func CheckSameCharacter() -> bool:
    var extendCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos + Vector2i(1, 0))
    var characterCheckList: Array[TowerDefenseCharacter] = []
    for chacrterCheck in cell.GetCharacterList():
        if !(chacrterCheck is TowerDefensePlant):
            continue
        if chacrterCheck.config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.POT || chacrterCheck.config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LILYPAD:
            continue
        if chacrterCheck == self:
            continue
        if chacrterCheck.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR):
            continue
        characterCheckList.append(chacrterCheck)
    if is_instance_valid(extendCell):
        for chacrterCheck in extendCell.GetCharacterList():
            if !(chacrterCheck is TowerDefensePlant):
                continue
            if chacrterCheck.config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.POT || chacrterCheck.config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LILYPAD:
                continue
            if chacrterCheck == self:
                continue
            if chacrterCheck.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR):
                continue
            characterCheckList.append(chacrterCheck)
    for i in range(characterCheckList.size()):
        for j in range(i + 1, characterCheckList.size()):
            if characterCheckList[i].config.name == characterCheckList[j].config.name:
                carrayCharacter1 = characterCheckList[i]
                carrayCharacter2 = characterCheckList[j]
                return true
    return false


func CheckAttack(area: Area2D) -> void :
    if !run:
        return
    var character = area.get_parent()
    if character is TowerDefenseCharacter:
        if hitCharacterList.has(character):
            return
        if !CanCollision(character.instance.maskFlags):
            return
        if !CanTarget(character):
            return
        if !character.instance.canBeCollection:
            return
        var num: float = 1800
        if is_instance_valid(carrayCharacter1):
            num += carrayCharacter1.GetCurrentHitPoint()
        if is_instance_valid(carrayCharacter2):
            num += carrayCharacter2.GetCurrentHitPoint()
        character.Hurt(num)
        hitCharacterList.append(character)

func ExportVariantSave() -> Dictionary:
    return {
        "run": run, 
        "speed": speed, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    run = data.get("run", false)
    speed = data.get("speed", 200.0)
