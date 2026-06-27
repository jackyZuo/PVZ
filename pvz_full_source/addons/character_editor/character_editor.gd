@tool
extends Control

var editor_plugin

const CHARACTER_REGISTRY_PATH: String = "res://Asset/Config/Character/CharacterResource.json"

const CATEGORY_ALL: String = "All"
const CATEGORY_PLANT: String = "Plant"
const CATEGORY_ZOMBIE: String = "Zombie"
const CATEGORY_ITEM: String = "Item"
const CATEGORY_MOWER: String = "Mower"
const CATEGORY_VASE: String = "Vase"
const CATEGORY_GRAVESTONE: String = "GraveStone"
const CATEGORY_CRATER: String = "Crater"

var registry_data: Dictionary = {}
var character_names: PackedStringArray = []
var character_categories: Dictionary = {}
var character_data_map: Dictionary = {}
var _filtered_names: PackedStringArray = []
var _loaded: bool = false

var current_character_name: String = ""
var current_config: TowerDefenseCharacterConfig

var _thumbnail_cache: Dictionary = {}
var _render_queue: Array = []
var _render_generation: int = 0
var _render_viewports: Array[SubViewport] = []
var _rendering: bool = false
var _current_load_name: String = ""
var _current_load_paths: PackedStringArray = []
var _current_load_path_idx: int = 0
var _current_load_idx: int = -1
var _current_load_gen: int = 0
var _rendering_thumbnail: bool = false

var search_line: LineEdit
var button_refresh: Button
var category_container: VBoxContainer
var category_buttons: Dictionary = {}
var current_category: String = CATEGORY_ALL
var character_list: ItemList
var label_name: Label
var label_type: Label
var button_save: Button
var button_add: Button
var button_rename: Button
var preview_section: VBoxContainer
var preview_sprite: AdobeAnimateSprite
var preview_viewport: SubViewport
var preview_vpc: SubViewportContainer
var damage_option: OptionButton
var custom_option: OptionButton
var armor_option: OptionButton

var tab_container: TabContainer
var config_fields: VBoxContainer
var packet_fields: VBoxContainer
var packet_preview_mode: bool = false
var packet_card_root: Control
var packet_card_bg: TextureRect
var packet_card_vpc: SubViewportContainer
var packet_card_vp: SubViewport
var packet_card_cost: Label
var packet_mode_pc_btn: Button
var packet_mode_mobile_btn: Button
var _current_pkt: TowerDefensePacketConfig = null
var _packet_sprite_inst: Node = null

var damage_list: ItemList
var damage_detail: VBoxContainer
var custom_list: ItemList
var custom_detail: VBoxContainer
var armor_list: ItemList
var armor_detail: VBoxContainer

var _cached_layer_names: PackedStringArray = []

func _ready() -> void :
    _BuildUI()
    _CreateRenderViewport()
    LoadRegistry()

func _process(_delta: float) -> void :
    if _rendering_thumbnail:
        return
    if _current_load_name.is_empty():
        _StartNextLoad()
        return
    var path: String = _current_load_paths[_current_load_path_idx]
    var status: int = ResourceLoader.load_threaded_get_status(path)
    if status == ResourceLoader.THREAD_LOAD_LOADED:
        var res: Resource = ResourceLoader.load_threaded_get(path)
        if res is PackedScene:
            _RenderOneThumbnail(_current_load_name)
        else:
            _TryNextPath()
    elif status == ResourceLoader.THREAD_LOAD_FAILED:
        _TryNextPath()

func _StartNextLoad() -> void :
    if _render_queue.is_empty():
        _rendering = false
        return
    var item: Dictionary = _render_queue.pop_front()
    if item["gen"] != _render_generation:
        _StartNextLoad()
        return
    _current_load_name = item["name"]
    _current_load_idx = item["idx"]
    _current_load_gen = item["gen"]
    var char_data: Dictionary = character_data_map.get(_current_load_name, {})
    var sprite_uid: String = str(char_data.get("Sprite", ""))
    var scene_uid: String = str(char_data.get("Scene", ""))
    _current_load_paths.clear()
    if not sprite_uid.is_empty():
        _current_load_paths.append(sprite_uid)
    if not scene_uid.is_empty():
        _current_load_paths.append(scene_uid)
    _current_load_path_idx = 0
    if _current_load_paths.is_empty():
        _thumbnail_cache[_current_load_name] = null
        _current_load_name = ""
        _StartNextLoad()
        return
    ResourceLoader.load_threaded_request(_current_load_paths[0])

func _TryNextPath() -> void :
    _current_load_path_idx += 1
    if _current_load_path_idx < _current_load_paths.size():
        ResourceLoader.load_threaded_request(_current_load_paths[_current_load_path_idx])
    else:
        _thumbnail_cache[_current_load_name] = null
        _current_load_name = ""
        _StartNextLoad()

func _CreateRenderViewport() -> void :
    var vp: = SubViewport.new()
    vp.size = Vector2i(176, 188)
    vp.transparent_bg = true
    vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
    vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    vp.size_2d_override = Vector2i(176, 188)
    vp.size_2d_override_stretch = true
    add_child(vp)
    _render_viewports.append(vp)

func _GetLayerNames() -> PackedStringArray:
    if not _cached_layer_names.is_empty():
        return _cached_layer_names
    if is_instance_valid(preview_sprite):
        var fad = preview_sprite.flashAnimeData
        if fad and not fad.layerList.is_empty():
            _cached_layer_names = fad.layerList
            return _cached_layer_names
    if not current_character_name.is_empty():
        var char_data: Dictionary = character_data_map.get(current_character_name, {})
        var sprite_uid: String = str(char_data.get("Sprite", ""))
        if sprite_uid.is_empty():
            sprite_uid = str(char_data.get("Scene", ""))
        if not sprite_uid.is_empty():
            var res: Resource = load(sprite_uid)
            if res is PackedScene:
                var state: SceneState = res.get_state()
                for i in range(state.get_node_count()):
                    for j in range(state.get_node_property_count(i)):
                        var pname: String = state.get_node_property_name(i, j)
                        if pname == "flashAnimeData":
                            var data: AdobeAnimateData = state.get_node_property_value(i, j)
                            if data and not data.layerList.is_empty():
                                _cached_layer_names = data.layerList
                                return _cached_layer_names
                            elif data and not data.animeFile.is_empty():
                                var tmp: = AdobeAnimateData.new()
                                tmp.animeFile = data.animeFile
                                _cached_layer_names = tmp.layerList
                                return _cached_layer_names
                            break
    return _cached_layer_names

