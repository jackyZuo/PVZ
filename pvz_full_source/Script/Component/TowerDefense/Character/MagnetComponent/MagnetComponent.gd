
class_name MagnetComponent extends ComponentBase


signal drawTarget(target: TowerDefenseCharacter)

signal breakDown(_armor: TowerDefenseArmorInstance)


@onready var state: StateChart = %StateChart


@export var posMarker: Marker2D

@export var breakDownTime: float = 15.0

@export var checkRange: Vector2 = Vector2(2.5, 2.5)

@export var checkAll: bool = false
@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var drawEventName: String = "action"

@export var shootBeginAnimeClips: String = "Begin"

@export var shootBeginAnimeTimeScale: float = 1.0

@export var shootAnimeClips: String = "Shooting"

@export var shootAnimeTimeScale: float = 1.0

@export var shootEndAnimeClips: String = "End"

@export var shootEndAnimeTimeScale: float = 1.0

@export var noActiveAnimeClips: String = "NonActiveIdle2"

@export var noActiveAnimeTimeScale: float = 1.0


var parent: TowerDefenseCharacter


var shape: RectangleShape2D = RectangleShape2D.new()

var params = PhysicsShapeQueryParameters2D.new()

var breakDownArmor: TowerDefenseArmorInstance

var breakDownTimer: float = 0.0

var magnet: TowerDefenseMagnet = null


var drawArmorCharacter: TowerDefenseCharacter

var drawArmor: TowerDefenseArmorInstance


var isArrive: bool = false


func GetName() -> String:
    return "MagnetComponent"


func _exit_tree() -> void :
    Destroy()


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return

    params.shape = shape
    params.collide_with_areas = true
    params.collision_mask = 1

    if is_instance_valid(sprite):
        state.process_mode = Node.PROCESS_MODE_INHERIT
        sprite.animeCompleted.connect(AnimeCompleted)
        sprite.animeEvent.connect(AnimeEvent)


func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return
    if breakDownArmor:
        if is_instance_valid(magnet):
            magnet.gridPos = parent.gridPos
            if !isArrive:
                if magnet.global_position.distance_to(posMarker.global_position) >= 0.01:
                    magnet.global_position = lerp(magnet.global_position, posMarker.global_position, 10.0 * delta)
                else:
                    isArrive = true
            else:
                magnet.global_position = posMarker.global_position
        ArmorBreakDown(delta)
        return



func CanArmorDraw() -> bool:
    if checkAll:
        var characterList = TowerDefenseManager.GetCampTarget(parent.camp)
        for character: TowerDefenseCharacter in characterList:
            if !character.instance.canBeCollection:
                continue
            if character is TowerDefenseCharacter:
                var armorList: Array[TowerDefenseArmorInstance] = []
                armorList.append_array(character.GetArmorHeadCover())
                armorList.append_array(character.GetArmorShield())
                armorList.append_array(character.GetArmorHelment())
                armorList.append_array(character.GetArmor())
                for armor: TowerDefenseArmorInstance in armorList:
                    if armor.IsMetallic():
                        drawArmorCharacter = character
                        drawArmor = armor
                        return true
    else:
        var pos: Vector2 = TowerDefenseManager.GetMapCellPosCenter(TowerDefenseManager.GetMapGridPos(parent.global_position))
        shape.size = TowerDefenseManager.GetMapGridSize() * 2.0 * checkRange
        params.transform = Transform2D(0, pos)
        await get_tree().physics_frame
        var arr = get_world_2d().direct_space_state.intersect_shape(params, 10000)
        for infor: Dictionary in arr:
            if infor["collider"] is Area2D:
                var area: Area2D = infor["collider"]
                var character = area.get_parent()
                if character is TowerDefenseCharacter:
                    if !character.instance.canBeCollection:
                        continue
                    if character.camp != parent.camp:
                        var gridDist: Vector2i = (character.gridPos - parent.gridPos).abs()
                        if float(gridDist.x) > checkRange.x || float(gridDist.y) > checkRange.y:
                            continue
                        var armorList: Array[TowerDefenseArmorInstance] = []
                        armorList.append_array(character.GetArmorHeadCover())
                        armorList.append_array(character.GetArmorShield())
                        armorList.append_array(character.GetArmorHelment())
                        armorList.append_array(character.GetArmor())
                        for armor: TowerDefenseArmorInstance in armorList:
                            if armor.IsMetallic():
                                drawArmorCharacter = character
                                drawArmor = armor
                                return true
    return false



