


class_name PhonkComponent extends ComponentBase


static var phonkEnabled: bool = false

static var phonkIntensity: float = 1.0


var parent: TowerDefenseCharacter



var stiffness: float = 800.0

var damping: float = 3.5

var rotStiffness: float = 1400.0

var rotDamping: float = 5.0

var maxScaleDeform: float = 0.6
var maxRotDeform: float = 0.5


var hurtIntensity: float = 1.2
var dieIntensity: float = 1.8
var attackIntensity: float = 0.6
var produceIntensity: float = 0.5
var plantIntensity: float = 0.8


var _scaleX: float = 0.0
var _scaleY: float = 0.0
var _rotVal: float = 0.0
var _velX: float = 0.0
var _velY: float = 0.0
var _velRot: float = 0.0


var _active: bool = false



var hurtCooldown: float = 0.5
var _lastHurtTime: float = -1.0


var _fireComponent: FireComponent
var _produceComponent: ProduceComponent


func GetName() -> String:
    return "PhonkComponent"


func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

    parent.destroy.connect(_OnCharacterDestroy)
    parent.bodyHurt.connect(_OnBodyHurt)
    parent.armorHurt.connect(_OnArmorHurt)
    parent.riseOver.connect(_OnRiseOver)

    _ConnectOptionalComponents()


func _ConnectOptionalComponents() -> void :
    if !is_instance_valid(parent) || !is_instance_valid(parent.componentManager):
        return
    _fireComponent = parent.componentManager.GetComponentFromType("FireComponent")
    if is_instance_valid(_fireComponent):
        _fireComponent.fireProjectile.connect(_OnFireProjectile)
    _produceComponent = parent.componentManager.GetComponentFromType("ProduceComponent")
    if is_instance_valid(_produceComponent):
        _produceComponent.product.connect(_OnProduct)


func _exit_tree() -> void :
    if is_instance_valid(parent):
        if parent.destroy.is_connected(_OnCharacterDestroy):
            parent.destroy.disconnect(_OnCharacterDestroy)
        if parent.bodyHurt.is_connected(_OnBodyHurt):
            parent.bodyHurt.disconnect(_OnBodyHurt)
        if parent.armorHurt.is_connected(_OnArmorHurt):
            parent.armorHurt.disconnect(_OnArmorHurt)
        if parent.riseOver.is_connected(_OnRiseOver):
            parent.riseOver.disconnect(_OnRiseOver)
    if is_instance_valid(_fireComponent) && _fireComponent.fireProjectile.is_connected(_OnFireProjectile):
        _fireComponent.fireProjectile.disconnect(_OnFireProjectile)
    if is_instance_valid(_produceComponent) && _produceComponent.product.is_connected(_OnProduct):
        _produceComponent.product.disconnect(_OnProduct)
    _active = false
    _ResetTransform()


func _OnBodyHurt(_num: int) -> void :
    if !phonkEnabled || !alive:
        return

    var needCooldown: bool = !(parent is TowerDefenseZombie) || parent.nearDie
    if needCooldown:
        var now: float = Time.get_ticks_msec() / 1000.0
        if now - _lastHurtTime < hurtCooldown:
            return
        _lastHurtTime = now
    Impulse(hurtIntensity * phonkIntensity)


func _OnArmorHurt(_num: int) -> void :
    if !phonkEnabled || !alive:
        return
    var needCooldown2: bool = !(parent is TowerDefenseZombie) || parent.nearDie
    if needCooldown2:
        var now2: float = Time.get_ticks_msec() / 1000.0
        if now2 - _lastHurtTime < hurtCooldown:
            return
        _lastHurtTime = now2
    Impulse(hurtIntensity * phonkIntensity)


func _OnCharacterDestroy(_character: TowerDefenseCharacter) -> void :
    if !phonkEnabled || !alive:
        return
    Impulse(dieIntensity * phonkIntensity)


func _OnRiseOver() -> void :
    if !phonkEnabled || !alive:
        return
    Impulse(plantIntensity * phonkIntensity)


func _OnFireProjectile(_projectile: TowerDefenseProjectile) -> void :
    if !phonkEnabled || !alive:
        return
    Impulse(attackIntensity * phonkIntensity)


func _OnProduct(_pos: int, _num: int) -> void :
    if !phonkEnabled || !alive:
        return
    Impulse(produceIntensity * phonkIntensity)


func PlayHurtPhonk() -> void :
    if !phonkEnabled || !alive:
        return
    Impulse(hurtIntensity * phonkIntensity)



