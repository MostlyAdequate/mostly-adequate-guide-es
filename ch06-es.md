# Capítulo 06: Aplicación de Ejemplo

## Programación Declarativa

Vamos a cambiar nuestra mentalidad. A partir de ahora, dejaremos de decirle al ordenador cómo hacer su trabajo y, en cambio, escribiremos una especificación de lo que nos gustaría obtener como resultado. Estoy seguro de que lo encontrarás mucho menos estresante que intentar microgestionarlo todo continuamente.

Declarativo, al contrario que imperativo, significa que escribiremos expresiones en lugar de instrucciones paso a paso.

Piensa en SQL. No existe un "primero haz esto, luego haz lo otro". Existe una expresión que especifica lo que nos gustaría obtener de la base de datos. Nosotros no decidimos como hacer el trabajo, la base de datos lo decide. Cuando se actualiza la base de datos y el motor de SQL es optimizado, nosotros no tenemos que cambiar nuestra consulta. Se debe a que existen muchas maneras de interpretar nuestra especificación y conseguir el mismo resultado.

Para algunas personas, yo incluido, al principio cuesta comprender el concepto de la programación declarativa, así que vamos a mostrar algunos ejemplos para hacernos una idea.

```js
// imperativo
const makes = [];
for (let i = 0; i < cars.length; i += 1) {
  makes.push(cars[i].make);
}

// declarativo
const makes = cars.map(car => car.make);
```

El bucle imperativo primero debe crear el array. El intérprete debe evaluar esta sentencia antes de continuar. Luego itera directamente sobre la lista de automóviles, incrementando manualmente un contador y mostrándonos sus partes y piezas en una vulgar exhibición de iteración explícita.

La versión con `map` es una sola expresión. No requiere ningún orden de evaluación. Hay mucha libertad en cuanto a la forma en que la función `map` itera y a como debe ser ensamblado el array devuelto. Especifica el *qué*, no el *cómo*. Así pues, es quien lleva puesta la brillante banda declarativa.

Además de ser más clara y más concisa, la función `map` puede ser optimizada a voluntad sin que el valioso código de nuestra aplicación necesite cambiar.

