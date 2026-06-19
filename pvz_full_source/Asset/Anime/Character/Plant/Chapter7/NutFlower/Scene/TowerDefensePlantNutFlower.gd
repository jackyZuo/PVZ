@tool
extends TowerDefensePlant

const NUT_FLOWER_HEAD_0 = preload("uid://be82j51vjke1j")
const NUT_FLOWER_HEAD_1 = preload("uid://bxyhuq515ddlw")
const NUT_FLOWER_HEAD_2 = preload("uid://bouacd0clkgti")
const NUT_FLOWER_PETALS_0 = preload("uid://cso7gcei1860x")
const NUT_FLOWER_PETALS_1 = preload("uid://dlwrnuy6lpacf")
const NUT_FLOWER_PETALS_2 = preload("uid://c1syccnl5bb86")

@onready var produceComponent: ProduceComponent = %ProduceComponent


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

@export_enum("Sun", "BrainSun", "JalaSun", "Coin", "Packet") var produceType: String = "Packet":
    set(_produceType):
        produceType = _produceType
        if is_node_ready():
            produceComponent.produceType = produceType

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

    produceComponent.produceInterval = produceInterval
    produceComponent.num = sunNum

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            sprite.SetReplace("NutFlower_head0.png", NUT_FLOWER_HEAD_0)
            sprite.SetReplace("NutFlower_petals0.png", NUT_FLOWER_PETALS_0)
        "Damage1":
            sprite.SetReplace("NutFlower_head0.png", NUT_FLOWER_HEAD_1)
            sprite.SetReplace("NutFlower_petals0.png", NUT_FLOWER_PETALS_1)
        "Damage2":
            sprite.SetReplace("NutFlower_head0.png", NUT_FLOWER_HEAD_2)
            sprite.SetReplace("NutFlower_petals0.png", NUT_FLOWER_PETALS_2)




func ExportVariantSave() -> Dictionary:
    return {
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 25)
