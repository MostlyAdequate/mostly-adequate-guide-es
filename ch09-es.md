# Capítulo 09: Cebollas Monádicas

## Factoría de Funtores Punzantes

Antes de seguir avanzando, tengo algo que confesar: No he sido completamente honesto sobre ese método `of` que hemos colocado en cada uno de nuestros tipos. Resulta que no está ahí para evitar la palabra clave `new`, si no para colocar los valores en lo que se llama *contexto mínimo por defecto*. Sí, `of` no sustituye a un constructor, sino que forma parte de una importante interfaz a la que llamamos *Pointed*.

> Un *funtor pointed* es un funtor con un método `of`

Lo importante aquí es la capacidad de dejar caer cualquier valor dentro de nuestro tipo y poder empezar a aplicar map.

```js
IO.of('tetris').map(concat(' master'));
// IO('tetris master')

Maybe.of(1336).map(add(1));
// Maybe(1337)

Task.of([{ id: 2 }, { id: 3 }]).map(map(prop('id')));
// Task([2,3])

Either.of('The past, present and future walk into a bar...').map(concat('it was tense.'));
// Right('The past, present and future walk into a bar...it was tense.')
```

Si recuerdas, los constructores de `IO` y `Task` esperan una función como argumento, pero `Maybe` y `Either` no. La motivación para esta interfaz es tener una forma común y consistente de colocar un valor en nuestro funtor sin las complejidades y demandas específicas de cada constructor. El término "contexto mínimo por defecto" carece de precisión, pero recoge bien la idea: nos gustaría levantar cualquier valor dentro de nuestro tipo y aplicarle `map` como de costumbre, obteniendo el comportamiento esperado de cualquier funtor.

Una corrección importante que debo hacer llegados a este punto (el juego de palabras es intencionado), es que `Left.of` no tiene ningún sentido. Cada funtor debe tener una forma de colocarle dentro un valor y en `Either` eso se hace con `new Right(x)`. Definimos `of` usando `Right` porque si nuestro tipo *puede* aplicar `map`, debe aplicar `map`. Viendo los ejemplos anteriores, deberíamos intuir como funcionará `of` normalmente y `Left` rompe ese molde.

Es posible que hayas oído hablar de funciones como `pure`, `point`, `unit`, y `return`. Estos son varios alias para nuestro método `of`, la función internacional del misterio. `of` será importante cuando empecemos a usar mónadas porque, como veremos, es nuestra responsabilidad volver a colocar los valores en el tipo manualmente.

Para evitar la palabra clave `new`, hay varios trucos estándar en JavaScript o en librerías así que los utilizaremos y de ahora en adelante usaremos `of` como adultos responsables que somos. Recomiendo usar funtores de `folktale`, `ramda` o `fantasy-land` ya que proporcionan el método `of` correcto así como amables constructores que no dependen de `new`.


## Mezclando Metáforas

<img src="images/onion.png" alt="cebolla" />

Verás, además de burritos espaciales (si has oído los rumores), las mónadas son como las cebollas. Permíteme demostrarlo con una situación muy común:

```js
const fs = require('fs');

// readFile :: String -> IO String
const readFile = filename => new IO(() => fs.readFileSync(filename, 'utf-8'));

// print :: String -> IO String
const print = x => new IO(() => {
  console.log(x);
  return x;
});

// cat :: String -> IO (IO String)
const cat = compose(map(print), readFile);

cat('.git/config');
// IO(IO('[core]\nrepositoryformatversion = 0\n'))
```

Lo que tenemos aquí es un `IO` atrapado dentro de otro `IO` porque `print` introdujo un segundo `IO` al aplicarlo con `map`. Para seguir trabajando con nuestro string, debemos hacer `map(map(f))` y para ver el efecto debemos hacer `unsafePerformIO().unsafePerformIO()`.

```js
// cat :: String -> IO (IO String)
const cat = compose(map(print), readFile);

// catFirstChar :: String -> IO (IO String)
const catFirstChar = compose(map(map(head)), cat);

catFirstChar('.git/config');
// IO(IO('['))
```

