class_name TowerDefenseProjectileRegistry

const REGISTRY_JSON: JSON = preload("res://Registry/Projectile/ProjectileRegistry.json")

static var isInit: bool = false
static var projectileDictionary: Dictionary[StringName, TowerDefenseProjectileData]
static var projectileSkinDictionary: Dictionary[StringName, TowerDefenseProjectileSkinData]
static var projectileChangeDataDictionary: Dictionary[StringName, TowerDefenseProjectileChangeData]
static var projectileMethodDictionary: Dictionary[StringName, GDScript]

static func Init() -> void :
    if isInit:
        return
    isInit = true
    RegisterInit()

static func RegisterInit() -> void :
    var data: Dictionary = REGISTRY_JSON.data

    var projectiles: Dictionary = data.get("Projectiles", {})
    for projectileName: String in projectiles:
        var projectileData = load(projectiles[projectileName]) as TowerDefenseProjectileData
        if projectileData:
            RegisterProjectile(projectileName, projectileData)

    var skins: Dictionary = data.get("Skins", {})
    for projectileName: String in skins:
        var projectileSkins: Dictionary = skins[projectileName]
        for skinName: String in projectileSkins:
            var skinData: Dictionary = projectileSkins[skinName]
            var scene: PackedScene = null
            var splat: PackedScene = null
            if skinData.has("SplatScene"):
                splat = load(skinData["SplatScene"])
            if skinData.has("ProjectileScene"):
                scene = load(skinData["ProjectileScene"])

            RegisterProjectileSkin(projectileName, skinName, scene, splat)

    var changes: Dictionary = data.get("Changes", {})
    for changeName: String in changes:
        var changeData: Dictionary = changes[changeName]
        for projectileName: String in changeData:
            RegisterProjectileChange(changeName, projectileName, changeData[projectileName])



static func RegisterProjectile(projectileName: StringName, projectileData: TowerDefenseProjectileData) -> void :
    projectileDictionary[projectileName] = projectileData
    projectileSkinDictionary[projectileName] = TowerDefenseProjectileSkinData.new()
    RegisterProjectileSkin(projectileName, &"Default", projectileData.projectileScene, projectileData.splatScene)

static func RegisterProjectileSkin(projectileName: StringName, skinName: String, skinProjectileScene: PackedScene, skinSplatScene: PackedScene) -> void :
    if !projectileSkinDictionary.has(projectileName):
        return
    projectileSkinDictionary[projectileName].AddSkin(skinName, skinProjectileScene, skinSplatScene)

static func RegisterProjectileChange(changeName: StringName, projectileName: StringName, toProjectileName: StringName) -> void :
    if !projectileChangeDataDictionary.has(changeName):
        projectileChangeDataDictionary[changeName] = TowerDefenseProjectileChangeData.new()
    projectileChangeDataDictionary[changeName].AddChange(projectileName, toProjectileName)

static func RegisterProjectileMethod(methodName: StringName, method: GDScript) -> void :
    projectileMethodDictionary[methodName] = method





static func GetProjectile(projectileName: StringName) -> TowerDefenseProjectileData:
    if !projectileDictionary.has(projectileName):
        return null
    return projectileDictionary[projectileName].duplicate()

static func HasProjectileSkin(projectileName: StringName, skinName: StringName) -> bool:
    if !projectileSkinDictionary.has(projectileName):
        return false
    return projectileSkinDictionary[projectileName].HasSkin(skinName)

static func GetProjectileSkinProjectileScene(projectileName: StringName, skinName: StringName) -> PackedScene:
    return projectileSkinDictionary[projectileName].GetSkinProjectileScene(skinName)

static func GetProjectileSkinSplatScene(projectileName: StringName, skinName: StringName) -> PackedScene:
    return projectileSkinDictionary[projectileName].GetSkinSplatScene(skinName)

static func GetProjectileChange(projectileName: StringName, changeName: StringName) -> StringName:
    if !projectileChangeDataDictionary.has(changeName):
        return &""
    return projectileChangeDataDictionary[changeName].GetChange(projectileName)

static func HasProjectileChange(changeName: StringName) -> bool:
    return projectileChangeDataDictionary.has(changeName)

static func HasChangeTarget(projectileName: StringName, changeName: StringName) -> bool:
    if !projectileChangeDataDictionary.has(changeName):
        return false
    return projectileChangeDataDictionary[changeName].HasChangeTarget(projectileName)

static func GetProjectileMethod(methodName: StringName) -> GDScript:
    if !projectileMethodDictionary.has(methodName):
        return null
    return projectileMethodDictionary[methodName]
