# Boceto: rehacer los edificios antiguos (para que el usuario lo corrija)

> Claude Code, 2026-11-11. Petición del usuario: «que TODOS los edificios tengan el nivel de detalle de la trattoria».
> Ya rehechos (no se tocan): posada El Jabalí, trattoria Il Corvo, comisaría y calabozo, hospital y morgue, biblioteca,
> botica Raíz Verde, capilla, molino viejo, escuela (aula con pizarra). Este boceto cubre **los 11 que faltan**.
> Boceto anterior de referencia: `BOCETOS_EDIFICIOS.md` §8–9 (2026-11-08).

## 0. El problema del tamaño (decidir antes de empezar)

Hoy cada edificio antiguo es **una sala de 6 × 4 m** (tiendas 116×76 px, casas 112×78, cívicos 128×96) y están
pegados unos a otros (10 px entre solares). Con esa huella no caben «varias salas con sentido». Tres caminos:

| Camino | Qué se hace | Resultado | Coste |
|---|---|---|---|
| **A. Dos plantas** (recomendado) | Planta baja = tienda/taller/sala; **piso alto = dormitorios**, con escalera, como la posada y el altillo de tu casa (ya existe el mecanismo de pisos) | Cada edificio gana el doble de espacio sin mover nada del mapa; se ve vida en dos niveles | medio por tipo de edificio (la escalera y las rutas de los vecinos se hacen una vez y se reutilizan) |
| B. Esperar al mapa 3× | Primero agrandar el mapa; luego edificios más grandes de una planta | Más salas por planta, pero todo se rehace después del mapa | poco ahora, mucho luego |
| C. Tabiques en la huella actual | Dividir la sala en 2 (tienda/trastienda o sala/alcoba) | Cuartos minúsculos (2 × 4 m), como los que no te gustaron en la posada | poco, pero resultado flojo |

Propuesta: **A** para tiendas, casas y edificios cívicos; **A + huella algo mayor** solo para la mansión (es la única con
sitio alrededor). Cuando llegue el mapa 3×, los edificios se trasladan enteros (ya tienen anclas) sin rehacerlos.

## 1. Las 4 tiendas-taller (planta baja taller, piso alto vivienda del maestro y su pariente)

Todas: portón ancho de taller con tablones en «Z», escaparate lateral con la mercancía, letrero colgante, farol de
baquelita en la puerta. Planta baja abierta al público con el **mostrador mirando a la puerta**; al fondo, escalera al
piso alto con 2 camas, mesa, baúl y una ventana. (Los maestros duermen hoy en «residencias» aparte: ver §2.)

1. **Herrería y Armería «Yunque Gris»** (Thoran y Kael). Baja: fragua encendida con chimenea de piedra, yunque, cubo de
   temple, fuelle, armero con espadas/picos/hachas colgados, mostrador con balanza, pila de carbón. Ruido de martillo
   de 8 a 18. Alto: dormitorio de padre e hijo. El jugador: comprar/arreglar armas, encargar piezas.
2. **Carnicería y Peletería «El Colmillo»** (Garrick y Lina). Baja: tabla de corte con cuchillas, ganchos con piezas
   colgadas, mostrador con balanza, barril de salmuera, bastidor de pieles estirándose y cubo de curtido (Lina) en el
   rincón trasero. Alto: dormitorio de los hermanos. El jugador: vender carne y pieles, comprar.
3. **Carpintería y Aserradero «Roble Viejo»** (Bram y Mila). Baja: banco de carpintero con sierra y cepillo, tablones
   apilados, caballete, serrín en el suelo, muebles a medio hacer (silla, puerta), pared de herramientas; en el rincón
   de Mila, torno pequeño y piezas de ebanistería. Alto: dormitorio. El jugador: encargar muebles/obras, comprar tablas.
4. **Pescadería y Molino «Aguas Claras»** (Marlo y Nora). Baja: mostrador de piedra con pescado sobre hielo/sal, redes
   colgadas y nasas (Nora las remienda en un banco), cubos, barril de salazón; rueda de molino pequeña y sacos de harina
   al fondo (es también molino). Alto: dormitorio. El jugador: comprar pescado y harina, vender capturas.

## 2. Las 4 «residencias» de esas familias (hoy casas aparte con 2 camas)

