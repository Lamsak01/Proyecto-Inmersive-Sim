---
tipo: "indice"
tags:
  - "mundo"
  - "personajes"
fuente: "Biblia §10.1"
---
# Los 21 Vecinos Originales

```dataview
TABLE rol, lugar
FROM "04_Censo_y_Misiones/Vecinos"
SORT lugar ASC
```

## Tabla original
Además de los hasta **79 vecinos adicionales** que llegan por migración o nacen en las familias (hasta el tope de **100 habitantes**), el valle arranca con estos **21 personajes fundadores**:

| Grupo / Lugar | Nombre | Rol Inicial | Notas de Diseño y Personalidad Base |
|---|---|---|---|
| **Herrería «Yunque Gris»** | **Thoran** | Maestro Herrero | Veterano orgulloso del metal; forja armas, herramientas y armaduras. |
| **Herrería «Yunque Gris»** | **Kael** | Ayudante de Herrería | Joven aprendiz; sale por las mañanas a picar mineral de hierro a la cantera. |
| **Carnicería «El Colmillo»** | **Garrick** | Maestro Carnicero | Cazador recio; encarga cacerías de jabalíes (`boar_hunt`) y compra piezas de caza. |
| **Carnicería «El Colmillo»** | **Lina** | Ayudante de Carnicería | Se encarga del despiece, ahumado y recolección en los claros del bosque. |
| **Carpintería «Roble Viejo»** | **Bram** | Maestro Carpintero | Construye muebles, reformas de casas (`P6.4`), arcos y ampliaciones de segunda planta. |
| **Carpintería «Roble Viejo»** | **Mila** | Ayudante de Carpintería | Sale a talar madera al bosque respetando el umbral ecológico. |
| **Botica «Raíz Verde»** | **Elena** | Maestra Boticaria | Prepara cataplasmas, antídotos, tónicos, lejía y compuestos alquímicos. |
| **Botica «Raíz Verde»** | **Tomás** | Ayudante de Botica | Recolecta hierbas medicinales en la pradera del oeste y setas en los claros. |
| **Pescadería y Molino «Aguas Claras»** | **Marlo** | Maestro Pescador y Molinero | Gestiona la pesca del lago y la molienda de trigo. |
| **Pescadería y Molino «Aguas Claras»** | **Nora** | Ayudante de Pescadería | Pesca en la orilla del lago y abastece el mercado de los miércoles. |
| **Gran Posada «El Jabalí Dorado»** | **Marta** | Posadera y Tabernera | Corazón de los rumores del pueblo; regenta la barra, las camas y el casino. |
| **Viajeros de la Posada** | **Aldric** | Viajero / Pensador Oscuro | Carismático e inquieto; candidato frecuente a fundar [[La Secta]] si estalla una crisis. |
| **Viajeros de la Posada** | **Sora** | Viajera / Buscadora | Observadora y diestra; suele sentarse a las mesas del casino o explorar el valle. |
| **Viajeros de la Posada** | **Darío** | Viajero / Tahúr | Aficionado a las cartas, los dados y los negocios rápidos. |
| **Seguridad y Ley** | **Comisario Vane** | Comisario del Valle | Dirige la comisaría, investiga delitos, recibe denuncias y custodia el calabozo. |
| **Seguridad y Ley** | **Guardia Rodric** | Guardia de Patrulla | Ronda las calles, separa peleas y acude a la puerta del este en las incursiones. |
| **Seguridad y Ley** | **Vigía del Oeste** | Guarda Fronterizo | Vigila el paso hacia la Llanura Salvaje y alerta de bandidos o bestias. |
| **Hospital y Morgue** | **Dr. Valen** | Médico y Forense | Cura heridas anatómicas, amputa miembros con gangrena, implanta prótesis y hace autopsias. |
| **Capilla del Alba** | **Hermano Anselmo** | Sacerdote del Alba | Oficia la misa dominical, atiende el confesionario los martes y jueves y cuida expósitos. |
| **Tierras Reales (Visitante)** | **Inquisidor Alistair** | Inquisidor Real | Llega cuando hay asesinatos o alerta máxima; interroga testigos y preside juicios públicos. |
| **Mercaderes Reales (Semanales)** | **Maese Casimir y Valeria** | Mercaderes de Caravana | Traen artículos exóticos de las Tierras Reales (*Veneno Paralizante, Ganzúa Maestra, Capa de Camuflaje, Cepo de Acero*). |

## Historia, rasgos, relaciones y secretos por partida (`B6`)
- **6 rasgos de personalidad coherentes** (`NPCData.INITIAL_PERSON_PROFILES`): cada uno de los 21 vecinos fundadores (más Valeria en la caravana real) cuenta con 6 rasgos explícitos en `TraitCatalog.gd` sin contradicciones de ejes, además de 3 rasgos alternativos (`trait_variants`) para que cada partida tenga matices distintos sin romper su carácter.
- **Amistades y rencores de partida** (`NPCData.INITIAL_NPC_RELATIONS` y `FOUNDER_RELATION_VARIANTS`): todos los fundadores arrancan con amistades y rencores cruzados entre sí, más variaciones por semilla (`VillageSecrets.seed_founder_history(vm, seed_val)`) que alteran algunas afinidades y agravios entre partidas.
- **De 2 a 3 secretos propios** (`NPCData.FOUNDER_SECRETS_POOL` y `npc.founder_secrets`): cada fundador guarda 2 o 3 secretos personales elegidos al empezar la partida que pueden descubrirse mediante rumores, confesiones o alta confianza en el diálogo (`NPCDialogue.gd`).
