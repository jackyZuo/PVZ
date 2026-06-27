@tool
extends EditorPlugin

const REGISTRY_PATH: String = "res://Registry/Projectile/ProjectileRegistry.json"

var editor_control: HSplitContainer

var search_line: LineEdit
var button_refresh: Button
var projectile_list: ItemList
var label_name: Label
var button_save: Button
var button_add: Button
var button_rename: Button
var skins_section: VBoxContainer
var changes_section: VBoxContainer
var preview_container: HBoxContainer

var registry_data: Dictionary = {}
var projectile_names: PackedStringArray = []
var projectile_uids: Dictionary = {}

var current_projectile_name: String = ""
var current_data: TowerDefenseProjectileData

func _enter_tree() -> void :
    _BuildUI()
    EditorInterface.get_editor_main_screen().add_child(editor_control)
    _make_visible(false)

func _exit_tree() -> void :
    if is_instance_valid(editor_control):
        editor_control.queue_free()

func _has_main_screen() -> bool:
    return true

func _get_plugin_name() -> String:
    return "Projectile"

func _make_visible(visible: bool) -> void :
    if is_instance_valid(editor_control):
        editor_control.visible = visible
    if not visible:
        EditorInterface.edit_resource(null)

func _BuildUI() -> void :
    editor_control = HSplitContainer.new()
    editor_control.split_offset = 250
    editor_control.name = "ProjectileEditor"
    editor_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    editor_control.size_flags_vertical = Control.SIZE_EXPAND_FILL

    var left_panel: VBoxContainer = VBoxContainer.new()
    left_panel.name = "LeftPanel"
    left_panel.custom_minimum_size = Vector2(250, 0)
    left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

    search_line = LineEdit.new()
    search_line.name = "SearchLine"
    search_line.placeholder_text = "Search projectile..."
    left_panel.add_child(search_line)

    button_refresh = Button.new()
    button_refresh.name = "ButtonRefresh"
    button_refresh.text = "Refresh"
    left_panel.add_child(button_refresh)

    projectile_list = ItemList.new()
    projectile_list.name = "ProjectileList"
    projectile_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    projectile_list.icon_mode = ItemList.ICON_MODE_LEFT
    projectile_list.fixed_icon_size = Vector2(24, 24)
    left_panel.add_child(projectile_list)

    editor_control.add_child(left_panel)

    var right_panel: VBoxContainer = VBoxContainer.new()
    right_panel.name = "RightPanel"
    right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

    var header: HBoxContainer = HBoxContainer.new()
    header.name = "Header"

    label_name = Label.new()
    label_name.name = "LabelName"
    label_name.text = "Select a projectile"
    label_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(label_name)

    button_save = Button.new()
    button_save.name = "ButtonSave"
    button_save.text = "Save"
    header.add_child(button_save)

    button_add = Button.new()
    button_add.name = "ButtonAdd"
    button_add.text = "+"
    header.add_child(button_add)

    button_rename = Button.new()
    button_rename.name = "ButtonRename"
    button_rename.text = "Rename"
    header.add_child(button_rename)

    right_panel.add_child(header)

    preview_container = HBoxContainer.new()
    preview_container.name = "PreviewContainer"
    preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_panel.add_child(preview_container)

    skins_section = VBoxContainer.new()
    skins_section.name = "SkinsSection"
    skins_section.visible = false
    right_panel.add_child(skins_section)

    changes_section = VBoxContainer.new()
    changes_section.name = "ChangesSection"
    changes_section.visible = false
    right_panel.add_child(changes_section)

    editor_control.add_child(right_panel)

    search_line.text_changed.connect(_on_search_text_changed)
    button_refresh.pressed.connect(_on_refresh_pressed)
    projectile_list.item_selected.connect(_on_item_selected)
    button_save.pressed.connect(_on_save_pressed)
    button_add.pressed.connect(_on_add_pressed)
    button_rename.pressed.connect(_on_rename_pressed)

    LoadRegistry()

