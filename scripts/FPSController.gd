extends KinematicBody

class_name FPSController

########################################
## FPS Script Signals
########################################
signal fps_shoot
signal fps_bullet_hit
signal fps_die
signal fps_jump

########################################
## Custom Script Variables
########################################
export(Dictionary) var inputActions : Dictionary = {
	"Move Forward": "movement_forward",
	"Move Backward": "movement_backward",
	"Move Left": "movement_left",
	"Move Right": "movement_right",
	"Shoot": "shoot",
	"Jump": "movement_jump",
	"Crouch": "movement_crouch",
	"Quit": "ui_cancel"
}
export(bool) var fullAimMode : bool = true
export(bool) var captureMouse : bool = true
export(float) var cameraSensitivity : float = 0.05
export(bool) var canShoot : bool = true
export(bool) var canJump : bool = true
export(bool) var canCrouch : bool = false
export(Texture) var targetTexture : Texture
export(Vector2) var targetPosition : Vector2 = Vector2(490, 210)
export(Vector3) var raycastDirection : Vector3 = Vector3(0, 0, -2000)
export(int) var collisionRadius : int = 1
export(float) var gravity_force : float = 25
export(float) var maxSpeed : float = 16
export(float) var jumpForce : float = 10
export(float) var acceleration : float = 5
export(float) var deacceleration : float = 16
export(float) var crouchDefaultHeight : float = 6.0
export(float) var crouchMinHeight : float = 2.5
export(float) var maxDieHeight : float = 40

########################################
## Internal Script Variables
########################################
var cameraGimbal : Spatial
var fpsCamera : Camera
var fpsCollision : CollisionShape
var fpsCollisionShape : CapsuleShape
var fpsAimRaycast : RayCast
var fpsHUD : CanvasLayer
var fpsHUDControl : Control
var fpsHUDAim : TextureRect
var characterVelocity = Vector3.ZERO
var characterDirection = Vector3.ZERO

func _ready(): _generateFPSNodes()

func _generateFPSNodes():
	# FPS Collision Shape
	fpsCollision =  CollisionShape.new()
	fpsCollisionShape = CapsuleShape.new()
	fpsCollisionShape.radius = collisionRadius
	fpsCollision.rotation_degrees.x = 90
	fpsCollision.shape = fpsCollisionShape
	add_child(fpsCollision)
	# FPS Camera 
	cameraGimbal = Spatial.new()
	fpsCamera = Camera.new()
	fpsCamera.current = true
	cameraGimbal.add_child(fpsCamera)
	add_child(cameraGimbal)
	# FPS Raycast
	fpsAimRaycast = RayCast.new()
	fpsAimRaycast.enabled = true
	fpsAimRaycast.cast_to = raycastDirection
	add_child(fpsAimRaycast)
	# HUD Controls
	fpsHUD = CanvasLayer.new()
	fpsHUDControl = Control.new()
	fpsHUDAim = TextureRect.new()
	if not targetTexture: 
		var defaultTargetTexture : Texture = load("res://addons/fps_controller/crosshair_default.png")
		fpsHUDAim.texture = defaultTargetTexture
	else: fpsHUDAim.texture = targetTexture
	fpsHUDAim.rect_position = targetPosition
	fpsHUDControl.add_child(fpsHUDAim)
	fpsHUD.add_child(fpsHUDControl)
	add_child(fpsHUD)
	# Mouse Settings 
	if captureMouse: 
		get_viewport().warp_mouse(OS.get_window_size() / 2)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	_fpsInputs()
	if canShoot: _fpsShoot()
	if canJump: _fpsJump()
	if canCrouch: _fpsCrouch(delta)
	_fpsDieFalling()
	_fpsQuitGame()
	_fpsMovement(delta)


func _fpsInputs():
	characterDirection = Vector3.ZERO
	var camXForm = fpsCamera.get_global_transform()
	var moveVector = Vector2.ZERO
	if Input.is_action_pressed(inputActions["Move Forward"]): moveVector.y += 1
	if Input.is_action_pressed(inputActions["Move Backward"]): moveVector.y -= 1
	if Input.is_action_pressed(inputActions["Move Left"]): moveVector.x -= 1
	if Input.is_action_pressed(inputActions["Move Right"]): moveVector.x += 1
	moveVector = moveVector.normalized()
	characterDirection += -camXForm.basis.z * moveVector.y
	characterDirection += camXForm.basis.x * moveVector.x


func _fpsMovement(delta):
	characterDirection.y = 0
	characterDirection = characterDirection.normalized()
	characterVelocity.y += delta * -gravity_force
	var hvel = characterVelocity
	hvel.y = 0
	var target = characterDirection
	target *= maxSpeed
	var accel
	if characterDirection.dot(hvel) > 0: accel = acceleration
	else: accel = deacceleration
	hvel = hvel.linear_interpolate(target, accel * delta)
	characterVelocity.x = hvel.x
	characterVelocity.z = hvel.z
	characterVelocity = move_and_slide(characterVelocity, Vector3.UP, true)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if fullAimMode: cameraGimbal.rotate_x(deg2rad(event.relative.y * cameraSensitivity * -1))
		self.rotate_y(deg2rad(event.relative.x * cameraSensitivity * -1))
		var cameraRotation = cameraGimbal.rotation_degrees
		cameraRotation.x = clamp(cameraRotation.x, -70, 70)
		cameraGimbal.rotation_degrees = cameraRotation


func _fpsShoot():
	if Input.is_action_pressed(inputActions["Shoot"]): 
		emit_signal("fps_shoot")
		var collider = fpsAimRaycast.get_collider()
		if fpsAimRaycast.is_colliding(): emit_signal("fps_bullet_hit", collider)


func _fpsQuitGame(): if Input.is_action_just_pressed(inputActions["Quit"]): get_tree().quit()


func _fpsDieFalling(): 
	if characterVelocity.y <= -maxDieHeight: 
		emit_signal("fps_die")
		get_tree().reload_current_scene()


func _fpsJump(): 
	if is_on_floor() and Input.is_action_just_pressed(inputActions["Jump"]): 
		characterVelocity.y = jumpForce
		emit_signal("fps_jump")


func _fpsCrouch(delta):
	if Input.is_action_pressed(inputActions["Crouch"]): fpsCollision.shape.height -= crouchMinHeight * delta
	else: fpsCollision.shape.height += crouchDefaultHeight * delta
	fpsCollision.shape.height = clamp(fpsCollision.shape.height, crouchMinHeight, crouchDefaultHeight)
