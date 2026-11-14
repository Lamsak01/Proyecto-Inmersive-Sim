extends RefCounted

## Banco de sonidos orgánicos sintetizados en memoria (PCM de 16 bits a 22.050 Hz) para el audio posicional 3D:
## agua corriendo del río y del lago, lluvia exterior, pasos por material, puertas de madera y voces de vecinos.

const FREC_MUESTREO: int = 22050

var _cache: Dictionary = {}


func obtener(clave: String) -> AudioStreamWAV:
	if _cache.has(clave):
		return _cache[clave] as AudioStreamWAV
	var wav: AudioStreamWAV = _generar(clave)
	_cache[clave] = wav
	return wav


func _generar(clave: String) -> AudioStreamWAV:
	if clave == "agua_rio":
		return _crear_bucle_agua(2.6, 0.22, 41)
	if clave == "lluvia_ambiente":
		return _crear_bucle_lluvia(2.2, 0.16, 97)
	if clave == "puerta_abrir":
		return _crear_puerta(true)
	if clave == "puerta_cerrar":
		return _crear_puerta(false)
	if clave.begins_with("paso_"):
		return _crear_paso(clave.trim_prefix("paso_"))
	if clave.begins_with("voz_"):
		return _crear_voz(int(clave.trim_prefix("voz_")))
	if clave == "disparo_seco":
		return _crear_impulso(0.24, 0.55, 0.12)
	return _crear_impulso(0.14, 0.36, 0.22)


func _empaquetar(muestras: PackedFloat32Array, en_bucle: bool) -> AudioStreamWAV:
	var n: int = muestras.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i: int in range(n):
		var v: int = clampi(int(round(muestras[i] * 32767.0)), -32768, 32767)
		if v < 0:
			v += 65536
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = FREC_MUESTREO
	wav.stereo = false
	wav.data = bytes
	if en_bucle:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = n
	return wav


