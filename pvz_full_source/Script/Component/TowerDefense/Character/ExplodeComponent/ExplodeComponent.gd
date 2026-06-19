
class_name ExplodeComponent extends ComponentBase


signal explode()


@onready var state: StateChart = %StateChart

@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var explodeAnimeClips: String = "Explode"

@export var explodeAnimeTimeScale: float = 1.0
@export_subgroup("ExplodeSetting")
@export var skipGameRunning: bool = false

@export var checkIZM: bool = true

@export_enum("Range", "Line", "Row", "Cross", "Slash") var explodeMethod: String = "Range"

@export var explodeUse: bool = true

@export var reload: bool = true

@export var explodeOnce: bool = true

@export var reverseAudio: String = "ReverseExplosion"

@export var explodeAudio: String = "ExplodeCherrybomb"

@export var explodeEvent: Array[TowerDefenseCharacterEventBase]

@export var explodeEffect: PackedScene

@export var explodeRange: Vector2 = Vector2(1.5, 1.5)
@export_subgroup("JalaSetting")

@export_enum("Fire", "IceFire", "MegaFire", "PurifyFire", "WhiteFire") var explodeJalaFireType: String = "Fire"

@export var explodeJalaNum: float = 1800.0

@export var explodeJalaOffset: Array[int]
@export_subgroup("CameraSetting")

@export var cameraShakeUse: bool = true

@export var cameraShakeOffset: Vector2 = Vector2(1, 1)

@export var cameraShakeForce: float = 5.0

@export var cameraShakeInterval: float = 0.05

@export var cameraShakeTime: int = 4
@export_subgroup("ScreenSetting")

@export var screenColorBlinkUse: bool = false

@export var screenColorBlinkColor: Color = Color.DARK_SLATE_BLUE

@export var screenColorBlinkDuration: float = 0.5

@export var screenColorBlinkRise: bool = false
@export_subgroup("ExtendSetting")

@export var craterCreateUse: bool = false

@export var craterCreatePacketName: String = "CraterDayGround"




var parent: TowerDefenseCharacter


var izmMode: bool = false

var isHurt: bool = false


func GetName() -> String:
    return "ExplodeComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return

    if checkIZM && TowerDefenseManager.IsIZMMode():
        izmMode = true
    if is_instance_valid(sprite):
        state.process_mode = Node.PROCESS_MODE_INHERIT
        sprite.animeCompleted.connect(AnimeCompleted)
        if izmMode:
            parent.bodyHurt.connect(IZMHurt)
            parent.armorHurt.connect(IZMHurt)


func Reload() -> void :
    reload = true


