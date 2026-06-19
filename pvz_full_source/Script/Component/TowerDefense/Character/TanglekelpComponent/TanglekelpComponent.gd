
class_name TanglekelpComponent extends ComponentBase


signal dragBegin(_target: TowerDefenseCharacter)

signal drag(_target: TowerDefenseCharacter, success: bool)


@onready var state: StateChart = %StateChart


@export var attackComponent: AttackComponent

@export var grabNum: int = 1

@export var destroyUse: bool = true

@export var targetDestroyUse: bool = true
@export_subgroup("AnimeSetting")

@export var grabSpriteScene: PackedScene

@export var grabAnimeClips: String = "Grab"

@export var grabAnimeTimeScale: float = 1.0

@export var grabFliterOpen: Array[String] = []

@export var grabFliterClose: Array[String] = []


var parent: TowerDefenseCharacter


var target: TowerDefenseCharacter


var currentGrabNum: int = 0


func GetName() -> String:
    return "TanglekelpComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return

    if is_instance_valid(attackComponent):
        state.process_mode = Node.PROCESS_MODE_INHERIT
    grabFliterOpen.clear()
    grabFliterClose.clear()


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return




func IdleEntered() -> void :
    if !alive:
        return
    if parent.componentRunning:
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
    if attackComponent.CanAttackOnce():
        target = attackComponent.target
        state.send_event("ToDrag")


func IdleExited() -> void :
    pass


func DragEntered() -> void :
    Drag(target)


@warning_ignore("unused_parameter")
func DragProcessing(delta: float) -> void :
    pass


func DragExited() -> void :
    pass



func Drag(character: TowerDefenseCharacter) -> void :
    dragBegin.emit(character)
    var dragFlag: bool = true
    if is_instance_valid(character):
        if !character.config.canDragIntoWater:
            dragFlag = false
    parent.instance.invincible = true
    AudioManager.AudioPlay("Floop", AudioManagerEnum.TYPE.SFX)
    AudioManager.AudioPlay("PlantWater", AudioManagerEnum.TYPE.SFX)
    var grabSprite = grabSpriteScene.instantiate()
    grabSprite.SetFliters(grabFliterOpen, true)
    grabSprite.SetFliters(grabFliterClose, false)
    parent.spriteGroup.add_child(grabSprite)
    grabSprite.visible = true
    grabSprite.SetAnimation(grabAnimeClips, false)
    grabSprite.global_position = character.global_position
    if dragFlag:
        if is_instance_valid(character):
            character.CreateSplash()
            character.sprite.pause = true
            character.hitBox.monitorable = false
    parent.itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.EFFECT
    if is_instance_valid(get_tree()):
        await get_tree().create_timer(0.5, false).timeout
    parent.CreateSplash()
    AudioManager.AudioPlay("ZombieEnteringWater", AudioManagerEnum.TYPE.SFX)
    if is_instance_valid(grabSprite):
        grabSprite.queue_free()
    drag.emit(character, dragFlag)
    currentGrabNum += 1
    if dragFlag:
        if is_instance_valid(character):
            if targetDestroyUse:
                if character.config.dragHurt != -1:
                    character.Hurt(character.config.dragHurt)
                    character.sprite.pause = false
                    character.hitBox.monitorable = true
                else:
                    character.die = true
                    character.Destroy()
            else:
                character.sprite.pause = false
                character.hitBox.monitorable = true
    if destroyUse:
        if currentGrabNum >= grabNum:
            AudioManager.AudioPlay("PlantWater", AudioManagerEnum.TYPE.SFX)
            if is_instance_valid(character):
                character.CreateSplash()
            parent.Destroy()
