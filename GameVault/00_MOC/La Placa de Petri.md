---
tipo: moc
aliases:
  - "Inicio"
  - "Biblia del Proyecto"
tags:
  - moc
  - proyecto/placa-de-petri
motor: "Godot 4"
max_population: 100
---
# 🧪 La Placa de Petri

> [!abstract] El proyecto
> Simulador inmersivo 2D (*immersive sim* + *village sim*) en vista cenital y pixel art. Transcurre en un **valle fronterizo aislado** de época anacrónica, con un pueblo de **hasta 100 vecinos** donde cada uno tiene personalidad, memoria, deseos, bolsillo, familia, fe, secretos y rencores.
> Código: `~/Videojuego` · Biblia completa: [[Biblia del Proyecto (original)]]

## 🧭 Navegación
| Área | Notas clave |
|---|---|
| **Visión y reglas** | [[Visión y Leyes de Oro]] · [[Las 6 Piezas Maestras]] · [[Las 7 Reglas de las Auditorías]] · [[Referentes]] |
| **Mundo** | [[Los 21 Vecinos Originales]] · [[Edificios y Espacios]] · [[Clases Sociales]] · [[Rasgos, Tendencias y Manías]] |
| **Historia** | [[Historia Principal - 4 Capítulos]] · [[Misiones secundarias]] |
| **La Secta** 🔒 | [[La Secta]] (reservada al autor) |
| **Roadmap** | [[Tablero]] · [[Pendientes e ideas]] · [[Lore provisional]] · [[Diagnóstico y recomendaciones]] · [[Assets de pago]] |
| **Historial** | [[Cronología del desarrollo]] · [[Cementerio de código]] |

> [!warning] Mayor riesgo actual: la «invisibilidad por menú»
> Recomendación de [[Diagnóstico y recomendaciones]]: no añadir más sistemas dentro de menús y dedicar el próximo ciclo a la **presencia física y visual en el mundo**.

## ⚙️ Sistemas
```dataview
TABLE area AS "Área", estado AS "Estado", codigo AS "Código"
FROM "02_Sistemas" OR "03_La_Secta"
SORT area ASC, file.name ASC
```

## 🟡 Sistemas a medias
```dataview
LIST codigo
FROM "02_Sistemas"
WHERE estado = "parcial"
```

## 📋 Pendientes abiertos
```dataview
TASK
FROM "05_Roadmap_y_Lore"
WHERE !completed
GROUP BY file.link
```

## 📝 Diario reciente
```dataview
LIST
FROM "06_Diario"
SORT file.name DESC
LIMIT 5
```
