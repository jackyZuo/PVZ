
class_name SleepComponent extends ComponentBase


const SLEEP_Z = preload("uid://bynt7ha6s6wvb")


var parent: TowerDefenseCharacter


var sleepSprite: AdobeAnimateSprite


func GetName() -> String:
    return "SleepComponent"


func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready


func SleepEntered() -> void :
    parent.componentAlive = false
    parent.instance.wakeUp = false
    parent.sprite.timeScale = parent.timeScale
    sleepSprite = SLEEP_Z.instantiate()
    sleepSprite.position = Vector2(20, 25)
    parent.spriteGroup.add_child(sleepSprite)
    parent.instance.sleep = true
    if parent.sleepAnimeClip != "":
        parent.sprite.SetAnimation(parent.sleepAnimeClip, true, 0.2)
    if TowerDefenseManager.IsIZMMode():
        parent.timeScaleSave = parent.timeScaleInit
        parent.timeScaleInit = 0.0
        parent.timeScale = 0.0
        parent.sprite.timeScale = 0.0


func SleepProcessing(_delta: float) -> void :
    if !CanSleep():
        parent.Idle()


func SleepExited() -> void :
    parent.componentAlive = true
    var saveScale: Vector2 = parent.transformPoint.scale
    var tween = parent.create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUART)
    tween.tween_property(parent.transformPoint, ^"scale:y", saveScale.y - 0.25, 0.25)
    tween.tween_property(parent.transformPoint, ^"scale:y", saveScale.y + 0.1, 0.25)
    tween.tween_property(parent.transformPoint, ^"scale:y", saveScale.y, 0.25)
    if is_instance_valid(sleepSprite):
        sleepSprite.queue_free()
    parent.instance.sleep = false
    if TowerDefenseManager.IsIZMMode():
        parent.timeScaleInit = parent.timeScaleSave



func CanSleep() -> bool:
    var hasSleepBuff: bool = parent.buff.BuffHas("Sleep")
    if parent.instance.wakeUp:
        if !hasSleepBuff:
            return false
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if is_instance_valid(mapFeature):
        if is_instance_valid(mapFeature.config) && mapFeature.config.isHeaven:
            return false
    var sleepFlag: bool = true
    match parent.config.sleepTime:
        "Never":
            sleepFlag = false
        "Day":
            if TowerDefenseManager.GetMapIsNight():
                sleepFlag = false
            if is_instance_valid(parent.cell):
                if parent.cell.elementFlags & TowerDefenseEnum.ELEMENT_SYSTEM.NIGHT:
                    sleepFlag = false
        "Night":
            if !TowerDefenseManager.GetMapIsNight():
                sleepFlag = false
            if is_instance_valid(parent.cell):
                if parent.cell.elementFlags & TowerDefenseEnum.ELEMENT_SYSTEM.DAY:
                    sleepFlag = false
    if hasSleepBuff:
        sleepFlag = true
    if is_instance_valid(TowerDefenseManager.GetMapFeature()) && is_instance_valid(parent.cell):
        if parent.cell.elementFlags & parent.instance.elementFlags:
            sleepFlag = false
        if parent.cell.HasCoffee(parent.camp):
            sleepFlag = false
            if hasSleepBuff:
                parent.buff.BuffDelete("Sleep")
    return sleepFlag