func Explode() -> void :
    if screenColorBlinkUse:
        ViewManager.FullScreenColorBlink(screenColorBlinkColor, screenColorBlinkDuration, screenColorBlinkRise)
    if cameraShakeUse:
        ViewManager.CameraShake(Vector2(randf_range( - cameraShakeOffset.x, cameraShakeOffset.x), randf_range( - cameraShakeOffset.y, cameraShakeOffset.y)), cameraShakeForce, cameraShakeInterval, cameraShakeTime)
    CreateParticlesEffect()
    if explodeAudio != "":
        AudioManager.AudioPlay(explodeAudio, AudioManagerEnum.TYPE.SFX)
    match explodeMethod:
        "Range":
            TowerDefenseExplode.CreateExplode(parent.global_position, explodeRange, explodeEvent, [], parent.camp, -1)
        "Line":
            for offset: int in explodeJalaOffset:
                if parent.gridPos.y + offset < 1:
                    continue
                if parent.gridPos.y + offset > TowerDefenseManager.GetMapGridNum().y:
                    continue
                TowerDefenseCharacter.CreateJalapenoFire(parent.camp, parent.gridPos + Vector2i(0, offset), explodeJalaNum, explodeEvent, [], explodeJalaFireType)
        "Row":
            for offset: int in explodeJalaOffset:
                if parent.gridPos.y + offset < 1:
                    continue
                if parent.gridPos.y + offset > TowerDefenseManager.GetMapGridNum().y:
                    continue
                TowerDefenseCharacter.CreateJalapenoFireColumn(parent.camp, parent.gridPos + Vector2i(0, offset), explodeJalaNum, explodeEvent, [], explodeJalaFireType)
        "Cross":
            for offset: int in explodeJalaOffset:
                if parent.gridPos.y + offset < 1:
                    continue
                if parent.gridPos.y + offset > TowerDefenseManager.GetMapGridNum().y:
                    continue
                TowerDefenseCharacter.CreateJalapenoFireColumn(parent.camp, parent.gridPos + Vector2i(0, offset), explodeJalaNum, explodeEvent, [], explodeJalaFireType)
                TowerDefenseCharacter.CreateJalapenoFire(parent.camp, parent.gridPos + Vector2i(0, offset), explodeJalaNum, explodeEvent, [], explodeJalaFireType)
        "Slash":
            for offset: int in explodeJalaOffset:
                if parent.gridPos.y + offset < 1:
                    continue
                if parent.gridPos.y + offset > TowerDefenseManager.GetMapGridNum().y:
                    continue
                TowerDefenseCharacter.CreateJalapenoFireSlash(parent.camp, parent.gridPos + Vector2i(0, offset), explodeJalaNum, explodeEvent, [], explodeJalaFireType)


    if craterCreateUse:
        parent.cell.Clear()
        parent.CraterCreate(true, craterCreatePacketName)
    explode.emit()



func CreateParticlesEffect() -> TowerDefenseEffectParticlesOnce:
    if !is_instance_valid(explodeEffect):
        return
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(explodeEffect, parent.gridPos)
    effect.global_position = parent.transformPoint.global_position - Vector2(0, 30)
    parent.characterNode.add_child(effect)
    return effect




@warning_ignore("unused_parameter")
func IZMHurt(num: int) -> void :
    isHurt = true


func IdleEntered() -> void :
    if parent.componentRunning:
        if parent is TowerDefensePlant:
            parent.Idle()


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if !TowerDefenseManager.IsGameRunning() && !skipGameRunning:
        return
    if !parent.inGame:
        return
    if !parent.componentAlive:
        return
    if parent.componentRunning:
        return
    if !reload:
        return
    state.send_event("ToExplode")


func IdleExited() -> void :
    pass


func ExplodeEntered() -> void :
    if parent is TowerDefensePlant:
        parent.Component()
    parent.instance.invincible = true
    if sprite.HasClip(explodeAnimeClips):
        sprite.SetAnimation(explodeAnimeClips, false, 0.2)
    if explodeUse:
        if reverseAudio != "":
            AudioManager.AudioPlay(reverseAudio, AudioManagerEnum.TYPE.SFX)


@warning_ignore("unused_parameter")
func ExplodeProcessing(delta: float) -> void :
    if !parent.componentAlive:
        state.send_event("ToIdle")
    if !checkIZM:
        if TowerDefenseManager.IsIZMMode():
            sprite.timeScale = explodeAnimeTimeScale
        else:
            sprite.timeScale = parent.timeScale * explodeAnimeTimeScale
    elif izmMode:
        if isHurt:
            sprite.timeScale = explodeAnimeTimeScale
        else:
            sprite.timeScale = 0.0
    else:
        sprite.timeScale = parent.timeScale * explodeAnimeTimeScale


func ExplodeExited() -> void :
    pass



func AnimeCompleted(clip: String) -> void :
    if parent.die || parent.nearDie:
        return
    match clip:
        explodeAnimeClips:
            if !reload:
                return
            reload = false
            if explodeUse:
                Explode()
            else:
                explode.emit()
            if explodeOnce:
                parent.Destroy()

func ExportComponentSave() -> Dictionary:
    return {
        "izmMode": izmMode, 
        "isHurt": isHurt, 
        "reload": reload, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    izmMode = _data.get("izmMode", false)
    isHurt = _data.get("isHurt", false)
    reload = _data.get("reload", true)
