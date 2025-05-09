extends CharacterBody3D

@export var JUMP_VELOCITY = 12.5
@export var WALKING_SPEED = 5.0
@export var SPRINTING_SPEED = 8.0
var ORIG_SPRINTING_SPEED = 8.0
@export var CROUCHING_SPEED = 3.0
@export var CROUCHING_DEPTH = -0.9
@export var MOUSE_SENS = 0.25
@export var LERP_SPEED = 6
@export var AIR_LERP_SPEED = 6
@export var FREE_LOOK_TILT_AMOUNT = 5.0
@export var SLIDING_SPEED = 24
@export var WIGGLE_ON_WALKING_SPEED = 14.0
@export var WIGGLE_ON_SPRINTING_SPEED = 22.0
@export var WIGGLE_ON_CROUCHING_SPEED = 10.0
@export var WIGGLE_ON_WALKING_INTENSITY = 0.1
@export var WIGGLE_ON_SPRINTING_INTENSITY = 0.2
@export var WIGGLE_ON_CROUCHING_INTENSITY = 0.05
@export var BUNNY_HOP_ACCELERATION = 0.1
@export var canvas : CanvasLayer = null;

var origPos : Vector3 = Vector3.ZERO;
var current_speed = 5.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3.ZERO
var is_walking = false
var stamcd = false
var is_sprinting = false
var is_crouching = false
var is_free_looking = false
var slide_vector = Vector2.ZERO
var wiggle_vector = Vector2.ZERO
var wiggle_index = 0.0
var wiggle_current_intensity = 0.0
var bunny_hop_speed = SPRINTING_SPEED
var last_velocity = Vector3.ZERO
var stand_after_roll = false
var playerPaused = false;

var gainingSpeed = 0;

var bottomStepCollide = false;
var topStepCollide = false;

var bobbing = 0;
var bobbingMultiplier = 0;
var bobbingSpeed = 1;
var isNoclip = false;

var isAllowedToSprint = true;
var isAllowedToSlide = true;

@export var OFFLINE = false;


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if(!OFFLINE):
		$Neck/Head/Eyes/Camera.current = is_multiplayer_authority();
	origPos = global_position;
	ORIG_SPRINTING_SPEED = SPRINTING_SPEED;


