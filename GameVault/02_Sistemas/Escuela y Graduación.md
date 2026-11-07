---
tipo: "sistema"
area: "mundo"
estado: "implementado"
codigo: "J3, PF.3"
tags:
  - "mecanica"
  - "mundo"
  - "sistema"
fuente: "Biblia §9.1"
---
# Escuela y Graduación

> Sección original: *Escuela, Maestro y Graduación (`J3`, `PF.3`, `Bloque PR`)*

- **Asistencia Escolar Autónoma (`Bloque PR`):** Si aún no habían llegado familias con niños de entre 6 y 15 años, al abrir la escuela se asientan dos jóvenes escolares en hogares del pueblo, se asigna automáticamente a un vecino instruido como **Maestro de Escuela** y cada mañana laborable (`Lunes a Sábado`, a las `09:00` y `11:00`) los niños caminan a la escuela y suman lecciones reales (`pupil_lessons`).
- **Graduación (`PF.3`):** Al completar **8 lecciones** (o al cumplir 16 años tras haber estudiado), el alumno se gradúa y recibe una **bonificación de aprendizaje (`school_bonus_days`)** que acelera su ascenso en su **primer oficio** adulto.

## Notas de diseño
- 2026-11-07 (Antigravity, Bloque B5): a las `09:00` en día lectivo, los escolares forman **fila india en la puerta de la escuela** (`school_door + Vector2(0, idx * 14)`) y sueltan un bocadillo corto de 1,5 s (`«📚🛎️ ¡En fila a la escuela!»`) antes de entrar a clase.