Con el camino A, estas familias **dormirían encima de su tienda** y las 4 casas quedan libres para: **(a)** alquilarlas
a vecinos sin casa (los 3 huéspedes de la posada y recién llegados) o **(b)** venderlas al jugador. Propuesta: (a).
Si prefieres mantenerlas como casas de las familias, se rehacen como casa de vecino (§5) y el piso alto de las tiendas
queda como almacén.

## 3. Edificios cívicos

5. **Ayuntamiento del Valle** (alcalde Aurelio). Baja: salón de plenos con estrado, atril de decretos, bancos para
   vecinos, tablón de bandos y mostrador del censo. Alto: despacho del alcalde (escritorio con el Libro de Cuentas,
   sillón, bandera del valle, archivadores de escrituras) y **cámara de las arcas** cerrada con llave (cofre municipal,
   reja). El jugador: comprar solares/hipotecas, consultar censo y cuentas, presentarse a alcalde; de noche, forzar
   las arcas o leer papeles.
6. **Albergue del Alba** (de la Fe; para pobres y recién llegados). Una planta grande sin dividir: 6 catres en fila
   con mantas de lana, mesa larga con escudillas, olla al fuego, armario de mantas, imagen del Alba; el padre Anselmo
   pasa por la tarde. Alto: no. El jugador: dormir gratis (mala cama), hablar con los que no tienen casa.
7. **Posada Humilde «El Candil»** (competencia barata del Jabalí). Baja: sala pequeña con 3 mesas, barra corta con
   candiles, chimenea, posadero. Alto: 2 cuartos de huéspedes con 2 camas cada uno y una cortina por puerta. El jugador:
   dormir barato, oír rumores de forasteros.

## 4. Casas nobles

8. **Mansión del Señor del Valle** (señor, señora, heredero; criada Lina del Caso I). Huella algo mayor. Baja: recibidor
   con escalera de doble tramo, gran salón con chimenea, mesa de banquete con candelabros, retratos; **despacho** con el
   gabinete forzado del Caso I (ya existe), sello de la casa y librería; cocina de servicio. Alto: alcoba principal con
   dosel, cuarto del heredero, cuarto de invitados, cuartito de la criada. Portón blasonado con clavos de bronce.
9. **Casa Grande de los Rentistas** (2 rentistas). Baja: salón con mesa de cobro de rentas (libro y balanza), sillones,
   vitrina; Alto: 2 alcobas. Puerta noble con marco de cantería.

## 5. Casas de vecino (plantilla para todos los solares que se construyan)

10. **Casa de vecino** (solares n/m/u/e, hoy casi todos «solar libre» en la demo). Baja: sala con fogón, mesa con
    sillas, alacena, banco de trabajo del oficio de la familia, perchero y leñera junto a la puerta. Alto (si tiene
    altillo): 2 camas con mesilla y baúl; sin altillo, las camas van al fondo de la sala tras una cortina. Puerta de
    tablas verticales con picaporte de hierro; cada casa con un color de contraventanas distinto.
11. **Tu casa** (ya tiene altillo y sótano): solo acabados: cocina de verdad, mesa de trabajo del detective con el
    tablero del caso en la pared, perchero, cofre, y la cama arriba.

## 6. Orden propuesto y coste

1. Mecanismo común «planta alta con escalera» para cualquier edificio (1 vez): medio.
2. Las 4 tiendas-taller: medio cada una (4 tardes). 3. Mansión y casa de rentistas: medio. 4. Ayuntamiento, albergue,
   El Candil: poco–medio. 5. Plantilla de casa de vecino + tu casa: poco–medio.
Cada edificio se cierra con foto por dentro y por fuera, prueba de puertas y la simulación de atascos.

## 7. Decidido por el usuario (2026-11-11)
- **Camino B**: primero el mapa ×3 (`PLAN_MAPA_X3.md`); después los edificios, con huella ×2 y varias salas por planta.
- Las familias artesanas **duermen encima de su tienda**; las 4 residencias libres las ocupan **vecinos nuevos desde el día 1** (no se alquilan). Oficios por decidir.
- Los edificios se planificarán con el usuario (salas y usos de §1–§5 como punto de partida) cuando el mapa esté estirado.