func _BuildUI() -> void :
    name = "CharacterEditor"
    anchor_right = 1.0
    anchor_bottom = 1.0
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL

    var main_hsplit: = HSplitContainer.new()
    main_hsplit.anchor_right = 1.0
    main_hsplit.anchor_bottom = 1.0
    main_hsplit.split_offset = 280
    main_hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(main_hsplit)

    var left_panel: = VBoxContainer.new()
    left_panel.custom_minimum_size = Vector2(280, 0)
    left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

    var search_hbox: = HBoxContainer.new()
    search_line = LineEdit.new()
    search_line.placeholder_text = "搜索角色..."
    search_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    search_hbox.add_child(search_line)
    button_refresh = Button.new()
    button_refresh.text = "刷新"
    search_hbox.add_child(button_refresh)
    left_panel.add_child(search_hbox)

    category_container = VBoxContainer.new()
    left_panel.add_child(category_container)
    _BuildCategoryButtons()

    character_list = ItemList.new()
    character_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    character_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    character_list.fixed_icon_size = Vector2(32, 32)
    character_list.icon_mode = ItemList.ICON_MODE_LEFT
    character_list.item_selected.connect(_on_item_selected)
    left_panel.add_child(character_list)

    main_hsplit.add_child(left_panel)

    var right_panel: = VBoxContainer.new()
    right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

    var header: = HBoxContainer.new()
    label_name = Label.new()
    label_name.text = "请选择一个角色"
    label_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(label_name)
    label_type = Label.new()
    label_type.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
    header.add_child(label_type)
    button_save = Button.new()
    button_save.text = "保存"
    header.add_child(button_save)
    button_add = Button.new()
    button_add.text = "+"
    header.add_child(button_add)
    button_rename = Button.new()
    button_rename.text = "重命名"
    header.add_child(button_rename)
    right_panel.add_child(header)

    preview_section = VBoxContainer.new()
    preview_section.visible = false
    var pt: = Label.new()
    pt.text = "预览"
    pt.add_theme_font_size_override("font_size", 16)
    preview_section.add_child(pt)

    preview_vpc = SubViewportContainer.new()
    preview_vpc.custom_minimum_size = Vector2(200, 200)
    preview_vpc.stretch = true
    preview_viewport = SubViewport.new()
    preview_viewport.transparent_bg = true
    preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    preview_viewport.size = Vector2i(200, 200)
    preview_vpc.add_child(preview_viewport)
    preview_section.add_child(preview_vpc)

    var ctrl_row: = HBoxContainer.new()
    ctrl_row.add_theme_constant_override("separation", 8)

    var dl: = Label.new()
    dl.text = "破损:"
    ctrl_row.add_child(dl)
    damage_option = OptionButton.new()
    damage_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    damage_option.item_selected.connect(_on_damage_option_changed)
    ctrl_row.add_child(damage_option)

    var cl: = Label.new()
    cl.text = "皮肤:"
    ctrl_row.add_child(cl)
    custom_option = OptionButton.new()
    custom_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    custom_option.item_selected.connect(_on_custom_option_changed)
    ctrl_row.add_child(custom_option)

    var al: = Label.new()
    al.text = "护甲:"
    ctrl_row.add_child(al)
    armor_option = OptionButton.new()
    armor_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    armor_option.item_selected.connect(_on_armor_option_changed)
    ctrl_row.add_child(armor_option)

    preview_section.add_child(ctrl_row)
    right_panel.add_child(preview_section)

    tab_container = TabContainer.new()
    tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tab_container.visible = false

    var config_tab: = VBoxContainer.new()
    config_tab.name = "角色配置"
    var config_tab_scroll: = ScrollContainer.new()
    config_tab_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    config_tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    config_tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    var config_tab_content: = VBoxContainer.new()
    config_tab_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    config_fields = VBoxContainer.new()
    config_fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    config_tab_content.add_child(config_fields)
    config_tab_scroll.add_child(config_tab_content)
    config_tab.add_child(config_tab_scroll)
    tab_container.add_child(config_tab)

    var packet_tab: = VBoxContainer.new()
    packet_tab.name = "卡牌"
    var packet_hsplit: = HSplitContainer.new()
    packet_hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
    packet_hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    packet_hsplit.split_offset = 280
    var packet_left: = VBoxContainer.new()
    packet_left.custom_minimum_size = Vector2(280, 0)
    var mode_row: = HBoxContainer.new()
    mode_row.alignment = BoxContainer.ALIGNMENT_CENTER
    mode_row.add_theme_constant_override("separation", 4)
    var mode_label: = Label.new()
    mode_label.text = "预览模式:"
    mode_row.add_child(mode_label)
    packet_mode_pc_btn = Button.new()
    packet_mode_pc_btn.text = "PC"
    packet_mode_pc_btn.toggle_mode = true
    packet_mode_pc_btn.button_pressed = true
    packet_mode_pc_btn.pressed.connect(_on_packet_mode_pc)
    mode_row.add_child(packet_mode_pc_btn)
    packet_mode_mobile_btn = Button.new()
    packet_mode_mobile_btn.text = "Mobile"
    packet_mode_mobile_btn.toggle_mode = true
    packet_mode_mobile_btn.pressed.connect(_on_packet_mode_mobile)
    mode_row.add_child(packet_mode_mobile_btn)
    packet_left.add_child(mode_row)
    var preview_center: = CenterContainer.new()
    preview_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    preview_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    packet_card_root = Control.new()
    packet_card_root.custom_minimum_size = Vector2(50, 70)
    var card_body: = Control.new()
    var card_layout: = Control.new()
    packet_card_bg = TextureRect.new()
    packet_card_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    packet_card_bg.stretch_mode = TextureRect.STRETCH_SCALE
    packet_card_bg.size = Vector2(50, 70)
    packet_card_bg.position = Vector2(0, 0)
    packet_card_vpc = SubViewportContainer.new()
    packet_card_vpc.position = Vector2(3, 6)
    packet_card_vpc.size = Vector2(176, 188)
    packet_card_vpc.scale = Vector2(0.25, 0.25)
    packet_card_vpc.stretch = true
    packet_card_bg.add_child(packet_card_vpc)
    packet_card_vp = SubViewport.new()
    packet_card_vp.size = Vector2i(176, 188)
    packet_card_vp.transparent_bg = true
    packet_card_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    packet_card_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    packet_card_vpc.add_child(packet_card_vp)
    packet_card_cost = Label.new()
    packet_card_cost.position = Vector2(2, 52)
    packet_card_cost.size = Vector2(35, 17)
    packet_card_cost.add_theme_font_size_override("font_size", 12)
    packet_card_cost.add_theme_color_override("font_color", Color.BLACK)
    packet_card_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    packet_card_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    packet_card_cost.text = ""
    packet_card_bg.add_child(packet_card_cost)
    card_layout.add_child(packet_card_bg)
    card_body.add_child(card_layout)
    packet_card_root.add_child(card_body)
    packet_card_root.scale = Vector2(3, 3)
    preview_center.add_child(packet_card_root)
    packet_left.add_child(preview_center)
    packet_hsplit.add_child(packet_left)
    packet_fields = VBoxContainer.new()
    packet_fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var packet_scroll: = ScrollContainer.new()
    packet_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    packet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    packet_scroll.add_child(packet_fields)
    packet_hsplit.add_child(packet_scroll)
    packet_tab.add_child(packet_hsplit)
    tab_container.add_child(packet_tab)

    var damage_tab: = VBoxContainer.new()
    damage_tab.name = "破损"
    var damage_hsplit: = HSplitContainer.new()
    damage_hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
    damage_hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    damage_hsplit.split_offset = 180
    var damage_left: = VBoxContainer.new()
    damage_left.custom_minimum_size = Vector2(180, 0)
    var damage_toolbar: = HBoxContainer.new()
    var btn_add_damage: = Button.new()
    btn_add_damage.text = "+ 添加破损点"
    btn_add_damage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn_add_damage.pressed.connect(_on_add_damage_point)
    damage_toolbar.add_child(btn_add_damage)
    damage_left.add_child(damage_toolbar)
    damage_list = ItemList.new()
    damage_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    damage_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    damage_list.item_selected.connect(_on_damage_list_selected)
    damage_left.add_child(damage_list)
    damage_hsplit.add_child(damage_left)
    damage_detail = VBoxContainer.new()
    damage_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    damage_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    damage_hsplit.add_child(damage_detail)
    damage_tab.add_child(damage_hsplit)
    tab_container.add_child(damage_tab)

    var custom_tab: = VBoxContainer.new()
    custom_tab.name = "皮肤"
    var custom_hsplit: = HSplitContainer.new()
    custom_hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
    custom_hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    custom_hsplit.split_offset = 180
    var custom_left: = VBoxContainer.new()
    custom_left.custom_minimum_size = Vector2(180, 0)
    var custom_toolbar: = HBoxContainer.new()
    var btn_add_custom: = Button.new()
    btn_add_custom.text = "+ 添加皮肤"
    btn_add_custom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn_add_custom.pressed.connect(_on_add_custom)
    custom_toolbar.add_child(btn_add_custom)
    custom_left.add_child(custom_toolbar)
    custom_list = ItemList.new()
    custom_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    custom_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    custom_list.item_selected.connect(_on_custom_list_selected)
    custom_left.add_child(custom_list)
    custom_hsplit.add_child(custom_left)
    custom_detail = VBoxContainer.new()
    custom_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    custom_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    custom_hsplit.add_child(custom_detail)
    custom_tab.add_child(custom_hsplit)
    tab_container.add_child(custom_tab)

    var armor_tab: = VBoxContainer.new()
    armor_tab.name = "护甲"
    var armor_hsplit: = HSplitContainer.new()
    armor_hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
    armor_hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    armor_hsplit.split_offset = 180
    var armor_left: = VBoxContainer.new()
    armor_left.custom_minimum_size = Vector2(180, 0)
    var armor_toolbar: = HBoxContainer.new()
    var btn_add_armor: = Button.new()
    btn_add_armor.text = "+ 添加护甲"
    btn_add_armor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn_add_armor.pressed.connect(_on_add_armor)
    armor_toolbar.add_child(btn_add_armor)
    armor_left.add_child(armor_toolbar)
    armor_list = ItemList.new()
    armor_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    armor_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    armor_list.item_selected.connect(_on_armor_list_selected)
    armor_left.add_child(armor_list)
    armor_hsplit.add_child(armor_left)
    armor_detail = VBoxContainer.new()
    armor_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    armor_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    armor_hsplit.add_child(armor_detail)
    armor_tab.add_child(armor_hsplit)
    tab_container.add_child(armor_tab)

    right_panel.add_child(tab_container)
    main_hsplit.add_child(right_panel)

    search_line.text_changed.connect(_on_search_text_changed)
    button_refresh.pressed.connect(_on_refresh_pressed)
    button_save.pressed.connect(_on_save_pressed)
    button_add.pressed.connect(_on_add_pressed)
    button_rename.pressed.connect(_on_rename_pressed)
    tab_container.tab_changed.connect(_on_main_tab_changed)

func _BuildCategoryButtons() -> void :
    _ClearChildren(category_container)
    var cats: = [CATEGORY_ALL, CATEGORY_PLANT, CATEGORY_ZOMBIE, CATEGORY_ITEM, CATEGORY_MOWER, CATEGORY_VASE, CATEGORY_GRAVESTONE, CATEGORY_CRATER]
    var hbox: = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 2)
    for cat in cats:
        var btn: = Button.new()
        btn.text = _CatName(cat)
        btn.toggle_mode = true
        btn.custom_minimum_size = Vector2(0, 26)
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if cat == CATEGORY_ALL:
            btn.button_pressed = true
        btn.pressed.connect(_on_category_pressed.bind(cat))
        category_buttons[cat] = btn
        hbox.add_child(btn)
    category_container.add_child(hbox)

func _CatName(cat: String) -> String:
    match cat:
        CATEGORY_ALL: return "全部"
        CATEGORY_PLANT: return "植物"
        CATEGORY_ZOMBIE: return "僵尸"
        CATEGORY_ITEM: return "道具"
        CATEGORY_MOWER: return "割草机"
        CATEGORY_VASE: return "花瓶"
        CATEGORY_GRAVESTONE: return "墓碑"
        CATEGORY_CRATER: return "弹坑"
        _: return cat

func _CharCat(n: String) -> String:
    if n.begins_with("Plant"): return CATEGORY_PLANT
    if n.begins_with("Zombie"): return CATEGORY_ZOMBIE
    if n.begins_with("Item"): return CATEGORY_ITEM
    if n.begins_with("Mower"): return CATEGORY_MOWER
    if n.begins_with("Vase"): return CATEGORY_VASE
    if n.begins_with("GraveStone"): return CATEGORY_GRAVESTONE
    if n.begins_with("Crater"): return CATEGORY_CRATER
    return CATEGORY_ALL

func _DisplayName(n: String) -> String:
    var prefixes: = ["Plant", "Zombie", "Item", "Mower", "Vase", "GraveStone", "Crater"]
    for p in prefixes:
        if n.begins_with(p) and n.length() > p.length():
            return n.substr(p.length())
    return n

func _on_category_pressed(cat: String) -> void :
    current_category = cat
    for key in category_buttons:
        category_buttons[key].button_pressed = (key == cat)
    _RefreshList(search_line.text)

func _EnsureLoaded() -> void :
    if _loaded:
        if character_list.item_count == 0 and not character_names.is_empty():
            _RefreshList("")
        return
    _loaded = true
    LoadRegistry()

func _on_refresh_pressed() -> void :
    _thumbnail_cache.clear()
    _loaded = true
    LoadRegistry()

func LoadRegistry() -> void :
    _LoadCharacterRegistry()
    _RefreshList("")

func _LoadCharacterRegistry() -> void :
    if not FileAccess.file_exists(CHARACTER_REGISTRY_PATH):
        push_error("[CharacterEditor] File not found: %s" % CHARACTER_REGISTRY_PATH)
        return
    var file: = FileAccess.open(CHARACTER_REGISTRY_PATH, FileAccess.READ)
    if not file:
        return
    var json_text: = file.get_as_text()
    file.close()
    var json: = JSON.new()
    if json.parse(json_text) != OK:
        return
    if not json.data is Dictionary:
        return
    registry_data = json.data
    character_names.clear()
    character_categories.clear()
    character_data_map.clear()
    for char_name in registry_data:
        var char_data: Dictionary = registry_data[char_name]
        character_names.append(char_name)
        character_categories[char_name] = _CharCat(char_name)
        character_data_map[char_name] = char_data
    character_names.sort()
    print("[CharacterEditor] Loaded %d characters" % character_names.size())

func _RefreshList(filter: String) -> void :
    _render_generation += 1
    _render_queue.clear()
    _rendering = false
    _current_load_name = ""
    _current_load_paths.clear()
    _rendering_thumbnail = false
    character_list.clear()
    _filtered_names.clear()
    for char_name in character_names:
        if current_category != CATEGORY_ALL and character_categories.get(char_name, "") != current_category:
            continue
        if not filter.is_empty() and char_name.findn(filter) == -1:
            continue
        _filtered_names.append(char_name)
        var idx: = _filtered_names.size() - 1
        if _thumbnail_cache.has(char_name) and _thumbnail_cache[char_name] != null:
            character_list.add_item(_DisplayName(char_name), _thumbnail_cache[char_name])
        else:
            character_list.add_item(_DisplayName(char_name))
            _render_queue.append({"name": char_name, "idx": idx, "gen": _render_generation})
    if not _render_queue.is_empty():
        _StartNextLoad()

func _RenderOneThumbnail(char_name: String) -> void :
    _rendering_thumbnail = true
    var char_data: Dictionary = character_data_map.get(char_name, {})
    var sprite_uid: String = str(char_data.get("Sprite", ""))
    var scene_uid: String = str(char_data.get("Scene", ""))
    var sprite_inst: Node = null
    if not sprite_uid.is_empty():
        var res: Resource = load(sprite_uid)
        if res is PackedScene:
            sprite_inst = res.instantiate()
    if sprite_inst == null and not scene_uid.is_empty():
        var res: Resource = load(scene_uid)
        if res is PackedScene:
            sprite_inst = res.instantiate()
    if sprite_inst == null:
        _thumbnail_cache[char_name] = null
        _rendering_thumbnail = false
        _current_load_name = ""
        _StartNextLoad()
        return
    var pkt_config: TowerDefensePacketConfig = _GetPacketConfig(char_name, char_data)
    var vp: SubViewport = _render_viewports[0]
    for c in vp.get_children():
        vp.remove_child(c)
        c.queue_free()
    vp.size = Vector2i(176, 188)
    vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    vp.add_child(sprite_inst)
    if sprite_inst is Node2D:
        if pkt_config:
            sprite_inst.position = pkt_config.packetAnimeOffset * 4.0
            sprite_inst.scale = pkt_config.packetAnimeScale * 4.0
            if pkt_config.packetFlip:
                sprite_inst.scale.x = - sprite_inst.scale.x
            var sp: = _FindSprite(sprite_inst)
            if sp:
                if not pkt_config.packetAnimeClip.is_empty():
                    sp.SetAnimation(pkt_config.packetAnimeClip, true)
                sp.pause = true
        else:
            sprite_inst.position = Vector2(vp.size) * 0.5
            sprite_inst.scale = Vector2(4.0, 4.0)
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
    if _current_load_gen != _render_generation:
        for c in vp.get_children():
            vp.remove_child(c)
            c.queue_free()
        vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
        _rendering_thumbnail = false
        _current_load_name = ""
        return
    var img: = vp.get_texture().get_image()
    if img and not img.is_empty() and img.get_width() > 0 and img.get_height() > 0 and img.get_width() <= 4096 and img.get_height() <= 4096:
        var tex: = ImageTexture.create_from_image(img)
        if tex:
            _thumbnail_cache[char_name] = tex
            _ApplyThumbnailToItem(_current_load_idx, tex)
        else:
            _thumbnail_cache[char_name] = null
    else:
        _thumbnail_cache[char_name] = null
    for c in vp.get_children():
        vp.remove_child(c)
        c.queue_free()
    vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
    _rendering_thumbnail = false
    _current_load_name = ""
    _StartNextLoad()

