@tool
extends TowerDefensePlant

@export var allEventList: Array[TowerDefenseCharacterEventBase] = []

var carrayCharacter1: TowerDefenseCharacter
var carrayCharacter2: TowerDefenseCharacter

var hitCharacterList: Array[TowerDefenseCharacter] = []

var run: bool = false

var speed: float = 200.0

var _pending_carrayCharacter1_name: String = ""
var _pending_carrayCharacter2_name: String = ""
var _pending_hitCharacterList_names: Array = []

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if !inGame:
        sprite.back.z_index = 0

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if _pending_carrayCharacter1_name != "":
        var _characterNode = TowerDefenseManager.GetCharacterNode()
        if is_instance_valid(_characterNode):
            var node = _characterNode.get_node_or_null(_pending_carrayCharacter1_name)
            if is_instance_valid(node):
                carrayCharacter1 = node
        _pending_carrayCharacter1_name = ""
    if _pending_carrayCharacter2_name != "":
        var _characterNode = TowerDefenseManager.GetCharacterNode()
        if is_instance_valid(_characterNode):
            var node = _characterNode.get_node_or_null(_pending_carrayCharacter2_name)
            if is_instance_valid(node):
                carrayCharacter2 = node
        _pending_carrayCharacter2_name = ""
    if _pending_hitCharacterList_names.size() > 0:
        var _characterNode = TowerDefenseManager.GetCharacterNode()
        if is_instance_valid(_characterNode):
            for hitName in _pending_hitCharacterList_names:
                var node = _characterNode.get_node_or_null(hitName)
                if is_instance_valid(node):
                    hitCharacterList.append(node)
        _pending_hitCharacterList_names = []

func IdleEntered() -> void :
    super.IdleEntered()
    if !run:
        puzzleShaderComponent.IdleEntered()

func IdleExited() -> void :
    super.IdleExited()
    if !run:
        puzzleShaderComponent.IdleExited()

func SleepProcessing(delta: float) -> void :
    super.SleepProcessing(delta)
    if !run:
        if CheckCanRun():
            Run()
    else:
        RunMovement(delta)

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if !run:
        if CheckCanRun():
            Run()
    else:
        RunMovement(delta)

func RunMovement(delta: float) -> void :
    if sprite.timeScale == 0:
        sprite.timeScale = timeScaleSave
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
    if TowerDefenseManager.IsIZMMode():
        timeScaleInit = timeScaleSave
        timeScale = timeScaleSave
        sprite.timeScale = timeScaleSave
        Idle()
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
    var mainCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
    var extendCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos + Vector2i(1, 0))
    var characterCheckList: Array[TowerDefenseCharacter] = []
    for chacraterCheck in mainCell.GetCharacterList():
        if !(chacraterCheck is TowerDefensePlant):
            continue
        if chacraterCheck.instance.isDestroy:
            continue
        if chacraterCheck.config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.POT || chacraterCheck.config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LILYPAD:
            continue
        if chacraterCheck == self:
            continue
        if chacraterCheck.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR):
            continue
        characterCheckList.append(chacraterCheck)
    if is_instance_valid(extendCell):
        for chacraterCheck in extendCell.GetCharacterList():
            if !(chacraterCheck is TowerDefensePlant):
                continue
            if chacraterCheck.instance.isDestroy:
                continue
            if chacraterCheck.config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.POT || chacraterCheck.config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LILYPAD:
                continue
            if chacraterCheck == self:
                continue
            if chacraterCheck.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR):
                continue
            characterCheckList.append(chacraterCheck)
    for i in range(characterCheckList.size()):
        for j in range(i + 1, characterCheckList.size()):
            if characterCheckList[i] == characterCheckList[j]:
                continue
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
    var data: Dictionary = {
        "run": run, 
        "speed": speed, 
    }
    if is_instance_valid(carrayCharacter1):
        data["carrayCharacter1NodeName"] = carrayCharacter1.name
    if is_instance_valid(carrayCharacter2):
        data["carrayCharacter2NodeName"] = carrayCharacter2.name
    if hitCharacterList.size() > 0:
        var hitNames: Array = []
        for hitChar in hitCharacterList:
            if is_instance_valid(hitChar):
                hitNames.append(hitChar.name)
        data["hitCharacterNodeNames"] = hitNames
    return data

func ImportVariantSave(data: Dictionary) -> void :
    run = data.get("run", false)
    speed = data.get("speed", 200.0)
    if data.has("carrayCharacter1NodeName"):
        _pending_carrayCharacter1_name = data["carrayCharacter1NodeName"]
    if data.has("carrayCharacter2NodeName"):
        _pending_carrayCharacter2_name = data["carrayCharacter2NodeName"]
    if data.has("hitCharacterNodeNames"):
        _pending_hitCharacterList_names = data["hitCharacterNodeNames"]
