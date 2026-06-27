
class_name AttackComponent extends ComponentBase


signal attackReady()

signal attack()

signal attackDps(delta: float)

signal attackOver()


@onready var state: StateChart = %StateChart


@export_enum("Default", "Eat", "Smash", "Chomp") var attackType: String = "Eat"

@export var checkArea: Area2D

@export var checkIntreval: int = 5
@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var attackAnimeClipsArray: Array[String] = ["Attack"]

@export var attackAnimeClips: String = "Attack"

@export var attackEventName: String = "attack"

@export var attackAnimeTimeScale: float = 1.0

@export var attackIntervalBase: float = 1.5

@export var attackInterval: float = 1.5

@export var attackIntervalOffset: float = 0.1

@export var spliceIdleAnimeClips: String = ""

@export var spliceIdleAnimeTimeScale: float = 1.0

@export var eventList: Array[TowerDefenseCharacterEventBase]
@export_subgroup("Setting")

@export var useZombieAttackCheck: bool = true

@export var checkGrid: bool = true

@export var checkLine: bool = false

@export var checkTall: bool = false

@export var checkVase: bool = false

@export var checkBowling: bool = false

@export var checkGravestone: bool = true

@export var checkAll: bool = false

@export var fliterLadder: bool = false

@export var eatAudio: String = "Chomp"


var parent: TowerDefenseCharacter


var target: TowerDefenseCharacter


var timeScale: float = 1.0

var timer: float = 0.25

var attackDpsTimer: float = 0.0


var checkIntrevalNow: int = 5


var groundRight: float = 0.0


func GetName() -> String:
    return "AttackComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    groundRight = TowerDefenseManager.GetMapGroundRight() + TowerDefenseManager.GetMapGridSize().x
    checkArea.area_exited.connect(ExitCheck)
    eventList = eventList.duplicate_deep()
    if is_instance_valid(sprite):
        parent.componentChange.connect(ComponentChange)
        state.process_mode = Node.PROCESS_MODE_INHERIT
        sprite.animeCompleted.connect(AnimeCompleted)
        sprite.animeEvent.connect(AnimeEvent)


func _physics_process(delta: float) -> void :
    if !alive:
        return
    var runScale: float = parent.timeScale * timeScale
    if TowerDefenseManager.IsIZMMode():
        runScale = 1.0
    if timer > 0:
        timer -= delta * runScale


func Refresh() -> void :
    timer = attackInterval + randf_range( - attackIntervalOffset * 2.0, - attackIntervalOffset)



func CanAttack() -> bool:
    if !alive:
        return false
    if !is_instance_valid(checkArea):
        return false



    if checkTall:
        target = GetTargetTall()
        if is_instance_valid(target):
            return true





    if parent is TowerDefenseZombie:
        if is_instance_valid(target):
            var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(target.gridPos)
            if is_instance_valid(cell):
                if !fliterLadder:
                    if is_instance_valid(cell.characterLadder) && parent.config.physique < TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE && parent.scale.x > 0.0:
                        target = null
                        return false

        if parent.isGarlic || parent.isChangeLine:
            return false
    if is_instance_valid(target):
        if !target.instance.canBeCollection:
            target = null
            return false
        if !is_instance_valid(target.hitBox):
            target = null
            return false
        if !parent.CanCollision(target.instance.maskFlags):
            target = null
            return false


        if !parent.CanTarget(target):
            target = null
        if checkGrid:
            if parent is TowerDefenseZombie && target is TowerDefensePlant:
                var checkFlag: bool = true
                var checkCharacterConfig: TowerDefenseCharacterConfig = target.config
                if checkCharacterConfig is TowerDefensePlantConfig:
                    for offset in checkCharacterConfig.extendGrid:
                        if parent.gridPos.x == target.gridPos.x + offset.x:
                            checkFlag = false
                if checkFlag && parent.gridPos.x != target.gridPos.x:
                    target = null
                    return false
        if target is TowerDefensePlant && !(target is TowerDefensePlantBowlingBase):
            var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(target.gridPos)

            var _target = cell.GetTarget(parent.instance.collisionFlags, parent.camp, false)
            if is_instance_valid(_target):
                if parent.CanCollision(_target.instance.maskFlags):
                    target = _target







        return is_instance_valid(target)

    if checkIntrevalNow > 0:
        checkIntrevalNow -= 1
        return false
    checkIntrevalNow = checkIntreval
    timer = 0.0
    return CanAttackOnce()