func _GetPacketConfig(char_name: String, char_data: Dictionary) -> TowerDefensePacketConfig:
    var pd: Dictionary = char_data.get("Packet", {})
    if pd.is_empty():
        return null
    for pk in pd:
        var puid: String = str(pd[pk])
        if puid.is_empty():
            continue
        var res: Resource = load(puid)
        if res is TowerDefensePacketConfig:
            return res
    return null

func _ApplyThumbnailToItem(idx: int, tex: Texture2D) -> void :
    if idx >= 0 and idx < character_list.item_count:
        character_list.set_item_icon(idx, tex)

func _on_search_text_changed(new_text: String) -> void :
    _RefreshList(new_text)

func _on_item_selected(index: int) -> void :
    if index < 0 or index >= _filtered_names.size():
        return
    current_character_name = _filtered_names[index]
    _ShowCharacterDetail(current_character_name)

func _ShowCharacterDetail(char_name: String) -> void :
    var char_data: Dictionary = character_data_map.get(char_name, {})
    label_name.text = char_name
    label_type.text = _CatName(character_categories.get(char_name, ""))
    _ShowConfigEditor(char_name, char_data)
    _ShowPreview(char_name, char_data)
    _ShowPacketEditor(char_name, char_data)
    _cached_layer_names.clear()
    _ShowDamageEditor()
    _ShowCustomEditor()
    _ShowArmorEditor()
    preview_section.visible = true
    tab_container.visible = true

func _ShowPreview(char_name: String, char_data: Dictionary) -> void :
    for c in preview_viewport.get_children():
        preview_viewport.remove_child(c)
        c.queue_free()
    preview_sprite = null

    damage_option.clear()
    custom_option.clear()
    armor_option.clear()
    damage_option.add_item("无", 0)
    custom_option.add_item("无", 0)
    armor_option.add_item("无", 0)

    var sprite_uid: String = str(char_data.get("Sprite", ""))
    var sprite_inst: Node = null

    if not sprite_uid.is_empty():
        var res: Resource = load(sprite_uid)
        if res is PackedScene:
            sprite_inst = res.instantiate()

    if sprite_inst == null:
        var scene_uid: String = str(char_data.get("Scene", ""))
        if not scene_uid.is_empty():
            var res: Resource = load(scene_uid)
            if res is PackedScene:
                sprite_inst = res.instantiate()

    if sprite_inst == null:
        return

    preview_viewport.add_child(sprite_inst)
    if sprite_inst is Node2D:
        sprite_inst.position = Vector2(preview_viewport.size) * 0.5
        sprite_inst.scale = Vector2.ONE
        var sp: = _FindSprite(sprite_inst)
        if sp:
            sp.pause = false
            preview_sprite = sp

    if current_config:
        if current_config.damagePointData:
            if current_config.damagePointData.damagePointDictionary.is_empty():
                current_config.damagePointData.Refresh()
            var dp_idx: = 1
            for dp_name in current_config.damagePointData.damagePointDictionary:
                damage_option.add_item(dp_name, dp_idx)
                dp_idx += 1
        if current_config.customData:
            if current_config.customData.customDictionary.is_empty():
                current_config.customData.Init()
            var cu_idx: = 1
            for cu_name in current_config.customData.customDictionary:
                custom_option.add_item(cu_name, cu_idx)
                cu_idx += 1
        if current_config.armorData:
            if current_config.armorData.armorDictionary.is_empty():
                current_config.armorData.Init()
            var ar_idx: = 1
            for ar_name in current_config.armorData.armorDictionary:
                armor_option.add_item(ar_name, ar_idx)
                ar_idx += 1

func _on_damage_option_changed(idx: int) -> void :
    if not is_instance_valid(preview_sprite) or not current_config:
        return
    if not current_config.damagePointData:
        return
    current_config.damagePointData.ClearDamagePointAll(preview_sprite)
    preview_sprite.UpdataChild()
    if idx <= 0:
        return
    var dp_name: String = damage_option.get_item_text(idx)
    if current_config.damagePointData.damagePointDictionary.has(dp_name):
        current_config.damagePointData.SetDamagePointFliters(preview_sprite, dp_name)
        preview_sprite.UpdataChild()

func _on_custom_option_changed(idx: int) -> void :
    if not is_instance_valid(preview_sprite) or not current_config:
        return
    if not current_config.customData:
        return
    current_config.customData.ClearCustomFliters(preview_sprite)
    preview_sprite.UpdataChild()
    if idx <= 0:
        return
    var cu_name: String = custom_option.get_item_text(idx)
    if current_config.customData.customDictionary.has(cu_name):
        current_config.customData.SetCustomFliters(preview_sprite, cu_name)
        preview_sprite.UpdataChild()

func _on_armor_option_changed(idx: int) -> void :
    if not is_instance_valid(preview_sprite) or not current_config:
        return
    if not current_config.armorData:
        return
    current_config.armorData.ClearArmorFlitersAll(preview_sprite)
    preview_sprite.UpdataChild()
    if idx <= 0:
        return
    var ar_name: String = armor_option.get_item_text(idx)
    if current_config.armorData.armorDictionary.has(ar_name):
        current_config.armorData.OpenArmorFliters(preview_sprite, ar_name)
        current_config.armorData.SetArmorReplace(preview_sprite, ar_name, 0)
        preview_sprite.UpdataChild()

func _on_main_tab_changed(tab_idx: int) -> void :
    if not is_instance_valid(preview_sprite) or not current_config:
        return
    if tab_idx == 0:
        damage_option.select(0)
        custom_option.select(0)
        armor_option.select(0)
        if current_config.damagePointData:
            current_config.damagePointData.ClearDamagePointAll(preview_sprite)
        if current_config.customData:
            current_config.customData.ClearCustomFliters(preview_sprite)
        if current_config.armorData:
            current_config.armorData.ClearArmorFlitersAll(preview_sprite)
        preview_sprite.UpdataChild()

func _ShowConfigEditor(char_name: String, char_data: Dictionary) -> void :
    _ClearChildren(config_fields)
    var config_path: = _FindConfigPath(char_name, char_data)
    if config_path.is_empty():
        var l: = Label.new()
        l.text = "  (未找到角色配置)"
        l.add_theme_color_override("font_color", Color.GRAY)
        config_fields.add_child(l)
        current_config = null
        return
    var res: Resource = load(config_path)
    if res is TowerDefenseCharacterConfig:
        current_config = res
        _BuildConfigFields(res)
        EditorInterface.edit_resource(res)
    else:
        current_config = null
        var l: = Label.new()
        l.text = "  (配置类型不匹配)" if res else "  (无法加载配置)"
        l.add_theme_color_override("font_color", Color.GRAY)
        config_fields.add_child(l)

func _FindConfigPath(char_name: String, char_data: Dictionary) -> String:
    var pd: Dictionary = char_data.get("Packet", {})
    if not pd.is_empty():
        for pk in pd:
            var puid: String = str(pd[pk])
            if puid.is_empty():
                continue
            var pr: Resource = load(puid)
            if pr is TowerDefensePacketConfig:
                var cfg: TowerDefenseCharacterConfig = pr.characterConfig
                if cfg and not cfg.resource_path.is_empty():
                    return cfg.resource_path
    var cat: = character_categories.get(char_name, "")
    var sub: = ""
    match cat:
        CATEGORY_PLANT: sub = "Plant/"
        CATEGORY_ZOMBIE: sub = "Zombie/"
        CATEGORY_ITEM: sub = "Item/"
        CATEGORY_MOWER: sub = "Mower/"
        CATEGORY_VASE: sub = "Vase/"
        CATEGORY_GRAVESTONE: sub = "GraveStone/"
        CATEGORY_CRATER: sub = "Crater/"
        _: return ""
    var base: = "res://Asset/Anime/Character/" + sub
    var paths: = [base + "Config/", base]
    for sp in paths:
        if not DirAccess.dir_exists_absolute(sp):
            continue
        var da: = DirAccess.open(sp)
        if not da:
            continue
        da.list_dir_begin()
        var fn: = da.get_next()
        while not fn.is_empty():
            if fn.begins_with(char_name) and fn.ends_with(".tres"):
                da.list_dir_end()
                return sp + fn
            fn = da.get_next()
        da.list_dir_end()
    return ""

func _BuildConfigFields(config: TowerDefenseCharacterConfig) -> void :
    _F("名称", "name", config.name, config, TYPE_STRING)
    _F("血量", "hitpoints", config.get("hitpoints"), config, TYPE_FLOAT)
    _F("濒死血量", "hitpointsNearDeath", config.get("hitpointsNearDeath"), config, TYPE_FLOAT)
    _F("爆炸伤害", "explosionHurt", config.explosionHurt, config, TYPE_FLOAT)
    _F("碾压伤害", "smashHurt", config.smashHurt, config, TYPE_FLOAT)
    _F("拖拽伤害", "dragHurt", config.dragHurt, config, TYPE_FLOAT)
    _F("尖刺伤害", "spikeHurt", config.spikeHurt, config, TYPE_FLOAT)
    _F("啃咬伤害", "biteHurt", config.biteHurt, config, TYPE_FLOAT)
    _S("布尔")
    _F("可拖入水中", "canDragIntoWater", config.canDragIntoWater, config, TYPE_BOOL)
    _F("可模仿", "canImitate", config.canImitate, config, TYPE_BOOL)
    _F("可复制", "canCopy", config.canCopy, config, TYPE_BOOL)
    _F("警告线过滤", "warnningLineFliter", config.warnningLineFliter, config, TYPE_BOOL)
    _S("睡眠/高度")
    _E("睡眠时间", "sleepTime", config.sleepTime, config, ["Never", "Night", "Day"])
    _E("高度", "height", config.height, config, ["GROUND", "LOW", "NORMAL", "TALL"])
    _S("资源引用")
    _R("伤害点数据", "damagePointData", config.damagePointData, config, "CharacterDamagePointData")
    _R("护甲数据", "armorData", config.armorData, config, "CharacterArmorData")
    _R("自定义数据", "customData", config.customData, config, "CharacterCustomData")
    _R("灰烬场景", "ashScene", config.ashScene, config, "PackedScene")
    _S("卡片属性")
    _E("所属世界", "homeWorld", config.homeWorld, config, ["NOONE", "MORDEN"])
    _F("费用", "cost", config.cost, config, TYPE_INT)
    _F("费用递增", "costRise", config.costRise, config, TYPE_INT)
    _F("夜间费用", "costNight", config.costNight, config, TYPE_INT)
    _F("费用倍率", "costMultiple", config.costMultiple, config, TYPE_FLOAT)
    _F("冷却时间", "packetCooldown", config.packetCooldown, config, TYPE_FLOAT)
    _F("初始冷却", "startingCooldown", config.startingCooldown, config, TYPE_FLOAT)
    _S("种植属性")
    _F("覆盖全部", "plantCoverAll", config.plantCoverAll, config, TYPE_BOOL)
    _F("覆盖自身", "plantCoverSelf", config.plantCoverSelf, config, TYPE_BOOL)
    _F("可周围种植", "plantCanHasSurround", config.plantCanHasSurround, config, TYPE_BOOL)
    _F("周围可种水", "plantSurroundCanPlantWater", config.plantSurroundCanPlantWater, config, TYPE_BOOL)
    _F("周围可有槽", "plantSurroundCanHasSlot", config.plantSurroundCanHasSlot, config, TYPE_BOOL)
    if config is TowerDefensePlantConfig:
        _S("植物特有")
        _F("可使用植物食物", "canUsePlantfood", config.canUsePlantfood, config, TYPE_BOOL)
        _F("IZM2过滤", "izm2Fliter", config.izm2Fliter, config, TYPE_BOOL)
    elif config is TowerDefenseZombieConfig:
        var zc: TowerDefenseZombieConfig = config as TowerDefenseZombieConfig
        _S("僵尸特有")
        _E("体型", "physique", zc.physique, zc, ["NOONE", "SMALL", "NORMAL", "MID", "HUGE", "CAR", "BOSS"])
        _F("攻击力", "attack", zc.attack, zc, TYPE_FLOAT)
        _F("碾压攻击", "smashAttack", zc.smashAttack, zc, TYPE_FLOAT)
        _F("碰撞音效", "impactAudio", zc.impactAudio, zc, TYPE_STRING)
        _S("生成属性")
        _F("预览", "preview", zc.preview, zc, TYPE_BOOL)
        _F("权重", "weight", zc.weight, zc, TYPE_INT)
        _F("波次点消耗", "wavePointCost", zc.wavePointCost, zc, TYPE_INT)
        _F("可生成植物食物", "canSpawnPlantfood", zc.canSpawnPlantfood, zc, TYPE_BOOL)
    elif config is TowerDefenseItemConfig:
        _S("道具特有")
        _F("是梯子", "isLadder", config.isLadder, config, TYPE_BOOL)
    elif config is TowerDefenseGravestoneConfig:
        _S("墓碑特有")
        _F("是宝箱", "isChests", config.isChests, config, TYPE_BOOL)
    elif config is TowerDefenseCraterConfig:
        _S("弹坑特有")
        _F("消散时间", "dieDownTime", config.dieDownTime, config, TYPE_FLOAT)
    elif config is TowerDefenseVaseConfig:
        _S("花瓶特有")
        _E("花瓶类型", "type", config.type, config, ["NORMAL", "PLANT", "ZOMBIE"])

