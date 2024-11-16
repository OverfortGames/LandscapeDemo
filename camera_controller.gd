extends CharacterBody3D

const INPUT_SPRINT : String = "sprint";
const INPUT_CROUCH : String = "crouch";
const INPUT_LEFT : String = "left";
const INPUT_RIGHT : String = "right";
const INPUT_UP : String = "up";
const INPUT_DOWN : String = "down";
const INPUT_TOGGLE_GRAVITY : String = "toggle_gravity";
const INPUT_TOGGLE_CURSOR : String = "toggle_cursor";
const GRAVITY : float = 9.81;

@export_group("Editor References")
@export
var camera : Camera3D;
@export_group("Settings")
@export
var normalSpeed : float = 20;
@export
var sprintSpeed : float = 60;
@export
var crouchSpeed : float = 10;
@export 
var decelerationLerpSpeed : float = 5.0;
@export
var gravityMultiplier = 1;
@export
var cameraSensitivity : float = 10;
@export
var cameraClamp : Vector2 = Vector2(-80,80);

var inputSprintPressed : bool;
var inputCrouchPressed : bool;
var inputDirection : Vector2;
var inputToggleGravityPressedThisFrame: bool;
var inputToggleCursorPressedThisFrame: bool;

var currentVelocity : Vector3;

var newCameraRotation : Vector3;

var cursorEnabled : bool;
var gravityEnabled : bool;

func _ready() -> void:
	pass;
	
func _unhandled_input(event: InputEvent) -> void:
	if(inputToggleCursorPressedThisFrame == true):
		return;
	
	if event is InputEventMouseMotion:
		newCameraRotation.y -= event.relative.x * cameraSensitivity;
		newCameraRotation.x -= event.relative.y * cameraSensitivity;
		newCameraRotation.x = clamp(newCameraRotation.x, deg_to_rad(cameraClamp.x), deg_to_rad(cameraClamp.y));
	
func _process(delta):
	gather_input();
	
	if(inputToggleGravityPressedThisFrame):
		gravityEnabled = !gravityEnabled
		
	if(inputToggleCursorPressedThisFrame):
		cursorEnabled = !cursorEnabled
	
	if(cursorEnabled):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
	else: 
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
		
	if(inputToggleCursorPressedThisFrame == false):
		camera.rotation = newCameraRotation;
	
	calculate_current_velocity(delta);
	velocity = currentVelocity;
	
	move_and_slide();
	pass;	
	
func gather_input() -> void:
	inputSprintPressed = Input.is_action_pressed(INPUT_SPRINT);
	inputCrouchPressed = Input.is_action_pressed(INPUT_CROUCH);
	inputDirection = Input.get_vector(INPUT_LEFT, INPUT_RIGHT, INPUT_UP, INPUT_DOWN);
	inputToggleGravityPressedThisFrame = Input.is_action_just_pressed(INPUT_TOGGLE_GRAVITY);
	inputToggleCursorPressedThisFrame =Input.is_action_just_pressed(INPUT_TOGGLE_CURSOR);
	pass;

func calculate_current_velocity(deltaFloat: float) -> void:
	var speed = normalSpeed;
	if(inputSprintPressed):
		speed = sprintSpeed;
	
	if(inputCrouchPressed):
		speed = crouchSpeed;
		
	# Get the input direction and handle the movement/deceleration.
	var direction = (camera.basis * Vector3(inputDirection.x, 0, inputDirection.y)).normalized();
	
	if direction.length_squared() > 0.5:
		currentVelocity.x = direction.x * speed;
		currentVelocity.z = direction.z * speed;
		
		if(gravityEnabled == false):
			currentVelocity.y = direction.y * speed;
			
	else:
		currentVelocity.x = lerp(currentVelocity.x, direction.x * speed, deltaFloat * decelerationLerpSpeed);
		
		if(gravityEnabled == false):
			currentVelocity.y = 0;
			
		currentVelocity.z = lerp(currentVelocity.z, direction.z * speed, deltaFloat * decelerationLerpSpeed);
		
	add_gravity(deltaFloat);
	
func add_gravity(deltaFloat: float) -> void:
	if(gravityEnabled == false):
		return;
		
	if(is_on_floor() == false):
		currentVelocity.y -= GRAVITY * gravityMultiplier * deltaFloat;
