# Capítulo 05: Programar Mediante Composición

## Cultivo Funcional
Aquí tenemos `compose`:

```js
const compose = (...fns) => (...args) => fns.reduceRight((res, fn) => [fn.call(null, ...res)], args)[0];
```

... ¡No te asustes! Este es el nivel-9000-super-Saiyan de _compose_. En aras del razonamiento, ignoremos la implementación variádica y consideremos una forma más simple capaz de componer juntas a dos funciones. Una vez te hayas hecho a la idea, puedes llevar la abstracción más allá y considerar que simplemente funciona para cualquier número de funciones (¡incluso podemos aportar pruebas de ello!)
Aquí tenemos una función _compose_ más amigable para quiénes me estáis leyendo:

```js
const compose2 = (f, g) => x => f(g(x));
```

`f` y `g` son funciones y `x` es el valor que está siendo canalizado a través de ellas.

La composición es una suerte de cultivo de funciones. Tú, horticultor de funciones, seleccionas dos con las características que te gustaría combinar y las mezclas para engendrar una nueva. Su uso es el siguiente:

```js
const toUpperCase = x => x.toUpperCase();
const exclaim = x => `${x}!`;
const shout = compose(exclaim, toUpperCase);

shout('send in the clowns'); // "SEND IN THE CLOWNS!"
```

La composición de dos funciones devuelve una nueva función. Esto tiene todo el sentido: componer dos unidades de algún tipo (en este caso función) debería devolver una nueva unidad de ese mismo tipo. No conectas dos legos entre sí y obtienes un "Lincoln Log" [*juego estadounidense de construcción de casitas de madera*]. Existe una teoría aquí, una ley subyacente que descubriremos a su debido tiempo.

En nuestra definición de `compose`, la `g` se ejecutará antes que la `f`, creando un flujo de datos de derecha a izquierda. Esto es mucho más legible que tener un montón de funciones anidadas. Sin compose, lo anterior sería:

```js
const shout = x => exclaim(toUpperCase(x));
```

En vez de adentro hacia afuera, lo ejecutamos de derecha a izquierda, lo cual supongo que es un paso a la izquierda (¡buu!) [*chiste malo que pierde la gracia en la traducción. En inglés, un paso a la derecha también quiere decir un paso en la buena dirección. En este chiste, el paso es hacia la izquierda, o sea, en la mala dirección*].

Veamos un ejemplo donde el orden en la secuencia importa:

```js
const head = x => x[0];
const reverse = reduce((acc, x) => [x, ...acc], []);
const last = compose(head, reverse);

last(['jumpkick', 'roundhouse', 'uppercut']); // 'uppercut'
```

`reverse` le da la vuelta a la lista, mientras que `head` coge el elemento inicial. Esto resulta en una efectiva a la vez que ineficiente función `last`. La secuencia de funciones en la composición debería ser evidente aquí. Podríamos definir una versión de izquierda a derecha, sin embargo, tal y como está se asemeja más a la versión matemática. Sí, eso es correcto, la composición viene directamente de los libros de matemáticas. De hecho, quizás es el momento de ver una propiedad que es válida para cualquier composición.

```js
// asociatividad
compose(f, compose(g, h)) === compose(compose(f, g), h);
```

La composición es asociativa, lo cual significa que no importa como agrupes dos de ellas. Entonces, si elegimos pasar la cadena de caracteres a mayúsculas, podemos escribir:

```js
compose(toUpperCase, compose(head, reverse));
// o también
compose(compose(toUpperCase, head), reverse);
```

Dado que no importa cómo agrupemos nuestras llamadas a `compose`, el resultado será el mismo. Esto nos permite escribir compose como una función *variádica* y usarla así:

```js
// anteriormente hubiésemos tenido que escribir dos composiciones, pero como es asociativa,
// podemos dar a compose tantas funciones como queramos y dejar que decida como agruparlas.
const arg = ['jumpkick', 'roundhouse', 'uppercut'];
const lastUpper = compose(toUpperCase, head, reverse);
const loudLastUpper = compose(exclaim, toUpperCase, head, reverse);

lastUpper(arg); // 'UPPERCUT'
loudLastUpper(arg); // 'UPPERCUT!'
```