func _S(title: String) -> void :
    config_fields.add_child(HSeparator.new())
    var l: = Label.new()
    l.text = title
    l.add_theme_font_size_override("font_size", 13)
    l.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
    config_fields.add_child(l)

func _F(label_text: String, prop: String, value: Variant, cfg: Resource, type: int) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    match type:
        TYPE_STRING:
            var e: = LineEdit.new()
            e.text = str(value)
            e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            e.text_changed.connect( func(t: String) -> void : cfg.set(prop, t))
            row.add_child(e)
        TYPE_FLOAT:
            var s: = SpinBox.new()
            s.min_value = -999999999.0
            s.max_value = 999999999.0
            s.step = 0.1
            s.value = float(value)
            s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            s.value_changed.connect( func(v: float) -> void : cfg.set(prop, v))
            row.add_child(s)
        TYPE_INT:
            var s: = SpinBox.new()
            s.min_value = -999999999
            s.max_value = 999999999
            s.step = 1
            s.value = int(value)
            s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            s.value_changed.connect( func(v: float) -> void : cfg.set(prop, int(v)))
            row.add_child(s)
        TYPE_BOOL:
            var c: = CheckBox.new()
            c.button_pressed = bool(value)
            c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            c.toggled.connect( func(p: bool) -> void : cfg.set(prop, p))
            row.add_child(c)
    config_fields.add_child(row)

func _E(label_text: String, prop: String, value: Variant, cfg: Resource, opts: Array) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    var ob: = OptionButton.new()
    for i in opts.size():
        ob.add_item(opts[i], i)
        if value is int and int(value) == i:
            ob.select(i)
        elif str(value) == opts[i]:
            ob.select(i)
    ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    ob.item_selected.connect( func(idx: int) -> void :
        if value is int:
            cfg.set(prop, idx)
        else:
            cfg.set(prop, opts[idx])
    )
    row.add_child(ob)
    config_fields.add_child(row)

func _R(label_text: String, prop: String, value: Resource, cfg: Resource, hint: String) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    var p: = EditorResourcePicker.new()
    p.base_type = hint
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    p.editable = true
    if value:
        p.edited_resource = value
    p.resource_changed.connect( func(r: Resource) -> void : cfg.set(prop, r))
    row.add_child(p)
    config_fields.add_child(row)

func _ShowPacketEditor(char_name: String, char_data: Dictionary) -> void :
    _ClearChildren(packet_fields)
    _current_pkt = null
    _ClearPacketSprite()
    packet_card_bg.texture = null
    packet_card_cost.text = ""
    var pd: Dictionary = char_data.get("Packet", {})
    if pd.is_empty():
        var l: = Label.new()
        l.text = "  (无卡片配置)"
        l.add_theme_color_override("font_color", Color.GRAY)
        packet_fields.add_child(l)
        return
    for pk in pd:
        var puid: String = str(pd[pk])
        if puid.is_empty():
            continue
        var frame: = PanelContainer.new()
        var vb: = VBoxContainer.new()
        var hdr: = HBoxContainer.new()
        var nl: = Label.new()
        nl.text = "卡片: %s" % pk
        nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hdr.add_child(nl)
        vb.add_child(hdr)
        var pr: Resource = load(puid)
        if pr is TowerDefensePacketConfig:
            _BuildPacketFields(pr, vb)
            _current_pkt = pr
            _RenderPacketPreview(pr)
        else:
            var pl: = Label.new()
            pl.text = "  路径: %s" % puid
            pl.add_theme_color_override("font_color", Color.GRAY)
            vb.add_child(pl)
        frame.add_child(vb)
        packet_fields.add_child(frame)

func _ClearPacketSprite() -> void :
    if is_instance_valid(_packet_sprite_inst):
        _packet_sprite_inst.queue_free()
    _packet_sprite_inst = null

func _RenderPacketPreview(pkt: TowerDefensePacketConfig) -> void :
    if not packet_card_bg or not packet_card_vp:
        return
    _ClearPacketSprite()
    packet_card_bg.texture = _GetPacketBackgroundTexture(pkt, packet_preview_mode)
    var cost_val: = _SCost(pkt)
    if pkt.GetCostRise() != -1:
        packet_card_cost.text = str(int(cost_val)) + "+"
    else:
        packet_card_cost.text = str(int(cost_val))
    _UpdatePacketCardLayout()
    var char_data: Dictionary = character_data_map.get(current_character_name, {})
    var sprite_uid: String = str(char_data.get("Sprite", ""))
    var sprite_inst: Node = null
    if not sprite_uid.is_empty():
        var res: Resource = load(sprite_uid)
        if res is PackedScene:
            sprite_inst = res.instantiate()
    if sprite_inst == null:
        var scene_uid: String = str(char_data.get("Scene", ""))
        if not scene_uid.is_empty():
            var res: Resource = load(scene_uid)
            if res is PackedScene:
                sprite_inst = res.instantiate()
    if sprite_inst == null:
        return
    packet_card_vp.add_child(sprite_inst)
    _packet_sprite_inst = sprite_inst
    if sprite_inst is Node2D:
        var is_mobile: = packet_preview_mode
        var base_scale: = pkt.packetAnimeScale if pkt.packetAnimeScale != Vector2.ZERO else Vector2.ONE
        if is_mobile:
            if current_config is TowerDefenseZombieConfig:
                sprite_inst.position = pkt.packetAnimeOffset * 1.2 * 4.0
            else:
                sprite_inst.position = pkt.packetAnimeOffset * 4.0
            sprite_inst.scale = base_scale * 1.25 * 4.0
        else:
            sprite_inst.position = pkt.packetAnimeOffset * 4.0
            sprite_inst.scale = base_scale * 4.0
        if pkt.packetFlip:
            sprite_inst.scale.x = - abs(sprite_inst.scale.x)
        var sp: = _FindSprite(sprite_inst)
        if sp:
            if not pkt.packetAnimeClip.is_empty():
                sp.SetAnimation(pkt.packetAnimeClip, true)
            sp.pause = false

func _GetPacketBackgroundTexture(pkt: TowerDefensePacketConfig, is_mobile: bool) -> Texture2D:
    var ptype: int = pkt.type if pkt.get("type") != null else 0
    if is_mobile:
        match ptype:
            0: return load("uid://bwfy3kman4ich")
            1: return load("uid://2smnyulcahs3")
            2: return load("uid://1242bw5k8uwq")
            3: return load("uid://cdrj5bkubm7la")
            4: return load("uid://dxa7vky1ueb2o")
            5: return load("uid://bwfy3kman4ich")
            6: return load("uid://csgt5dkel0xeb")
            7: return load("uid://3k84w2g5d10r")
            8: return load("uid://dfy7jg4c8v30x")
            _: return load("uid://bwfy3kman4ich")
    else:
        match ptype:
            0: return load("uid://bwksngvkn16cd")
            1: return load("uid://dfihegby6yat6")
            2: return load("uid://eutur83nlbar")
            3: return load("uid://dricqt0scm3sm")
            4: return load("uid://bwnw5thitfc8e")
            5: return load("uid://bwksngvkn16cd")
            6: return load("uid://btgdkkg66xc8d")
            7: return load("uid://dbkcwpq2ie7t0")
            8: return load("uid://dfy7jg4c8v30x")
            _: return load("uid://bwksngvkn16cd")
    return null

func _UpdatePacketCardLayout() -> void :
    if not packet_card_root:
        return
    var is_mobile: = packet_preview_mode
    if is_mobile:
        packet_card_root.scale = Vector2(2, 2)
        packet_card_root.custom_minimum_size = Vector2(96, 60)
        packet_card_bg.size = Vector2(96, 60)
        packet_card_bg.position = Vector2(0, 0)
        packet_card_vpc.position = Vector2(6, 6)
        packet_card_vpc.size = Vector2(82.0, 46.0) * 4.0
        packet_card_cost.position = Vector2(45, 32)
        packet_card_cost.size = Vector2(48, 25)
        packet_card_cost.texture_filter = TextureFilter.TEXTURE_FILTER_PARENT_NODE
        packet_card_cost.add_theme_font_size_override("font_size", 24)
        packet_card_cost.add_theme_color_override("font_color", Color.WHITE)
        packet_card_cost.add_theme_color_override("font_outline_color", Color.BLACK)
        packet_card_cost.add_theme_constant_override("outline_size", 5)
        var fzt: = load("uid://coqskwlqtnypf")
        if fzt:
            packet_card_cost.add_theme_font_override("font", fzt)
    else:
        packet_card_root.scale = Vector2(3, 3)
        packet_card_root.custom_minimum_size = Vector2(50, 70)
        packet_card_bg.size = Vector2(50, 70)
        packet_card_bg.position = Vector2(0, 0)
        packet_card_vpc.position = Vector2(3, 6)
        packet_card_vpc.size = Vector2(176, 188)
        packet_card_cost.texture_filter = TextureFilter.TEXTURE_FILTER_LINEAR
        packet_card_cost.position = Vector2(2, 52)
        packet_card_cost.size = Vector2(35, 17)
        packet_card_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        packet_card_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        packet_card_cost.add_theme_font_size_override("font_size", 12)
        packet_card_cost.add_theme_color_override("font_color", Color.BLACK)
        packet_card_cost.remove_theme_constant_override("outline_size")
        var pcf: = load("uid://dww00k8yk5k72")
        if pcf:
            packet_card_cost.add_theme_font_override("font", pcf)
    _UpdatePacketSpriteLayout()