func GetCanArmorDrawCharacterList() -> Array:
    var characterList: Array = []
    if checkAll:
        var characterListGet = TowerDefenseManager.GetCampTarget(parent.camp)
        for character: TowerDefenseCharacter in characterListGet:
            if !character.instance.canBeCollection:
                continue
            var armorList: Array[TowerDefenseArmorInstance] = []
            armorList.append_array(character.GetArmorHeadCover())
            armorList.append_array(character.GetArmorShield())
            armorList.append_array(character.GetArmorHelment())
            armorList.append_array(character.GetArmor())
            for armor: TowerDefenseArmorInstance in armorList:
                if armor.IsMetallic():
                    if !characterList.has(character):
                        characterList.append(character)
    else:
        var pos: Vector2 = TowerDefenseManager.GetMapCellPosCenter(TowerDefenseManager.GetMapGridPos(parent.global_position))
        shape.size = TowerDefenseManager.GetMapGridSize() * 2.0 * checkRange
        params.transform = Transform2D(0, pos)
        await get_tree().physics_frame
        var arr = get_world_2d().direct_space_state.intersect_shape(params)
        for infor: Dictionary in arr:
            if infor["collider"] is Area2D:
                var area: Area2D = infor["collider"]
                var character = area.get_parent()
                if character is TowerDefenseCharacter:
                    if !character.instance.canBeCollection:
                        continue
                    if character.camp != parent.camp:
                        var gridDist: Vector2i = (character.gridPos - parent.gridPos).abs()
                        if float(gridDist.x) > checkRange.x || float(gridDist.y) > checkRange.y:
                            continue
                        var armorList: Array[TowerDefenseArmorInstance] = []
                        armorList.append_array(character.GetArmorHeadCover())
                        armorList.append_array(character.GetArmorShield())
                        armorList.append_array(character.GetArmorHelment())
                        armorList.append_array(character.GetArmor())
                        for armor: TowerDefenseArmorInstance in armorList:
                            if armor.IsMetallic():
                                if !characterList.has(character):
                                    characterList.append(character)
    return characterList



func ArmorDraw() -> TowerDefenseArmorInstance:
    if !is_instance_valid(drawArmorCharacter):
        return null
    breakDownArmor = drawArmor

    AudioManager.AudioPlay("Magnet", AudioManagerEnum.TYPE.SFX)
    magnet = drawArmorCharacter.ArmorDraw(breakDownArmor)
    drawArmorCharacter.sprite.queue_redraw()
    if is_instance_valid(magnet):
        magnet.adsorbedObject = parent
        magnet.gridPos = parent.gridPos
        breakDownTimer = breakDownTime
        return breakDownArmor
    return null



func ArmorDrawNear() -> TowerDefenseArmorInstance:
    var lengthMin = 100000000
    if checkAll:
        var characterList = TowerDefenseManager.GetCampTarget(parent.camp)
        for character: TowerDefenseCharacter in characterList:
            if !character.instance.canBeCollection:
                continue
            if parent.global_position.distance_squared_to(character.global_position) < lengthMin:
                var armorList: Array[TowerDefenseArmorInstance] = []
                armorList.append_array(character.GetArmorHeadCover())
                armorList.append_array(character.GetArmorShield())
                armorList.append_array(character.GetArmorHelment())
                armorList.append_array(character.GetArmor())
                for armor: TowerDefenseArmorInstance in armorList:
                    if armor.IsMetallic():
                        drawArmorCharacter = character
                        drawArmor = armor
                        lengthMin = parent.global_position.distance_squared_to(character.global_position)
                        break
    else:
        await get_tree().physics_frame
        var arr = get_world_2d().direct_space_state.intersect_shape(params, 10000)
        for infor: Dictionary in arr:
            if infor["collider"] is Area2D:
                var area: Area2D = infor["collider"]
                var character = area.get_parent()
                if character is TowerDefenseCharacter:
                    if !character.instance.canBeCollection:
                        continue
                    if parent.global_position.distance_squared_to(character.global_position) < lengthMin:
                        if character.camp != parent.camp:
                            var gridDist: Vector2i = (character.gridPos - parent.gridPos).abs()
                            if float(gridDist.x) > checkRange.x || float(gridDist.y) > checkRange.y:
                                continue
                            var armorList: Array[TowerDefenseArmorInstance] = []
                            armorList.append_array(character.GetArmorHeadCover())
                            armorList.append_array(character.GetArmorShield())
                            armorList.append_array(character.GetArmorHelment())
                            armorList.append_array(character.GetArmor())
                            for armor: TowerDefenseArmorInstance in armorList:
                                if armor.IsMetallic():
                                    lengthMin = parent.global_position.distance_squared_to(character.global_position)
                                    drawArmorCharacter = character
                                    drawArmor = armor
                                    break

    if !is_instance_valid(drawArmorCharacter):
        return null
    breakDownArmor = drawArmor

    AudioManager.AudioPlay("Magnet", AudioManagerEnum.TYPE.SFX)
    magnet = drawArmorCharacter.ArmorDraw(breakDownArmor)
    drawArmorCharacter.sprite.queue_redraw()
    if is_instance_valid(magnet):
        drawTarget.emit(drawArmorCharacter)
        magnet.adsorbedObject = parent
        magnet.gridPos = parent.gridPos
        breakDownTimer = breakDownTime
        return breakDownArmor
    else:
        breakDownArmor = null
    return null



