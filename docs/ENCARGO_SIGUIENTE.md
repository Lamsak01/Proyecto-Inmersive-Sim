# ⭐ ENCARGO DE HOY — Piezas que faltan para cerrar el Caso I (sin la acusación)
Modo demo activo. No muevas edificios ni crees sistemas nuevos: **conecta lo que ya existe**. Resultado de la partida
de prueba en `docs/PLAN_PARTIDA_CASO1.md` (los ❌). Trama en `docs/PLAN_BETA_MISTERIO.md` §5 (lee solo los párrafos
«El libro y la sala oculta», «Los secuestradores» y lo que cite cada punto).

**Trabaja por trozos pequeños:** guarda en disco al menos cada 10 min y commit y push por punto (si pasas >25 min sin
guardar nada, te reinician). Apunta cada ✅/❌ nuevo en `PLAN_PARTIDA_CASO1.md`.

1. **Diálogos del caso conectados** (`DetectiveCaseData.custom_dialogues` → `NPCDialogue.gd`): el **boticario** analiza
   el frasco del estómago (`alchemist_analyze_flask`) y la **criada** de la mansión reconoce el frasco
   (`noble_maid_recognize_vial`). Solo aparecen cuando el jugador ya tiene la pista previa que les toca; se anotan en el
   cuaderno del caso. No reescribas los textos: usa los que ya hay.
2. **Gabinete forzado en la Mansión del Señor del Valle:** mueble examinable con [E], con la **cerradura forzada** (marcas
   visibles) y texto que describa lo que se ve, sin conclusiones. Se anota en el cuaderno.
3. **Roles del caso en el mundo** (`assign_case_roles()` llamado al empezar el Caso I, y que sobreviva a guardar/cargar):
   - **Casa de la víctima** y **casa del familiar** asignadas a casas que ya existan. En casa del familiar, la **página
     arrancada** del libro, examinable, con **dosis tachadas y corregidas** a mano.
   - **Los tres secuestradores** escondidos en el **molino** (el joven de capa parda, el del carro y el vecino de doble
     vida, que de día vive en el pueblo con su **prenda azul rota** o **arañazos en el brazo** visibles al examinarle).
     Usa los NPC/enemigos que ya existen; se puede pelear con ellos o escabullirse. **No** hagas captura sin matar ni
     interrogatorio nuevo: si ya existe algo, conéctalo; si no, apúntalo como ❌.
   - Si el jugador tarda demasiado (unos días), los dos forasteros **se van del molino** (si ya hay un reloj de días).

Al final, amplía `tools/tests/partida_caso1.gd` con lo nuevo y pásala (`RECORRIDO PASSED`). Capturas en 1.ª persona en
`docs/capturas_arreglos/caso1/partida/` (sufijo `_v2`). Informe arriba de `docs/INFORME_ANTIGRAVITY.md`, máx. 12
líneas, y `DIA_TERMINADO.txt`. Godot siempre en primer plano con `timeout`. **La acusación NO**: espera al autor.

## Notas del supervisor
