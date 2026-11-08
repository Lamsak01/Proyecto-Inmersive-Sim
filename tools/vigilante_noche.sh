#!/usr/bin/env bash
# Vigilante nocturno de Antigravity (Claude Code, 2026-11-08).
# Cada 10 min mira si alguien trabaja en el juego. Si su Antigravity sigue abierto pero lleva ATASCADO_MIN sin tocar nada, lo reinicia. Si lleva 20 min parado y la lista
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
ATASCADO_MIN="${ATASCADO_MIN:-25}" # mi Antigravity sigue abierto pero sin tocar nada este tiempo = atascado: lo reinicio
DURACION_MAX="3h"     # tiempo máximo de cada lanzamiento
MODO="${MODO:-noche}" # MODO=dia: trabaja de día, sin hora de fin, y arranca en seguida
MAX_LANZAMIENTOS="${MAX_LANZAMIENTOS:-6}"
HORA_FIN=9            # (solo de noche) a partir de las 9:00 no lanza nada nuevo
FIN="$REPO/docs/NOCHE_TERMINADA.txt"
[ "$MODO" = dia ] && FIN="$REPO/docs/DIA_TERMINADO.txt" && MAX_LANZAMIENTOS="${MAX_LANZAMIENTOS_DIA:-10}"
DRYRUN="${DRYRUN:-0}" # DRYRUN=1: solo dice qué haría
ONCE="${ONCE:-0}"     # ONCE=1: una sola comprobación

ORDEN='Lee docs/GUIA_CORTA_ANTIGRAVITY.md, «Ahorro de tokens» en docs/DIRECTIVAS_ANTIGRAVITY.md y «MODO NOCHE» al principio de docs/ENCARGO_SIGUIENTE.md, y síguelo hasta acabar la lista sin parar ni preguntar. Mira antes git log -15 --oneline, git status y SOLO el resumen del principio de docs/INFORME_ANTIGRAVITY.md (head -40; no leas el informe entero): sigue desde el primer punto no hecho. Si hay cambios sin guardar en git, son trabajo a medias: revísalos y termínalos primero. Tras cada paso, mira «Notas del supervisor (noche)». Al acabar toda la lista, crea docs/NOCHE_TERMINADA.txt y haz commit y push.'
[ "$MODO" = dia ] && ORDEN='Lee docs/GUIA_CORTA_ANTIGRAVITY.md y «Ahorro de tokens» en docs/DIRECTIVAS_ANTIGRAVITY.md. Haz, sin parar ni preguntar, el «ENCARGO DE HOY» del principio de docs/ENCARGO_SIGUIENTE.md y después «TROCEO DE ARCHIVOS GRANDES» (justo debajo). Dudas de diseño a docs/PREGUNTAS_PENDIENTES.md y sigue. Para saber por dónde vas, mira git log -15 --oneline, git status y SOLO el resumen del principio de docs/INFORME_ANTIGRAVITY.md (head -40; no leas el informe entero, es muy largo, y de ENCARGO_SIGUIENTE.md lee solo las dos secciones nombradas): sigue desde el primer punto no hecho; si hay cambios sin guardar, son trabajo a medias: termínalos primero. Commit y push tras cada punto. Tras cada punto, mira «Notas del supervisor». Al acabar las dos listas, crea docs/DIA_TERMINADO.txt y haz commit y push.'

log() { echo "$(date '+%Y-%m-%d %H:%M') $*" >> "$LOG"; [ "$DRYRUN" = 1 ] && echo "$*"; }

lanzados=0
primera=1
pid_mio=""
relanzar_ya=0
rm -f "$PARAR"
log "Vigilante arrancado en modo $MODO (máx. $MAX_LANZAMIENTOS lanzamientos, hasta las $HORA_FIN:00)."
# Si ya hay un Antigravity trabajando (p. ej. al reiniciar el vigilante), lo adopto en vez de lanzar otro.
adoptado=$(pgrep -f -- "$AGY -p" | head -1)
if [ -n "$adoptado" ]; then pid_mio="$adoptado"; primera=0; log "Adopto el Antigravity que ya trabajaba ($pid_mio)."; fi

# ¿Hay señales de trabajo real en los últimos N minutos? (archivos del juego, un Godot de pruebas o el registro de Antigravity)
hay_actividad() {
  local min="$1"
  [ -n "$(find "$REPO" \( -path "$REPO/.git" -o -path "$REPO/.godot" \) -prune -o \
      -type f -mmin -"$min" ! -name '*.import' ! -name '*.uid' -print 2>/dev/null | head -1)" ] && return 0
  [ -n "$(ps -eo args= | grep 'godot-bin' | grep -v -- '--editor' | grep -v grep | head -1)" ] && return 0
  [ -n "$(find "$HOME" -maxdepth 1 -name 'vigilante_agy_*.log' -mmin -"$min" 2>/dev/null | head -1)" ] && return 0
  return 1
}

while true; do
  if [ -f "$PARAR" ]; then log "Parado a mano."; exit 0; fi
  if [ -f "$FIN" ]; then log "Lista terminada ($FIN). Fin."; exit 0; fi

  # ¿Sigue vivo el Antigravity que lancé yo?
  if [ -n "$pid_mio" ] && kill -0 "$pid_mio" 2>/dev/null; then
    if hay_actividad "$ATASCADO_MIN"; then
      log "Mi Antigravity ($pid_mio) sigue trabajando."
    else
      log "Mi Antigravity ($pid_mio) lleva $ATASCADO_MIN min sin tocar nada: parece atascado. Lo reinicio."
      if [ "$DRYRUN" != 1 ]; then
        pkill -TERM -P "$pid_mio" 2>/dev/null; kill "$pid_mio" 2>/dev/null
        pkill -TERM -f -- "$AGY -p" 2>/dev/null
      fi
      pid_mio=""; relanzar_ya=1
    fi
  fi
  if [ -z "$pid_mio" ] || ! kill -0 "$pid_mio" 2>/dev/null; then
    [ -n "$pid_mio" ] && log "Mi Antigravity ($pid_mio) ha terminado."
    pid_mio=""
    # ¿Alguien ha tocado archivos del juego hace poco? (sin .git, .godot ni .import)
    recientes=$(find "$REPO" \( -path "$REPO/.git" -o -path "$REPO/.godot" \) -prune -o \
      -type f -mmin -"$INACTIVO_MIN" ! -name '*.import' ! -name '*.uid' -print 2>/dev/null | head -1)
    # ¿Hay un Godot en marcha? (pruebas o capturas)
    # (no cuenta el editor de Godot del usuario, que puede estar abierto toda la noche)
    godot=$(ps -eo args= | grep 'godot-bin' | grep -v -- '--editor' | grep -v grep | head -1)
    hora=$(date +%-H)
    if [ "$MODO" = dia ] && [ "$primera" = 1 ] && [ -z "$godot" ]; then recientes=""; fi
    if [ "$relanzar_ya" = 1 ] && [ -z "$godot" ]; then recientes=""; fi
    primera=0; relanzar_ya=0
    if [ -n "$recientes" ] || [ -n "$godot" ]; then
      log "Alguien está trabajando (${recientes:+archivo reciente}${godot:+ Godot en marcha}). Espero."
    elif [ "$MODO" != dia ] && [ "$hora" -ge "$HORA_FIN" ] && [ "$hora" -lt 20 ]; then
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
