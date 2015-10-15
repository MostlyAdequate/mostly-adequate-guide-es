# Capítulo 5: Programando Componiendo

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

Composición es como cultivo de manera funcionalComposition feels like function husbandry. You, breeder of functions, select two with traits you'd like to combine and mash them together to spawn a brand new one. Usage is as follows:

```js
var toUpperCase = function(x) { return x.toUpperCase(); };
var exclaim = function(x) { return x + '!'; };
var shout = compose(exclaim, toUpperCase);

shout("send in the clowns");
//=> "SEND IN THE CLOWNS!"
```

La composición de dos funciones devuelve una nueva función. Esto tiene sentido: componer dos unidades del mismo tipo (en este caso una función) debería devolver una nueva unidad del mismo tipo. Si juntas dos legos no obtienes una casa de montaña. Exister una teoría, una ley que descubriremos en su debido tiempo.

En nuestra definición de `compose`, la `g` se ejecutará antes que la `f`, creando un flujo de datos de derecha a izquierda. Esto se puede leer mejor que tener un montón de funciones anidadas. Sin composición, lo escrito arribe sería:

```js
var shout = function(x){
  return exclaim(toUpperCase(x));
};
```

En vez de dentro hacía fuera, lo ejecutamos de derecha a izquierda, lo cual supongo que un paso a la derecha[^boo]. Vamos a ver un ejemplo donde importa la secuencia:

```js
var head = function(x) { return x[0]; };
var reverse = reduce(function(acc, x){ return [x].concat(acc); }, []);
var last = compose(head, reverse);

last(['jumpkick', 'roundhouse', 'uppercut']);
//=> 'uppercut'
```

`reverse` devolverá una lista, mientras `head` coje el elemento inicial. Esto resulta en un efectiva, aunque inefectiva, función `last`. La secuencia de funciones en la composición debería de ser aparente en este ejemplo. Podríamos definir una versión de izquierda a derecha, de todas formas, copiaremos la versión matemática lo mejor posible. Sí, eso es correcto, composición viene directamente de los libros de matemáticas. De hecho, quizás es el momento de hechar un vistazo a una propiedad que es válida para cualquier composición.

```js
// asociatividad
var associative = compose(f, compose(g, h)) == compose(compose(f, g), h);
// true
```

Composición es asociativa, lo cual significa que no importa como los agrupes. Entonces, si queremos capitalizar una cadena, podemos escribir:

```js
compose(toUpperCase, compose(head, reverse));

// o también
compose(compose(toUpperCase, head), reverse);
```

No importa como agrupemos nuestras llamadas a funciones, ya que el resultado será el mismo. Esto nos permite escribir una composición variable tal que así:

```js
// anteriormente hubiesemos tenido que escribir dos composiciones, pero porque es asociativa, podemos componer tantas funciones como queramos y dejarle decidir como agruparlas.
var lastUpper = compose(toUpperCase, head, reverse);

lastUpper(['jumpkick', 'roundhouse', 'uppercut']);
//=> 'UPPERCUT'


var loudLastUpper = compose(exclaim, toUpperCase, head, reverse)

loudLastUpper(['jumpkick', 'roundhouse', 'uppercut']);
//=> 'UPPERCUT!'
```

Aplicar la propiedad asociativa nos da una flexibilidad y paz mental , sabiendo que el resultado va a ser equivaliente. Una definición un poco más complicada está incluída con el soporte de librerías para este libro y es la definición que podrás encontrar normalmente en librerías como [lodash][lodash-website], [underscore][underscore-website], y [ramda][ramda-website].

One pleasant benefit of associativity is that any group of functions can be extracted and bundled together in their very own composition. Let's play with refactoring our previous example:

```js
var loudLastUpper = compose(exclaim, toUpperCase, head, reverse);

// or
var last = compose(head, reverse);
var loudLastUpper = compose(exclaim, toUpperCase, last);

// or
var last = compose(head, reverse);
var angry = compose(exclaim, toUpperCase);
var loudLastUpper = compose(angry, last);

// more variations...
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

Código Pointfree puede, ayudarnos a eleminar nombres innecesarios y manternos genéricos y concisos. Pointfree es una bueno como prueba de fuego para saber si nuestro código funcional esta compuesto de pequeñas funciones que tienen toman un input y devuelven in output. No puedes componer un bucle while, por ejemplo. Sin embargo, pointfree es una espada de doble filo y a veces puede no dejar clara cual es su intención. No todo código funcional es pointfree y esto es O.K. Lo utilizaremos cuando podamos y sino, usaremos funciones normales.

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

Si tienes problemas a depurar esta composición, podemos utilizar una función para rastrear que es lo que pasa, aunque esta función sea impura puede ser de gran ayuda.

```js
var trace = curry(function(tag, x){
  console.log(tag, x);
  return x;
});

var dasherize = compose(join('-'), toLower, split(' '), replace(/\s{2,}/ig, ' '));

