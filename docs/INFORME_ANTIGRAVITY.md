# Informe de Trabajo — Antigravity (2026-11-07)

## Encargo: Herramientas del Detective (Bloques D1, D2, D3, D4 y D5)

Se han implementado y verificado los cinco bloques de **Herramientas del Detective** (`D1`–`D5`) siguiendo el diseño de `docs/PLAN_BETA_MISTERIO.md` (§§5–6) y el boceto visual `docs/bocetos/examen_cuerpo.html`, además de corregir el fallo visual reportado en `docs/FALLOS_VISIBLES.md`.

> **Atajo de teclado clave:** La **`Tecla N`** (`[N] Tablero`) abre y cierra en cualquier momento el **Tablero del caso** (tablero de corcho del detective), también accesible desde la pestaña `📌 Tablero [N]` dentro de la interfaz forense.

---

## 1. Resumen por Bloque

### Bloque D1 — Examen de cuerpo (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`, `scripts/world/CorpseInteractable.gd`)
- **Vista de examen forense fiel a `docs/bocetos/examen_cuerpo.html`:**
  - Cabecera oscura (`#1b1612`) con sello rojo `CASO #01 · ARCHIVO FORENSE`, nombre de la víctima, oficio/edad y lugar/hora del hallazgo, más barra de **5 pestañas** (`1 · Examen del cuerpo`, `2 · Autopsia (morgue)`, `3 · Escena del crimen`, `4 · Tablero del caso`, `5 · Acusar`) y botón `✕ Cerrar [ESC]`.
  - **Columna izquierda (Lienzo de silueta + escena top-down):**
    - Fondo con boceto top-down de la escena (empedrado, farola cálida, casa colindante, manchas de sangre, contorno de tiza y marcadores numerados `1` y `2` en amarillo).
    - Silueta anatómica vectorial dibujada con `_draw()` en dos variantes según el género de la víctima: **femenina** (hombros más estrechos, cintura marcada, caderas suaves y melena oscura dibujada *detrás* de la cabeza mediante polígonos laterales y superiores sin tapar la cara) y **masculina** (hombros anchos y torso recto).
    - **Zonas clicables con anillos numerados (`1`–`7`)**:
      - Puntos ámbar pulsantes cuando aún no se han examinado; al hacer clic se vuelven rojos y despliegan la marca anatómica correspondiente (surco violáceo en cuello, hematoma occipital, fibras rojas bajo uñas, manchas de barro en rodillas, bolsillo vuelto con iniciales, etc.).
      - Puntos azules con icono `🔍` (`requiere_lupa: true`): exigen tener `magnifying_glass` en el inventario del jugador; sin lupa muestran aviso contextual y no se desbloquean.
    - **Controles del lienzo:** botones `[ ↺ Girar cuerpo: Frente / Espalda ]`, `[ 🔍 Usar lupa ]` y `[ 🧤 Tomar muestra (N/2) ]`, más leyenda inferior y etiqueta `TEMPERATURA AMBIENTE · FRÍO DE MADRUGADA`.
  - **Columna derecha (Cuaderno de campo, `#f3ead6`):**
    - Ficha de la víctima con retrato estilizado, **barra de estado del cadáver** en 4 fases (`Reciente` → `Enfriándose` → `Rígido` → `Deteriorado`, con degradación de pruebas físicas si pasa demasiado tiempo a la intemperie), detalle de la zona seleccionada con confirmación `"✓ Anotado en el cuaderno"` en verde oscuro legible, lista de observaciones anotadas y bloque de **hipótesis preliminar del detective** que se sintetiza automáticamente al descubrir 3 o más hallazgos.
  - **Acciones al pie:** `[ Llevárselo a la morgue ]` y `[ Dejar el cuerpo aquí ]`.

