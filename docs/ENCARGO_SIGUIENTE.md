# ⭐ ENCARGO DE HOY — Retoques del río, el molino y la capilla
Modo demo activo. No muevas edificios ni crees sistemas. Mira las capturas de anoche en `docs/capturas_arreglos/rio_molino/`.

1. **El río parece una acequia** (`02_rio_en_el_pueblo.png`): en el pueblo es estrecho y casi recto. Que sea un **río de
   verdad**: bastante más ancho al cruzar el pueblo, con **curvas y orillas irregulares** (piedras, juncos, barro), y que
   se **estreche poco a poco** al subir hacia el norte hasta ser arroyo junto al claro y el molino. Sin mover edificios;
   el puente viejo y los vados deben seguir sirviendo (puente más largo si hace falta). Agua no pisable; rutas de
   vecinos intactas.
2. **El molino está demasiado limpio** (`06_molino_dentro.png`): debe verse **abandonado hace años**: tablas del
   suelo rotas o levantadas, polvo, telarañas, muebles volcados, maderas caídas, alguna pared con boquete, poca luz.
   Que se mantengan el pajar, el hogar con ceniza, el cordel y la mesa con el papel. El **barro rojo** de la orilla del
   molino tiene que verse claramente rojo (arcilla), distinto del pardo del claro (`05_barro_rojo_y_rueda.png`).
3. **Un vecino subido encima del altar de la capilla** (`docs/capturas_arreglos/interiores/05_suelo_capilla_despues.png`):
   que nadie pueda ponerse sobre altares, mesas ni muebles; busca la causa (punto de destino o asiento mal colocado) y
   compruébalo en los demás edificios del Caso I.

Capturas antes/después en 1.ª persona en `docs/capturas_arreglos/rio_molino/` (sufijo `_v2`). Commit y push por punto.
Al final, `RECORRIDO PASSED`. Informe arriba de `docs/INFORME_ANTIGRAVITY.md`, máx. 12 líneas. Godot siempre en primer
plano con `timeout`.

## Notas del supervisor
**(01:15) El usuario quiere que trabajes toda la noche. NO crees `DIA_TERMINADO.txt` al acabar el punto 3: sigue con los
puntos 4–9, en orden.** Trama decidida en `docs/PLAN_BETA_MISTERIO.md` §5 (lee solo los párrafos que cite cada punto).
Pistas = objetos que se examinan con [E] en 1.ª persona, con su texto, y que se anotan en el cuaderno del caso si ese
sistema ya lo permite (no inventes sistemas nuevos). Captura en 1.ª persona por punto en `docs/capturas_arreglos/caso1/`.

4. **Molino: sótano con reja** («Cómo llegó el frasco»): sótano bajo el molino que da al **canal de la rueda**; reja de
   hierro con **marcas de haberla intentado forzar** y un **trozo de tela** del familiar enganchado. **Comisaría:**
   **denuncia de desaparición archivada** (papel examinable en el cuarto de pruebas o un archivador).
5. **Biblioteca: sala oculta** («El libro y la sala oculta»): tras una estantería que se abre con un **libro-palanca**;
   se delata por una **corriente de aire** (polvo que se mueve) y **marcas de arrastre** en el suelo. Dentro: libros de
   ocultismo, venenos y la antigua fe; el **cuaderno secreto de firmas** y el **libro con una página arrancada**.
6. **Puente viejo:** el **zapato izquierdo** de la víctima, examinable («La víctima»).
7. **Inicio de la demo** (`FALLOS_VISIBLES.md`: «El campamento inicial está en medio del pueblo»): el jugador empieza
   en **las afueras** (camino de entrada al valle), no en un campamento dentro del pueblo. Al empezar, pantalla con la
   **carta de contratación** (solo texto) con un texto provisional: «Carta de contratación — texto pendiente del autor».
8. **Bosque alrededor del claro del cuerpo** (`FALLOS_VISIBLES.md`: «El bosque parece un parque»): más denso y oscuro
   alrededor del arroyo, con sotobosque y borde irregular, para que el claro se sienta escondido.
9. **Río en el pueblo con más curvas** (aún parece un canal ancho): meandros y orillas desiguales, sin mover edificios.

Al acabar el 9 (o si ya no da tiempo), informe arriba de `docs/INFORME_ANTIGRAVITY.md` y entonces sí `DIA_TERMINADO.txt`.