func CanAttackOnce() -> bool:
    if !checkAll:
        GetTarget()
        if is_instance_valid(target):
            if parent is TowerDefenseZombie:
                var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(target.gridPos)
                if is_instance_valid(cell):
                    if !fliterLadder:
                        if is_instance_valid(cell.characterLadder) && parent.config.physique < TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE && parent.scale.x > 0.0:
                            target = null
                            return false
            if target is TowerDefensePlant && !(target is TowerDefensePlantBowlingBase):
                var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(target.gridPos)
                if is_instance_valid(cell):
                    var chacrater: TowerDefenseCharacter = cell.GetTarget(parent.instance.collisionFlags, parent.camp, false)
                    if is_instance_valid(chacrater):
                        if parent.CanCollision(chacrater.instance.maskFlags):
                            target = chacrater
        return is_instance_valid(target)
    else:
        var characterList = TowerDefenseManager.GetCharacterTargetFromArea(parent, checkArea, false, false)
        if checkGravestone:
            characterList = characterList.filter(
                func(checkCharacter):
                    if checkCharacter is TowerDefenseGravestone:
                        return checkCharacter.canAttack
                    return true
            )
            return characterList.size() > 0
        return TowerDefenseManager.GetCharacterHasTargetFromArea(parent, checkArea, false, false)



func GetTargetTall() -> TowerDefenseCharacter:
    var characterList = GetTargetList()
    if characterList.size() > 0:
        for checkCharacter: TowerDefenseCharacter in characterList:
            if checkCharacter.instance.height >= TowerDefenseEnum.CHARACTER_HEIGHT.TALL:
                return checkCharacter
    return null



func GetTarget() -> TowerDefenseCharacter:
    var characterList = GetTargetList()
    if characterList.size() > 0:
        var character: TowerDefenseCharacter = characterList[0]
        if character is TowerDefensePlant:
            if character is not TowerDefensePlantBowlingBase:
                var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(character.gridPos)
                if is_instance_valid(cell):
                    var _target: TowerDefenseCharacter = cell.GetTarget(parent.instance.collisionFlags, parent.camp, false)
                    if is_instance_valid(_target):
                        if parent.CanCollision(_target.instance.maskFlags):
                            character = _target
        target = character
        return character
    target = null
    return null