### Bloque D2 — Autopsia en la morgue con el Dr. Valen (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`)
- Al trasladar el cuerpo a la morgue del hospital (`deliver_corpse_to_morgue`), se habilita la pestaña `2 · Autopsia (morgue)` (y al interactuar con la mesa de autopsias en el hospital se abre directamente esta vista).
- **Mesa de autopsias:** muestra la silueta sobre losa clínica con bandejas de instrumental, frascos de muestras recogidas (`N/2`) y 3 hallazgos internos desbloqueables (`Vías respiratorias y cuello`, `Contenido gástrico y sangre`, `Cotejo de muestras recogidas`).
- **Informe del Dr. Valen:**
  - Si el jugador consulta al doctor (`ask_valen_hint`), el Dr. Valen orienta la investigación hacia una pista clave.
  - Gráfico comparativo de **4 barras de color** (`Veneno / tóxico`, `Forcejeo previo`, `Arma blanca`, `Asfixia / golpe`) con porcentajes por caso.
  - Dictamen forense con **Causa aparente** vs. **Causa real** (revelada al completar los análisis internos o usar el `forensic_kit`).

### Bloque D3 — Escena del crimen a oscuras con linterna (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`)
- Vista `3 · Escena del crimen` con lienzo interactivo de la escena del hallazgo cubierta por un velo nocturno oscuro (`#06080ef2`).
- **Círculo de luz cálida de la linterna** perfectamente centrado en el anillo dorado del cursor que sigue el ratón (o foco ambiental reducido si el jugador no lleva `lantern`), iluminando solo los indicios dentro de su radio (`Huellas de botas con barro`, `Cuerda de cáñamo cortada`, `Hebilla de latón`, `Fibras de lana roja`, `Nota arrugada con iniciales`).
- Hacer clic sobre un indicio iluminado lo examina y lo añade automáticamente al cuaderno y al tablero de corcho.
- Panel derecho con el registro de indicios de la escena y los **testigos cercanos** generados o vinculados al caso, con su testimonio y botón para fijarlos en el tablero.

### Bloque D4 — Tablero de corcho con chinchetas e hilos rojos (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`)
- Accesible en cualquier momento con la **`Tecla N`** (`open_corkboard()`) o desde la pestaña `4 · Tablero del caso`.
- Textura de corcho con marco de madera oscura y **tarjetas arrastrables** con chincheta superior para:
  - **Víctima** (chincheta roja),
  - **Sospechosos** (chincheta ámbar, con retrato, oficio, coartada y botón `Interrogar`),
  - **Pistas y hallazgos** del cuerpo, autopsia y escena (chincheta azul/verde).
- **Hilos rojos tensados por encima de las tarjetas:** botón `[ 🧶 Tender hilo rojo ]` (o clic derecho entre dos chinchetas) para conectar o desconectar cualquier par de tarjetas.
- **Deducción de conexiones clave:** al unir con hilo rojo las tarjetas que forman una contradicción o prueba incriminatoria del caso, se desbloquea una conclusión deductiva en el expediente y para la vista `5 · Acusar`.

### Bloque D5 — Datos de los 10 casos + Fallo visible de la Trattoria (`scripts/systems/DetectiveCaseData.gd`, `scripts/world/BuildingExterior3D.gd`)
- **10 casos completos en `DetectiveCaseData.gd` (`CASES` 1..10):**
  1. *Caso 1 — El Silencio del Escriba* (Aldric Vane, estrangulado con cuerda de cáñamo, culpable: **Bruno**).
  2. *Caso 2 — El Brillo del Arsénico* (Helena Vael, envenenamiento crónico, culpable: **Cora**).
  3. *Caso 3 — La Sombra del Campanario* (Padre Tomás, empujado tras golpe previo, culpable: **Ansel**).
  4. *Caso 4 — Sangre en la Forja* (Garrick el Herrero, golpe con martillo de forja, culpable: **Dario**).
  5. *Caso 5 — El Último Brindis* (Marco de la Trattoria, digitalina en vino de reserva, culpable: **Livia**).
  6. *Caso 6 — Cosecha Amarga* (Berta del Molino, asfixia con saco de harina, culpable: **Orson**).
  7. *Caso 7 — El Secreto del Puerto Seco* (Capitán Roldán, daga estrecha por la espalda, culpable: **Vasco**).
  8. *Caso 8 — Cenizas en el Invernadero* (Clara la Herborista, inhalación de belladona quemada, culpable: **Silas**).
  9. *Caso 9 — El Reloj Parado a las Tres* (Maestro relojero Elías, golpe con contrapeso de bronce, culpable: **Nora**).
  10. *Caso 10 — La Confesión del Juez* (Juez Severo, veneno de contacto en sello lacrado, culpable: **Valerio**).
