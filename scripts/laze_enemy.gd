extends Base_Enemy

func _ready() -> void:
	MAX_HP = 175
	current_HP = MAX_HP
	speed = 40.0
	fire_rate = 0.95
	damage = 25
	_adjust_power()
	_on_enemy_fire_rate_timeout()

func _on_enemy_fire_rate_timeout() -> void:
	var bullet_1 = bullet_scene.instantiate()
	var bullet_2 = bullet_scene.instantiate()
	bullet_1.position = position + Vector2(5, 45)
	bullet_2.position = position - Vector2(5, 0)
	bullet_2.position.y += 45
	bullet_1.velocity = Vector2(0, 500)
	bullet_2.velocity = Vector2(0 ,500)
	bullet_1.bullet_damage = damage
	bullet_2.bullet_damage = damage
	bullet_1.add_to_group("enemies_bullet")
	bullet_2.add_to_group("enemies_bullet")
	get_tree().get_first_node_in_group("main").add_child(bullet_1)
	get_tree().get_first_node_in_group("main").add_child(bullet_2)
	$EnemyFireRate.start()
