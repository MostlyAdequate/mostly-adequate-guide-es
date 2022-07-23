# Capítulo 2: Funciones de primera clase

## Una revisión rápida
Cuando decimos que las funciones son de "primera clase", queremos decir que son como todas los demás... una clase normal[^clase turista?]. Podemos tratar a las funciones como cualquier otro tipo de dato y no hay nada particularmente especial en ellas - almacenarlas en arrays, pasarlas a todos lados, asignarlas a variables, lo que quieras.

Ese es JavaScript 101, pero vale la pena mencionar como una rápida búsqueda de código en GitHub mostrará la evasión colectiva, o tal vez la ignorancia generalizada del concepto. ¿Deberíamos mostrar un ejemplo fingido? Deberíamos.

```js
var hi = function(name){
  return "Hi " + name;
};

var greeting = function(name) {
  return hi(name);
};
```

Aquí, el wrapper de la función alrededor de `hi` en `greeting` es completamente redundante. ¿Por qué? Porque las funciones son *invocables* en JavaScript. Cuando `hi` tiene los `()` al final, se ejecutará y devolverá un valor. Cuando no los tiene, simplemente devolverá la función almacenada en la variable. Sólo para estar seguro, echa un vistazo.

```js
hi;
// function(name){
//  return "Hi " + name
// }

hi("jonas");
// "Hi jonas"
```

Ya que `greeting` simplemente está llamando a `hi` con el mismo argumento, podríamos simplemente escribir:

```js
var greeting = hi;


greeting("times");
// "Hi times"
```

En otras palabras, `hi` ya es una función que espera un argumento, ¿Por qué colocar otra función alrededor de ella qué simplemente llame a `hi` con el mismo argumento? No tiene ningún maldito sentido. Es como ponerte tu parka más pesada al final de un julio mortal solo para subir el aire acondicionado y pedir un helado.

Es demasiado detallado y, también, una mala práctica rodear una función con otra función simplemente para retrasar la evaluación. (Veremos por qué en un momento, pero tiene que ver con el mantenimiento.)

Comprender bien esto es fundamental antes de continuar, así que vamos a ver unos cuantos ejemplos divertidos extraídos de módulos de npm.

```js
// ignorante
var getServerStuff = function(callback){
  return ajaxCall(function(json){
    return callback(json);
  });
};

// informado
var getServerStuff = ajaxCall;
```

El mundo está lleno de código ajax exactamente así. Esta es la razón por la que ambos son equivalentes:

```js
// esta línea
return ajaxCall(function(json){
  return callback(json);
});

// es la misma que esta línea
return ajaxCall(callback);

// así que podemos refactorizar getServerStuff
var getServerStuff = function(callback){
  return ajaxCall(callback);
};

// ...lo que es equivalente a esto
var getServerStuff = ajaxCall; // <-- mira mamá, sin ()
```

Y eso, amigos, es cómo se hace. Una vez más, luego veremos por qué soy tan insistente.

```js
var BlogController = (function() {
  var index = function(posts) {
    return Views.index(posts);
  };

  var show = function(post) {
    return Views.show(post);
  };

  var create = function(attrs) {
    return Db.create(attrs);
  };

  var update = function(post, attrs) {
    return Db.update(post, attrs);
  };

  var destroy = function(post) {
    return Db.destroy(post);
  };

  return {
    index: index, show: show, create: create, update: update, destroy: destroy
  };
})();
```

Este controlador ridiculo es 99% hueco, Podríamos, ya sea, reescribirlo como:

```js
var BlogController = {
  index: Views.index,
  show: Views.show,
  create: Db.create,
  update: Db.update,
  destroy: Db.destroy
};
```

...o desecharlo por completo, ya que no hace nada que no sea agrupar `Views` y `Db`.

## ¿Por qué favorecer a las funciones de primera clase?

Ok, vayamos a las razones de por qué favorecer a las funciones de primera clase. Como vimos en los ejemplos `getServerStuff` y `BlogController`, es fácil agregar capas de indirección que no tienen ningún valor real y sólo incrementan la cantidad de código para mantener y buscar.

Además, si una función que estamos innecesariamente envolviendo cambia, también debemos cambiar nuestra función wrapper.

```js
httpGet('/post/2', function(json){
  return renderPost(json);
});
```

Si `httpGet` fuese a cambiar para enviar un posible error (`err`), necesitariamos cambiar la función interna.

```js
// tenemos que ir a cada llamada a httpGet en la aplicación y pasar explicitamente err.
httpGet('/post/2', function(json, err){
  return renderPost(json, err);
});
```

Si la hubiéramos escrito como una función de primera clase, mucho menos tendría que cambiar:

```js
// renderPost es llamado dentro de httpGet, con todos los argumentos que quiera
httpGet('/post/2', renderPost);
```

Además de la eliminación de funciones innecesarias, debemos nombrar y referenciar argumentos. Los nombres son casi un problema. Tenemos nombres inapropiados, especialmente, cuando el código base crece y los requerimientos cambian.

Tener multiples nombres para el mismo concepto es una fuente común de confusión en proyectos. También existe el problema de código genérico. Por ejemplo, estas dos funciones hacen exactamente la misma cosa, pero una es infinitamente más general y reusable.

```js
// específico para nuestro blog actual
var validArticles = function(articles) {
  return articles.filter(function(article){
    return article !== null && article !== undefined;
  });
};

// mucho más relevante para futuros proyectos
var compact = function(xs) {
  return xs.filter(function(x) {
    return x !== null && x !== undefined;
  });
};
```

Cuando nombramos cosas, aparentemenete nos atamos a datos específicos (en este caso `articles`). Esto sucede bastante y es una fuente de gran parte de la reinvención.

Debo mencionar que, al igual que con código orientado a objetos, debes ser conciente de que `this` puede morderte en la yugular. Si una función subyacente usa `this` y la llamamos como de primera clase, estamos sujetos a esta ira de la abstracción con fugas.

```js
var fs = require('fs');

// aterrador
fs.readFile('freaky_friday.txt', Db.save);

// no tanto
fs.readFile('freaky_friday.txt', Db.save.bind(Db));
```

Después de haber sido enlazada a sí misma, `Db` es libre de acceder a su código basura prototípico. Yo evito usar `this` como un pañal sucio. Realmente no hay ninguna necesidad cuando se escribe código funcional. Sin embargo, cuando se integra con otras librerias, tendrás que aceptar el loco mundo que nos rodea.

Algunos argumentaran que `this` es necesario para la velocidad. Si eres del tipo micro-optimizador, por favor cierra este libro. Si no puedes recuperar tu dinero, quizás puedas intercambiarlo por algo más incómodo.

Y con eso, estamos listos para seguir adelante.

[Capítulo 3: Pura Felicidad con Funciones Puras](ch3-es.md)
