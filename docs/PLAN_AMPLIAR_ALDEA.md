# Plan para ampliar la aldea (propuesta, 2026-11-06)

> **Estado (2026-11-06):** pasos 1, 2 y 3 HECHOS (ver `docs/HANDOFF.md` §7). Pendiente: paso 4.
> Cambios respecto a la propuesta: el terreno de los solares no cambia (solo la casa de dentro); Molino del Este con
> 2 casas y molino de adorno (no es un oficio nuevo).

> Propuesta de Claude Code. **No está hecho:** cambia dónde están las casas y los caminos. Eso toca la navegación de los
> vecinos, los solares en construcción y varias pruebas, así que espera el visto bueno del usuario.
> Capturas de cómo está hoy: `docs/capturas/noche2_valle_despues.jpg`.

## Qué pasa hoy
- Casi todas las casas nuevas son **solares iguales de 130 × 96 px**, puestos en filas rectas a 140 px unos de otros
  (filas n, m, u y e). Desde arriba parece una cuadrícula de clones.
- El centro (plaza, tiendas, hospital, comisaría) está apretado. El sur y el oeste del valle están casi vacíos: solo
  hay hierba entre el lago, la granja y el bosque.

## Lo que ya hice esta noche (solo aspecto, sin mover nada)
Cada edificio 3D varía ya según su nombre:
- altura del muro;
- orientación y altura del tejado;
- ala más baja en los edificios anchos, que les da silueta de «L»;
- porche sobre la puerta;
- chimenea;
- campanario en la iglesia.

Las casas ya no son idénticas, pero siguen ocupando el mismo hueco del mapa.

## Propuesta en 4 pasos (de menos a más trabajo)

### 1. Tamaños distintos de solar (coste: poco-medio)
Tres tamaños en vez de uno:
- **casita:** 100 × 76;
- **casa:** 130 × 96, como ahora;
- **casona:** 170 × 112.

Cada solar nuevo se asigna por sorteo con semilla fija, para que no cambie entre partidas. Las casas de los pobres
salen más pequeñas y las de los ricos más grandes; encaja con las clases sociales.
- *Lo notarías:* casas de tamaños distintos en la misma calle.
- *Si no se hace:* la cuadrícula de clones sigue ahí.

### 2. Romper las filas (coste: medio)
- Desplazar cada solar unos ±20 px hacia delante o atrás, y dejar uno o dos huecos por fila con un huerto, un corral o
  un pozo.
- Las calles traseras (filas m y u) pasan a ser caminos con curva suave.
- *Lo notarías:* calles que parecen de pueblo de verdad, no de cuadrícula.
- *Riesgo:* hay que regenerar la navegación de esas calles y repasar las pruebas de solares.

### 3. Barrios nuevos más separados (coste: medio)
- **Barrio del Lago:** 4–5 casitas dispersas en la orilla sur del lago ampliado, con su embarcadero. Hay hueco entre
  el lago y la Granja del Sur.
- **Caseríos del bosque:** 2–3 casas aisladas en el linde del bosque, con leñero. Sitio para leñadores y gente
  huraña (encaja con los rasgos de los vecinos).
- **Molino del este:** junto al Puesto del Paso, un molino y dos casas de molineros.
- *Lo notarías:* que el valle se ve habitado y no todo amontonado en el centro.

### 4. Casas con forma de L o con patio (coste: mucho)
Casas cuya planta sean dos rectángulos (cuerpo y ala), con muros y colisiones reales en forma de L. Pide cambiar cómo se
guardan las huellas de los edificios. Mi recomendación es **más adelante**: el paso 1 y la variación 3D ya dan mucha
diferencia por menos coste.

## Mi recomendación
Hacer los pasos **1 y 3 juntos** en un bloque (coste medio). Son los que más cambian la sensación de pueblo y menos
riesgo tienen, porque los barrios nuevos van en zonas vacías. El paso 2 después, y el 4 solo si sigue haciendo falta.