Aunque es bueno ver que en nuestra aplicación tenemos dos efectos empaquetados y listos para salir, se parece a trabajar con dos trajes de seguridad contra materiales peligrosos y acabamos con una extraña e incómoda API. Veamos otra situación:

```js
// safeProp :: Key -> {Key: a} -> Maybe a
const safeProp = curry((x, obj) => Maybe.of(obj[x]));

// safeHead :: [a] -> Maybe a
const safeHead = safeProp(0);

// firstAddressStreet :: User -> Maybe (Maybe (Maybe Street))
const firstAddressStreet = compose(
  map(map(safeProp('street'))),
  map(safeHead),
  safeProp('addresses'),
);

firstAddressStreet({
  addresses: [{ street: { name: 'Mulburry', number: 8402 }, postcode: 'WC2N' }],
});
// Maybe(Maybe(Maybe({name: 'Mulburry', number: 8402})))
```

De nuevo vemos esta situación en la que tenemos funtores anidados donde se puede ver claramente que hay tres posibilidades de fallo en nuestra función, pero es un poco presuntuoso esperar que quien nos llama aplicará `map` tres veces para llegar al valor, que acabamos de conocer. Este patrón aparecerá una y otra vez y es la principal situación por la que necesitaremos hacer brillar en el cielo nocturno al poderoso símbolo de la mónada.

He dicho que las mónadas son como cebollas porque se nos saltan las lágrimas cuando pelamos con `map` cada capa de funtor anidado para llegar al valor del interior. Podemos secar nuestros ojos, respirar hondo, y utilizar un método llamado `join`.

```js
const mmo = Maybe.of(Maybe.of('nunchucks'));
// Maybe(Maybe('nunchucks'))

mmo.join();
// Maybe('nunchucks')

const ioio = IO.of(IO.of('pizza'));
// IO(IO('pizza'))

ioio.join();
// IO('pizza')

const ttt = Task.of(Task.of(Task.of('sewers')));
// Task(Task(Task('sewers')));

ttt.join();
// Task(Task('sewers'))
```

Si tenemos dos capas del mismo tipo, podemos unirlas aplastándolas juntas con `join`. Esta capacidad de unir, este matrimonio de funtores, es lo que hace mónada a una mónada. Avancemos hacia la definición completa con algo un poco más preciso:

> Las mónadas son funtores pointed que pueden aplanar

Cualquier funtor que defina un método `join`, que tenga un método `of`, y que obedezca unas pocas leyes, es una mónada. Definir `join` no es muy difícil así que hagámoslo para `Maybe`:

```js
Maybe.prototype.join = function join() {
  return this.isNothing() ? Maybe.of(null) : this.$value;
};
```

Ahí está, tan simple como absorber a nuestro propio gemelo en el vientre. Si tenemos `Maybe(Maybe(x))` entonces `.$value` simplemente eliminará la capa adicional innecesaria y, a partir de ahí, podremos aplicar `map` con seguridad. De lo contrario, solo tendremos el `Maybe` ya que no se habría mapeado nada en primer lugar.

Ahora que tenemos un método `join`, vamos a espolvorear algo de polvo de mónada mágica sobre el ejemplo de `firstAddressStreet` y a verlo en acción:

```js
// join :: Monad m => m (m a) -> m a
const join = mma => mma.join();

// firstAddressStreet :: User -> Maybe Street
const firstAddressStreet = compose(
  join,
  map(safeProp('street')),
  join,
  map(safeHead), safeProp('addresses'),
);

firstAddressStreet({
  addresses: [{ street: { name: 'Mulburry', number: 8402 }, postcode: 'WC2N' }],
});
// Maybe({name: 'Mulburry', number: 8402})
```

Hemos añadido `join` allá donde nos hemos encontrado `Maybe`s anidados para evitar que se nos vayan de las manos. Hagamos lo mismo con `IO` para asentar la idea.

```js
IO.prototype.join = () => this.unsafePerformIO();
```

De nuevo, nosotros solo hemos eliminado una capa. O sea, no nos hemos deshecho de la pureza, sino que simplemente hemos eliminado una capa sobrante de embalaje.