func _UpdatePacketSpriteLayout() -> void :
    if not is_instance_valid(_packet_sprite_inst) or not _current_pkt:
        return
    var pkt: TowerDefensePacketConfig = _current_pkt
    var inst: Node2D = _packet_sprite_inst as Node2D
    if not inst:
        return
    var is_mobile: = packet_preview_mode
    var base_scale: = pkt.packetAnimeScale if pkt.packetAnimeScale != Vector2.ZERO else Vector2.ONE
    if is_mobile:
        if current_config is TowerDefenseZombieConfig:
            inst.position = pkt.packetAnimeOffset * 1.2 * 4.0
        else:
            inst.position = pkt.packetAnimeOffset * 4.0
        inst.scale = base_scale * 1.25 * 4.0
    else:
        inst.position = pkt.packetAnimeOffset * 4.0
        inst.scale = base_scale * 4.0
    if pkt.packetFlip:
        inst.scale.x = - abs(inst.scale.x)

func _on_packet_mode_pc() -> void :
    if not packet_preview_mode:
        return
    packet_preview_mode = false
    packet_mode_pc_btn.button_pressed = true
    packet_mode_mobile_btn.button_pressed = false
    _UpdatePacketCardLayout()
    if _current_pkt:
        packet_card_bg.texture = _GetPacketBackgroundTexture(_current_pkt, false)
        _RenderPacketPreview(_current_pkt)

func _on_packet_mode_mobile() -> void :
    if packet_preview_mode:
        return
    packet_preview_mode = true
    packet_mode_pc_btn.button_pressed = false
    packet_mode_mobile_btn.button_pressed = true
    _UpdatePacketCardLayout()
    if _current_pkt:
        packet_card_bg.texture = _GetPacketBackgroundTexture(_current_pkt, true)
        _RenderPacketPreview(_current_pkt)

func _BuildPacketFields(pkt: TowerDefensePacketConfig, vb: VBoxContainer) -> void :
    _PF(vb, "名称", pkt.name)
    _PF(vb, "描述", pkt.describe if pkt.get("describe") != null else "")
    _PF(vb, "存档键", pkt.saveKey if pkt.get("saveKey") != null else "")
    var tv: int = pkt.type if pkt.get("type") != null else 0
    var tn: = ["WHITE", "GOLD", "DIAMOND", "COLOUR", "STAR", "ORIGINAL", "ZOMBIE", "COVER", "GRAY"]
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = "卡片类型"
    l.custom_minimum_size.x = 80
    row.add_child(l)
    var ob: = OptionButton.new()
    for i in tn.size():
        ob.add_item(tn[i], i)
        if tv == i:
            ob.select(i)
    ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    ob.item_selected.connect( func(idx: int) -> void :
        pkt.set("type", idx)
        packet_card_bg.texture = _GetPacketBackgroundTexture(pkt, packet_preview_mode)
    )
    row.add_child(ob)
    vb.add_child(row)
    _PS(vb, "费用", _SCost(pkt), pkt, "overrideCost")
    _PS(vb, "冷却时间", _SCd(pkt), pkt, "overridePacketCooldown", true)
    _PS(vb, "初始冷却", _SScd(pkt), pkt, "overrideStartingCooldown", true)
    var cfg: TowerDefenseCharacterConfig = pkt.characterConfig
    if cfg:
        var cr: = HBoxContainer.new()
        var cl: = Label.new()
        cl.text = "角色配置"
        cl.custom_minimum_size.x = 80
        cr.add_child(cl)
        var p: = EditorResourcePicker.new()
        p.base_type = "TowerDefenseCharacterConfig"
        p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        p.editable = true
        p.edited_resource = cfg
        p.resource_changed.connect( func(r: Resource) -> void : pkt.set("characterConfig", r))
        cr.add_child(p)
        vb.add_child(cr)

func _PF(vb: VBoxContainer, lt: String, val: String) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = lt
    l.custom_minimum_size.x = 80
    row.add_child(l)
    var e: = LineEdit.new()
    e.text = val
    e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(e)
    vb.add_child(row)

func _PS(vb: VBoxContainer, lt: String, val: float, pkt: Resource, prop: String, is_f: bool = false) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = lt
    l.custom_minimum_size.x = 80
    row.add_child(l)
    var s: = SpinBox.new()
    s.min_value = -999999999
    s.max_value = 999999999
    s.step = 0.1 if is_f else 1
    s.value = val
    s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    s.value_changed.connect( func(v: float) -> void :
        if is_f: pkt.set(prop, v)
        else: pkt.set(prop, int(v))
    )
    row.add_child(s)
    vb.add_child(row)

func _ParseFilterStr(s: String) -> PackedStringArray:
    if s.is_empty():
        return PackedStringArray()
    return s.split("&", false)

func _BuildFilterStr(parts: PackedStringArray) -> String:
    var filtered: = PackedStringArray()
    for p in parts:
        if not p.is_empty():
            filtered.append(p)
    return "&".join(filtered)

func _BuildFilterCheckboxes(container: VBoxContainer, layer_names: PackedStringArray, open_str: String, close_str: String, open_setter: Callable, close_setter: Callable, extra_label: String, extra_str: String, extra_setter: Callable, on_preview: Callable) -> void :
    var open_set: = {}
    for p in _ParseFilterStr(open_str):
        open_set[p] = true
    var close_set: = {}
    for p in _ParseFilterStr(close_str):
        close_set[p] = true
    var extra_set: = {}
    if not extra_label.is_empty():
        for p in _ParseFilterStr(extra_str):
            extra_set[p] = true

    var has_extra: = not extra_label.is_empty()

    var header_row: = HBoxContainer.new()
    var name_hdr: = Label.new()
    name_hdr.text = "图层名"
    name_hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_hdr.custom_minimum_size.x = 120
    header_row.add_child(name_hdr)
    var show_hdr: = Label.new()
    show_hdr.text = "显示"
    show_hdr.custom_minimum_size.x = 50
    show_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    header_row.add_child(show_hdr)
    var hide_hdr: = Label.new()
    hide_hdr.text = "隐藏"
    hide_hdr.custom_minimum_size.x = 50
    hide_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    header_row.add_child(hide_hdr)
    if has_extra:
        var extra_hdr: = Label.new()
        extra_hdr.text = extra_label
        extra_hdr.custom_minimum_size.x = 50
        extra_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        header_row.add_child(extra_hdr)
    container.add_child(header_row)

    var sep: = HSeparator.new()
    container.add_child(sep)

    var show_arr: = []
    var hide_arr: = []
    var extra_arr: = []

    for layer_name in layer_names:
        var row: = HBoxContainer.new()
        var nl: = Label.new()
        nl.text = layer_name
        nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        nl.custom_minimum_size.x = 120
        nl.add_theme_font_size_override("font_size", 11)
        row.add_child(nl)

        var show_cb: = CheckBox.new()
        show_cb.button_pressed = open_set.has(layer_name)
        show_cb.custom_minimum_size.x = 50
        show_cb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        row.add_child(show_cb)
        show_arr.append(show_cb)

        var hide_cb: = CheckBox.new()
        hide_cb.button_pressed = close_set.has(layer_name)
        hide_cb.custom_minimum_size.x = 50
        hide_cb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        row.add_child(hide_cb)
        hide_arr.append(hide_cb)

        var extra_cb: CheckBox = null
        if has_extra:
            extra_cb = CheckBox.new()
            extra_cb.button_pressed = extra_set.has(layer_name)
            extra_cb.custom_minimum_size.x = 50
            extra_cb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
            row.add_child(extra_cb)
            extra_arr.append(extra_cb)

        var captured_idx: = show_arr.size() - 1

        show_cb.toggled.connect( func(pressed: bool) -> void :
            if pressed:
                hide_cb.button_pressed = false
                if has_extra and extra_arr[captured_idx]:
                    extra_arr[captured_idx].button_pressed = false
            _SyncFilterFromCheckboxes(layer_names, show_arr, hide_arr, extra_arr, has_extra, open_setter, close_setter, extra_setter)
            on_preview.call()
        )
        hide_cb.toggled.connect( func(pressed: bool) -> void :
            if pressed:
                show_cb.button_pressed = false
                if has_extra and extra_arr[captured_idx]:
                    extra_arr[captured_idx].button_pressed = false
            _SyncFilterFromCheckboxes(layer_names, show_arr, hide_arr, extra_arr, has_extra, open_setter, close_setter, extra_setter)
            on_preview.call()
        )
        if has_extra and extra_cb:
            extra_cb.toggled.connect( func(pressed: bool) -> void :
                if pressed:
                    show_cb.button_pressed = false
                    hide_cb.button_pressed = false
                _SyncFilterFromCheckboxes(layer_names, show_arr, hide_arr, extra_arr, has_extra, open_setter, close_setter, extra_setter)
                on_preview.call()
            )

        container.add_child(row)

func _SyncFilterFromCheckboxes(layer_names: PackedStringArray, show_arr: Array, hide_arr: Array, extra_arr: Array, has_extra: bool, open_setter: Callable, close_setter: Callable, extra_setter: Callable) -> void :
    var open_parts: = PackedStringArray()
    var close_parts: = PackedStringArray()
    var extra_parts: = PackedStringArray()
    for i in layer_names.size():
        if i < show_arr.size() and show_arr[i].button_pressed:
            open_parts.append(layer_names[i])
        if i < hide_arr.size() and hide_arr[i].button_pressed:
            close_parts.append(layer_names[i])
        if has_extra and i < extra_arr.size() and extra_arr[i].button_pressed:
            extra_parts.append(layer_names[i])
    open_setter.call(_BuildFilterStr(open_parts))
    close_setter.call(_BuildFilterStr(close_parts))
    if has_extra:
        extra_setter.call(_BuildFilterStr(extra_parts))

func _ApplyDamagePreview() -> void :
    if not is_instance_valid(preview_sprite) or not current_config:
        return
    if not current_config.damagePointData:
        return
    current_config.damagePointData.ClearDamagePointAll(preview_sprite)
    preview_sprite.UpdataChild()
    var idx: = damage_list.get_selected_items()
    if idx.is_empty():
        return
    var sel_idx: int = idx[0]
    if sel_idx < 0 or sel_idx >= current_config.damagePointData.damagePointList.size():
        return
    var cfg: CharacterDamagePointConfig = current_config.damagePointData.damagePointList[sel_idx]
    var open_parts: = _ParseFilterStr(cfg.animeFliterOpen)
    var close_parts: = _ParseFilterStr(cfg.animeFliterClose)
    if not open_parts.is_empty():
        preview_sprite.SetFliters(Array(open_parts), true)
    if not close_parts.is_empty():
        preview_sprite.SetFliters(Array(close_parts), false)
    if cfg.replaceMediaName:
        preview_sprite.SetReplace(cfg.replaceMediaName, cfg.replaceMediaTexture)
    preview_sprite.UpdataChild()

func _ApplyCustomPreview() -> void :
    if not is_instance_valid(preview_sprite) or not current_config:
        return
    if not current_config.customData:
        return
    current_config.customData.ClearCustomFliters(preview_sprite)
    preview_sprite.UpdataChild()
    var idx: = custom_list.get_selected_items()
    if idx.is_empty():
        return
    var sel_idx: int = idx[0]
    if sel_idx < 0 or sel_idx >= current_config.customData.customList.size():
        return
    var cfg: CharacterCustomConfig = current_config.customData.customList[sel_idx]
    var open_parts: = _ParseFilterStr(cfg.animeFliterOpen)
    var close_parts: = _ParseFilterStr(cfg.animeFliterClose)
    if not open_parts.is_empty():
        preview_sprite.SetFliters(Array(open_parts), true)
    if not close_parts.is_empty():
        preview_sprite.SetFliters(Array(close_parts), false)
    preview_sprite.UpdataChild()

