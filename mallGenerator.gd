extends Node3D

@export var chunkInstance : PackedScene = preload("res://Scenes/chunk.tscn");
# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(16):
		for y in range(16):
			var newChunk = chunkInstance.instantiate()
			newChunk.x = x * 8;
			newChunk.y = y * 8;
			
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
