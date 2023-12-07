# Capítulo 10: Funtores Aplicativos

## Aplicando Aplicativos

El nombre **funtor aplicativo** es placenteramente descriptivo dados sus orígenes funcionales. Los programadores funcionales son conocidos por aparecer con nombres como `mappend` o `liftA4`, que parecen perfectamente naturales cuando se ven en el laboratorio de matemáticas, pero que en cualquier otro contexto son claros como un Darth Vader indeciso en el autoservicio.

En cualquier caso, el nombre debería revelar lo que esta interfaz nos da: *la capacidad de aplicar funtores entre ellos*.

Pero, ¿por qué una persona normal y racional como tú querría una cosa así? Incluso, ¿qué *significa* aplicar un funtor a otro?

Para responder a estas preguntas, comenzaremos con una situación en la que ya te habrás visto en tus viajes funcionales. Digamos que, hipotéticamente, tenemos dos funtores (del mismo tipo) con sus respectivos valores, y que queremos llamar a una función con esos dos valores como argumentos. Algo simple, como sumar los valores de dos `Container`.

```js
// No podemos hacer esto porque los números están embotellados.
add(Container.of(2), Container.of(3));
// NaN

// Usemos nuestra función map en la que tanto confiamos
const containerOfAdd2 = map(add, Container.of(2));
// Container(add(2))
```

Ahora tenemos un `Container` con una función dentro que está parcialmente aplicada. Más específicamente, tenemos un `Container(add(2))` y queremos aplicar su `add(2)` al `3` de `Container(3)` para completar la llamada. En otras palabras, queremos aplicar un funtor a otro funtor.

Pues resulta que ya tenemos las herramientas para llevar a cabo esta tarea. Podemos aplicar `chain` y luego `map` a la función parcialmente aplicada `add(2)`, tal que así:

```js
Container.of(2).chain(two => Container.of(3).map(add(two)));
```

El problema aquí es que estamos atrapados en el mundo secuencial de las mónadas en el que nada puede ser evaluado hasta que la mónada anterior haya terminado su trabajo. Tenemos dos valores fuertes e independientes y parece innecesario retrasar la creación de `Containter(3)` tan solo para satisfacer las demandas secuenciales de las mónadas.

De hecho, si nos viésemos en este aprieto, sería maravilloso si pudiéramos, sucintamente, aplicar el contenido de un funtor al valor de otro, sin esas funciones y variables innecesarias.


## Barcos en Botellas

<img src="images/ship_in_a_bottle.jpg" alt="https://www.deviantart.com/hollycarden" />

`ap` es una función que puede aplicar la función contenida en un funtor al valor contenido en otro. Di esto cinco veces más rápido.

```js
Container.of(add(2)).ap(Container.of(3));
// Container(5)

// ahora todo junto

Container.of(2).map(add).ap(Container.of(3));
// Container(5)
```

Así sí, bonito y limpio. Buenas noticias para `Container(3)` dado que ha sido liberado de la cárcel de la función monádica anidada. Vale la pena mencionar de nuevo que `add`, en este caso, resulta parcialmente aplicada durante el primer `map` así que esto solo funciona cuando `add` está currificada.

Podemos definir `ap` como:

```js
Container.prototype.ap = function (otherContainer) {
  return otherContainer.map(this.$value);
};
```

Recuerda, `this.$value` será una función y aceptaremos otro funtor por lo que solo necesitaremos mapearlo. Y con eso tenemos definida nuestra interfaz:


> Un *funtor aplicativo* es un funtor pointed con un método `ap`

Observa la dependencia en **pointed**. La interfaz pointed es aquí crucial, tal y como veremos en los próximos ejemplos.

Percibo tu escepticismo (o quizás confusión y horror), pero mantén la mente abierta; este personaje `ap` demostrará ser de utilidad. Antes de meternos en ello, exploremos una bonita propiedad.

```js
F.of(x).map(f) === F.of(f).ap(F.of(x));
```

En correcto español, mapear `f` equivale a usar la función `ap` de un funtor de `f`. O en un español más correcto, podemos colocar `x` en nuestro contendor y hacer `map(f)`, o, podemos levantar tanto `f` como `x` en nuestro contenedor y luego aplicarles `ap`. Esto nos permite escribir de izquierda a derecha:

```js
Maybe.of(add).ap(Maybe.of(2)).ap(Maybe.of(3));
// Maybe(5)

Task.of(add).ap(Task.of(2)).ap(Task.of(3));
// Task(5)
```

Entrecerrando los ojos, se puede incluso reconocer vagamente la manera normal de llamar a una función. Más adelante en el capítulo veremos la versión pointfree, pero por ahora, esta es la manera preferida de escribir un código como este. Usando `of`, cada valor es transportado al mágico mundo de los contenedores, ese universo paralelo donde cada aplicación puede ser asíncrona o nula o lo que sea y donde `ap` aplicará funciones dentro de ese lugar de fantasía. Es como construir un barco dentro de una botella.

