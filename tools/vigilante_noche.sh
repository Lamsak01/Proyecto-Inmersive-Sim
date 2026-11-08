#!/usr/bin/env bash
# Vigilante nocturno de Antigravity (Claude Code, 2026-11-08).
# Cada 10 min mira si alguien trabaja en el juego. Si lleva 20 min parado y la lista
# de la noche no está acabada, lanza un Antigravity nuevo para que siga.
# Se para solo: al acabar la lista (docs/NOCHE_TERMINADA.txt), tras MAX_LANZAMIENTOS o a la HORA_FIN.
# Uso:   nohup bash tools/vigilante_noche.sh >/dev/null 2>&1 &
# Parar: touch ~/PARAR_VIGILANTE      Registro: ~/vigilante_noche.log

REPO="${REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
AGY="${AGY:-$(command -v agy || echo "$HOME/AntigravityTerminal/agy")}"
LOG="$HOME/vigilante_noche.log"
PARAR="$HOME/PARAR_VIGILANTE"
MODELO="gemini-4-argon-medium"
ESPERA=600            # segundos entre comprobaciones (10 min)
INACTIVO_MIN=20       # minutos sin tocar archivos = parado
DURACION_MAX="3h"     # tiempo máximo de cada lanzamiento
MAX_LANZAMIENTOS=6
HORA_FIN=9            # a partir de las 9:00 no lanza nada nuevo
DRYRUN="${DRYRUN:-0}" # DRYRUN=1: solo dice qué haría
ONCE="${ONCE:-0}"     # ONCE=1: una sola comprobación

ORDEN='Lee docs/GUIA_CORTA_ANTIGRAVITY.md, «Ahorro de tokens» en docs/DIRECTIVAS_ANTIGRAVITY.md y «MODO NOCHE» al principio de docs/ENCARGO_SIGUIENTE.md, y síguelo hasta acabar la lista sin parar ni preguntar. Mira antes git log, git status y docs/INFORME_ANTIGRAVITY.md: sigue desde el primer punto no hecho. Si hay cambios sin guardar en git, son trabajo a medias: revísalos y termínalos primero. Tras cada paso, mira «Notas del supervisor (noche)». Al acabar toda la lista, crea docs/NOCHE_TERMINADA.txt y haz commit y push.'

log() { echo "$(date '+%Y-%m-%d %H:%M') $*" >> "$LOG"; [ "$DRYRUN" = 1 ] && echo "$*"; }

lanzados=0
pid_mio=""
rm -f "$PARAR"
log "Vigilante arrancado (máx. $MAX_LANZAMIENTOS lanzamientos, hasta las $HORA_FIN:00)."

while true; do
  if [ -f "$PARAR" ]; then log "Parado a mano."; exit 0; fi
  if [ -f "$REPO/docs/NOCHE_TERMINADA.txt" ]; then log "Lista de la noche terminada. Fin."; exit 0; fi

  # ¿Sigue vivo el Antigravity que lancé yo?
  if [ -n "$pid_mio" ] && kill -0 "$pid_mio" 2>/dev/null; then
    log "Mi Antigravity ($pid_mio) sigue trabajando."
  else
    [ -n "$pid_mio" ] && log "Mi Antigravity ($pid_mio) ha terminado."
    pid_mio=""
    # ¿Alguien ha tocado archivos del juego hace poco? (sin .git, .godot ni .import)
    recientes=$(find "$REPO" \( -path "$REPO/.git" -o -path "$REPO/.godot" \) -prune -o \
      -type f -mmin -"$INACTIVO_MIN" ! -name '*.import' ! -name '*.uid' -print 2>/dev/null | head -1)
    # ¿Hay un Godot en marcha? (pruebas o capturas)
    # (no cuenta el editor de Godot del usuario, que puede estar abierto toda la noche)
    godot=$(ps -eo args= | grep 'godot-bin' | grep -v -- '--editor' | grep -v grep | head -1)
    hora=$(date +%-H)
    if [ -n "$recientes" ] || [ -n "$godot" ]; then
      log "Alguien está trabajando (${recientes:+archivo reciente}${godot:+ Godot en marcha}). Espero."
    elif [ "$hora" -ge "$HORA_FIN" ] && [ "$hora" -lt 20 ]; then
      log "Ya es de día ($hora h): no lanzo más. Fin."; exit 0
    elif [ "$lanzados" -ge "$MAX_LANZAMIENTOS" ]; then
      log "Llegado al máximo de $MAX_LANZAMIENTOS lanzamientos. Fin."; exit 0
    else
      lanzados=$((lanzados + 1))
      if [ "$DRYRUN" = 1 ]; then
        log "[prueba] Lanzaría Antigravity n.º $lanzados."
      else
        log "Todo parado $INACTIVO_MIN min: lanzo Antigravity n.º $lanzados."
        ( cd "$REPO" && timeout "$DURACION_MAX" "$AGY" -p "$ORDEN" \
            --dangerously-skip-permissions --model "$MODELO" \
            >> "$HOME/vigilante_agy_$lanzados.log" 2>&1 ) &
        pid_mio=$!
      fi
    fi
  fi
  [ "$ONCE" = 1 ] && exit 0
  sleep "$ESPERA"
done
