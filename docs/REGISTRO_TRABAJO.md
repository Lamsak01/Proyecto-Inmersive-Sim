# Registro de trabajo autónomo

El usuario dio vía libre el 2026-11-03 («implementa todo lo del plan sin parar mientras duermo; pruebas solo al final
de un bloque grande; lleva un registro por si algo falla»). Aquí se apunta cada paso en orden, con su estado, los
archivos tocados y lo que queda sin probar. Si algo falla, este es el sitio para ver qué cambió y cuándo.

Leyenda: ✅ probado y subido · 🟡 escrito, sin probar · 🔴 falló (ver nota) · ⏳ en marcha

## Bloque A — Cerrar «crecer el pueblo» (V3, V6, V9, V7, solares, UI1)

| # | Paso | Estado | Archivos | Nota |
|---|------|--------|----------|------|
| A1 | V3 llegadas y marchas | ✅ | VillageMigration.gd | Subido en 9914a3c |
| A2 | V6 nobles | ✅ | VillageNobility.gd, VillageTown.gd, VillageNPC.gd | Fallo de carga (PersonProfile) corregido; el juego ya carga |
| A3 | Solares fila m (m1–m5) y calleja | ✅ | VillageLots.gd | |
| A4 | V9 hijos, escuela y maestro | ✅ | VillageFamily.gd + filtros de edad | |
| A5 | V7 sonda de crecimiento | ✅ | tools/tests/growth_probe.gd | |
| A6 | UI1 diálogo ordenado | ✅ | NPCDialogue.gd | |
| A7 | Pruebas del bloque (4 suites) | ✅ | verify_all.gd | Fallo en el test del señor (dependía del oro tras impuestos), corregido |
| A8 | Sonda de crecimiento (30 días) | ⏳ | growth_probe.gd | En segundo plano |