func _input(event):
	if(event is InputEventKey):
		if(event.is_action_pressed("ui_cancel")):
			playerPaused = !playerPaused;
			if(playerPaused):
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	if event is InputEventMouseMotion:
		if(isNoclip):return;
		if is_free_looking:
			$Neck.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
			$Neck.rotation.y = clamp($Neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
		$Neck/Head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
		$Neck/Head.rotation.x = clamp($Neck/Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta):
	if(!OFFLINE && !is_multiplayer_authority()):
		return;
	
	if(Input.is_action_just_pressed("free_look")):
		isNoclip = !isNoclip;
		if(isNoclip):
			$"../FreeLookCamera".global_position = get_node("Neck/Head/Eyes/Camera").global_position;
			$"../FreeLookCamera".make_current();
		else:
			get_node("Neck/Head/Eyes/Camera").make_current();
			
	if(isNoclip):return;
	
	if(true):
		if(bottomStepCollide && !topStepCollide):
			global_position.y += 0.57;
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var eVel = velocity * transform.basis
	$Neck.rotation.z = lerp($Neck.rotation.z,eVel.x*-0.01,0.15);
	if stand_after_roll:
		$Neck/Head.position.y = lerp($Neck/Head.position.y, 0.0, delta * LERP_SPEED)
		$StandingCollisionShape.disabled = true
		$CrouchingCollisionShape.disabled = false
		stand_after_roll = false
	
	if Input.is_action_pressed("crouch") or $RayCast.is_colliding():
		if is_on_floor():
			current_speed = lerp(current_speed, CROUCHING_SPEED, delta * LERP_SPEED)
		$Neck/Head.position.y = lerp($Neck/Head.position.y, CROUCHING_DEPTH, delta * 15)
		$StandingCollisionShape.disabled = true
		$CrouchingCollisionShape.disabled = false
		wiggle_current_intensity = WIGGLE_ON_CROUCHING_INTENSITY
		wiggle_index += WIGGLE_ON_CROUCHING_SPEED * delta
		if is_sprinting and input_dir != Vector2.ZERO and is_on_floor():
			$SlidingTimer.start()
			slide_vector = input_dir
		elif !Input.is_action_pressed("sprint"):
			$SlidingTimer.stop()
		is_walking = false
		is_sprinting = false
		is_crouching = true
	else:
		$Neck/Head.position.y = lerp($Neck/Head.position.y, 0.0, delta * 8)
		$StandingCollisionShape.disabled = false
		$CrouchingCollisionShape.disabled = true
		$SlidingTimer.stop()
		if Input.is_action_pressed("sprint") && isAllowedToSprint:
			if(isAllowedToSprint): ## Yes we check it 2 times, this is because of mental retardation
				if !Input.is_action_pressed("jump"):
					bunny_hop_speed = SPRINTING_SPEED
				current_speed = lerp(current_speed, bunny_hop_speed, delta * LERP_SPEED)
				wiggle_current_intensity = WIGGLE_ON_SPRINTING_INTENSITY
				wiggle_index += WIGGLE_ON_SPRINTING_SPEED * delta
				is_walking = false
				is_sprinting = true
			else:
				is_sprinting = false
			is_crouching = false
		else:
			current_speed = lerp(current_speed, WALKING_SPEED, delta * LERP_SPEED)
			wiggle_current_intensity = WIGGLE_ON_WALKING_INTENSITY
			wiggle_index += WIGGLE_ON_WALKING_SPEED * delta
			is_walking = true
			is_sprinting = false
			is_crouching = false
	
	if Input.is_action_pressed("free_look") or !$SlidingTimer.is_stopped():
		is_free_looking = true
		if $SlidingTimer.is_stopped():
			$Neck/Head/Eyes.rotation.z = -deg_to_rad(
				$Neck.rotation.y * FREE_LOOK_TILT_AMOUNT
			)
		else:
			$Neck/Head/Eyes.rotation.z = lerp(
				$Neck/Head/Eyes.rotation.z,
				deg_to_rad(4.0), 
				delta * LERP_SPEED
			)
	else:
		is_free_looking = false
		rotation.y += $Neck.rotation.y
		$Neck.rotation.y = 0
		$Neck/Head/Eyes.rotation.z = lerp(
			$Neck/Head/Eyes.rotation.z,
			0.0,
			delta*LERP_SPEED
		)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif $SlidingTimer.is_stopped() and input_dir != Vector2.ZERO:
		wiggle_vector.y = sin(wiggle_index)
		wiggle_vector.x = sin(wiggle_index / 2) + 0.5
		$Neck/Head/Eyes.position.y = lerp(
			$Neck/Head/Eyes.position.y,
			wiggle_vector.y * (wiggle_current_intensity / 2.0), 
			delta * LERP_SPEED
		)
		$Neck/Head/Eyes.position.x = lerp(
			$Neck/Head/Eyes.position.x,
			wiggle_vector.x * wiggle_current_intensity, 
			delta * LERP_SPEED
		)
	else:
		$Neck/Head/Eyes.position.y = lerp($Neck/Head/Eyes.position.y, 0.0, delta * LERP_SPEED)
		$Neck/Head/Eyes.position.x = lerp($Neck/Head/Eyes.position.x, 0.0, delta * LERP_SPEED)
		#if last_velocity.y <= -7.5:
		#	$Neck/Head.position.y = lerp($Neck/Head.position.y, CROUCHING_DEPTH, delta * LERP_SPEED)
		#	$StandingCollisionShape.disabled = false
		#	$CrouchingCollisionShape.disabled = true
		#	$Neck/Head/Eyes/AnimationPlayer.play("roll")
		if last_velocity.y <= -7.5:
			$Neck/Head/Eyes/AnimationPlayer.play("landing")
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		$Neck/Head/Eyes/AnimationPlayer.play("jump")
		if !$SlidingTimer.is_stopped():
			velocity.y = JUMP_VELOCITY * 1.25
			$SlidingTimer.stop()
		else:
			velocity.y = JUMP_VELOCITY
		if is_sprinting:
			bunny_hop_speed += BUNNY_HOP_ACCELERATION
		else:
			bunny_hop_speed = SPRINTING_SPEED
	
	if $SlidingTimer.is_stopped():
		if is_on_floor():
			direction = lerp(
				direction,
				(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				delta * LERP_SPEED
			)
		elif input_dir != Vector2.ZERO:
			direction = lerp(
				direction,
				(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				delta * AIR_LERP_SPEED
			)
	else: ##this is the 100% sliding code lmfao
		if(isAllowedToSlide):
			direction = (transform.basis * Vector3(slide_vector.x, 0.0, slide_vector.y)).normalized()
			current_speed = ($SlidingTimer.time_left / $SlidingTimer.wait_time + 0.5) * SLIDING_SPEED
		else:
			$SlidingTimer.stop() ##Cancel the player's slide because hes tired
	current_speed = clamp(current_speed, 3.0, 24.0)
	
	if direction:
		velocity.x = direction.x * current_speed * gainingSpeed
		velocity.z = direction.z * current_speed * gainingSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	last_velocity = velocity
	
	var checkVel = velocity * transform.basis
	if(abs(checkVel.z) > 9):
		pass
	else:
		pass
	newHandleSprintLimit(delta);
	if(is_sprinting):
		gainingSpeed = clampf(gainingSpeed + delta*0.8, 1, 1.8);
		
	else:
		gainingSpeed = clampf(gainingSpeed - delta*1.5, 1, 1.8);
	#print(gainingSpeed)
	move_and_slide()
	
var timerSprint = 0.005;
var timerSlide = 0.025;
var timerUnSprint = 0.001;
func handleSprintLimit(delta):
	
	if(stamcd):
		SPRINTING_SPEED = WALKING_SPEED;
	else:
		SPRINTING_SPEED = ORIG_SPRINTING_SPEED;
	
	#print(current_speed == SLIDING_SPEED);
	#print("sprint: " + str(is_sprinting) + "  crouch: " + str(is_crouching) + "  slide: " + str(current_speed == SLIDING_SPEED) + " cd:" + str(stamcd))
	##TODO: if sliding, decrease more energy
		##  set sprint speed to walkspeed if energy is out [/]
	if(is_sprinting) :
		#print("SPRINT")
		if(timerSprint <= 0):
			if canvas.get_node("energyBar").frame > 0:
				canvas.get_node("energyBar").frame -= 1;
			timerSprint = 0.005;
		else:
			timerSprint -= delta;
	elif ((!(is_sprinting) && !(Input.is_action_pressed("iswalk"))) || ((!(is_sprinting)) && is_crouching) && (current_speed != SLIDING_SPEED)):
		if(timerUnSprint <= 0):
			if(!is_crouching):
				canvas.get_node("energyBar").frame += 1;
				timerUnSprint = 0.08;
			else:
				if(Input.is_action_pressed("iswalk")):
					canvas.get_node("energyBar").frame += 1;
					timerUnSprint = 0.085;
				else:
					canvas.get_node("energyBar").frame += 1;
					timerUnSprint = 0.008;
		else:
			timerUnSprint -= delta;
		if canvas.get_node("energyBar").frame == 100:
			stamcd = false
	
	elif is_crouching && current_speed == SLIDING_SPEED: ##Sliding
		if(timerSprint <= 0):
			if current_speed == SLIDING_SPEED:
				canvas.get_node("energyBar").frame -= 2;
				timerSprint = 0.008;
		else:
			timerSprint -= delta;
	
	if canvas.get_node("energyBar").frame == 0:
		stamcd = true
		pass

func newHandleSprintLimit(delta):
	#print(isAllowedToSprint);
	if(Input.is_action_pressed("iswalk") && round(velocity) != Vector3.ZERO): ##This code only works if the player is moving
		if(is_sprinting) : ##if it's JUST sprinting.
			print("SPRINTING")
			if(timerSprint <= 0):
				if canvas.get_node("energyBar").frame > 0:
					canvas.get_node("energyBar").frame -= 1;
				timerSprint = 0.005;
			else:
				timerSprint -= delta;
		elif(is_on_floor() && is_crouching && Input.is_action_just_pressed("jump") && !stamcd ): ##if it's sliding and jumping, punish the player lmao
			print("SLIDE JUMPING")
			var b = canvas.get_node("energyBar").frame - 25
			var e = create_tween().set_ease(Tween.EASE_OUT);
			e.tween_property(canvas.get_node("energyBar"), "frame", b, 0.25);
			#if(timerSprint <= 0):
			#	if canvas.get_node("energyBar").frame > 0:
			#		canvas.get_node("energyBar").frame -= 2;
			#	timerSprint = 0.008;
			#else:
			#	timerSprint -= delta;
		elif(!is_sprinting && ($SlidingTimer.time_left == 0)) : ##if it's JUST walking AND not sliding, still regen, even if it's moving.
			processRegenCode(delta);
		elif((ceil($SlidingTimer.time_left) != 0.0)): ##if it's JUST sliding
			print("SLIDING")
			if(timerSprint <= 0):
				canvas.get_node("energyBar").frame -= 1;
				timerSprint = 0.008;

				if current_speed == SLIDING_SPEED:
					canvas.get_node("energyBar").frame -= 2;
					timerSprint = 0.008;
				print("why sliding")

			else:
				timerSprint -= delta;
		print($SlidingTimer.time_left)
	else: ##Otherwise, if it's not moving
		processRegenCode(delta);
	print(ceil($SlidingTimer.time_left));
	print(canvas.get_node("energyBar").frame);
	match(canvas.get_node("energyBar").frame): ##Do checking if energy bar is either zero or a hundereud
		100:
			stamcd = false;
		0:
			stamcd = true;
			isAllowedToSlide = false;
			isAllowedToSprint = false;
func processRegenCode(delta):
	if(stamcd): ##We only start to regen if stamcd is true, fully drained out
		isAllowedToSlide = false; ## Again, we set it twice because this is utterly fucking retarded
		isAllowedToSprint = false;
		if(timerUnSprint <= 0):
			if(!is_crouching): ##If it's just crouchign, then make it regen faster.
				canvas.get_node("energyBar").frame += 1;
				timerUnSprint = 0.08;
			else: ##Otherwise, then make it regen normally.
				if(Input.is_action_pressed("iswalk")):
					canvas.get_node("energyBar").frame += 1;
					timerUnSprint = 0.085;
				else:
					canvas.get_node("energyBar").frame += 1;
					timerUnSprint = 0.008;
		else:
			timerUnSprint -= delta;
	else:
		isAllowedToSlide = true;
		isAllowedToSprint = true;

func _on_sliding_timer_timeout():
	is_free_looking = false


func _on_animation_player_animation_finished(anim_name):
	stand_after_roll = anim_name == 'roll' and !is_crouching


func bottomStepEnter(body):
	if(body != self):
		bottomStepCollide = true;
func bottomStepExit(body):
	if(body != self):
		bottomStepCollide = false;

func topStepEntered(body):
	if(body != self):
		topStepCollide = true;
func topStepExit(body):
	if(body != self):
		topStepCollide = false;
