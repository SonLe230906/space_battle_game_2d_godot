extends Area2D
@export var label_name = "Label"
@export var color_name = Color.AQUA

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label.text = label_name
	$Label.modulate = color_name
	position.x += 30
	position.y -= 30 - randf_range(0, 15)
	$Timer.start()
	modulate.a = 0.1
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "modulate:a", 1, 0.1)
	tween.tween_property(self, "position:y", position.y - 20, 0.1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (modulate.a <= 0):
		queue_free()

func _on_timer_timeout() -> void:
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "position:y", position.y - 20, 0.25)
	tween.tween_property(self, "modulate:a", 0, 0.25)
