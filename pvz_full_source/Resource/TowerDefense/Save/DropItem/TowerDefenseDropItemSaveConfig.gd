class_name TowerDefenseDropItemSaveConfig extends Resource

@export var dropItemType: int
@export var pos: Vector2
@export var sunNum: int
@export var movingMethod: int
@export var isCollect: bool
@export var die: bool
@export var over: bool
@export var autoCollect: bool
@export var height: float
@export var velocity: Vector2
@export var gravity: float
@export var ySpeed: float
@export var z: float
@export var groundHeight: float
@export var timerTimeLeft: float
@export var spriteSave: Dictionary = {}

func SaveDropItem(dropItem: Node) -> void :
    pos = dropItem.global_position
    print("[Save] 保存掉落物: pos=(%.1f, %.1f)" % [pos.x, pos.y])
    if dropItem is TowerDefenseSunBase:
        var sun: TowerDefenseSunBase = dropItem as TowerDefenseSunBase
        sunNum = sun.sunNum
        movingMethod = sun.movingMethod
        isCollect = sun.isCollect
        die = sun.die
        over = sun.over
        autoCollect = sun.autoCollect
        height = sun.height
        if is_instance_valid(sun.moveComponent):
            velocity = sun.moveComponent.velocity
            gravity = sun.moveComponent.gravity
        if is_instance_valid(sun.dieDownTimer):
            timerTimeLeft = sun.dieDownTimer.time_left
        if is_instance_valid(sun.sprite):
            spriteSave = sun.sprite.ExportSpriteSave()
        if dropItem is TowerDefenseSun:
            dropItemType = ObjectManagerConfig.OBJECT.SUN
        elif dropItem is TowerDefenseBrainSun:
            dropItemType = ObjectManagerConfig.OBJECT.SUN_BRAIN
        elif dropItem is TowerDefenseSunJalapeno:
            dropItemType = ObjectManagerConfig.OBJECT.SUN_JALAPENO
        print("[Save] 掉落物保存完成: type=%d sunNum=%d 动画=%s" % [dropItemType, sunNum, "有" if spriteSave.size() > 0 else "无"])

@warning_ignore("unused_parameter")
func LoadDropItem(owner: TowerDefenseLevelSaveConfig) -> void :
    print("[Load] 加载掉落物: type=%d pos=(%.1f, %.1f) sunNum=%d" % [dropItemType, pos.x, pos.y, sunNum])
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var dropItem: Node = ObjectManager.PoolPop(dropItemType, characterNode)
    if dropItem is TowerDefenseSunBase:
        var sun: TowerDefenseSunBase = dropItem as TowerDefenseSunBase
        sun.global_position = pos
        sun.Init(sunNum, movingMethod, height, velocity, gravity, -1)
        sun.isCollect = isCollect
        sun.die = die
        sun.over = over
        sun.autoCollect = autoCollect
        if timerTimeLeft > 0 and is_instance_valid(sun.dieDownTimer):
            sun.dieDownTimer.start(timerTimeLeft)
        if is_instance_valid(sun.sprite) and spriteSave.size() > 0:
            sun.sprite.ImportSpriteSave(spriteSave)
        print("[Load] 掉落物加载完成: type=%d sunNum=%d 动画=%s" % [dropItemType, sunNum, "已恢复" if spriteSave.size() > 0 else "无"])
