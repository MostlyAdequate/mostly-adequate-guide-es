# Chapter 6: Example Application

# Capítulo 6: Aplicación de ejemplo

## Declarative coding

## Codificación declarativa

We are going to switch our mindset. From here on out, we'll stop telling the computer how to do its job and instead write a specification of what we'd like as a result. I'm sure you'll find it much less stressful than trying to micromanage everything all the time.

Cambiaremos nuestra mentalidad. De aquí en adelante, dejaremos de decirle al computador cómo hacer su trabajo y, en su lugar, escribiremos una especificación de los que nos gustaría como resultado. Estoy seguro que lo encontrarás mucho menos estresante que intentar microgestionarlo todo, todo el tiempo.

Declarative, as opposed to imperative, means that we will write expressions, as opposed to step by step instructions.

Declarativo, a diferencia de imperativo, significa que escribiremos expresiones, en lugar de instrucciones paso a paso.

Think of SQL. There is no "first do this, then do that". There is one expression that specifies what would like from the database. We don't decide how to do the work, it does. When the database is upgraded and the SQL engine optimized, we don't have to change our query. This is because there are many ways to interpret our specification and achieve the same result.

Piensa en SQL. No existe un "primero haz esto, luego haz esto". Existe una expresión que especifica lo que nos gustaría obtener de la base de datos. Nosotros no decidimos cómo hacer el trabajo, la base de datos lo decide. Cuando se actualiza la base de datos y el motor de SQL es optimizado, nosotros no tenemos que cambiar nuestra consulta. Se debe a que existen muchas maneras de interpretar nuestra especificación y conseguir el mismo resultado.

For some folks, myself included, it's hard to grasp the concept of declarative coding at first so let's point out a few examples to get a feel for it.

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

The imperative loop must first instantiate the array. The interpreter must evaluate this statement before moving on. Then it directly iterates through the list of cars, manually increasing a counter and showing its bits and pieces to us in a vulgar display of explicit iteration.

El bucle imperativo primero debe instanciar el array. El intérprete debe evaluar esta sentencia antes de continuar. Luego itera directamente a través de la lista de carros, incrementando manualmente un contador y mostrándonos sus partes y piezas en una forma vulgar de iteración explícita.

The `map` version is one expression. It does not require any order of evaluation. There is much freedom here for how the map function iterates and how the returned array may be assembled. It specifies *what*, not *how*. Thus, it wears the shiny declarative sash.

La versión con el `map` es una expresión. No requiere ningún orden de evaluación. Hay mucha libertad aquí para ver cómo la función `map` itera y cómo el array devuelto puede ser construido. Se especifica el *qué*, no el *cómo*. De este modo, se viste con el cinturón brillante declarativo.

In addition to being clearer and more concise, the map function may be optimized at will and our precious application code needn't change.

Además de ser más claro y más conciso, la función `map` puede ser optimizada a voluntad y el valioso código de nuestra aplicación no necesita cambiar.

For those of you who are thinking "Yes, but it's much faster to do the imperative loop", I suggest you educate yourself on how the JIT optimizes your code. Here's a [terrific video that may shed some light](https://www.youtube.com/watch?v=65-RbBwZQdU)

