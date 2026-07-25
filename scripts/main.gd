extends Node2D
@export var player_scene : PackedScene
@export var bullet_scene : PackedScene
@export var enemy_scene : PackedScene
@export var enemy_2_scene : PackedScene
@export var ufo_enemy_scene : PackedScene
@export var laze_enemy_scene : PackedScene
@export var first_boss : PackedScene 
@export var collectable_scene : PackedScene
@export var upgrade_menu : PackedScene
@export var pause_menu : PackedScene
@export var settings_menu : PackedScene
@export var indicator : PackedScene
@export var effect : PackedScene
@export var wave_count = 1
@export var enemy_remaining = 2
@export var count_enemy = enemy_remaining
@export var enemy_escape = 0
var enemy_number = [2, 0, 0, 0]
var enemy_percent = [0.6, 0.15, 0.05, 0.2]
var temp_enemy_spawn = 2
var is_waiting = false
var fighting_boss = false
var started = false
var coin_collected = 0
var played = 0
var player_loaded_data = {
	"MAX_HP": 150,
	"highest_score" : 0,
	"coins": 0,
	"fire_rate" : 0.275,
	"bullet_damage" : 15,
	"crit_rate" : 0,
	"crit_damage": 1,
	"speed" : 500,
	"healing_rate" : 0,
	"coin_multiplier" : 1,
	"resistance" : 0,
	"upgraded" : [0,0,0,0,0,0,0,0]
}

@onready var enemy_loaded = {
	0 : enemy_scene,
	1 : enemy_2_scene,
	2 : ufo_enemy_scene,
	3 : laze_enemy_scene
}

var counter = 0
var score = 0
var list_collectable = ["shield", "fire_rate", "speed", "hp", "coin"]
var collectable_rate = [0.04, 0.06, 0.1, 0.3, 0.5]

var player = null

@export var settings_data = {
	"difficulty" : 1,
	"indicator_enabled" : true,
	"sound_enabled" : true
}
var power_difficulty = [0.5,1,1.5]
var current_stat_multiplier = power_difficulty[0]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, 0.5)
	$Play.sound = 1
	$Upgrade.sound = 1
	$Settings.sound = 1
	$Exit.sound = 1
	$PauseButton.sound = 2
	if (_read_file("user://player.dat") != null):
		player_loaded_data = _read_file("user://player.dat")
		
	if (_read_file("user://settings.dat") != null):	
		settings_data = _read_file("user://settings.dat")
	add_to_group("main")
	$AnnouncementLabel.hide()
	$Play.add_to_group("animation_button")
	$Upgrade.add_to_group("animation_button")
	$Settings.add_to_group("animation_button")
	$Exit.add_to_group("animation_button")
	$GameOver.hide()
	$PlayerScore.show()
	$PlayerScore.text = "Highest Score: " + str(int(player_loaded_data["highest_score"]))
	$Collectable.show()
	$Collectable.animation_name = "coin_default"
	$PauseButton.hide()
	$WaveCount.hide()
	$EnemyRemaining.hide()
	$BossName.hide()
	$BossHealthBar.hide()
	$EnemyEscape.hide()
func new_game() -> void:
	get_tree().call_group("player", "queue_free")
	player = player_scene.instantiate()
	player.player_data = player_loaded_data.duplicate()
	player.add_to_group("player")
	add_child(player)
	enemy_number = [2,0,0,0]
	is_waiting = false
	$GameTitle.hide()
	$Play.hide()
	$Upgrade.hide()
	$Settings.hide()
	$Exit.hide()
	$EnemySpawn.start()
	$AnimatedSprite2D.play()
	$GameOver.hide()
	$PlayerScore.position.x = 22
	$PlayerScore.position.y = 70
	$PlayerScore.show()
	$PauseButton.show()
	$WaveCount.show()
	$EnemyRemaining.show()
	$EnemyEscape.show()
	$Soundtrack_1.stop()
	$Soundtrack_2.play()
	$Credit.hide()
	enemy_escape = 0
	wave_count = 1
	enemy_remaining = 2
	coin_collected = 0
	count_enemy = enemy_remaining
	temp_enemy_spawn = enemy_remaining
	started = true
