# Registro de cambios

Cambios del juego, del más nuevo al más antiguo. Añade una entrada al cerrar cada bloque, en lenguaje sencillo.
El detalle técnico está en `docs/HANDOFF.md` (sección 7) y el historial completo en `git log`. Lo anterior a B0.1 está en `AUDIT_LOG.md` y `SESSION_CONTEXT_LOG.md`.

## 2026-11-02

### Refuerzo del código
- **R4**: investigaciones, interrogatorios y juicio pasan a `VillageJustice.gd`; el juego no cambia.
- **R3**: quedadas, peleas y chismes pasan a `VillageSocialLife.gd`; el juego no cambia.
- **R2**: la construcción del pueblo pasa a `VillageWorldBuilder.gd`; el mundo sigue idéntico.
- **R1**: nuevo test del ciclo completo de guardar y cargar una partida; no encontró errores y el juego no cambia.

### Documentación
- Puesta al día del traspaso: nuevo `CLAUDE.md`, este registro y `docs/HANDOFF.md` actualizado.

### Vida social — Fase 6 (cerrada)
- **B6.4** (`87f4c74`): las quedadas ya no se cancelan casi siempre al irse a dormir: duran menos y no se planifican después de las 20:15. Revisión del código: 9 correcciones; la más importante evita que los chismes revelen muertes aún sin descubrir. El efecto en quedadas y parejas no se llegó a medir.
- **B6.3** (`7146515`): dos partidas de 60 días medidas: 4 peleas y 3 parejas nuevas en cada una, sin muertes ni vecinos aislados.

## 2026-11-01

### Vida social — Fases 4 a 6
- **B6.1 y B6.2** (`7b1bf12`): los vecinos se cuentan novedades, puedes preguntarles por ellas y lo muy sabido aparece en el tablón de la plaza.
- **B5.4** (`dea66aa`): casamentero: animar a dos solteros compatibles a acercarse.
- **B5.3** (`5545530`): mediar entre enemigos y separar peleas en marcha.
- **B5.2** (`b32e6b5`): hablar bien o mal de un vecino con Carisma, una vez al día.
- **B5.1** (`c3781c4`): preguntar qué opina un vecino de otros y escuchar a escondidas.
- **B4.2** (`b85d166`, `36972fe`): peleas visibles, breves y raras, solo tras una enemistad larga, con moratón leve, testigos y guardia.
- **B4.1** (`74d1f87`, `5e50d81`, `ab76242`): resolución interna de peleas con dados; corregido el uso de la salud y la tirada diaria.

### Vida social — Fases 0 a 3
- **B3.1 a B3.5**: cortejos, citas, celos, rupturas, reconciliaciones, duelo y visitas al cementerio.
- **B2.1 y B2.2**: quedadas en la plaza y la taberna; los rivales se evitan.
- **B1.1 a B1.3**: conversaciones reales de 2 turnos entre vecinos.
- **B0.1 a B0.9**: nombres únicos, fichas de persona, generador de vecinos nuevos, relaciones por identificador, guardado, registro de eventos, Director Social, pareja inicial y simulador de 60 días.

### Otros cambios
- Velocidad de tiempo persistente 1x/2x/4x/8x.
- Sprites de vecinos, suelos, muros y empedrado renovados.
