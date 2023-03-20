# Capítulo 12: Atravesando la Piedra

Hasta ahora, en nuestro circo de contenedores, nos has visto domar al feroz [funtor](ch08-es.md#mi-primer-funtor), doblegándolo a nuestra voluntad para realizar cualquier operación que se nos antoje. Has sido deslumbrado por los malabares hechos con multitud de peligrosos efectos simultáneamente utilizando [aplicación](ch10-es.md) de funciones para reunir los resultados. Presenciaste con asombro la desaparición de contenedores al ser [unidos](ch09-es.md) entre ellos. En el espectáculo de efectos secundarios, les hemos visto [componerse](ch08-es.md#un-poco-de-teoría) en uno solo. Y más recientemente, nos aventuramos más allá de lo natural y [transformamos](ch11-es.md) un tipo en otro ante tus propios ojos.

Y ahora, para nuestro siguiente truco, veremos los "traversables". Veremos tipos volar unos sobre otros como si fuesen trapecistas, manteniendo nuestro valor intacto. Reordenaremos los efectos como a las cabinas de una atracción de feria. Cuando nuestros contenedores se entrelacen como las extremidades de un contorsionista podremos utilizar esta interfaz para enderezar las cosas. Con distintas disposiciones presenciaremos distintos efectos. Tráeme mis bombachos y mi flauta de émbolo, comencemos.

## Tipos y Tipos

Pongámonos raros:

```js
// readFile :: FileName -> Task Error String

// firstWords :: String -> String
const firstWords = compose(intercalate(' '), take(3), split(' '));

// tldr :: FileName -> Task Error String
const tldr = compose(map(firstWords), readFile);

map(tldr, ['file1', 'file2']);
// [Task('hail the monarchy'), Task('smash the patriarchy')]
```

Aquí estamos leyendo un grupo de archivos y terminamos con un inútil array de tareas. ¿Cómo podríamos ejecutar cada una de ellas? Sería de lo más agradable si pudiésemos cambiar los tipos de sitio para tener `Task Error [String]` en vez de `[Task Error String]`. De esta manera tendríamos un valor futuro conteniendo todos los resultados, que es más agradable para nuestras necesidades asíncronas que varios valores futuros llegando a su antojo.

He aquí un último ejemplo de una situación complicada:

```js
// getAttribute :: String -> Node -> Maybe String
// $ :: Selector -> IO Node

// getControlNode :: Selector -> IO (Maybe (IO Node))
const getControlNode = compose(map(map($)), map(getAttribute('aria-controls')), $);
```

Mira esos `IO` anhelando estar juntos. Sería simplemente encantador poder unirlos con `join` y dejar que bailasen mejilla con mejilla, pero, por desgracia, un `Maybe` se interpone entre ellos como una carabina en el baile de graduación. Nuestro mejor movimiento aquí sería colocarlos uno junto al otro para que sus tipos estuviesen al fin juntos, y así simplificar nuestra firma a `IO (Maybe Node)`.

## Feng Shui de Tipos

La interfaz *Traversable* consiste en dos gloriosas funciones: `sequence` y `traverse`.

Reordenemos nuestros tipos utilizando `sequence`:

```js
sequence(List.of, Maybe.of(['the facts'])); // [Just('the facts')]
sequence(Task.of, new Map({ a: Task.of(1), b: Task.of(2) })); // Task(Map({ a: 1, b: 2 }))
sequence(IO.of, Either.of(IO.of('buckle my shoe'))); // IO(Right('buckle my shoe'))
sequence(Either.of, [Either.of('wing')]); // Right(['wing'])
sequence(Task.of, left('wing')); // Task(Left('wing'))
```

¿Ves lo que ha ocurrido aquí? Nuestro tipo con anidamiento es dado la vuelta como a unos pantalones de piel en una húmeda noche de verano. El funtor de dentro es movido hacia el exterior y viceversa. Has de saber que `sequence` es un poco particular en cuanto a sus argumentos. Tiene el siguiente aspecto:

```js
// sequence :: (Traversable t, Applicative f) => (a -> f a) -> t (f a) -> f (t a)
const sequence = curry((of, x) => x.sequence(of));
```

Comencemos por el segundo argumento. Ha de ser un *Traversable* conteniendo un *Aplicativo* que, aún sonando bastante restrictivo, suele ser lo más común. Es el `t (f a)` quien es transformado en `f (t a)`. ¿No es expresivo? Queda claro como el agua que los dos tipos bailan dos-à-dos el uno alrededor del otro. El primer argumento es tan solo una muleta y tan solo es necesario en un lenguaje sin tipos. Es un constructor de tipo (nuestro *of*) proporcionado para que podamos invertir tipos como `Left`, reacios a `map`; más sobre esto en un minuto.

Utilizando `sequence` podemos mover tipos de un lado a otro con la precisión de un trilero. Pero ¿cómo funciona esto? Veamos como un tipo, por ejemplo `Either`, la implementaría.

```js
class Right extends Either {
  // ...
  sequence(of) {
    return this.$value.map(Either.of);
  }
}
```

Ah, si, si nuestro valor `$value` es un funtor (de hecho debe ser un aplicativo), podemos simplemente aplicarle nuestro constructor mediante `map` para que salte por encima del tipo.    

Puede que te hayas dado cuenta de que hemos ignorado por completo el `of`. Se pasa como argumento para cuando el mapeo es inútil, como es en el caso de `Left`:

```js
class Left extends Either {
  // ...
  sequence(of) {
    return of(this);
  }
}
```

Nos gustaría que los tipos acabasen siempre en la misma disposición, por lo que es necesario que tipos como `Left`, que no contienen a nuestro aplicativo interno, reciban algo de ayuda para hacerlo. La interfaz *Aplicativo* requiere que primero tengamos un *Funtor Pointed* para que siempre tengamos un *of* que pasar. En un lenguaje con sistema de tipos, el tipo externo puede ser inferido de la firma y no necesita ser proporcionado explícitamente.

## Surtido de Efectos

Distintas disposiciones tienen distintos resultados en cuanto a nuestros contenedores se refiere. Si tengo `[Maybe a]`, es una colección de posibles valores mientras que si tengo un `Maybe [a]`, es una posible colección de valores. Lo primero indica que seremos indulgentes y nos quedaremos con "los buenos", mientras que lo último significa que es una situación del tipo "todo o nada". De igual manera, `Either Error (Task Error a)` puede representar una validación del lado del cliente y `Task Error (Either Error a)` puede ser del lado del servidor. Los tipos pueden ser intercambiados para proporcionarnos diferentes efectos.

```js
// fromPredicate :: (a -> Bool) -> a -> Either e a

// partition :: (a -> Bool) -> [a] -> [Either e a]
const partition = f => map(fromPredicate(f));

// validate :: (a -> Bool) -> [a] -> Either e [a]
const validate = f => traverse(Either.of, fromPredicate(f));
```

Aquí tenemos dos funciones distintas según se basan en aplicar `map` o `traverse`. La primera, `partition`, nos dará un array de `Left`s y `Right`s de acuerdo con la función predicado. Esto es útil para mantener los preciosos datos a mano para futuros usos en vez de descartarlos junto con el agua del baño. En cambio, `validate` nos devolverá en `Left` el primer elemento que no supere el predicado, o todos los elementos en un `Right` si todo está bien. Al escoger un orden diferente de tipos, obtenemos un comportamiento diferente:

Veamos la función `traverse` de `List` para ver como está hecho el método `validate`.

```js
traverse(of, fn) {
    return this.$value.reduce(
      (f, a) => fn(a).map(b => bs => bs.concat(b)).ap(f),
      of(new List([])),
    );
  }
```

Esto tan solo ejecuta un `reduce` en la lista. La función reduce es `(f, a) => fn(a).map(b => bs => bs.concat(b)).ap(f)`, que da algo de miedo, así que veámosla paso a paso.

1. `reduce(..., ...)`

   Recuerda la firma de `reduce :: [a] -> (f -> a -> f) -> f -> f`. El primer argumento es en realidad proporcionado por la notación con punto en `$value`, así que es una lista de cosas.
   Después necesitamos una función desde un `f` (el acumulador) y un `a` (el iterado) para devolvernos un nuevo acumulador.

2. `of(new List([]))`

   El valor semilla es `of(new List([]))`, el cual en nuestro caso es `Right([]) :: Either e [a]`. ¡Fíjate que `Either e [a]` también será nuestro tipo resultante!

3. `fn :: Applicative f => a -> f a`

   Si lo aplicamos a nuestro ejemplo de arriba, `fn` es en realidad `fromPredicate(f) :: a -> Either e a`.
   > fn(a) :: Either e a

4. `.map(b => bs => bs.concat(b))`

   Cuando es `Right`, `Either.map` pasa el valor correcto a la función y devuelve un nuevo `Right` con el resultado. En este caso, la función tiene un parámetro (`b`), y devuelve otra función (`bs => bs.concat(b)`, donde `b` está al alcance gracias a la closure). Cuando es `Left`, el valor de left es devuelto.
   > fn(a).map(b => bs => bs.concat(b)) :: Either e ([a] -> [a])

5. .`ap(f)`

   Recuerda que aquí `f` es un Aplicativo, así que podemos aplicar la función `bs => bs.concat(b)` a cualquier valor `bs :: [a]` que esté en `f`. Afortunadamente para nosotros, `f` proviene de nuestra semilla inicial y tiene el siguiente tipo: `f :: Either e [a]` que, por cierto, se conserva cuando aplicamos `bs => bs.concat(b)`.
   Cuando `f` es `Right` llama a `bs => bs.concat(b)`, quien a su vez devuelve un `Right` con el elemento añadido a la lista. Cuando es `Left`, el valor izquierdo (del paso anterior o de la iteración anterior respectivamente) es devuelto.
   > fn(a).map(b => bs => bs.concat(b)).ap(f) :: Either e [a]

Esta transformación aparentemente milagrosa se consigue con tan solo 6 míseras líneas de código en `List.traverse`, y se logra con `of`, `map` y `ap` por lo que funcionará para cualquier Funtor Aplicativo. Este es un gran ejemplo
de cómo estas abstracciones pueden ayudar a escribir código altamente genérico con solo unas pocas suposiciones (¡que pueden, por cierto, ser declaradas y comprobadas a nivel de tipos!)

## El Vals de los Tipos

Es momento de revisitar y limpiar nuestros ejemplos iniciales.

```js
// readFile :: FileName -> Task Error String

// firstWords :: String -> String
const firstWords = compose(intercalate(' '), take(3), split(' '));

// tldr :: FileName -> Task Error String
const tldr = compose(map(firstWords), readFile);

traverse(Task.of, tldr, ['file1', 'file2']);
// Task(['hail the monarchy', 'smash the patriarchy']);
```

Utilizando `traverse` en vez de `map`, hemos conseguido formar un rebaño con esas revoltosas `Task`, convirtiéndolas en un bonito y coordinado array de resultados. Esto es como `Promise.all()`, si estás familiarizado, excepto que no es una única función personalizada, no, esto funciona para cualquier tipo *traversable*. Estas apis matemáticas tienden a capturar de forma interoperable y reusable la mayor parte de las cosas que nos gustaría hacer, en vez de que cada librería reinvente estas funciones para un solo tipo.

Limpiemos el último ejemplo de closure:

```js
// getAttribute :: String -> Node -> Maybe String
// $ :: Selector -> IO Node

// getControlNode :: Selector -> IO (Maybe Node)
const getControlNode = compose(chain(traverse(IO.of, $)), map(getAttribute('aria-controls')), $);
```

En vez de `map(map($))` tenemos `chain(traverse(IO.of, $))`, que invierte nuestros tipos dado que, mediante `chain`, aplica map y luego aplana los dos `IO`.

## Sin Ley Ni Orden

Bien, ahora, antes de que te pongas a juzgar y golpees la tecla de borrar como con un mazo para olvidar el capítulo, tómate un momento para reconocer que todas estas leyes son útiles garantías de código. Es conjetura mía que la finalidad de las arquitecturas de muchos programas es intentar poner restricciones útiles en nuestro código para reducir las posibilidades, para guiarnos hacia las respuestas cuando lo diseñamos y cuando lo leemos.

Una interfaz sin leyes es simple indirección. Como cualquier otra estructura matemática, debemos exponer las propiedades para nuestra propia cordura. Esto tiene un efecto similar a la encapsulación, dado que protege a los datos, permitiéndonos intercambiar la interfaz por otro ciudadano ejemplar.

Acompáñame, tenemos algunas leyes que averiguar.

### Identidad

```js
const identity1 = compose(sequence(Identity.of), map(Identity.of));
const identity2 = Identity.of;

// pruébalo con Right
identity1(Either.of('stuff'));
// Identity(Right('stuff'))

identity2(Either.of('stuff'));
// Identity(Right('stuff'))
```

Esto debería ser sencillo. Si colocamos un `Identity` dentro de nuestro funtor, y luego le damos la vuelta con `sequence` es lo mismo que colocarlo por fuera desde el principio. Hemos elegido a `Right` como conejillo de indias porque con él es fácil probar a aplicar la ley e inspeccionarlo. Podríamos haber usado cualquier otro funtor, sin embargo, el usar un funtor concreto como `Identity` en la propia ley, podría haber levantado algunas cejas. Recuerda que una [categoría](ch05-es.md#teoría-de-categorías) es definida por morfismos entre sus objetos con composición asociativa e identidad. Cuando se trata de la categoría de funtores, las transformaciones naturales son los morfismos e `Identity` es, bueno, la identidad. El funtor `Identity` es tan fundamental para demostrar las leyes como nuestra función `compose`. De hecho, deberíamos dejar aquí este tema y pasar a hacer lo mismo con nuestro tipo [Compose](ch08-es.md#un-poco-de-teoría):

### Composición

```js
const comp1 = compose(sequence(Compose.of), map(Compose.of));
const comp2 = (Fof, Gof) => compose(Compose.of, map(sequence(Gof)), sequence(Fof));


// Pruébalo con algunos tipos que tengamos por ahí
comp1(Identity(Right([true])));
// Compose(Right([Identity(true)]))

comp2(Either.of, Array)(Identity(Right([true])));
// Compose(Right([Identity(true)]))
```

Esta ley preserva la composición tal y como se esperaba: si intercambiamos la composición de funtores, no deberíamos tener ninguna sorpresa dado que la composición es un funtor en sí mismo. Arbitrariamente hemos escogido `true`, `Right`, `Identity` y `Array` para probarlo. Librerías como [quickcheck](https://hackage.haskell.org/package/QuickCheck) o [jsverify](http://jsverify.github.io/) pueden ayudarnos a comprobar la ley mediante pruebas con datos aleatorios en las entradas.

Como consecuencia natural de la ley de arriba, obtenemos la capacidad de [fusionar *traversals*](https://www.cs.ox.ac.uk/jeremy.gibbons/publications/iterator.pdf), lo que es bueno desde el punto de vista del rendimiento.

### Naturalidad

```js
const natLaw1 = (of, nt) => compose(nt, sequence(of));
const natLaw2 = (of, nt) => compose(sequence(of), map(nt));

// comprobar con una transformación natural al azar y nuestros amigables funtores Identity/Right.

// maybeToEither :: Maybe a -> Either () a
const maybeToEither = x => (x.$value ? new Right(x.$value) : new Left());

natLaw1(Maybe.of, maybeToEither)(Identity.of(Maybe.of('barlow one')));
// Right(Identity('barlow one'))

natLaw2(Either.of, maybeToEither)(Identity.of(Maybe.of('barlow one')));
// Right(Identity('barlow one'))
```

Esto es parecido a nuestra ley de la identidad. Si primero meneamos a los tipos y luego ejecutamos una transformación natural en el exterior, debería ser lo mismo que mapear una transformación natural y después voltear los tipos.

Una consecuencia natural de esta ley es:

```js
traverse(A.of, A.of) === A.of;
```

Lo cual, de nuevo, es bueno desde el punto de vista del rendimiento.


## En Resumen

*Traversable* es una poderosa interfaz que nos provee con la capacidad de reordenar nuestros tipos con la facilidad de un interiorista con telequinesis. Con distintas disposiciones podemos conseguir distintos efectos, así como planchar esas feas arrugas en los tipos que nos impiden unirlos con `join`. A continuación, nos desviaremos un poco para ver una de las interfaces más poderosas de la programación funcional y puede que incluso del propio álgebra: [Los Monoides lo unen todo](ch13-es.md)

## Ejercicios

Teniendo en cuenta los siguientes elementos:

```js
// httpGet :: Route -> Task Error JSON

// routes :: Map Route Route
const routes = new Map({ '/': '/', '/about': '/about' });
```


{% exercise %}  
Utiliza la interfaz traversable para cambiar la firma de tipo de `getJsons` a
Map Route Route → Task Error (Map Route JSON)

  
{% initial src="./exercises/ch12/exercise_a.js#L11;" %}  
```js  
// getJsons :: Map Route Route -> Map Route (Task Error JSON)
const getJsons = map(httpGet);
```  
  
  
{% solution src="./exercises/ch12/solution_a.js" %}  
{% validation src="./exercises/ch12/validation_a.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
  
  
---  


Ahora definimos la siguiente función de validación:

```js
// validate :: Player -> Either String Player
const validate = player => (player.name ? Either.of(player) : left('must have name'));
```


{% exercise %}  
Usando traversable, y la función `validate`, actualiza `startGame` (y su firma)
para que solo comience el juego si todos los jugadores son válidos

  
{% initial src="./exercises/ch12/exercise_b.js#L7;" %}  
```js  
// startGame :: [Player] -> [Either Error String]
const startGame = compose(map(map(always('game started!'))), map(validate));
```  
  
  
{% solution src="./exercises/ch12/solution_b.js" %}  
{% validation src="./exercises/ch12/validation_b.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
  
  
---  


Finalmente, teniendo en cuenta algunas funciones de soporte para el sistema de archivos:

```js
// readfile :: String -> String -> Task Error String
// readdir :: String -> Task Error [String]
```

{% exercise %}  
Utiliza traversable para reordenar y aplanar los Task y Maybe anidados

  
{% initial src="./exercises/ch12/exercise_c.js#L8;" %}  
```js  
// readFirst :: String -> Task Error (Maybe (Task Error String))
const readFirst = compose(map(map(readfile('utf-8'))), map(safeHead), readdir);
```  
  
  
{% solution src="./exercises/ch12/solution_c.js" %}  
{% validation src="./exercises/ch12/validation_c.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
