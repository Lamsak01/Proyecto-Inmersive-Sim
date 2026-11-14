#!/usr/bin/env bash
# Contador de restos 2D del juego (objetivo del usuario, 2026-11-14: TODO en 3D, CERO 2D en el mundo y su lógica).
# Solo lee. Uso: bash tools/contar_2d.sh   → una línea por familia y el TOTAL. El total tiene que bajar hasta 0.
# No cuenta la interfaz (menús, HUD, paneles: nodos Control), que es plana en cualquier juego 3D.
cd "$(dirname "$0")/.." || exit 1
DIRS="scripts scenes mapa"
total=0
contar() { # nombre · patrón · tipos de archivo
	local n
	n=$(grep -rhoE "$2" $DIRS $3 2>/dev/null | wc -l)
	printf "%-52s %6d\n" "$1" "$n"
	total=$((total + n))
}
GD="--include=*.gd"
TSCN="--include=*.tscn"
echo "== Nodos y física 2D en el código"
contar "Cuerpos, áreas y choques 2D" '\b(CharacterBody2D|StaticBody2D|RigidBody2D|Area2D|CollisionShape2D|CollisionPolygon2D)\b' "$GD"
contar "Dibujos 2D del mundo (Sprite2D, polígonos, baldosas)" '\b(Sprite2D|AnimatedSprite2D|Polygon2D|Line2D|TileMapLayer|TileMap)\b' "$GD"
contar "Cámara, luz y partículas 2D" '\b(Camera2D|CanvasModulate|PointLight2D|LightOccluder2D|GPUParticles2D|CPUParticles2D)\b' "$GD"
contar "Navegación y consultas de física 2D" '\b(NavigationRegion2D|NavigationAgent2D|NavigationPolygon|PhysicsRayQueryParameters2D|PhysicsShapeQueryParameters2D|PhysicsPointQueryParameters2D|PhysicsDirectSpaceState2D)\b' "$GD"
contar "Sonido 2D" '\bAudioStreamPlayer2D\b' "$GD"
contar "Scripts que son nodos 2D (extends …2D)" '^extends (Node2D|CharacterBody2D|Area2D|StaticBody2D|Sprite2D)' "$GD"
contar "Menciones de Node2D" '\bNode2D\b' "$GD"
echo "== Nodos 2D en las escenas"
contar "Nodos 2D en .tscn" 'type="[A-Za-z]*2D"|type="TileMapLayer"|type="CanvasModulate"' "$TSCN"
echo "== Lógica en píxeles y pisos de mentira"
contar "Nombres en píxeles (_px)" '[a-zA-Z0-9]_px\b' "$GD"
contar "Conversiones mapa ↔ 3D (Mapa3D.)" '\bMapa3D\.' "$GD"
contar "Pisos como número (elevation_level)" 'elevation_level' "$GD"
contar "Estirón ×5 y mapa viejo" 'Zona\.(des)?estirar|ESCALA_ANTIGUA|MapaViejo|mapa original|pos_original' "$GD"
contar "Distancias planas (distance_to en el plano)" 'distance(_squared)?_to\(' "$GD"
contar "Ratón sobre el mapa 2D" 'get_global_mouse_position|\bmouse_pos\b' "$GD"
echo "----------------------------------------------------------------"
printf "%-52s %6d\n" "TOTAL RESTOS 2D" "$total"