func _ApplyArmorPreview() -> void :
    if not is_instance_valid(preview_sprite) or not current_config:
        return
    if not current_config.armorData:
        return
    current_config.armorData.ClearArmorFlitersAll(preview_sprite)
    preview_sprite.UpdataChild()
    var idx: = armor_list.get_selected_items()
    if idx.is_empty():
        return
    var sel_idx: int = idx[0]
    if sel_idx < 0 or sel_idx >= current_config.armorData.armorList.size():
        return
    var cfg: ArmorSlotConfig = current_config.armorData.armorList[sel_idx]
    TowerDefenseArmorRegistry.Init()
    var typeData: TowerDefenseArmorTypeData = TowerDefenseArmorRegistry.GetArmorType(cfg.armorName)
    if typeData:
        var open_parts: = _ParseFilterStr(cfg.openFliter)
        var close_parts: = _ParseFilterStr(cfg.closeFliter)
        if not open_parts.is_empty():
            preview_sprite.SetFliters(Array(open_parts), true)
        if not close_parts.is_empty():
            preview_sprite.SetFliters(Array(close_parts), false)
        preview_sprite.UpdataChild()

func _ShowDamageEditor() -> void :
    damage_list.clear()
    _ClearChildren(damage_detail)
    if not current_config or not current_config.damagePointData:
        return
    var dp_data: CharacterDamagePointData = current_config.damagePointData
    if dp_data.damagePointDictionary.is_empty():
        dp_data.Refresh()
    for i in dp_data.damagePointList.size():
        var cfg: CharacterDamagePointConfig = dp_data.damagePointList[i]
        var display_name: String = cfg.damagePointName if cfg.damagePointName else "破损点 #%d" % (i + 1)
        damage_list.add_item(display_name)
    if damage_list.item_count > 0:
        damage_list.select(0)
        _on_damage_list_selected(0)

func _on_damage_list_selected(idx: int) -> void :
    _ClearChildren(damage_detail)
    if not current_config or not current_config.damagePointData:
        return
    if idx < 0 or idx >= current_config.damagePointData.damagePointList.size():
        return
    if idx + 1 < damage_option.item_count:
        damage_option.select(idx + 1)
    var cfg: CharacterDamagePointConfig = current_config.damagePointData.damagePointList[idx]

    var hdr: = HBoxContainer.new()
    var title: = Label.new()
    title.text = cfg.damagePointName if cfg.damagePointName else "破损点 #%d" % (idx + 1)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 14)
    hdr.add_child(title)
    var del_btn: = Button.new()
    del_btn.text = "删除"
    del_btn.custom_minimum_size.x = 50
    del_btn.pressed.connect( func(captured_idx = idx) -> void :
        var removed_cfg: CharacterDamagePointConfig = current_config.damagePointData.damagePointList[captured_idx]
        current_config.damagePointData.damagePointList.remove_at(captured_idx)
        current_config.damagePointData.Refresh()
        _DeleteResourceFile(removed_cfg)
        _SaveDamagePointData()
        _ShowDamageEditor()
    )
    hdr.add_child(del_btn)
    damage_detail.add_child(hdr)

    var sub_tabs: = TabContainer.new()
    sub_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sub_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var prop_tab: = ScrollContainer.new()
    prop_tab.name = "属性"
    prop_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    var prop_vb: = VBoxContainer.new()
    prop_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _AddFieldString(prop_vb, "名称", cfg.damagePointName, func(v: String) -> void : cfg.damagePointName = v)
    _AddFieldFloat(prop_vb, "伤害百分比", cfg.damagePersontage, func(v: float) -> void :
        cfg.damagePersontage = v
        if current_config and current_config.damagePointData:
            current_config.damagePointData.Refresh()
            _ShowDamageEditor()
    )
    _AddFieldResource(prop_vb, "特效场景", "PackedScene", cfg.animeEffect, func(r: Resource) -> void : cfg.animeEffect = r)
    _AddFieldVector2(prop_vb, "特效偏移", cfg.animeEffectOffset, func(v: Vector2) -> void : cfg.animeEffectOffset = v)
    _AddFieldBool(prop_vb, "是否掉落", cfg.isDrop, func(v: bool) -> void : cfg.isDrop = v)
    _AddFieldString(prop_vb, "替换媒体名", str(cfg.replaceMediaName), func(v: String) -> void : cfg.replaceMediaName = StringName(v))
    _AddFieldResource(prop_vb, "替换贴图", "Texture2D", cfg.replaceMediaTexture, func(r: Resource) -> void : cfg.replaceMediaTexture = r)
    _AddFieldString(prop_vb, "受伤音效", cfg.damageAudio, func(v: String) -> void : cfg.damageAudio = v)
    prop_tab.add_child(prop_vb)
    sub_tabs.add_child(prop_tab)

    var filter_tab: = ScrollContainer.new()
    filter_tab.name = "滤镜"
    filter_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    var filter_vb: = VBoxContainer.new()
    filter_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var layer_names: = _GetLayerNames()
    if layer_names.is_empty():
        var hint: = Label.new()
        hint.text = "  (无Sprite图层信息，请选择有Sprite的角色)"
        hint.add_theme_color_override("font_color", Color.GRAY)
        filter_vb.add_child(hint)
    else:
        _BuildFilterCheckboxes(filter_vb, layer_names, cfg.animeFliterOpen, cfg.animeFliterClose, func(v: String) -> void : cfg.animeFliterOpen = v, func(v: String) -> void : cfg.animeFliterClose = v, "", "", func() -> void : pass, _ApplyDamagePreview)
    filter_tab.add_child(filter_vb)
    sub_tabs.add_child(filter_tab)

    damage_detail.add_child(sub_tabs)

func _ShowCustomEditor() -> void :
    custom_list.clear()
    _ClearChildren(custom_detail)
    if not current_config or not current_config.customData:
        return
    var cu_data: CharacterCustomData = current_config.customData
    if cu_data.customDictionary.is_empty():
        cu_data.Init()
    for i in cu_data.customList.size():
        var cfg: CharacterCustomConfig = cu_data.customList[i]
        var display_name: String = cfg.customName if cfg.customName else "皮肤 #%d" % (i + 1)
        custom_list.add_item(display_name)
    if custom_list.item_count > 0:
        custom_list.select(0)
        _on_custom_list_selected(0)

func _on_custom_list_selected(idx: int) -> void :
    _ClearChildren(custom_detail)
    if not current_config or not current_config.customData:
        return
    if idx < 0 or idx >= current_config.customData.customList.size():
        return
    if idx + 1 < custom_option.item_count:
        custom_option.select(idx + 1)
    var cfg: CharacterCustomConfig = current_config.customData.customList[idx]

    var hdr: = HBoxContainer.new()
    var title: = Label.new()
    title.text = cfg.customName if cfg.customName else "皮肤 #%d" % (idx + 1)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 14)
    hdr.add_child(title)
    var del_btn: = Button.new()
    del_btn.text = "删除"
    del_btn.custom_minimum_size.x = 50
    del_btn.pressed.connect( func(captured_idx = idx) -> void :
        var removed_cfg: CharacterCustomConfig = current_config.customData.customList[captured_idx]
        current_config.customData.customList.remove_at(captured_idx)
        current_config.customData.Init()
        _DeleteResourceFile(removed_cfg)
        _SaveCustomData()
        _ShowCustomEditor()
    )
    hdr.add_child(del_btn)
    custom_detail.add_child(hdr)

    var sub_tabs: = TabContainer.new()
    sub_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sub_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var prop_tab: = ScrollContainer.new()
    prop_tab.name = "属性"
    prop_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    var prop_vb: = VBoxContainer.new()
    prop_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _AddFieldString(prop_vb, "开启键值", cfg.openKey, func(v: String) -> void : cfg.openKey = v)
    _AddFieldString(prop_vb, "名称", cfg.customName, func(v: String) -> void : cfg.customName = v)
    var type_opts: = PackedStringArray(["White", "Gold"])
    var type_idx: = 0
    if cfg.type == "Gold": type_idx = 1
    _AddFieldEnum(prop_vb, "类型", type_opts, type_idx, func(sel_idx: int) -> void : cfg.type = type_opts[sel_idx])
    _AddFieldString(prop_vb, "图鉴名称", cfg.customHandbookName, func(v: String) -> void : cfg.customHandbookName = v)
    _AddFieldString(prop_vb, "图鉴获取", cfg.customHandbookAccess, func(v: String) -> void : cfg.customHandbookAccess = v)
    _AddFieldString(prop_vb, "替换媒体名", cfg.damagePointChangeMediaName, func(v: String) -> void : cfg.damagePointChangeMediaName = v)
    _AddFieldTextureArray(prop_vb, "替换贴图数组", cfg.damagePointChangeMediaTexture, _ShowCustomEditor)
    _AddSectionLabel(prop_vb, "图鉴")
    _AddFieldMultiline(prop_vb, "图鉴故事", cfg.customHandbookStory, func(v: String) -> void : cfg.customHandbookStory = v)
    prop_tab.add_child(prop_vb)
    sub_tabs.add_child(prop_tab)

    var filter_tab: = ScrollContainer.new()
    filter_tab.name = "滤镜"
    filter_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    var filter_vb: = VBoxContainer.new()
    filter_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var layer_names: = _GetLayerNames()
    if layer_names.is_empty():
        var hint: = Label.new()
        hint.text = "  (无Sprite图层信息)"
        hint.add_theme_color_override("font_color", Color.GRAY)
        filter_vb.add_child(hint)
    else:
        _BuildFilterCheckboxes(filter_vb, layer_names, cfg.animeFliterOpen, cfg.animeFliterClose, func(v: String) -> void : cfg.animeFliterOpen = v, func(v: String) -> void : cfg.animeFliterClose = v, "", "", func() -> void : pass, _ApplyCustomPreview)
    filter_tab.add_child(filter_vb)
    sub_tabs.add_child(filter_tab)

    custom_detail.add_child(sub_tabs)

func _ShowArmorEditor() -> void :
    armor_list.clear()
    _ClearChildren(armor_detail)
    if not current_config or not current_config.armorData:
        return
    var ar_data: CharacterArmorData = current_config.armorData
    if ar_data.armorDictionary.is_empty():
        ar_data.Init()
    for i in ar_data.armorList.size():
        var cfg: ArmorSlotConfig = ar_data.armorList[i]
        var display_name: String = cfg.armorName if cfg.armorName else "护甲 #%d" % (i + 1)
        armor_list.add_item(display_name)
    if armor_list.item_count > 0:
        armor_list.select(0)
        _on_armor_list_selected(0)

