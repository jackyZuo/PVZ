@tool
class_name CharacterCustomConfig extends Resource

@export var openKey: String = ""
@export var customName: String = ""
@export_enum("White", "Gold") var type: String = "White"

@export var customHandbookName: String = ""
@export var customHandbookAccess: String = ""
@export var customHandbookStory: String = ""

@export_multiline var animeFliterOpen: String = "":
    set(_animeFliterOpen):
        animeFliterOpen = _animeFliterOpen
        emit_changed()
@export_multiline var animeFliterClose: String = "":
    set(_animeFliterClose):
        animeFliterClose = _animeFliterClose
        emit_changed()

@export var damagePointChangeMediaName: String = ""
@export var damagePointChangeMediaTexture: Array[Texture2D]
