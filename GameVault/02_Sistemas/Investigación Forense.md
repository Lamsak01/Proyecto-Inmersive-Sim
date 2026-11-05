---
tipo: "sistema"
area: "crimen"
estado: "implementado"
codigo: "P2"
tags:
  - "medicina"
  - "crimen"
  - "sistema"
fuente: "Biblia §5.3"
---
# Investigación Forense

> Sección original: *Investigación Forense y Crímenes Complejos (`P2 Forensics`)*

Todas las mecánicas forenses exigen estar cerca o tener acceso real y ninguna opción del diálogo revela quién es el culpable si el jugador no lo ha descubierto antes:

| Código | Mecánica Forense | Cómo Funciona y Contramedidas |
|---|---|---|
| `P2.1` | **Plantar prueba falsa** | Coloca un objeto incriminatorio en casa de un vecino; si alguien te ve, se vuelve en tu contra. |
| `P2.2` | **Comprar coartada falsa** | Un vecino amigo o sobornado declara que estuviste con él a la hora del crimen. |
| `P2.3` | **Intimidar testigo** | Amenaza a quien te vio (tirada de Combate/Agresividad); si falla, te denuncia al instante (`+25` búsqueda). |
| `P2.4` | **Sicario por encargo** | Un vecino con odio extremo y oro contrata a un matón para atacar a su rival de noche. |
| `P2.5` | **Veneno lento y autopsia** | El veneno en comida o bebida actúa al día siguiente; el **Dr. Valen** sólo lo detecta tras examinar el cuerpo en la Morgue. |
| `P2.6` | **Incriminar a un rival** | Desviar las sospechas del expediente policial hacia alguien con móvil creíble. |
| `P2.7` | **Mover/arrastrar cadáver** | Esconder el cuerpo en el río, bosque o alcantarillas antes de que alguien lo vea. |
| `P2.8` | **Confesión ebrio o febril** | Un asesino con culpa alta que bebe en la taberna o delira con fiebre puede soltar una frase incriminatoria **sólo si estás a ≤ 140 px**. |
| `P2.9` | **Chivo expiatorio** | El comisario corrupto o presionado cierra el caso culpando a un forastero o marginado. |
| `P2.10` | **Emboscada nocturna** | Avisar a la guardia para tender una trampa nocturna a un criminal reincidente. |
| `P2.11` | **Fregar sangre con lejía** | Limpiar las manchas de sangre de la escena del crimen (exige **doble confirmación `[E]`** y lejía de la botica). |
| `P2.12` | **Sobornar autopsia** | Pagar al médico (si su honradez lo permite) para que certifique muerte natural. |
| `P2.13` | **Póliza de seguro de vida** | Algunos vecinos firman pólizas (incluidas pólizas inocentes de padres o esposos precavidos, para que ver una póliza nunca destripe un crimen). Si el asegurado muere y el beneficiario la cobra, el pago sale de las [[Arcas Municipales]] y despierta sospechas del Inquisidor. |
| `P2.14` | **Trucar hora de la muerte** | Calentar o enfriar el cuerpo antes de la autopsia para confundir el *rigor mortis* y validar una coartada. |
| `P2.15` | **El «limpiador» nocturno** | Pagar al perista para que haga desaparecer pruebas físicas antes del amanecer. |
| `P2.16` | **Crimen por imitación (*copycat*)** | Un asesino imita el método de otro crimen reciente para que culpen al mismo autor. |
| `P2.17` | **Confesión forzada** | Arrancar una confesión firmada mediante chantaje (con `20%` de riesgo de que se rebele y te delate). |

## Notas de diseño
-