func ArmorBreakDown(delta: float) -> void :
    if breakDownTimer > 0.0:
        breakDownTimer -= delta * parent.timeScale
        if is_instance_valid(magnet):
            magnet.scale = Vector2.ONE * (breakDownTimer / breakDownTime)
        return
    BreakDownOver()


func BreakDownOver() -> void :
    if is_instance_valid(breakDownArmor):
        BreakDown(breakDownArmor)
        breakDown.emit(breakDownArmor)
    breakDownArmor = null
    isArrive = false
    if is_instance_valid(magnet):
        magnet.queue_free()
        magnet = null


func Destroy() -> void :
    if is_instance_valid(magnet):
        magnet.queue_free()
        magnet = null




func IdleEntered() -> void :
    if parent.componentRunning:
        parent.Idle()


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if !parent.componentAlive:
        return
    if parent.componentRunning:
        return
    if await CanArmorDraw():
        parent.Component()
        state.send_event("ToBegin")


func IdleExited() -> void :
    pass


func BeginEntered() -> void :
    sprite.SetAnimation(shootBeginAnimeClips, false, 0.2)


@warning_ignore("unused_parameter")
func BeginProcessing(delta: float) -> void :
    if !TowerDefenseManager.IsIZMMode():
        sprite.timeScale = parent.timeScale * shootBeginAnimeTimeScale
    else:
        sprite.timeScale = shootBeginAnimeTimeScale


func BeginExited() -> void :
    pass


func ShootEntered() -> void :
    sprite.SetAnimation(shootAnimeClips, false, 0.0)


@warning_ignore("unused_parameter")
func ShootProcessing(delta: float) -> void :
    if !TowerDefenseManager.IsIZMMode():
        sprite.timeScale = parent.timeScale * shootAnimeTimeScale
    else:
        sprite.timeScale = shootAnimeTimeScale


func ShootExited() -> void :
    pass


func EndEntered() -> void :
    sprite.SetAnimation(shootEndAnimeClips, false, 0.2)


@warning_ignore("unused_parameter")
func EndProcessing(delta: float) -> void :
    if !TowerDefenseManager.IsIZMMode():
        sprite.timeScale = parent.timeScale * shootBeginAnimeTimeScale
    else:
        sprite.timeScale = shootBeginAnimeTimeScale


func EndExited() -> void :
    pass


func NoActiveEntered() -> void :
    sprite.SetAnimation(noActiveAnimeClips, true, 0.2)


@warning_ignore("unused_parameter")
func NoActiveProcessing(delta: float) -> void :
    if !TowerDefenseManager.IsIZMMode():
        sprite.timeScale = parent.timeScale * noActiveAnimeTimeScale
    else:
        sprite.timeScale = noActiveAnimeTimeScale


func NoActiveExited() -> void :
    pass


@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    match command:
        drawEventName:
            await ArmorDrawNear()


func AnimeCompleted(clip: String) -> void :
    match clip:
        shootBeginAnimeClips:
            state.send_event("ToShoot")
        shootAnimeClips:
            if is_instance_valid(breakDownArmor):
                state.send_event("ToNoActive")
            else:
                state.send_event("ToEnd")
        shootEndAnimeClips:
            state.send_event("ToIdle")


func BreakDown(_armor: TowerDefenseArmorInstance) -> void :
    if !is_instance_valid(sprite):
        return
    state.send_event("ToEnd")

func ExportComponentSave() -> Dictionary:
    return {
        "breakDownTimer": breakDownTimer, 
        "isArrive": isArrive, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    breakDownTimer = _data.get("breakDownTimer", 0.0)
    isArrive = _data.get("isArrive", false)
