
class_name ShovelCommand


static var currentShovel: String = ""


static func ListShovels() -> void :
    var shovelList: Array = TowerDefenseManager.GetShovelList()
    var current: String = _GetCurrentShovel()
    CommandConsole.PrintLine("[color=cyan]═══════ 铲子列表 ═══════[/color]")
    for shovelName: String in shovelList:
        var config: ShovelConfig = TowerDefenseManager.GetShovel(shovelName)
        var isCurrent: bool = shovelName == current
        var prefix: String = "[color=green]►[/color] " if isCurrent else "  "
        var shovelInfo: String = String(TranslationServer.translate(config.name)) if config else shovelName
        CommandConsole.PrintLine("%s%s [color=gray](%s)[/color]" % [prefix, shovelInfo, shovelName])


static func ChangeShovel(shovelName: String) -> void :
    var shovelConfig: ShovelConfig = TowerDefenseManager.GetShovel(shovelName)
    if !shovelConfig:
        CommandConsole.PrintError("未找到铲子: %s  输入 /shovel list 查看所有铲子" % shovelName)
        return
    currentShovel = shovelName
    GameSaveManager.SetKeyValue("CurrentShovel", shovelName)
    _UpdateShovelManager(shovelConfig)
    CommandConsole.PrintSuccess("已更换铲子: %s" % String(TranslationServer.translate(shovelConfig.name)))




static func GetShovelNames() -> Array:
    var result: Array = ["list"]
    result.append_array(TowerDefenseManager.GetShovelList())
    return result


static func _GetCurrentShovel() -> String:
    if currentShovel == "":
        currentShovel = GameSaveManager.GetKeyValue("CurrentShovel")
        if !currentShovel:
            currentShovel = "ShovelDefault"
    return currentShovel


static func _UpdateShovelManager(shovelConfig: ShovelConfig) -> void :
    var currentControl = TowerDefenseManager.currentControl
    if !is_instance_valid(currentControl):
        return
    var shovelFeature: TowerDefenseBattleFeatureShovel = currentControl.GetFeature("Shovel")
    if !is_instance_valid(shovelFeature) || !is_instance_valid(shovelFeature.shovelManager):
        return
    shovelFeature.shovelManager.shovelConfig = shovelConfig
    if is_instance_valid(shovelFeature.shovelManager.shovelSprite):
        shovelFeature.shovelManager.shovelSprite.texture = shovelConfig.texture
    if is_instance_valid(shovelFeature.shovelManager.mapShovelSprite):
        shovelFeature.shovelManager.mapShovelSprite.texture = shovelConfig.texture
