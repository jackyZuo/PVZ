@tool
extends TowerDefensePlant
const PLANT_ROBOT_BACK_1 = preload("uid://2ebfsacjxwse")
const PLANT_ROBOT_BACK_2 = preload("uid://drjphbxctwqg5")
const PLANT_ROBOT_BACK_3 = preload("uid://800yffpdvahb")
const PLANT_ROBOT_BODY_A_1 = preload("uid://ce35mdynvmvys")
const PLANT_ROBOT_BODY_A_2 = preload("uid://dct082g5i6hg2")
const PLANT_ROBOT_BODY_A_3 = preload("uid://dxgmilyjml4ar")
const PLANT_ROBOT_BODY_B_1 = preload("uid://chpeoi5efjvh3")
const PLANT_ROBOT_BODY_B_2 = preload("uid://b6r70pq04d4ix")
const PLANT_ROBOT_BODY_B_3 = preload("uid://btbl5f7ps30pe")
const PLANT_ROBOT_LEFT_A_1 = preload("uid://dixhlofgnr2sn")
const PLANT_ROBOT_LEFT_A_2 = preload("uid://dtj3daoe3i4ti")
const PLANT_ROBOT_LEFT_A_3 = preload("uid://doovkx7gcrx86")
const PLANT_ROBOT_LEFT_B_1 = preload("uid://dqh161x05tspr")
const PLANT_ROBOT_LEFT_B_2 = preload("uid://bb5kstf508tte")
const PLANT_ROBOT_LEFT_B_3 = preload("uid://dmln03hqaw5gp")
const PLANT_ROBOT_LEFT_C_1 = preload("uid://btwt3uvvuwqvi")
const PLANT_ROBOT_LEFT_C_2 = preload("uid://bl70mcjce8gs5")
const PLANT_ROBOT_LEFT_C_3 = preload("uid://ipidh6t2njt5")
const PLANT_ROBOT_LEFT_D_1 = preload("uid://xxnso6kdbkmo")
const PLANT_ROBOT_LEFT_D_2 = preload("uid://dkedocvimlovk")
const PLANT_ROBOT_LEFT_D_3 = preload("uid://cvlfngqme066r")
const PLANT_ROBOT_RIGHT_A_1 = preload("uid://dl3031sobp60x")
const PLANT_ROBOT_RIGHT_A_2 = preload("uid://dhu31tsxoow2k")
const PLANT_ROBOT_RIGHT_A_3 = preload("uid://bik8j6bxg7c6f")
const PLANT_ROBOT_RIGHT_B_1 = preload("uid://de2tghwbp36s1")
const PLANT_ROBOT_RIGHT_B_2 = preload("uid://crlmumytyhe5g")
const PLANT_ROBOT_RIGHT_B_3 = preload("uid://cfmmts1sfdfh7")
const PLANT_ROBOT_RIGHT_C_1 = preload("uid://bjdp1rn525cpp")
const PLANT_ROBOT_RIGHT_C_2 = preload("uid://cy0mkglnhyjb1")
const PLANT_ROBOT_RIGHT_C_3 = preload("uid://dcyvp5l2b6xpf")
const PLANT_ROBOT_RIGHT_D_1 = preload("uid://cxdjxqi46a72q")
const PLANT_ROBOT_RIGHT_D_2 = preload("uid://b23wdixmq6p32")
const PLANT_ROBOT_RIGHT_D_3 = preload("uid://yimmc7j73xhe")

@onready var fireComponent: FireComponent = %FireComponent
@onready var fireComponent2: FireComponent = %FireComponent2
@onready var collisionShape2d2: CollisionShape2D = %CollisionShape2D2
@onready var collisionShape2d3: CollisionShape2D = %CollisionShape2D3
@onready var timerComponent: TimerComponent = %TimerComponent

var modeList: Array = ["A", "B", "C"]
var modeId: int = 0

func _ready() -> void :
    super._ready()
    collisionShape2d2.position.y = TowerDefenseManager.GetMapGridSize().y
    collisionShape2d3.position.y = - TowerDefenseManager.GetMapGridSize().y

func IdleEntered() -> void :
    super.IdleEntered()
    match modeId:
        0:
            fireComponent.alive = true
            sprite.SetAnimation("IdleA", true, 0.1)
        1:
            fireComponent2.alive = true
            sprite.SetAnimation("IdleB", true, 0.1)
        2:
            instance.explosionHurt = config.explosionHurt / 2
            instance.smashHurt = config.smashHurt / 2
            instance.dragHurt = config.dragHurt / 2
            instance.spikeHurt = config.spikeHurt / 2
            instance.biteHurt = config.biteHurt / 2
            timerComponent.Run("Heal", 1.0)
            sprite.SetAnimation("IdleC", true, 0.1)

func DownEntered() -> void :
    timerComponent.Stop("Heal")
    fireComponent.alive = false
    fireComponent2.alive = false
    instance.explosionHurt = config.explosionHurt
    instance.smashHurt = config.smashHurt
    instance.dragHurt = config.dragHurt
    instance.spikeHurt = config.spikeHurt
    instance.biteHurt = config.biteHurt
    match modeId:
        0:
            sprite.SetAnimation("DownA", false, 0.1)
        1:
            sprite.SetAnimation("DownB", false, 0.1)
        2:
            sprite.SetAnimation("DownC", false, 0.1)

@warning_ignore("unused_parameter")
func DownProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func DownExited() -> void :
    pass

