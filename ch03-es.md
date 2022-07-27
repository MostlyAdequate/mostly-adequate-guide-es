# Capítulo 3: Pura Felicidad con Funciones Puras

## Oh Ser Puro Otra Vez

Una cosa que necesitamos para comenzar correctamente es la idea de una función pura.

>Una función pura es una función que, dada la misma entrada, siempre devolverá la misma salida y no contiene ningún efecto secundario observable.

Toma por ejemplo `slice` y `splice`. Son dos funciones que hacen exactamente lo mismo - eso sí, de una forma muy diferente, pero lo mismo al fin y al cabo. Decimos que `slice` es *pura* porque siempre devuelve la misma salida para cada entrada, garantizado. `splice`, sin embargo, se comerá su array y lo escupirá cambiado para siempre, lo cual es un efecto observable.

```js
const xs = [1,2,3,4,5];

// pura
xs.slice(0,3); // [1,2,3]

xs.slice(0,3); // [1,2,3]

xs.slice(0,3); // [1,2,3]


// impura
xs.splice(0,3); // [1,2,3]

xs.splice(0,3); // [4,5]

xs.splice(0,3); // []
```

En programación funcional, no nos gustan las funciones poco manejables como `splice`, que muta datos. Esto nunca nos servirá, ya que nos esforzamos por tener funciones en las que podamos confiar, que devuelven siempre la misma salida, no funciones que dejan un desastre a su paso como `splice`.

Veamos otro ejemplo.

```js
// impuro
let minimum = 21;
const checkAge = age => age >= minimum;

// puro
const checkAge = (age) => {
  const minimum = 21;
  return age >= minimum;
};
```