dasherize('The world is a vampire');
// TypeError: Cannot read property 'apply' of undefined
```

Something is wrong here, let's `trace`

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

The `trace` function allows us to view the data at a certain point for debugging purposes. Languages like haskell and purescript have similar functions for ease of development.

Composition will be our tool for constructing programs and, as luck would have it, is backed by a powerful theory that ensures things will work out for us. Let's examine this theory.


## Category theory

Category theory is an abstract branch of mathematics that can formalize concepts from several different branches such as set theory, type theory, group theory, logic, and more. It primarily deals with objects, morphisms, and transformations, which mirrors programming quite closely. Here is a chart of the same concepts as viewed from each separate theory.

<img src="images/cat_theory.png" />

Sorry, I didn't mean to frighten you. I don't expect you to be intimately familiar with all these concepts. My point is to show you how much duplication we have so you can see why category theory aims to unify these things.

In category theory, we have something called... a category. It is defined as a collection with the following components:

  * A collection of objects
  * A collection of morphisms
  * A notion of composition on the morphisms
  * A distinguished morphism called identity

Category theory is abstract enough to model many things, but let's apply this to types and functions, which is what we care about at the moment.

**A collection of objects**
The objects will be data types. For instance, ``String``, ``Boolean``, ``Number``, ``Object``, etc. We often view data types as sets of all the possible values. One could look at ``Boolean`` as the set of `[true, false]` and ``Number`` as the set of all possible numeric values. Treating types as sets is useful because we can use set theory to work with them.


**A collection of morphisms**
The morphisms will be our standard every day pure functions.

**A notion of composition on the morphisms**
This, as you may have guessed, is our brand new toy - `compose`. We've discussed that our `compose` function is associative which is no coincidence as it is a property that must hold for any composition in category theory.

Here is an image demonstrating composition:

<img src="images/cat_comp1.png" />
<img src="images/cat_comp2.png" />

Here is a concrete example in code:

```js
var g = function(x){ return x.length; };
var f = function(x){ return x === 4; };
var isFourLetterWord = compose(f, g);
```

**A distinguished morphism called identity**
Let's introduce a useful function called `id`. This function simply takes some input and spits it back at you. Take a look:

```js
var id = function(x){ return x; };
```

You might ask yourself "What in the bloody hell is that useful for?". We'll make extensive use of this function in the following chapters, but for now think of it as a function that can stand in for our value - a function masquerading as every day data.

`id` must play nicely with compose. Here is a property that always holds for every unary[^unary: a one argument function] function f:

```js
// identity
compose(id, f) == compose(f, id) == f;
// true
```

Hey, it's just like the identity property on numbers! If that's not immediately clear, take some time with it. Understand the futility. We'll be seeing `id` used all over the place soon, but for now we see it's a function that acts as a stand in for a given value. This is quite useful when writing pointfree code.

So there you have it, a category of types and functions. If this is your first introduction, I imagine you're still a little fuzzy on what a category is and why it's useful. We will build upon this knowledge throughout the book. As of right now, in this chapter, on this line, you can at least see it as providing us with some wisdom regarding composition - namely, the associativity and identity properties.

What are some other categories, you ask? Well, we can define one for directed graphs with nodes being objects, edges being morphisms, and composition just being path concatenation. We can define with Numbers as objects and `>=` as morphisms[^actually any partial or total order can be a category]. There are heaps of categories, but for the purposes of this book, we'll only concern ourselves with the one defined above. We have sufficiently skimmed the surface and must move on.


## In Summary
Composition connects our functions together like a series of pipes. Data will flow through our application as it must - pure functions are input to output after all so breaking this chain would disregard output, rendering our software useless.

We hold composition as a design principle above all others. This is because it keeps our app simple and reasonable. Category theory will play a big part in app architecture, modelling side effects, and ensuring correctness.

We are now at a point where it would serve us well to see some of this in practice. Let's make an example application.

[Chapter 6: Example Application](ch6.md)

## Exercises

```js
var _ = require('ramda');
var accounting = require('accounting');

// Example Data
var CARS = [
    {name: "Ferrari FF", horsepower: 660, dollar_value: 700000, in_stock: true},
    {name: "Spyker C12 Zagato", horsepower: 650, dollar_value: 648000, in_stock: false},
    {name: "Jaguar XKR-S", horsepower: 550, dollar_value: 132000, in_stock: false},
    {name: "Audi R8", horsepower: 525, dollar_value: 114200, in_stock: false},
    {name: "Aston Martin One-77", horsepower: 750, dollar_value: 1850000, in_stock: true},
    {name: "Pagani Huayra", horsepower: 700, dollar_value: 1300000, in_stock: false}
  ];

// Exercise 1:
// ============
// use _.compose() to rewrite the function below. Hint: _.prop() is curried.
var isLastInStock = function(cars) {
  var last_car = _.last(cars);
  return _.prop('in_stock', last_car);
};

// Exercise 2:
// ============
// use _.compose(), _.prop() and _.head() to retrieve the name of the first car
var nameOfFirstCar = undefined;


// Exercise 3:
// ============
// Use the helper function _average to refactor averageDollarValue as a composition
var _average = function(xs) { return _.reduce(_.add, 0, xs) / xs.length; }; // <- leave be

var averageDollarValue = function(cars) {
  var dollar_values = _.map(function(c) { return c.dollar_value; }, cars);
  return _average(dollar_values);
};


// Exercise 4:
// ============
// Write a function: sanitizeNames() using compose that returns a list of lowercase and underscored car's names: e.g: sanitizeNames([{name: "Ferrari FF", horsepower: 660, dollar_value: 700000, in_stock: true}]) //=> ["ferrari_ff"].

var _underscore = _.replace(/\W+/g, '_'); //<-- leave this alone and use to sanitize

var sanitizeNames = undefined;


// Bonus 1:
// ============
// Refactor availablePrices with compose.

var availablePrices = function(cars) {
  var available_cars = _.filter(_.prop('in_stock'), cars);
  return available_cars.map(function(x){
    return accounting.formatMoney(x.dollar_value);
  }).join(', ');
};


// Bonus 2:
// ============
// Refactor to pointfree. Hint: you can use _.flip()

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
