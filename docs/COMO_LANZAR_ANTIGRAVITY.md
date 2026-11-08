# Cómo lanzar a Antigravity (cualquier ordenador)

## Preparar el ordenador (una vez)
1. Descargar el juego de GitHub (o `git pull` si ya está) en una carpeta, p. ej. `~/Videojuego`.
2. Godot 4.7.2 por Flatpak: `flatpak install flathub org.godotengine.Godot`.
3. Antigravity instalado y con la sesión iniciada. Saber dónde está su programa `agy`
   (en el ordenador principal: `~/AntigravityTerminal/agy`).
4. Quitar la suspensión del ordenador si va a trabajar solo mucho rato.

## ⭐ Trabajo de todo el día sin vigilarlo (lo recomendado)
En una terminal, desde la carpeta del juego (cambia la ruta de `agy` si en ese ordenador es otra):

```
git pull && rm -f docs/DIA_TERMINADO.txt && MODO=dia AGY=~/AntigravityTerminal/agy nohup bash tools/vigilante_noche.sh >/dev/null 2>&1 &
```

Lanza a Antigravity en seguida, sin pedir permisos, y si se para más de 20 min lo vuelve a lanzar (hasta 10 veces).
Se para solo al acabar el encargo de hoy y el troceo (`docs/DIA_TERMINADO.txt`). Pararlo a mano: `touch ~/PARAR_VIGILANTE`.
Ver qué hace: `tail ~/vigilante_noche.log` y `git log --oneline -5`.

## Lanzar el encargo de hoy una sola vez, sin que pida permisos
Desde la carpeta del juego (cambia la ruta de `agy` si en ese ordenador es otra):

```
git pull && ~/AntigravityTerminal/agy -p "Lee docs/GUIA_CORTA_ANTIGRAVITY.md y haz el ENCARGO DE HOY del principio de docs/ENCARGO_SIGUIENTE.md, sin parar ni preguntar. Commit y push tras cada punto." --dangerously-skip-permissions --model gemini-4-argon-medium
```

Mientras trabaja: no juegues ni toques los archivos del juego en ese ordenador.

## Para la noche (modo noche) (se relanza solo si se para)
```
rm -f docs/NOCHE_TERMINADA.txt; AGY=~/AntigravityTerminal/agy nohup bash tools/vigilante_noche.sh >/dev/null 2>&1 &
```
Pararlo: `touch ~/PARAR_VIGILANTE`. Registro: `~/vigilante_noche.log`.

## Antes de volver al otro ordenador
Comprueba que Antigravity terminó y subió todo (`git status` limpio y `git push` hecho). En el otro: `git pull`.
