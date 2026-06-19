class_name TowerDefenseProjectileSkinData extends RefCounted

var skinList: Array[StringName]
var skinProjectileSceneDictionary: Dictionary[StringName, PackedScene]
var skinSplatSceneDictionary: Dictionary[StringName, PackedScene]

func AddSkin(skinName: StringName, projectileScene: PackedScene, splatScene: PackedScene) -> void :
    skinProjectileSceneDictionary[skinName] = projectileScene
    skinSplatSceneDictionary[skinName] = splatScene
    skinList.append(skinName)

func GetSkinProjectileScene(skinName: StringName) -> PackedScene:
    if !HasSkin(skinName):
        return null
    return skinProjectileSceneDictionary[skinName]

func GetSkinSplatScene(skinName: StringName) -> PackedScene:
    if !HasSkin(skinName):
        return null
    return skinSplatSceneDictionary[skinName]

func HasSkin(skinName: StringName) -> bool:
    return skinList.has(skinName)

func IsEmpty() -> bool:
    return skinList.size() > 0
