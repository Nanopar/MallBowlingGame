extends Node3D

@export var chunkInstance : PackedScene = preload("res://Scenes/chunk.tscn");
@export var canvas : CanvasLayer = null;
# Called when the node enters the scene tree for the first time.
func _ready():
	canvas.get_node("Generating").hide();
	gen()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(Input.is_action_just_pressed("ui_paste")):
		canvas.get_node("Generating").show();
		await get_tree().create_timer(1).timeout
		for n in get_children():
			remove_child(n)
			n.queue_free() 
		gen();

func gen():
	for x in range(8):
		for y in range(8):
			var newChunk = chunkInstance.instantiate()
			add_child(newChunk)
			newChunk.global_position.x = x * 16;
			newChunk.global_position.z = y * 16;
			var models = newChunk.get_node("Models").get_children();
			var pick;
			if(randi_range(0,10) >= 4):
				pick = models.pick_random();
			else:
				pick = models[0];
			
			if pick.name == "3":
				var Arotation = [0,90,180,270];
				pick.rotation_degrees.y = Arotation.pick_random()
			elif pick.name == "4":
				var Arotation = [0,90];
				pick.rotation_degrees.y = Arotation.pick_random()
			pick.show();
			await get_tree().create_timer(0.00000000000000000001).timeout
	await get_tree().create_timer(1).timeout
	canvas.get_node("Generating").hide();
	pass # Replace with function body.
