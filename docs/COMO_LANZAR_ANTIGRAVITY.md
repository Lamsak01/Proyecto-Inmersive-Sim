# Cómo lanzar a Antigravity (cualquier ordenador)

## Preparar el ordenador (una vez)
1. Descargar el juego de GitHub (o `git pull` si ya está) en una carpeta, p. ej. `~/Videojuego`.
2. Godot 4.7.2 por Flatpak: `flatpak install flathub org.godotengine.Godot`.
3. Antigravity instalado y con la sesión iniciada. Saber dónde está su programa `agy`
   (en el ordenador principal: `~/AntigravityTerminal/agy`).
4. Quitar la suspensión del ordenador si va a trabajar solo mucho rato.

## Lanzar el encargo de hoy, sin que pida permisos
Desde la carpeta del juego (cambia la ruta de `agy` si en ese ordenador es otra):

```
git pull && ~/AntigravityTerminal/agy -p "Lee docs/GUIA_CORTA_ANTIGRAVITY.md y haz el ENCARGO DE HOY del principio de docs/ENCARGO_SIGUIENTE.md, sin parar ni preguntar. Commit y push tras cada punto." --dangerously-skip-permissions --model gemini-4-argon-medium
```

Mientras trabaja: no juegues ni toques los archivos del juego en ese ordenador.

## Para la noche (se relanza solo si se para)
```
rm -f docs/NOCHE_TERMINADA.txt; AGY=~/AntigravityTerminal/agy nohup bash tools/vigilante_noche.sh >/dev/null 2>&1 &
```
Pararlo: `touch ~/PARAR_VIGILANTE`. Registro: `~/vigilante_noche.log`.

## Antes de volver al otro ordenador
Comprueba que Antigravity terminó y subió todo (`git status` limpio y `git push` hecho). En el otro: `git pull`.