Aplicar la propiedad asociativa nos da esta flexibilidad y la tranquilidad de que el resultado será equivalente. La definición variádica y un poco más complicada está incluida en las librerías de soporte de este libro y es la definición que se suele encontrar en librerías como [lodash][lodash-website], [underscore][underscore-website], y [ramda][ramda-website].

Un agradable beneficio de la asociatividad es que cualquier grupo de funciones puede ser extraído y agrupado en su propia composición. Juguemos a refactorizar nuestro ejemplo anterior:

```js
const loudLastUpper = compose(exclaim, toUpperCase, head, reverse);

// -- o también -------------------------------------------------------

const last = compose(head, reverse);
const loudLastUpper = compose(exclaim, toUpperCase, last);

// -- o también -------------------------------------------------------

const last = compose(head, reverse);
const angry = compose(exclaim, toUpperCase);
const loudLastUpper = compose(angry, last);

// más variaciones...
```

No hay repuestas correctas o incorrectas; solo estamos juntando nuestras piezas de lego de la manera que nos plazca. Normalmente, lo mejor es agrupar las cosas de manera que se puedan reutilizar, como `last` y `angry`. Si te es familiar "[Refactoring][refactoring-book]" de Fowler, quizás reconozcas a este proceso como "[extract function][extract-function-refactor]"... excepto por no tener que preocuparte por el estado de ningún objeto.

## Pointfree

El estilo pointfree [*que se puede encontrar traducido como programación tácita*] se refiere a no hablar nunca sobre tus datos. Perdona. Se refiere a funciones que nunca mencionan los datos sobre los que operan. Las funciones de primera clase, la currificación, y la composición hacen un buen equipo para crear este estilo.

> Sugerencia: En el [Apéndice C - Utilidades Pointfree](./appendix_c-es.md) hay definidas versiones pointfree de `replace` y `toLowerCase`. ¡No dudes en echar un vistazo!
 
```js
// no es pointfree porque mencionamos a los datos: word
const snakeCase = word => word.toLowerCase().replace(/\s+/ig, '_');

// pointfree
const snakeCase = compose(replace(/\s+/ig, '_'), toLowerCase);
```

¿Ves como hemos aplicado `replace` parcialmente? Lo que estamos haciendo es canalizar nuestros datos a través de cada una de las funciones de un solo argumento. La currificación nos permite preparar cada función para que solo coja los datos, opere con ellos, y se los pase a quien siga. Algo más a destacar es como en la versión pointfree no necesitamos a los datos para construir nuestra función, mientras que con la función no pointfree, necesitamos tener disponible a nuestra `word` [*palabra*] antes que nada.

Veamos otro ejemplo.

```js
// no es pointfree porque mencionamos a los datos: name
const initials = name => name.split(' ').map(compose(toUpperCase, head)).join('. ');

// pointfree
// NOTA: utilizamos 'intercalate' del apéndice en lugar de 'join' presentada en el capítulo 9!
const initials = compose(intercalate('. '), map(compose(toUpperCase, head)), split(' '));

initials('hunter stockton thompson'); // 'H. S. T'
```

El código pointfree puede de nuevo ayudarnos a eliminar nombres innecesarios y mantenernos concisos y genéricos. Pointfree es un buen indicador para saber si nuestro código funcional está compuesto de pequeñas funciones que toman un input y devuelven un output. No se puede componer un bucle while, por ejemplo. Sin embargo, ten cuidado porque pointfree es un arma de doble filo y a veces puede ofuscar la intención. No todo el código funcional es pointfree y eso está bien. Lo utilizaremos cuando podamos y si no, de lo contrario, utilizaremos funciones normales.

## Depurando
Un error común es componer algo como `map`, una función de dos argumentos, sin antes aplicarla parcialmente.

```js
// incorrecto - terminamos pasando un array a angry y aplicamos map parcialmente con quién sabe qué.
const latin = compose(map, angry, reverse);

latin(['frog', 'eyes']); // error

// correcto - cada función espera 1 argumento.
const latin = compose(map(angry), reverse);

latin(['frog', 'eyes']); // ['EYES!', 'FROG!'])
```

Si estás teniendo problemas para depurar una composición, podemos utilizar esta útil pero impura función `trace` para ver qué es lo que está pasando.