func _read_file(path : String):
	var file = FileAccess.open(path, FileAccess.READ)
	var return_data
	var json = new()
	if (file != null && file.get_as_text() != ""):
		return_data = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		print(path, " isn't exist!")
	return return_data
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (settings_data != null):
		current_stat_multiplier = power_difficulty[settings_data["difficulty"]] * pow(1.05, int(wave_count) / int(10))
	if (player != null):
		$NumberOfCoins.text = str(int(player.player_data["coins"]))
	else:
		$NumberOfCoins.text = str(int(player_loaded_data["coins"]))
	#print(get_tree().get_nodes_in_group("player").size())
	if ($PauseButton.is_hovered()):
		$PauseButton.self_modulate = Color(1,1,1,1)
		$PauseButton.sound = 2
	else:
		$PauseButton.self_modulate = Color(1,1,1,0.5)
	if (started == true):
		$PlayerScore.text = "Score: " + str(int(score))
		$PlayerScore.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if is_waiting == true:
		var tween = create_tween()
		tween.tween_property($AnnouncementLabel, "modulate:a", 1, 0.25)
	else:
		$AnnouncementLabel.modulate.a = 0
		
	for button in get_tree().get_nodes_in_group("animation_button"):
		if (button.disabled == false && button.is_hovered()):
			var tween = create_tween()
			tween.tween_property(button, "position:x", 105, 0.25)
		else:
			var tween = create_tween()
			tween.tween_property(button, "position:x", 55, 0.25)
			
	if (player != null && player.current_HP <= 0):
		game_over()
	if (enemy_escape == 5):
		game_over()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.destroyed == true:
			if (enemy.name != "Boss_1"):
				$Explode.volume_db = 1
				$Explode.play()
			elif (enemy.name == "Boss_1"):
				get_tree().call_group("warning_area", "queue_free")
				$Explode.volume_db = 20
				$Explode.play()
				for i in range (0, 100):
					var coin = collectable_scene.instantiate()
					coin.position = enemy.position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
					coin.animation_name = "coin_collectable"
					coin.add_to_group("item_collectable")
					add_child(coin)
				$BossName.hide()
				$BossHealthBar.hide()
			$ExplodeEffect.position = enemy.position
			$ExplodeEffect.emitting = true
			var name_collectable = ""
			var random_number = randf_range(0, 100)
			for i in range(0,5):
				if (random_number < collectable_rate[i] * 100 || random_number > collectable_rate[i] * 100 && collectable_rate[i] >= 0.5):
					name_collectable = list_collectable[i]
					break
			var current_pos = enemy.position
			score += enemy.MAX_HP * 0.8
			enemy.queue_free()
			var collectable = collectable_scene.instantiate()
			collectable.position = current_pos
			collectable.animation_name = name_collectable + "_collectable"
			collectable.add_to_group("item_collectable")
			add_child(collectable)
			count_enemy -= 1
		elif enemy.over_border == true:
			if (enemy.name == "Boss_1"):
				game_over()
			else:
				var score_deducted = 50 * int(enemy.current_HP) / int(enemy.MAX_HP)
				if score >= score_deducted:
					score -= score_deducted
				count_enemy -= 1
				enemy_escape += 1
				var tween = create_tween()
				tween.tween_property($EnemyEscape, "modulate", Color('RED'), 0.25)
				tween.tween_property($EnemyEscape, "modulate", Color(1,1,1,1), 0.25)
			enemy.queue_free()
	
	for collectable in get_tree().get_nodes_in_group("item_collectable"):
		if collectable.collected == true:
			if collectable.animation_name == "coin_collectable":
				var collected = 1
				if (player.player_data["coin_multiplier"] != 0):
					collected *= player.player_data["coin_multiplier"]
				player.player_data["coins"] += collected
				coin_collected += collected
				player.add_child(_show_indicator(collected, "+ ", "g", Color.YELLOW)) 
				$CoinSound.play()
			elif collectable.animation_name == "hp_collectable":
				var hp_added = 0
				if (player.current_HP + 15 > player.player_data["MAX_HP"]):
					hp_added = player.player_data["MAX_HP"] - player.current_HP
				else:
					hp_added = 15
				player.current_HP += hp_added
				player.add_child(_show_indicator(hp_added, "+ ", "", Color.GREEN))
				$BuffSound.play()
			elif collectable.animation_name == "fire_rate_collectable":
				player.player_data["fire_rate"] *= 0.2
				$Return_Fire_Rate.start()
				player.add_child(_show_indicator(0, "Fire Rate Boost", "", Color.ORANGE))
				_add_effect($Return_Fire_Rate.wait_time, "fire_rate")
				$BuffSound.play()
			elif collectable.animation_name == "shield_collectable":
				player.player_data["resistance"] += 0.45
				$Return_Resistance.start()
				player.add_child(_show_indicator(0, "Resistance Boost", "", Color.GRAY))
				_add_effect($Return_Resistance.wait_time, "resistance")
				$BuffSound.play()
			elif collectable.animation_name == "speed_collectable":
				player.player_data["speed"] += 350
				$Return_Speed.start()
				player.add_child(_show_indicator(0, "Speed Boost", "", Color.YELLOW))
				_add_effect($Return_Speed.wait_time, "speed")
				$BuffSound.play()
			collectable.queue_free()
	
	$WaveCount.text = "Wave: " + str(wave_count)
	$EnemyRemaining.text = "Remaining: " + str(count_enemy)
	$EnemyEscape.text = "Escape: " + str(enemy_escape) + "/5" 
	if count_enemy == 0 && is_waiting == false:
		if ((wave_count + 1) % 10 != 0):
			$Wave_Delay.start()
		else:
			$EnemySpawn.stop()
		$AnnouncementLabel.show()
		is_waiting = true
		$BossSoundTrack_1.stop()
		$Completed.play()
		$Soundtrack_2.play()
	if (is_waiting == true && wave_count != null && (wave_count + 1) % 10 != 0):
		$AnnouncementLabel.text = "WAVE COMPLETED!\n\nNext wave starts in " + str(int($Wave_Delay.time_left + 1))
		$AnnouncementLabel.add_theme_font_size_override("font_size", 24)
		$AnnouncementLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		$AnnouncementLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wave_count != null && (wave_count + 1) % 10 == 0 && fighting_boss == false && count_enemy == 0:
		fighting_boss = true
		$AnnouncementLabel.text= "Something crazy is comming..."
		$AnnouncementLabel.add_theme_font_size_override("font_size", 24)
		$DelayBossSpawn.start()
	if Input.is_action_just_pressed("quit") && get_tree().paused == false && started == true:
		_on_pause_button_pressed()
	if get_tree().get_nodes_in_group("pause").size() > 0 && get_tree().get_first_node_in_group("pause").quit == true:
		get_tree().call_group("pause", "queue_free")
		game_over()
		
	if (settings_data != null):
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), !settings_data["sound_enabled"])