En la parte impura, `checkAge` depende de la variable mutable `minimum` para determinar el resultado. En otras palabras, depende del estado del sistema, lo que es decepcionante porque incrementa la [carga cognitiva](https://es.wikipedia.org/wiki/Teoría_de_la_carga_cognitiva) por la introducción de un entorno externo.

Puede que no parezca mucho en este ejemplo, pero esta dependencia sobre el estado es una de las mayores contribuciones a la complejidad de los sistemas(http://www.curtclifton.net/storage/papers/MoseleyMarks06a.pdf). Esta `checkAge` puede devolver un resultado diferente dependiendo de factores externos a la entrada, lo que no solo la descalifica como pura, sino que también pone a nuestra mente a prueba cada vez que razonamos sobre el software.

Por otro lado, su forma pura, es completamente auto suficiente. También podemos hacer que  `minimum` sea inmutable, lo que preserva la pureza ya que el estado nunca cambia. Para hacer esto, debemos crear un objeto para poder congelarlo.

```js
const immutableState = Object.freeze({ minimum: 21 });
```

## Los Efectos Secundarios Pueden Incluir... 

Miremos más hacia estos "efectos secundarios" para mejorar nuestra intuición. Entonces, ¿qué es este indudablemente nefasto *efecto secundario* mencionado en la definición de *función pura*? Nos referiremos a *efecto* como a cualquier cosa que ocurra en nuestra computación que no sea el cálculo de un resultado.

No hay nada intrínsecamente malo acerca de los efectos y los usaremos por todas partes en futuros capítulos. Es la parte *secundaria* la que tiene connotaciones negativas. El agua por sí misma no es una incubadora de larvas, es el *estancamiento* lo que produce los enjambres, y te aseguro que los efectos *secundarios* son un criadero similar en tus propios programas.

>Un *efecto secundario* es un cambio de estado del sistema o una *interacción observable* con el mundo exterior que ocurre durante el cálculo de un resultado. 

Los efectos secundarios pueden incluir, pero no limitarse a

  * cambiar el sistema de ficheros
  * insertar un registro en una base de datos
  * hacer una llamada http
  * mutaciones
  * imprimir en pantalla / loguear
  * obtener entrada del usuario
  * consultar el DOM
  * acceder al estado del sistema
  
Y el listado sigue y sigue. Cualquier interacción con el mundo exterior de una función es un efecto secundario, lo que es un hecho que puede llevarte a sospechar de la practicidad de programar sin ellos. La filosofía de la programación funcional postula que los efectos secundarios son la causa principal de incorrecciones en el comportamiento.

No es que tengamos prohibido usarlos, más bien queremos contenerlos y ejecutarlos de manera controlada. Aprenderemos como hacerlo cuando lleguemos a los functores y mónadas en capítulos posteriores, pero por ahora, trataremos de mantener estas insidiosas funciones apartadas de las puras.

Los efectos secundarios descalifican a una función para ser *pura* y tiene sentido: las funciones puras, por definición, deben devolver siempre la misma salida dada la misma entrada, lo que no es posible garantizar cuando se están manejando asuntos del exterior de nuestra función local.

Veamos con más detalle por qué insistimos en la misma salida por entrada. Levantaos el cuello de las camisas, vamos a ver algo de matemáticas de octavo grado. 

## Matemáticas de Octavo Grado

De mathisfun.com:

> Una función es una relación especial entre valores: 
> Cada uno de sus valores de entrada devuelve exactamente un valor de salida.

En otras palabras, es solo una relación entre dos valores: la entrada y la salida. Aunque cada entrada tiene exactamente una salida, esa salida no tiene que ser necesariamente única por cada entrada. El siguiente diagrama muestra un función perfectamente válida de `x` a `y`;

<img src="images/function-sets.gif" alt="function sets" />(http://www.mathsisfun.com/sets/function.html)

Para contrastar, el siguiente diagrama muestra una relación que *no* es una función ya que el valor de entrada `5` apunta a varias salidas: 

<img src="images/relation-not-function.gif" alt="relation not function" />(http://www.mathsisfun.com/sets/function.html)

Las funciones pueden ser descritas como un set de pares con su posición (entrada, salida): `[(1,2), (3,6), (5,10)]` (Parece que esta función dobla su entrada).

O tal vez una tabla: 
<table> <tr> <th>Entrada</th> <th>Salida</th> </tr> <tr> <td>1</td> <td>2</td> </tr> <tr> <td>2</td> <td>4</td> </tr> <tr> <td>3</td> <td>6</td> </tr> </table>

O incluso como un gráfico con `x` como la entrada e `y` como la salida:

<img src="images/fn_graph.png" width="300" height="300" alt="function graph" />

No hay necesidad de detalles de implementación si la entrada dicta la salida. Ya que las funciones son simplemente mapeos de entrada a salida, uno puede simplemente apuntar los valores en objetos y ejecutarlos con `[]` en lugar de `()`.

```js
const toLowerCase = {
  A: 'a',
  B: 'b',
  C: 'c',
  D: 'd',
  E: 'e',
  F: 'f',
};
toLowerCase['C']; // 'c'

const isPrime = {
  1: false,
  2: true,
  3: true,
  4: false,
  5: true,
  6: false,
};
isPrime[3]; // true
```

Por supuesto, puedes querer calcular en lugar de apuntar valores a mano, pero esto ilustra una forma diferente de pensar sobre las funciones. (Debes estar pensando "¿qué pasa con las funciones con múltiples paramentos?". Ciertamente, esto presenta un pequeño inconveniente cuando se piensa en términos matemáticos. Por ahora, podemos empaquetarlos en un array o simplemente pensar que como entrada pasamos el objeto `argumentos`. Cuando aprendamos sobre *currying*, veremos cómo podemos modelar directamente la definición matemática de una función.)

Aquí viene la dramática revelación: Las funciones puras *son* funciones matemáticas y ellas son todo sobre lo que trata la programación funcional. Programar con estos pequeños ángeles puede tener grandes beneficios. Veamos algunas de las razones por las que estamos dispuestos a recorrer tan grandes distancias para preservar la pureza.

## Los Argumentos Para La Pureza

### Almacenable en Caché

Para empezar, las funciones puras siempre pueden ser cacheadas por su entrada. Esto se hace típicamente con una técnica llamada memoización: 

```js
const squareNumber = memoize(x => x * x);

squareNumber(4); // 16

squareNumber(4); // 16, devuelve lo cacheado para entrada 4

squareNumber(5); // 25

squareNumber(5); // 25, devuelve ñp cacheado para entrada 5
```

Aquí hay una implementación simplificada, aunque haya disponibles otras mucho más robustas.

```js
const memoize = (f) => {
  const cache = {};

  return (...args) => {
    const argStr = JSON.stringify(args);
    cache[argStr] = cache[argStr] || f(...args);
    return cache[argStr];
  };
};
```

Algo a tener en cuenta es que puedes transformar funciones impuras en puras retrasando su evaluación: 

```js
const pureHttpCall = memoize((url, params) => () => $.getJSON(url, params));
```

Lo interesante aquí es que realmente no hacemos la llamada http - en su lugar devolvemos una función que lo hará cuando sea llamada. Esta función es pura porque siempre devolverá la misma salida dada la misma entrada: la función que hará esa llamada http en particular dados `url` y `params`. 

Nuestra función `memoize` funciona bien, aunque no cachea los resultados de la llamada http, si no que cachea la función generada.

Esto todavía no es muy útil, pero pronto aprenderemos algunos trucos que harán que lo sea. La lección es que podemos cachear cualquier función sin importar cuan destructiva parezca.

### Portables / Auto-documentadas

Las funciones puras son completamente auto contenidas. Todo lo que necesita la función se le pasa en bandeja de plata. Considera esto por un momento... ¿Cómo puede esto ser beneficioso? Para empezar, las dependencias de la función son explícitas y por lo tanto más fáciles de ver y entender - nada extraño sucede a escondidas.

```js
// impura
const signUp = (attrs) => {
  const user = saveUser(attrs);
  welcomeUser(user);
};

// pura
const signUp = (Db, Email, attrs) => () => {
  const user = saveUser(Db, attrs);
  welcomeUser(Email, user);
};
```

Este ejemplo demuestra que la función pura debe ser honesta acerca de sus dependencias y, como tal, debe decirnos exactamente qué es lo que hace. Solo por su firma, sabemos que usará una `Db`, `Email`, y `attrs` lo que ya es algo por lo menos interesante.

Aprenderemos a hacer funciones puras como esta sin limitarnos a solo aplazar la evaluación, pero debería quedar claro que la forma pura es mucho más informativa que su escurridiza contraparte que trama quién sabe qué.

Algo más a tener en cuenta es que estamos forzados a "inyectar" dependencias, o pasarlas como argumentos, lo que hace a nuestra aplicación más flexible, pues hemos parametrizado nuestra base de datos o cliente de email o lo que sea (no te preocupes, veremos una manera de hacer esto menos tedioso de lo que parece). Si decidimos usar una Db diferente solo necesitaremos llamar a nuestra función con ella. Si nos encontramos escribiendo una nueva aplicación en la que nos gustaría reutilizar esta confiable función, simplemente tendremos que pasar a esta función el `Db` e `Email` que tengamos en ese momento.

En un entorno JavaScript, portabilidad puede significar serializar y enviar funciones por un socket. Puede significar ejecutar toda nuestra aplicación con Web Workers. La portabilidad es un rasgo poderoso.

Al contrario de los "típicos" métodos y procedimientos de la programación imperativa profundamente enraizados en sus entornos a través de estado, dependencias, y efectos, las funciones puras se pueden ejecutar en cualquier sitio que desee nuestro corazón.

¿Cuándo fué la última vez que copiaste un método en una nueva app? Una de mis citas favoritas proviene del creador de Erlang, Joe Armstrong: "El problema con los lenguajes orientados a objetos es todo ese entorno implícito que llevan a todos lados con ellos. Querías una banana pero tienes un gorila sosteniendo una banana... y la jungla entera". 

### Testeable

Después de lo anterior, nos damos cuenta de que las funciones puras hacen que el testing sea mucho más fácil. No necesitamos mockear una pasarela de pagos "real" o configurar y verificar el estado del mundo después de cada test. Simplemente pasamos la entrada a la función y verificamos su salida.

De hecho, encontramos que la comunidad funcional está descubriendo nuevas herramientas de pruebas que pueden bombardear nuestra función con entradas generadas y verificar que sus propiedades se mantienen en la salida. Está fuera del alcance de este libro, pero os animo encarecidamente a que busquéis y probéis *Quickcheck* - una herramienta de pruebas que está hecha a medida para un entorno puramente funcional.

### Comprensible

Muchos creen que la mayor victoria cuando trabajas con funciones puras es la *transparencia referencial*. Un trozo de código es referencialmente transparente cuando puede ser sustituido por su valor resultante sin cambiar el comportamiento del programa.

Dado que las funciones puras no tienen efectos secundarios, tan solo pueden influir en el comportamiento de un programa a través de sus valores de salida. Además, puesto que sus valores de salida pueden calcularse de forma fiable con tan solo utilizar sus valores de entrada, las funciones puras siempre mantendrán la transparencia referencial. Veamos un ejemplo.

```js
const { Map } = require('immutable');

// Alias: p = player, a = attacker, t = target
const jobe = Map({ name: 'Jobe', hp: 20, team: 'red' });
const michael = Map({ name: 'Michael', hp: 20, team: 'green' });
const decrementHP = p => p.set('hp', p.get('hp') - 1);
const isSameTeam = (p1, p2) => p1.get('team') === p2.get('team');
const punch = (a, t) => (isSameTeam(a, t) ? t : decrementHP(t));

punch(jobe, michael); // Map({name:'Michael', hp:19, team: 'green'})
```

`decrementHP`, `isSameTeam` y `punch` son todas puras y por tanto referencialmente transparentes. Podemos usar la técnica llamada *razonamiento ecuacional*, donde podemos sustituir "iguales por iguales" para razonar sobre el código. Es un poco como evaluar manualmente el código sin tener en cuenta las peculiaridades de la evaluación programática. Usando transparencia referencial, juguemos con este código un poco.

Primero reemplazamos la función `isSameTeam`.

```js
const punch = (a, t) => (a.get('team') === t.get('team') ? t : decrementHP(t));
```

Ya que nuestros datos son inmutables, podemos simplemente reemplazar los equipos por sus valores reales

```js
const punch = (a, t) => ('red' === 'green' ? t : decrementHP(t));
```

Vemos que en este caso la condición es falsa por lo que podemos quitar toda la rama del `if`

```js
const punch = (a, t) => decrementHP(t);
```

Y si también reemplazamos `decrementHP`, vemos que, en este caso, `punch` se convierte en una llamada para reducir `hp` en 1.

```js
const punch = (a, t) => t.set('hp', t.get('hp') - 1);
```

Esta habilidad para razonar acerca del código es excelente para en general refactorizarlo y entenderlo. De hecho, hemos utilizado esta técnica para refactorizar nuestro programa de bandada de gaviotas. Usamos razonamiento ecuacional para aprovechar las propiedades de adición y multiplicación. De hecho, utilizaremos estas técnicas a lo largo de todo el libro.

### Código Paralelo

Finalmente, y aquí está el golpe de grácia, podemos ejecutar en paralelo cualquier función pura, ya que no necesita acceder a memoria compartida y no puede, por definición, tener una condición de carrera debido a algún efecto secundario.

Esto podría usarse tanto en un servidor con entorno js e hilos de ejecución como en un navegador con web workers, aunque la cultura actual parece evitarlo debido a lo complejo que resulta tratar con funciones impuras.

## En Resumen

Hemos visto qué son las funciones puras y por qué nosotros, como programadores funcionales, creemos que son extraordinarias. De aquí en adelante, nos esforzaremos en escribir todas nuestras funciones de una forma pura. Necesitaremos algunas herramientas adicionales para ayudarnos, pero mientras tanto, trataremos de separar las funciones impuras del resto del código puro. 

Escribir programas con funciones puras es algo laborioso sin tener algunas herramientas extra en nuestro cinturón. Hemos de hacer malabares con los datos pasando argumentos por todas partes, tenemos prohibido utilizar estado y sin mencionar lo de los efectos secundarios. ¿Cómo afrontar la escritura de estos programas de masoquista? Vamos a obtener una nueva herramienta llamada curry.

[Capítulo 4: Currying](ch4-es.md)