func _on_armor_list_selected(idx: int) -> void :
    _ClearChildren(armor_detail)
    if not current_config or not current_config.armorData:
        return
    if idx < 0 or idx >= current_config.armorData.armorList.size():
        return
    if idx + 1 < armor_option.item_count:
        armor_option.select(idx + 1)
    var cfg: ArmorSlotConfig = current_config.armorData.armorList[idx]

    var hdr: = HBoxContainer.new()
    var title: = Label.new()
    title.text = cfg.armorName if cfg.armorName else "护甲 #%d" % (idx + 1)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 14)
    hdr.add_child(title)
    var del_btn: = Button.new()
    del_btn.text = "删除"
    del_btn.custom_minimum_size.x = 50
    del_btn.pressed.connect( func(captured_idx = idx) -> void :
        var removed_cfg: ArmorSlotConfig = current_config.armorData.armorList[captured_idx]
        current_config.armorData.armorList.remove_at(captured_idx)
        current_config.armorData.Init()
        _DeleteResourceFile(removed_cfg)
        _SaveArmorData()
        _ShowArmorEditor()
    )
    hdr.add_child(del_btn)
    armor_detail.add_child(hdr)

    var prop_scroll: = ScrollContainer.new()
    prop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    prop_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    prop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    var prop_vb: = VBoxContainer.new()
    prop_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _AddFieldString(prop_vb, "名称", cfg.armorName, func(v: String) -> void : cfg.armorName = v)
    _AddFieldEnum(prop_vb, "替换方式", PackedStringArray(["Media", "Sprite"]), 0 if cfg.replaceMethod == "Media" else 1, func(idx: int) -> void : cfg.replaceMethod = "Media" if idx == 0 else "Sprite")
    _AddFieldString(prop_vb, "替换媒体名", str(cfg.replaceMediaName), func(v: String) -> void : cfg.replaceMediaName = StringName(v))
    _AddFieldString(prop_vb, "节点路径", str(cfg.slotPath), func(v: String) -> void : cfg.slotPath = NodePath(v))
    _AddFieldVector2(prop_vb, "偏移", cfg.offset, func(v: Vector2) -> void : cfg.offset = v)
    _AddFieldFloat(prop_vb, "旋转", cfg.rotation, func(v: float) -> void : cfg.rotation = v)
    _AddFieldVector2(prop_vb, "缩放", cfg.scale, func(v: Vector2) -> void : cfg.scale = v)
    _AddFieldString(prop_vb, "开启过滤器", cfg.openFliter, func(v: String) -> void : cfg.openFliter = v)
    _AddFieldString(prop_vb, "关闭过滤器", cfg.closeFliter, func(v: String) -> void : cfg.closeFliter = v)
    _AddFieldString(prop_vb, "销毁过滤器", cfg.destroyFliter, func(v: String) -> void : cfg.destroyFliter = v)
    _AddFieldFloat(prop_vb, "护甲生命值", cfg.damagePoint, func(v: float) -> void : cfg.damagePoint = v, -1.0)
    prop_scroll.add_child(prop_vb)
    armor_detail.add_child(prop_scroll)

func _on_add_damage_point() -> void :
    if not current_config:
        return
    if not current_config.damagePointData:
        current_config.damagePointData = CharacterDamagePointData.new()
    var new_cfg: = CharacterDamagePointConfig.new()
    var idx: = current_config.damagePointData.damagePointList.size() + 1
    new_cfg.damagePointName = "Damage%d" % idx
    current_config.damagePointData.damagePointList.append(new_cfg)
    current_config.damagePointData.Refresh()
    var save_path: = _SaveDamagePointConfig(new_cfg)
    if not save_path.is_empty():
        var loaded: CharacterDamagePointConfig = load(save_path)
        if loaded:
            var lst: Array = current_config.damagePointData.damagePointList
            for i in lst.size():
                if lst[i] == new_cfg:
                    lst[i] = loaded
                    break
            current_config.damagePointData.Refresh()
        _SaveDamagePointData()
    _ShowDamageEditor()
    if damage_list.item_count > 0:
        damage_list.select(damage_list.item_count - 1)
        _on_damage_list_selected(damage_list.item_count - 1)

func _on_add_custom() -> void :
    if not current_config:
        return
    if not current_config.customData:
        current_config.customData = CharacterCustomData.new()
    var new_cfg: = CharacterCustomConfig.new()
    var idx: = current_config.customData.customList.size() + 1
    new_cfg.customName = "Custom%d" % idx
    current_config.customData.customList.append(new_cfg)
    current_config.customData.Init()
    var save_path: = _SaveCustomConfig(new_cfg)
    if not save_path.is_empty():
        var loaded: CharacterCustomConfig = load(save_path)
        if loaded:
            var lst: Array = current_config.customData.customList
            for i in lst.size():
                if lst[i] == new_cfg:
                    lst[i] = loaded
                    break
            current_config.customData.Init()
        _SaveCustomData()
    _ShowCustomEditor()
    if custom_list.item_count > 0:
        custom_list.select(custom_list.item_count - 1)
        _on_custom_list_selected(custom_list.item_count - 1)

func _on_add_armor() -> void :
    if not current_config:
        return
    if not current_config.armorData:
        current_config.armorData = CharacterArmorData.new()
    var new_cfg: = ArmorSlotConfig.new()
    var idx: = current_config.armorData.armorList.size() + 1
    new_cfg.armorName = "Armor%d" % idx
    current_config.armorData.armorList.append(new_cfg)
    current_config.armorData.Init()
    var save_path: = _SaveArmorConfig(new_cfg)
    if not save_path.is_empty():
        var loaded: ArmorSlotConfig = load(save_path)
        if loaded:
            var lst: Array = current_config.armorData.armorList
            for i in lst.size():
                if lst[i] == new_cfg:
                    lst[i] = loaded
                    break
            current_config.armorData.Init()
        _SaveArmorData()
    _ShowArmorEditor()
    if armor_list.item_count > 0:
        armor_list.select(armor_list.item_count - 1)
        _on_armor_list_selected(armor_list.item_count - 1)

func _GetCharacterDir() -> String:
    if current_character_name.is_empty():
        return ""
    var char_data: Dictionary = character_data_map.get(current_character_name, {})
    var sprite_uid: String = str(char_data.get("Sprite", ""))
    if sprite_uid.is_empty():
        sprite_uid = str(char_data.get("Scene", ""))
    if sprite_uid.is_empty():
        return ""
    var sprite_path: String = ResourceUID.get_id_path(ResourceUID.text_to_id(sprite_uid)) if sprite_uid.begins_with("uid://") else sprite_uid
    if sprite_path.is_empty():
        return ""
    return sprite_path.get_base_dir()

func _EnsureDir(path: String) -> void :
    if not DirAccess.dir_exists_absolute(path):
        DirAccess.make_dir_recursive_absolute(path)

func _DeleteResourceFile(res: Resource) -> void :
    if not res or res.resource_path.is_empty():
        return
    if ResourceLoader.exists(res.resource_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(res.resource_path))

func _GetFilePrefix() -> String:
    var cat: = character_categories.get(current_character_name, "")
    if cat == CATEGORY_PLANT and current_character_name.begins_with("Plant"):
        return current_character_name.substr(5)
    return current_character_name

func _SaveDamagePointConfig(cfg: CharacterDamagePointConfig) -> String:
    var base_dir: = _GetCharacterDir()
    if base_dir.is_empty():
        return ""
    var dp_dir: = base_dir.path_join("DamagePoint").path_join("Config")
    _EnsureDir(dp_dir)
    var prefix: = _GetFilePrefix()
    var file_name: String = cfg.damagePointName if cfg.damagePointName else "DamagePoint"
    var save_path: = dp_dir.path_join(prefix + "DamagePoint" + file_name + ".tres")
    ResourceSaver.save(cfg, save_path)
    return save_path

func _SaveCustomConfig(cfg: CharacterCustomConfig) -> String:
    var base_dir: = _GetCharacterDir()
    if base_dir.is_empty():
        return ""
    var c_dir: = base_dir.path_join("Custom").path_join("Config")
    _EnsureDir(c_dir)
    var prefix: = _GetFilePrefix()
    var file_name: String = cfg.customName if cfg.customName else "Custom"
    var save_path: = c_dir.path_join(prefix + file_name + ".tres")
    ResourceSaver.save(cfg, save_path)
    return save_path

func _SaveArmorConfig(cfg: ArmorSlotConfig) -> String:
    var base_dir: = _GetCharacterDir()
    if base_dir.is_empty():
        push_warning("[CharacterEditor] Cannot save armor config: character dir is empty")
        return ""
    var a_dir: = base_dir.path_join("Armor").path_join("Config")
    _EnsureDir(a_dir)
    var prefix: = _GetFilePrefix()
    var file_name: String = cfg.armorName if cfg.armorName else "Armor"
    var save_path: = a_dir.path_join(prefix + "Armor" + file_name + ".tres")
    var err: = ResourceSaver.save(cfg, save_path)
    if err != OK:
        push_warning("[CharacterEditor] Failed to save armor config: " + save_path + " error=" + str(err))
    return save_path

func _SaveDamagePointData() -> void :
    if not current_config or not current_config.damagePointData:
        return
    var base_dir: = _GetCharacterDir()
    if base_dir.is_empty():
        return
    var dp_dir: = base_dir.path_join("DamagePoint")
    _EnsureDir(dp_dir)
    var prefix: = _GetFilePrefix()
    var save_path: = dp_dir.path_join(prefix + "DamagePointData.tres")
    ResourceSaver.save(current_config.damagePointData, save_path)

func _SaveCustomData() -> void :
    if not current_config or not current_config.customData:
        return
    var base_dir: = _GetCharacterDir()
    if base_dir.is_empty():
        return
    var c_dir: = base_dir.path_join("Custom")
    _EnsureDir(c_dir)
    var prefix: = _GetFilePrefix()
    var save_path: = c_dir.path_join(prefix + "CoustomData.tres")
    ResourceSaver.save(current_config.customData, save_path)

func _SaveArmorData() -> void :
    if not current_config or not current_config.armorData:
        return
    var base_dir: = _GetCharacterDir()
    if base_dir.is_empty():
        return
    var a_dir: = base_dir.path_join("Armor")
    _EnsureDir(a_dir)
    var prefix: = _GetFilePrefix()
    var save_path: = a_dir.path_join(prefix + "ArmorData.tres")
    ResourceSaver.save(current_config.armorData, save_path)

func _AddFieldString(container: VBoxContainer, label_text: String, value: String, setter: Callable) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    var e: = LineEdit.new()
    e.text = value
    e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    e.text_changed.connect( func(t: String) -> void : setter.call(t))
    row.add_child(e)
    container.add_child(row)

func _AddFieldFloat(container: VBoxContainer, label_text: String, value: float, setter: Callable, min_val: float = -99999.0) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    var s: = SpinBox.new()
    s.min_value = min_val
    s.max_value = 999999999.0
    s.step = 0.1
    s.value = value
    s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    s.value_changed.connect( func(v: float) -> void : setter.call(v))
    row.add_child(s)
    container.add_child(row)

func _AddFieldInt(container: VBoxContainer, label_text: String, value: int, setter: Callable) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    var s: = SpinBox.new()
    s.min_value = -999999999
    s.max_value = 999999999
    s.step = 1
    s.value = value
    s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    s.value_changed.connect( func(v: float) -> void : setter.call(int(v)))
    row.add_child(s)
    container.add_child(row)

func _AddFieldBool(container: VBoxContainer, label_text: String, value: bool, setter: Callable) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    var c: = CheckBox.new()
    c.button_pressed = value
    c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    c.toggled.connect( func(p: bool) -> void : setter.call(p))
    row.add_child(c)
    container.add_child(row)

func _AddFieldEnum(container: VBoxContainer, label_text: String, options: PackedStringArray, selected_idx: int, setter: Callable) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    var ob: = OptionButton.new()
    for i in options.size():
        ob.add_item(options[i], i)
    if selected_idx >= 0 and selected_idx < options.size():
        ob.select(selected_idx)
    ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    ob.item_selected.connect( func(sel_idx: int) -> void : setter.call(sel_idx))
    row.add_child(ob)
    container.add_child(row)

func _AddFieldResource(container: VBoxContainer, label_text: String, base_type: String, value: Resource, setter: Callable) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    var p: = EditorResourcePicker.new()
    p.base_type = base_type
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    p.editable = true
    if value:
        p.edited_resource = value
    p.resource_changed.connect( func(r: Resource) -> void : setter.call(r))
    row.add_child(p)
    container.add_child(row)

func _AddFieldMultiline(container: VBoxContainer, label_text: String, value: String, setter: Callable) -> void :
    var l: = Label.new()
    l.text = label_text
    container.add_child(l)
    var te: = TextEdit.new()
    te.text = value
    te.custom_minimum_size = Vector2(0, 60)
    te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    te.wrap_mode = 2
    te.text_changed.connect( func() -> void : setter.call(te.text))
    container.add_child(te)

