# Capítulo 13: Los Monoides Lo Unen Todo

## Salvaje Combinación 

En este capítulo, examinaremos los *monoides* mediante los *semigrupos*. Los *monoides* son el chicle en el pelo de la abstracción matemática. Capturan una idea que comprende múltiples disciplinas y las une todas juntas figurativa y literalmente. Son la fuerza omnipotente que conecta todo aquello que tiene la capacidad de calcular. Son el oxígeno en nuestra base de código, el suelo en el que corre, entrelazamiento cuántico codificado.

Los *monoides* tratan sobre la combinación. Pero, ¿qué es combinación? Puede significar muchas cosas, desde acumulación hasta concatenación pasando por multiplicación o elección, composición, ordenación, ¡incluso evaluación! Veremos numerosos ejemplos, pero solo pasaremos de puntillas por la falda de la montaña de los monoides. Los ejemplares son abundantes y las aplicaciones, amplias. El objetivo de este capítulo es proporcionar una buena intuición para que puedas crear tus propios *monoides*.

## Abstrayendo La Suma

La suma tiene algunas interesantes cualidades que me gustaría discutir. Démosle un vistazo a través de nuestras gafas de abstracción.

Para empezar, es una operación binaria, o sea, es una operación que toma dos valores y devuelve uno solo, todo dentro del mismo conjunto.

```js
// una operación binaria
1 + 1 = 2
```

¿Lo ves? Dos valores en el dominio, un valor en el codominio, todos del mismo conjunto; números, por decirlo así. Algunos dirían que los números están "cerrados bajo la suma", queriendo decir que el tipo nunca cambiará, sin importar cuál se eche en la mezcla. Esto quiere decir que podemos encadenar la operación, puesto que el resultado siempre es otro número:

```js
// podemos ejecutar esto con cualquier cantidad de números
1 + 7 + 5 + 4 + ...
```

Además, tenemos la asociatividad, que nos da la capacidad de agrupar operaciones como nos plazca. Por cierto, una operación binaria asociativa es la receta para la computación paralela porque podemos trocear y distribuir el trabajo.

```js
// asociatividad
(1 + 2) + 3 = 6
1 + (2 + 3) = 6
```

No vayas a confundir esto con conmutatividad, la cual nos permite cambiar el orden. Aunque se mantiene para la suma, ahora mismo no estamos especialmente interesados en esta propiedad; demasiado específica para nuestras necesidades de abstracción.

Ahora que lo pienso, ¿qué propiedades deben estar si o si en nuestra superclase abstracta? ¿Qué rasgos son específicos de la suma y cuáles pueden ser generalizados? ¿Hay otras abstracciones en medio de esta jerarquía o es todo un mismo trozo? Este es el tipo de razonamiento que nuestros antepasados matemáticos aplicaban cuando concebían las interfaces en el álgebra abstracta.

Como era de esperar, cuando estos "abstraccionistas" de la vieja escuela abstrajeron la suma aterrizaron en el concepto de *grupo*. Un *grupo* tiene todo lo que se necesita incluyendo el concepto de números negativos. Aquí solo estamos interesados en el operador binario asociativo así que elegiremos la interfaz menos específica, *Semigrupo*. Un *Semigrupo* es un tipo con un método `concat` que hace de operador binario asociativo.

Implementémoslo para la suma y llamémosle `Sum`:

```js
const Sum = x => ({
  x,
  concat: other => Sum(x + other.x)
})
```

Fíjate que con `concat` concatenamos con otro `Sum` y siempre devolvemos un `Sum`.

He utilizado una factoría en vez de nuestra típica ceremonia con el prototipo, principalmente porque `Sum` no es *pointed* y no queremos tener que teclear `new`. De todos modos, aquí está en acción:

```js
Sum(1).concat(Sum(3)) // Sum(4)
Sum(4).concat(Sum(37)) // Sum(41)
```

Así podemos programar para la interfaz, no para la implementación. Dado que esta interfaz viene de la teoría de grupos, tiene siglos de literatura respaldándola. ¡Documentación sin esfuerzo adicional!

Como mencionaba antes, `Sum` no es *pointed*, y tampoco es un *functor*. Como ejercicio, vuelve atrás y comprueba las leyes para ver por qué. Vale, yo te lo diré: únicamente puede mantener un número, así que `map` no tiene sentido aquí dado que no podemos transformar al valor subyacente en otro tipo. ¡Ese sería un `map` muy limitado de hecho!

Y entonces, ¿por qué es útil? Bien, como con cualquier interfaz, podemos cambiar nuestro ejemplar para conseguir distintos resultados:

```js
const Product = x => ({ x, concat: other => Product(x * other.x) })

const Min = x => ({ x, concat: other => Min(x < other.x ? x : other.x) })

const Max = x => ({ x, concat: other => Max(x > other.x ? x : other.x) })
```