```js
// log :: a -> IO a
const log = x => new IO(() => {
  console.log(x);
  return x;
});

// setStyle :: Selector -> CSSProps -> IO DOM
const setStyle =
  curry((sel, props) => new IO(() => jQuery(sel).css(props)));

// getItem :: String -> IO String
const getItem = key => new IO(() => localStorage.getItem(key));

// applyPreferences :: String -> IO DOM
const applyPreferences = compose(
  join,
  map(setStyle('#main')),
  join,
  map(log),
  map(JSON.parse),
  getItem,
);

applyPreferences('preferences').unsafePerformIO();
// Object {backgroundColor: "green"}
// <div style="background-color: 'green'"/>
```

`getItem` devuelve un `IO String` así que aplicamos `map` para parsearlo. Tanto `log` como `setStyle` devuelven `IO` por lo que hemos de aplicar `join` para mantener nuestro anidamiento bajo control.

## Mi Cadena Golpea Mi Pecho

<img src="images/chain.jpg" alt="cadena" />

Puede que hayas notado un patrón. A menudo acabamos llamando a `join` justo después de un `map`. Abstraigamos esto en una función llamada `chain` [*cadena*].

```js
// chain :: Monad m => (a -> m b) -> m a -> m b
const chain = curry((f, m) => m.map(f).join());

// or

// chain :: Monad m => (a -> m b) -> m a -> m b
const chain = f => compose(join, map(f));
```

Tan solo hemos agrupado este combo map/join en una sola función. Si has leído sobre mónadas anteriormente, puede que también hayas visto a `chain` llamada como `>>=` (pronunciado bind) o `flatMap` que son todo alias para el mismo concepto. Personalmente, creo que `flatMap` es el nombre más preciso, pero continuaremos con `chain` ya que es el nombre ampliamente aceptado en JS. Refactoricemos los dos ejemplos anteriores con `chain`:

```js
// map/join
const firstAddressStreet = compose(
  join,
  map(safeProp('street')),
  join,
  map(safeHead),
  safeProp('addresses'),
);

// chain
const firstAddressStreet = compose(
  chain(safeProp('street')),
  chain(safeHead),
  safeProp('addresses'),
);

// map/join
const applyPreferences = compose(
  join,
  map(setStyle('#main')),
  join,
  map(log),
  map(JSON.parse),
  getItem,
);

// chain
const applyPreferences = compose(
  chain(setStyle('#main')),
  chain(log),
  map(JSON.parse),
  getItem,
);
```

He reemplazado cualquier `map/join` por nuestra nueva función `chain` para ordenar un poco las cosas. Lo de limpiar está muy bien y tal, pero hay más cosas en `chain` de las que se ven a simple vista; es más un tornado que una aspiradora. Como `chain` anida efectos sin esfuerzo alguno, podemos capturar de una forma puramente funcional tanto la *secuencia* como la *asignación de variables*.

```js
// getJSON :: Url -> Params -> Task JSON
getJSON('/authenticate', { username: 'stale', password: 'crackers' })
  .chain(user => getJSON('/friends', { user_id: user.id }));
// Task([{name: 'Seimith', id: 14}, {name: 'Ric', id: 39}]);

// querySelector :: Selector -> IO DOM
querySelector('input.username')
  .chain(({ value: uname }) =>
    querySelector('input.email')
      .chain(({ value: email }) => IO.of(`Welcome ${uname} prepare for spam at ${email}`))
  );
// IO('Welcome Olivia prepare for spam at olivia@tremorcontrol.net');

Maybe.of(3)
  .chain(three => Maybe.of(2).map(add(three)));
// Maybe(5);

Maybe.of(null)
  .chain(safeProp('address'))
  .chain(safeProp('street'));
// Maybe(null);
```