```js
const trace = curry((tag, x) => {
  console.log(tag, x);
  return x;
});

const dasherize = compose(
  intercalate('-'),
  toLower,
  split(' '),
  replace(/\s{2,}/ig, ' '),
);

dasherize('The world is a vampire');
// TypeError: Cannot read property 'apply' of undefined
```

Parece que algo fue mal, vamos a probar con `trace`

```js
const dasherize = compose(
  intercalate('-'),
  toLower,
  trace('después de split'),
  split(' '),
  replace(/\s{2,}/ig, ' '),
);

dasherize('The world is a vampire');
// después de split [ 'The', 'world', 'is', 'a', 'vampire' ]
```

¡Ah! Necesitamos usar `toLower` con `map` ya que está trabajando con un array.

```js
const dasherize = compose(
  intercalate('-'),
  map(toLower),
  split(' '),
  replace(/\s{2,}/ig, ' '),
);

dasherize('The world is a vampire'); // 'the-world-is-a-vampire'
```

A la hora de depurar, la función `trace` nos permite observar los datos en un cierto punto. Lenguajes como Haskell y PureScript tienen funciones similares para facilitar el desarrollo.

La composición será nuestra herramienta para construir programas y, afortunadamente, está respaldada por una poderosa teoría que asegura que las cosas funcionarán. Examinemos esta teoría.


## Teoría de Categorías

La teoría de categorías es una rama abstracta de las matemáticas que puede formalizar conceptos a partir de distintas ramas como la teoría de conjuntos, la teoría de tipos, la teoría de grupos, lógica, y más. Principalmente maneja objetos, morfismos, y transformaciones, lo cual se asemeja bastante a programar. He aquí una gráfica de los mismos conceptos vistos según las distintas teorías.

<img src="images/cat_theory.png" alt="teoría de categorías" />

Lo siento, no pretendía asustarte. No espero que estés íntimamente familiarizado con todos estos conceptos. Mi intención es mostrarte cuanta duplicación existe y así puedas ver cómo la teoría de categorías tiene por objeto unificar estas cosas.

En la teoría de categorías, tenemos algo que se llama... una categoría. Está definida como una colección con los siguientes componentes:

  * Una colección de objetos
  * Una colección de morfismos
  * Una noción de composición en los morfismos
  * Un morfismo en particular llamado identidad

La teoría de categorías es suficientemente abstracta como para modelar muchas cosas, pero vamos a aplicar esto a tipos y funciones, que es lo que nos importa en este momento.

**Una colección de objetos**
Los objetos serán tipos de datos. Por ejemplo, ``String``, ``Boolean``, ``Number``, ``Object``, etc. Frecuentemente vemos a los tipos de datos como un conjunto de todos los valores posibles. Se puede ver a ``Boolean`` como el conjunto de `[true, false]` y a ``Number`` como el conjunto de todos los valore numéricos posibles. Tratar a los tipos como conjuntos es útil porque podemos utilizar la teoría de conjuntos con ellos.

**Una colección de morfismos**
Los morfismos serán nuestras funciones puras estándar de cada día.

**Una noción de composición en los morfismos**
Esto, como ya habrás adivinado, es nuestro flamante juguete nuevo: `compose`. Hemos visto que nuestra función `compose` es asociativa, lo cual no es una coincidencia, ya que es una propiedad que debe mantenerse para cualquier composición en la teoría de categorías.

Aquí tenemos una imagen que demuestra la composición:

<img src="images/cat_comp1.png" alt="composición de categorías 1" />
<img src="images/cat_comp2.png" alt="composición de categorías 2" />

He aquí un ejemplo concreto en código:

```js
const g = x => x.length;
const f = x => x === 4;
const isFourLetterWord = compose(f, g);
```

**Un morfismo en particular llamado identidad**
Introduzcamos una útil función llamada `id`. Esta función simplemente acepta una entrada y te la escupe de vuelta. Echa un vistazo:

```js
const id = x => x;
```

Quizás te preguntes a tí mismo "¿Para qué demonios puede ser esto útil?". En los siguientes capítulos haremos un uso intensivo de esta función, pero por ahora piensa en ella como una función que puede sustituir a nuestro valor; una función que se hace pasar por datos normales y corrientes.

`id` ha de interactuar bien con compose. Aquí tenemos una propiedad que siempre se cumple para cualquier función unaria f (unaria: función de un solo argumento):

