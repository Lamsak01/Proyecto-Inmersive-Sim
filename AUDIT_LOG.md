# Registro de Auditoría y Depuración con Rollback (`AUDIT_LOG.md`)

Este archivo registra únicamente **bugs reales de jugabilidad/lógica** detectados durante el bucle de auditoría, junto con el commit previo exacto para permitir un rollback inmediato (`git revert <commit>` o `git reset --hard <commit_previo>`).

---

## Iteración 1 — Commit Base para Rollback: `9c1952c`

### 1. Veredicto del Inquisidor Real sin Testigos y Clave de Coartada en Fallback
- **Archivo y líneas afectadas:** `scripts/systems/VillageManager.gd` (`líneas 5729-5755`)
- **Descripción del fallo real:**
  1. En `_conclude_royal_investigation_with_mandatory_verdict()`, la condición para descartar al jugador sin testigos era `sc <= 15 and kd < 0.0`. Como llevar equipada el arma inicial por defecto (Espada) sumaba `+16` (`score = 26`), si matabas al mercader lejos del pueblo (`> 360 px`) sin ningún testigo ni prueba, todos los aldeanos se descartaban por distancia y el Inquisidor condenaba mágicamente al jugador.
  2. En el bucle de respaldo (`línea 5745`) se consultaba `s_entry.get("alibi", "")` en lugar de la clave real `s_entry.get("mem_alibi_partner", "")`.
- **Solución aplicada:** Exigir `sc < 45 and kd < 0.0` para descartar al jugador cuando no hay testigos ni pruebas físicas/policiales, corregir la clave `"mem_alibi_partner"` en el bucle de respaldo y elegir al aldeano sin coartada más cercano antes de caer en `"Jugador"`.

### 2. Empuje Físico (`push_velocity`) Ignorado en Enemigos de la Llanura y Ranas
- **Archivo y líneas afectadas:** `scripts/enemies/DummyEnemy.gd` (`líneas 62-70, 124-126`)
- **Descripción del fallo real:** `DummyEnemy` define `push_velocity` y recibe `apply_push(force)` al ser golpeado (por ejemplo, con el Martillo), pero `_physics_process(delta)` nunca aplicaba ni desaceleraba `push_velocity`.
- **Solución aplicada:** Aplicar y desacelerar `push_velocity` al inicio de `DummyEnemy._physics_process(delta)` (igual que en `scenes/npc.gd`).

### 3. Pausa de Tiempo (`WorldClock.is_time_frozen()`) Ignorada por Sangrado, Stun, Agonía e IA Enemiga
- **Archivos y líneas afectadas:**
  - `scripts/systems/combat/HealthComponent.gd` (`líneas 30-34`)
  - `scripts/systems/combat/StunComponent.gd` (`líneas 17-19`)
  - `scripts/enemies/VillageNPC.gd` (`línea 704`)
  - `scripts/systems/ai/EnemyAI.gd` (`líneas 103-106`)
- **Descripción del fallo real:** Mientras el reloj del mundo está congelado por jugar Póker/Billar en la Taberna (`WorldClock.is_time_frozen()`), el sangrado activo (`HealthComponent._process`) seguía drenando vida (pudiendo matar al jugador en plena partida de cartas), el temporizador de agonía (`bleedout_timer`) y de aturdimiento (`StunComponent`) seguían corriendo, y `EnemyAI` seguía procesando movimiento/ataques.
- **Solución aplicada:** Pausar el tick en `HealthComponent._process`, `StunComponent._process`, `EnemyAI._physics_process` y el descuento de `bleedout_timer` en `VillageNPC._physics_process` cuando `WorldClock.is_time_frozen()` es `true`.
