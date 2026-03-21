extends Node

@export var flush_interval: float = 5.0

var online: bool = false
var event_queue: Array[Dictionary] = []

@onready var flush_timer: Timer = Timer.new()


func _ready() -> void:
	add_child(flush_timer)
	flush_timer.one_shot = false
	flush_timer.wait_time = flush_interval
	flush_timer.timeout.connect(_on_flush_timer_timeout)
	flush_timer.start()


func queue_event(event_type: String, payload: Dictionary) -> void:
	event_queue.append({
		"event_type": event_type,
		"payload": payload,
		"timestamp": Time.get_unix_time_from_system()
	})


func set_online(value: bool) -> void:
	online = value
	if online:
		_flush_queue()


func _on_flush_timer_timeout() -> void:
	if online:
		_flush_queue()


func _flush_queue() -> void:
	if event_queue.is_empty():
		return
	for queued_event in event_queue:
		print("[MockAPI] Sent: ", queued_event)
	event_queue.clear()
