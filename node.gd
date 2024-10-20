extends Node

const CONFIG_FILE_PATH = "user://settings.cfg"
const SPELL_FILES = {
	"BRD": "res://BRD_spells.txt",
	"BER": "res://BER_spells.txt",
	"BST": "res://BST_spells.txt",
	"CLR": "res://CLR_spells.txt",
	"ENC": "res://ENC_spells.txt",
	"NEC": "res://NEC_spells.txt",
	"MAG": "res://MAG_spells.txt",
	"MNK": "res://MNK_spells.txt",
	"PAL": "res://PAL_spells.txt",
	"RNG": "res://RNG_spells.txt",
	"ROG": "res://ROG_spells.txt",
	"SHD": "res://SHD_spells.txt",
	"SHM": "res://SHM_spells.txt",
	"WAR": "res://WAR_spells.txt",
	"WIZ": "res://WIZ_spells.txt",
	"DRU": "res://DRU_spells.txt"
}

var game_dir: String = ""
var character: String
var character_inventory: String
var current_spell_class: String
var expansion_set: String = ""
var expansion_save: bool = false

var color_column1 = Color("#d79921")
var color_column2 = Color("#ebdbb2")
var color_column3 = Color("#928374")

@onready var label_game_dir: Label = %LabelGameDir
@onready var file_dialog_game_dir: FileDialog = %FileDialogGameDir
@onready var file_list: ItemList = %ItemListFiles
@onready var item_list_spells: ItemList = %ItemListSpells
@onready var label_spells: Label = %LabelSpells
@onready var item_list: ItemList = %ItemList
@onready var button_bard: Button = %ButtonBard
@onready var button_necromancer: Button = %ButtonNecromancer
@onready var button_druid: Button = %ButtonDruid
@onready var panel: Panel = %Panel
@onready var label_missing: Label = %LabelMissing
@onready var label_exp: Label = %LabelExp
@onready var menu_button_exp: MenuButton = %MenuButtonExp
@onready var label_class: Label = %LabelClass
@onready var label: Label = %Label
@onready var label_2: Label = %Label2
@onready var check_button_exp: CheckButton = %CheckButtonExp
@onready var popup_panel: PopupPanel = %PopupPanel

@onready var bard: AnimatedSprite2D = %Bard
@onready var beastlord: AnimatedSprite2D = %Beastlord
@onready var berserker: AnimatedSprite2D = %Berserker
@onready var cleric: AnimatedSprite2D = %Cleric
@onready var druid: AnimatedSprite2D = %Druid
@onready var enchanter: AnimatedSprite2D = %Enchanter
@onready var magician: AnimatedSprite2D = %Magician
@onready var monk: AnimatedSprite2D = %Monk
@onready var necromancer: AnimatedSprite2D = %Necromancer
@onready var paladin: AnimatedSprite2D = %Paladin
@onready var ranger: AnimatedSprite2D = %Ranger
@onready var rogue: AnimatedSprite2D = %Rogue
@onready var shadowknight: AnimatedSprite2D = %Shadowknight
@onready var shaman: AnimatedSprite2D = %Shaman
@onready var warrior: AnimatedSprite2D = %Warrior
@onready var wizard: AnimatedSprite2D = %Wizard
@onready var label_v: Label = %LabelV