Para aquellos que estén pensando "Sí, pero es mucho más rápido hacer el bucle imperativo", les sugiero que se informen sobre cómo el JIT optimiza su código. Aquí hay un [excelente video que puede arrojar algo de luz](https://www.youtube.com/watch?v=g0ek4vV7nEA).

He aquí otro ejemplo.

```js
// imperativo
const authenticate = (form) => {
  const user = toUser(form);
  return logIn(user);
};

// declarativo
const authenticate = compose(logIn, toUser);
```

Aunque no hay nada necesariamente malo en la versión imperativa, sigue escondiendo una evaluación por pasos. La expresión con `compose` simplemente afirma un hecho: la autenticación es la composición de `toUser` y `logIn`. Nuevamente, esto deja margen de maniobra para permitir cambios en el código, y hace que nuestro código de aplicación sea una especificación de alto nivel.

Como no tenemos que codificar el orden de evaluación, la programación declarativa se presta a la computación paralela. Esto, junto con las funciones puras, es la razón por la que la programación funcional es una buena opción para el futuro paralelo; en realidad no tenemos que hacer nada especial para conseguir sistemas paralelos/concurrentes.

## Un Flickr Con Programación Funcional

Ahora construiremos una aplicación de ejemplo de manera declarativa y usando composición. Por ahora seguiremos haciendo trampas y utilizando efectos secundarios, pero los mantendremos al mínimo y los separaremos de nuestra base de código puro. Vamos a construir un widget para el navegador que obtenga imágenes de Flickr y las muestre. Empecemos creando el andamiaje de la aplicación. Aquí está el html:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Flickr App</title>
  </head>
  <body>
    <main id="js-main" class="main"></main>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.2.0/require.min.js"></script>
    <script src="main.js"></script>
  </body>
</html>
```

Y aquí está esqueleto de main.js

```js
const CDN = s => `https://cdnjs.cloudflare.com/ajax/libs/${s}`;
const ramda = CDN('ramda/0.21.0/ramda.min');
const jquery = CDN('jquery/3.0.0-rc1/jquery.min');

requirejs.config({ paths: { ramda, jquery } });
requirejs(['jquery', 'ramda'], ($, { compose, curry, map, prop }) => {
  // la aplicación va aquí
});
```

Estamos usando [ramda](http://ramdajs.com) en lugar de lodash o cualquier otra librería de utilidades. Incluye `compose`, `curry`, y más. He usado requirejs, hecho que puede parecer exagerado, pero la usaremos a lo largo de todo el libro y mantener la consistencia es clave.

Ahora que hemos dejado esto claro, vamos a la especificación. Nuestra aplicación hará 4 cosas.

1. Construir una url para nuestro término de búsqueda en particular
2. Hacer una llamada a la api de flickr
3. Transformar el json resultante en imágenes html
4. Colocarlas en la pantalla

Arriba se mencionan 2 acciones impuras. ¿Puedes verlas? Esos pedacitos dónde se obtienen datos de la api de flickr y donde se muestran en la pantalla. Definámoslos primero para así poder ponerlos en cuarentena. Además, añadiré nuestra bonita función `trace` para poder depurar fácilmente.

```js
const Impure = {
  getJSON: curry((callback, url) => $.getJSON(url, callback)),
  setHtml: curry((sel, html) => $(sel).html(html)),
  trace: curry((tag, x) => { console.log(tag, x); return x; }),
};
```

Aquí simplemente hemos envuelto los métodos de jQuery para ser currificados y hemos intercambiado los argumentos a una posición más favorable. He agregado las funciones al espacio de nombres `Impure` para saber que son funciones peligrosas. En un futuro ejemplo, haremos que estas dos funciones sean puras.

A continuación debemos construir una url para pasársela a nuestra función `Impure.getJSON`.

```js
const host = 'api.flickr.com';
const path = '/services/feeds/photos_public.gne';
const query = t => `?tags=${t}&format=json&jsoncallback=?`;
const url = t => `https://${host}${path}${query(t)}`;
```

Hay formas extravagantes y demasiado complejas de escribir `url` en estilo pointfree usando monoides (aprenderemos sobre ello más adelante) o combinadores. Hemos optado por quedarnos con una versión más legible y ensamblar esta cadena de una forma no pointfree.

Escribamos una función `app` que haga la llamada y coloque los contenidos en la pantalla.

```js
const app = compose(Impure.getJSON(Impure.trace('response')), url);
app('cats');
```

Esta llama a nuestra función `url`, luego pasa la cadena a nuestra función `getJSON`, que ha sido aplicada parcialmente con `trace`. Cuando arranque la aplicación mostrará por consola la respuesta a la llamada a la API.

<img src="images/console_ss.png" alt="respuesta en la consola" />

Nos gustaría construir imágenes a partir de este json. Parece que las `mediaUrls` están enterradas en la propiedad `m` de `media` de cada uno de los `items`.

De cualquier manera, para llegar a estas propiedades anidadas podemos usar una útil función getter universal de rambda llamada `prop`. Aquí tienes una versión casera para que puedas ver lo que está pasando:

```js
const prop = curry((property, object) => object[property]);
```

Realmente es bastante aburrida. Tan solo usamos la sintaxis `[]` para acceder a una propiedad de cualquier objeto. Vamos a usar esto para llegar a nuestras `mediaUrls`.

```js
const mediaUrl = compose(prop('m'), prop('media'));
const mediaUrls = compose(map(mediaUrl), prop('items'));
```

Una vez hemos reunido a los `items`, debemos aplicarles `map` para extraer cada url. Esto da como resultado un bonito array de `mediaUrls`. Conectemos esto a nuestra aplicación y presentemos las imágenes por pantalla.

```js
var renderImages = _.compose(Impure.setHtml("body"), srcs);
var app = _.compose(Impure.getJSON(renderImages), url);
```

Todo lo que hemos hecho es una nueva composición que llamará a nuestras `mediaUrls` y establecerá el html de `<main>` con ellas. Ahora que tenemos algo para mostrar aparte de un json en crudo, hemos reemplazado la llamada a `trace` por la llamada a `renderImages`. Esto mostrará nuestras `mediaUrls` dentro del `body` de forma cruda.

Nuestro paso final es convertir esas `mediaUrls` en imágenes de verdad. En una aplicación más grande, usaríamos una librería de template/dom como Handlebars o React. Sin embargo, para esta aplicación solo necesitamos una etiqueta `img`, así que vamos a seguir con jQuery.

```js
const img = src => $('<img />', { src });
```

El método `html` de jQuery aceptará un array de etiquetas. Solo tenemos que transformar nuestras `mediaUrls` en imágenes y enviárselas a `setHtml`.

```js
const images = compose(map(img), mediaUrls);
const render = compose(Impure.setHtml('#js-main'), images);
const app = compose(Impure.getJSON(render), url);
```

Y ¡hemos terminado!

<img src="images/cats_ss.png" alt="rejilla de gatos" />

Aquí está el script completo:
[include](./exercises/ch06/main.js)

Mira eso. Una especificación hermosamente declarativa de lo que son las cosas, no de cómo llegan a serlo. Ahora vemos a cada línea como a una ecuación con sus propiedades. Podemos usar estas propiedades para razonar acerca de nuestra aplicación y refactorizarla.

## Una Refactorización Basada En Principios

Hay una optimización disponible; nosotros hacemos `map` sobre cada elemento para convertirlo en una url, luego hacemos nuevamente `map` sobre esas `mediaUrls` para convertirlas en etiquetas `img`. He aquí una ley con respecto a map y la composición:

```js
// ley de composición de map
compose(map(f), map(g)) === map(compose(f, g));
```

Podemos utilizar esta propiedad para optimizar nuestro código. Refactorizemos basándonos en principios.

```js
// código original
const mediaUrl = compose(prop('m'), prop('media'));
const mediaUrls = compose(map(mediaUrl), prop('items'));
const images = compose(map(img), mediaUrls);
```

Pongamos en la misma línea nuestras funciones `map`. Podemos incluir el código de `mediaUrls` directamente en `images` gracias al razonamiento ecuacional y a la pureza.

```js
const mediaUrl = compose(prop('m'), prop('media'));
const images = compose(map(img), map(mediaUrl), prop('items'));
```

Ahora que tenemos a nuestras funciones `map` en la misma línea podemos aplicar la ley de la composición.

```js
/*
compose(map(f), map(g)) === map(compose(f, g));
compose(map(img), map(mediaUrl)) === map(compose(img, mediaUrl));
*/

const mediaUrl = compose(prop('m'), prop('media'));
const images = compose(map(compose(img, mediaUrl)), prop('items'));
```

Ahora, al convertir cada elemento en una `img`, solo recorrerá el bucle una vez. Hagámoslo un poco más legible extrayendo la función.

```js
const mediaUrl = compose(prop('m'), prop('media'));
const mediaToImg = compose(img, mediaUrl);
const images = compose(map(mediaToImg), prop('items'));
```

## En Resumen

Hemos visto con una aplicación pequeña, pero real, como poner en práctica nuestras nuevas habilidades. Hemos utilizado nuestro marco matemático para razonar sobre nuestro código y refactorizarlo. Pero ¿qué hay del manejo de errores y la ramificación de código? ¿Cómo podemos hacer que toda la aplicación sea completamente pura en vez de tan solo agregar a un espacio de nombres las funciones destructivas? ¿Cómo podemos hacer que nuestra aplicación sea más segura y expresiva? Estas son las preguntas que abordaremos en la parte 2.

[Capítulo 7: Hindley-Milner y Yo](ch07-es.md)
