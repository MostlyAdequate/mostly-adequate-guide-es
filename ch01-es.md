# Capítulo 01: ¿Qué Estamos Haciendo?

## Presentaciones

¡Hola! Soy el Profesor Franklin Frisby, encantado de conocerte. Vamos a pasar algo de tiempo juntos, pues se supone que voy a enseñarte algo de programación funcional. Pero basta de hablar sobre mí, ¿qué hay de ti? Espero que el lenguaje JavaScript te sea por lo menos familiar, que tengas algo de experiencia en programación orientada a objetos, y que te apetezca convertirte en un programador de bandera. No necesitas tener un doctorado en entomología, solo necesitas saber cómo encontrar y matar algunos bugs [*bichos*].

No asumo que tengas ningún conocimiento previo sobre programación funcional porque ya sabemos lo que sucede cuando uno presupone, pero espero que hayas encontrado problemas al trabajar con estados mutables, con efectos secundarios no restringidos, y con diseño sin principios. Ahora que ya nos hemos presentado, sigamos adelante.

El propósito de este capítulo es darte una idea de lo que buscamos cuando escribimos programas funcionales. Para poder entender los próximos capítulos, hemos de tener una idea sobre qué hace que un programa sea *funcional*. De lo contrario, acabaremos garabateando sin rumbo, evitando objetos a toda costa; un esfuerzo sin sentido. Necesitamos una diana a la que lanzar nuestro código, una brújula celestial para cuando las aguas se agiten.

Hay ciertos principios de programación, varios acrónimos, que nos guiarán a través de los túneles oscuros de cualquier aplicación: DRY (don't repeat yourself [*no te repitas*]), YAGNI (ya ain't gonna need it [*no lo vas a necesitar*]), alta cohesión bajo acoplamiento, principio de mínima sorpresa, responsabilidad única, etc.

No voy a alargarme enumerando cada una de las guías que he escuchado a lo largo de los años... La cuestión es que siguen vigentes en un entorno funcional, aunque de forma meramente tangencial a nuestro objetivo final.
Lo que me gustaría que entendieses por ahora, antes de seguir adelante, es cuál será nuestra intención cuando nos aferremos al teclado; nuestro Xanadú funcional.

<!--BREAK-->

## Un Breve Encuentro

Vamos a empezar con un toque de locura. He aquí una aplicación de gaviotas [*seagulls*]. Cuando una bandada [*flock*] se junta con otra [*conjoin*], se convierten en una bandada más grande y cuando se reproducen [*breed*], aumentan por el número de gaviotas con las que se reproducen. Ahora bien, este no pretende ser un buen ejemplo de código orientado a objetos, ojo, este código está aquí para resaltar los peligros de nuestro moderno enfoque basado en asignación. Contempla:

```js
class Flock {
  constructor(n) {
    this.seagulls = n;
  }

  conjoin(other) {
    this.seagulls += other.seagulls;
    return this;
  }

  breed(other) {
    this.seagulls = this.seagulls * other.seagulls;
    return this;
  }
}

const flockA = new Flock(4);
const flockB = new Flock(2);
const flockC = new Flock(0);
const result = flockA
  .conjoin(flockC)
  .breed(flockB)
  .conjoin(flockA.breed(flockB))
  .seagulls;
// 32
```

¿Quién en la faz de la tierra, sería capaz de crear tan espantosa abominación? Es irrazonablemente difícil seguir el rastro del estado interno mientras muta. Y, por si esto fuera poco, ¡la respuesta es incorrecta! Debería ser `16`, pero `flockA` ha sido alterado permanentemente durante el proceso. Pobre `flockA`. ¡Esto es anarquía en la informática! ¡Esto es aritmética de animales salvajes!

Si no entiendes este programa, no pasa nada, yo tampoco lo entiendo. La cuestión es que el estado y los valores mutables son difíciles de seguir, incluso en un ejemplo tan pequeño.

Vamos a intentarlo de nuevo, esta vez con un enfoque más funcional:

```js
const conjoin = (flockX, flockY) => flockX + flockY;
const breed = (flockX, flockY) => flockX * flockY;

const flockA = 4;
const flockB = 2;
const flockC = 0;
const result =
    conjoin(breed(flockB, conjoin(flockA, flockC)), breed(flockA, flockB));
// 16
```