func _ready() -> void:
	load_game_dir()
	if game_dir:
		update_file_list()
	var file = FileAccess.open("res://EXP_list.txt", FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if not line.is_empty():
				menu_button_exp.get_popup().add_item(line)
		file.close()
	button_bard.connect("pressed", Callable(self, "_on_button_bard_pressed"))
	button_necromancer.connect("pressed", Callable(self, "_on_button_necromancer_pressed"))
	button_druid.connect("pressed", Callable(self, "_on_button_druid_pressed"))
	menu_button_exp.get_popup().id_pressed.connect(_on_item_selected)
	check_button_exp.button_pressed = expansion_save
	set_column_colors()
	set_column_colors_spells()
	check_settings_file()
	var version = ProjectSettings.get_setting("application/config/version")
	label_v.text = "v " + str(version) + " "

func _on_item_selected(id: int):
	var item_text = menu_button_exp.get_popup().get_item_text(id)
	var display_text = item_text.split("(")[0].strip_edges()
	label_exp.text = display_text
	expansion_set = display_text
	var function_name = display_text.to_lower().replace(" ", "_")
	if has_method(function_name):
		call(function_name)
		save_game_dir()
	else:
		pass

func check_settings_file():
	var file = game_dir
	
	if file == "":
		print("Settings file not found or inaccessible.")
		#call_deferred("show_popup")
		var timer = Timer.new()
		timer.connect("timeout", show_popup)
		timer.set_wait_time(0.1)  # 100 ms delay
		timer.set_one_shot(true)
		add_child(timer)
		timer.start()
	else:
		popup_panel.hide()

func show_popup():
	if not popup_panel.visible:
		popup_panel.show()
		popup_panel.popup_centered()

func update_file_list() -> void:
	file_list.clear()
	var dir = DirAccess.open(game_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with("-Spellbook.txt"):
				var name_server = file_name.get_slice("-Spellbook.txt", 0)
				var parts = name_server.split("_", false, 1)
				if parts.size() == 2:
					var display_name = "%s - %s" % [parts[1].capitalize(), parts[0].capitalize()]
					file_list.add_item(display_name)
					file_list.set_item_tooltip_enabled(file_list.get_item_count() - 1, false)
					file_list.set_item_metadata(file_list.get_item_count() - 1, file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		label_game_dir.text = game_dir
	else:
		label_game_dir.text = "<-- Please select a game directory!"

func update_character_inventory(file_name: String) -> void:
	var updated_name = file_name.replace("Spellbook", "Inventory")
	character_inventory = updated_name

func populate_spell_list(file_content: String) -> void:
	item_list_spells.clear()
	item_list_spells.max_columns = 2
	label.show()
	for line in file_content.split("\n"):
		if line.strip_edges().is_empty():
			continue
		var parts = line.split("\t", false, 1)
		if parts.size() >= 2:
			var number = parts[0].strip_edges()
			if number.length() == 1:
				number = "  " + number
			elif number.length() == 2:
				number = " " + number
			number = number.rpad(3)
			
			var spell_name = parts[1].strip_edges()
			item_list_spells.add_item(number)
			item_list_spells.add_item(spell_name)
		else:
			item_list_spells.add_item(line.strip_edges())
			item_list_spells.add_item("")
	set_column_colors_spells()

func load_spells_into_item_list(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	label_2.show()
	menu_button_exp.show()
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		if parts.size() == 3:
			var number = parts[0].strip_edges()
			if number.length() == 1:
				number = "  " + number
			elif number.length() == 2:
				number = " " + number
			item_list.add_item(number.rpad(3))
			item_list.add_item(parts[1].strip_edges())
			item_list.add_item(parts[2].strip_edges())
		else:
			printerr("Invalid line format: ", line)
			item_list.add_item(line)
			item_list.add_item("")
			item_list.add_item("")
	file.close()
	update_missing_count()

func remove_matching_spells() -> void:
	var spells_to_remove = []
	var character_spells = {}
	for i in range(0, item_list_spells.get_item_count(), 2):
		var spell_number = item_list_spells.get_item_text(i).strip_edges()
		var spell_name = item_list_spells.get_item_text(i + 1).strip_edges()
		character_spells[spell_name] = spell_number
	for i in range(0, item_list.get_item_count(), 3):
		var spell_number = item_list.get_item_text(i).strip_edges()
		var spell_name = item_list.get_item_text(i + 1).strip_edges()
		if spell_name in character_spells and character_spells[spell_name] == spell_number:
			spells_to_remove.append(i)
	for i in range(spells_to_remove.size() - 1, -1, -1):
		var index_to_remove = spells_to_remove[i]
		item_list.remove_item(index_to_remove + 2)
		item_list.remove_item(index_to_remove + 1)
		item_list.remove_item(index_to_remove)
	update_missing_count()

func set_column_colors():
	var colors = [color_column1, color_column2, color_column3]
	var item_count = item_list.get_item_count()
	for i in range(item_count):
		var color_index = i % 3
		item_list.set_item_custom_fg_color(i, colors[color_index])
		item_list.set_item_tooltip_enabled(i, false)

func set_column_colors_spells():
	var colors = [color_column1, color_column2, color_column3]
	var item_count = item_list_spells.get_item_count()
	for i in range(item_count):
		var color_index = i % 2
		item_list_spells.set_item_custom_fg_color(i, colors[color_index])
		item_list_spells.set_item_tooltip_enabled(i, false)

func _on_file_dialog_game_dir_dir_selected(dir: String) -> void:
	game_dir = dir
	save_game_dir()
	update_file_list()

func _on_button_set_game_dir_pressed() -> void:
	file_dialog_game_dir.popup_centered(Vector2i(500, 400))

func _on_button_bag_pressed() -> void:
	remove_inventory_from_itemlist()

func _on_item_list_files_item_selected(index: int) -> void:
	var original_filename = file_list.get_item_metadata(index)
	var file_path = game_dir.path_join(original_filename)
	var file_content = FileAccess.get_file_as_string(file_path)
	populate_spell_list(file_content)
	update_spell_count()
	update_character_inventory(original_filename)
	print("Inventory file: " + character_inventory)
	label_exp.hide()
	item_list.hide()
	bard.hide()
	berserker.hide()
	beastlord.hide()
	cleric.hide()
	druid.hide()
	enchanter.hide()
	magician.hide()
	monk.hide()
	necromancer.hide()
	paladin.hide()
	ranger.hide()
	rogue.hide()
	shadowknight.hide()
	shaman.hide()
	warrior.hide()
	wizard.hide()
	item_list_spells.show()
	panel.show()
	label_class.text = ""
	menu_button_exp.hide()
	label_missing.text = ""
	label_exp.text = ""
	label_2.hide()
	$ButtonBag.show()

func _on_check_button_exp_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		expansion_save = true
		save_game_dir()
	else:
		expansion_save = false
		save_game_dir()

func remove_inventory_from_itemlist() -> void:
	var full_file_path = game_dir.path_join(character_inventory)
	if not FileAccess.file_exists(full_file_path):
		print("Error: File not found - ", full_file_path)
		return
	var file = FileAccess.open(full_file_path, FileAccess.READ)
	if file == null:
		print("Error: Unable to open file - ", full_file_path)
		return
	var content = file.get_as_text()
	file.close()
	var lines = content.split("\n")
	for line in lines:
		if line.contains("Spell:"):
			var spell_start = line.find("Spell:") + 6
			var spell_end = line.find("\t", spell_start)
			var spell_name = line.substr(spell_start, spell_end - spell_start).strip_edges()
			for i in range(item_list.get_item_count() - 1, -1, -1):
				var item_text = item_list.get_item_text(i)
				if spell_name in item_text:
					item_list.remove_item(i + 2)
					item_list.remove_item(i + 1)
					item_list.remove_item(i)
					print("Removed line: ", item_text)
					break
	update_missing_count()

func _on_button_close_cfg_pressed() -> void:
	save_game_dir()
	$PopupPanel.hide()

func update_spell_count() -> void:
	label_spells.text = str(item_list_spells.get_item_count() / 2) if item_list_spells.get_item_count() > 0 else ""

func save_game_dir() -> void:
	var config = ConfigFile.new()
	config.set_value("Settings", "game_dir", game_dir)
	config.set_value("Settings", "expansion_set", expansion_set)
	config.set_value("Settings", "expansion_save", expansion_save)
	var error = config.save(CONFIG_FILE_PATH)
	if error != OK:
		printerr("Failed to save config file. Error code: ", error)

func load_game_dir() -> void:
	var config = ConfigFile.new()
	if config.load(CONFIG_FILE_PATH) == OK:
		game_dir = config.get_value("Settings", "game_dir", "")
		expansion_set = config.get_value("Settings", "expansion_set", "")
		expansion_save = config.get_value("Settings", "expansion_save", false)
	else:
		game_dir = ""
		expansion_set = ""
		expansion_save = false
		popup_panel.show()

func update_missing_count():
	var line_count = item_list.get_item_count() / 3 + 1
	%LabelMissing.text = str(line_count)

func _on_button_update_pressed() -> void:
	update_file_list()

func _on_button_info_pressed() -> void:
	$PopupPanel.show()

func run_stored_selection():
	if expansion_set.is_empty():
		print("No expansion set selected")
		return
	label_exp.text = expansion_set
	var function_name = expansion_set.to_lower().replace(" ", "_")
	if has_method(function_name):
		call(function_name)
	else:
		print("Function not found: ", function_name)

func everquest():
	load_spells_into_item_list_EQ(SPELL_FILES[current_spell_class])

func the_ruins_of_kunark():
	load_spells_into_item_list_Kunark(SPELL_FILES[current_spell_class])

func the_scars_of_velious():
	load_spells_into_item_list_Velious(SPELL_FILES[current_spell_class])

func the_shadows_of_luclin():
	load_spells_into_item_list_Luclin(SPELL_FILES[current_spell_class])

func the_planes_of_power():
	load_spells_into_item_list_PoP(SPELL_FILES[current_spell_class])

func the_legacy_of_ykesha():
	load_spells_into_item_list_LoY(SPELL_FILES[current_spell_class])

func lost_dungeons_of_norrath():
	load_spells_into_item_list_LDoN(SPELL_FILES[current_spell_class])

func gates_of_discord():
	load_spells_into_item_list_Gates(SPELL_FILES[current_spell_class])

func omens_of_war():
	load_spells_into_item_list_Omens(SPELL_FILES[current_spell_class])

func dragons_of_norrath():
	load_spells_into_item_list_DoN(SPELL_FILES[current_spell_class])

func depths_of_darkhollow():
	load_spells_into_item_list_DoD(SPELL_FILES[current_spell_class])

func prophecy_of_ro():
	load_spells_into_item_list_PoR(SPELL_FILES[current_spell_class])

func the_serpents_spine():
	load_spells_into_item_list_TSS(SPELL_FILES[current_spell_class])

func the_buried_sea():
	load_spells_into_item_list_TBS(SPELL_FILES[current_spell_class])

func secrets_of_faydwer():
	load_spells_into_item_list_SoF(SPELL_FILES[current_spell_class])

func seeds_of_destruction():
	load_spells_into_item_list_SoD(SPELL_FILES[current_spell_class])

func underfoot():
	load_spells_into_item_list_UF(SPELL_FILES[current_spell_class])

func house_of_thule():
	load_spells_into_item_list_HoT(SPELL_FILES[current_spell_class])

func veil_of_alaris():
	load_spells_into_item_list_VoA(SPELL_FILES[current_spell_class])

func rain_of_fear():
	load_spells_into_item_list_RoF(SPELL_FILES[current_spell_class])

func call_of_the_forsaken():
	load_spells_into_item_list_CotF(SPELL_FILES[current_spell_class])

func the_darkened_sea():
	load_spells_into_item_list_TDS(SPELL_FILES[current_spell_class])

func the_broken_mirror():
	load_spells_into_item_list_TBM(SPELL_FILES[current_spell_class])

func empires_of_kunark():
	load_spells_into_item_list_EoK(SPELL_FILES[current_spell_class])

func ring_of_scale():
	load_spells_into_item_list_RoS(SPELL_FILES[current_spell_class])

func the_burning_lands():
	load_spells_into_item_list_TBL(SPELL_FILES[current_spell_class])

func torment_of_velious():
	load_spells_into_item_list_ToV(SPELL_FILES[current_spell_class])

func claws_of_veeshan():
	load_spells_into_item_list_CoV(SPELL_FILES[current_spell_class])

func terror_of_luclin():
	load_spells_into_item_list_ToL(SPELL_FILES[current_spell_class])

func night_of_shadows():
	load_spells_into_item_list_NoS(SPELL_FILES[current_spell_class])

func laurions_song():
	load_spells_into_item_list_LS(SPELL_FILES[current_spell_class])

func load_spells_into_item_list_EQ(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		if parts.size() == 3 and parts[2].strip_edges().to_upper().ends_with("EQ"):
			item_list.add_item(parts[0].strip_edges().rpad(3))
			item_list.add_item(parts[1].strip_edges())
			item_list.add_item(parts[2].strip_edges())
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_Kunark(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_Velious(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_Luclin(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_PoP(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_LoY(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_LDoN(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_Gates(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_Omens(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_DoN(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_DoD(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_PoR(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_TSS(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_TBS(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_SoF(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_SoD(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_UF(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_HoT(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_VoA(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_RoF(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("ROF"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_CotF(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_TDS(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_TBM(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS") or expansion.ends_with("TBM"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_EoK(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS") or expansion.ends_with("TBM") or expansion.ends_with("EOK"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_RoS(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS") or expansion.ends_with("TBM") or expansion.ends_with("EOK") or expansion.ends_with("ROS"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_TBL(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS") or expansion.ends_with("TBM") or expansion.ends_with("EOK") or expansion.ends_with("ROS") or expansion.ends_with("TBL"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_ToV(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS") or expansion.ends_with("TBM") or expansion.ends_with("EOK") or expansion.ends_with("ROS") or expansion.ends_with("TBL") or expansion.ends_with("TOV"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_CoV(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS") or expansion.ends_with("TBM") or expansion.ends_with("EOK") or expansion.ends_with("ROS") or expansion.ends_with("TBL") or expansion.ends_with("TOV") or expansion.ends_with("COV"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_ToL(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS") or expansion.ends_with("TBM") or expansion.ends_with("EOK") or expansion.ends_with("ROS") or expansion.ends_with("TBL") or expansion.ends_with("TOV") or expansion.ends_with("COV") or expansion.ends_with("TOL"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_NoS(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS") or expansion.ends_with("TBM") or expansion.ends_with("EOK") or expansion.ends_with("ROS") or expansion.ends_with("TBL") or expansion.ends_with("TOV") or expansion.ends_with("COV") or expansion.ends_with("TOL") or expansion.ends_with("NOS"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func load_spells_into_item_list_LS(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ", file_path)
		return
	item_list.clear()
	item_list.max_columns = 3
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts = line.split("\t")
		set_column_colors()
		if parts.size() == 3:
			var expansion = parts[2].strip_edges().to_upper()
			if expansion.ends_with("EQ") or expansion.ends_with("KUNARK") or expansion.ends_with("VELIOUS") or expansion.ends_with("LUCLIN") or expansion.ends_with("POP") or expansion.ends_with("LOY") or expansion.ends_with("LDON") or expansion.ends_with("GATES") or expansion.ends_with("OMENS") or expansion.ends_with("DON") or expansion.ends_with("DOD") or expansion.ends_with("POR") or expansion.ends_with("TSS") or expansion.ends_with("TBS") or expansion.ends_with("SOF") or expansion.ends_with("SOD") or expansion.ends_with("UF") or expansion.ends_with("HOT") or expansion.ends_with("VOA") or expansion.ends_with("COTF") or expansion.ends_with("TDS") or expansion.ends_with("TBM") or expansion.ends_with("EOK") or expansion.ends_with("ROS") or expansion.ends_with("TBL") or expansion.ends_with("TOV") or expansion.ends_with("COV") or expansion.ends_with("TOL") or expansion.ends_with("NOS") or expansion.ends_with("LS"):
				item_list.add_item(parts[0].strip_edges())
				item_list.add_item(parts[1].strip_edges())
				item_list.add_item(expansion)
		else:
			continue
	file.close()
	remove_matching_spells()
	set_column_colors()
	update_missing_count()

func _on_button_bard_pressed() -> void:
	current_spell_class = "BRD"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Bard"
	bard.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return
		

func _on_button_necromancer_pressed() -> void:
	current_spell_class = "NEC"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Necromancer"
	necromancer.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_druid_pressed() -> void:
	current_spell_class = "DRU"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Druid"
	druid.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_beastlord_pressed() -> void:
	current_spell_class = "BST"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Beastlord"
	beastlord.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_berserker_pressed() -> void:
	current_spell_class = "BER"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Berserker"
	berserker.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_cleric_pressed() -> void:
	current_spell_class = "CLR"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Cleric"
	cleric.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_enchanter_pressed() -> void:
	current_spell_class = "ENC"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Enchanter"
	enchanter.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_magician_pressed() -> void:
	current_spell_class = "MAG"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Magician"
	magician.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_monk_pressed() -> void:
	current_spell_class = "MNK"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Monk"
	monk.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_paladin_pressed() -> void:
	current_spell_class = "PAL"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Paladin"
	paladin.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_ranger_pressed() -> void:
	current_spell_class = "RNG"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Ranger"
	ranger.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_rogue_pressed() -> void:
	current_spell_class = "ROG"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Rogue"
	rogue.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_shadowknight_pressed() -> void:
	current_spell_class = "SHD"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Shadowknight"
	shadowknight.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_shaman_pressed() -> void:
	current_spell_class = "SHM"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Shaman"
	shaman.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_warrior_pressed() -> void:
	current_spell_class = "WAR"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Warrior"
	warrior.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return

func _on_button_wizard_pressed() -> void:
	current_spell_class = "WIZ"
	load_spells_into_item_list(SPELL_FILES[current_spell_class])
	remove_matching_spells()
	set_column_colors()
	label_class.text = "Wizard"
	wizard.show()
	item_list.show()
	label_exp.show()
	panel.hide()
	if expansion_save == true:
		run_stored_selection()
		return
