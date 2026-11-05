---
tipo: "historia-desarrollo"
tags:
  - "cronologia"
  - "historia-desarrollo"
fuente: "Biblia §2"
---
# Cronología del desarrollo

> [!note]- Desplegar línea de tiempo completa del desarrollo (Febrero 2026 → Noviembre 2026)
> ### Etapa 0: El Prototipo de Sigilo y la Gran Poda (Febrero 2026)
> - **Día 0 (`8a9cbb9` – `7aba4f5`):** Nace el prototipo de acción y sigilo en vista cenital. Se crea el controlador de movimiento con *sprint*, esquiva (*dodge*) y agachado (*crouch*), el sistema de ondas de ruido con oclusión por paredes, conos de visión (`VisionCone2D`), el rastro fantasma del jugador (*Ghost Search* cuando un guardia te pierde de vista), objetos rompibles (cajas, barriles, muros débiles) y el combate base con **Espada** (corte + sangrado) y **Martillo** (golpe contundente + aturdimiento).
> - **Evolución visual de la protagonista «Vero» (`V1` a `V9`):** Diseño pixel-art de 4 direcciones de la protagonista rubia con capucha oscura y máscara, junto con la integración del arte *Epic RPG World — The Village V2.1* e interiores *V1.3*.
> - **La Gran Simplificación (`dbfffdd`, `archived_systems/`):** Para evitar que sistemas experimentales pesados frenaran la simulación del pueblo y para migrar el renderizado a `gl_compatibility`, se archivaron 4 subsistemas antiguos (ver [[Cementerio de código]]): el primer sistema de armaduras, la red de cables eléctricos físicos (`addons/powergrid/`), el inventario por cuadrícula estilo *Tarkov* y los interiores en escenas separadas con teletransportadores.
>
> ### Etapa 1: Supervivencia, Ecosistema Vivo y la Aldea Inicial (Fases 1 a 5)
> - **Reloj y Supervivencia:** Se introduce el reloj del mundo de 24 horas (`WorldClock`), clima dinámico (`☀️ Despejado`, `🌧️ Lluvia`, `🌫️ Niebla`) y necesidades del jugador (Vida, Sangrado, Aturdimiento, Aguante, Hambre, Sueño).
> - **Rueda Radial de 8 Herramientas (`[Tab]`):** Espada, Martillo, Hacha, Pico, Arco de caza con tensión y parábola, Hoz, Regadera y Caña de pescar, todas mejorables de `Nv.1` a `Nv.3`.
> - **Campamento del Jugador:** Evolución en 3 niveles (`Tienda → Cabaña de madera → Casa de piedra con cofre`), hoguera de cocina, tronco para sentarse, huerto `3×3` con compostador y aspersor, y gallinero con crianza genética (`Nv.1–3`), ataques nocturnos de zorros y defensa del perro guardián **Toby**.
> - **Bosque Profundo con Reglas Ecológicas:** Separación en 3 hábitats (pradera de conejos, claros de venados, cantera y guaridas de zorros), caza de zorros por sigilo + salto (`POUNCE`), piaras de jabalíes que embisten, ciénaga de ranas y bandidos al oeste, y umbrales matemáticos de conservación para impedir la extinción.
>
> ### Etapa 2: Gremios, Economía Viva, Casino, Medicina RimWorld y Justicia (Fases 6 a 10)
> - **Las 5 Familias Artesanas y la Posada:** Herrería, Carnicería, Carpintería, Botica, Pescadería/Molino y la Gran Posada «El Jabalí Dorado».
> - **Economía de Oferta y Demanda:** Multiplicadores de precios en vivo (`0.80x` a `2.25x`), expediciones matutinas de recolección de los artesanos, compra de insumos entre talleres, sabotaje de talleres y compra de acciones al 50% (Socio) o 100% (Dueño Único).
> - **Casino de la Posada (`[F1]`–`[F4]`):** Póker Texas Hold'em con gestos psicológicos (*tells*), Blackjack 21, Ruleta Europea y Billar 2D con física de bolas, pausando el reloj del mundo mientras juegas con vecinos sentados de verdad.
> - **Medicina Anatómica y Morgue:** Salud por partes del cuerpo (cabeza, torso, brazos, piernas, órganos), dolor, desangrado, infección, estado agonizante (`is_downed`), muerte persistente con putrefacción, huellas de sangre, avistamiento por línea de visión real y traslado físico a la Morgue del **Dr. Valen**.
> - **Justicia, Comisaría e Inquisidor Real:** **Comisario Vane**, **Guardia Rodric**, puertas con cerradura según alerta del pueblo (`🟢/🟡/🔴`), cerrojos interiores `[B]`, derribos sigilosos, arresto con esposas, mercaderes reales (**Maese Casimir** y **Valeria la Tratante**) y el **Inquisidor Real Alistair**, que investiga crímenes interrogando testigos sin omnisciencia y celebra juicios públicos en la plaza.
>
> ### Etapa 3: La Gran Simulación Social, Crecimiento Urbano y Misiones (Bloques B, T, U, C, R, S, D, G, E, I, O, V, A–N, Q, M)
> - **Identidad y los 140 Rasgos (`B0`, `T1–T5`):** 400 nombres y 200 apellidos, perfiles únicos, 140 rasgos (51 ejes de opuestos + 22 sueltos, 17 raros), ocultos al inicio (`❓`) y descubiertos tratando con el vecino, espiando o por rumores.
> - **Relaciones de un Solo Sentido y Romance (`B1–B3`, `U1–U7`):** Aprecio y chispa asimétricos (`↩`), manías unilaterales, cortejo sin plazos fijos, amor no correspondido, celos, rupturas, luto con visitas al cementerio y enfriamiento por distancia.
> - **Chismes, Memoria que se Degrada y Crónica (`B6`, `C1–C5`, `R1–R5`):** Recuerdos que pierden fuerza cada día y se deforman al contarse de boca en boca; panel de **Crónica del Pueblo (`[O]`)**.
> - **Secretos, Deseos Propios y Asesinatos (`S1–S6`, `D1–D6`, `V8`):** Infidelidades, chantajes, deseos autónomos de venganza, ambición por talleres vacantes y asesinatos entre vecinos con señales previas.
> - **Fe, Bandos, Necesidades e Instituciones (`G1–G7`, `E1–E7`, `I1–I6`, `O1–O8`):** **Fe del Alba** (**Hermano Anselmo**), descanso dominical, pandillas, higiene en pozos y lavadero, enfermedades contagiosas (**Resfriado** y **Fiebre gris**), clases sociales, gachas solidarias en el albergue, adicciones a bebida y juego, elecciones en urna cada 28 días, impuestos de los sábados, corrupción y **La Secta** secreta.
> - **Crecimiento de la Ciudad a 100 Vecinos (`V1–V9`, `A–K`, `H`, `PQ`):** Nuevos edificios y oficios (Panadería, Sastrería, Posada «El Candil», Albergue, Ayuntamiento, Biblioteca, Escuela, Mercado de los miércoles, Taller de reparaciones, Granja, Rancho, Cantera, Leñador, Lavadero, Parque, Mirador, Mansión Noble), 27+ solares edificables, préstamos hipotecarios, jornaleros por horas, migración, embarazos de 9 días y niños que crecen hasta hacerse adultos a los 16 años.
> - **25 Misiones Secundarias (`Q1–Q4`, `M`, `N`):** Encargos emergentes (`❗`) que nacen de los problemas reales de los vecinos.
>
> ### Etapa 4: Profundidad Sistémica, Mundo Exterior y Auditorías (Bloques P1–P7, PA–PD, PF–PR)
> - **Los 7 Bloques de Profundidad (`P1`–`P7`):** Clanes familiares y feudos de sangre (`P1`), investigación forense avanzada y seguros de vida (`P2`), linajes, bastardos y herencias (`P3`), confesionario, bulas y santuario en la capilla (`P4`), alcaldía jugable, decretos y moción de censura (`P5`), compra de casas, reformas, alquileres y el «Bazar del Forastero» (`P6`), y bajos fondos con perista, contrabando, golpes, extorsión y la «Red de las Sombras» (`P7`).
> - **Las 12 Expansiones de Mundo (`PF`–`PQ`):** Fama individual y **Maestros Artesanos** con Obras Maestras (`PF`), admiradores obsesivos y acompañantes (`PG`), cría de animales por etapas y apuestas (`PH`), amputaciones y prótesis (`PI`), red eléctrica de 3 circuitos y reforestación de pinos (`PJ`), rutas comerciales e investigación tecnológica (`PK`), incursiones con motivo real y defensa física en el camino del este (`PL`), caballos, carretas y expediciones arqueológicas (`PM`), capas verticales `-1/0/+1` y alcantarillas (`PN`), arcabuz de chispa y terminales lógicas (`PO`), asentamiento «Puesto del Paso» e Historia Principal en 4 capítulos (`PP`), y ampliación urbana a 100 vecinos (`PQ`).
> - **Auditorías y Vida Autónoma (`Auditoría P1–P7`, `Auditoría PF–PQ`, `Bloque PR`):** Eliminación total de oro salido de la nada, destripes de secretos en menús y retos sin fallo; activación de la vida autónoma del pueblo (los maestros venden solos en el mercado, el rancho renueva su rebaño, los niños van a la escuela con el maestro y el ayuntamiento invierte el superávit de las arcas en tecnología, rutas y milicia).
