---
tipo: "roadmap"
estado: "pendiente"
tags:
  - "pendiente"
  - "idea"
fuente: "Biblia §15.2"
---
# Pendientes e ideas

Ver también el [[Tablero]].

#pendiente

#### A. Presencia Física y Combate en el Mundo (Prioridad Alta)
- [x] **Uso del Arcabuz de Chispa en combate directo (`PO.1`):** Actualmente suma `+2` a la defensa del pueblo en incursiones; falta permitir equiparlo en la rueda/manos para disparar proyectiles reales con recarga lenta, humo y estampido de ruido alto en el mapa.
- [x] **Lugar físico en el mapa para el «Puesto del Paso» (`PP.1`):** Recinto caminable en el extremo este del camino principal (`Vector2(1615, 50)`) con empalizada, aserradero, granero, atalaya, carta interactiva `[E]` y colonos que acuden a trabajar de `08:00` a `17:00` (en 2D y 3D).
- [x] **Amputaciones y prótesis aplicadas al propio jugador (`PI`):** Visible tanto en el cuerpo 3D articulado del jugador y de los vecinos como en el visor `[F8]`.
- [x] **Escaleras y sótanos caminables con geometría visual (`PN`):** Altillos `+1` con escalera y camas y cámaras subterráneas `-1` de las alcantarillas representados visualmente en el escenario 3D (`WorldStage3D.gd`).

#### B. Ampliación de [[La Secta]] (Reservada al Usuario — `scripts/systems/VillageSect.gd`)
- [ ] **Jerarquía interna de la secta:** Rangos de iniciado, acólito y círculo interior, con misiones propias si el jugador decide infiltrarse o liderarla.
- [ ] **Infiltración en las instituciones:** Qué ocurre cuando la mayoría de los votantes, el comisario o el alcalde pertenecen en secreto a la secta.
- [ ] **Choque abierto entre la Capilla del Alba y la Secta:** Cisma religioso, inquisición eclesiástica o conversión del propio sacerdote si cae en crisis de fe profunda.

#### C. Ideas de pulido y despertar de tendencias dormidas (`TraitCatalog.gd`)
- [ ] **Conectar las tendencias marcadas como «dormidas» en `TraitCatalog.gd`:** Varias tendencias (`courage`, `night`, `wit`, `nerve`, `spending`, `innovation`, `wander`, `rivalry`, `animals`) ya se usan en bloques recientes (`PF`–`PR`), pero conviene limpiar la etiqueta `(dormida)` de sus descripciones y ampliar su peso en las rutinas horarias (por ejemplo, que los *Noctámbulos* e *Insomnes* tengan paseos nocturnos visibles por las calles).
- [ ] **Sonido, efectos visuales y señales en el mapa de lo que ocurre sin abrir menús:** Bocadillos cortos o iconos flotantes cuando un maestro termina una obra maestra, cuando los niños entran en fila a la escuela o cuando el ayuntamiento inaugura una mejora pagada con el superávit.