func _on_refresh_pressed() -> void :
    LoadRegistry()

func LoadRegistry() -> void :
    if not FileAccess.file_exists(REGISTRY_PATH):
        push_warning("[ProjectileEditor] Registry file not found: %s" % REGISTRY_PATH)
        return
    var file: FileAccess = FileAccess.open(REGISTRY_PATH, FileAccess.READ)
    var json_text: String = file.get_as_text()
    file.close()
    var json: JSON = JSON.new()
    var err: int = json.parse(json_text)
    if err != OK:
        push_warning("[ProjectileEditor] JSON parse error: %s (line %s)" % [json.get_error_message(), json.get_error_line()])
        return
    if not json.data is Dictionary:
        push_warning("[ProjectileEditor] JSON data is not a Dictionary")
        return
    registry_data = json.data
    projectile_list.clear()
    projectile_names.clear()
    projectile_uids.clear()
    var projectiles: Dictionary = registry_data.get("Projectiles", {})
    for projectile_name: String in projectiles:
        projectile_names.append(projectile_name)
        projectile_uids[projectile_name] = projectiles[projectile_name]
    projectile_names.sort()
    _RefreshList("")

func _RefreshList(filter: String) -> void :
    projectile_list.clear()
    for i: int in projectile_names.size():
        var pname: String = projectile_names[i]
        if filter.is_empty() or pname.findn(filter) != -1:
            var idx: int = projectile_list.add_item(pname)
            var tex: Texture2D = _GetProjectileTexture(pname)
            if tex:
                projectile_list.set_item_icon(idx, tex)

func _GetProjectileTexture(projectile_name: String) -> Texture2D:
    var data: TowerDefenseProjectileData = _LoadProjectileData(projectile_name)
    if not data:
        return null
    if data.projectileScene:
        var scene: PackedScene = data.projectileScene
        var inst: Node = scene.instantiate()
        var tex: Texture2D = _FindTextureInNode(inst)
        inst.queue_free()
        return tex
    return null

func _FindTextureInNode(node: Node) -> Texture2D:
    if node is Sprite2D and node.texture:
        return node.texture
    if node is TextureRect and node.texture:
        return node.texture
    for child: Node in node.get_children():
        var tex: Texture2D = _FindTextureInNode(child)
        if tex:
            return tex
    return null

func _on_search_text_changed(new_text: String) -> void :
    _RefreshList(new_text)

func _on_item_selected(index: int) -> void :
    var selected_name: String = projectile_list.get_item_text(index)
    var data: TowerDefenseProjectileData = _LoadProjectileData(selected_name)
    current_projectile_name = selected_name
    current_data = data
    label_name.text = selected_name
    if data:
        EditorInterface.edit_resource(data)
    else:
        EditorInterface.edit_resource(null)
    _ShowPreview(selected_name, data)
    _ShowSkinsEditor(selected_name)
    _ShowChangesEditor(selected_name)

func _LoadProjectileData(projectile_name: String) -> TowerDefenseProjectileData:
    if not projectile_uids.has(projectile_name):
        return null
    var uid_path: String = projectile_uids[projectile_name]
    var res: Resource = load(uid_path)
    if res is TowerDefenseProjectileData:
        return res
    push_warning("[ProjectileEditor] Failed to load ProjectileData for '%s' from '%s'" % [projectile_name, uid_path])
    return null

func _ShowPreview(projectile_name: String, data: TowerDefenseProjectileData) -> void :
    _ClearChildren(preview_container)
    if not data:
        var no_sel: Label = Label.new()
        no_sel.text = "(no selection)"
        preview_container.add_child(no_sel)
        return
    if data.projectileScene:
        _AddPreviewBlock("ProjectileScene", data.projectileScene)
    if data.splatScene:
        _AddPreviewBlock("SplatScene", data.splatScene)