Bueno, esta vez la respuesta es correcta. Con mucho menos código. La anidación de funciones es algo confusa... (pondremos remedio a esto en el capítulo 5). Está mejor, pero profundicemos un poco más. Llamar a las cosas por su nombre tiene sus ventajas. Si hubiéramos examinado nuestras funciones más de cerca, habríamos descubierto que estamos utilizando simples sumas (`conjoin`) y multiplicaciones (`breed`).

Realmente no hay nada especial en estas dos funciones aparte de sus nombres. Vamos a renombrarlas a `multiply` [*multiplicar*] y `add` [*añadir*] para revelar sus verdaderas identidades.

```js
const add = (x, y) => x + y;
const multiply = (x, y) => x * y;

const flockA = 4;
const flockB = 2;
const flockC = 0;
const result =
    add(multiply(flockB, add(flockA, flockC)), multiply(flockA, flockB));
// 16
```
Y con esto obtenemos el conocimiento de los antiguos:

```js
// asociativa
add(add(x, y), z) === add(x, add(y, z));

// conmutativa
add(x, y) === add(y, x);

// identidad
add(x, 0) === x;

// distributiva
multiply(x, add(y,z)) === add(multiply(x, y), multiply(x, z));
```

Ah, sí, esas viejas y fieles propiedades matemáticas serán de ayuda. No te preocupes si no las sabes de memoria. Puede que haya pasado mucho tiempo desde que las estudiamos. Vamos a ver si podemos utilizar estas propiedades para simplificar nuestra pequeña aplicación de gaviotas.

```js
// Línea original
add(multiply(flockB, add(flockA, flockC)), multiply(flockA, flockB));

// Aplicamos la propiedad de identidad para eliminar la suma sobrante
// (add(flockA, flockC) == flockA)
add(multiply(flockB, flockA), multiply(flockA, flockB));

// Aplicamos la propiedad distributiva para llegar a nuestro resultado
multiply(flockB, add(flockA, flockA));
```

¡Brillante! No hemos tenido que escribir ni una pizca de código aparte de las llamadas a las funciones. Hemos incluído las implementaciones de `add` y `multiply` por completitud, pero en realidad no hacía falta escribirlas, puesto que seguro que ya existen en alguna librería.

Seguramente estarás pensando "qué pícaro, al poner este ejemplo". O "en la realidad los programas no son tan simples y no se puede razonar sobre ellos de esta manera". He seleccionado este ejemplo porque la mayoría ya sabemos sumar y multiplicar, y así es fácil ver cómo las matemáticas pueden sernos útiles.

No te desesperes, a lo largo de este libro hablaremos un poco sobre teoría de categorías, teoría de conjuntos, y cálculo lambda para escribir ejemplos de la vida real que consigan la misma elegante simplicidad y que resulten como nuestro ejemplo de la bandada de gaviotas. Tampoco necesitas tener un título en matemáticas, será sencillo y natural, como utilizar otro framework u otra API.

Puede resultar sorprendente oír que se pueden escribir aplicaciones completas y reales utilizando programación funcional tal y como hemos mostrado en el ejemplo anterior. Programas con sólidas propiedades. Programas cortos sobre los que razonar fácilmente. Programas que no reinventan la rueda una y otra vez. La falta de leyes es buena si vas a cometer un crimen, pero en este libro, vamos a reconocer y a obedecer a las leyes de las matemáticas.

Querremos utilizar una teoría en la que todas las piezas tiendan a encajar limpiamente. Querremos representar nuestro problema específico en términos de pequeñas piezas genéricas y combinables, para luego explotar sus propiedades en nuestro propio beneficio. Será necesaria un poco más de disciplina que en el enfoque del "todo vale" de la programación imperativa (más adelante definiremos más precisamente qué es la programación imperativa, pero por ahora considérala cualquier cosa que no sea programación funcional). La recompensa de trabajar dentro de un marco matemático basado en principios verdaderamente te asombrará.

Hemos visto un destello de nuestra estrella del norte funcional, pero hay unos cuantos conceptos que necesitamos entender antes de realmente poder emprender nuestro viaje.

[Capítulo 2: Funciones de Primera Clase](ch02-es.md)
