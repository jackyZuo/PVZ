class_name TowerDefenseBattleProcessEmpty extends TowerDefenseBattleProcess

var seedBankFeature: TowerDefenseBattleFeatureSeedBank
var cameraFeature: TowerDefenseBattleFeatureCamera

func Init(_data: Dictionary) -> void :
    super.Init(_data)

func Ready() -> void :
    seedBankFeature = GetFeature("SeedBank")
    cameraFeature = GetFeature("Camera")

func GameInit() -> void :
    pass

func GameEntry() -> void :
    if seedBankFeature:
        seedBankFeature.seedBank.packetSlotContainer.visible = true
    if GameSaveManager.GetConfigValue("MobilePreset"):
        control.uiTopAnimationPlayer.play("MobileEnter")
    else:
        control.uiTopAnimationPlayer.play("Enter")

func GameReady() -> void :
    if seedBankFeature:
        seedBankFeature.seedBank.Ready()

func GameStart() -> void :
    if seedBankFeature:
        seedBankFeature.seedBank.StartFromProgress()

func CheckFinal() -> bool:
    return false

func CheckFail() -> bool:
    return false

func ZombieEnterHouse(character: TowerDefenseCharacter) -> void :
    character.Destroy()