func _AddPreviewBlock(label_text: String, scene_res: PackedScene) -> void :
    var vbox: VBoxContainer = VBoxContainer.new()
    var lbl: Label = Label.new()
    lbl.text = label_text
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(lbl)
    var vp_container: SubViewportContainer = SubViewportContainer.new()
    vp_container.custom_minimum_size = Vector2(80, 80)
    vp_container.stretch = true
    var vp: SubViewport = SubViewport.new()
    vp.transparent_bg = true
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    vp.size = Vector2i(80, 80)
    vp_container.add_child(vp)
    var inst: Node = scene_res.instantiate()
    vp.add_child(inst)
    _AutoCenterNode(inst, vp)
    vbox.add_child(vp_container)
    preview_container.add_child(vbox)

func _AutoCenterNode(inst: Node, vp: SubViewport) -> void :
    if inst is Node2D:
        (inst as Node2D).position = Vector2(vp.size) * 0.5
    _ForceProcessParticles(inst)

func _ForceProcessParticles(node: Node) -> void :
    if node is GPUParticles2D:
        var p: GPUParticles2D = node as GPUParticles2D
        p.emitting = true
        p.one_shot = false
        p.amount_ratio = 1.0
    elif node is CPUParticles2D:
        var p: CPUParticles2D = node as CPUParticles2D
        p.emitting = true
        p.one_shot = false
    for child: Node in node.get_children():
        _ForceProcessParticles(child)

func _ShowSkinsEditor(projectile_name: String) -> void :
    _ClearChildren(skins_section)
    var title_bar: HBoxContainer = HBoxContainer.new()
    var title: Label = Label.new()
    title.text = "Skins:"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_bar.add_child(title)
    var add_skin_btn: Button = Button.new()
    add_skin_btn.text = "+ Skin"
    add_skin_btn.pressed.connect( func() -> void : _AddSkin(projectile_name))
    title_bar.add_child(add_skin_btn)
    skins_section.add_child(title_bar)

    var skins: Dictionary = registry_data.get("Skins", {}).get(projectile_name, {})
    if skins.is_empty():
        skins_section.visible = true
        var empty: Label = Label.new()
        empty.text = "  (none)"
        empty.add_theme_color_override("font_color", Color.GRAY)
        skins_section.add_child(empty)
        return
    skins_section.visible = true
    for skin_name: String in skins:
        var skin_data: Dictionary = skins[skin_name]
        _AddSkinRow(projectile_name, skin_name, skin_data)

func _AddSkinRow(projectile_name: String, skin_name: String, skin_data: Dictionary) -> void :
    var frame: PanelContainer = PanelContainer.new()
    var vbox: VBoxContainer = VBoxContainer.new()

    var row_header: HBoxContainer = HBoxContainer.new()
    var name_edit: LineEdit = LineEdit.new()
    name_edit.text = skin_name
    name_edit.custom_minimum_size.x = 100
    name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row_header.add_child(name_edit)
    var del_btn: Button = Button.new()
    del_btn.text = "x"
    del_btn.pressed.connect( func() -> void :
        _DeleteSkin(projectile_name, skin_name)
    )
    row_header.add_child(del_btn)
    vbox.add_child(row_header)

    var scene_row: HBoxContainer = HBoxContainer.new()
    var scene_lbl: Label = Label.new()
    scene_lbl.text = "Proj:"
    scene_row.add_child(scene_lbl)
    var scene_val: String = str(skin_data.get("ProjectileScene", ""))
    if not scene_val.is_empty():
        scene_row.add_child(_CreateSkinPreview(scene_val))
    var scene_picker: EditorResourcePicker = _CreateResourcePicker("PackedScene")
    if not scene_val.is_empty():
        var res: Resource = load(scene_val)
        if res:
            scene_picker.edited_resource = res
    scene_picker.resource_changed.connect( func(resource: Resource) -> void :
        if resource:
            _SetSkinField(projectile_name, skin_name, "ProjectileScene", resource.resource_path if not resource.resource_path.is_empty() else "")
        else:
            _SetSkinField(projectile_name, skin_name, "ProjectileScene", "")
    )
    scene_row.add_child(scene_picker)

    var sep: VSeparator = VSeparator.new()
    scene_row.add_child(sep)

    var splat_lbl: Label = Label.new()
    splat_lbl.text = "Splat:"
    scene_row.add_child(splat_lbl)
    var splat_val: String = str(skin_data.get("SplatScene", ""))
    if not splat_val.is_empty():
        scene_row.add_child(_CreateSkinPreview(splat_val))
    var splat_picker: EditorResourcePicker = _CreateResourcePicker("PackedScene")
    if not splat_val.is_empty():
        var res2: Resource = load(splat_val)
        if res2:
            splat_picker.edited_resource = res2
    splat_picker.resource_changed.connect( func(resource: Resource) -> void :
        if resource:
            _SetSkinField(projectile_name, skin_name, "SplatScene", resource.resource_path if not resource.resource_path.is_empty() else "")
        else:
            _SetSkinField(projectile_name, skin_name, "SplatScene", "")
    )
    scene_row.add_child(splat_picker)
    vbox.add_child(scene_row)

    frame.add_child(vbox)
    skins_section.add_child(frame)