- Cada caso incluye género, zonas anatómicas de frente y espalda (normales y con lupa), hallazgos de autopsia, pista del Dr. Valen, barras forenses, causa aparente y real, indicios de la escena del crimen, testigos, sospechosos con coartada y conexiones clave del tablero.
- **Vinculación con NPCs reales (`assign_case_roles`):** vincula víctima, culpable, sospechosos y testigos con vecinos vivos del pueblo sin matar a ningún NPC al iniciar el juego; solo instancia el cadáver cuando un caso se activa expresamente.
- **Corrección de `docs/FALLOS_VISIBLES.md`:**
  - *Fachada de la trattoria «Il Corvo» en 3D:* en `scripts/world/BuildingExterior3D.gd` (`_apply_shell_Role_theme`), el rol `"trattoria"` ahora aplica fachadas de estuco cálido color crema/terracota claro (`Color(0.88, 0.80, 0.68)`) con zócalo de ladrillo terracota (`Color(0.68, 0.36, 0.26)`) y contraventanas verde oliva, eliminando el aspecto de tablas oscuras. Marcado con `✅ (2026-11-07)` en `docs/FALLOS_VISIBLES.md`.

---

## 2. Verificación Automática (`verify_all.gd`)

Se ejecutó la suite integral `tools/tests/verify_all.gd` en modo headless:

```bash
timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd > /tmp/v.log 2>&1
```

- **Resultado:** `EXIT_CODE=0` — **100 % de los tests en verde**, incluyendo los nuevos bloques de pruebas `D5.1a–D5.1c`, `D1.0–D1.3`, `D2.1a–D2.4`, `D3.1a–D3.2c` y `D4.1a–D4.5`.

---

## 3. Tour Visual de Capturas (`docs/capturas_detective/`)

Todas las capturas fueron generadas con el motor en ejecución real y revisadas visualmente una por una:

| Archivo | Contenido verificado |
| :--- | :--- |
| `docs/capturas_detective/d1_examen_mujer.png` | Vista `1 · Examen del cuerpo` con silueta femenina (melena detrás de la cabeza), marcas anatómicas reveladas, boceto 3D top-down y cuaderno de campo con `"✓ Anotado en el cuaderno"`. |
| `docs/capturas_detective/d1_examen_hombre.png` | Vista `1 · Examen del cuerpo` con silueta masculina (Caso 1, Aldric Vane), zonas reveladas y cuaderno de campo. |
| `docs/capturas_detective/d2_autopsia_morgue.png` | Vista `2 · Autopsia (morgue)` con mesa clínica, frascos de muestras (`2/2`), consejo del Dr. Valen, gráfico de 4 barras de color y causa aparente vs. causa real. |
| `docs/capturas_detective/d3_escena_crimen.png` | Vista `3 · Escena del crimen` a oscuras con el haz cálido de la linterna centrado en el cursor e iluminando las pruebas, más testigos a la derecha. |
| `docs/capturas_detective/d4_tablero_corcho.png` | Vista `4 · Tablero del caso` (`Tecla N`) con tarjetas de víctima, sospechosos y pistas separadas sobre el corcho e hilos rojos tensados por encima de las tarjetas. |
| `docs/capturas_detective/mundo_plaza_dia.png` | Vista general de la plaza central de día con vecinos y edificios. |
| `docs/capturas_detective/mundo_plaza_noche.png` | Vista general de la plaza central de noche con iluminación de farolas. |
| `docs/capturas_detective/mundo_trattoria_dia.png` | Fachada 3D de la Trattoria «Il Corvo» corregida con estuco crema cálido y ladrillo terracota claro. |
| `docs/capturas_detective/mundo_morgue_dia.png` | Exterior del Hospital / Morgue del Dr. Valen y Comisaría de día. |
| `docs/capturas_detective/mundo_bosque_noche.png` | Vista nocturna del bosque periférico. |
