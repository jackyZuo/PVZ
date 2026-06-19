extends DialogPopup

func TrueButtonPressed() -> void :
    match Global.enterLevelMode:
        "OnlineLevel":
            InternetServerManager.OnlineLevelPost(Global.enterLevelId, "failure")
    SceneManager.ReloadScene(true)


func FalseButtonPressed() -> void :
    Close()