func _CreateSkinPreview(path: String) -> SubViewportContainer:
    var vp_container: SubViewportContainer = SubViewportContainer.new()
    vp_container.custom_minimum_size = Vector2(80, 80)
    vp_container.stretch = true
    var vp: SubViewport = SubViewport.new()
    vp.transparent_bg = true
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    vp.size = Vector2i(80, 80)
    var res: Resource = load(path)
    if res is PackedScene:
        var inst: Node = res.instantiate()
        vp.add_child(inst)
        _AutoCenterNode(inst, vp)
    vp_container.add_child(vp)
    return vp_container

func _CreateResourcePicker(type_name: String) -> EditorResourcePicker:
    var picker: EditorResourcePicker = EditorResourcePicker.new()
    picker.base_type = type_name
    picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    picker.editable = true
    return picker

func _AddSkin(projectile_name: String) -> void :
    var skins: Dictionary = registry_data.get("Skins", {})
    if not skins.has(projectile_name):
        skins[projectile_name] = {}
    var proj_skins: Dictionary = skins[projectile_name]
    var new_name: String = "NewSkin"
    var counter: int = 1
    while proj_skins.has(new_name):
        new_name = "NewSkin%d" % counter
        counter += 1
    proj_skins[new_name] = {"ProjectileScene": ""}
    _SaveRegistryJson()
    _ShowSkinsEditor(projectile_name)

func _DeleteSkin(projectile_name: String, skin_name: String) -> void :
    var skins: Dictionary = registry_data.get("Skins", {})
    if skins.has(projectile_name) and skins[projectile_name].has(skin_name):
        skins[projectile_name].erase(skin_name)
        _SaveRegistryJson()
        _ShowSkinsEditor(projectile_name)

func _SetSkinField(projectile_name: String, skin_name: String, field: String, value: String) -> void :
    var skins: Dictionary = registry_data.get("Skins", {})
    if skins.has(projectile_name) and skins[projectile_name].has(skin_name):
        if value.is_empty():
            skins[projectile_name][skin_name].erase(field)
        else:
            skins[projectile_name][skin_name][field] = value
    _SaveRegistryJson()

