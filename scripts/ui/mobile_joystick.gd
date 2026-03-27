extends Control
## Virtual on-screen joystick for mobile / touch devices.
##
## Emits move_left / move_right / move_up / move_down actions exactly the same
## way a keyboard would, so player.gd needs ZERO changes.
##
## Usage: instantiate this scene as a child of HUD CanvasLayer; it is fully
## self-contained.  Visibility should be controlled by its parent.

## Radius of the joystick base circle in pixels
const BASE_RADIUS := 70.0
## Maximum pixel distance the thumb can travel from the base center
const THUMB_RADIUS := 65.0
## Normalised axis magnitude below which movement is ignored (dead zone)
const DEAD_ZONE := 0.25
## Background circle colour
const COLOR_BASE := Color(1.0, 1.0, 1.0, 0.15)
## Thumb circle colour
const COLOR_THUMB := Color(1.0, 1.0, 1.0, 0.45)
## Rim colour
const COLOR_RIM := Color(1.0, 1.0, 1.0, 0.3)

var _base_center: Vector2 = Vector2.ZERO
var _thumb_offset: Vector2 = Vector2.ZERO
var _touch_index: int = -1          # which finger owns this joystick
var _is_pressed: bool = false

# References to our two drawn circles (created procedurally)
var _thumb: Control = null
var _base_visual: Control = null

# Which actions are currently "held" so we can release the right ones
var _held_actions: Array[String] = []


func _ready() -> void:
	set_process_input(true)
	anchor_left   = 0.0
	anchor_top    = 1.0
	anchor_right  = 0.0
	anchor_bottom = 1.0
	# Bottom-left: 20px inset on each side; size accommodates the draw area
	var diameter := (BASE_RADIUS + THUMB_RADIUS) * 2.0 + 20.0
	offset_left   = 20.0
	offset_top    = -(diameter + 20.0)
	offset_right  = diameter + 20.0
	offset_bottom = -20.0
	_base_center  = Vector2(size.x * 0.5, size.y * 0.5)
	# Draw order: this node draws the base; thumb is a child drawn on top
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.5)
	# Outer rim
	draw_circle(c, BASE_RADIUS + 4.0, COLOR_RIM)
	# Base fill
	draw_circle(c, BASE_RADIUS, COLOR_BASE)
	# Thumb
	var thumb_pos := c + _thumb_offset
	draw_circle(thumb_pos, BASE_RADIUS * 0.40, COLOR_THUMB)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			if _touch_index == -1 and _point_in_joystick(e.position):
				_touch_index = e.index
				_is_pressed  = true
				_on_drag(e.position)
		else:
			if e.index == _touch_index:
				_release()
	elif event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		if e.index == _touch_index and _is_pressed:
			_on_drag(e.position)


func _on_drag(screen_pos: Vector2) -> void:
	# Convert screen position to local coordinates, relative to base center
	var local := get_global_transform().affine_inverse() * screen_pos
	var c     := Vector2(size.x * 0.5, size.y * 0.5)
	var delta := local - c
	if delta.length() > THUMB_RADIUS:
		delta = delta.normalized() * THUMB_RADIUS
	_thumb_offset = delta
	queue_redraw()
	_update_actions()


func _release() -> void:
	_touch_index  = -1
	_is_pressed   = false
	_thumb_offset = Vector2.ZERO
	queue_redraw()
	_clear_actions()


func _update_actions() -> void:
	var dir: Vector2 = _thumb_offset / THUMB_RADIUS   # -1..+1
	var new_actions: Array[String] = []
	if dir.x < -DEAD_ZONE:
		new_actions.append("move_left")
	if dir.x >  DEAD_ZONE:
		new_actions.append("move_right")
	if dir.y < -DEAD_ZONE:
		new_actions.append("move_up")
	if dir.y >  DEAD_ZONE:
		new_actions.append("move_down")

	# Release actions that are no longer active
	for action in _held_actions:
		if not new_actions.has(action):
			Input.action_release(action)

	# Press newly active actions
	for action in new_actions:
		if not _held_actions.has(action):
			Input.action_press(action)

	_held_actions = new_actions


func _clear_actions() -> void:
	for action in _held_actions:
		Input.action_release(action)
	_held_actions.clear()


## Returns true when the given global screen position is inside the joystick's
## interactive area (a circle of radius BASE_RADIUS around the base center).
func _point_in_joystick(screen_pos: Vector2) -> bool:
	var local := get_global_transform().affine_inverse() * screen_pos
	var c     := Vector2(size.x * 0.5, size.y * 0.5)
	return local.distance_to(c) <= BASE_RADIUS + THUMB_RADIUS
