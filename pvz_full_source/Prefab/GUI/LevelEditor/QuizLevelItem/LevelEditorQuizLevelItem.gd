extends Control

@onready var nameLabel: Label = %NameLabel
@onready var mapTexture: TextureRect = %MapTexture

var map: String
var levelConfig: TowerDefenseLevelConfig

func Init(_map: String) -> void :
    map = _map
    var mapConfig: TowerDefenseMapConfig = TowerDefenseManager.GetMapConfig(map)
    mapTexture.texture = mapConfig.mapTexture
    nameLabel.text = mapConfig.translate