```js
// identidad
compose(id, f) === compose(f, id) === f;
// true
```

¡Eh, es como la propiedad de identidad en los números! Si esto no lo ves claro inmediatamente, dedícale algún tiempo. Entiende la futilidad. Pronto veremos a `id` usada en todas partes, pero por ahora veámosla como a una función que actúa como sustituta de un valor dado. Esto es bastante útil a la hora de escribir código pointfree.

Así que ahí lo tienes, una categoría de tipos y funciones. Si esta es tu primera introducción, imagino que seguirás algo confuso sobre qué es una categoría y su utilidad. Aprenderemos más sobre todo esto a lo largo del libro. Por el momento, en este capítulo, en esta línea, puedes verlo al menos como que nos provee de algo de sabiduría sobre la composición; concretamente sobre las propiedades de identidad y asociatividad.

¿Qué otras categorías hay, te preguntarás? Bien, podemos definir una para grafos dirigidos en la que los nodos son objetos, las aristas son morfismos, y la composición es simplemente una concatenación de caminos. Podemos definir otra con Números como objetos y `>=` como morfismos (en realidad cualquier orden parcial o total puede ser una categoría). Hay montones de categorías, pero para el propósito de este libro solo tendremos en cuenta la definida anteriormente. Hemos mirado por encima lo suficiente y tenemos que seguir.


## En Resumen
La composición conecta nuestras funciones como si de una especie de tuberías se tratase. Los datos fluirán a través de nuestra aplicación como es debido; después de todo las funciones puras van de entrada a salida, por lo que romper esta cadena invalidaría la salida, convirtiendo a nuestro software en inútil.

Consideramos a la composición como el principio de diseño que está por encima de todos los demás. Esto se debe a que mantiene a nuestra app simple y razonable. La teoría de categorías desempeñará un papel importante en la arquitectura de aplicaciones, modelando los efectos secundarios, y asegurando que está libre de errores.

Hemos llegado a un punto donde nos será útil ver algo de esto en la práctica. Hagamos una aplicación de ejemplo.

[Capítulo 6: Aplicación de Ejemplo](ch06-es.md)

## Ejercicios

En cada uno de los siguientes ejercicios, consideraremos objetos Car [*Coche*] con la siguiente forma:

```js
{
  name: 'Aston Martin One-77',
  horsepower: 750,
  dollar_value: 1850000,
  in_stock: true,
}
```


{% exercise %}  
Utiliza `compose()` para reescribir la función de abajo.  
  
{% initial src="./exercises/ch05/exercise_a.js#L12;" %}  
```js  
const isLastInStock = (cars) => {  
  const lastCar = last(cars);  
  return prop('in_stock', lastCar);  
};  
```  
  
{% solution src="./exercises/ch05/solution_a.js" %}  
{% validation src="./exercises/ch05/validation_a.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  


---


Teniendo en cuenta la siguiente función:

```js
const average = xs => reduce(add, 0, xs) / xs.length;
```

{% exercise %}  
Usa la función de soporte `average` para refactorizar `averageDollarValue` a una composición.  
  
{% initial src="./exercises/ch05/exercise_b.js#L7;" %}  
```js  
const averageDollarValue = (cars) => {  
  const dollarValues = map(c => c.dollar_value, cars);  
  return average(dollarValues);  
};  
```  
  
{% solution src="./exercises/ch05/solution_b.js" %}  
{% validation src="./exercises/ch05/validation_b.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  


---


{% exercise %}  
Refactoriza `fastestCar` utilizando `compose()` y otras funciones en estilo pointfree. Pista, la función  
`append` puede resultar útil.  
  
{% initial src="./exercises/ch05/exercise_c.js#L4;" %}  
```js  
const fastestCar = (cars) => {  
  const sorted = sortBy(car => car.horsepower);  
  const fastest = last(sorted);  
  return concat(fastest.name, ' is the fastest');  
};  
```  
  
{% solution src="./exercises/ch05/solution_c.js" %}  
{% validation src="./exercises/ch05/validation_c.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  

[lodash-website]: https://lodash.com/
[underscore-website]: https://underscorejs.org/
[ramda-website]: https://ramdajs.com/
[refactoring-book]: https://martinfowler.com/books/refactoring.html
[extract-function-refactor]: https://refactoring.com/catalog/extractFunction.html
