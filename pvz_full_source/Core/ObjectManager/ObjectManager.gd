extends Node2D

var poolList: Array[PoolConfig] = []

func _ready() -> void :
    poolList.resize(ObjectManagerConfig.OBJECT.MAX)

    for i in range(ObjectManagerConfig.OBJECT.MAX):
        poolList[i] = null

    PoolCreate(preload("uid://dyrv5jg4hiu2l"), ObjectManagerConfig.OBJECT.PROJECTILE, 4000, "Refresh", "Recycle")
    PoolCreate(preload("uid://bct1gvf1i8ohw"), ObjectManagerConfig.OBJECT.DAMAGEPART, 200, "Refresh", "Recycle")

    PoolCreate(preload("uid://dk3bkihnh1i0l"), ObjectManagerConfig.OBJECT.SUN, 100, "Refresh", "Recycle")
    PoolCreate(preload("uid://d161xee5m0kkw"), ObjectManagerConfig.OBJECT.SUN_BRAIN, 100, "Refresh", "Recycle")
    PoolCreate(preload("uid://da7lvlco511ds"), ObjectManagerConfig.OBJECT.SUN_JALAPENO, 100, "Refresh", "Recycle")

    PoolCreate(preload("uid://csynbfevdbiju"), ObjectManagerConfig.OBJECT.COIN_SILVER, 100, "Refresh", "Recycle")
    PoolCreate(preload("uid://kbif4idtgolo"), ObjectManagerConfig.OBJECT.COIN_GOLD, 100, "Refresh", "Recycle")
    PoolCreate(preload("uid://6b78y08u52f5"), ObjectManagerConfig.OBJECT.COIN_DIAMOND, 100, "Refresh", "Recycle")
    PoolCreate(preload("uid://bnrh1k2cgopsn"), ObjectManagerConfig.OBJECT.COIN_LUCKY_BAG, 100, "Refresh", "Recycle")
    PoolCreate(preload("uid://733w81lrellb"), ObjectManagerConfig.OBJECT.COIN_TQ, 100, "Refresh", "Recycle")
    PoolCreate(preload("uid://c25ngfvpp0uo3"), ObjectManagerConfig.OBJECT.COIN_YB1, 100, "Refresh", "Recycle")
    PoolCreate(preload("uid://1twddwaolt4r"), ObjectManagerConfig.OBJECT.COIN_YB2, 100, "Refresh", "Recycle")
    PoolCreate(preload("uid://dsfn18qda4271"), ObjectManagerConfig.OBJECT.COIN_GOLD_SHARD, 100, "Refresh", "Recycle")

    PoolCreate(preload("uid://ueeii5v2dl8q"), ObjectManagerConfig.OBJECT.PARTICLES_SPLASH, 500, "Refresh", "Recycle")
    PoolCreate(preload("uid://lcop8me7nwde"), ObjectManagerConfig.OBJECT.PARTICLES_RISE_DIRT, 200, "Refresh", "Recycle")
    PoolCreate(preload("uid://b0wigigia32ny"), ObjectManagerConfig.OBJECT.PARTICLES_ICE_TRAP, 200, "Refresh", "Recycle")


func Clear() -> void :
    TowerDefenseProjectilePool.Clear()
    for i in range(poolList.size()):
        var pool = poolList[i]
        if is_instance_valid(pool):
            pool.Clear()

func PoolCreate(scene: PackedScene, id: ObjectManagerConfig.OBJECT, maxNum: int, popCallable: String = "", pushCallable: String = "") -> PoolConfig:

    if id < 0 or id >= ObjectManagerConfig.OBJECT.MAX:
        push_error("Invalid pool ID: " + str(id))
        return null


    if poolList[id] != null:
        poolList[id].Clear()


    var pool = PoolConfig.new()
    pool.scene = scene
    pool.maxNum = maxNum
    pool.popCallable = popCallable
    pool.pushCallable = pushCallable
    poolList[id] = pool
    return pool

func PoolPush(id: ObjectManagerConfig.OBJECT, node: Node) -> void :

    if !is_instance_valid(node):
        return
    if id < 0 or id >= ObjectManagerConfig.OBJECT.MAX:
        push_error("Invalid pool ID: " + str(id))
        return
    if poolList[id] == null:
        push_error("Pool not initialized for ID: " + str(id))
        return
    poolList[id].Push(node)

func PoolPop(id: ObjectManagerConfig.OBJECT, parent: Node) -> Node:

    if !is_instance_valid(parent):
        return null
    if id < 0 or id >= ObjectManagerConfig.OBJECT.MAX:
        push_error("Invalid pool ID: " + str(id))
        return null
    if poolList[id] == null:
        push_error("Pool not initialized for ID: " + str(id))
        return null
    return poolList[id].Pop(parent)