func GetTargetList() -> Array:
    if parent is TowerDefenseZombie:
        checkGravestone = true
    var characterList: Array = []
    var filterGravestone: bool = !checkGravestone || parent is TowerDefenseZombie

    if !checkTall:
        if is_instance_valid(checkArea):
            characterList = TowerDefenseManager.GetCharacterTargetFromArea(parent, checkArea, false, false, !checkVase)
        characterList = characterList.filter(
            func(checkCharacter: TowerDefenseCharacter):
                if !checkCharacter.instance.canBeCollection:
                    return false
                if checkCharacter.global_position.x > groundRight:
                    return false
                if checkGrid:
                    if parent is TowerDefenseZombie && checkCharacter is TowerDefensePlant:
                        var checkFlag: bool = true
                        var checkCharacterConfig: TowerDefenseCharacterConfig = checkCharacter.config
                        if checkCharacterConfig is TowerDefensePlantConfig:
                            for offset in checkCharacterConfig.extendGrid:
                                if parent.gridPos.x == checkCharacter.gridPos.x + offset.x:
                                    checkFlag = false
                        if checkFlag && parent.gridPos.x != checkCharacter.gridPos.x:
                            return false
                if !checkBowling:
                    if checkCharacter is TowerDefensePlantBowlingBase:
                        return false
                if filterGravestone:
                    if checkCharacter is TowerDefenseGravestone:
                        if checkCharacter.camp != TowerDefenseEnum.CHARACTER_CAMP.ALL:
                            return false
                if checkLine:
                    if checkCharacter.gridPos.y != parent.gridPos.y && !checkCharacter.targetRegistrationComponent.allLineCheck:
                        return false
                return true
        )
    else:
        var areas = TowerDefenseManager.GetOverlappingAreasCached(checkArea)
        for area: Area2D in areas:
            var checkCharacter = area.get_parent()
            if checkCharacter is TowerDefenseCharacter:
                if checkCharacter.die || checkCharacter.nearDie:
                    continue
                if !checkCharacter.instance.canBeCollection:
                    continue
                if checkCharacter.global_position.x > groundRight:
                    continue
                if !parent.CanTarget(checkCharacter):
                    continue
                if checkCharacter.instance.height >= TowerDefenseEnum.CHARACTER_HEIGHT.TALL:
                    if checkLine:
                        if checkCharacter.gridPos.y != parent.gridPos.y && !checkCharacter.targetRegistrationComponent.allLineCheck:
                            continue
                    if checkCharacter is TowerDefensePlant:
                        if is_instance_valid(checkCharacter.cell):
                            if is_instance_valid(checkCharacter.cell.characterLadder):
                                continue
                            for character in checkCharacter.cell.GetCharacterList():
                                if character is TowerDefensePlant:
                                    if !character.instance.canBeCollection:
                                        continue
                                    if !checkCharacter.instance.canBeCollection:
                                        continue
                                    if !parent.CanTarget(character):
                                        continue
                                    if !parent.CanCollision(character.instance.maskFlags):
                                        continue
                                    characterList.append(character)
                    characterList.append(checkCharacter)
                    continue
                if !parent.CanCollision(checkCharacter.instance.maskFlags):
                    continue
                if checkCharacter is TowerDefenseCrater:
                    continue
                if checkCharacter is TowerDefenseItem:
                    if !checkCharacter.canCheck:
                        if attackType != "Smash":
                            continue
                        elif !(checkCharacter is TowerDefenseVase):
                            continue
                        elif !checkVase:
                            continue
                if filterGravestone:
                    if checkCharacter is TowerDefenseGravestone:
                        if checkCharacter.camp != TowerDefenseEnum.CHARACTER_CAMP.ALL:
                            continue
                if !checkBowling:
                    if checkCharacter is TowerDefensePlantBowlingBase:
                        continue
                if checkGrid:
                    if parent is TowerDefenseZombie && checkCharacter is TowerDefensePlant:
                        var checkFlag: bool = true
                        var checkCharacterConfig: TowerDefenseCharacterConfig = checkCharacter.config
                        if checkCharacterConfig is TowerDefensePlantConfig:
                            for offset in checkCharacterConfig.extendGrid:
                                if parent.gridPos.x == checkCharacter.gridPos.x + offset.x:
                                    checkFlag = false
                        if checkFlag && parent.gridPos.x != checkCharacter.gridPos.x:
                            continue
                if checkLine:
                    if checkCharacter.gridPos.y != parent.gridPos.y && !checkCharacter.targetRegistrationComponent.allLineCheck:
                        continue
                characterList.append(checkCharacter)

    return characterList



func GetCharcterList() -> Array:
    if parent is TowerDefenseZombie:
        checkGravestone = true
    var characterList: Array = []
    var filterGravestone: bool = !checkGravestone || parent is TowerDefenseZombie

    var areas = TowerDefenseManager.GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.die || checkCharacter.nearDie:
                continue
            if !checkCharacter.instance.canBeCollection:
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if filterGravestone:
                if checkCharacter is TowerDefenseGravestone:
                    if checkCharacter.camp != TowerDefenseEnum.CHARACTER_CAMP.ALL:
                        continue
            if !checkBowling:
                if checkCharacter is TowerDefensePlantBowlingBase:
                    continue
            if checkGrid:
                if parent is TowerDefenseZombie && checkCharacter is TowerDefensePlant:
                    var checkFlag: bool = true
                    var checkCharacterConfig: TowerDefenseCharacterConfig = checkCharacter.config
                    if checkCharacterConfig is TowerDefensePlantConfig:
                        for offset in checkCharacterConfig.extendGrid:
                            if parent.gridPos.x == checkCharacter.gridPos.x + offset.x:
                                checkFlag = false
                    if checkFlag && parent.gridPos.x != checkCharacter.gridPos.x:
                        continue
            if checkLine:
                if checkCharacter.gridPos.y != parent.gridPos.y && !checkCharacter.targetRegistrationComponent.allLineCheck:
                    continue
            characterList.append(checkCharacter)

    return characterList





