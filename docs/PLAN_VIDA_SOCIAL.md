# Plan v3: Vida social procedural de los aldeanos

> Cambios respecto a la v2: el sistema **no depende de los 17 vecinos actuales**. Todo funciona igual con vecinos que lleguen más tarde. Parejas sin plazos, peleas discretas. Sigue sin haber código.

## 1. Mi opinión sobre lo que decidiste

| Tu decisión | Mi opinión |
|---|---|
| **Todo procedural, que valga para NPC nuevos** | Totalmente de acuerdo y es lo correcto. Cambia el diseño: los datos de cada vecino (género, edad, personalidad, gustos) se **generan** y el lore fijo pasa a ser solo un "extra" opcional. |
| **Lore provisional, puedo ajustarlo** | Perfecto: asignaré género y edad según cada historia y retocaré el lore donde haga falta, sin pedirte permiso por cada cambio. |
| **Parejas naturales, sin fechas límite** | Sí. Lo planteo como **probabilidad, no como plazo**: los "6–10 días" pasan a ser solo una duración *típica*, no una norma. Nadie "busca pareja"; solo se enamoran quienes ya pasan tiempo juntos. Puede que en una partida no surja ninguna, y está bien. |
| **Empiezan solteros, quizá 1–2 parejas** | Bien. Esas 1–2 parejas iniciales serán "semillas" de ejemplo (por ejemplo Elena y el Dr. Valen). |
| **Peleas discretas** | De acuerdo: dos vecinos se paran uno frente al otro, un movimiento sutil y algún "💢" ocasional. Los dados se tiran **por dentro** y solo ves el desenlace. |

## 2. Lo que encontré en el código y afecta al plan

1. **Los vecinos nuevos se crean en 5 sitios distintos** (reemplazo de autoridades, posadera nueva, artesano nuevo, viajeros, y al cargar partida). Cada uno les pone nombre y rol a su manera. No existe un paso común de "crear a una persona".
2. **Las listas de nombres son cortas y rotan** (5 nombres cada una). Pasado un tiempo **se repetirían**. Como las relaciones se guardan **por nombre**, dos "Caminante Elian" compartirían relaciones, y un recién llegado podría heredar las de un muerto con su mismo nombre. Esto hay que arreglarlo sí o sí.
3. **Los rasgos hoy son por oficio** (el herrero siempre "Perfeccionista"), no por persona. Para la compatibilidad necesitamos una **personalidad** propia de cada uno, distinta del oficio.
4. **Los nuevos usan un solo aspecto genérico** (`villager_traveler.png`). Un hombre y una mujer nuevos se verían igual. No es un problema para el sistema, pero conviene saberlo: si más adelante quieres variedad visual, habría que añadir imágenes.

## 3. Diseño procedural: la "ficha de persona"

Cada aldeano, fijo o nuevo, tiene una **ficha social** con los mismos campos. Los fijos la tienen escrita a mano; los nuevos se **generan** al crearlos. El resto del sistema solo lee la ficha, así que no sabe ni le importa quién sea.

| Campo | Para qué sirve |
|---|---|
| **Identificador único** | Evita el choque de nombres y herencia de relaciones de muertos |
| **Género** | Atracción (por ahora todos heterosexuales, pero el campo "orientación" queda previsto) |
| **Edad** (número y grupo: joven / adulto / mayor) | Compatibilidad y fuerza en peleas |
| **Personalidad** (3 rasgos propios: Leal, Alegre, Celoso, Cruel…) | Compatibilidad, conflictos, carácter en peleas |
| **Gustos** (comida favorita, aficiones, cosas que detesta) | Afinidad: "los dos aman el pescado" |
| **Estado sentimental** (soltero, en pareja con X, viudo/a) | Cortejo, celos, duelo |
| **Memoria social corta** (lo último que pasó con cada vecino) | Charlas con sentido, rencores |
| **Historia** (semilla de lore) | Texto de ambientación; en los nuevos, generado con plantillas |

**Reglas del generador de vecinos nuevos**
- **Nombre único garantizado** (nunca repetido ni de un fallecido).
- **Equilibrio de género:** el generador se inclina a corregir desequilibrios (si faltan mujeres, sale una con más probabilidad).
- **Edad según oficio** (guardias jóvenes, mayores más comunes en oficios veteranos).
- **Personalidad y gustos** con algo de azar y de coherencia con el oficio.

**Todo se calcula en vivo** con quienes haya en el pueblo en ese momento, no con listas de nombres. Si mueren 10 vecinos y llegan 10 nuevos, el sistema sigue igual.

## 4. Director Social (sin cambios)

Un único sistema central decide, cada pocos segundos, qué escena social ocurre y entre quiénes, con un **máximo de 2–3 escenas simultáneas** para cuidar el rendimiento de tu PC. Los aldeanos solo ejecutan (caminar, mirar, hablar, animar).

## 5. Parejas: que surjan solas