func _ShowChangesEditor(projectile_name: String) -> void :
    _ClearChildren(changes_section)
    var title_bar: HBoxContainer = HBoxContainer.new()
    var title: Label = Label.new()
    title.text = "Changes:"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_bar.add_child(title)
    var add_change_btn: Button = Button.new()
    add_change_btn.text = "+ Change"
    add_change_btn.pressed.connect( func() -> void : _AddChange(projectile_name))
    title_bar.add_child(add_change_btn)
    changes_section.add_child(title_bar)

    var changes_for_proj: Dictionary = _GetChangesForProjectile(projectile_name)
    if changes_for_proj.is_empty():
        changes_section.visible = true
        var empty: Label = Label.new()
        empty.text = "  (none)"
        empty.add_theme_color_override("font_color", Color.GRAY)
        changes_section.add_child(empty)
        return
    changes_section.visible = true
    for change_type: String in changes_for_proj:
        var target: String = changes_for_proj[change_type]
        _AddChangeRow(projectile_name, change_type, target)

func _GetChangesForProjectile(projectile_name: String) -> Dictionary:
    var result: Dictionary = {}
    var changes: Dictionary = registry_data.get("Changes", {})
    for change_key: String in changes:
        var change_map: Dictionary = changes[change_key]
        if change_map.has(projectile_name):
            result[change_key] = change_map[projectile_name]
    return result

func _AddChangeRow(projectile_name: String, change_type: String, target: String) -> void :
    var row: HBoxContainer = HBoxContainer.new()
    var type_edit: LineEdit = LineEdit.new()
    type_edit.text = change_type
    type_edit.custom_minimum_size.x = 80
    type_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    type_edit.text_submitted.connect( func(val: String) -> void :
        _RenameChangeType(projectile_name, change_type, val)
    )
    row.add_child(type_edit)
    var arrow: Label = Label.new()
    arrow.text = "->"
    row.add_child(arrow)
    var target_edit: LineEdit = LineEdit.new()
    target_edit.text = target
    target_edit.custom_minimum_size.x = 80
    target_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    target_edit.text_submitted.connect( func(val: String) -> void :
        _SetChangeTarget(projectile_name, change_type, val)
    )
    row.add_child(target_edit)
    var del_btn: Button = Button.new()
    del_btn.text = "x"
    del_btn.pressed.connect( func() -> void :
        _DeleteChange(projectile_name, change_type)
    )
    row.add_child(del_btn)
    changes_section.add_child(row)

func _AddChange(projectile_name: String) -> void :
    var changes: Dictionary = registry_data.get("Changes", {})
    var new_type: String = "NewChange"
    var counter: int = 1
    while changes.has(new_type):
        new_type = "NewChange%d" % counter
        counter += 1
    changes[new_type] = {}
    changes[new_type][projectile_name] = projectile_name
    _SaveRegistryJson()
    _ShowChangesEditor(projectile_name)

func _DeleteChange(projectile_name: String, change_type: String) -> void :
    var changes: Dictionary = registry_data.get("Changes", {})
    if changes.has(change_type) and changes[change_type].has(projectile_name):
        changes[change_type].erase(projectile_name)
        if changes[change_type].is_empty():
            changes.erase(change_type)
        _SaveRegistryJson()
        _ShowChangesEditor(projectile_name)

func _SetChangeTarget(projectile_name: String, change_type: String, target: String) -> void :
    var changes: Dictionary = registry_data.get("Changes", {})
    if changes.has(change_type):
        changes[change_type][projectile_name] = target
        _SaveRegistryJson()

func _RenameChangeType(projectile_name: String, old_type: String, new_type: String) -> void :
    var changes: Dictionary = registry_data.get("Changes", {})
    if not changes.has(old_type):
        return
    var target: String = changes[old_type].get(projectile_name, projectile_name)
    changes[old_type].erase(projectile_name)
    if changes[old_type].is_empty():
        changes.erase(old_type)
    if not changes.has(new_type):
        changes[new_type] = {}
    changes[new_type][projectile_name] = target
    _SaveRegistryJson()
    _ShowChangesEditor(projectile_name)

func _SaveRegistryJson() -> void :
    var new_json: String = JSON.stringify(registry_data, "\t")
    var save_file: FileAccess = FileAccess.open(REGISTRY_PATH, FileAccess.WRITE)
    save_file.store_string(new_json)
    save_file.close()

