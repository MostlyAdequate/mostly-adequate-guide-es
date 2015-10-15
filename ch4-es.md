# Capitulo 4: Currying

## No puedo vivir, si vivir es sin ti 
*NdT: El titulo viene de la letra de una canción "Can't live if livin' is without you"

Mi padre una vez me explicó como es que uno puede vivir sin ciertas cosas hasta que uno las adquiere. Un microondas es una de esas cosas. Los smartphones, son otra. Los mas mayores entre nosotros recordarán una vida plena sin internet. Para mi, `currying` esta en esta lista.

El concepto es sencillo: Puedes llamar a una función con menos parámetros de los que espera. Devuelve una función que recibe los parámetros restantes.

Puedes elegir llamarla con todos sus parámetros de una vez o simplemente pasarle cada parámetros poco a poco.

```js
var add = function(x) {
  return function(y) {
    return x + y;
  };
};

var increment = add(1);
var addTen = add(10);

increment(2);
// 3

addTen(2);
// 12
```

Aquí hemos hecho una función `add` que acepta un parámetro y devuelve una función. Al llamarla, la función devuelta recuerda el primer parámetro anterior mediante un closure (o cerradura). Sin embargo, llamarla con ambos parámetros de una vez es un poco molesto, entonces podemos utilizar una función especial de ayuda llamada `curry` que hace que llamar o definir estas funciones sea mas fácil.

Ahora crearemos unas pocas funciones para nuestro entretenimiento.

```js
var curry = require('lodash.curry');

var match = curry(function(what, str) {
  return str.match(what);
});

var replace = curry(function(what, replacement, str) {
  return str.replace(what, replacement);
});

var filter = curry(function(f, ary) {
  return ary.filter(f);
});

var map = curry(function(f, ary) {
  return ary.map(f);
});
```

El patrón que he seguido es uno simple, pero importante. He posicionado estratégicamente los datos sobre los que vamos a operar (Cadena, Array) como el ultimo parámetro. Quedará mas claro porqué cuando lo usemos.

```js
match(/\s+/g, "hello world");
// [ ' ' ]

match(/\s+/g)("hello world");
// [ ' ' ]

var hasSpaces = match(/\s+/g);
// function(x) { return x.match(/\s+/g) }

hasSpaces("hello world");
// [ ' ' ]

hasSpaces("spaceless");
// null

filter(hasSpaces, ["tori_spelling", "tori amos"]);
// ["tori amos"]

var findSpaces = filter(hasSpaces);
// function(xs) { return xs.filter(function(x) { return x.match(/\s+/g) }) }

findSpaces(["tori_spelling", "tori amos"]);
// ["tori amos"]

var noVowels = replace(/[aeiou]/ig);
// function(replacement, x) { return x.replace(/[aeiou]/ig, replacement) }

var censored = noVowels("*");
// function(x) { return x.replace(/[aeiou]/ig, "*") }

censored("Chocolate Rain");
// 'Ch*c*l*t* R**n'
```
Lo que demostramos aquí es la habilidad de pre-cargar una función con un parámetro o dos con el fin de recibir una nueva función que recuerda esos parámetros.

Os aliento a probar `npm install lodash`, copiar el código anterior y probarlo en la consola REPL. También puedes hacer lo mismo en un navegador donde `lodash` o `ramda` están disponibles. 

## Mas que un chiste / o salsa especial 

*NdT: Haciendo referencia a la salsa de `Curry`.

El currying es útil para muchas cosas. Podemos hacer nuevas funciones solo pasando nuestras funciones de base con algunos parámetros como hemos visto en `hasSpaces`, `findSpaces` y `censored`.

También tenemos la habilidad de transformar cualquier función que trabaje con un solo elemento en una función que trabaje con una lista simplemente envolviéndola con `map`: 

```js
var getChildren = function(x) {
  return x.childNodes;
};

var allTheChildren = map(getChildren);
```

