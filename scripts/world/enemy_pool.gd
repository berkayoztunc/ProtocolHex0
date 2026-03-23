class_name EnemyPool
extends Node

# How many instances to pre-warm per archetype at startup.
const PRE_WARM_PER_TYPE: int = 2

# archetype_id -> Array[CharacterBody2D]
# All entries are children of this node.
# Availability is tracked by visibility: visible=false means dormant/available.
var _pools: Dictionary = {}
var _scene: PackedScene


func initialize(scene: PackedScene) -> void:
	_scene = scene
	var archetypes: Dictionary = ConfigService.get_value("enemies.archetypes", {}) as Dictionary
	for key in archetypes.keys():
		var arch_id: String = str(key)
		_pools[arch_id] = []
		for _i in PRE_WARM_PER_TYPE:
			_create_for_archetype(arch_id)


# Returns a dormant (invisible, disabled) enemy of the requested archetype.
# Caller is responsible for calling activate() after full setup.
func acquire(archetype_id: String) -> CharacterBody2D:
	if not _pools.has(archetype_id):
		_pools[archetype_id] = []
	var pool: Array = _pools[archetype_id]
	for entry in pool:
		var e: CharacterBody2D = entry as CharacterBody2D
		if e != null and not e.visible:
			return e
	# Pool exhausted for this archetype — expand
	_create_for_archetype(archetype_id)
	return _pools[archetype_id].back() as CharacterBody2D


# Called after setup is complete to make the enemy live.
func activate(enemy: CharacterBody2D) -> void:
	enemy.visible = true
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")


# Called from enemy.gd instead of queue_free() when a pool owner is set.
func release(enemy: CharacterBody2D) -> void:
	enemy.visible = false
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.velocity = Vector2.ZERO
	enemy.remove_from_group("enemies")
	if enemy.has_method("reset_for_pool"):
		enemy.reset_for_pool()


func _create_for_archetype(archetype_id: String) -> void:
	var enemy: CharacterBody2D = _scene.instantiate() as CharacterBody2D
	# Pre-configure archetype BEFORE add_child so that _ready() uses the
	# correct char_base_path when setting up the animated sprite.
	var arch_data: Variant = ConfigService.get_value("enemies.archetypes.%s" % archetype_id, null)
	if arch_data != null and typeof(arch_data) == TYPE_DICTIONARY:
		enemy.call("setup_from_archetype", archetype_id, arch_data as Dictionary)
	enemy.set("_pool_owner", self)
	add_child(enemy)
	# _ready() runs synchronously during add_child and calls add_to_group("enemies").
	# Remove from the group since this instance is dormant.
	enemy.remove_from_group("enemies")
	enemy.visible = false
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	_pools[archetype_id].append(enemy)