func Impulse(force: float = 1.0) -> void :
    if !phonkEnabled || !alive:
        return
    if !is_instance_valid(parent) || !is_instance_valid(parent.transformPoint):
        return

    var dirX: float = (1.0 if randf() > 0.5 else -1.0) * randf_range(0.5, 1.0)
    var dirY: float = - dirX * randf_range(0.5, 1.0)
    var dirRot: float = (1.0 if randf() > 0.5 else -1.0) * randf_range(0.5, 1.0)
    var randMul: float = randf_range(0.8, 1.3)

    _velX += force * 8.0 * dirX * randMul
    _velY += force * 6.0 * dirY * randMul
    _velRot += force * 7.0 * dirRot * randMul
    _active = true


func _physics_process(_delta: float) -> void :
    if !_active || !is_instance_valid(parent) || !is_instance_valid(parent.transformPoint):
        return


    _velX += ( - stiffness * _scaleX - damping * _velX) * _delta
    _velY += ( - stiffness * _scaleY - damping * _velY) * _delta
    _velRot += ( - rotStiffness * _rotVal - rotDamping * _velRot) * _delta

    _scaleX += _velX * _delta
    _scaleY += _velY * _delta
    _rotVal += _velRot * _delta


    _scaleX = clampf(_scaleX, - maxScaleDeform, maxScaleDeform)
    _scaleY = clampf(_scaleY, - maxScaleDeform, maxScaleDeform)
    _rotVal = clampf(_rotVal, - maxRotDeform, maxRotDeform)


    var targetScale: = Vector2(1.0 + _scaleX, 1.0 + _scaleY)
    var targetRot: float = _rotVal
    var lerpFactor: float = minf(_delta * 25.0, 1.0)
    parent.transformPoint.scale = parent.transformPoint.scale.lerp(targetScale, lerpFactor)
    parent.transformPoint.rotation = lerpf(parent.transformPoint.rotation, targetRot, lerpFactor)


    if absf(_scaleX) < 0.001 && absf(_scaleY) < 0.001 && absf(_rotVal) < 0.001\
&& absf(_velX) < 0.01 && absf(_velY) < 0.01 && absf(_velRot) < 0.01:
        _active = false
        _ResetTransform()


func _ResetTransform() -> void :
    _scaleX = 0.0
    _scaleY = 0.0
    _rotVal = 0.0
    _velX = 0.0
    _velY = 0.0
    _velRot = 0.0
    if is_instance_valid(parent) && is_instance_valid(parent.transformPoint):
        parent.transformPoint.scale = Vector2.ONE
        parent.transformPoint.rotation = 0.0


func SetAlive(_alive: bool) -> void :
    super.SetAlive(_alive)
    if !_alive:
        _active = false
        _ResetTransform()




static func InjectToCharacter(character: TowerDefenseCharacter) -> void :
    if !is_instance_valid(character) || !is_instance_valid(character.componentManager):
        return
    if character.componentManager.GetComponentFromType("PhonkComponent") != null:
        return
    var comp: = PhonkComponent.new()
    comp.name = "PhonkComponent"
    character.componentManager.add_child(comp)
    character.componentManager.componentList.append(comp)
    if !character.componentManager.componentDictionary.has("PhonkComponent"):
        character.componentManager.componentDictionary["PhonkComponent"] = []
    character.componentManager.componentDictionary["PhonkComponent"].append(comp)
    character.phonkComponent = comp


static func RemoveFromCharacter(character: TowerDefenseCharacter) -> void :
    if !is_instance_valid(character) || !is_instance_valid(character.componentManager):
        return
    var comp: ComponentBase = character.componentManager.GetComponentFromType("PhonkComponent")
    if comp == null:
        return
    character.componentManager.componentList.erase(comp)
    if character.componentManager.componentDictionary.has("PhonkComponent"):
        character.componentManager.componentDictionary["PhonkComponent"].erase(comp)
    character.phonkComponent = null
    if is_instance_valid(character.transformPoint):
        character.transformPoint.scale = Vector2.ONE
        character.transformPoint.rotation = 0.0
    comp.queue_free()


static func InjectAll() -> void :
    var tree: SceneTree = Engine.get_main_loop() as SceneTree
    for character in tree.get_nodes_in_group("Plant"):
        if is_instance_valid(character) && character is TowerDefenseCharacter:
            InjectToCharacter(character)
    for character in tree.get_nodes_in_group("Zombie"):
        if is_instance_valid(character) && character is TowerDefenseCharacter:
            InjectToCharacter(character)


static func RemoveAll() -> void :
    var tree: SceneTree = Engine.get_main_loop() as SceneTree
    for character in tree.get_nodes_in_group("Plant"):
        if is_instance_valid(character) && character is TowerDefenseCharacter:
            RemoveFromCharacter(character)
    for character in tree.get_nodes_in_group("Zombie"):
        if is_instance_valid(character) && character is TowerDefenseCharacter:
            RemoveFromCharacter(character)