func UpEntered() -> void :
    match modeId:
        0:
            sprite.SetAnimation("UpA", false, 0.1)
        1:
            sprite.SetAnimation("UpB", false, 0.1)
        2:
            sprite.SetAnimation("UpC", false, 0.1)

@warning_ignore("unused_parameter")
func UpProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func UpExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "UpA", "UpB", "UpC":
            Idle()
        "DownA", "DownB", "DownC":
            modeId = (modeId + 1 + modeList.size()) % modeList.size()
            state.send_event("ToUp")

@warning_ignore("unused_parameter")
func DoublePressed(pos: Vector2) -> void :
    state.send_event("ToDown")

func Timeout(timerName: String) -> void :
    match timerName:
        "Heal":
            timerComponent.Run("Heal", 1.0)
            Health(50.0)
            if instance.hitpoints >= instance.hitpointsSave:
                instance.hitpoints = instance.hitpointsSave

func DamagePointReach(damagePointName: String) -> void :
    match damagePointName:
        "Damage0":
            sprite.SetReplace("PlantRobot_Back1.png", PLANT_ROBOT_BACK_1)
            sprite.SetReplace("PlantRobot_BodyA_1.png", PLANT_ROBOT_BODY_A_1)
            sprite.SetReplace("PlantRobot_BodyB_1.png", PLANT_ROBOT_BODY_B_1)
            sprite.SetReplace("PlantRobot_LeftA_1.png", PLANT_ROBOT_LEFT_A_1)
            sprite.SetReplace("PlantRobot_LeftB_1.png", PLANT_ROBOT_LEFT_B_1)
            sprite.SetReplace("PlantRobot_LeftC_1.png", PLANT_ROBOT_LEFT_C_1)
            sprite.SetReplace("PlantRobot_LeftD_1.png", PLANT_ROBOT_LEFT_D_1)
            sprite.SetReplace("PlantRobot_RightA_1.png", PLANT_ROBOT_RIGHT_A_1)
            sprite.SetReplace("PlantRobot_RightB_1.png", PLANT_ROBOT_RIGHT_B_1)
            sprite.SetReplace("PlantRobot_RightC_1.png", PLANT_ROBOT_RIGHT_C_1)
            sprite.SetReplace("PlantRobot_RightD_1.png", PLANT_ROBOT_RIGHT_D_1)
        "Damage1":
            sprite.SetReplace("PlantRobot_Back1.png", PLANT_ROBOT_BACK_2)
            sprite.SetReplace("PlantRobot_BodyA_1.png", PLANT_ROBOT_BODY_A_2)
            sprite.SetReplace("PlantRobot_BodyB_1.png", PLANT_ROBOT_BODY_B_2)
            sprite.SetReplace("PlantRobot_LeftA_1.png", PLANT_ROBOT_LEFT_A_2)
            sprite.SetReplace("PlantRobot_LeftB_1.png", PLANT_ROBOT_LEFT_B_2)
            sprite.SetReplace("PlantRobot_LeftC_1.png", PLANT_ROBOT_LEFT_C_2)
            sprite.SetReplace("PlantRobot_LeftD_1.png", PLANT_ROBOT_LEFT_D_2)
            sprite.SetReplace("PlantRobot_RightA_1.png", PLANT_ROBOT_RIGHT_A_2)
            sprite.SetReplace("PlantRobot_RightB_1.png", PLANT_ROBOT_RIGHT_B_2)
            sprite.SetReplace("PlantRobot_RightC_1.png", PLANT_ROBOT_RIGHT_C_2)
            sprite.SetReplace("PlantRobot_RightD_1.png", PLANT_ROBOT_RIGHT_D_2)
        "Damage2":
            sprite.SetReplace("PlantRobot_Back1.png", PLANT_ROBOT_BACK_3)
            sprite.SetReplace("PlantRobot_BodyA_1.png", PLANT_ROBOT_BODY_A_3)
            sprite.SetReplace("PlantRobot_BodyB_1.png", PLANT_ROBOT_BODY_B_3)
            sprite.SetReplace("PlantRobot_LeftA_1.png", PLANT_ROBOT_LEFT_A_3)
            sprite.SetReplace("PlantRobot_LeftB_1.png", PLANT_ROBOT_LEFT_B_3)
            sprite.SetReplace("PlantRobot_LeftC_1.png", PLANT_ROBOT_LEFT_C_3)
            sprite.SetReplace("PlantRobot_LeftD_1.png", PLANT_ROBOT_LEFT_D_3)
            sprite.SetReplace("PlantRobot_RightA_1.png", PLANT_ROBOT_RIGHT_A_3)
            sprite.SetReplace("PlantRobot_RightB_1.png", PLANT_ROBOT_RIGHT_B_3)
            sprite.SetReplace("PlantRobot_RightC_1.png", PLANT_ROBOT_RIGHT_C_3)
            sprite.SetReplace("PlantRobot_RightD_1.png", PLANT_ROBOT_RIGHT_D_3)

func ExportVariantSave() -> Dictionary:
    return {
        "modeId": modeId, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    modeId = data.get("modeId", 0)
    fireComponent.alive = modeId == 0
    fireComponent2.alive = modeId == 1
    if modeId == 2:
        instance.explosionHurt = config.explosionHurt / 2
        instance.smashHurt = config.smashHurt / 2
        instance.dragHurt = config.dragHurt / 2
        instance.spikeHurt = config.spikeHurt / 2
        instance.biteHurt = config.biteHurt / 2