Pasar a una función menos parámetros de los que espera se conoce normalmente como *aplicación parcial*. Aplicar parcialmente una función puede quitar mucho código repetitivo. Considera como seria la función anterior `allTheChildren` con el `map`, sin currying, de lodash[^nota que los parámetros están en diferente orden]:

```js
var allTheChildren = function(elements) {
  return _.map(elements, getChildren);
};
```

Normalmente no definimos funciones que trabajan con arrays, porque podemos llamar simplemente `map(getChildren)`. Lo mismo para `sort`, `filter`, y otras funciones de alto orden[^Funciones de alto orden: Una función que acepta o devuelve una función].

Cuando hablamos acerca de *funciones puras*, decimos que pasan 1 entrada a 1 salida. Currying hace exactamente eso: cada uno de los parámetros devuelve una nueva función que espera los parámetros faltantes. Eso, viejo amigo, es 1 entrada a una salida.

Sin importar si la salida es otra función, califica como pura. Si permitimos múltiples parámetros por vez, pero esto se puede ver como quitar simplemente unos `()` por conveniencia.

## En resumen

Currying es practico y disfruto mucho trabajando con funciones *curry*-ficadas diariamente. Es una herramienta para nuestro cinturón que hace la programación funcional menos verboso y tedioso.

Podemos crear nuevas y útiles funciones al vuelo simplemente pasandole unos pocos argumentos y como bono, retenemos la definición de función matemática a pesar de sus múltiples parámetros.

Ahora vamos a adquirir otra herramienta esencial llamada `compose`.

[Capitulo 5: Programando por composición](ch5-es.md)

## Ejercicios

Una pequeña nota antes de empezar. Usaremos una librería llamada *ramda* que aplica `curry` a cada función por defecto. Alternativamente puedes escoger *lodash-fp* que hace lo mismo y esta escrita/mantenida por el creador de `lodash`. Ambas funcionaran sin problemas, es solo cuestion de preferencia.

[ramda](http://ramdajs.com)
[lodash-fp](https://github.com/lodash/lodash-fp)

Hay [test unitarios](https://github.com/DrBoolean/mostly-adequate-guide/tree/master/code/part1_exercises) para ejecutar con cada ejercicio mientras los codificas, o puedes simplemente copiar-pegar en la consola REPL de JavaScript de los ejercicios previo si prefieres.

Las respuestas se proporcionan con el código en el [repositorio del libro](https://github.com/DrBoolean/mostly-adequate-guide/tree/master/code/part1_exercises/answers)

```js
var _ = require('ramda');


// Ejercicio 1
//==============
// Refactoriza para quitar todos los parámetros mediante aplicación parcial de la función

var words = function(str) {
  return _.split(' ', str);
};

// Ejercicio 1a
//==============
// Usa la funcion map para crear una nueva función words que trabaje con un array de cadenas.

var sentences = undefined;


// Ejercicio 2
//==============
// Refactoriza para quitar los parámetros mediante la aplicación parcial de las funciones

var filterQs = function(xs) {
  return _.filter(function(x){ return match(/q/i, x);  }, xs);
};


// Ejercicio 3
//==============
// Usa la funcion auxiliar _keepHighest para refactorizar max y que no haga
// referencia a ningún parámetro


// LEAVE BE:
var _keepHighest = function(x,y){ return x >= y ? x : y; };

// REFACTOR THIS ONE:
var max = function(xs) {
  return _.reduce(function(acc, x){
    return _keepHighest(acc, x);
  }, -Infinity, xs);
};


// Bonus 1:
// ============
// envuelve la función slice del array para que sea funcional y con curry.
// //[1,2,3].slice(0, 2)
var slice = undefined;


// Bonus 2:
// ============
// usa slice para definir una función "take" que quite n elementos del principio de una cadena. Hazla con curry
// 
// // Result for "Something" with n=4 should be "Some"
var take = undefined;
```
