class_name TowerDefenseCameraControl extends Node2D

@onready var cameraBeginMarker: Marker2D = %CameraBeginMarker
@onready var cameraRightViewMarker: Marker2D = %CameraRightViewMarker
@onready var cameraPreViewMarker: Marker2D = %CameraPreViewMarker
@onready var camera: Camera2D = %Camera
@onready var downRightMarker: Marker2D = %DownRightMarker

var size: Vector2

var alive: bool = false
var cameraZoomMin: Vector2 = Vector2(1.5, 1.5)
var cameraZoomMax: Vector2 = Vector2(1.0, 1.0)

var mousePress: bool = false
var mouseSavePos: Vector2 = Vector2.ZERO

var WINDOW_WIDTH: int = ProjectSettings.get_setting("display/window/size/viewport_width")
var WINDOW_HEIGHT: int = ProjectSettings.get_setting("display/window/size/viewport_height")

func InitSize(_size: Vector2) -> void :
    size = _size
    cameraRightViewMarker.global_position.x = clamp(size.x - get_viewport().get_visible_rect().size.x, 0, cameraRightViewMarker.global_position.x)
    cameraPreViewMarker.global_position.x = clamp(size.x - get_viewport().get_visible_rect().size.x - 56, 0, cameraPreViewMarker.global_position.x)