¿Has visto? Hemos utilizado `Task` en nuestro ejemplo. Esta es una de las principales situaciones en las que los funtores aplicativos muestran su fuerza. Veamos un ejemplo más en profundidad.

## Motivación para la Coordinación

Digamos que estamos construyendo un sitio web de viajes y que queremos recuperar tanto una lista de destinos turísticos como de eventos locales. Cada una es una llamada separada e independiente.

```js
// Http.get :: String -> Task Error HTML

const renderPage = curry((destinations, events) => { /* generar página */ });

Task.of(renderPage).ap(Http.get('/destinations')).ap(Http.get('/events'));
// Task("<div>una página con destinos y eventos</div>")
```

Ambas llamadas `Http` se harán a la vez y `renderPage` será llamada cuando ambas se hayan resuelto. Contrasta esto con la versión monádica en la que una tarea `Task` debe finalizar antes de que se inicie la siguiente. Dado que no necesitamos los destinos para recuperar los eventos, nos libramos de la evaluación secuencial.

De nuevo, como estamos utilizando aplicación parcial para alcanzar este resultado, debemos asegurarnos de que `renderPage` está currificada o no esperará a que terminen ambas tareas. Por cierto, si alguna vez has tenido que hacer algo así manualmente, apreciarás la asombrosa simplicidad de esta interfaz. Esta es la bonita forma del código que nos acerca un paso más hacia la singularidad.

Veamos otro ejemplo.

```js
// $ :: String -> IO DOM
const $ = selector => new IO(() => document.querySelector(selector));

// getVal :: String -> IO String
const getVal = compose(map(prop('value')), $);

// signIn :: String -> String -> Bool -> User
const signIn = curry((username, password, rememberMe) => { /* signing in */ });

IO.of(signIn).ap(getVal('#email')).ap(getVal('#password')).ap(IO.of(false));
// IO({ id: 3, email: 'gg@allin.com' })
```

`signIn` es una función currificada de 3 argumentos por lo que tenemos que aplicar `ap` en consecuencia. Con cada `ap`, `signIn` recibe un argumento más hasta que está completa y luego se ejecuta. Podemos seguir este patrón con tantos argumentos como sea necesario. Otra cosa a tener en cuenta es que dos argumentos terminan de manera natural en `IO` mientras que el último necesita una pequeña ayuda de `of` para levantarlo a `IO` ya que `ap` espera que la función y todos sus argumentos sean del mismo tipo.

## Colega, ¿Alguna Vez Levantas?

Examinemos una manera *pointfree* de escribir esas llamadas aplicativas. Dado que sabemos que `map` equivale a `of/ap`, podemos escribir funciones genéricas que aplicarán `ap` tantas veces como especifiquemos:

```js
const liftA2 = curry((g, f1, f2) => f1.map(g).ap(f2));

const liftA3 = curry((g, f1, f2, f3) => f1.map(g).ap(f2).ap(f3));

// liftA4, etc
```

`liftA2` es un nombre extraño. Suena a uno de esos ascensores de carga poco fiables de una fábrica en decadencia o a una matrícula para una empresa de limusinas baratas. Sin embargo, una vez aclarado, se explica por sí mismo: levanta esas piezas al mundo del funtor aplicativo.

Cuando vi por primera vez ese sin sentido de 2-3-4 me pareció feo e innecesario. Después de todo, podemos comprobar la aridad de las funciones en JavaScript y construirlas dinámicamente. Sin embargo, suele ser útil aplicar parcialmente a `liftA(N)` para que no pueda variar en la cantidad de argumentos.

Veámoslo en uso:

```js
// checkEmail :: User -> Either String Email
// checkName :: User -> Either String String

const user = {
  name: 'John Doe',
  email: 'blurp_blurp',
};

//  createUser :: Email -> String -> IO User
const createUser = curry((email, name) => { /* creando... */ });

Either.of(createUser).ap(checkEmail(user)).ap(checkName(user));
// Left('email inválido')

liftA2(createUser, checkEmail(user), checkName(user));
// Left('email inválido')
```

Como `createUser` toma dos argumentos, utilizamos el correspondiente `liftA2`. Las dos sentencias son equivalentes, pero la versión `liftA2` no menciona a `Either`. Esto la hace más genérica y flexible, ya que dejamos de casarnos con un tipo específico.


Veamos los ejemplos anteriores escritos de esta manera:

```js
liftA2(add, Maybe.of(2), Maybe.of(3));
// Maybe(5)

liftA2(renderPage, Http.get('/destinations'), Http.get('/events'));
// Task('<div>una página con destinos y eventos</div>')

liftA3(signIn, getVal('#email'), getVal('#password'), IO.of(false));
// IO({ id: 3, email: 'gg@allin.com' })
```


## Operadores

En lenguajes como Haskell, Scala, PureScript y Swift, en los cuales es posible crear tus propios operadores infijos, puedes ver sintaxis como esta:

```hs
-- Haskell / PureScript
add <$> Right 2 <*> Right 3
```

```js
// JavaScript
map(add, Right(2)).ap(Right(3));
```

Es útil saber que `<$>` es `map` (también conocido como `fmap`) y que `<*>` es simplemente `ap`. Esto permite un estilo de aplicación de funciones más natural y puede ayudar a eliminar algunos paréntesis.

## Abrelatas Gratis
<img src="images/canopener.jpg" alt="http://www.breannabeckmeyer.com/" />

No hemos hablado mucho de las funciones derivadas. Dado que todas estas interfaces se construyen a partir de otras y obedecen a un conjunto de leyes, podemos definir algunas interfaces más débiles en términos de las más fuertes.

Por ejemplo, sabemos que un aplicativo es primero un funtor, así que, si tenemos un ejemplar de aplicativo, seguramente podamos definir un funtor para nuestro tipo.

Esta clase de perfecta harmonia computacional es posible porque estamos trabajando dentro de un marco matemático. Mozart no podría haberlo hecho mejor aún teniendo Ableton de niño.

Antes mencioné que `of/ap` equivale a `map`. Podemos utilizar este conocimiento para definir `map`:

```js
// map derivado de of/ap
X.prototype.map = function map(f) {
  return this.constructor.of(f).ap(this);
};
```

Las mónadas están, por así decirlo, arriba del todo de la cadena alimenticia, así que si tenemos a `chain`, obtenemos funtor y aplicativo de forma gratuita:

```js
// map derivada de chain
X.prototype.map = function map(f) {
  return this.chain(a => this.constructor.of(f(a)));
};

// ap derivada de chain/map
X.prototype.ap = function ap(other) {
  return this.chain(f => other.map(f));
};
```

Si podemos definir una mónada, podemos definir tanto la interfaz de aplicativo como la de funtor. Esto es bastante notable, ya que obtenemos todos estos abrelatas sin coste alguno. Podemos incluso examinar un tipo y automatizar este proceso.

Hay que señalar que parte del atractivo de `ap` es su capacidad para ejecutar cosas de manera concurrente, por lo que definirla mediante `chain` hace que se pierda esa optimización. A pesar de esto, es bueno tener una interfaz funcionando inmediatamente mientras uno trabaja en la mejor implementación posible.

¿Por qué no utilizar mónadas y así ya estar listos?, te preguntarás. Es una buena práctica trabajar con el nivel de potencia que necesitas en cada momento, ni más, ni menos. Al descartar posibles funcionalidades, mantenemos la carga cognitiva al mínimo. Es por esto que es bueno favorecer a los aplicativos por encima de las mónadas.

Las mónadas tienen la capacidad única de secuenciar el cálculo, asignar variables, y detener la ejecución siguiente, todo ello gracias a la estructura de anidamiento descendente. Cuando vemos que se usan aplicativos, no tenemos que estar atentos a nada de eso.

Y ahora, sobre los aspectos legales...

## Leyes

Al igual que el resto de construcciones matemáticas que hemos explorado, los funtores aplicativos tienen algunas propiedades que pueden sernos útiles en nuestro día a día programando. En primer lugar, debes saber que los aplicativos están "cerrados bajo composición", lo que significa que `ap` nunca nos cambiará el tipo de los contenedores (otra razón más para favorecerlos por encima de las mónadas). Eso no quiere decir que no podamos tener múltiples efectos diferentes; podemos apilar nuestros tipos sabiendo que seguirán siendo los mismos durante toda nuestra aplicación.

Para demostrarlo:

```js
const tOfM = compose(Task.of, Maybe.of);

liftA2(liftA2(concat), tOfM('Rainy Days and Mondays'), tOfM(' always get me down'));
// Task(Maybe(Rainy Days and Mondays always get me down))
```

Lo ves, no hay que preocuparse de que los diferentes tipos se mezclen.

Llega el momento de ver nuestra ley favorita de la teoría de categorías: *identidad*:

### Identidad

```js
// identidad
A.of(id).ap(v) === v;
```

Bien, así que aplicar `id` desde el interior de un funtor no debería alterar el valor en `v`. Por ejemplo:

```js
const v = Identity.of('Pillow Pets');
Identity.of(id).ap(v) === v;
```