Para aquellos de ustedes que estan pensando "Sí, pero es mucho más rápido hacer el bucle imperativo", Te sugiero que te eduques tu mismo acerca de cómo el JIT optimiza tu código. Aquí tienes un [excelente video que puede darte una idea](https://www.youtube.com/watch?v=65-RbBwZQdU).

Here is another example.

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

Though there's nothing necessarily wrong with the imperative version, there is still an encoded step-by-step evaluation baked in. The `compose` expression simply states a fact: Authentication is the composition of `toUser` and `logIn`. Again, this leaves wiggle room for support code changes and results in our application code being a high level specification.

Aunque no hay nada malo con la versión imperativa, todavía hay una evaluación codificada paso a paso cocinándose. La expresión `compose` simplemente afirma un hecho: `Authentication` es la composición de `toUser` y `logIn`. Nuevamente, esto deja espacio suficiente para soportar cambios en el código, lo que se traduce en tener un código de alto nivel de especificación en nuestra aplicación.

Because we are not encoding order of evaluation, declarative coding lends itself to parallel computing. This coupled with pure functions is why FP is a good option for the parallel future - we don't really need to do anything special to achieve parallel/concurrent systems.

Debigo que no estamos codificando el orden de evaluación, la codificación declarativa se presta para la computación paralela. Esto, junto con funciones puras es la razón por la que la programación funcional es una buena opción para el futuro paralelo - realmente no tenemos que hacer nada especial para conseguir sistemas paralelos/concurrentes.

## A flickr of functional programming

## Un Flickr hecho con programación funcional

We will now build an example application in a declarative, composable way. We'll still cheat and use side effects for now, but we'll keep them minimal and separate from our pure codebase. We are going to build a browser widget that sucks in flickr images and displays them. Let's start by scaffolding the app. Here's the html:

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

And here's the flickr.js skeleton:

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

We're pulling in [ramda](http://ramdajs.com) instead of lodash or some other utility library. It includes `compose`, `curry`, and more. I've used requirejs, which may seem like overkill, but we'll be using it throughout the book and consistency is key. Also, I've started us off with our nice `trace` function for easy debugging.

Estamos usando [ramda](http://ramdajs.com) en lugar de lodash o cualquier otra librería de utilidades. Incluye `compose`, `curry`, y más. He usado requirejs, que puede parecer un poco exagerado, sin embargo lo estaremos usando a través del libro y, la consistencia es la clave. También, he empezado con una bonita función `trace` para facilitar la depuración.

Now that that's out of the way, on to the spec. Our app will do 4 things.

Ahora que eso está fuera de nuestro camino, vamos a las especificaciones. Nuestra aplicación hará 4 cosas.

1. Construct a url for our particular search term
2. Make the flickr api call
3. Transform the resulting json into html images
4. Place them on the screen


1. Construir una url para nuestro término de búsqueda en particular
2. Hacer una llamada al API de Flickr
3. Transformar la respuesta json en imágenes html
4. Colocarlas en la pantalla

There are 2 impure actions mentioned above. Do you see them? Those bits about getting data from the flickr api and placing it on the screen. Let's define those first so we can quarantine them.

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

Here we've simply wrapped jQuery's methods to be curried and we've swapped the arguments to a more favorable position. I've namespaced them with `Impure` so we know these are dangerous functions. In a future example, we will make these two functions pure.

Aquí simplemente hemos envuelto los métodos de jQuery para ser curried y hemos movido los argumentos a una posición más favorable. Las he agregado al namespace `Impure` así sabremos que estas son funciones peligrosas.

Next we must construct a url to pass to our `Impure.getJSON` function.

A continuación debemos construir una url para pasarla a nuestra función `Impure.getJSON`.

```js
var url = function (term) {
  return 'https://api.flickr.com/services/feeds/photos_public.gne?tags=' +
    term + '&format=json&jsoncallback=?';
};
```

There are fancy and overly complex ways of writing `url` pointfree using monoids[^we'll learn about these later] or combinators. We've chosen to stick with a readable version and assemble this string in the normal pointful fashion.

Hay muchas formas fáciles y otras demasiado complejas de escribir `url` pointfree usando monoides[^aprenderemos qué son más adelante] o combinadores. Nos hemos apegado a una versión más legible y armamos esta cadena de una forma común y corriente.

Let's write an app function that makes the call and places the contents on the screen.

Vamos a escribir una función `app` que haga la llamada y coloque los contenidos en la pantalla.

```js
var app = _.compose(Impure.getJSON(trace("response")), url);

app("cats");
```

This calls our `url` function, then passes the string to our `getJSON` function, which has been partially applied with `trace`. Loading the app will show the response from the api call in the console.

Esta llama a nuestra función `url`, luego pasa la cadena a nuestra función `getJSON`, la que ha sido aplicada parcialmente con `trace`. Cuando la aplicación se cargue mostrará la respuesta de la llamada a la API en la consola.

<img src="images/console_ss.png"/>

We'd like to construct images out of this json. It looks like the srcs are buried in `items` then each `media`'s `m` property.

Nos gustaría construir imágenes a partir de este json. Parece qué los `src` están incluidos en la propiedad `m` de `media` para cada `items`.

Anyhow, to get at these nested properties we can use a nice universal getter function from ramda called `_.prop()`. Here's a homegrown version so you can see what's happening:

De cualquier manera, para llegar a estas propiedades anidadas podemos usar una bonita función getter universal de rambda llamada `_.prop()`. Aquí tienes una versión hecha a mano para que puedas ver lo qué está pasando:

```js
var prop = _.curry(function(property, object){
  return object[property];
});
```

It's quite dull actually. We just use `[]` syntax to access a property on whatever object. Let's use this to get at our srcs.

Realmente es bastante aburrida. Sólo usamos la sintaxis `[]` para acceder a una propiedad en cualquier objeto. Vamos a usar esto para llegar a nuestros `src`.

```js
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var srcs = _.compose(_.map(mediaUrl), _.prop('items'));
```

Once we gather the `items`, we must `map` over them to extract each media url. This results in a nice array of srcs. Let's hook this up to our app and print them on the screen.

Una vez reunamos los `items`, debemos aplicarles `map` para extraer cada url. Esto da como resultado un bonito array de urls. Vamos a conectar esto a nuestra aplicación e imprimir las imágenes en la pantalla.

```js
var renderImages = _.compose(Impure.setHtml("body"), srcs);
var app = _.compose(Impure.getJSON(renderImages), url);
```

All we've done is make a new composition that will call our `srcs` and set the body html with them. We've replaced the `trace` call with `renderImages` now that we have something to render besides raw json. This will crudely display our srcs directly in the body.

Todo lo qué hemos hecho es hacer una nueva composición que llamará a nuestros `srcs`y establecerá el html del `body` con ellos. Hemos remplazado la llamada a `trace` con `renderImages` ahora que tenemos algo para mostrar además de un json crudo. Esto mostrará crudamente nuestros `srcs` directamente en el `body`.

Our final step is to turn these srcs into bonafide images. In a bigger application, we'd use a template/dom library like Handlebars or React. For this application though, we only need an img tag so let's stick with jQuery.

Nuestro paso final es convertir esos `srcs` en imágenes de buena fé. En una aplicación más grande, usaríamos una librería para template/dom como Handlebars o React. Sin embargo, para esta aplicación, sólo necesitamos una etiqueta `img` así que vamos a seguir con jQuery.

```js
var img = function (url) {
  return $('<img />', { src: url });
};
```

jQuery's `html()` method will accept an array of tags. We only have to transform our srcs into images and send them along to `setHtml`.

El método `html()` de jQuery aceptará un array de etiquetas. Sólo tenemos que transformar nuestros `srcs` en imágenes y enviarselas a `setHtml`.

```js
var images = _.compose(_.map(img), srcs);
var renderImages = _.compose(Impure.setHtml("body"), images);
var app = _.compose(Impure.getJSON(renderImages), url);
```

And we're done!

Y ¡hemos terminado!

<img src="images/cats_ss.png" />

Here is the finished script:

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

Now look at that. A beautifully declarative specification of what things are, not how they come to be. We now view each line as an equation with properties that hold. We can use these properties to reason about our application and refactor.

Ahora mira eso. Una especificación hermosamente declarativa de lo que son las cosas, no cómo llegan a ser. Ahora vemos cada línea como una ecuación con las propiedades que poseen. Podemos usar estas propiedades para razonar acerca de nuestra aplicación y refactorizar.

## A Principled Refactor

## Un refactor basado en principios

There is an optimization available - we map over each item to turn it into a media url, then we map again over those srcs to turn them into img tags. There is a law regarding map and composition:

Hay una optimización disponible - nosotros hacemos `map` sobre cada elemento para convertirlo en una url, luego hacemos nuevamente `map` sobre esas urls para convertirlas en etiquetas `img`. Hay una ley con respecto a `map` y `composition`:

```js
// map's composition law
// ley de composición para map
var law = compose(map(f), map(g)) == map(compose(f, g));
```

We can use this property to optimize our code. Let's have a principled refactor.

Podemos usar esta propiedad para optimizar nuestro código. Hagamos un refactor basado en principios.

```js
// código original
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var srcs = _.compose(_.map(mediaUrl), _.prop('items'));

var images = _.compose(_.map(img), srcs);

```

Let's line up our maps. We can inline the call to `srcs` in `images` thanks to equational reasoning and purity.

Alineemos nuestras funciones `map`. Podemos hacer la llamada a `srcs` en `images` gracias al razonamiento ecuacional y pureza.

```js
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var images = _.compose(_.map(img), _.map(mediaUrl), _.prop('items'));
```

Now that we've lined up our `map`'s we can apply the composition law.

Ahora que hemos alineado nuestras funciones `map` podemos aplicar la ley de composición.

```js
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var images = _.compose(_.map(_.compose(img, mediaUrl)), _.prop('items'));
```

Now the bugger will only loop once while turning each item into an img. Let's just make it a little more readable by extracting the function out.

Ahora solamente iteraremos una vez cuando estemos convirtiendo cada elemento en una imágen. Vamos a hacerlo un poco más legible extrayendo la función.

```js
var mediaUrl = _.compose(_.prop('m'), _.prop('media'));

var mediaToImg = _.compose(img, mediaUrl);

var images = _.compose(_.map(mediaToImg), _.prop('items'));
```

## In Summary

## En resumen

We have seen how to put our new skills into use with a small, but real world app. We've used our mathematical framework to reason about and refactor our code. But what about error handling and code branching? How can we make the whole application pure instead of merely namespacing destructive functions? How can we make our app safer and more expressive? These are the questions we will tackle in part 2.

Hemos visto cómo poner nuestras nuevas habilidades en uso con una aplicación pequeña, pero real. Hemos usado nuestro framework matemático para razonar y refactorizar nuestro código. ¿Pero qué hay del manejo de errores y la ramificación de código? ¿Cómo podemos hacer la aplicación completamente pura en vez de simplemente agregar funciones destructivas a un namespace? ¿Cómo podemos hacer nuestra aplicación más segura y expresiva? Estas son preguntas qué abordaremos en la parte 2.

[Chapter 7: Hindley-Milner and Me](ch7.md)

[Capítulo 7: Hindley-Milner y yo](ch7-es.md)
