class_name TowerDefenseProjectilePool

const MAX_POOL_SIZE_PER_SCENE: int = 100
const META_SCENE_KEY: String = "_projectile_pool_scene"

static var _pools: Dictionary = {}

static func Pop(scene: PackedScene, parent: Node) -> Node2D:
    var sceneId: int = scene.get_instance_id()
    var node: Node2D
    if _pools.has(sceneId) && _pools[sceneId].size() > 0:
        node = _pools[sceneId].pop_back()
        var currentParent: Node = node.get_parent()
        if is_instance_valid(currentParent):
            if currentParent != parent:
                node.reparent(parent)
        else:
            parent.add_child(node)
    else:
        node = scene.instantiate() as Node2D
        node.set_meta(META_SCENE_KEY, sceneId)
        parent.add_child(node)
    return node

static func Push(node: Node) -> void :
    if !is_instance_valid(node):
        return
    if !node.has_meta(META_SCENE_KEY):
        return
    var sceneId: int = node.get_meta(META_SCENE_KEY)
    var currentParent: Node = node.get_parent()
    if is_instance_valid(currentParent):
        currentParent.remove_child(node)
    if node is Node2D:
        node.visible = true
        node.rotation = 0.0
        node.scale = Vector2.ONE
        node.position = Vector2.ZERO
    if !_pools.has(sceneId):
        _pools[sceneId] = []
    if _pools[sceneId].size() < MAX_POOL_SIZE_PER_SCENE:
        _pools[sceneId].append(node)
    else:
        node.queue_free()

static func Clear() -> void :
    for sceneId in _pools:
        for node in _pools[sceneId]:
            if is_instance_valid(node) && !node.is_queued_for_deletion():
                node.queue_free()
    _pools.clear()

static func GetPoolSize(scene: PackedScene) -> int:
    var sceneId: int = scene.get_instance_id()
    if !_pools.has(sceneId):
        return 0
    return _pools[sceneId].size()

static func GetTotalPoolSize() -> int:
    var total: int = 0
    for sceneId in _pools:
        total += _pools[sceneId].size()
    return total