func _on_enemy_spawn_timeout() -> void:
	counter = randi_range(0, 3)
	while (temp_enemy_spawn != 0 && enemy_number[counter] == 0):
		counter = randi_range(0, 3)
	if (count_enemy > 0 && get_tree().get_nodes_in_group("enemy").size() != count_enemy):
		if enemy_number[counter] > 0:
			var enemy = enemy_loaded[counter].instantiate()
			var enemy_position_x = randf_range(40, 685)
			enemy.position.x = enemy_position_x
			enemy.position.y = -15
			enemy.power_multiplier = current_stat_multiplier
			enemy.add_to_group("enemy")
			add_child(enemy)
			$EnemySpawn.start()
			enemy_number[counter] -= 1
			temp_enemy_spawn -= 1
		
func _spawn_boss() -> void:
	var boss = first_boss.instantiate()
	boss.power_multiplier = current_stat_multiplier
	$BossName.show()
	$BossHealthBar.add_to_group("boss_health_bar")
	$BossHealthBar.show()
	boss.add_to_group("enemy")
	add_child(boss)
	$EnemySpawn.stop()

func game_over() -> void:
	$Soundtrack_2.stop()
	$BossSoundTrack_1.stop()
	$Explode.play()
	$Return_Fire_Rate.stop()
	$Return_Resistance.stop()
	$Return_Speed.stop()
	started = false
	$Wave_Delay.stop()
	$DelayBossSpawn.stop()
	$EnemySpawn.stop()
	$GameOver.show()
	$AnnouncementLabel.hide()
	for collectable in get_tree().get_nodes_in_group("item_collectable"):
		if collectable.animation_name == "coin_collectable":
			var collected = 1 * player.player_data["coin_multiplier"]
			player.player_data["coins"] += collected
			coin_collected += collected
	player_loaded_data["coins"] = player.player_data["coins"]
	$PlayerScore.text = "Score: " + str(int(score)) + "\n\nCoins collected: " + str(int(coin_collected))
	$PlayerScore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$PlayerScore.position.x = $GameOver.position.x + 50
	$PlayerScore.position.y = $GameOver.position.y + 100
	if (score > player.player_data["highest_score"]):
		player_loaded_data["highest_score"] = score
	$ShowTitle.start()
	$PauseButton.hide()
	$WaveCount.hide()
	$EnemyRemaining.hide()
	$BossName.hide()
	$BossHealthBar.hide()
	$EnemyEscape.hide()
	enemy_escape = 0
	get_tree().call_group("player", "queue_free")
	get_tree().call_group("enemy", "queue_free")
	get_tree().call_group("player_bullet", "queue_free")
	get_tree().call_group("enemies_bullet", "queue_free")
	get_tree().call_group("item_collectable", "queue_free")
	get_tree().call_group("collectable_effect", "queue_free")
func _on_show_title_timeout() -> void:
	$GameOver.hide()
	$GameTitle.show()
	$ShowTitle.stop()
	$Soundtrack_2.stop()
	$Soundtrack_1.play()
	$PlayerScore.position.x = 22
	$PlayerScore.position.y = 70
	$PlayerScore.text = "Highest Score: " + str(int(player_loaded_data["highest_score"]))
	$Play.show()
	$Upgrade.show()
	$Settings.show()
	$Exit.show()
	$Credit.show()
	started = false
	score = 0

