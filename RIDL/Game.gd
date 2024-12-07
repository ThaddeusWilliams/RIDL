extends Node

var variables = {
	
}
var relationships = { # -100 to +100
}

signal CustomSignal(params: Array) ## The first param is ALWAYS the custom signal's name

func sound_play(stream: AudioStream, where: Vector3, _volume: float = -3, _pitch = .78):
	var s = AudioStreamPlayer3D.new()
	add_child(s)
	s.global_position = where
	s.stream = stream
	s.volume_db = _volume
	s.pitch_scale = _pitch
	s.play()
	await s.finished
	s.queue_free()
