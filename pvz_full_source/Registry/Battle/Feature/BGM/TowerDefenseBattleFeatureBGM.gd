class_name TowerDefenseBattleFeatureBGM extends TowerDefenseBattleFeature

var backgroundAudio: AudioStreamPlayerMember
var backgroundDrumsAudio: AudioStreamPlayerMember
var backgroundMusicConfig: TowerDefenseBackgroundMusicConfig

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    var backgroundMusic: String = data.get("BackgroundMusic", "")
    if backgroundMusic != "":
        backgroundMusicConfig = TowerDefenseManager.GetBackgroundMusicConfig(backgroundMusic)

func Process(delta: float) -> void :
    if is_instance_valid(backgroundDrumsAudio):
        if TowerDefenseManager.GetZombie().size() >= 10:
            backgroundDrumsAudio.volumeScale = lerpf(backgroundDrumsAudio.volumeScale, 1.0, delta * 1.0)
        else:
            backgroundDrumsAudio.volumeScale = lerpf(backgroundDrumsAudio.volumeScale, 0.0, delta * 1.0)

func GameEntry() -> void :
    PlayEntryBGM()

func GameStart() -> void :
    StopBGM()
    if is_instance_valid(backgroundMusicConfig):
        if backgroundMusicConfig.flag1 != "":
            backgroundAudio = AudioManager.AudioPlay(backgroundMusicConfig.flag1, AudioManagerEnum.TYPE.MUSIC, 0.0, false, false)
        if backgroundMusicConfig.drums != "":
            backgroundDrumsAudio = AudioManager.AudioPlay(backgroundMusicConfig.drums, AudioManagerEnum.TYPE.MUSIC, 0.0, false, false)
            backgroundDrumsAudio.volumeScale = 0.0

func GameReady() -> void :
    StopBGM()

func PlayEntryBGM() -> void :
    if is_instance_valid(backgroundMusicConfig):
        if is_instance_valid(backgroundAudio):
            backgroundAudio.stop()
        if is_instance_valid(backgroundDrumsAudio):
            backgroundDrumsAudio.stop()
        if backgroundMusicConfig.entry != "":
            backgroundAudio = AudioManager.AudioPlay(backgroundMusicConfig.entry, AudioManagerEnum.TYPE.MUSIC, 0.0, false, false)

func StopBGM() -> void :
    if is_instance_valid(backgroundAudio):
        backgroundAudio.stop()
    if is_instance_valid(backgroundDrumsAudio):
        backgroundDrumsAudio.stop()