Podríamos haber escrito estos ejemplos con `compose`, pero habríamos necesitado unas cuantas funciones de soporte y, de todos modos, este estilo se presta a la asignación explícita de variables a través de closures. En vez de esto estamos usando la versión infija de `chain` que, por cierto, puede ser derivada automáticamente de `map` y `join` para cualquier tipo: `t.prototype.chain = function(f) { return this.map(f).join(); }`. También podemos definir `chain` manualmente si queremos una falsa sensación de rendimiento, aunque deberemos tener cuidado con mantener la funcionalidad correcta, es decir, debe ser igual que `map` seguido de `join`. Un hecho interesante es que si hemos creado `chain` podemos derivar `map` sin mucho esfuerzo simplemente embotellando de nuevo el valor con `of` cuando hemos terminado. Con `chain`, también podemos definir `join` como `chain(id)`. Puede parecer que estamos jugando al "Texas Hold em" con un mago de la bisutería en el sentido de que nos estamos sacando cosas de la espalda, pero, como en la mayoría de las matemáticas, todas estas construcciones basadas en principios están interrelacionadas. Muchas de estas derivaciones se mencionan en el repo de [fantasyland](https://github.com/fantasyland/fantasy-land), que es la especificación oficial en JavaScript para tipos de datos algebraicos.

De todos modos, vamos a los ejemplos anteriores. En el primer ejemplo vemos dos tareas encadenadas en una secuencia de acciones asíncronas; primero recupera a la persona usuaria y luego con su id encuentra a sus amistades. Usamos `chain` para evitar vernos en la situación de `Task(Task([Friend]))`.

A continuación, utilizamos `querySelector` para encontrar diferentes entradas y crear un mensaje de bienvenida. Date cuenta de que en la función más interna tenemos acceso tanto a `uname` como a `email`; eso es asignación funcional de variables en su máxima expresión. Dado que `IO` nos presta amablemente su valor, tenemos la responsabilidad de dejarlo como lo encontramos, pues no querríamos corromper su veracidad (ni nuestro programa). `IO.of` es la herramienta perfecta para el trabajo y es la razón por la que Pointed es un prerrequisito importante para la interfaz Mónada. Sin embargo, podríamos optar por aplicar `map` ya que eso también devolvería el tipo correcto.

```js
querySelector('input.username').chain(({ value: uname }) =>
  querySelector('input.email').map(({ value: email }) =>
    `Welcome ${uname} prepare for spam at ${email}`));
// IO('Welcome Olivia prepare for spam at olivia@tremorcontrol.net');
```

Por último, tenemos dos ejemplos que usan `Maybe`. Dado que `chain` está usando map por debajo, si cualquier valor es nulo, detenemos en seco la computación.

No te preocupes si estos ejemplos son difíciles de entender al principio. Juega con ellos. Moléstales con un palo. Rómpelos en trozos y móntalos de nuevo. Recuerda aplicar `map` cuando lo devuelto sea un valor "normal" y `chain` cuando lo devuelto sea otro funtor. En el próximo capítulo, nos acercaremos a los `Aplicativos` y veremos buenos trucos para hacer que este tipo de expresiones sean más bonitas y altamente legibles.

Como recordatorio, esto no funciona con dos tipos anidados diferentes. La composición de funtores y, posteriormente, los transformadores de mónadas, pueden ayudarnos en esa situación.

## Borrachera de Poder

Programar utilizando contenedores puede llegar a ser confuso. En ocasiones nos vemos luchando por entender dentro de cuantos contenedores está un valor o si tenemos que utilizar `map` o `chain` (pronto veremos más métodos de contenedores). Podemos mejorar mucho la depuración con trucos como implementar `inspect` y aprenderemos a crear una pila [*stack*] que pueda manejar cualquier efecto que le lancemos, pero aún y así hay veces que nos preguntamos si merecen la pena tantas molestias.

Me gustaría blandir la ardiente espada monádica por un momento para exhibir el poder de programar de esta manera.

Leamos un archivo para después subirlo directamente: 

```js
// readFile :: Filename -> Either String (Task Error String)
// httpPost :: String -> String -> Task Error JSON
// upload :: Filename -> Either String (Task Error JSON)
const upload = compose(map(chain(httpPost('/uploads'))), readFile);
```

Aquí estamos bifurcando varias veces nuestro código. Mirando las firmas de tipo puedo ver que nos protegemos contra 3 errores. `readFile` utiliza `Either` para validar la entrada (quizás asegurándose de que el archivo está presente), `readFile` puede fallar cuando accede al archivo como expresa el primer parámetro de tipo de `Task`, y la subida puede fallar por cualquier razón tal y como expresa el `Error` en `httpPost`. Sin mucho esfuerzo hemos realizado con `chain` dos acciones asíncronas anidadas y secuenciales.

Todo esto se consigue con un solo flujo lineal de derecha a izquierda. Todo es puro y declarativo. Contiene razonamiento ecuacional y propiedades fiables. No nos vemos forzados a añadir confusos e innecesarios nombres de variables. Nuestra función `upload` está escrita con una interfaz genérica y no con una API específica de un solo uso. Es una maldita línea por dios.

Para contrastar, veamos la forma imperativa estándar de llevar esto a cabo:

```js
// upload :: Filename -> (String -> a) -> Void
const upload = (filename, callback) => {
  if (!filename) {
    throw new Error('You need a filename!');
  } else {
    readFile(filename, (errF, contents) => {
      if (errF) throw errF;
      httpPost('/uploads', contents, (errH, json) => {
        if (errH) throw errH;
        callback(json);
      });
    });
  }
};
```

Bueno, ¿no es esto la aritmética del diablo? Se nos hace rebotar a través de un volátil laberinto de locura. ¡Imagina que además fuese la típica app que va mutando variables sobre la marcha! Verdaderamente estaríamos en un pozo de alquitrán.

## Teoría

La primera ley que veremos es la asociatividad, pero puede que no de la forma acostumbrada.

```js
// asociatividad
compose(join, map(join)) === compose(join, join);
```

Estas leyes se refieren al anidamiento característico de las mónadas por lo que la asociatividad se centra en unir primero los tipos más internos o primero los más externos para llegar al mismo resultado. Una imagen puede ser más instructiva:

<img src="images/monad_associativity.png" alt="ley de la asociatividad de las mónadas" />

Empezando por la parte superior izquierda y moviéndonos hacia abajo, primero podemos unir con `join` las dos `M` más externas en `M(M(M a))` para luego llegar hasta nuestra deseada `M a` con otro `join`. Alternativamente, podemos abrir el capó y aplanar las dos `M` más internas con `map(join)`. Acabamos con la misma `M a` independientemente de si unimos primero las `M` más internas o primero las más externas y eso es todo sobre lo que trata la asociatividad. Hay que tener en cuenta que `map(join) != join`. Los pasos intermedios pueden variar en valor, pero el resultado final del último `join` será el mismo.

La segunda ley es similar:

```js
// identidad para todo (M a)
compose(join, of) === compose(join, map(of)) === id;
```

Afirma que, para cualquier mónada `M`, `of` y `join` equivale a `id`. Podemos incluso hacer `map(of)` y atacarla de dentro hacia afuera. A esto lo llamamos "identidad triangular" porque tiene esa forma cuando lo visualizamos:

<img src="images/triangle_identity.png" alt="ley de la identidad de las mónadas" />

Si comenzamos por arriba a la izquierda y vamos hacia la derecha, podemos ver que `of` deja caer nuestro `M a` dentro de otro contenedor `M`. Luego, si nos movemos hacia abajo y aplicamos `join`, obtenemos lo mismo que si hubiésemos llamado a `id` desde el principio. Moviéndonos de derecha a izquierda, vemos que si nos escabullimos bajo las mantas con `map` y llamamos a `of` con `a` tal cual, igualmente acabaremos con `M (M a)` y aplicando `join` volveremos al punto de partida.

Debo mencionar que acabo de escribir `of`, sin embargo, ha de ser el `M.of` específico para cualquier mónada que estemos utilizando. 

Un momento, he visto estas leyes, identidad y asociatividad, en algún otro sitio antes... Espera, estoy pensando... ¡Por supuesto! Son las leyes de una categoría. Pero eso significaría que necesitamos una función de composición para completar la definición. Contempla:

```js
const mcompose = (f, g) => compose(chain(f), g);

// identidad por la izquierda
mcompose(M, f) === f;

// identidad por la derecha
mcompose(f, M) === f;

// asociatividad
mcompose(mcompose(f, g), h) === mcompose(f, mcompose(g, h));
```

Estas son las leyes de la categoría después de todo. Las mónadas forman una categoría llamada "categoría Kleisli" en la que todos los objetos son mónadas y los morfismos son funciones encadenadas. No pretendo burlarme de ti con trozos de teoría de categorías y sin dar mucha explicación de como encaja el rompecabezas. La intención es arañar la superficie lo suficiente como para mostrar su relevancia, y despertar cierto interés mientras nos concentramos en las propiedades prácticas que podemos usar cada día.


## En Resumen

Las mónadas nos permiten perforar a través de computaciones anidadas. Podemos asignar variables, ejecutar efectos secuenciales, realizar tareas asíncronas, todo ello sin colocar un solo ladrillo en la pirámide del terror. Vienen al rescate cuando un valor se encuentra encarcelado bajo múltiples capas del mismo tipo. Con la ayuda del fiel compañero "pointed", las mónadas son capaces de prestarnos un valor sin su caja sabiendo que podremos colocarlo de nuevo donde estaba cuando hayamos terminado.

Sí, las mónadas son muy potentes, pero aún y así seguimos viendo que necesitamos algunas funciones de contenedor adicionales. Por ejemplo, ¿y si necesitamos ejecutar a la vez una lista de llamadas a una api y luego reunir los resultados? Podemos realizar esta tarea con mónadas, pero tendríamos que esperar a que cada una terminase antes de llamar a la siguiente. ¿Qué hay de combinar diversas validaciones? Nos gustaría seguir validando para ir recopilando la lista de errores, pero las mónadas detendrán el espectáculo nada más entrar a escena el primer `Left`.

En el próximo capítulo, veremos como encajan los funtores aplicativos en el mundo de los contenedores y por qué en muchos casos los preferimos a las mónadas.

[Capítulo 10: Funtores Aplicativos](ch10-es.md)


## Ejercicios


Considerando un objeto User como el que sigue:

```js  
const user = {  
  id: 1,  
  name: 'Albert',  
  address: {  
    street: {  
      number: 22,  
      name: 'Walnut St',  
    },  
  },  
};  
```  
  
{% exercise %}  
Utiliza `safeProp` y `map/join` o `chain` para obtener de manera segura el nombre 
de la calle cuando se proporciona un usuario
  
{% initial src="./exercises/ch09/exercise_a.js#L16;" %}  
```js  
// getStreetName :: User -> Maybe String  
const getStreetName = undefined;  
```  
  
  
{% solution src="./exercises/ch09/solution_a.js" %}  
{% validation src="./exercises/ch09/validation_a.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  


---


Consideremos ahora los siguientes elementos:

```js
// getFile :: IO String
const getFile = IO.of('/home/mostly-adequate/ch09.md');

// pureLog :: String -> IO ()
const pureLog = str => new IO(() => console.log(str));
```

{% exercise %}  
Utiliza getFile para obtener la ruta del archivo, eliminar el directorio y
mantener solo el nombre base y luego muéstralo de forma pura. Sugerencia: podrías
querer usar `split` y `last` para obtener el nombre base de una ruta de archivo.
  
{% initial src="./exercises/ch09/exercise_b.js#L13;" %}  
```js  
// logFilename :: IO ()  
const logFilename = undefined;  
  
```  
  
  
{% solution src="./exercises/ch09/solution_b.js" %}  
{% validation src="./exercises/ch09/validation_b.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  


---

Para este ejercicio, consideremos las funciones de soporte con las siguientes firmas:

```js
// validateEmail :: Email -> Either String Email
// addToMailingList :: Email -> IO([Email])
// emailBlast :: [Email] -> IO ()
```

{% exercise %}  
Utiliza `validateEmail`, `addToMailingList` y `emailBlast` para crear una función
que añada un nuevo correo electrónico a la lista de correo si este es válido, y que luego 
lo notifique a toda la lista.
  
{% initial src="./exercises/ch09/exercise_c.js#L11;" %}  
```js  
// joinMailingList :: Email -> Either String (IO ())  
const joinMailingList = undefined;  
```  
  
  
{% solution src="./exercises/ch09/solution_c.js" %}  
{% validation src="./exercises/ch09/validation_c.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
