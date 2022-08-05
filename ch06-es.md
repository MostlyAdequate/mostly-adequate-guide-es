# Capítulo 6: Aplicación de ejemplo

## Codificación declarativa

Cambiaremos nuestra mentalidad. De aquí en adelante, dejaremos de decirle al computador cómo hacer su trabajo y, en su lugar, escribiremos una especificación de los que nos gustaría como resultado. Estoy seguro que lo encontrarás mucho menos estresante que intentar microgestionarlo todo, todo el tiempo.

Declarativo, a diferencia de imperativo, significa que escribiremos expresiones, en lugar de instrucciones paso a paso.

Piensa en SQL. No existe un "primero haz esto, luego haz esto". Existe una expresión que especifica lo que nos gustaría obtener de la base de datos. Nosotros no decidimos cómo hacer el trabajo, la base de datos lo decide. Cuando se actualiza la base de datos y el motor de SQL es optimizado, nosotros no tenemos que cambiar nuestra consulta. Se debe a que existen muchas maneras de interpretar nuestra especificación y conseguir el mismo resultado.

Para algunas personas, incluyéndome, al principio es dificil comprender el concepto de la codificación declarativa, así que vamos a mostrar algunos ejemplos para tener una mejor idea de lo que se trata.

```js
// imperativo
var makes = [];
for (i = 0; i < cars.length; i++) {
  makes.push(cars[i].make);
}

// declarativo
var makes = cars.map(function(car){ return car.make; });
```

El bucle imperativo primero debe instanciar el array. El intérprete debe evaluar esta sentencia antes de continuar. Luego itera directamente a través de la lista de carros, incrementando manualmente un contador y mostrándonos sus partes y piezas en una forma vulgar de iteración explícita.

La versión con el `map` es una expresión. No requiere ningún orden de evaluación. Hay mucha libertad aquí para ver cómo la función `map` itera y cómo el array devuelto puede ser construido. Se especifica el *qué*, no el *cómo*. De este modo, se viste con el cinturón brillante declarativo.

Además de ser más claro y más conciso, la función `map` puede ser optimizada a voluntad y el valioso código de nuestra aplicación no necesita cambiar.

