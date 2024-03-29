# Capítulo 03: Pura Felicidad con Funciones Puras

## Oh Ser Puro Otra Vez

Una cosa que necesitamos para comenzar correctamente es la idea de una función pura.

>Una función pura es una función que, dada la misma entrada, siempre devolverá la misma salida y que no contiene ningún efecto secundario observable.

Toma por ejemplo `slice` y `splice`. Son dos funciones que hacen exactamente lo mismo, eso sí, de una forma muy diferente, pero lo mismo al fin y al cabo. Decimos que `slice` es *pura* porque siempre devuelve la misma salida para cada entrada, garantizado. `splice`, sin embargo, se comerá su array y lo escupirá cambiado para siempre, lo cual es un efecto observable.

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

En programación funcional, no nos gustan las funciones poco manejables como `splice`, que muta los datos. Esto no es aceptable, ya que nos esforzamos por tener funciones en las que podamos confiar, que devuelvan siempre la misma salida, no funciones que dejan un desastre a su paso como `splice`.

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

En la parte impura, `checkAge` depende de la variable mutable `minimum` para determinar el resultado. En otras palabras, depende del estado del sistema, lo que es decepcionante porque incrementa la [carga cognitiva](https://es.wikipedia.org/wiki/Teoría_de_la_carga_cognitiva) al introducir un entorno externo.

Puede que no parezca mucho en este ejemplo, pero esta dependencia sobre el estado es una de las mayores contribuciones a la complejidad de los sistemas(http://www.curtclifton.net/storage/papers/MoseleyMarks06a.pdf). Esta `checkAge` puede devolver un resultado diferente dependiendo de factores externos a la entrada, lo que no solo la descalifica como pura, sino que además pone a prueba a nuestra mente cada vez que razonamos sobre el software.

Por otro lado, su forma pura, es completamente autosuficiente. También podemos hacer que  `minimum` sea inmutable, lo que preserva la pureza, ya que el estado nunca cambia. Para hacer esto, debemos crear un objeto para poder congelarlo.

```js
const immutableState = Object.freeze({ minimum: 21 });
```

## Los Efectos Secundarios Pueden Incluir...

Veamos más cosas sobre estos "efectos secundarios" para mejorar nuestra intuición. Entonces, ¿qué es este indudablemente nefasto *efecto secundario* mencionado en la definición de *función pura*? Nos referiremos a *efecto* como a cualquier cosa que ocurra en nuestra computación que no sea calcular un resultado.

No hay nada intrínsecamente malo acerca de los efectos y los usaremos por todas partes en futuros capítulos. Es la parte *secundaria* la que tiene connotaciones negativas. El agua por sí sola no es una incubadora de larvas, es su *estancamiento* lo que produce los enjambres, y te aseguro que en tus propios programas los efectos *secundarios* son un criadero similar.

>Un *efecto secundario* es un cambio en el estado del sistema, o una *interacción observable* con el mundo exterior, que sucede durante el cálculo de un resultado. 

Los efectos secundarios pueden incluir, pero no limitarse a

  * cambiar el sistema de ficheros
  * insertar un registro en una base de datos
  * hacer una llamada http
  * mutar valores
  * imprimir en pantalla/registro
  * obtener entrada del usuario
  * consultar el DOM
  * acceder al estado del sistema
  
Y el listado sigue y sigue. Cualquier interacción de una función con el mundo exterior es un efecto secundario, hecho que puede llevarte a sospechar de la practicidad de programar sin ellos. La filosofía de la programación funcional postula que los efectos secundarios son la principal causa de las incorrecciones en el comportamiento.

No es que tengamos prohibido usarlos, más bien queremos contenerlos y ejecutarlos de manera controlada. Aprenderemos como hacerlo cuando lleguemos a los funtores y mónadas en capítulos posteriores, pero por ahora, trataremos de mantener a estas insidiosas funciones apartadas de las puras.

Los efectos secundarios descalifican a una función para ser *pura* y tiene sentido: las funciones puras, por definición, deben devolver siempre la misma salida dada la misma entrada, lo que no es garantizable cuando se manejan asuntos externos a nuestra función local.

Veamos con más detalle por qué insistimos en lo de la misma salida para cada entrada. Levantaos el cuello de las camisas, vamos a ver algo de matemáticas de octavo grado [*estudiantes de entre 13 y 14 años].

## Matemáticas de Octavo Grado

De mathisfun.com:

> Una función es una relación especial entre valores: 
> Cada uno de sus valores de entrada devuelve exactamente un valor de salida.

En otras palabras, tan solo es una relación entre dos valores: la entrada y la salida. Aunque cada entrada tiene exactamente una salida, esa salida no tiene que ser necesariamente única por cada entrada. El siguiente diagrama muestra una función de `x` a `y` perfectamente válida;

<img src="images/function-sets.gif" alt="conjuntos de funciones" />(http://www.mathsisfun.com/sets/function.html)

Para contrastar, el siguiente diagrama muestra una relación que *no* es una función, ya que el valor de entrada `5` apunta a varias salidas: 

<img src="images/relation-not-function.gif" alt="relación que no es una función" />(http://www.mathsisfun.com/sets/function.html)

Las funciones pueden ser descritas como un conjunto de pares con la posición (entrada, salida): `[(1,2), (3,6), (5,10)]` (Parece que esta función dobla su entrada).

O tal vez una tabla: 
<table> <tr> <th>Entrada</th> <th>Salida</th> </tr> <tr> <td>1</td> <td>2</td> </tr> <tr> <td>2</td> <td>4</td> </tr> <tr> <td>3</td> <td>6</td> </tr> </table>

O incluso como un gráfico con `x` como la entrada e `y` como la salida:

<img src="images/fn_graph.png" width="300" height="300" alt="grafo de funciones" />

No hay necesidad de detalles de implementación si la entrada dicta la salida. Ya que las funciones tan solo son mapeos de entrada a salida, podemos simplemente escribir objetos literales y ejecutarlos con `[]` en lugar de `()`.

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

Por supuesto, puedes querer calcular en lugar de apuntar valores a mano, pero esto ilustra una forma diferente de pensar sobre las funciones. (Debes estar pensando "¿qué pasa con las funciones con múltiples argumentos?". Ciertamente, esto presenta un pequeño inconveniente cuando se piensa en términos matemáticos. Por ahora, podemos empaquetarlos en un array o simplemente pensar que como entrada pasamos el objeto `arguments`. Cuando aprendamos sobre *currying*, veremos cómo podemos modelar directamente la definición matemática de función.)

Aquí viene la dramática revelación: Las funciones puras *son* funciones matemáticas y son todo sobre lo que trata la programación funcional. Programar con estos pequeños ángeles puede tener grandes beneficios. Veamos algunas de las razones por las que estamos dispuestos a recorrer tan grandes distancias para preservar la pureza.

## Los Argumentos Para La Pureza

### Almacenable en Caché

Para empezar, las funciones puras siempre pueden ser almacenadas en caché por su entrada. Esto se hace típicamente con una técnica llamada memoización: 

```js
const squareNumber = memoize(x => x * x);

squareNumber(4); // 16

squareNumber(4); // 16, devuelve lo almacenado en caché para la entrada 4

squareNumber(5); // 25

squareNumber(5); // 25, devuelve lo almacenado en cache para la entrada 5
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

Lo interesante aquí es que realmente no hacemos la llamada http; en su lugar devolvemos una función que lo hará cuando sea llamada. Esta función es pura porque siempre devolverá la misma salida dada la misma entrada: la función que hará esa llamada http en particular dados `url` y `params`. 

Nuestra función `memoize` funciona bien, aunque no guarda en caché los resultados de la llamada http, sino que guarda la función generada.

Esto todavía no es muy útil, pero pronto aprenderemos algunos trucos que harán que lo sea. La lección es que podemos guardar en caché cualquier función sin importar cuan destructiva parezca.

### Portables / Autodocumentadas

Las funciones puras son completamente autocontenidas. Todo lo que necesita la función se le pasa en bandeja de plata. Considera esto por un momento... ¿Cómo puede esto ser beneficioso? Para empezar, las dependencias de la función son explícitas y, por lo tanto, más fáciles de ver y entender; nada extraño sucede a escondidas.

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

Este ejemplo demuestra que la función pura debe ser honesta acerca de sus dependencias y que como tal debe decirnos exactamente qué es lo que hace. Solo por su firma, sabemos que usará una `Db`, `Email` y `attrs`, lo que debería ser, cuanto menos, revelador.

Aprenderemos a crear funciones puras como esta sin limitarnos a tan solo aplazar la evaluación, pero debería quedar claro que la forma pura es mucho más informativa que su escurridiza contraparte que trama quién sabe qué.

Algo más a tener en cuenta es que se nos obliga a "inyectar" dependencias, pasándolas como argumentos, lo que hace a nuestra aplicación más flexible, pues hemos parametrizado nuestra base de datos, cliente de email o lo que sea (no te preocupes, veremos una manera de hacer esto menos tedioso de lo que parece). Si decidimos usar una base de datos diferente solo necesitaremos llamar con ella a nuestra función. Si nos encontramos escribiendo una nueva aplicación en la que nos gustaría reutilizar esta confiable función, simplemente tendremos que pasar a esta función la `Db` y el `Email` que tengamos en ese momento.

En un entorno JavaScript, portabilidad puede significar serializar y enviar funciones por un socket. Puede significar ejecutar toda nuestra aplicación con Web Workers. La portabilidad es un rasgo poderoso.

Al contrario de los "típicos" métodos y procedimientos de la programación imperativa profundamente enraizados a sus entornos a través de estado, dependencias y efectos, las funciones puras pueden ejecutarse allá donde nuestro corazón desee.

¿Cuándo fué la última vez que copiaste un método en una nueva app? Una de mis citas favoritas proviene del creador de Erlang, Joe Armstrong: "El problema con los lenguajes orientados a objetos es todo ese entorno implícito que llevan a todos lados con ellos. Querías una banana, pero tienes un gorila sosteniendo una banana... y la jungla entera". 

### Testeable

Después de lo anterior, nos damos cuenta de que las funciones puras hacen que el testing sea mucho más fácil. No necesitamos mockear una pasarela de pagos "real" o configurar y verificar el estado del mundo después de cada test. Simplemente, pasamos la entrada a la función y verificamos su salida.

De hecho, la comunidad funcional está siendo pionera nuevas herramientas de pruebas que pueden bombardear nuestra función con entradas generadas y verificar que sus propiedades se mantienen en la salida. Está fuera del alcance de este libro, pero os animo encarecidamente a que busquéis y probéis *Quickcheck*; una herramienta de pruebas que está hecha a medida para un entorno puramente funcional.

### Comprensible

Muchas personas creen que la mayor victoria cuando trabajas con funciones puras es la *transparencia referencial*. Un trozo de código es referencialmente transparente cuando puede ser sustituido por su valor resultante sin cambiar el comportamiento del programa.

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

`decrementHP`, `isSameTeam` y `punch` son todas puras y, por tanto, referencialmente transparentes. Podemos usar la técnica llamada *razonamiento ecuacional*, donde podemos sustituir "iguales por iguales" para razonar sobre el código. Es un poco como evaluar manualmente el código sin tener en cuenta las peculiaridades de la evaluación programática. Usando transparencia referencial, juguemos un poco con este código.

Primero reemplazamos la función `isSameTeam`.

```js
const punch = (a, t) => (a.get('team') === t.get('team') ? t : decrementHP(t));
```

Ya que nuestros datos son inmutables, podemos simplemente reemplazar cada equipo [*team*] por su valor real

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

Esta habilidad para razonar acerca del código es excelente para, en general, refactorizarlo y entenderlo. De hecho, hemos utilizado esta técnica para refactorizar nuestro programa de bandada de gaviotas. Usamos razonamiento ecuacional para aprovechar las propiedades de adición y multiplicación. De hecho, utilizaremos estas técnicas a lo largo de todo el libro.

### Código Paralelo

Finalmente, y aquí está el golpe de gracia, podemos ejecutar en paralelo cualquier función pura, ya que no necesita acceder a memoria compartida y no puede, por definición, tener una condición de carrera debido a algún efecto secundario.

Esto podría usarse tanto en un servidor con entorno js e hilos de ejecución como en un navegador con web workers, aunque la cultura actual parece evitarlo debido a lo complejo que resulta tratar con funciones impuras.

## En Resumen

Hemos visto qué son las funciones puras y por qué en programación funcional creemos que son extraordinarias. De aquí en adelante, nos esforzaremos en escribir todas nuestras funciones de una forma pura. Necesitaremos algunas herramientas adicionales para ayudarnos, pero mientras tanto, trataremos de separar las funciones impuras del resto del código puro. 

Resulta un poco laborioso escribir programas con funciones puras al no tener algunas herramientas extra en nuestro cinturón. Hemos de hacer malabares con los datos pasando argumentos por todas partes, tenemos prohibido utilizar estado y sin mencionar lo de los efectos secundarios. ¿Cómo afrontar la escritura de estos programas de masoquista? Obtengamos una nueva herramienta llamada curry.

[Capítulo 4: Currying](ch04-es.md)