`Identity.of(id)` me hace reir por lo inútil que es. De todos modos, lo que resulta aquí interesante, como ya establecimos antes, es que `of/ap` es lo mismo que `map`, por lo que esta ley se deduce directamente de la identidad del funtor: `map(id) == id`.

La belleza de usar estas leyes es que, igual que un entrenador de gimnasia de guardería, obligan a todas nuestras interfaces a jugar bien entre ellas.

### Homomorfismo

```js
// Homomorfismo
A.of(f).ap(A.of(x)) === A.of(f(x));
```

Un *homomorfismo* tan solo es un map que preserva la estructura. De hecho, un funtor solo es un *homomorfismo* entre categorías, ya que preserva la estructura original de la categoría que está siendo mapeada.


Realmente, tan solo estamos metiendo nuestras funciones y valores normales en un contenedor y ejecutando el cálculo en su interior, así que no debería sorprendernos que alcancemos el mismo resultado si aplicamos todo dentro del contenedor (lado izquierdo de la ecuación) o lo aplicamos fuera y luego lo colocamos dentro (lado derecho).

Un ejemplo rápido:

```js
Either.of(toUpperCase).ap(Either.of('oreos')) === Either.of(toUpperCase('oreos'));
```

### Intercambio

La ley del *intercambio* establece que no importa si elegimos levantar nuestra función en el lado izquierdo o en el derecho de `ap`.

```js
// intercambio
v.ap(A.of(x)) === A.of(f => f(x)).ap(v);
```

He aquí un ejemplo:

```js
const v = Task.of(reverse);
const x = 'Sparklehorse';

v.ap(Task.of(x)) === Task.of(f => f(x)).ap(v);
```

### Composición

Y, por último, la composición, que no es más que una manera de comprobar que nuestra composición estándar de funciones se mantiene cuando se aplica dentro de los contenedores.

```js
// composición
A.of(compose).ap(u).ap(v).ap(w) === u.ap(v.ap(w));
```

```js
const u = IO.of(toUpperCase);
const v = IO.of(concat('& beyond'));
const w = IO.of('blood bath ');

IO.of(compose).ap(u).ap(v).ap(w) === u.ap(v.ap(w));
```

## En Resumen

Un buen caso de uso para los aplicativos es cuando tenemos múltiples argumentos de funtor. Nos dan la posibilidad de aplicar funciones a los argumentos todo dentro del mundo de los funtores. Aunque ya podíamos hacer esto con las mónadas, preferiremos los funtores aplicativos cuando no necesitemos ninguna funcionalidad monádica específica.

Casi hemos terminado con las apis de contenedores. Hemos aprendido a como aplicar `map`, `chain`, y ahora `ap`, a funciones. En el próximo capítulo aprenderemos a como trabajar mejor con múltiples funtores y a como desmontarlos siguiendo unos principios.

[Capítulo 11: Transforma Otra Vez, Naturalmente](ch11-es.md)


## Ejercicios

{% exercise %}  
Escribe una función, utilizando `Maybe` y `ap`, que sume dos números que pueden ser null.
  
{% initial src="./exercises/ch10/exercise_a.js#L3;" %}  
```js  
// safeAdd :: Maybe Number -> Maybe Number -> Maybe Number  
const safeAdd = undefined;  
```  
  
  
{% solution src="./exercises/ch10/solution_a.js" %}  
{% validation src="./exercises/ch10/validation_a.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
  
  
---  
  
  
{% exercise %}  
Reescribe `safeAdd` de exercise_a para que utilice `liftA2` en vez de `ap`.
  
{% initial src="./exercises/ch10/exercise_b.js#L3;" %}  
```js  
// safeAdd :: Maybe Number -> Maybe Number -> Maybe Number  
const safeAdd = undefined;  
```  
  
  
{% solution src="./exercises/ch10/solution_b.js" %}  
{% validation src="./exercises/ch10/validation_b.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
  
  
---  
  
Para el próximo ejercicio, tendremos en cuenta las siguientes funciones de soporte:
  
```js  
const localStorage = {  
  player1: { id:1, name: 'Albert' },  
  player2: { id:2, name: 'Theresa' },  
};  
  
// getFromCache :: String -> IO User  
const getFromCache = x => new IO(() => localStorage[x]);  
  
// game :: User -> User -> String  
const game = curry((p1, p2) => `${p1.name} vs ${p2.name}`);  
```  
  
{% exercise %}  
Escribe un IO que tome de la caché tanto a player1 como a player2 y que inicie el juego.
  
  
{% initial src="./exercises/ch10/exercise_c.js#L16;" %}  
```js  
// startGame :: IO String  
const startGame = undefined;  
```  
  
  
{% solution src="./exercises/ch10/solution_c.js" %}  
{% validation src="./exercises/ch10/validation_c.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
