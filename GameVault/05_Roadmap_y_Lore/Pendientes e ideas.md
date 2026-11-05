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
- [ ] **Uso del Arcabuz de Chispa en combate directo (`PO.1`):** Actualmente suma `+2` a la defensa del pueblo en incursiones; falta permitir equiparlo en la rueda/manos para disparar proyectiles reales con recarga lenta, humo y estampido de ruido alto en el mapa.
- [ ] **Lugar físico en el mapa para el «Puesto del Paso» (`PP.1`):** Actualmente el asentamiento fronterizo (empalizada, atalaya, posta) se gestiona por menú; falta construir su recinto caminable en el extremo este/norte del mapa.
- [ ] **Amputaciones y prótesis aplicadas al propio jugador (`PI`):** Hoy operan sobre los vecinos heridos en el hospital; falta que el jugador también pueda perder un miembro por gangrena sin tratar y equiparse prótesis mecánicas visibles en su sprite/ficha.
- [ ] **Escaleras y sótanos caminables con geometría visual (`PN`):** Hoy las capas `-1 / 0 / +1` y las alcantarillas tienen lógica de altura, anclaje y visibilidad; falta dibujar los interiores de sótanos y altillos con sus propios muebles y escaleras en el *tilemap*.

#### B. Ampliación de [[La Secta]] (Reservada al Usuario — `scripts/systems/VillageSect.gd`)
- [ ] **Jerarquía interna de la secta:** Rangos de iniciado, acólito y círculo interior, con misiones propias si el jugador decide infiltrarse o liderarla.
- [ ] **Infiltración en las instituciones:** Qué ocurre cuando la mayoría de los votantes, el comisario o el alcalde pertenecen en secreto a la secta.
- [ ] **Choque abierto entre la Capilla del Alba y la Secta:** Cisma religioso, inquisición eclesiástica o conversión del propio sacerdote si cae en crisis de fe profunda.

#### C. Ideas de pulido y despertar de tendencias dormidas (`TraitCatalog.gd`)
- [ ] **Conectar las tendencias marcadas como «dormidas» en `TraitCatalog.gd`:** Varias tendencias (`courage`, `night`, `wit`, `nerve`, `spending`, `innovation`, `wander`, `rivalry`, `animals`) ya se usan en bloques recientes (`PF`–`PR`), pero conviene limpiar la etiqueta `(dormida)` de sus descripciones y ampliar su peso en las rutinas horarias (por ejemplo, que los *Noctámbulos* e *Insomnes* tengan paseos nocturnos visibles por las calles).
- [ ] **Sonido, efectos visuales y señales en el mapa de lo que ocurre sin abrir menús:** Bocadillos cortos o iconos flotantes cuando un maestro termina una obra maestra, cuando los niños entran en fila a la escuela o cuando el ayuntamiento inaugura una mejora pagada con el superávit.
