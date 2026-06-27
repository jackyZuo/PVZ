@tool
extends TowerDefensePlant

var over: bool = false
var run: bool = false

func SleepEntered() -> void :
    super.SleepEntered()
    instance.invincible = false

func IdleEntered() -> void :
    super.IdleEntered()
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if CanSleep():
        Sleep()
        return
    instance.invincible = true
    sprite.SetAnimation("Idle", false, 0.2)
    run = true

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale * 1.0
    if TowerDefenseManager.IsIZMMode():
        timeScaleInit = timeScaleSave

func IdleExited() -> void :
    super.IdleExited()

func AnimeCompleted(clip: String) -> void :
    if !inGame:
        return
    super.AnimeCompleted(clip)
    match clip:
        "Idle":
            if !run:
                return
            if over:
                return
            over = true
            gridPos = TowerDefenseManager.GetMapGridPos(global_position)
            CreateColdEffect(camp, gridPos)
            var seedBankList = TowerDefenseManager.GetSeedBankList()
            for packetShow: TowerDefenseInGamePacketShow in seedBankList:
                var identifyKey: String = packetShow.originalSaveKey if packetShow.originalSaveKey != "" else packetShow.config.saveKey
                if identifyKey == packet.saveKey:
                    var baseCooldown: float = packetShow.config.characterConfig.packetCooldown
                    packetShow.coldDownTimer += 50.0
                    if packetShow.config.overridePacketCooldown == -1:
                        packetShow.config.overridePacketCooldown = baseCooldown + 50.0
                    else:
                        packetShow.config.overridePacketCooldown += 50.0
                else:
                    packetShow.coldDownTimer = 0.0
            Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "run": run, 
        "over": over
    }

func ImportVariantSave(data: Dictionary) -> void :
    run = data.get("run", false)
    over = data.get("over", false)
