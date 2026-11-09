# ⭐ ENCARGO DE HOY — ¿Se puede jugar el Caso I de principio a fin?
Modo demo activo. No muevas edificios ni crees sistemas. Trama en `docs/PLAN_BETA_MISTERIO.md` §5 (solo lo necesario).

**ORDEN (10:55):** haz **primero el punto 2** (corto) y su commit. Luego, para el punto 1, **antes de estudiar el
código** crea `docs/PLAN_PARTIDA_CASO1.md` con tu plan en 5–10 líneas y haz commit; después ve apuntando ahí cada pista
comprobada (✅/❌) **según avanzas**, con commit cada 2–3 pistas. Si pasas 20 min sin escribir nada, te reinician.

1. **Partida completa del Caso I, como un jugador** (prueba automática nueva o ampliación de `recorrido_fijo.gd`):
   empezar en las afueras con la carta → ir al claro → examinar el cuerpo y las pistas del claro → molino (dentro,
   sótano y reja, barro rojo) → puente viejo (zapato) → comisaría (denuncia archivada) → biblioteca (libro-palanca,
   sala oculta, cuaderno de firmas, libro con página arrancada) → resto de pistas del caso → **acusar** con el sistema
   que ya exista. Comprueba en cada paso: que la pista **se alcanza a pie** (sin atravesar paredes ni teletransportar),
   que **[E] funciona**, que **se anota en el cuaderno del caso**, y que al final la acusación se puede hacer y da su
   resultado. Si algo falla y el arreglo es pequeño, arréglalo; si es grande, **apúntalo** en el informe sin arreglarlo.
   Lista final en el informe: cada pista con ✅/❌ y el motivo.
2. **Sala oculta de la biblioteca, más oscura** (`docs/capturas_arreglos/caso1/05b_biblioteca_sala_oculta_v2.png`):
   aún está demasiado iluminada. Que la única luz sea la vela (cálida, corta), rincones casi negros; que se siga
   pudiendo leer el recuadro y ver los objetos examinables. Captura `_v3`.

Capturas en 1.ª persona de los pasos que fallen (y de la acusación final) en `docs/capturas_arreglos/caso1/partida/`.
Commit y push por punto. Al final, `RECORRIDO PASSED`. Informe arriba de `docs/INFORME_ANTIGRAVITY.md`, máx. 15 líneas,
y `DIA_TERMINADO.txt`. Godot siempre en primer plano con `timeout`.

## Notas del supervisor
