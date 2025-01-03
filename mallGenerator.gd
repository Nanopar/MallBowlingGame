extends Node3D

@export var chunkInstance : PackedScene = preload("res://Scenes/chunk.tscn");
@export var canvas : CanvasLayer = null;
# Called when the node enters the scene tree for the first time.
func _ready():
	
	canvas.get_node("Generating").hide();
	gen()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(Input.is_action_just_pressed("regen")):
		canvas.get_node("Generating").show();
		await get_tree().create_timer(1).timeout
		for n in get_children():
			remove_child(n)
			n.queue_free() 
		gen();

func gen():
	for x in range(4):
		for y in range(4):
			var newChunk = chunkInstance.instantiate()
			add_child(newChunk)
			newChunk.global_position.x = x * 16;
			newChunk.global_position.z = y * 16;
			var models = newChunk.get_node("Models").get_children();
			for i in models:
				var e = i.get_node("blocks").get_children()
				for c in e:
					c.collision_shape.disabled = true;
				i.hide();

			var pick;
			if(true):
				pick = models[0];
			elif(randi_range(0,10) >= 4):
				pick = models.pick_random();
			else:
				pick = models[0];
			
			if pick.name == "3" || pick.name == "5":
				var Arotation = [0,90,180,270];
				pick.rotation_degrees.y = Arotation.pick_random()
			elif pick.name == "4":
				var Arotation = [0,90];
				pick.rotation_degrees.y = Arotation.pick_random()
			pick.show();
			var e = pick.get_node("blocks").get_children()
			for c in e:
				c.collision_shape.disabled = false;
			#for i in models:
			#	if i != pick:
			#		remove_child(i);
			#		i.queue_free();
			await get_tree().create_timer(0.00000000000000000001).timeout
	await get_tree().create_timer(1).timeout
	canvas.get_node("Generating").hide();
	pass # Replace with function body.
