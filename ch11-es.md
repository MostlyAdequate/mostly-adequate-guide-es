# Capítulo 11: Transforma Otra Vez, Naturalmente

[*El título en inglés es 'Transform Again, Naturally' que recuerda a la canción Alone Again (Naturally) de Gilbert O'Sullivan*]

Estamos a punto de discutir sobre las *transformaciones naturales* en cuanto a su utilidad práctica en nuestro día a día programando. Sucede que son un pilar de la teoría de categorías y absolutamente indispensables a la hora de aplicar matemáticas al razonar sobre nuestro código y al refactorizarlo. Como tal, creo que es mi deber informarte sobre la lamentable injusticia que estás a punto de presenciar, indudablemente debido a mi limitado alcance. Empecemos.

## Maldice Este Nido

Me gustaría abordar el tema del anidamiento. No el instintivo impulso que sienten quienes están a punto de ser padres cuando limpian y reordenan obsesiva e impulsivamente, sino del... bueno, ahora que lo pienso, eso no está tan lejos de la realidad, tal y como veremos en los próximos capítulos... En cualquier caso, lo que quiero decir con *anidamiento* es cuando se tienen dos o más tipos distintos todos acurrucados en torno a un valor, acunándolo, por así decirlo, como a un recién nacido.

```js
Right(Maybe('b'));

IO(Task(IO(1000)));

[Identity('bee thousand')];
```

Hasta ahora hemos logrado, mediante ejemplos cuidadosamente elaborados, evadirnos de este típico escenario, pero en la práctica, mientras programamos, los tipos tienden a enredarse entre ellos como el cable de unos auriculares en un exorcismo. Si no mantenemos a nuestros tipos meticulosamente bien organizados a medida que avanzamos, nuestro código se leerá más peludo que un hipster en un café de gatos.

## Una Comedia de Situación

```js
// getValue :: Selector -> Task Error (Maybe String)
// postComment :: String -> Task Error Comment
// validate :: String -> Either ValidationError String

// saveComment :: () -> Task Error (Maybe (Either ValidationError (Task Error Comment)))
const saveComment = compose(
  map(map(map(postComment))),
  map(map(validate)),
  getValue('#comment'),
);
```

La banda está aquí al completo, para consternación de nuestra firma de tipos. Permíteme explicar brevemente el código. Con `getValue('#comment')`, que es una acción que recupera el texto de un elemento, comenzamos obteniendo lo proporcionado por el usuario. Ahora bien, cabe la posibilidad de que se produzca un error al buscar el elemento o que el valor string no exista, así que devuelve `Task Error (Maybe String)`. Después de esto, debemos aplicar `map` tanto sobre `Task` como sobre `Maybe` para pasarle el texto a `validate`, quien a su vez nos entrega mediante `Either`, un `ValidationError` o nuestro `String`. A continuación, mapeamos durante días para enviar el `String` de nuestro `Task Error (Maybe (Either ValidationError String))` a `postComment`, que nos devuelve el `Task` resultante.

Qué desorden tan espantoso. Un collage de tipos abstractos, expresionismo de tipos amateur, un Pollock polimórfico, un Mondrian monolítico. Hay numerosas soluciones para este problema tan común. Podemos componer los tipos en un monstruoso contenedor, ordenarlos y aplicar `join` sobre algunos, homogeneizarlos, deconstruirlos, etc. En este capítulo nos centraremos en homogeneizarlos mediante *transformaciones naturales*.

## Todo Natural

Una *Transformación Natural* es un "morfismo entre funtores", o sea, una función que opera en los contenedores mismos. Tipológicamente, es una función `(Functor f, Functor g) => f a -> g a`. Lo que la hace especial es que no podemos, bajo ningún concepto, asomarnos al contenido de nuestro funtor. Piensa en ello como un intercambio de información clasificada; las dos partes ignoran lo que hay en el sobre de manila sellado con "top secret". Es una operación estructural. Un cambio funcional de vestuario. Formalmente, una *transformación natural* es cualquier función para la que se cumple lo siguiente:

<img width=600 src="images/natural_transformation.png" alt="diagrama de transformación natural" />

o en código:

```js
// nt :: (Functor f, Functor g) => f a -> g a
compose(map(f), nt) === compose(nt, map(f));
```

Tanto el diagrama como el código dicen lo mismo: Podemos ejecutar nuestra transformación natural y luego aplicar `map` o podemos aplicar `map` y luego ejecutar nuestra transformación natural y obtener el mismo resultado. Casualmente esto se desprende de un [teorema gratuito](ch07-es.md#teoremas-gratis), aunque las transformaciones naturales (y los funtores) no están limitadas a funciones sobre tipos.

## Conversión de Tipos Basada en Principios

Como programadores estamos familiarizados con la conversión de tipos. Transformamos tipos como `String` a `Boolean` e `Integer` a `Float` (aunque JavaScript solo tiene `Number`). Simplemente aquí la diferencia es que estamos trabajando con contenedores algebraicos y tenemos algo de teoría a nuestra disposición.

Veamos ejemplos de algunas de estas conversiones:

```js
// idToMaybe :: Identity a -> Maybe a
const idToMaybe = x => Maybe.of(x.$value);

// idToIO :: Identity a -> IO a
const idToIO = x => IO.of(x.$value);

// eitherToTask :: Either a b -> Task a b
const eitherToTask = either(Task.rejected, Task.of);

// ioToTask :: IO a -> Task () a
const ioToTask = x => new Task((reject, resolve) => resolve(x.unsafePerform()));

// maybeToTask :: Maybe a -> Task () a
const maybeToTask = x => (x.isNothing ? Task.rejected() : Task.of(x.$value));

// arrayToMaybe :: [a] -> Maybe a
const arrayToMaybe = x => Maybe.of(x[0]);
```

¿Ves la idea? Solo estamos cambiando un funtor por otro. Se nos permite perder información por el camino, siempre y cuando el valor al que aplicaremos `map` no se pierda con tanto cambio de forma. Ese es el punto: `map` debe continuar, según nuestra definición, incluso después de la transformación.

Una manera de ver todo esto es que estamos transformando a nuestros efectos. Bajo esta luz, podemos ver a `ioToTask` como convertir de síncrono a asíncrono o a `arrayToMaybe` como convertir de no determinístico a posible fallo. Date cuenta que no podemos convertir de asíncrono a síncrono en JavaScript, así que no podemos escribir `taskToIO`; eso sería una transformación supernatural.

## Envidia de Características

Supongamos que queremos utilizar algunas características de otro tipo, como por ejemplo `sortBy` en un `List`. Las *Transformaciones naturales* proporcionan una buena forma de convertir al tipo objetivo sabiendo que nuestro `map` será válido.

```js
// arrayToList :: [a] -> List a
const arrayToList = List.of;

const doListyThings = compose(sortBy(h), filter(g), arrayToList, map(f));
const doListyThings_ = compose(sortBy(h), filter(g), map(f), arrayToList); // law applied
```

Un movimiento de nuestra nariz, tres toques de nuestra varita, dejamos caer `arrayToList`, y ¡voilà!, nuestro `[a]` es un `List a` y podemos utilizar `sortBy` si queremos.

Además, se vuelve más fácil de optimizar / fusionar operaciones al mover `map(f)` hacia la izquierda de la *transformación natural*, como se muestra en `doListyThings_`.

## JavaScript Isomórfico

Cuando podemos ir completamente hacia atrás y hacia adelante sin perder ninguna información, se considera un *isomorfismo*. Esta solo es una palabra elegante para decir que "mantiene los mismos datos". Decimos que dos tipos son *isomorfos* si podemos proporcionar las *transformaciones naturales* "hacia" y "desde" como demuestra:

```js
// promiseToTask :: Promise a b -> Task a b
const promiseToTask = x => new Task((reject, resolve) => x.then(resolve).catch(reject));

// taskToPromise :: Task a b -> Promise a b
const taskToPromise = x => new Promise((resolve, reject) => x.fork(reject, resolve));

const x = Promise.resolve('ring');
taskToPromise(promiseToTask(x)) === x;

const y = Task.of('rabbit');
promiseToTask(taskToPromise(y)) === y;
```

Q.E.D. `Promise` y `Task` son *isomorfos*. También podemos escribir una función `listToArray` para complementar nuestra `arrayToList` y demostrar que también lo son. Como contraejemplo, `arrayToMaybe` no es un *isomorfismo* dado que pierde información:

```js
// maybeToArray :: Maybe a -> [a]
const maybeToArray = x => (x.isNothing ? [] : [x.$value]);

// arrayToMaybe :: [a] -> Maybe a
const arrayToMaybe = x => Maybe.of(x[0]);

const x = ['elvis costello', 'the attractions'];

// no isomorfa
maybeToArray(arrayToMaybe(x)); // ['elvis costello']

// pero es una transformación natural
compose(arrayToMaybe, map(replace('elvis', 'lou')))(x); // Just('lou costello')
// ==
compose(map(replace('elvis', 'lou')), arrayToMaybe)(x); // Just('lou costello')
```

Sin embargo, sí que son *transformaciones naturales*, ya que la función `map` de cada lado da el mismo resultado. Menciono los *isomorfismos* aquí, a mitad del capítulo, porque estamos hablando de ello, pero no te dejes engañar, son un concepto enormemente poderoso y omnipresente. De todos modos, sigamos adelante.

## Una Definición Más Amplia

Estas funciones estructurales no se limitan en absoluto a la conversión de tipos.

He aquí otras distintas:

```hs
reverse :: [a] -> [a]

join :: (Monad m) => m (m a) -> m a

head :: [a] -> a

of :: a -> f a
```

Las leyes de la transformación natural también son válidas para estas funciones. Una cosa que puede confundirte es que `head :: [a] -> a` puede verse como `head :: [a] -> Identity a`. Somos libres de insertar `Identity` donde queramos mientras demostramos las leyes, ya que podemos a su vez demostrar que `a` es isomorfo con `Identity a` (lo ves, te dije que los *isomorfismos* eran omnipresentes).

## Una Solución Para El Anidamiento

Volviendo a nuestra cómica firma de tipos. Podemos espolvorear en ella algunas *transformaciones naturales* a lo largo del código que la llama para aplicar coerción de tipos a cada tipo que varíe y que así sean todos uniformes y que, por lo tanto, se puedan unir con `join`.

```js
// getValue :: Selector -> Task Error (Maybe String)
// postComment :: String -> Task Error Comment
// validate :: String -> Either ValidationError String

// saveComment :: () -> Task Error Comment
const saveComment = compose(
  chain(postComment),
  chain(eitherToTask),
  map(validate),
  chain(maybeToTask),
  getValue('#comment'),
);
```

¿Qué tenemos aquí? Tan solo hemos añadido `chain(maybeToTask)` y `chain(eitherToTask)`. Ambas tienen el mismo efecto; de manera natural, transforman el funtor que guarda nuestro `Task`, en otro `Task` y luego une los dos con `join`. De esta manera evitamos el anidamiento justo desde el origen igual que los pinchos para palomas en el alféizar de una ventana. Como dicen en la Ciudad de la Luz, "Mieux vaut prévenir que guérir"; más vale prevenir que curar.

## En Resumen

Las *Transformaciones Naturales* son funciones sobre nuestros funtores. Son un concepto extremadamente importante en la teoría de categorías y empezarán a aparecer por todas partes una vez que adoptemos más abstracciones, pero, por ahora, las hemos limitado a unas pocas aplicaciones concretas. Como hemos visto, podemos conseguir diferentes efectos al convertir tipos, con la garantía de que mantendremos nuestra composición. También pueden ayudarnos con el anidamiento de tipos, aunque tienen el efecto general de homogeneizar nuestros funtores al mínimo común denominador que, en la práctica, es el funtor con los efectos más volátiles (`Task` en la mayoría de los casos).

Esta continuada y tediosa clasificación de tipos es el precio que pagamos por haberlos materializado; convocados desde el éter. Por supuesto, los efectos implícitos son mucho más insidiosos, así que aquí estamos, librando esta justa batalla. Necesitaremos algunas herramientas más en nuestro equipamiento antes de poder enrollar las más largas amalgamas de tipos. A continuación, veremos cómo reordenar nuestros tipos con *Traversable*.

[Capítulo 12: Atravesando la Piedra](ch12-es.md)


## Ejercicios

{% exercise %}  
Escribe una transformación natural que convierta `Either b a` en `Maybe a`
  
{% initial src="./exercises/ch11/exercise_a.js#L3;" %}  
```js  
// eitherToMaybe :: Either b a -> Maybe a  
const eitherToMaybe = undefined;  
```  
  
  
{% solution src="./exercises/ch11/solution_a.js" %}  
{% validation src="./exercises/ch11/validation_a.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
  
  
---  


```js
// eitherToTask :: Either a b -> Task a b
const eitherToTask = either(Task.rejected, Task.of);
```

{% exercise %}  
Utilizando `eitherToTask`, simplifica `findNameById` para eliminar el `Either` anidado.
  
{% initial src="./exercises/ch11/exercise_b.js#L6;" %}  
```js  
// findNameById :: Number -> Task Error (Either Error User)  
const findNameById = compose(map(map(prop('name'))), findUserById);  
```  
  
  
{% solution src="./exercises/ch11/solution_b.js" %}  
{% validation src="./exercises/ch11/validation_b.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
  
  
---  


Como recordatorio, las siguientes funciones están disponibles en el contexto del ejercicio:

```hs
split :: String -> String -> [String]
intercalate :: String -> [String] -> String
```

{% exercise %}  
Escribe los isomorfismos entre String y [Char].
  
{% initial src="./exercises/ch11/exercise_c.js#L8;" %}  
```js  
// strToList :: String -> [Char]  
const strToList = undefined;  
  
// listToStr :: [Char] -> String  
const listToStr = undefined;  
```  
  
  
{% solution src="./exercises/ch11/solution_c.js" %}  
{% validation src="./exercises/ch11/validation_c.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
