---
tipo: "roadmap"
tags:
  - "recomendacion"
  - "diagnostico"
  - "organizacion"
fuente: "Biblia §16"
---
# Diagnóstico y recomendaciones

### 16.1 Diagnóstico de Salud Actual del Proyecto
> [!info] Estado Técnico y Sistémico (Commit `11b48b4`)
> - **Cobertura de Pruebas:** **95 bloques de prueba automatizados** (`verify_all.gd`), más `social_sim.gd`, `dialogue_coverage.gd`, `names_check.gd` y la sonda de 16–30 días (`feature_probe.gd`), pasando al **100% sin un solo error**.
> - **Rendimiento:** Escalado probado hasta **100 vecinos (`POP_CAP = 100`)** manteniendo `~5.7 ms/frame` gracias al escalonado de IA por distancia y por capa vertical.
> - **Economía y Simulación:** La sonda autónoma confirma que el pueblo ya **no se estanca**: los maestros venden sus obras maestras, el rancho renueva su ganado, los niños asisten a clase con el maestro y el ayuntamiento reinvierte el superávit de las arcas sin acumular miles de monedas muertas.

### 16.2 El Mayor Riesgo Actual (y Cómo Evitarlo)
El riesgo número uno de **[[La Placa de Petri]]** ya **no es la falta de sistemas** (tiene más sistemas interconectados que la mayoría de juegos comerciales del género), sino la **«invisibilidad por menú»**:
- Durante los bloques `PF–PQ` se crearon decenas de mecánicas que vivían dentro de submenús de diálogo (`[E]`). Si el jugador no abría la opción exacta con el vecino exacto, no sabía que el sistema existía.
- **Recomendación de oro para las siguientes fases:** **Congelar la adición de sistemas nuevos en menús** y dedicar el próximo ciclo exclusivamente a **presencia física, visual y espacial en el mundo** (que se vea la fila de niños yendo a la escuela, el puesto de obras maestras brillando los miércoles, los guardias marchando al camino del este a las 16:00 antes de una incursión, el humo del arcabuz y el recinto físico del «Puesto del Paso»).