func AttackDps(delta: float, num: float) -> float:
    var character: TowerDefenseCharacter = target
    if !is_instance_valid(character):
        return num
    var hitNum: float = num * delta
    if parent.iceSpeedDown:
        hitNum /= 2.0

    character.AttackDeal(parent, attackType, hitNum)
    if is_instance_valid(character.cell):
        character.cell.AttackDeal(parent, attackType, hitNum)
    EventExecuteDps(character, delta)
    if TowerDefenseManager.GetMapIsVampire():
        parent.instance.hitpoints += hitNum
        if is_instance_valid(parent.showHealthComponent):
            parent.showHealthComponent.MarkDirty()
    var numGet: float = character.instance.Hurt(hitNum, false, Vector2.ZERO, false)
    if is_instance_valid(character.showHealthComponent):
        character.showHealthComponent.MarkDirty()
    if character is TowerDefensePlant:
        if numGet > 0 || character.instance.die:
            AudioManager.AudioPlay("Gulp", AudioManagerEnum.TYPE.SFX)
    if attackDpsTimer > 0.0:
        attackDpsTimer -= delta
    else:
        attackDpsTimer = 1.0
        character.Bright()
        AudioManager.AudioPlay(eatAudio, AudioManagerEnum.TYPE.SFX)
    return numGet





func HealthDps(delta: float, num: float) -> float:
    var character: TowerDefenseCharacter = target
    if !character:
        return num
    var hitNum: float = num * delta
    if parent.iceSpeedDown:
        hitNum /= 2.0
    return hitNum




func Attack(num: float) -> float:
    var character: TowerDefenseCharacter = target
    if !character:
        return num
    character.AttackDeal(parent, attackType, num)
    if is_instance_valid(character.cell):
        character.cell.AttackDeal(parent, attackType, num)
    EventExecute(character)
    return character.Hurt(num, true, Vector2.ZERO)



func AttackAll(num: float) -> void :
    var characterList = TowerDefenseManager.GetCharacterTargetFromArea(parent, checkArea)
    for character: TowerDefenseCharacter in characterList:
        if is_instance_valid(character):
            character.AttackDeal(parent, attackType, num)
            if is_instance_valid(character.cell):
                character.cell.AttackDeal(parent, attackType, num)
            character.Hurt(num, true, Vector2.ZERO)
            EventExecute(character)



func SmashAttackAll(num: float) -> void :
    var characterList = TowerDefenseManager.GetCharacterTargetFromArea(parent, checkArea)
    for character: TowerDefenseCharacter in characterList:
        if character:
            character.AttackDeal(parent, attackType, num)
            if is_instance_valid(character.cell):
                character.cell.AttackDeal(parent, attackType, num)
            character.SmashHurt(num, true, Vector2.ZERO)
            EventExecute(character)




func AttackAllFlag(num: float, flag: int) -> void :
    var characterList = TowerDefenseManager.GetCharacterTargetFromArea(parent, checkArea)
    for character: TowerDefenseCharacter in characterList:
        if character:
            character.AttackDeal(parent, attackType, num)
            if is_instance_valid(character.cell):
                character.cell.AttackDeal(parent, attackType, num)
            character.FlagHurt(num, flag, true, Vector2.ZERO)
            EventExecute(character)




func SmashAttack(num: float) -> float:
    var character: TowerDefenseCharacter = GetTarget()
    if !character:
        return num
    return character.SmashHurt(num, true, Vector2.ZERO)