Para aquellos de ustedes que estan pensando "Sí, pero es mucho más rápido hacer el bucle imperativo", Te sugiero que te eduques tu mismo acerca de cómo el JIT optimiza tu código. Aquí tienes un [excelente video que puede darte una idea](https://www.youtube.com/watch?v=65-RbBwZQdU).

Aquí hay otro ejemplo.

```js
// imperativo
var authenticate = function(form) {
  var user = toUser(form);
  return logIn(user);
};

// declarativo
var authenticate = compose(logIn, toUser);
```

Aunque no hay nada malo con la versión imperativa, todavía hay una evaluación codificada paso a paso cocinándose. La expresión `compose` simplemente afirma un hecho: `Authentication` es la composición de `toUser` y `logIn`. Nuevamente, esto deja espacio suficiente para soportar cambios en el código, lo que se traduce en tener un código de alto nivel de especificación en nuestra aplicación.

Debigo que no estamos codificando el orden de evaluación, la codificación declarativa se presta para la computación paralela. Esto, junto con funciones puras es la razón por la que la programación funcional es una buena opción para el futuro paralelo - realmente no tenemos que hacer nada especial para conseguir sistemas paralelos/concurrentes.

## Un Flickr hecho con programación funcional

Ahora construiremos una aplicación de ejemplo de una manera compuesta y declarativa. Por el momento usaremos trucos y herramientas secundarias, pero los mantendremos al mínimo y por separado de nuestro código base. Vamos a construir un widget para el navegador que obtegna imágenes de Flickr y las muestre. Empecemos creando la aplicación. Aquí está el html:

```html
<!DOCTYPE html>
<html>
  <head>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.1.11/require.min.js"></script>
    <script src="flickr.js"></script>
  </head>
  <body></body>
</html>
```

Y aquí está la estructura del flickr.js

```js
requirejs.config({
  paths: {
    ramda: 'https://cdnjs.cloudflare.com/ajax/libs/ramda/0.13.0/ramda.min',
    jquery: 'https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min'
  }
});

require([
    'ramda',
    'jquery'
  ],
  function (_, $) {
    var trace = _.curry(function(tag, x) {
      console.log(tag, x);
      return x;
    });
    // la aplicación va aquí
  });
```

Estamos usando [ramda](http://ramdajs.com) en lugar de lodash o cualquier otra librería de utilidades. Incluye `compose`, `curry`, y más. He usado requirejs, que puede parecer un poco exagerado, sin embargo lo estaremos usando a través del libro y, la consistencia es la clave. También, he empezado con una bonita función `trace` para facilitar la depuración.

Ahora que eso está fuera de nuestro camino, vamos a las especificaciones. Nuestra aplicación hará 4 cosas.

1. Construir una url para nuestro término de búsqueda en particular
2. Hacer una llamada al API de Flickr
3. Transformar la respuesta json en imágenes html
4. Colocarlas en la pantalla

Hay 2 acciones impuras mencionadas anteriormente. ¿Puedes verlas? Esos pedacitos dónde se obtienen datos de la API de Flickr y dónde se muestran en la pantalla. Vamos a definirlos primero para qué así podamos aislarlos.

```js
var Impure = {
  getJSON: _.curry(function(callback, url) {
    $.getJSON(url, callback);
  }),

  setHtml: _.curry(function(sel, html) {
    $(sel).html(html);
  })
};
```

Aquí simplemente hemos envuelto los métodos de jQuery para ser curried y hemos movido los argumentos a una posición más favorable. Las he agregado al namespace `Impure` así sabremos que estas son funciones peligrosas.

A continuación debemos construir una url para pasarla a nuestra función `Impure.getJSON`.

```js
var url = function (term) {
  return 'https://api.flickr.com/services/feeds/photos_public.gne?tags=' +
    term + '&format=json&jsoncallback=?';
};
```

Hay muchas formas fáciles y otras demasiado complejas de escribir `url` pointfree usando monoides[^aprenderemos qué son más adelante] o combinadores. Nos hemos apegado a una versión más legible y armamos esta cadena de una forma común y corriente.

Vamos a escribir una función `app` que haga la llamada y coloque los contenidos en la pantalla.

```js
var app = _.compose(Impure.getJSON(trace("response")), url);

app("cats");
```

Esta llama a nuestra función `url`, luego pasa la cadena a nuestra función `getJSON`, la que ha sido aplicada parcialmente con `trace`. Cuando la aplicación se cargue mostrará la respuesta de la llamada a la API en la consola.

<img src="images/console_ss.png"/>

Nos gustaría construir imágenes a partir de este json. Parece qué los `src` están incluidos en la propiedad `m` de `media` para cada `items`.

De cualquier manera, para llegar a estas propiedades anidadas podemos usar una bonita función getter universal de rambda llamada `_.prop()`. Aquí tienes una versión hecha a mano para que puedas ver lo qué está pasando:

```js
var prop = _.curry(function(property, object){
  return object[property];
});
```

Realmente es bastante aburrida. Sólo usamos la sintaxis `[]` para acceder a una propiedad en cualquier objeto. Vamos a usar esto para llegar a nuestros `src`.

```js
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var srcs = _.compose(_.map(mediaUrl), _.prop('items'));
```

Una vez reunamos los `items`, debemos aplicarles `map` para extraer cada url. Esto da como resultado un bonito array de urls. Vamos a conectar esto a nuestra aplicación e imprimir las imágenes en la pantalla.

```js
var renderImages = _.compose(Impure.setHtml("body"), srcs);
var app = _.compose(Impure.getJSON(renderImages), url);
```

Todo lo qué hemos hecho es hacer una nueva composición que llamará a nuestros `srcs`y establecerá el html del `body` con ellos. Hemos remplazado la llamada a `trace` con `renderImages` ahora que tenemos algo para mostrar además de un json crudo. Esto mostrará crudamente nuestros `srcs` directamente en el `body`.

Nuestro paso final es convertir esos `srcs` en imágenes de buena fé. En una aplicación más grande, usaríamos una librería para template/dom como Handlebars o React. Sin embargo, para esta aplicación, sólo necesitamos una etiqueta `img` así que vamos a seguir con jQuery.

```js
var img = function (url) {
  return $('<img />', { src: url });
};
```

El método `html()` de jQuery aceptará un array de etiquetas. Sólo tenemos que transformar nuestros `srcs` en imágenes y enviarselas a `setHtml`.

```js
var images = _.compose(_.map(img), srcs);
var renderImages = _.compose(Impure.setHtml("body"), images);
var app = _.compose(Impure.getJSON(renderImages), url);
```

Y ¡hemos terminado!

<img src="images/cats_ss.png" />

Aquí está el script completo:

```js
requirejs.config({
  paths: {
    ramda: 'https://cdnjs.cloudflare.com/ajax/libs/ramda/0.13.0/ramda.min',
    jquery: 'https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min'
  }
});

require([
    'ramda',
    'jquery'
  ],
  function (_, $) {
    ////////////////////////////////////////////
    // Utilidades

    var Impure = {
      getJSON: _.curry(function(callback, url) {
        $.getJSON(url, callback);
      }),

      setHtml: _.curry(function(sel, html) {
        $(sel).html(html);
      })
    };

    var img = function (url) {
      return $('<img />', { src: url });
    };

    var trace = _.curry(function(tag, x) {
      console.log(tag, x);
      return x;
    });

    ////////////////////////////////////////////

    var url = function (t) {
      return 'http://api.flickr.com/services/feeds/photos_public.gne?tags=' +
        t + '&format=json&jsoncallback=?';
    };

    var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

    var srcs = _.compose(_.map(mediaUrl), _.prop('items'));

    var images = _.compose(_.map(img), srcs);

    var renderImages = _.compose(Impure.setHtml("body"), images);

    var app = _.compose(Impure.getJSON(renderImages), url);

    app("cats");
  });
```

Ahora mira eso. Una especificación hermosamente declarativa de lo que son las cosas, no cómo llegan a ser. Ahora vemos cada línea como una ecuación con las propiedades que poseen. Podemos usar estas propiedades para razonar acerca de nuestra aplicación y refactorizar.

## Un refactor basado en principios

Hay una optimización disponible - nosotros hacemos `map` sobre cada elemento para convertirlo en una url, luego hacemos nuevamente `map` sobre esas urls para convertirlas en etiquetas `img`. Hay una ley con respecto a `map` y `composition`:

```js
// ley de composición para map
var law = compose(map(f), map(g)) == map(compose(f, g));
```

Podemos usar esta propiedad para optimizar nuestro código. Hagamos un refactor basado en principios.

```js
// código original
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var srcs = _.compose(_.map(mediaUrl), _.prop('items'));

var images = _.compose(_.map(img), srcs);

```

Alineemos nuestras funciones `map`. Podemos hacer la llamada a `srcs` en `images` gracias al razonamiento ecuacional y pureza.

```js
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var images = _.compose(_.map(img), _.map(mediaUrl), _.prop('items'));
```

Ahora que hemos alineado nuestras funciones `map` podemos aplicar la ley de composición.

```js
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var images = _.compose(_.map(_.compose(img, mediaUrl)), _.prop('items'));
```

Ahora solamente iteraremos una vez cuando estemos convirtiendo cada elemento en una imágen. Vamos a hacerlo un poco más legible extrayendo la función.

```js
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var mediaToImg = _.compose(img, mediaUrl);

var images = _.compose(_.map(mediaToImg), _.prop('items'));
```

## En resumen

Hemos visto cómo poner nuestras nuevas habilidades en uso con una aplicación pequeña, pero real. Hemos usado nuestro framework matemático para razonar y refactorizar nuestro código. ¿Pero qué hay del manejo de errores y la ramificación de código? ¿Cómo podemos hacer la aplicación completamente pura en vez de simplemente agregar funciones destructivas a un namespace? ¿Cómo podemos hacer nuestra aplicación más segura y expresiva? Estas son preguntas qué abordaremos en la parte 2.

[Capítulo 7: Hindley-Milner y yo](ch7-es.md)
