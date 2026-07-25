extends Node2D

var time = 0
var animation_name = ""
var multiplier = 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$EffectSprite.animation = animation_name
	$EndEffect.wait_time = time
	$EndEffect.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Time.text = str(int($EndEffect.time_left + 1))
	$Multiplier.text = "x" + str(int(multiplier))

func _on_end_effect_timeout() -> void:
	if (get_tree().get_nodes_in_group("player").size() != 0):
		get_tree().get_first_node_in_group("player")._remove_effect(multiplier)
	var index = -1
	var effect_group = get_tree().get_nodes_in_group("collectable_effect")
	for i in range (0, effect_group.size()):
		if (effect_group[i] == self):
			index = i 
		elif (index != -1 && i > index):
			effect_group[i].position -= Vector2(90, 0)
	
	remove_from_group("collectable_effect")
	queue_free()

func _reset_timer() -> void:
	$EndEffect.stop()
	$EndEffect.start()
