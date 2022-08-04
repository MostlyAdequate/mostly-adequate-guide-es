# Capítulo 5: Programando por composición

## Reproducción Funcional

Aquí tenemos `compose`:

```js
var compose = function(f,g) {
  return function(x) {
    return f(g(x));
  };
};
```

`f` y `g` son funciones y `x` es el valor "pasado" a través.

La composición es como la reproducción funcional. Tú, reproductor de funciones, selecciona dos con las características que te gustaría combinar y mézclalas para formar una nueva. Su uso es así:

```js
var toUpperCase = function(x) { return x.toUpperCase(); };
var exclaim = function(x) { return x + '!'; };
var shout = compose(exclaim, toUpperCase);

shout("send in the clowns");
//=> "SEND IN THE CLOWNS!"
```

La composición de dos funciones devuelve una nueva función. Esto tiene sentido: componer dos unidades del mismo tipo (en este caso una función) debería devolver una nueva unidad del mismo tipo. Si juntas dos legos no obtienes una casa de montaña. Existe una teoría, una ley que descubriremos en su debido tiempo.

En nuestra definición de `compose`, la `g` se ejecutará antes que la `f`, creando un flujo de datos de derecha a izquierda. Esto es mucho más legible que tener un montón de funciones anidadas. Sin compose, lo escrito arriba sería:

```js
var shout = function(x){
  return exclaim(toUpperCase(x));
};
```

En vez de adentro hacia afuera, lo ejecutamos de derecha a izquierda, lo cual supongo que es un paso a la izquierda[^boo]. Veamos un ejemplo donde importa la secuencia:

```js
var head = function(x) { return x[0]; };
var reverse = reduce(function(acc, x){ return [x].concat(acc); }, []);
var last = compose(head, reverse);

last(['jumpkick', 'roundhouse', 'uppercut']);
//=> 'uppercut'
```

`reverse` devolverá una lista, mientras `head` coje el elemento inicial. Esto resulta en un efectiva, aunque ineficiente, función `last`. La secuencia de funciones en la composición debería de ser aparente en este ejemplo. Podríamos definir una versión de izquierda a derecha, de todas formas, copiaremos la versión matemática lo mejor posible. Sí, eso es correcto, la composición viene directamente de los libros de matemáticas. De hecho, quizás es el momento de hechar un vistazo a una propiedad que es válida para cualquier composición.

```js
// asociatividad
var associative = compose(f, compose(g, h)) == compose(compose(f, g), h);
// true
```

La composición es asociativa, lo cual significa que no importa como los agrupes. Entonces, si queremos capitalizar una cadena, podemos escribir:

```js
compose(toUpperCase, compose(head, reverse));

// o también
compose(compose(toUpperCase, head), reverse);
```

No importa cómo agrupemos nuestras llamadas compose, ya que el resultado será el mismo. Esto nos permite escribir compose como una función *variadic* y usarla así:

```js
// anteriormente hubiesemos tenido que escribir dos composiciones, pero porque es asociativa, podemos componer tantas funciones como queramos y dejarle decidir como agruparlas.
var lastUpper = compose(toUpperCase, head, reverse);

lastUpper(['jumpkick', 'roundhouse', 'uppercut']);
//=> 'UPPERCUT'


var loudLastUpper = compose(exclaim, toUpperCase, head, reverse)

loudLastUpper(['jumpkick', 'roundhouse', 'uppercut']);
//=> 'UPPERCUT!'
```

Aplicar la propiedad asociativa nos da flexibilidad y paz mental, sabiendo que el resultado va a ser equivaliente. Una definición un poco más complicada está incluída con el soporte de librerías para este libro y es la definición que podrás encontrar normalmente en librerías como [lodash][lodash-website], [underscore][underscore-website], y [ramda][ramda-website].

Uno de los beneficios de la asociatividad es que cualquier grupo de funciones puede ser extraído y reagrupado en una composición. Vámos a jugar un poco reescribiendo nuestra ejemplo anterior:

```js
var loudLastUpper = compose(exclaim, toUpperCase, head, reverse);

// o
var last = compose(head, reverse);
var loudLastUpper = compose(exclaim, toUpperCase, last);

// o
var last = compose(head, reverse);
var angry = compose(exclaim, toUpperCase);
var loudLastUpper = compose(angry, last);

// más variaciones...
```

No hay repuestas correctas o incorrectas - solo estamos juntando nuestras piezas de legos de la manera que nos plazca. Normalmente lo mejor es agrupar de manera que se pueda reusar como `last` y `angry`. Si estás familiarizado con Fowler´s "[Refactoring][refactoring-book]", uno quizá reconozca el proceso como "[extract method][extract-method-refactor]"...sin la preocupación de tener en cuenta el estado del objecto.

## Pointfree

Pointfree significa, no especificar tus datos nunca. Perdona. Significa que las funciones nunca mencionan los datos sobre los que opera. Funciones de primera clase, currying, y composición juegan juntas creando este estilo.

```js
//no es pointfree porque mencionamos los datos: word
var snakeCase = function (word) {
  return word.toLowerCase().replace(/\s+/ig, '_');
};

//pointfree
var snakeCase = compose(replace(/\s+/ig, '_'), toLowerCase);
```

Ves como hemos aplicado `replace` parcialmente? Lo que estamos haciendo es pasando nuestros datos a través de cada función con un solo argumento. Currying nos permite preparar cada función para que solo coja sus datos, opere con ellos, y los devuelva. En la versión pointfree, se puede ver, como no se necesita los data para construir nuestra función, en contra, conla función  no pointfree (pointful), necesitamos tener `word` disponible antes de nada.

Vamos a ver otro ejemplo.

```js
//no es pointfree porque mencionamos los datos: name
var initials = function (name) {
  return name.split(' ').map(compose(toUpperCase, head)).join('. ');
};

//pointfree
var initials = compose(join('. '), map(compose(toUpperCase, head)), split(' '));

initials("hunter stockton thompson");
// 'H. S. T'
```

Código Pointfree puede, ayudarnos a eleminar nombres innecesarios y manternos genéricos y concisos. Pointfree es una buena prueba de fuego para saber si nuestro código funcional esta compuesto de pequeñas funciones que tienen toman un input y devuelven in output. No puedes componer un bucle while, por ejemplo. Sin embargo, pointfree es una espada de doble filo y a veces puede no dejar clara cual es su intención. No todo código funcional es pointfree y esto es O.K. Lo utilizaremos cuando podamos y sino, usaremos funciones comúnes.

## Depurando
Un error común es el componer algo como `map`, una función de dos argumentos, sin antes aplicarlar parcialmente.

```js
//Inconrrecto - terminamos dando un array a angry y aplicamos map parcialmente con díos sabe que.
var latin = compose(map, angry, reverse);

latin(["frog", "eyes"]);
// error


// derecha - cada función espera 1 argumento.
var latin = compose(map(angry), reverse);

latin(["frog", "eyes"]);
// ["EYES!", "FROG!"])
```

Si tienes problemas depurarando esta composición, podemos utilizar una función para rastrear que es lo que pasa, aunque esta función sea impura puede ser de gran ayuda.

```js
var trace = curry(function(tag, x){
  console.log(tag, x);
  return x;
});

var dasherize = compose(join('-'), toLower, split(' '), replace(/\s{2,}/ig, ' '));

dasherize('The world is a vampire');
// TypeError: Cannot read property 'apply' of undefined
```

Parece que algo fue mal, vamos a probar con `trace`

```js
var dasherize = compose(join('-'), toLower, trace("after split"), split(' '), replace(/\s{2,}/ig, ' '));
// después de split [ 'The', 'world', 'is', 'a', 'vampire' ]
```

Ah! Necesitamos ejecutar `map` a `toLower` ya que es un array.

```js
var dasherize = compose(join('-'), map(toLower), split(' '), replace(/\s{2,}/ig, ' '));

dasherize('The world is a vampire');

// 'the-world-is-a-vampire'
```

La función `trace` es para depuración y nos permite observar los datos en ciertos momentos. Lenguajes como haskell y purescript tienen funciones similares para agilizar el desarrollo.

