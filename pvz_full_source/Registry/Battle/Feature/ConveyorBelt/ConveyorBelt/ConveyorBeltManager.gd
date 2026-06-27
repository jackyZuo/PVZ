class_name ConveyorBeltManager extends Control

const CONVEYOR_BELT_SUN = preload("uid://i6rwl358wldw")
const CONVEYOR_BELT_SUN_BACKDROP = preload("uid://6h0njlvpp86")

@onready var pcConveyorBeltContainer: HBoxContainer = %PCConveyorBeltContainer
@onready var mobileConveyorBeltContainer: VBoxContainer = %MobileConveyorBeltContainer

@onready var pcControl: Control = %PCControl
@onready var mobileControl: Control = %MobileControl

@onready var packetContainer: Control = %PacketContainer
@onready var belt: TextureRect = %Belt

@onready var mobileBelt1: Sprite2D = %MobileBelt1
@onready var mobilePacketContainer1: Control = %MobilePacketContainer1
@onready var mobileBelt2: Sprite2D = %MobileBelt2
@onready var mobilePacketContainer2: Control = %MobilePacketContainer2

@onready var conveyorBeltRectPC: NinePatchRect = %ConveyorBeltRectPC
@onready var conveyorBeltRectMobile1: NinePatchRect = %ConveyorBeltRectMobile1
@onready var conveyorBeltRectMobile2: NinePatchRect = %ConveyorBeltRectMobile2

@onready var mobileConveyorBeltSunBarTexture: TextureRect = %MobileConveyorBeltSunBarTexture
@onready var mobileConveyorBeltSunLabel: Label = %MobileConveyorBeltSunLabel

@onready var pcConveyorBeltSunBarTexture: TextureRect = %PCConveyorBeltSunBarTexture
@onready var pcConveyorBeltSunLabel: Label = %PCConveyorBeltSunLabel

var beltTime: float = 0.0

var isMobileUI: bool = false

var conveyorBeltContainer: Container

var isSunType: bool = false
var sunNumShow: int = 0

func _ready() -> void :
    BattleEventBus.uiSwitched.connect(ApplyMode)
    isMobileUI = GameSaveManager.GetConfigValue("MobilePreset")
    @warning_ignore("incompatible_ternary")
    conveyorBeltContainer = (mobileConveyorBeltContainer if isMobileUI else pcConveyorBeltContainer)
    ApplyMode(isMobileUI)

func ApplyMode(mobile_preset: bool) -> void :
    if mobile_preset:
        conveyorBeltContainer = mobileConveyorBeltContainer
        pcConveyorBeltContainer.visible = false
        custom_minimum_size.x = 0
    else:
        conveyorBeltContainer = pcConveyorBeltContainer
        mobileConveyorBeltContainer.visible = false
        custom_minimum_size.x = 781 + (80 if isSunType else 0)
    isMobileUI = mobile_preset
    conveyorBeltContainer.visible = true
    SyncConveyorBelt(isMobileUI)
    if isSunType:
        if is_instance_valid(pcConveyorBeltSunBarTexture):
            pcConveyorBeltSunBarTexture.visible = !mobile_preset
        if is_instance_valid(pcConveyorBeltSunLabel):
            pcConveyorBeltSunLabel.visible = !mobile_preset
        ShowMobileSunBar(mobile_preset)

func SyncConveyorBelt(mobile_preset: bool) -> void :
    var children = GetPacketChildren( !mobile_preset)
    var id: int = 0
    for child in children:
        if child is TowerDefenseInGamePacketShow:
            if mobile_preset:
                if id % 2 == 0:
                    child.reparent(mobilePacketContainer1)
                    child.position = Vector2(0.0, 16 + 61.0 * floor(float(id) / 2))
                else:
                    child.reparent(mobilePacketContainer2)
                    child.position = Vector2(0.0, 16 + 61.0 * floor(float(id) / 2))
            else:
                child.reparent(packetContainer)
                child.position = Vector2(13 + 53.0 * id, 0.0)
            id += 1

func Init(type: String) -> void :
    await get_tree().physics_frame
    if type == "Sun":
        isSunType = true
        if is_instance_valid(conveyorBeltRectPC):
            conveyorBeltRectPC.texture = CONVEYOR_BELT_SUN_BACKDROP
        if is_instance_valid(belt):
            belt.texture = CONVEYOR_BELT_SUN
        if is_instance_valid(conveyorBeltRectMobile1):
            conveyorBeltRectMobile1.texture = CONVEYOR_BELT_SUN_BACKDROP
        if is_instance_valid(conveyorBeltRectMobile2):
            conveyorBeltRectMobile2.texture = CONVEYOR_BELT_SUN_BACKDROP
        if is_instance_valid(mobileBelt1):
            mobileBelt1.texture = CONVEYOR_BELT_SUN
        if is_instance_valid(mobileBelt2):
            mobileBelt2.texture = CONVEYOR_BELT_SUN
        if is_instance_valid(pcConveyorBeltSunBarTexture):
            pcConveyorBeltSunBarTexture.visible = !isMobileUI
        if is_instance_valid(pcConveyorBeltSunLabel):
            pcConveyorBeltSunLabel.visible = !isMobileUI
        ShowMobileSunBar(isMobileUI)
        if !isMobileUI:
            custom_minimum_size.x = 781 + 80
        var initSun: int = TowerDefenseManager.GetSun()
        if initSun >= 0:
            sunNumShow = initSun
            if is_instance_valid(pcConveyorBeltSunLabel):
                pcConveyorBeltSunLabel.text = str(sunNumShow)
            if is_instance_valid(mobileConveyorBeltSunLabel):
                mobileConveyorBeltSunLabel.text = str(sunNumShow)