func _AddFieldVector2(container: VBoxContainer, label_text: String, value: Vector2, setter: Callable) -> void :
    var row: = HBoxContainer.new()
    var l: = Label.new()
    l.text = label_text
    l.custom_minimum_size.x = 100
    row.add_child(l)
    var xl: = Label.new()
    xl.text = "X:"
    row.add_child(xl)
    var sx: = SpinBox.new()
    sx.min_value = -999999999.0
    sx.max_value = 999999999.0
    sx.step = 0.1
    sx.value = value.x
    sx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(sx)
    var yl: = Label.new()
    yl.text = "Y:"
    row.add_child(yl)
    var sy: = SpinBox.new()
    sy.min_value = -999999999.0
    sy.max_value = 999999999.0
    sy.step = 0.1
    sy.value = value.y
    sy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(sy)
    sx.value_changed.connect( func(v: float) -> void : setter.call(Vector2(v, sy.value)))
    sy.value_changed.connect( func(v: float) -> void : setter.call(Vector2(sx.value, v)))
    container.add_child(row)

func _AddFieldFloatArray(container: VBoxContainer, arr: Array, on_changed: Callable) -> void :
    for i in arr.size():
        var row: = HBoxContainer.new()
        var idx_label: = Label.new()
        idx_label.text = "[%d]" % i
        idx_label.custom_minimum_size.x = 30
        row.add_child(idx_label)
        var sb: = SpinBox.new()
        sb.value = float(arr[i])
        sb.min_value = 0.0
        sb.max_value = 1.0
        sb.step = 0.01
        sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var captured_i: = i
        sb.value_changed.connect( func(v: float) -> void : arr[captured_i] = v)
        row.add_child(sb)
        var del_btn: = Button.new()
        del_btn.text = "×"
        del_btn.custom_minimum_size.x = 24
        del_btn.pressed.connect( func(captured_idx = i) -> void :
            arr.remove_at(captured_idx)
            on_changed.call()
        )
        row.add_child(del_btn)
        container.add_child(row)
    var add_btn: = Button.new()
    add_btn.text = "+ 添加阶段"
    add_btn.pressed.connect( func() -> void :
        arr.append(0.0)
        on_changed.call()
    )
    container.add_child(add_btn)

func _AddFieldTextureArray(container: VBoxContainer, label_text: String, arr: Array, on_changed: Callable) -> void :
    var l: = Label.new()
    l.text = label_text
    container.add_child(l)
    for i in arr.size():
        var row: = HBoxContainer.new()
        var idx_label: = Label.new()
        idx_label.text = "[%d]" % i
        idx_label.custom_minimum_size.x = 30
        row.add_child(idx_label)
        var picker: = EditorResourcePicker.new()
        picker.base_type = "Texture2D"
        picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        picker.editable = true
        if arr[i]:
            picker.edited_resource = arr[i]
        var captured_i: = i
        picker.resource_changed.connect( func(r: Resource) -> void : arr[captured_i] = r)
        row.add_child(picker)
        var del_btn: = Button.new()
        del_btn.text = "×"
        del_btn.custom_minimum_size.x = 24
        del_btn.pressed.connect( func(captured_idx = i) -> void :
            arr.remove_at(captured_idx)
            on_changed.call()
        )
        row.add_child(del_btn)
        container.add_child(row)
    var add_btn: = Button.new()
    add_btn.text = "+ 添加贴图"
    add_btn.pressed.connect( func() -> void :
        arr.append(null)
        on_changed.call()
    )
    container.add_child(add_btn)

func _AddSectionLabel(container: VBoxContainer, text: String) -> void :
    container.add_child(HSeparator.new())
    var l: = Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", 12)
    l.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
    container.add_child(l)

func _on_save_pressed() -> void :
    if not current_config:
        return
    var sp: = current_config.resource_path
    if sp.is_empty():
        return
    ResourceSaver.save(current_config, sp)
    print("[CharacterEditor] Saved: %s" % sp)
    var cd: Dictionary = character_data_map.get(current_character_name, {})
    var pd: Dictionary = cd.get("Packet", {})
    for pk in pd:
        var puid: String = str(pd[pk])
        if puid.is_empty():
            continue
        var pr: Resource = load(puid)
        if pr:
            ResourceSaver.save(pr, pr.resource_path)

func _on_add_pressed() -> void :
    var popup: = PopupPanel.new()
    popup.title = "新建角色"
    popup.min_size = Vector2(450, 180)
    var vb: = VBoxContainer.new()
    var nh: = HBoxContainer.new()
    var nl: = Label.new()
    nl.text = "角色名称:"
    nh.add_child(nl)
    var ne: = LineEdit.new()
    ne.placeholder_text = "例如: PlantNewFlower"
    ne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    nh.add_child(ne)
    vb.add_child(nh)
    var th: = HBoxContainer.new()
    var tl: = Label.new()
    tl.text = "角色类型:"
    th.add_child(tl)
    var to: = OptionButton.new()
    to.add_item("植物 (Plant)", 0)
    to.add_item("僵尸 (Zombie)", 1)
    to.add_item("道具 (Item)", 2)
    to.add_item("割草机 (Mower)", 3)
    to.add_item("花瓶 (Vase)", 4)
    to.add_item("墓碑 (GraveStone)", 5)
    to.add_item("弹坑 (Crater)", 6)
    to.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    th.add_child(to)
    vb.add_child(th)
    var ph: = HBoxContainer.new()
    var pl: = Label.new()
    pl.text = "保存路径:"
    ph.add_child(pl)
    var pe: = LineEdit.new()
    pe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    pe.placeholder_text = "留空使用默认路径"
    ph.add_child(pe)
    var pb: = Button.new()
    pb.text = "浏览..."
    pb.pressed.connect( func() -> void :
        var dlg: = EditorFileDialog.new()
        dlg.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
        dlg.access = EditorFileDialog.ACCESS_RESOURCES
        dlg.title = "选择保存位置"
        dlg.add_filter("*.tres", "资源文件")
        dlg.current_file = ne.text + ".tres" if not ne.text.is_empty() else "NewCharacter.tres"
        dlg.file_selected.connect( func(path: String) -> void :
            pe.text = path
        )
        popup.add_child(dlg)
        dlg.popup_centered(Vector2i(800, 600))
    )
    ph.add_child(pb)
    vb.add_child(ph)
    to.item_selected.connect( func(_idx: int) -> void :
        if pe.text.is_empty():
            return
        var prefix: = ""
        match to.get_selected_id():
            0: prefix = "Plant"
            1: prefix = "Zombie"
            2: prefix = "Item"
            3: prefix = "Mower"
            4: prefix = "Vase"
            5: prefix = "GraveStone"
            6: prefix = "Crater"
        var name: = ne.text
        if not name.begins_with(prefix) and not prefix.is_empty():
            name = prefix + name
        pe.text = "res://Asset/Anime/Character/%s/Config/%s/%s.tres" % [prefix, name, name]
    )
    var bh: = HBoxContainer.new()
    bh.alignment = BoxContainer.ALIGNMENT_CENTER
    var ok: = Button.new()
    ok.text = "确定"
    var cc: = Button.new()
    cc.text = "取消"
    bh.add_child(ok)
    bh.add_child(cc)
    vb.add_child(bh)
    popup.add_child(vb)
    editor_plugin.add_child(popup)
    ok.pressed.connect( func() -> void :
        _CreateNew(ne.text, to.get_selected_id(), pe.text)
        popup.queue_free()
    )
    cc.pressed.connect( func() -> void : popup.queue_free())
    ne.text_submitted.connect( func(_t: String) -> void :
        _CreateNew(ne.text, to.get_selected_id(), pe.text)
        popup.queue_free()
    )
    popup.popup_centered()

func _CreateNew(char_name: String, type_id: int, custom_path: String = "") -> void :
    if char_name.is_empty():
        return
    if registry_data.has(char_name):
        return
    var prefix: = ""
    match type_id:
        0: prefix = "Plant"
        1: prefix = "Zombie"
        2: prefix = "Item"
        3: prefix = "Mower"
        4: prefix = "Vase"
        5: prefix = "GraveStone"
        6: prefix = "Crater"
    if not char_name.begins_with(prefix):
        char_name = prefix + char_name
    var cp: = custom_path
    if cp.is_empty():
        cp = "res://Asset/Anime/Character/%s/Config/%s/%s.tres" % [prefix, char_name, char_name]
    var dp: = cp.get_base_dir()
    if not DirAccess.dir_exists_absolute(dp):
        DirAccess.make_dir_recursive_absolute(dp)
    var nc: TowerDefenseCharacterConfig = null
    match type_id:
        0: nc = TowerDefensePlantConfig.new()
        1: nc = TowerDefenseZombieConfig.new()
        2: nc = TowerDefenseItemConfig.new()
        3: nc = TowerDefenseMowerConfig.new()
        4: nc = TowerDefenseVaseConfig.new()
        5: nc = TowerDefenseGravestoneConfig.new()
        6: nc = TowerDefenseCraterConfig.new()
    if nc:
        nc.name = char_name
        ResourceSaver.save(nc, cp)
    registry_data[char_name] = {"Sprite": "", "Scene": "", "Packet": {}}
    _SaveRegistry()
    EditorInterface.get_resource_filesystem().scan()
    LoadRegistry()

func _on_rename_pressed() -> void :
    if current_character_name.is_empty():
        return
    var popup: = PopupPanel.new()
    popup.title = "重命名角色"
    popup.min_size = Vector2(300, 80)
    var vb: = VBoxContainer.new()
    var ne: = LineEdit.new()
    ne.text = current_character_name
    vb.add_child(ne)
    var bh: = HBoxContainer.new()
    bh.alignment = BoxContainer.ALIGNMENT_CENTER
    var ok: = Button.new()
    ok.text = "确定"
    var cc: = Button.new()
    cc.text = "取消"
    bh.add_child(ok)
    bh.add_child(cc)
    vb.add_child(bh)
    popup.add_child(vb)
    editor_plugin.add_child(popup)
    ok.pressed.connect( func() -> void :
        _DoRename(current_character_name, ne.text)
        popup.queue_free()
    )
    cc.pressed.connect( func() -> void : popup.queue_free())
    ne.text_submitted.connect( func(v: String) -> void :
        _DoRename(current_character_name, v)
        popup.queue_free()
    )
    popup.popup_centered()

func _DoRename(old_name: String, new_name: String) -> void :
    if new_name.is_empty() or new_name == old_name:
        return
    if not registry_data.has(old_name) or registry_data.has(new_name):
        return
    var d: Dictionary = registry_data[old_name]
    registry_data.erase(old_name)
    registry_data[new_name] = d
    _SaveRegistry()
    LoadRegistry()

func _SaveRegistry() -> void :
    var j: = JSON.stringify(registry_data, "\t")
    var f: = FileAccess.open(CHARACTER_REGISTRY_PATH, FileAccess.WRITE)
    f.store_string(j)
    f.close()

func _FindSprite(node: Node) -> AdobeAnimateSprite:
    if node is AdobeAnimateSprite:
        return node as AdobeAnimateSprite
    for c in node.get_children():
        var found: = _FindSprite(c)
        if found:
            return found
    return null

func _ClearChildren(node: Node) -> void :
    for c in node.get_children():
        c.queue_free()

func _SCost(p: TowerDefensePacketConfig) -> float:
    if is_instance_valid(p.characterConfig):
        return float(p.characterConfig.cost)
    return float(p.overrideCost) if p.overrideCost != -1 else 0.0

func _SCd(p: TowerDefensePacketConfig) -> float:
    if is_instance_valid(p.characterConfig):
        return p.characterConfig.packetCooldown
    return p.overridePacketCooldown if p.overridePacketCooldown != -1.0 else 0.0

func _SScd(p: TowerDefensePacketConfig) -> float:
    if is_instance_valid(p.characterConfig):
        return p.characterConfig.startingCooldown
    return p.overrideStartingCooldown if p.overrideStartingCooldown != -1.0 else 0.0
