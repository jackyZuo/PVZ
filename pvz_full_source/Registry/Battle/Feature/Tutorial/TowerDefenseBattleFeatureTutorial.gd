class_name TowerDefenseBattleFeatureTutorial extends TowerDefenseBattleFeature

var config: TutorialConfig

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    var isCustom: bool = data.get("isCustom", false)
    if !isCustom:
        var tutorialName: String = data.get("TutorialName", "")
        if tutorialName != "":
            config = TowerDefenseManager.GetTutorial(tutorialName)
            config.Init()
    else:
        config = TutorialConfig.new()
        config.Load(data)

func GameStart() -> void :
    if is_instance_valid(config):
        if config.saveKey != "" && GameSaveManager.GetTutorialValue(config.saveKey):
            return
        TutorialManager.TutorialEnter(config)
        await TutorialManager.tutorialFinish

func GameStartFromProgress() -> void :
    pass
