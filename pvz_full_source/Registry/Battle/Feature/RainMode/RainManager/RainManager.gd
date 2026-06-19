class_name RainManager extends Control

@onready var pcRainContainer: HBoxContainer = %PCRainContainer
@onready var pcSunBarTexture: TextureRect = %PCSunBarTexture
@onready var pcSunLabel: Label = %PCSunLabel

@onready var mobileSunBarTexture: TextureRect = %MobileSunBarTexture
@onready var mobileSunLabel: Label = %MobileSunLabel

var isMobileUI: bool = false
var isSunType: bool = false
var sunNumShow: int = 0

func _ready() -> void :
    BattleEventBus.uiSwitched.connect(ApplyMode)
    isMobileUI = GameSaveManager.GetConfigValue("MobilePreset")
    ApplyMode(isMobileUI)

func ApplyMode(mobile_preset: bool) -> void :
    isMobileUI = mobile_preset
    if mobile_preset:
        pcRainContainer.visible = false
        mobileSunBarTexture.visible = isSunType
        custom_minimum_size.x = 0
    else:
        pcRainContainer.visible = true
        mobileSunBarTexture.visible = false
        pcSunBarTexture.visible = isSunType
        pcSunLabel.visible = isSunType
        custom_minimum_size.x = 80 if isSunType else 0

func Init(type: String) -> void :
    await get_tree().physics_frame
    if type == "Sun":
        isSunType = true
        var initSun: int = TowerDefenseManager.GetSun()
        if initSun >= 0:
            sunNumShow = initSun
            if is_instance_valid(pcSunLabel):
                pcSunLabel.text = str(sunNumShow)
            if is_instance_valid(mobileSunLabel):
                mobileSunLabel.text = str(sunNumShow)
        if !isMobileUI:
            pcSunBarTexture.visible = true
            pcSunLabel.visible = true
            custom_minimum_size.x = 80
        else:
            mobileSunBarTexture.visible = true

func UpdateSunDisplay() -> void :
    if !isSunType:
        return
    var sunNum: int = TowerDefenseManager.GetSun()
    if sunNumShow != sunNum:
        sunNumShow = sunNum
        if is_instance_valid(pcSunLabel):
            pcSunLabel.text = str(sunNumShow)
        if is_instance_valid(mobileSunLabel):
            mobileSunLabel.text = str(sunNumShow)

func ShowMobileSunBar(_visible: bool) -> void :
    if is_instance_valid(mobileSunBarTexture):
        mobileSunBarTexture.visible = _visible

func GetMobileSunLabel() -> Label:
    return mobileSunLabel

func GetPCSunLabel() -> Label:
    return pcSunLabel
