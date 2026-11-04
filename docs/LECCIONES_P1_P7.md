# Lecciones de la auditoría de P1–P7 (para el siguiente agente)

Revisé (Claude Code, 2026-11-04) los bloques P1–P7. Informe completo: `docs/AUDITORIA_P1_P7.md`.
Arreglos en los commits 43e6f46, 8ee8ed5 y 0f85298. Léelos antes de tocar esos módulos.

## Qué se hizo mal

1. Se documentaron ~25 mecánicas que no existen (lejía, sobornar autopsia, seguro de vida, caravana, timba de dados,
   fingir milagro, debates, indulto...). El CHANGELOG decía "70 mecánicas" sin comprobarlo. Regla: solo se documenta
   lo que está en el código.
2. Se rompió el misterio: el menú del comisario nombraba al asesino antes de investigar; el rencor de clan saltaba en
   el instante del crimen; el culpable se adivinaba por subcadena del texto de cierre (salía el comisario Vane como
   asesino).
3. Se creó oro de la nada: perista sin quitar objetos, pelea siempre ganada, robo desde el diálogo, extorsión sin
   pagador, cofre que regala oro, recompensas sin bolsillo.
4. Veneno = asesinato instantáneo, sin testigos ni riesgo.
5. Pulsar E compraba casa o cambiaba impuestos sin confirmar.
6. Se llamó a funciones que no existen (`advance_to_morning`) dentro de `has_method`, así que fallaban en silencio.
   Doble cobro viernes/sábado por mal cálculo del día de la semana.
7. Moción repetible hasta ganar; nombrar comisario borraba la búsqueda; títere sin que el jugador supiera nada;
   vecinos viviendo en dos casas; adopción repetible.

## Qué se arregló (en `main`, los 4 tests pasan)

- Ninguna opción nombra a un culpable que el jugador no ha averiguado.
- Todo oro sale del bolsillo de alguien o de una caja (`VillageClans.pay_from_pocket`).
- Veneno con testigos y efecto al día siguiente; doble E para confirmar decisiones (`press_twice`); cama solo de noche
  y pasa el tiempo; moción con firmas y 30 días de espera; `move_into_player_home` saca al vecino de su casa anterior.
- CHANGELOG corregido; lo no hecho está en `docs/VISION_Y_FUTURO.md` como pendiente.

## Reglas para seguir

- Antes de escribir "hecho", comprueba que la acción existe y tiene un test.
- Nunca uses `has_method()` para algo que crees que existe: búscalo primero.
- Pendiente de riesgo bajo: renombrar niños puede desincronizar registros que van por nombre.
