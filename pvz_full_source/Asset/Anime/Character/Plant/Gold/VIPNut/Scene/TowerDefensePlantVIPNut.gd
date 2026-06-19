@tool
extends TowerDefensePlant
const VIP_NUT_SKIN_2_1 = preload("uid://3lrskq4eia8b")
const VIP_NUT_SKIN_2_2 = preload("uid://c6lmbuq33tm3")
const VIP_NUT_SKIN_2_3 = preload("uid://frbgmrgbd7s1")
const VIP_NUT_SKIN_4_1 = preload("uid://bisp36tuaclyt")
const VIP_NUT_SKIN_4_2 = preload("uid://jh80dvtmfn58")
const VIP_NUT_SKIN_4_3 = preload("uid://iywdryeb7h4g")

@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var growUpComponent: GrowUpComponent = %GrowUpComponent

@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if is_node_ready():
            produceComponent.produceInterval = produceInterval

@export var sunNum: int = 25:
    set(_sunNum):
        sunNum = _sunNum
        if is_node_ready():
            produceComponent.num = sunNum

@export var growUpTime: float = 60.0:
    set(_growUpTime):
        growUpTime = _growUpTime
        if is_node_ready():
            growUpComponent.growUpTime[0] = growUpTime

@export var growUpSunNum: int = 50:
    set(_growUpSunNum):
        growUpSunNum = _growUpSunNum

@export_enum("Sun", "BrainSun", "JalaSun", "Coin") var produceType: String = "Sun":
    set(_produceType):
        produceType = _produceType
        if !is_node_ready():
            await ready
        produceComponent.produceType = produceType

@export var dieCreateSunNum: int = 200

var over: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

    produceComponent.produceInterval = produceInterval
    produceComponent.num = sunNum

    growUpComponent.growUpTime[0] = growUpTime

func GowUp(reach: int) -> void :
    match reach:
        0:
            produceComponent.num = growUpSunNum
            dieCreateSunNum = 400
            instance.height = TowerDefenseEnum.CHARACTER_HEIGHT.TALL
            Health(4000)
            instance.hitpointsSave += 4000

func DestroySet() -> void :
    if over:
        return
    over = true
    for i in floor(float(dieCreateSunNum) / 50):
        if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode() || instance.hypnoses:
            BrainSunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
        else:
            SunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("VIPNut_skin2_1.png", VIP_NUT_SKIN_2_1)
                sprite.SetReplace("VIPNut_skin4_1.png", VIP_NUT_SKIN_4_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("VIPNut_skin2_1.png", VIP_NUT_SKIN_2_2)
                sprite.SetReplace("VIPNut_skin4_1.png", VIP_NUT_SKIN_4_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("VIPNut_skin2_1.png", VIP_NUT_SKIN_2_3)
                sprite.SetReplace("VIPNut_skin4_1.png", VIP_NUT_SKIN_4_3)

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "growUpTime": growUpTime, 
        "growUpSunNum": growUpSunNum, 
        "dieCreateSunNum": dieCreateSunNum, 
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 25)
    growUpTime = data.get("growUpTime", 60.0)
    growUpSunNum = data.get("growUpSunNum", 50)
    dieCreateSunNum = data.get("dieCreateSunNum", 200)
    over = data.get("over", false)