func _ClearChildren(node: Node) -> void :
    for child: Node in node.get_children():
        child.queue_free()

func _on_rename_pressed() -> void :
    if current_projectile_name.is_empty():
        return
    var popup: PopupPanel = PopupPanel.new()
    popup.title = "Rename Projectile"
    popup.min_size = Vector2(300, 80)
    var vbox: VBoxContainer = VBoxContainer.new()
    var name_edit: LineEdit = LineEdit.new()
    name_edit.text = current_projectile_name
    vbox.add_child(name_edit)
    var btn_hbox: HBoxContainer = HBoxContainer.new()
    btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    var ok_btn: Button = Button.new()
    ok_btn.text = "OK"
    var cancel_btn: Button = Button.new()
    cancel_btn.text = "Cancel"
    btn_hbox.add_child(ok_btn)
    btn_hbox.add_child(cancel_btn)
    vbox.add_child(btn_hbox)
    popup.add_child(vbox)
    add_child(popup)
    ok_btn.pressed.connect( func() -> void :
        _DoRename(current_projectile_name, name_edit.text)
        popup.queue_free()
    )
    cancel_btn.pressed.connect( func() -> void :
        popup.queue_free()
    )
    name_edit.text_submitted.connect( func(val: String) -> void :
        _DoRename(current_projectile_name, val)
        popup.queue_free()
    )
    popup.popup_centered()

func _DoRename(old_name: String, new_name: String) -> void :
    if new_name.is_empty() or new_name == old_name:
        return
    var projectiles: Dictionary = registry_data.get("Projectiles", {})
    if not projectiles.has(old_name):
        return
    if projectiles.has(new_name):
        push_warning("[ProjectileEditor] Name already exists: %s" % new_name)
        return
    var uid_val: String = projectiles[old_name]
    projectiles.erase(old_name)
    projectiles[new_name] = uid_val
    var skins: Dictionary = registry_data.get("Skins", {})
    if skins.has(old_name):
        skins[new_name] = skins[old_name]
        skins.erase(old_name)
    var changes: Dictionary = registry_data.get("Changes", {})
    for change_key: String in changes:
        var change_map: Dictionary = changes[change_key]
        if change_map.has(old_name):
            change_map[new_name] = change_map[old_name]
            change_map.erase(old_name)
    _SaveRegistryJson()
    LoadRegistry()

func _on_save_pressed() -> void :
    if not current_data:
        return
    var save_path: String = current_data.resource_path
    if save_path.is_empty():
        return
    ResourceSaver.save(current_data, save_path)
    _SaveRegistryJson()
    print("[ProjectileEditor] Saved: %s -> %s" % [current_projectile_name, save_path])

