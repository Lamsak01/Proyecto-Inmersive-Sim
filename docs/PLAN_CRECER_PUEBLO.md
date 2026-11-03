# Plan: crecer el pueblo (bloques V)

Estado: **pendiente de aprobación**. Paso 9 de `docs/VISION_Y_FUTURO.md`. La meta final es una ciudad de unos 100 vecinos.
Este paso es el primer escalón: que el pueblo pueda crecer (o encogerse) solo, sin que el juego se arrastre.
Regla del usuario: nada «porque sí». La gente llega o se va según cómo le vaya al pueblo, no por fecha.

## Qué existe hoy

- 18 vecinos en 5 casas de familia, la posada, la capilla y los edificios de la autoridad. El mapa está colocado a mano.
- Solo llega gente para **cubrir huecos**: una autoridad, la posadera o un oficio que se quedó sin nadie. Como mucho
  llegan 2 al día, caminando desde el borde del mapa, y el generador les da nombre y rasgos.
- Quien no puede pagar la posada acaba en un campamento en las afueras.
- No hay nacimientos ni niños. No hay nobles: se aplazaron a este paso.
- Todos los vecinos se simulan a pleno detalle siempre, estén cerca o lejos. Con 18 vale; con 40 o 100 no se sabe.

## Bloques

- **V1 – Medir el rendimiento.** Una prueba sin pantalla con 18, 40, 70 y 100 vecinos que mida cuánto tarda cada
  fotograma y cada día de juego. Sin esto, todo lo demás es a ciegas.
- **V2 – Simulación simplificada para quien esté lejos.** Los vecinos fuera de la pantalla piensan y se mueven con
  menos frecuencia: sus necesidades, el trabajo y las charlas se resuelven a grandes rasgos, sin calcular cada paso.
  Al acercarte, vuelven al detalle completo sin que se note el salto. Los sistemas sociales (chismes, deseos, secta,
  crónica) siguen igual: ya funcionan por horas y días.
- **V3 – Llegadas y marchas según el pueblo.** El pueblo tiene un **atractivo**: trabajo libre, vivienda libre, poca
  crisis, buena fama y seguridad. Si es alto, llegan forasteros a quedarse, ya sean jornaleros, artesanos o familias.
  Si el pueblo va mal (crisis larga, pobreza, crímenes, un escándalo), algunos se marchan: primero los que no tienen
  casa ni lazos. Se ve en la crónica y en los chismes.
- **V4 – Vivienda.** Unos **solares** alrededor del pueblo donde se pueden levantar casas nuevas, reutilizando los
  dibujos que ya hay. Las construye el carpintero, con el oro de quien llega o como obra pública pagada con las arcas.
  Mientras tanto, la gente vive en la posada o en el campamento.
- **V5 – Oficios y servicios nuevos.** Dos o tres oficios que tengan sentido con lo que ya existe (ver decisión 2), más
  **jornaleros**: trabajo sencillo y mal pagado para quien llega sin oficio.
- **V6 – Los nobles.** Un **señor del valle** y su familia, en una casa señorial en un solar del pueblo. Son muy ricos,
  cobran rentas por las tierras y pesan en las elecciones. Encajan con los «ricos aburridos» de la secta.
- **V7 – Medición y tests.** Un test por comportamiento, al final. La sonda cuenta la población, las llegadas y
  marchas, las casas construidas y la velocidad.

## Decisiones que necesito

1. **Tamaño en este paso:** ¿hasta cuántos vecinos? Recomiendo un techo de unos **40**, para medir bien antes de ir a 100.
2. **Oficios nuevos:** ¿cuáles? Algunas opciones son panadero, sastre, barbero y casa de baños, maestro con escuela,
   leñador o minero. Recomiendo **panadero, sastre y casa de baños**, más los jornaleros.
3. **Nacimientos:** ¿parejas que tienen hijos que crecen? Es lo más orgánico, pero exige niños (dibujos, rutinas y
   edades) y es un sistema grande. Recomiendo **dejarlo para después** y crecer de momento con quien llega.
4. **Nobles:** ¿entran en este paso (V6) o más adelante? Recomiendo que entren, pero al final del paso.
5. **El mapa:** ¿solares nuevos en los bordes del pueblo actual, o una zona nueva (un barrio)? Recomiendo **solares en
   los bordes**, porque no cambia lo que ya funciona.
6. **Cómo hacerlo:** recomiendo **V1 y V2 primero**, con una medición, y el resto después. Si el rendimiento no da, hay
   que saberlo antes de traer a más gente.

## Riesgos

- **Rendimiento.** Es el gran riesgo del paso: por eso V1 y V2 van primero.
- **El dibujo.** Casas y oficios nuevos reutilizan dibujos que ya existen; harán falta dibujos propios más adelante.
- **El equilibrio.** Más gente cambia la economía, las elecciones, los bandos y la secta. Lo mediré con la sonda.
- **Las partidas guardadas.** Los vecinos y casas nuevos tienen que guardarse y cargarse bien. Habrá un test para eso.

## Nota para el futuro

El usuario ampliará **el sistema de sectas** más adelante. Lo que se haga aquí (nobles, ricos, llegadas y marchas) debe
dejarle sitio.
