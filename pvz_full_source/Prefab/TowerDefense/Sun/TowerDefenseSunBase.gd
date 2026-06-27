class_name TowerDefenseSunBase extends Node2D

@onready var sprite: AdobeAnimateSprite = %SunSprite
@onready var moveComponent: MoveComponent = %MoveComponent
@onready var light: PointLight2D = %Light
@onready var dieDownTimer: Timer = %DieDownTimer

var sunNum: int = 25
var height: float = 500
var isCollect: bool = false
var die: bool = false
var movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.LAND

var over: bool = false

var view: Viewport
var camera: Camera2D
var viewSize: Vector2

var autoCollect: bool = false

signal collect(num: int)

func GetGroupName() -> String:
    return "Sun"

func GetPoolKey() -> int:
    return ObjectManagerConfig.OBJECT.SUN

func GetDropItemConfig() -> DropItemConfig:
    return DropItemRegistry.GetById(GetPoolKey())

func OnCollectStart() -> void :
    pass

func GetCollectValue() -> int:
    var config: DropItemConfig = GetDropItemConfig()
    if config && config.handler:
        return config.handler.GetCollectValue(sunNum)
    return sunNum

func OnDieDown() -> bool:
    return false

func ShouldAutoCollect() -> bool:
    var config: DropItemConfig = GetDropItemConfig()
    if config && config.handler:
        if config.handler.ShouldAutoCollect():
            return true
    return autoCollect

func ConnectCollectSignal() -> void :
    var config: DropItemConfig = GetDropItemConfig()
    if config && config.handler:
        collect.connect( func(_num: int): config.handler.OnCollect(global_position, _num))
    else:
        collect.connect(TowerDefenseManager.AddSun)

func OnReady() -> void :
    pass

func OnRefresh() -> void :
    pass

@warning_ignore("unused_parameter")
func OnInitScaleTween(tween: Tween) -> void :
    pass

func Refresh() -> void :
    add_to_group(GetGroupName(), true)
    sprite.position = Vector2.ZERO
    sunNum = 25
    height = 500
    isCollect = false
    die = false
    over = false

    view = get_viewport()
    camera = view.get_camera_2d()
    viewSize = view.get_visible_rect().size

    light.visible = TowerDefenseManager.GetMapIsNight() && GameSaveManager.GetConfigValue("MapEffect")
    sprite.scale = Vector2.ZERO
    sprite.modulate.a = 1.0
    if is_instance_valid(dieDownTimer):
        dieDownTimer.start()

    OnRefresh()

    await get_tree().physics_frame
    autoCollect = GameSaveManager.GetFeatureValue("SunCollect")
    if ShouldAutoCollect():
        get_tree().create_timer(0.5, false).timeout.connect(Collection)

func Recycle() -> void :
    pass

func Init(_sunNum: int, _movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD, _height: float = 0.0, velocity: Vector2 = Vector2.ZERO, gravity: float = 0.0, moverStopTime: float = -1):
    sunNum = _sunNum
    movingMethod = _movingMethod
    height = _height
    match movingMethod:
        TowerDefenseEnum.SUN_MOVING_METHOD.LAND:
            moveComponent.SetVelocity(velocity)
        TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY:
            moveComponent.SetVelocity(velocity)
            moveComponent.SetGravity(gravity)

    var size: float = abs(sunNum / 25.0)
    if size > 2.0:
        size = 2.0
    var tween = create_tween()
    tween.tween_property(sprite, "scale", Vector2.ONE * size, 0.1).from(Vector2.ZERO)
    OnInitScaleTween(tween)

    if moverStopTime != -1:
        await get_tree().create_timer(moverStopTime, false).timeout
        moveComponent.MoveClear()

func _ready() -> void :
    ConnectCollectSignal()
    view = get_viewport()
    camera = view.get_camera_2d()
    viewSize = view.get_visible_rect().size
    sprite.SetAnimation("Idle", true)
    OnReady()

@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    if isCollect:
        return
    if Geometry2D.is_point_in_circle(get_global_mouse_position(), sprite.global_position, 40 * scale.x):
        Collection()

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if autoCollect:
        return
    if !over:
        if sprite.position.y > height && moveComponent.velocity.y > 0:
            moveComponent.MoveClear()
            sprite.position.y = height
            over = true

func Collection() -> void :
    if die:
        return
    if isCollect:
        return
    OnCollectStart()
    light.visible = false
    var config: DropItemConfig = GetDropItemConfig()
    var pickAudio: String = "Sun"
    if config:
        pickAudio = config.pickAudio
    AudioManager.AudioPlay(pickAudio, AudioManagerEnum.TYPE.SFX)
    moveComponent.MoveClear()
    isCollect = true
    var cameraPos: Vector2 = camera.global_position
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(sprite, "global_position", cameraPos + Vector2(32.0, 32.0), 1.0)
    await tween.finished
    collect.emit(GetCollectValue())
    remove_from_group(GetGroupName())
    tween = create_tween()
    tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
    await tween.finished
    Destroy()

func DieDown() -> void :
    if isCollect:
        return
    if OnDieDown():
        return
    moveComponent.MoveClear()
    remove_from_group(GetGroupName())
    die = true
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
    await tween.finished
    Destroy()

func Destroy() -> void :
    ObjectManager.PoolPush(GetPoolKey(), self)
