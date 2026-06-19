class_name TowerDefenseBattleFeatureNpcTalk extends TowerDefenseBattleFeature

const NPC_TALK_CONTROL = preload("uid://cjc8tc43kdv47")

const NPC_CRAZY_DAVE = preload("uid://cvadcalsore2n")

signal talkFinish()
signal finish()

var npcTalkControl: NpcTalkControl
var config: NpcTalkConfig
var currentIndex: int = 0
var npcDictionary: Dictionary = {}

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    npcTalkControl = NPC_TALK_CONTROL.instantiate()
    npcTalkControl.npcTalkFeature = self
    control.AddUI(npcTalkControl, 4)

    var isCustom: bool = data.get("isCustom", false)
    if !isCustom:
        var talkName: String = data.get("TalkName", "")
        if talkName != "":
            config = TowerDefenseManager.GetNpcTalk(talkName)
            config.Init()
    else:
        config = NpcTalkConfig.new()
        config.Load(data)

func GameInit() -> void :
    pass

func StartTalk() -> void :
    if !is_instance_valid(config):
        talkFinish.emit()
        return
    var npcTalkGet: bool = false
    if config.saveKey != "":
        npcTalkGet = GameSaveManager.GetTutorialValue(config.saveKey)
    if !npcTalkGet:
        await control.get_tree().create_timer(1.5, false).timeout
        var bgmFeature = GetFeature("BGM")
        if bgmFeature:
            bgmFeature.StopBGM()
            bgmFeature.backgroundAudio = AudioManager.AudioPlay("MainMenu", AudioManagerEnum.TYPE.MUSIC)
        currentIndex = 0
        TalkNext()
        await finish

    talkFinish.emit()

func TalkNext() -> void :
    if currentIndex < config.talkList.size():
        var talk: NpcTalkBaseConfig = config.talkList[currentIndex]
        var npc: NpcBase = await GetNpc(talk.npc)
        npcTalkControl.ShowTalk(npc, talk)
        if talk is NpcTalkHandConfig:
            npcTalkControl.ShowHand(npc, talk)
        if talk.anime == "Leave":
            if npcDictionary.has(talk.npc):
                var oldNpc: NpcBase = npcDictionary[talk.npc]
                if is_instance_valid(oldNpc) && finish.is_connected(oldNpc.Finish):
                    finish.disconnect(oldNpc.Finish)
                npcDictionary.erase(talk.npc)
            if talk is NpcTalkTutorialConfig:
                TutorialManager.TutorialEnter(talk.tutorial)
                await TutorialManager.tutorialFinish
        elif talk is NpcTalkTutorialConfig:
            TutorialManager.TutorialEnter(talk.tutorial)
            await TutorialManager.tutorialFinish
            if is_instance_valid(npc):
                await npc.talkNext
        elif is_instance_valid(npc):
            await npc.talkNext

        currentIndex += 1
        TalkNext()
    else:
        finish.emit()

func GetNpc(npcName: String = "CrazyDave") -> NpcBase:
    if npcDictionary.has(npcName):
        if !is_instance_valid(npcDictionary[npcName]):
            npcDictionary.erase(npcName)
    if !npcDictionary.has(npcName):
        match npcName:
            "CrazyDave":
                var instance = NPC_CRAZY_DAVE.instantiate() as NpcBase
                npcTalkControl.AddNpc(instance)
                npcDictionary["CrazyDave"] = instance
                finish.connect(instance.Finish)
                await instance.npcReady
    return npcDictionary[npcName]

func GameEntry() -> void :
    if !control.hasProgress:
        var levelConfig: TowerDefenseLevelConfig = control.levelConfig
        if levelConfig.talk != "" || levelConfig.isCustomTalk:
            Init({
                "talk": levelConfig.talk, 
                "isCustomTalk": levelConfig.isCustomTalk, 
                "customTalk": levelConfig.customTalk
            })
            await StartTalk()