Y esto no está limitado a números. Veamos otros tipos:

```js
const Any = x => ({ x, concat: other => Any(x || other.x) })
const All = x => ({ x, concat: other => All(x && other.x) })

Any(false).concat(Any(true)) // Any(true)
Any(false).concat(Any(false)) // Any(false)

All(false).concat(All(true)) // All(false)
All(true).concat(All(true)) // All(true)

[1,2].concat([3,4]) // [1,2,3,4]

"miracle grow".concat("n") // miracle grown"

Map({day: 'night'}).concat(Map({white: 'nikes'})) // Map({day: 'night', white: 'nikes'})
```

Si los miras fijamente el tiempo suficiente, el patrón aparecerá como en un estereograma. Está en todas partes. Estamos fusionando estructuras de datos, combinando lógica, construyendo cadenas de texto... Parece que podemos meter a golpes casi cualquier tarea dentro de esta interfaz basada en la combinación.

Ya he usado `Map` unas cuantas veces. Perdóname si no te lo he presentado adecuadamente. `Map` tan solo envuelve a `Object` para así poder embellecerlo con algunos métodos extra sin alterar el tejido del universo.


## Todos Mis Functores Favoritos Son Semigrupos

Los tipos que hemos visto hasta ahora y que implementan la interfaz functor también implementan la interfaz semigrupo. Veamos a `Identity` (el artista antes conocido como Contenedor):

```js
Identity.prototype.concat = function(other) {
  return new Identity(this.__value.concat(other.__value))
}

Identity.of(Sum(4)).concat(Identity.of(Sum(1))) // Identity(Sum(5))
Identity.of(4).concat(Identity.of(1)) // TypeError: this.__value.concat is not a function
```

Es un *semigrupo* si y solo si su valor `__value` es un *semigrupo*. Como un ala delta hecha de chocolate, solo lo es mientras lo tiene.

Otros tipos tienen un comportamiento similar:

```js
// combinación con manejo de errores
Right(Sum(2)).concat(Right(Sum(3))) // Right(Sum(5))
Right(Sum(2)).concat(Left('some error')) // Left('some error')


// combina asincronía
Task.of([1,2]).concat(Task.of([3,4])) // Task([1,2,3,4])
```

Esto es particularmente útil cuando apilamos estos semigrupos en una combinación en cascada:

```js
// formValues :: Selector -> IO (Map String String)
// validate :: Map String String -> Either Error (Map String String)

formValues('#signup').map(validate).concat(formValues('#terms').map(validate)) // IO(Right(Map({username: 'andre3000', accepted: true})))
formValues('#signup').map(validate).concat(formValues('#terms').map(validate)) // IO(Left('one must accept our totalitarian agreement'))

serverA.get('/friends').concat(serverB.get('/friends')) // Task([friend1, friend2])

// loadSetting :: String -> Task Error (Maybe (Map String Boolean))
loadSetting('email').concat(loadSetting('general')) // Task(Maybe(Map({backgroundColor: true, autoSave: false})))
```

En el ejemplo de arriba, hemos combinado un `IO` que contiene un `Either` que a su vez contiene un `Map` para validar y fusionar los valores del formulario. Después hemos llamado a un par de servidores distintos y hemos combinado sus resultados de manera asíncrona utilizando `Task` y `Array`. Finalmente hemos apilado `Task`, `Maybe` y `Map` para cargar, parsear y fusionar múltiples ajustes.

Estos ejemplos podrían haber utilizado `chain` o `ap`, pero los *semigrupos* capturan lo que queremos de forma mucho más concisa.

Esto se extiende más allá de los functores. De hecho, resulta que cualquier cosa hecha enteramente de semigrupos es ella misma un semigrupo.

```js
const Analytics = (clicks, path, idleTime) => ({
  clicks,
  path,
  idleTime,
  concat: other =>
    Analytics(clicks.concat(other.clicks), path.concat(other.path), idleTime.concat(other.idleTime))
})

Analytics(Sum(2), ['/home', '/about'], Right(Max(2000))).concat(Analytics(Sum(1), ['/contact'], Right(Max(1000))))
// Analytics(Sum(3), ['/home', '/about', '/contact'], Right(Max(2000)))
```

Como ves, todo sabe como combinarse. Resulta que podemos hacer lo mismo sin ningún esfuerzo adicional tan solo utilizando el tipo `Map`:

```js
Map({clicks: Sum(2), path: ['/home', '/about'], idleTime: Right(Max(2000))}).concat(Map({clicks: Sum(1), path: ['/contact'], idleTime: Right(Max(1000))}))
// Map({clicks: Sum(3), path: ['/home', '/about', '/contact'], idleTime: Right(Max(2000))})
```