**Cómo nace una relación sin forzarla**
- Cada pareja posible acumula **chispa** muy despacio, **solo si pasan tiempo juntos** (trabajan cerca, comen juntos, charlan).
- La chispa crece cuando coinciden gustos, personalidad compatible, edad cercana y buena relación previa.
- Cada día hay una **pequeña probabilidad** de avanzar de etapa si se cumplen las condiciones. Si no, nada ocurre.
- **Nadie "busca" pareja**: no hay estado de búsqueda ni reloj. Si no coinciden, no pasa nada.
- Etapas: `Amigos → Interés → Coqueteo → Citas → Pareja`. Cada una dura lo que dure el azar; la duración "típica" será de varios días, pero **sin tope**.
- **Celos y rupturas** si hay malos eventos; **reconciliación** posible.
- **Misma casa o familia: no hay romance.**
- **Parejas que son de hogares distintos** siguen viviendo cada una en su casa y pasan las tardes juntas.

**Duelo y viudedad** (importante en un pueblo donde la gente muere):
- Si muere la pareja, el otro queda **viudo/a** con humor bajo durante varios días de juego y **no inicia romance** hasta pasado un tiempo.
- Si el jugador es el culpable y lo descubren, hay consecuencias fuertes en la relación con ese vecino y su círculo.

**Calibración:** como no tiene plazos, no sabremos a ojo si ocurre "demasiado" o "nunca". Propongo **simular cientos de días en modo automático** y medir cuántas parejas, rupturas y peleas salen, para ajustar las probabilidades antes de que lo juegues.

## 6. Peleas discretas

- **Tensión** entre dos vecinos sube con insultos, celos, robos y rencores. Una pelea ocurre si supera un umbral, hay un detonante y su carácter lo permite (un "Pacífico" casi nunca pelea).
- **La escena:** se plantan frente a frente; unos segundos de **movimientos sutiles** (pequeños empujones, temblor leve) y algún "💢". Nada exagerado.
- **El resultado** se decide con dados **por dentro**, ponderados por fuerza (oficio, edad, salud, personalidad). Solo ves quién queda peor: el perdedor se tambalea o se retira.
- **Consecuencias:** heridas leves, relación mucho peor entre ellos, testigos que toman partido, guardias que intervienen. **Sin muerte.**

## 7. Tu papel: observador, instigador, mediador

Se mantienen las ideas del plan anterior (espiar, hablar bien o mal de alguien, llevar chismes, intervenir antes de una pelea, hacer de casamentero), apoyadas en **Carisma** y **Sigilo**. Se implementan al final.

## 8. Fases (revisadas)

| Fase | Qué se hace | Qué verás en el juego |
|---|---|---|
| **0. Cimientos** | Ficha de persona + generador de vecinos nuevos con nombre único; asignar género y edad a los actuales; migrar relaciones a identificadores únicos; guardado; registro de eventos; esqueleto del Director | Casi nada; los nuevos ya llegan con identidad propia |
| **1. Conversaciones** | Acciones sociales con frases según personalidad, gustos y relación | Burbujas con diálogos reales |
| **2. Pasar tiempo juntos** | Amigos quedan, rivales se evitan | Pueblo con rutinas sociales |
| **3. Parejas** | Chispa, etapas, celos, duelo y viudedad | Cortejos y parejas que surgen solos |
| **4. Peleas** | Tensión, escena discreta con dados internos, heridas leves, guardias | Peleas sutiles y sus consecuencias |
| **5. Tu papel** | Observador, instigador, mediador | Nuevas opciones al hablar y al presenciar escenas |
| **6. Chismes y pulido** | Chismes entre vecinos, "Noticias del pueblo", simulación para calibrar, auditoría | Ecosistema que se retroalimenta |

Cada fase termina con pruebas automáticas, auditoría y **tu prueba jugando**.

## 9. Riesgos

| Riesgo | Control |
|---|---|
| Nombres repetidos o heredados de muertos | Identificador único + nombre único garantizado (Fase 0) |
| Guardado antiguo incompatible | Migración con valores por defecto; probar cargas |
| Romances demasiado raros o demasiado frecuentes | Simulación de cientos de días para calibrar |
| Pocas mujeres o pocos hombres tras muertes | Generador que equilibra el género |
| Lag por demasiada IA | Director con máximo 2–3 escenas |
| Todos los nuevos se ven igual | Aceptado por ahora; mejora visual opcional futura |

## 10. Decisiones que me quedan

1. **Nombres y apariencia de los nuevos:** ¿te parece bien que el generador use nombres por género de una lista amplia (unas 30–40 por género) y el mismo aspecto genérico por ahora?
2. **Edad:** ¿asigno edades numéricas (por ejemplo 19, 34, 61) o prefieres solo grupos (joven, adulto, mayor)? Recomiendo números, porque dan más juego en la compatibilidad.
3. **Parejas iniciales:** ¿pongo **Elena y el Dr. Valen** como pareja al empezar, y una segunda opcional (por ejemplo **Marlo y Marta**), o solo una?
4. **Simulación de calibración:** ¿te parece bien que antes de la Fase 3 ejecute simulaciones automáticas de muchos días para ajustar las probabilidades?

Con tus respuestas, arranco por la **Fase 0**.