func _on_play_pressed() -> void:
	new_game()

func _on_exit_pressed() -> void:
	_notification(NOTIFICATION_WM_CLOSE_REQUEST)

func _save_data(path : String, save_var):
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	var json = JSON.new()
	if (save_file):
		save_file.store_string(JSON.stringify(save_var))
		save_file.close()
	else:
		print(path, " isn't exist!")
func _on_upgrade_pressed() -> void:
	_disable_button()
	var upgrade_menu_hud = upgrade_menu.instantiate()
	upgrade_menu_hud.player_data = player_loaded_data
	add_child(upgrade_menu_hud)
	$PlayerScore.hide()
	$PlayerScore.add_to_group("player_score")

func _on_pause_button_pressed() -> void:
	if (get_tree().get_nodes_in_group("pause").size() == 0):
		get_tree().paused = true
		var pause_menu_hud = pause_menu.instantiate()
		pause_menu_hud.add_to_group("pause")
		add_child(pause_menu_hud)
	elif (get_tree().get_nodes_in_group("pause").size() == 1):
		get_tree().paused = false
		get_tree().call_group("pause", "queue_free")
		get_tree().call_group("settings","queue_free")
	else:
		get_tree().paused = false
		get_tree().call_group("pause", "queue_free")

func _on_delay_boss_spawn_timeout() -> void:
	$Soundtrack_2.stop()
	$BossSoundTrack_1.play()
	is_waiting = false
	wave_count += 1
	count_enemy = 1
	_spawn_boss()
	$DelayBossSpawn.stop()

func _on_wave_delay_timeout() -> void:
	wave_count += 1
	enemy_remaining += 2
	enemy_remaining = int(enemy_remaining)
	temp_enemy_spawn = enemy_remaining
	var temp = enemy_remaining
	enemy_number[0] = int(ceil(temp * enemy_percent[0]))
	temp = enemy_remaining - enemy_number[0]
	enemy_number[1] = int(ceil(temp * enemy_percent[1] / (1 - enemy_percent[0])))
	enemy_number[2] = int(floor(temp * enemy_percent[2] / (1 - enemy_percent[0])))
	enemy_number[3] = enemy_number[0] - enemy_number[1] - enemy_number[2]
	count_enemy = enemy_remaining
	if fighting_boss == true:
		fighting_boss = false
	$Wave_Delay.stop()
	is_waiting = false
	$EnemySpawn.start()

func _on_return_fire_rate_timeout() -> void:
	player.player_data["fire_rate"] = player_loaded_data["fire_rate"]

func _on_return_resistance_timeout() -> void:
	player.player_data["resistance"] = player_loaded_data["resistance"]

func _on_return_speed_timeout() -> void:
	player.player_data["speed"] = player_loaded_data["speed"]
	
func _show_indicator(number : float, text : String, text_2 : String, color : Color) -> Area2D:
	if (settings_data["indicator_enabled"] == true):
		var an_indicator = indicator.instantiate()
		an_indicator.label_name = text
		an_indicator.label_name += str(int(number)) 
		an_indicator.label_name += text_2
		an_indicator.color_name = color
		return an_indicator
	return null
func _add_effect(input_time : float, effect_name : String):
	var found = false
	for effect in get_tree().get_nodes_in_group("collectable_effect"):
		if (effect.animation_name == effect_name):
			found = true
			effect.multiplier += 1
			effect._reset_timer()
	if (found == false):
		var new_effect = effect.instantiate()
		new_effect.time = input_time
		new_effect.animation_name = effect_name
		var collectable_effect = get_tree().get_nodes_in_group("collectable_effect")
		if (collectable_effect.size() == 0):
			new_effect.position = Vector2(45, 1038)
		else:
			new_effect.position = collectable_effect.get(collectable_effect.size() - 1).position + Vector2(90, 0)
			
		new_effect.add_to_group("collectable_effect")
		add_child(new_effect)


func _on_soundtrack_1_finished() -> void:
	$Soundtrack_1.play()


func _on_soundtrack_2_finished() -> void:
	$Soundtrack_2.play()


func _on_boss_sound_track_1_finished() -> void:
	$BossSoundTrack_1.play()


func _on_settings_pressed() -> void:
	var setting = settings_menu.instantiate()
	_disable_button()
	add_child(setting)

func _enable_button() -> void:
	$Play.disabled = false
	$Upgrade.disabled = false
	$Settings.disabled = false
	$Exit.disabled = false

func _disable_button() -> void:
	$Play.disabled = true
	$Upgrade.disabled = true
	$Settings.disabled = true
	$Exit.disabled = true

func _notification(what: int) -> void:
	if (what == NOTIFICATION_WM_CLOSE_REQUEST):
		get_tree().quit()
		_save_data("user://player.dat", player_loaded_data)
		_save_data("user://settings.dat", settings_data)
