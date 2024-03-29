# Capítulo 02: Funciones de Primera Clase

## Un Repaso Rápido
Cuando decimos que las funciones son de "primera clase", queremos decir que son como cualquier otra clase... o sea, una clase normal. Podemos tratar a las funciones como a cualquier otro tipo de dato y no hay nada particularmente especial en ellas; pueden ser almacenadas en arreglos, pasadas como parámetros de otras funciones, asignadas a variables, y lo que quieras.

Esto es de primero de JavaScript, pero vale la pena mencionarlo, pues una búsqueda rápida de código en GitHub mostrará la evasión colectiva, o tal vez la ignorancia generalizada de este concepto. ¿Deberíamos poner un ejemplo ficticio? Deberíamos.

```js
const hi = name => `Hi ${name}`;
const greeting = name => hi(name);
```

Aquí, en `greeting`, la función que envuelve a `hi` es completamente redundante. ¿Por qué? Porque las funciones son *llamables* en JavaScript. Cuando `hi` tiene los `()` al final, se ejecutará y devolverá un valor. Cuando no los tiene, simplemente devolverá la función almacenada en la variable. Solo para asegurarte, echa un vistazo tú mismo.

```js
hi; // name => `Hi ${name}`
hi("jonas"); // "Hi jonas"
```

Dado que `greeting` tan solo está llamando a `hi` con el mismo argumento, podríamos simplemente escribir:

```js
const greeting = hi;
greeting("times"); // "Hi times"
```

En otras palabras, `hi` ya es una función que espera un argumento, ¿por qué colocar otra función alrededor de ella que simplemente llame a `hi` con el mismo condenado argumento? No tiene ningún maldito sentido. Es como ponerte tu parka más pesada al final de un julio mortal solo para subir el aire acondicionado y pedir un helado.

Rodear una función con otra función simplemente para retrasar la evaluación es demasiado detallado y también una mala práctica. (Veremos por qué en un momento, pero tiene que ver con el mantenimiento.)

Es fundamental comprender bien esto antes de continuar, así que vamos a examinar algunos otros divertidos ejemplos extraídos de paquetes de npm.

```js
// ignorante
const getServerStuff = callback => ajaxCall(json => callback(json));

// iluminado
const getServerStuff = ajaxCall;
```

El mundo está repleto de código ajax exactamente igual a este. He aquí la razón por la que ambos son equivalentes:

```js
// esta línea
ajaxCall(json => callback(json));

// es lo mismo que esta línea
ajaxCall(callback);

// así que refactorizamos getServerStuff
const getServerStuff = callback => ajaxCall(callback);

// ...la cual es equivalente a esto
const getServerStuff = ajaxCall; // <-- mira mama, sin ()'s
```

Y así, amigos, es cómo se hace. Uno más para que entendamos por qué estoy siendo tan insistente.

```js
const BlogController = {
  index(posts) { return Views.index(posts); },
  show(post) { return Views.show(post); },
  create(attrs) { return Db.create(attrs); },
  update(post, attrs) { return Db.update(post, attrs); },
  destroy(post) { return Db.destroy(post); },
};
```

Este ridículo controlador es 99% aire. Podríamos reescribirlo como:

```js
const BlogController = {
  index: Views.index,
  show: Views.show,
  create: Db.create,
  update: Db.update,
  destroy: Db.destroy
};
```

...o desecharlo por completo, puesto que no hace más que agrupar `Views` y `Db`.

## ¿Por Qué Favorecer a las Funciones de Primera Clase?

Vale, vayamos a las razones por las que favorecer a las funciones de primera clase. Como vimos en los ejemplos `getServerStuff` y `BlogController`, es fácil agregar capas de indirección que no añaden ningún valor y que lo único que hacen es incrementar la cantidad de código en el que rebuscar y que mantener.

Además, si cambia una función que estamos envolviendo innecesariamente, también deberemos cambiar la función que la envuelve.

```js
httpGet('/post/2', json => renderPost(json));
```

Si `httpGet` cambiase para enviar un posible error (`err`), necesitaríamos cambiar la función interna.

```js
// ir a cada llamada a httpGet en la aplicación y pasar explícitamente err.
httpGet('/post/2', (json, err) => renderPost(json, err));
```

Si la hubiéramos escrito como una función de primera clase, mucho menos necesitaríamos cambiar:

```js
// renderPost es llamada desde dentro de httpGet, con todos los argumentos que quiera
httpGet('/post/2', renderPost);
```

Si no eliminamos las funciones innecesarias deberemos nombrar a los argumentos y hacer referencia a ellos. Los nombres son algo problemáticos, ya sabes. Existen potenciales errores de nombrado, especialmente cuando la base de código envejece y los requerimientos cambian.

Tener múltiples nombres para el mismo concepto suele ser una fuente de confusión en los proyectos. También existe el problema del código genérico. Por ejemplo, estas dos funciones hacen exactamente lo mismo, pero una es infinitamente más general y reusable.

```js
// específico para nuestro blog actual
const validArticles = articles =>
  articles.filter(article => article !== null && article !== undefined),

// mucho más relevante para futuros proyectos
const compact = xs => xs.filter(x => x !== null && x !== undefined);
```

Usando nombres concretos, aparentemente nos atamos a datos específicos (en este caso `articles`). Esto sucede bastante a menudo y es una fuente de mucha de la reinvención.

Debo mencionar que, al igual que con código orientado a objetos, debes ser consciente de que `this` puede morderte en la yugular. Si una función subyacente usa `this` y la llamamos como si fuese de primera clase, estamos sujetos a esta cólera de la abstracción con fugas.

```js
const fs = require('fs');

// aterrador
fs.readFile('freaky_friday.txt', Db.save);

// no tanto
fs.readFile('freaky_friday.txt', Db.save.bind(Db));
```

Después de haber sido enlazada a sí misma, `Db` es libre de acceder a su prototípico código basura. Yo evito usar `this` de la misma manera que evito usar un pañal sucio. Realmente no hay ninguna necesidad cuando se escribe código funcional. Sin embargo, al interactuar con otras bibliotecas, tendrás que aceptar el loco mundo que nos rodea.

Hay quien argumentará que `this` es necesario para optimizar la velocidad. Si te va la micro-optimización, por favor cierra este libro. Si no puedes recuperar tu dinero, quizás puedas intercambiarlo por algo más complejo.

Y con esto estamos listos para seguir adelante.

[Capítulo 3: Pura Felicidad con Funciones Puras](ch03-es.md)
