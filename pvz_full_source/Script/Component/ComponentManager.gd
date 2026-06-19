
class_name ComponentManager extends Node2D


@export var componentList: Array[ComponentBase] = []

@export var componentDictionary: Dictionary[String, Array] = {}


var parent: Node


func _enter_tree() -> void :
    parent = get_parent()


func _ready() -> void :
    for child in get_children():
        if child is ComponentBase:
            componentList.append(child)
            if !componentDictionary.has(child.GetName()):
                componentDictionary[child.GetName()] = []
            componentDictionary[child.GetName()].append(child)




func GetComponentFromName(_name: String) -> ComponentBase:
    for component: ComponentBase in componentList:
        if component.name == _name:
            return component
    return null





func GetComponentFromType(_type: String, id: int = 0) -> ComponentBase:
    if componentDictionary.has(_type):
        var list = componentDictionary[_type]
        if list.size() > id:
            return list[id]
    return null
