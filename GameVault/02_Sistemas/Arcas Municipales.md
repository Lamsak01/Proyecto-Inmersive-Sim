---
tipo: "sistema"
area: "politica"
estado: "implementado"
codigo: "treasury"
tags:
  - "politica"
  - "economia"
  - "sistema"
fuente: "Biblia §4, §5, §8.1, §9.4, §14"
---
# Arcas Municipales

Tesoro del pueblo (`treasury`), gestionado desde el Ayuntamiento → [[Alcaldía y Política]].

## Entradas
- **Impuesto sobre la renta de los sábados**: según lo que cada vecino ganó en la semana, por tramos (0 % hasta 4/día, 15 % hasta 15/día, 30 % el resto), multiplicado por el edicto fiscal.
- **Alquiler de puestos del mercado** (4 por vendedor) y **arancel de las rutas comerciales** (4 por intercambio).

## Salidas
- **Inversión autónoma del superávit:** cuando superan las **320 monedas** y no hay campaña abierta, se invierte como máximo una vez cada 4 días en investigación, [[Rutas Comerciales]], milicia o subsidios.
- **Pago de pólizas de seguro de vida** (`P2.13`) → [[Investigación Forense]].
- **Recompensas**, como delatar a la [[Red de las Sombras]].
- **Desfalco** posible por parte del alcalde (`P5.10–P5.11`).

## Riesgos
- Por encima de **300 de oro** atraen [[Incursiones y Defensa|incursiones]] (`raid_lure`); si estas triunfan, saquean parte de las arcas.

## Regla
- Pertenecen a la economía de **suma cero**: ver [[Las 7 Reglas de las Auditorías]], regla 1.

## Notas de diseño
- 2026-11-05 (Claude Code): impuesto del sábado cambiado a renta semanal por tramos (pedido del usuario): exento hasta 4 de oro/día, 15 % entre 4 y 15/día, 30 % por encima. Medido: arcas estables entre ~385 y ~900.
- 2026-11-05 (Claude Code): nuevas entradas aprobadas por el usuario: alquiler de puestos del mercado (4 por vendedor cada miércoles) y arancel de 4 por intercambio de las rutas comerciales (oro de fuera del valle).
- 2026-11-05 (Claude Code): auditoría Regla 1. Ahora pagan de verdad los encargos del tablón y el sueldo entero de médico y guardias (si están vacías, se cobra lo que haya); reciben multas, fianzas, la tasa de la moción de destitución y la multa de los ladrones atrapados.
- 