func UpdateBeltAnimation(delta: float) -> void :
    if !visible:
        return
    if TowerDefenseManager.currentControl.isGameRunning:
        beltTime += delta
    if !isMobileUI:
        if is_instance_valid(belt) and is_instance_valid(belt.material):
            belt.material.set_shader_parameter("time", beltTime)
        var packetNum: int = packetContainer.get_child_count()
        for id in packetNum:
            var packet: TowerDefenseInGamePacketShow = packetContainer.get_child(id)
            var targetPos: Vector2 = GetPacketPos(id)
            if packet.position.x > targetPos.x:
                packet.position.x -= delta * 50.0
            else:
                packet.position.x = targetPos.x
    else:
        if is_instance_valid(mobileBelt1) and is_instance_valid(mobileBelt1.material):
            mobileBelt1.material.set_shader_parameter("time", beltTime)
        if is_instance_valid(mobileBelt2) and is_instance_valid(mobileBelt2.material):
            mobileBelt2.material.set_shader_parameter("time", beltTime)
        for id in mobilePacketContainer1.get_child_count():
            var packet: TowerDefenseInGamePacketShow = mobilePacketContainer1.get_child(id)
            var targetPos: Vector2 = mobilePacketContainer1.position + Vector2(0, 61 * id)
            if packet.position.y > targetPos.y:
                packet.position.y -= delta * 50.0
            else:
                packet.position.y = targetPos.y
        for id in mobilePacketContainer2.get_child_count():
            var packet: TowerDefenseInGamePacketShow = mobilePacketContainer2.get_child(id)
            var targetPos: Vector2 = mobilePacketContainer2.position + Vector2(0, 61 * id)
            if packet.position.y > targetPos.y:
                packet.position.y -= delta * 50.0
            else:
                packet.position.y = targetPos.y

func GetPacketPos(id: int) -> Vector2:
    return packetContainer.position + Vector2(53.0 * id, 0)

func GetPacketChildren(mobile_preset: bool = isMobileUI) -> Array[Node]:
    var children: Array[Node] = []
    if mobile_preset:
        if is_instance_valid(mobilePacketContainer1):
            children.append_array(mobilePacketContainer1.get_children())
        if is_instance_valid(mobilePacketContainer2):
            children.append_array(mobilePacketContainer2.get_children())
    else:
        if is_instance_valid(packetContainer):
            children.append_array(packetContainer.get_children())
    return children

func GetPacketCount() -> int:
    if !isMobileUI:
        return packetContainer.get_child_count()
    else:
        return mobilePacketContainer1.get_child_count() + mobilePacketContainer2.get_child_count()

func ResetPacketPositions() -> void :
    if !isMobileUI:
        var id: int = 0
        for child in packetContainer.get_children():
            if child is TowerDefenseInGamePacketShow:
                child.position = Vector2(13 + 53.0 * id, 0.0)
                id += 1
    else:
        var id1: int = 0
        for child in mobilePacketContainer1.get_children():
            if child is TowerDefenseInGamePacketShow:
                child.position = Vector2(0.0, 16 + 61.0 * id1)
                id1 += 1
        var id2: int = 0
        for child in mobilePacketContainer2.get_children():
            if child is TowerDefenseInGamePacketShow:
                child.position = Vector2(0.0, 16 + 61.0 * id2)
                id2 += 1

func AddPacketToUI(packet: TowerDefenseInGamePacketShow) -> void :
    if isMobileUI:
        packet.position = Vector2(0.0, 680.0)
        if mobilePacketContainer1.get_child_count() <= mobilePacketContainer2.get_child_count():
            mobilePacketContainer1.add_child(packet)
        else:
            mobilePacketContainer2.add_child(packet)
    else:
        packet.position = Vector2(868.0, 0.0)
        packetContainer.add_child(packet)

func ShowMobileSunBar(_visible: bool) -> void :
    if is_instance_valid(mobileConveyorBeltSunBarTexture):
        mobileConveyorBeltSunBarTexture.visible = _visible

func GetMobileSunLabel() -> Label:
    return mobileConveyorBeltSunLabel

func GetPCSunLabel() -> Label:
    return pcConveyorBeltSunLabel

func UpdateSunDisplay() -> void :
    if !isSunType:
        return
    var sunNum: int = TowerDefenseManager.GetSun()
    if sunNumShow != sunNum:
        sunNumShow = sunNum
        if is_instance_valid(pcConveyorBeltSunLabel):
            pcConveyorBeltSunLabel.text = str(sunNumShow)
        if is_instance_valid(mobileConveyorBeltSunLabel):
            mobileConveyorBeltSunLabel.text = str(sunNumShow)
