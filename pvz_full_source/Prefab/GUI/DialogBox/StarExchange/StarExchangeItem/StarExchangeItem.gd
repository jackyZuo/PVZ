class_name StarExchangeItem extends Control

@onready var costLabel: Label = %CostLabel
@onready var button: Button = %Button
@onready var packetNode: Control = %PacketNode
@onready var packet: TowerDefenseInGamePacketShow = %Packet
@onready var finishTexture: TextureRect = %FinishTexture

var data: Dictionary

var finishNum: int = 0

func Init(_data: Dictionary, _finishNum: int = 0) -> void :
    data = _data
    finishNum = _finishNum
    match data["Type"]:
        "Packet":
            packet.Init(TowerDefenseManager.GetPacketConfig(data["Key"]))
    costLabel.text = "x%d" % data["FinishNum"]

    if finishNum >= data["FinishNum"]:
        var packetValue = GameSaveManager.GetTowerDefensePacketValue(data["Key"])
        if packetValue.get_or_add("Unlock", false):
            finishTexture.visible = true

func Pressed() -> void :
    if finishNum >= data["FinishNum"]:
        var packetValue = GameSaveManager.GetTowerDefensePacketValue(data["Key"])
        if !packetValue.get_or_add("Unlock", false):
            packetValue["Unlock"] = true
            finishTexture.visible = true
            GameSaveManager.SetTowerDefensePacketValue(data["Key"], packetValue)
            GameSaveManager.Save()
            var dialog = DialogManager.DialogCreate("DialogBoxTips")
            dialog.text = "[center][font_size=24]您成功兑换该植物[/font_size][/center]"
        else:
            var dialog = DialogManager.DialogCreate("DialogBoxTips")
            dialog.text = "[center][font_size=24]您已经兑换该植物[/font_size][/center]"
    else:
        var dialog = DialogManager.DialogCreate("DialogBoxTips")
        dialog.text = "[center][font_size=24]您的星星不足[/font_size][/center]"