Composición será nuestra herramienta para construir programas y, afortunadamente, esta respaldada por una teoría poderosa que asegura que las cosas funcionarán. Vamos a examinar esta teoría.


## Teoría categórica.

Teoría categorica es una rama abstracta de las matemáticas que puede formalizar conceptos a partir de ramas distintas como teoría de conjuntos, teoría de tipos, teoría de grupos, lógica, y más. Principalmente lidia con objetos, morfismos, y transformaciones, el cual se asemeja a progrmación bastante. Aquí tenemos una gráfica de los mismos conceptos visto desde cada teoría separada.

<img src="images/cat_theory.png" />

Lo siento, no prentendí asustarte. No espero que estés intimamente familiarizado con todos estos conceptos. Mi intención es mostrate cuanta duplicación tenemos, y como la teoría categórica apunta a unificar estas cosas.

En la teoría categórica, tenemos algo que se llama... una categoría. Esta definida como una colección con los siguientes componentes:

  * Una colección de objectos
  * Una colección de morfismos.
  * Una noción de composición en los morfismos
  * Un morfismo distinguido llamado identidad

La teoría categórica es suficientemente abstracta para modelar muchas cosas, vamos aplicar estos tipos y funciones, que es lo único que nos importat en este momento.

**Una colección de objectos**
Los objectos serán tipo de datos. Por ejemplo, ``String``, ``Boolean``, ``Number``, ``Object``, etc. Frecuentemente vemos tipos de datos como un conjunto de todos los valores posibles. Uno podría ver un ``Boolean`` como un conjunto de `[true, false]` y ``Number`` como un conjunto de todos los valore numéricos posibles. Tratar los tipos como conjuntos es útil porque podemos utilizar la teoría del conjunto con ellos.

**Una colección de morfismos**
Los morfismos serán nuestras funciones puras estándard de cada día.

**Una noción de composición en los morfismos**
Esto, como ya habrás adivinado, es nuestro nuevo juguete a estrenar - `compose`. Anteriormente vimos que nuestra función `compose` es asociativa, lo cual no es una coincidencia ya que es una propiedad necesaria para cualquier composición de la teoría categórica.

Aquí tenemos una imagen que demuestra la composición:

<img src="images/cat_comp1.png" />
<img src="images/cat_comp2.png" />

Aquí un ejemplo concreto en códig:

```js
var g = function(x){ return x.length; };
var f = function(x){ return x === 4; };
var isFourLetterWord = compose(f, g);
```

**Un morfismo distinguido llamado identidad**
Vamos a introducir otra útil función llamada `id`. Esta función simplemente acepta una entrada y te la escupe de vuelta. Hechale un vistazo:

```js
var id = function(x){ return x; };
```

Quizás te preguntes a tí mismo "¿Para que demónios puede ser esto útil?". En los siguientes capítulos haremos un uso extenso de esta función, pero por ahora piensa sobre esta función como si fuese un valor, una función que enmascara nuestros datos.

`id` tiene que interactúar bien con compose (composición). Aquí tenemos una propiedad que cumple siempre para cada unario[^unario: función de un argumento] función f:

```js
// identidad
compose(id, f) == compose(f, id) == f;
// true
```

Hey, es como la propiedad de identidad con números! Si esto no lo tienes claro aún, tomate tú tiempo. Entiende la futilidad. Pronto veremos como `id` será usado en muchos sitios, pero por ahora considera esta función como una función que actúa como soporte para un valor dado. Será bastante útil cuando escribamos código pointfree.

Ahi lo tienes, una categória de tipos y funciones. Si esta es tú primera introducción, imagino que estarás un poco confuso con la idea de que es una categoría y su utilidad. Trabajaremos sobre estos conocimientos a lo largo del libro. Por el momento, en este capítulo, en esta línea, lo puedes ver como algo que nos provee con conocimientos relacionados con la composición - llamalo, propiedades de identidad y asociativas.

