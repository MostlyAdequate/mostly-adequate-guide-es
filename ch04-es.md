# Capítulo 04: Currificación

## No Puedo Vivir Si Vivir Es Sin Ti
[*El título en inglés es 'Can't Live If Livin' Is without You' que recuerda a la canción "Without You" de Badfinger*]

Mi padre una vez me explicó como hay ciertas cosas sin las que se puede vivir hasta que las compras. Un microondas es una de esas cosas. Los smartphones, otra. Los más mayores de nosotros recordarán una vida de plenitud sin internet. Para mí, la `currificación` [*currying en inglés*] está en esta lista.

El concepto es sencillo: Puedes llamar a una función con menos argumentos de los que espera. Esta devuelve una función que espera los argumentos restantes.

Puedes elegir llamarla con todos sus argumentos de una vez o simplemente pasarle cada argumento poco a poco.

```js
const add = x => y => x + y;
const increment = add(1);
const addTen = add(10);

increment(2); // 3
addTen(2); // 12
```

Aquí hemos hecho una función `add` que acepta un argumento y devuelve una función. A partir de entonces, al llamarla, la función devuelta recuerda el primer argumento mediante la closure. Sin embargo, llamarla con ambos argumentos de una vez es un poco molesto, por lo que podemos utilizar una función de soporte especial llamada `curry` para facilitar la definición y la llamada de funciones como esta.

Vamos a preparar unas pocas funciones currificadas para nuestro disfrute. Desde ahora, nos 
apoyaremos en nuestra función `curry` definida en el [Apéndice A - Funciones Esenciales de Soporte](./appendix_a-es.md).

```js
const match = curry((what, s) => s.match(what));
const replace = curry((what, replacement, s) => s.replace(what, replacement));
const filter = curry((f, xs) => xs.filter(f));
const map = curry((f, xs) => xs.map(f));
```

El patrón que he seguido es uno simple, pero importante. He posicionado estratégicamente los datos sobre los que vamos a operar (String, Array) como último argumento. Quedará mas claro por qué cuando lo usemos.

(La sintaxis `/r/g` es una expresión regular que significa _encuentra todas las letras 'r'_. Lee [más sobre expresiones regulares](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions) si quieres.)

```js
match(/r/g, 'hello world'); // [ 'r' ]

const hasLetterR = match(/r/g); // x => x.match(/r/g)
hasLetterR('hello world'); // [ 'r' ]
hasLetterR('just j and s and t etc'); // null

filter(hasLetterR, ['rock and roll', 'smooth jazz']); // ['rock and roll']

const removeStringsWithoutRs = filter(hasLetterR); // xs => xs.filter(x => x.match(/r/g))
removeStringsWithoutRs(['rock and roll', 'smooth jazz', 'drum circle']); // ['rock and roll', 'drum circle']

const noVowels = replace(/[aeiou]/ig); // (r,x) => x.replace(/[aeiou]/ig, r)
const censored = noVowels('*'); // x => x.replace(/[aeiou]/ig, '*')
censored('Chocolate Rain'); // 'Ch*c*l*t* R**n'
```

Lo que demostramos aquí es la habilidad para precargar una función con un argumento o dos con el fin de recibir una nueva función que recuerda dichos argumentos.

Os aliento a clonar el repositorio de Mostly Adequate (`git clone
https://github.com/MostlyAdequate/mostly-adequate-guide-es.git`), copiar el código anterior y probarlo en la consola REPL. La función curry, igual que cualquier cosa definida en los apéndices, están disponibles en el módulo `support/index.js`.

Alternativamente, dale un vistazo a la versión en inglés publicada en `npm`:

```
npm install @mostly-adequate/support
```

## Más Que Un Juego de Palabras / Salsa Especial

La currificación es útil para muchas cosas. Podemos hacer nuevas funciones solo pasando algunos argumentos a nuestras funciones base, tal y como hemos visto en `hasLetterR`, `removeStringsWithoutRs` y `censored`.

También tenemos la habilidad para transformar cualquier función que trabaje con un solo elemento en una función que trabaje con una lista, simplemente envolviéndola con `map`: 

```js
const getChildren = x => x.childNodes;
const allTheChildren = map(getChildren);
```

Pasar a una función menos argumentos de los que espera, típicamente se conoce como *aplicación parcial*. Aplicar parcialmente una función puede quitar mucho código repetitivo. Considera como sería la función anterior `allTheChildren` con el `map` sin currificación de lodash (fíjate que los argumentos están en diferente orden):

