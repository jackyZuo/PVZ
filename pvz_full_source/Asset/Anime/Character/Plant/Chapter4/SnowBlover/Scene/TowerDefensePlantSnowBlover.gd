@tool
extends TowerDefensePlant

@onready var bloverComponent: BloverComponent = %BloverComponent

var projectileName: String = "SnowPea":
    set(_projectileName):
        projectileName = _projectileName
        var data: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projectileName))
        data.skinName = StringName(skinName)
        bloverComponent.projectileDataList = [data]

var skinName: String = "Default":
    set(_skinName):
        skinName = _skinName
        bloverComponent.projectileDataList[0].skinName = skinName

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

var run: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if currentCustom.has("Custom0"):
        skinName = "Piece"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Piece"
    else:
        skinName = "Default"

func IdleEntered() -> void :
    if !inGame:
        return
    if !TowerDefenseManager.currentControl.isGameRunning:
        return
    Run()

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale * 2.0
    if !inGame:
        return
    if !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !run:
        Run()

func Run() -> void :
    sprite.SetAnimation("Blow", false, 0.2)
    sprite.AddAnimation("Loop", 0.0, true, 0.0)
    instance.invincible = true
    run = true

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "blow":
            bloverComponent.Execult()

func BlowOver() -> void :
    Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "projectileName": projectileName, 
        "skinName": skinName, 
        "run": run, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    projectileName = data.get("projectileName", "SnowPea")
    skinName = data.get("skinName", "Default")
    run = data.get("run", false)