func _on_add_pressed() -> void :
    var popup: PopupPanel = PopupPanel.new()
    popup.title = "Add Projectile"
    popup.min_size = Vector2(420, 130)
    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 6)

    var name_row: HBoxContainer = HBoxContainer.new()
    var name_lbl: Label = Label.new()
    name_lbl.text = "Name:"
    name_lbl.custom_minimum_size.x = 50
    name_row.add_child(name_lbl)
    var name_edit: LineEdit = LineEdit.new()
    name_edit.placeholder_text = "Projectile name"
    name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_row.add_child(name_edit)
    vbox.add_child(name_row)

    var path_row: HBoxContainer = HBoxContainer.new()
    var path_lbl: Label = Label.new()
    path_lbl.text = "Path:"
    path_lbl.custom_minimum_size.x = 50
    path_row.add_child(path_lbl)
    var path_edit: LineEdit = LineEdit.new()
    path_edit.placeholder_text = "res://Registry/Projectile/Config/..."
    path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    path_row.add_child(path_edit)
    var browse_btn: Button = Button.new()
    browse_btn.text = "..."
    browse_btn.tooltip_text = "Browse"
    path_row.add_child(browse_btn)
    vbox.add_child(path_row)

    var btn_hbox: HBoxContainer = HBoxContainer.new()
    btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    var ok_btn: Button = Button.new()
    ok_btn.text = "OK"
    var cancel_btn: Button = Button.new()
    cancel_btn.text = "Cancel"
    btn_hbox.add_child(ok_btn)
    btn_hbox.add_child(cancel_btn)
    vbox.add_child(btn_hbox)
    popup.add_child(vbox)
    add_child(popup)

    name_edit.text_changed.connect( func(new_text: String) -> void :
        if not path_edit.text.is_empty():
            return
        path_edit.placeholder_text = "res://Registry/Projectile/Config/%s/%s.tres" % [new_text, new_text]
    )

    browse_btn.pressed.connect( func() -> void :
        var dialog: EditorFileDialog = EditorFileDialog.new()
        dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
        dialog.access = EditorFileDialog.ACCESS_RESOURCES
        dialog.title = "Save Projectile Resource"
        dialog.add_filter("*.tres", "Resource Files")
        var current_dir: String = path_edit.text.get_base_dir() if not path_edit.text.is_empty() else "res://Registry/Projectile/Config"
        dialog.current_dir = current_dir
        var proj_name: String = name_edit.text
        if not proj_name.is_empty():
            dialog.current_file = proj_name + ".tres"
        add_child(dialog)
        dialog.file_selected.connect( func(selected_path: String) -> void :
            path_edit.text = selected_path
            dialog.queue_free()
        )
        dialog.canceled.connect( func() -> void :
            dialog.queue_free()
        )
        dialog.popup_centered(Vector2i(800, 600))
    )

    var _do_create: Callable = func() -> void :
        var proj_name: String = name_edit.text
        var save_path: String = path_edit.text
        if save_path.is_empty():
            save_path = "res://Registry/Projectile/Config/%s/%s.tres" % [proj_name, proj_name]
        _CreateNewProjectile(proj_name, save_path)
        popup.queue_free()

    ok_btn.pressed.connect(_do_create)
    cancel_btn.pressed.connect( func() -> void :
        popup.queue_free()
    )
    name_edit.text_submitted.connect( func(_text: String) -> void :
        _do_create.call()
    )
    popup.popup_centered()

func _CreateNewProjectile(projectile_name: String, save_path: String) -> void :
    if projectile_name.is_empty():
        return
    if save_path.is_empty():
        save_path = "res://Registry/Projectile/Config/%s/%s.tres" % [projectile_name, projectile_name]
    if not save_path.ends_with(".tres"):
        save_path += ".tres"
    var dir_path: String = save_path.get_base_dir()
    if not DirAccess.dir_exists_absolute(dir_path):
        DirAccess.make_dir_recursive_absolute(dir_path)
    var new_data: TowerDefenseProjectileData = TowerDefenseProjectileData.new()
    new_data.name = projectile_name
    ResourceSaver.save(new_data, save_path)
    EditorInterface.get_resource_filesystem().scan()
    _UpdateRegistryJson(projectile_name, save_path)
    print("[ProjectileEditor] Created: %s -> %s" % [projectile_name, save_path])

func _UpdateRegistryJson(projectile_name: String, tres_path: String) -> void :
    var file: FileAccess = FileAccess.open(REGISTRY_PATH, FileAccess.READ)
    var json_text: String = file.get_as_text()
    file.close()
    var json: JSON = JSON.new()
    json.parse(json_text)
    var data: Dictionary = json.data
    var projectiles: Dictionary = data.get("Projectiles", {})
    projectiles[projectile_name] = tres_path
    var new_json: String = JSON.stringify(data, "\t")
    var save_file: FileAccess = FileAccess.open(REGISTRY_PATH, FileAccess.WRITE)
    save_file.store_string(new_json)
    save_file.close()