Podemos apilar y combinar tantos como queramos. Solo es cuestión de añadir otro árbol al bosque, u otra llama al incendio del bosque dependiendo de tu base de código.

El comportamiento intuitivo por defecto es combinar lo que el tipo contiene, sin embargo, hay casos en los que ignoramos lo que hay dentro y combinamos el contenedor en sí mismo. Considera un tipo como `Stream` (Flujo):

```js
const submitStream = Stream.fromEvent('click', $('#submit'))
const enterStream = filter(x => x.key === 'Enter', Stream.fromEvent('keydown', $('#myForm')))

submitStream.concat(enterStream).map(submitForm) // Stream()
```

Podemos combinar flujos de eventos capturando los eventos de ambos en un nuevo flujo. Alternativamente, podríamos haberlos combinado insistiendo en que contienen un semigrupo. De hecho, hay muchos posibles ejemplares para cada tipo. Considera `Task`. Podemos combinar las tareas eligiendo la más temprana o la más tardía de las dos. Siempre podemos elegir el primer `Right` en vez de cortocircuitar con `Left`, que tiene el efecto de ignorar los errores. Hay una interfaz llamada *Alternative* (Alternativa) que implementa alguno de estos, bueno, ejemplares alternativos, típicamente concentrada en elegir más que en combinar en cascada. Vale la pena estudiarla si te ves en la necesidad de una funcionalidad como esta.

## Monoides A Cambio De Nada

Estamos abstrayendo la suma pero, como a los babilonios, nos falta el concepto de cero (hubo cero menciones sobre él).

El cero actúa como la *identidad* queriendo decir que cualquier elemento añadido a `0` devolverá ese mismo elemento. En términos de abstracción, sirve de ayuda pensar en el `0` como un elemento neutral o *vacío*. Es importante el hecho de que actúa de la misma manera tanto en el lado izquierdo como en el derecho de nuestra operación binaria:

```js
// identidad
1 + 0 = 1
0 + 1 = 1
```

Denominemos `empty` (vacío) a este concepto y creemos con él una nueva interfaz. Como tantas startups, escogeremos un abominable y poco informativo a la vez que googleable nombre: *Monoide*. La receta para *Monoide* es coger cualquier *semigrupo* y añadirle un elemento *identidad* especial. Vamos a implementar esto con una función `empty` en el propio tipo:

```js
Array.empty = () => []
String.empty = () => ""
Sum.empty = () => Sum(0)
Product.empty = () => Product(1)
Min.empty = () => Min(Infinity)
Max.empty = () => Max(-Infinity)
All.empty = () => All(true)
Any.empty = () => Any(false)
```

¿Cuándo podría un valor identidad vacío demostrar ser útil? Eso es como preguntar por qué el cero es útil. Como no preguntar nada en absoluto...

Cuando no tenemos nada más, ¿en quién podemos contar? Cero. ¿Cuántos bugs queremos? Cero. Esta es nuestra tolerancia hacía el código no confiable. Un nuevo comienzo. El precio definitivo. Puede aniquilar todo lo que haya en su camino o salvarnos de un apuro. Un salvavidas dorado y un pozo de desesperación.

En cuanto al código, corresponden a valores por defecto:

```js
const settings = (prefix="", overrides=[], total=0) => ...

const settings = (prefix=String.empty(), overrides=Array.empty(), total=Sum.empty()) => ...
```

O para devolver un valor útil cuando no tenemos nada más:

```js
sum([]) // 0
```

También son el valor inicial perfecto para un acumulador...

## Doblando La Casa

Resulta que `concat` y `empty` encajan perfectamente con las dos primeras ranuras de `reduce`. De hecho podemos reducir un array de *semigrupos* ignorando el valor *vacío*, pero, como puedes ver, esto conduce a una precaria situación:

```js
// concat :: Semigroup s => s -> s -> s
const concat = x => y => x.concat(y)

[Sum(1), Sum(2)].reduce(concat) // Sum(3)

[].reduce(concat) // TypeError: Reduce of empty array with no initial value
```

Y la dinamita explota. Como un tobillo torcido en una maratón, obtenemos un error de ejecución. JavaScript es más que feliz dejando que nos atemos pistolas a nuestras zapatillas deportivas antes de salir a correr; es algo así como un lenguaje conservador, supongo, pero nos detiene en seco cuando el array se torna yermo. ¿Qué podría devolver ahora?¿`Nan`, `false`, `-1`? Si fuésemos a continuar con nuestro programa, querríamos un resultado del tipo correcto. Podría devolver un `Maybe` para indicar la posibilidad de fallo, pero podemos hacer algo mejor.

Vamos a utilizar nuestra versión currificada de `reduce` y a hacer una versión segura donde el valor vacío no sea opcional. En lo sucesivo será conocida como `fold`:

```js
// fold :: Monoid m => m -> [m] -> m
const fold = reduce(concat)
```