func SmashAttackCell(num: float) -> void :
    if parent.die:
        return
    if parent.nearDie:
        return
    if !is_instance_valid(target):
        return
    if target is TowerDefenseZombie || target is TowerDefenseGravestone || target is TowerDefenseVase:
        target.SmashHurt(num, true, Vector2.ZERO)

    elif target is TowerDefensePlant:
        target = GetTarget()
        if is_instance_valid(target):
            var skipList: Array = []
            var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(target.gridPos)
            for cellCharacter: TowerDefenseCharacter in cell.characterList.duplicate():
                if !is_instance_valid(cellCharacter):
                    continue
                if cellCharacter is TowerDefenseGravestone:
                    continue
                if cellCharacter is TowerDefenseCrater:
                    continue
                if cellCharacter.CanTarget(parent) && cellCharacter.CanCollision(parent.instance.collisionFlags):
                    if cellCharacter.SmashHurt(num, true, Vector2.ZERO) == num:
                        skipList.append(cellCharacter)
                    cellCharacter.AttackDeal(parent, attackType, num)
            for checkSkipCharacter: TowerDefenseCharacter in skipList:
                checkSkipCharacter.SmashHurt(num, true, Vector2.ZERO)
                checkSkipCharacter.AttackDeal(parent, attackType, num)
    elif target is TowerDefenseItem && target.canCheck:
        target.SmashHurt(num, true, Vector2.ZERO)



func AttackEventExecute() -> void :
    var characterList = GetTargetList()
    for character: TowerDefenseCharacter in characterList:
        if is_instance_valid(character):
            EventExecute(character)



func EventExecute(character: TowerDefenseCharacter) -> void :
    for event: TowerDefenseCharacterEventBase in eventList:
        event.Execute(parent.global_position, character)




func EventExecuteDps(character: TowerDefenseCharacter, delta: float) -> void :
    for event: TowerDefenseCharacterEventBase in eventList:
        event.ExecuteDps(parent.global_position, character, delta)



func ExitCheck(area: Area2D) -> void :
    if area.get_parent() == target:
        target = null




func IdleEntered() -> void :
    target = null
    if !alive:
        return
    if is_instance_valid(sprite):
        if spliceIdleAnimeClips != "":
            sprite.SetAnimation(spliceIdleAnimeClips, true, 0.2)
    if parent.componentRunning:
        if parent is TowerDefensePlant:
            parent.Idle()


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if !alive:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if !parent.componentAlive:
        return
    if parent.componentRunning:
        return
    if parent.die || parent.nearDie:
        return
    if timer > 0:
        return
    if CanAttack():
        if parent is TowerDefensePlant:
            parent.Component()
        state.send_event("ToAttack")


func IdleExited() -> void :
    pass


func AttackEntered() -> void :
    Refresh()
    attackReady.emit()
    sprite.SetAnimation(attackAnimeClips, true, 0.2)


func AttackProcessing(delta: float) -> void :
    if !is_instance_valid(parent):
        return
    if !is_instance_valid(sprite):
        return
    if !alive:
        parent.Idle()
        state.send_event("ToIdle")
        return
    if !parent.componentAlive:
        state.send_event("ToIdle")
        return
    if parent.die || parent.nearDie:
        state.send_event("ToIdle")
        return
    sprite.timeScale = parent.timeScale * attackAnimeTimeScale * (attackIntervalBase + attackIntervalBase / 3) / (attackInterval + attackIntervalBase / 3)
    attackDps.emit(delta)


func AttackExited() -> void :
    pass




@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    if parent.die || parent.nearDie:
        return
    match command:
        attackEventName:
            attack.emit()



func AnimeCompleted(clip: String) -> void :
    if !alive:
        return
    if attackAnimeClipsArray.has(clip):
        attackOver.emit()
        state.send_event("ToIdle")


func ComponentChange() -> void :
    state.send_event("ToIdle")

func ExportComponentSave() -> Dictionary:
    var data: Dictionary = {
        "timer": timer, 
        "checkIntrevalNow": checkIntrevalNow, 
    }
    if is_instance_valid(target):
        data["target"] = target.name.validate_node_name()
    return data

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    timer = _data.get("timer", 0.0)
    checkIntrevalNow = _data.get("checkIntrevalNow", 0)
    var targetName: String = _data.get("target", "")
    if targetName != "" and _owner.charcterDicionary.has(targetName):
        target = _owner.charcterDicionary[targetName]

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {
        "timer": timer, 
        "checkIntrevalNow": checkIntrevalNow, 
    }
    return data

func SyncDeserialize(_data: Dictionary) -> void :
    timer = _data.get("timer", timer)
    checkIntrevalNow = _data.get("checkIntrevalNow", checkIntrevalNow)