func _crear_bucle_agua(segundos: float, amplitud: float, semilla: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var total: int = int(segundos * float(FREC_MUESTREO))
	var margen: int = int(0.25 * float(FREC_MUESTREO))
	var crudo := PackedFloat32Array()
	crudo.resize(total + margen)
	var bajo: float = 0.0
	var medio: float = 0.0
	for i: int in range(total + margen):
		var t: float = float(i) / float(FREC_MUESTREO)
		var blanco: float = rng.randf_range(-1.0, 1.0)
		bajo = bajo * 0.965 + blanco * 0.035
		medio = medio * 0.84 + (blanco - bajo) * 0.16
		var murmullo: float = 0.72 + 0.28 * sin(t * TAU * 1.54) * cos(t * TAU * 0.77)
		var burbuja: float = sin(t * TAU * (290.0 + 70.0 * sin(t * 4.2))) * maxf(0.0, sin(t * 17.0) - 0.88) * 0.45
		crudo[i] = (bajo * 1.35 + medio * 0.55 + burbuja) * murmullo * amplitud
	var final_m := PackedFloat32Array()
	final_m.resize(total)
	for i: int in range(total):
		if i < margen:
			var a: float = float(i) / float(margen)
			final_m[i] = lerpf(crudo[total + i], crudo[i], a)
		else:
			final_m[i] = crudo[i]
	return _empaquetar(final_m, true)


func _crear_bucle_lluvia(segundos: float, amplitud: float, semilla: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var total: int = int(segundos * float(FREC_MUESTREO))
	var margen: int = int(0.20 * float(FREC_MUESTREO))
	var crudo := PackedFloat32Array()
	crudo.resize(total + margen)
	var suave: float = 0.0
	for i: int in range(total + margen):
		var blanco: float = rng.randf_range(-1.0, 1.0)
		suave = suave * 0.78 + blanco * 0.22
		var gotita: float = blanco * 0.35 if rng.randf() < 0.004 else 0.0
		crudo[i] = (suave * 0.75 + gotita) * amplitud
	var final_m := PackedFloat32Array()
	final_m.resize(total)
	for i: int in range(total):
		final_m[i] = lerpf(crudo[total + i], crudo[i], float(i) / float(margen)) if i < margen else crudo[i]
	return _empaquetar(final_m, true)


func _crear_paso(superficie: String) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(superficie)
	var dur: float = 0.14 if superficie == "agua" else 0.10
	var total: int = int(dur * float(FREC_MUESTREO))
	var m := PackedFloat32Array()
	m.resize(total)
	var filtro: float = 0.0
	var frec_golpe: float = 95.0 if superficie == "madera" else (145.0 if superficie == "piedra" else 78.0)
	var corte: float = 0.52 if superficie == "piedra" else (0.72 if superficie == "agua" else 0.84)
	for i: int in range(total):
		var t: float = float(i) / float(FREC_MUESTREO)
		var env: float = exp(-t * (22.0 if superficie == "agua" else 34.0))
		filtro = filtro * corte + rng.randf_range(-1.0, 1.0) * (1.0 - corte)
		var cuerpo: float = sin(t * TAU * frec_golpe * exp(-t * 8.0)) * exp(-t * 42.0)
		m[i] = (filtro * 0.55 + cuerpo * 0.65) * env * 0.42
	return _empaquetar(m, false)


func _crear_puerta(abriendo: bool) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 311 if abriendo else 617
	var dur: float = 0.26 if abriendo else 0.21
	var total: int = int(dur * float(FREC_MUESTREO))
	var m := PackedFloat32Array()
	m.resize(total)
	for i: int in range(total):
		var t: float = float(i) / float(FREC_MUESTREO)
		var pestillo: float = sin(t * TAU * 420.0) * exp(-t * 75.0) * 0.32
		var chirrido: float = 0.0
		if abriendo and t > 0.03:
			var tc: float = t - 0.03
			chirrido = sin(tc * TAU * (168.0 + 38.0 * sin(tc * 24.0))) * exp(-tc * 9.5) * 0.24
		var golpe_madera: float = 0.0
		if not abriendo and t > 0.05:
			var tg: float = t - 0.05
			golpe_madera = (sin(tg * TAU * 86.0) + rng.randf_range(-0.3, 0.3)) * exp(-tg * 28.0) * 0.42
		m[i] = pestillo + chirrido + golpe_madera
	return _empaquetar(m, false)


func _crear_voz(variante: int) -> AudioStreamWAV:
	var bases: Array[float] = [118.0, 142.0, 174.0, 198.0]
	var f0: float = bases[posmod(variante, bases.size())]
	var dur: float = 0.15
	var total: int = int(dur * float(FREC_MUESTREO))
	var m := PackedFloat32Array()
	m.resize(total)
	for i: int in range(total):
		var t: float = float(i) / float(FREC_MUESTREO)
		var ventana: float = sin(clampf(t / dur, 0.0, 1.0) * PI)
		var f: float = f0 * (1.0 + 0.05 * sin(t * 28.0))
		var onda: float = sin(t * TAU * f) * 0.55 + sin(t * TAU * f * 2.0) * 0.28 + sin(t * TAU * f * 3.0) * 0.12
		m[i] = onda * ventana * 0.24
	return _empaquetar(m, false)


func _crear_impulso(dur: float, amp: float, suavizado: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(dur * 1000.0)
	var total: int = int(dur * float(FREC_MUESTREO))
	var m := PackedFloat32Array()
	m.resize(total)
	var f: float = 0.0
	for i: int in range(total):
		var t: float = float(i) / float(FREC_MUESTREO)
		f = f * (1.0 - suavizado) + rng.randf_range(-1.0, 1.0) * suavizado
		m[i] = (f * 0.7 + sin(t * TAU * 92.0) * 0.3) * exp(-t * 18.0) * amp
	return _empaquetar(m, false)