La `m` inicial es nuestro valor vacío; nuestro punto neutro inicial, y luego tomamos un array de `m`s y las aplastamos hasta llegar a un hermoso valor diamantino.

```js
fold(Sum.empty(), [Sum(1), Sum(2)]) // Sum(3)
fold(Sum.empty(), []) // Sum(0)

fold(Any.empty(), [Any(false), Any(true)]) // Any(true)
fold(Any.empty(), []) // Any(false)


fold(Either.of(Max.empty()), [Right(Max(3)), Right(Max(21)), Right(Max(11))]) // Right(Max(21))
fold(Either.of(Max.empty()), [Right(Max(3)), Left('error retrieving value'), Right(Max(11))]) // Left('error retrieving value')

fold(IO.of([]), ['.link', 'a'].map($)) // IO([<a>, <button class="link"/>, <a>])
```

Hemos proporcionado manualmente un valor vacío para estos dos últimos, ya que no podemos definir uno en el propio tipo. Eso es totalmente correcto. Los lenguajes tipados pueden averiguarlo por ellos mismos, pero aquí tenemos que pasarlo nosotros.

## No Un Monoide Exactamente

Hay algunos *semigrupos* que no pueden convertirse en *monoides*, o sea, que no pueden proporcionar un valor inicial. Fíjate en `First`:

```js
const First = x => ({ x, concat: other => First(x) })

Map({id: First(123), isPaid: Any(true), points: Sum(13)}).concat(Map({id: First(2242), isPaid: Any(false), points: Sum(1)}))
// Map({id: First(123), isPaid: Any(true), points: Sum(14)})
```

Fusionaremos un par de cuentas y mantendremos el primer id. No hay manera de definir un valor vacío para ello. Esto no significa que no sea útil.


## Gran Teoría Unificadora

## ¿Teoría De Grupos O Teoría De Categorías?

En el álgebra abstracta el concepto de operación binaria está en todas partes. Para una *categoría* es, de hecho, la operación primaria. Sin embargo, no podemos modelar nuestra operación en la teoría de categorías sin una *identidad*. Esta es la razón por la que comenzamos con un semigrupo de la teoría de grupos para luego, una vez tenemos el elemento *vacío*, saltar a un monoide de la teoría de categorías.

Los monoides forman una categoría de un solo objeto donde el morfismo es `concat`, `empty` es la identidad y la composición está garantizada.

### Composición Como Monoide

Las funciones de tipo `a -> a`, donde el dominio es del mismo conjunto que el codominio, son llamadas *endomorfismos*. Podemos crear un *monoide* llamado *Endo* que capture esta idea:

```js
const Endo = run => ({
  run,
  concat: other =>
    Endo(compose(run, other.run))
})

Endo.empty = () => Endo(identity)


// en acción

// thingDownFlipAndReverse :: Endo [String] -> [String]
const thingDownFlipAndReverse = fold(Endo(() => []), [Endo(reverse), Endo(sort), Endo(append('thing down')])

thingDownFlipAndReverse.run(['let me work it', 'is it worth it?'])
// ['thing down', 'let me work it', 'is it worth it?']
```

Dado que todos son del mismo tipo, podemos concatenar a través de `compose` y los tipos siempre se alinean.

### Mónada Como Monoide

Puede que hayas notado que `join` es una operación que toma dos mónadas (anidadas) y las aplasta en una sola de manera asociativa. Es también una transformación natural o una "función functor". Como establecimos anteriormente, podemos crear una categoría con functores como objetos y transformaciones naturales como morfismos. Si la especializamos en *Endofunctores*, o sea, functores del mismo tipo, entonces `join` nos provee de un monoide en la categoría de Endofunctores también conocida como Mónada. Mostrar en código la formulación exacta requiere de algunos trucos que te animo a googlear, pero esta es la idea general.

### Aplicativo Como Monoide

Incluso lo functores aplicativos tienen una formulación monoidal conocida en teoría de categorías como *functor monoidal laxo*. Podemos implementar la interfaz como un monoide y recuperar `ap` de él:

```js
// concat :: f a -> f b -> f [a, b]
// empty :: () -> f ()

// ap :: Functor f => f (a -> b) -> f a -> f b
const ap = compose(map(([f, x]) => f(x)), concat)
```


## En Resumen

Como puedes ver, todo está conectado, o puede estarlo. Este profundo hecho convierte a los *Monoides* en una poderosa herramienta de modelado para amplias franjas de la arquitectura de aplicaciones llegando hasta las piezas de datos más pequeñas. Te animo a pensar en *monoides* cuándo la acumulación o combinación directas formen parte de tu aplicación, y a que, una vez lo tengas claro, empieces a ampliar la definición a más aplicaciones (te sorprenderá lo mucho que se puede modelar con un *monoide*).

## Ejercicios