```js
const allTheChildren = elements => map(elements, getChildren);
```

Normalmente no definimos funciones que trabajan con arrays, porque simplemente podemos llamar en línea a `map(getChildren)`. Lo mismo con `sort`, `filter`, y otras funciones de alto orden (una *función de alto orden* es una función que acepta o devuelve una función).

Cuando hablábamos de *funciones puras*, dijimos que llevan de 1 entrada a 1 salida. La currificación hace exactamente eso: cada uno de los argumentos devuelve una nueva función que espera los argumentos restantes. Eso, viejo amigo, es 1 entrada a 1 salida.

No importa si la salida es otra función; califica como pura. Permitimos más de un argumento a la vez, pero viéndolo tan solo como para quitar por conveniencia los `()` adicionales.

## En resumen

Las currificación es práctica y disfruto mucho trabajando diariamente con funciones currificadas. Es una herramienta para el cinturón que hace a la programación funcional menos verbosa y tediosa.

Podemos crear al vuelo nuevas y útiles funciones, simplemente pasándole unos pocos argumentos y además, retenemos la definición de función matemática a pesar de sus múltiples argumentos.

Adquiramos otra herramienta esencial llamada `compose`.

[Capitulo 5: Programando por Composición](ch05-es.md)

## Ejercicios

#### Nota sobre los ejercicios

A lo largo del libro, podrás encontrar una sección 'Ejercicios' como esta. Los ejercicios pueden hacerse directamente en el navegador siempre que estés leyendo desde [gitbook](https://mostly-adequate.gitbooks.io/mostly-adequate-guide) (recomendado).

Fíjate que, para todos los ejercicios del libro, siempre tienes en el contexto global unas útiles funciones de ayuda. Por lo tanto, ¡cualquier cosa definida en el [Apéndice A](./appendix_a-es.md), [Apéndice B](./appendix_b-es.md) y [Apéndice C](./appendix_c-es.md) está disponible para ti! Y, por si esto fuera poco, algunos ejercicios también definen funciones específicas al problema que presentan; de hecho, también considéralas disponibles.

> Sugerencia: ¡puedes enviar tu solución con `Ctrl + Enter` en el editor embebido!

#### Ejecutando Los Ejercicios En Tu Máquina (opcional)

En caso de preferir hacer los ejercicios directamente en archivos usando tu propio editor:

- clona el repositorio (`git clone git@github.com:MostlyAdequate/mostly-adequate-guide-es.git`)
- ve a la sección *exercises* (`cd mostly-adequate-guide-es/exercises`)
- instala lo necesario usando [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) (`npm install`)
- completa las respuestas modificando los archivos llamados *exercise_&ast;* dentro del directorio del correspondiente capítulo 
- ejecuta la corrección con npm (p. ej. `npm run ch04`)

Los tests unitarios se ejecutarán con tus respuestas y darán sugerencias en caso de error. Por cierto, las respuestas a los ejercicios están en los archivos llamados *solution_&ast;*.

#### ¡Practiquemos!

{% exercise %}  
Refactoriza para quitar todos los argumentos aplicando parcialmente la función.
  
{% initial src="./exercises/ch04/exercise_a.js#L3;" %}  
```js  
const words = str => split(' ', str);  
```  
  
{% solution src="./exercises/ch04/solution_a.js" %}  
{% validation src="./exercises/ch04/validation_a.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  


---


{% exercise %}  
Refactoriza para quitar todos los argumentos aplicando parcialmente las funciones.
  
{% initial src="./exercises/ch04/exercise_b.js#L3;" %}  
```js  
const filterQs = xs => filter(x => match(/q/i, x), xs);
```  
  
{% solution src="./exercises/ch04/solution_b.js" %}  
{% validation src="./exercises/ch04/validation_b.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  


---


Teniendo en cuenta la siguiente función:

```js  
const keepHighest = (x, y) => (x >= y ? x : y);  
```  

{% exercise %}  
Refactoriza `max` para que no haga referencia a ningún argumento usando la función de ayuda `keepHighest`.  
  
{% initial src="./exercises/ch04/exercise_c.js#L7;" %}  
```js  
const max = xs => reduce((acc, x) => (x >= acc ? x : acc), -Infinity, xs);  
```  
  
{% solution src="./exercises/ch04/solution_c.js" %}  
{% validation src="./exercises/ch04/validation_c.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