¿Cuáles son otras categorías, te preguntas? Bien, podemos definir gráfos dirigidos con nodos como objetos, we can define one for directed graphs with nodes being objects, edges being morphisms, y composición solo como camino de concatenación. Podemos definir números como objectos y `>=` como morfismos[^realmente cualquier orden parcial o total puede ser una categoría]. Hay un montón de categorías, pero para el propósito de este libro, solo nos preocuparemos del que hemos definido anteriormente. Hemos cubierto bastante la superficie y tenemos que seguir.


## Resúmen
Composición conecta nuestras funciones como una serie de tuberías. Datos fluyen a través de nuestra aplicación como tiene que ser - funciones puras son entrada a salida después de todo, romper con esta cadena sería descuidar la sálida, siendo nuestro software inútil.

Ante todo, mantenemos composición como principio de diseño. Porque nos permite mantener nuestra app simple y razonable. Teoría categórica tiene un gran rol en la arquitectura de nuestra app, modelando efectos secundarios, y no asegura exactitud.

Hemos llegado al punto donde nos será útil ver algunos ejemplos prácticos. Vamos a hacer una aplicación como ejemplo.

[Capítulo 6: Aplicación de ejemplo](ch6.md)

## Ejercicios

```js
var _ = require('ramda');
var accounting = require('accounting');

// Datos de ejemplo
var CARS = [
    {name: "Ferrari FF", horsepower: 660, dollar_value: 700000, in_stock: true},
    {name: "Spyker C12 Zagato", horsepower: 650, dollar_value: 648000, in_stock: false},
    {name: "Jaguar XKR-S", horsepower: 550, dollar_value: 132000, in_stock: false},
    {name: "Audi R8", horsepower: 525, dollar_value: 114200, in_stock: false},
    {name: "Aston Martin One-77", horsepower: 750, dollar_value: 1850000, in_stock: true},
    {name: "Pagani Huayra", horsepower: 700, dollar_value: 1300000, in_stock: false}
  ];

// Ejercicio 1:
// ============
// utiliza _.compose() para reescribir la siguiente función. Pista: _.prop() está currieada.
var isLastInStock = function(cars) {
  var last_car = _.last(cars);
  return _.prop('in_stock', last_car);
};

// Ejercicio 2:
// ============
// utiliza _.compose(), _.prop() and _.head() para obtener el nombre del primer coche.
var nameOfFirstCar = undefined;


// Ejercicio 3:
// ============
// Utiliza la función de ayuda _average para reescribir averageDollarValue como composición.
var _average = function(xs) { return _.reduce(_.add, 0, xs) / xs.length; }; // <- déjalo

var averageDollarValue = function(cars) {
  var dollar_values = _.map(function(c) { return c.dollar_value; }, cars);
  return _average(dollar_values);
};


// Ejercicio 4:
// ============
// Escribe la función: sanitizeNames() que devuelva una lista de con los nombres de coches en minúsculas y los espacios por subrayado, utilizando compose: ejemplo: sanitizeNames([{name: "Ferrari FF", horsepower: 660, dollar_value: 700000, in_stock: true}]) //=> ["ferrari_ff"].

var _underscore = _.replace(/\W+/g, '_'); //<-- déjalo y utiliza sanitize

var sanitizeNames = undefined;


// Bonus 1:
// ============
// Reescribe availablePrices con compose.

var availablePrices = function(cars) {
  var available_cars = _.filter(_.prop('in_stock'), cars);
  return available_cars.map(function(x){
    return accounting.formatMoney(x.dollar_value);
  }).join(', ');
};


// Bonus 2:
// ============
// Convierte esta función a pointfree. Pista: puedes usar _.flip()

var fastestCar = function(cars) {
  var sorted = _.sortBy(function(car){ return car.horsepower }, cars);
  var fastest = _.last(sorted);
  return fastest.name + ' is the fastest';
};
```

[lodash-website]: https://lodash.com/
[underscore-website]: http://underscorejs.org/
[ramda-website]: http://ramdajs.com/
[refactoring-book]: http://martinfowler.com/books/refactoring.html
[extract-method-refactor]: http://refactoring.com/catalog/extractMethod.html
