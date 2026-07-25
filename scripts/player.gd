extends CharacterBody2D

var screen_size
@export var bullet_scene : PackedScene
@export var indicator : PackedScene
@export var player_data = {
	"MAX_HP" : 150,
	"highest_score" : 0,
	"coins" : 0,
	"coin_multiplier" : 0,
	"speed" : 500,
	"fire_rate" : 1.0,
	"bullet_damage" : 20,
	"crit_rate" : 0,
	"crit_damage" : 1,
	"healing_rate" : 1,
	"resistance" : 0,
	"upgraded" : [0,0,0,0,0,0,0,0]
}
@export var current_HP = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	position.x = 350
	position.y = 870
	$Healing_Timer.start()
	$PlayerFireRate.start()
	current_HP = player_data["MAX_HP"]

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * player_data["speed"]
	move_and_slide()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = position.clamp(Vector2.ZERO + Vector2(40, 40), screen_size - Vector2(40, 40))
	$HealthBar.value = float(current_HP)/float(player_data["MAX_HP"]) * 100
	$PlayerFireRate.wait_time = player_data["fire_rate"]
	
func _on_player_fire_rate_timeout() -> void:
	var bullet = bullet_scene.instantiate()
	bullet.position = position - Vector2(0, 50)
	bullet.velocity = Vector2(0, -500)
	bullet.add_to_group("player_bullet")
	get_tree().get_first_node_in_group("main").add_child(bullet)
	$PlayerFireRate.start()
	
func _on_area_entered(area: Area2D) -> void:
	var damage_dealt = 0
	if area.is_in_group("enemies_bullet"):	
		damage_dealt = area.bullet_damage
		damage_dealt -= damage_dealt * player_data["resistance"]
		current_HP -= damage_dealt
		_show_indicator(damage_dealt, "- ", Color.RED)
		area._cause_effect()
		if (!area.is_in_group("laser")):
			area.queue_free()
		$Damaged_1.play()
	if area.is_in_group("enemy"):
		damage_dealt = area.damage
		damage_dealt -= damage_dealt * player_data["resistance"]
		current_HP -= damage_dealt
		_show_indicator(damage_dealt, "- ", Color.RED)
		$Damaged_1.play()
	
func _show_indicator(number : float, text : String, color : Color) -> void:
	if (get_tree().get_first_node_in_group("main").settings_data["indicator_enabled"] == true):
		var new_indicator = indicator.instantiate()
		new_indicator.label_name = text + str(int(number))
		new_indicator.color_name = color
		add_child(new_indicator)
	
func _on_healing_timer_timeout() -> void:
	if (current_HP < player_data["MAX_HP"] && player_data["healing_rate"] > 0):
		current_HP += player_data["healing_rate"]
		_show_indicator(player_data["healing_rate"], "+ ", Color.GREEN)
	$Healing_Timer.start()


func _remove_effect(multiplier : float) -> void:
	player_data["speed"] = get_tree().get_first_node_in_group("main").player_loaded_data["speed"]
	player_data["fire_rate"] = get_tree().get_first_node_in_group("main").player_loaded_data["fire_rate"]
