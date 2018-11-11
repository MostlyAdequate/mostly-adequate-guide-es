# Tupperware

## El gran Contenedor 

<img src="images/jar.jpg" alt="http://blog.dwinegar.com/2011/06/another-jar.html" />

Todos hemos visto cómo crear programas que conducen data por un tubo compuesto de series de funciones puras. Son especificaciones declarativas de este comportamiento. Pero ¿Cómo controlar el flujo, manejar de errores, acciones asíncronas, estado y pero aún los `side effects` ó efectos secundarios? En este capítulo, vamos a descubrir la fundación sobre la cual estas abstracciones están construidas. 


Primero vamos a crear un contenedor. Este contenedor debe contener cualquier tipo de valor; como un ziplock que solo contiene pudín de tapioca, sin embargo, si solo lo contiene no nos dará mucho valor. Mejor debe ser un objeto, pero no le daremos métodos ni propiedades en el sentido OO (Programación dirigida a objetos). Trataremos este objeto como un baúl y que guarda nuestros datos.

```js
var Container = function(x) {
  this.__value = x;
}

Container.of = function(x) { return new Container(x); };
```

Aquí está nuestro primer contenedor. Lo hemos llamado, inteligentemente, `Container` (Contenedor). Usáremos `Container.of` como un constructor que nos ahora el trabajo de tener que escribir la terrible palabra `new` en nuestro código. Hay algo que esconde la palabra `of` que no es evidente, pero por ahora, pensemos como la manera correcta de guardar nuestros datos en el contenedor. 

Entonces, revisemos nuestro baúl 

```js
Container.of(3)
//=> Container(3)


Container.of("hotdogs")
//=> Container("hotdogs")


Container.of(Container.of({name: "yoda"}))
//=> Container(Container({name: "yoda" }))
```

Si estamos usando `node` as ejecutar este código se vería `{__value: x}` aunque nosotros construimos un `Container(x)`. Chrome nos dará en consola la propiedad del tipo; sin embargo, esto no importa, siempre y cuando entendamos cómo se ve el `Container`. En algunos ambientes uno puede sobre escribir la propiedad `inspect` si se quiere, pero no seremos tan metódicos. Para el alcance de este libro, escribiremos el output conceptual como si hubiéramos sobre escrito la propiedad `inspect`, esto es mucho más descriptivo que el valor `{__value:x}`, lo anterior también aplica por simples razones estéticas. 


Continuemos aclarando temas antes de continuar:

* `Container` es un objeto con una propiedad. Muchos contenedores solo contienen una cosa, claro, no están limitados a una. Hemos llamado esta propiedad arbitrariamente `__value`

* La propiedad `__value` no puede ser de un tipo específico de lo contrario nuestro `Container` no sería un container. 


* Una vez datos entran en nuestro `Container` se mantiene ahí. Nosotros *podríamos* sacarlo usando `__value`, pero eso anularía el ejercicio.

Las razones por las cuales estamos haciendo esto, serán más claras en el transcurso del capítulo, por el momento han de creerme.

## Mi primer Functor

Dado que hemos guardado nuestro dato en nuestro contenedor, tenemos que tener una manera de ejecutar funciones sobre él.

```js
// (a -> b) -> Container a -> Container b
Container.prototype.map = function(f){
  return Container.of(f(this.__value))
}
```

Si ven, es tal cual la famosa función de Array `map`, excepto que tenemos un `Container a` y no un `[a]`. Esto funciona esencialmente de la misma manera:

```js
Container.of(2).map(function(two){ return two + 2 })
//=> Container(4)


Container.of("flamethrowers").map(function(s){ return s.toUpperCase() })
//=> Container("FLAMETHROWERS")


Container.of("bombs").map(_.concat(' away')).map(_.prop('length'))
//=> Container(10)
```

Nosotros podemos trabajar con el valor sin nunca sacarlo de nuestro `Container`. Esto es algo increíble. Nuestro valor en el `Container` es entregado a la función `map` para que podamos trabajarlo y luego retornado a su `Container` para guardarlo de manera segura. Como resultado de nunca salir de `Container`, podríamos continuar usando `map`, pasando funciones a nuestro antojo. Podríamos inclusive cambiar el tipo como se demostró en el último ejemplo de los tres últimos. 


Momento, si seguimos llamando la función `map`, pareciera que creamos una especie de composición! ¿Qué tipo de magia matemática está ocurriendo? Bueno hemos descubierto los *Functores*.


> Un Functor es un tipo que implementa la función `map` y obedece ciertas reglas

Si, *Functor* es simplemente una interface con un contrato. Inclusive, podríamos haberlo llamado *Mappable*, pero no sería tan sofisticado como llamarlo *Functor*. Los Functores viene de la teoría de categoría y revisaremos con detalle las matemáticas hacia el final del capítulo, por ahora, trabajaremos con la intuición y las aplicaciones prácticas para esta extraña interface

¿Cuál podría ser la razón para guardar todo en un `Container` y luego usar `map` para llegar a él? Pues la respuesta se revela sola si hacemos otra pregunta: ¿Qué ganamos en delegar al `Container` que llame funciones por nosotros? Bueno, esto es una abstracción de llamado de funciones. Cuando aplicamos `map` a una función, le pedimos al container que llame la función por nosotros. Este es un concepto muy poderoso.

## El talvez de Schrödinger

<img src="images/cat.png" alt="cool cat, need reference" />

Los `Container`s son un concepto aburrido. De hecho, se le suelen llamar `Identidad` y tienen el mismo impacto como nuestras funciones `id`[^de nuevo, acá hay un link matemático que veremos cuándo el tiempo sea el indicado]. Sin embargo, hay otros Functores de forma de contenedores que implementan una función `map`, que provee comportamientos específicos mientras se `map`ean. Defínanos entonces:  

```js
var Maybe = function(x) {
  this.__value = x;
}

Maybe.of = function(x) {
  return new Maybe(x);
}

Maybe.prototype.isNothing = function() {
  return (this.__value === null || this.__value === undefined);
}

Maybe.prototype.map = function(f) {
  return this.isNothing() ? Maybe.of(null) : Maybe.of(f(this.__value));
}
```

Ahora, `maybe` sé mucho como un `Container` con un cambio menor: primero revisa si hay un valor antes de llamar la función que se le entrega. Esto tiene el efecto de omitir esos fastidiosos nulls mientras `map`eamos los datos[^Nota: esta implementación es mínima y es solo de fines pedagógicos]

```js
Maybe.of("Malkovich Malkovich").map(match(/a/ig));
//=> Maybe(['a', 'a'])

Maybe.of(null).map(match(/a/ig));
//=> Maybe(null)

Maybe.of({name: "Boris"}).map(_.prop("age")).map(add(10));
//=> Maybe(null)

Maybe.of({name: "Dinah", age: 14}).map(_.prop("age")).map(add(10));
//=> Maybe(24)

```
Es de notar que nuestra app no explota de errores mientras `map`eamos funciones sobre nuestros valores nulos. Estos es porque `Maybe` se encargará de revisar que el valor exista cada vez que se le aplica la función.


La notación de punto (dot sintaxis) esta bien y funcional, pero por razones antes mencionadas en la primera parte, nos gustaría mantener nuestro estilo `pointfree`, o libre de variables tácitas. Afortunadamente, `map` está completamente equipada para delegar cualquier Functor que recibe:

```js
//  map :: Functor f => (a -> b) -> f a -> f b
var map = curry(function(f, any_functor_at_all) {
  return any_functor_at_all.map(f);
});
```

Esto es perfecto, ya que podemos continuar con la composición como habíamos descrito anteriormente usando `map`. Este es el caso también con el `map` de ramda.js. Usaremos la notación de punto (dot notation) cuando es instructiva y la versión `pointfree` cuando sea conveniente. ¿Notaron cómo agregué algo nuevo a la firma de la función? `Functor f =>` nos dice que `f` debe ser un Functor. No era algo extraordinario, pero creí conveniente decirlo.  

## Casos de uso

En la vida real, típicamente vemos `Maybe` usado en funciones que puedan fallar al retornamos un resultado.

```js
//  safeHead :: [a] -> Maybe(a)
var safeHead = function(xs) {
  return Maybe.of(xs[0]);
};

var streetName = compose(map(_.prop('street')), safeHead, _.prop('addresses'));

streetName({addresses: []});
// Maybe(null)

streetName({addresses: [{street: "Shady Ln.", number: 4201}]});
// Maybe("Shady Ln.")
```

`safeHead` es como nuestro normal `_.head`, pero con `type safety` ó seguridad de tipos. Una cosa curiosa pasa cuando `Maybe` es introducido en nuestro código; somos forzados a manejar esos estados obscuros que retornan `null`. La función `safeHead` es honesta y de manera directa nos dice sus posibilidades de falla, por lo cual nos entrega un `Maybe` para informarnos de esto. También, estamos más que solo informados, porque estamos forzados a `map`ear para llegar al valor y dejarlo guardado dentro del objeto `Maybe`. Esencialmente, este es un `null` revisado por la función `safeHead`. Ahora, podemos dormir más tranquilos sabiendo que un `null` no aparecerá donde menos lo esperamos. APIs que utilicen este concepto garantizarán un software más seguro. 

Algunas veces una función puede retornar un `Maybe(null)` explícito para señalar una falla. Por ejemplo:

```js
//  withdraw :: Number -> Account -> Maybe(Account)
var withdraw = curry(function(amount, account) {
  return account.balance >= amount ?
    Maybe.of({balance: account.balance - amount}) :  
     Maybe.of(null);
});

//  finishTransaction :: Account -> String
var finishTransaction = compose(remainingBalance, updateLedger);  // <- these composed functions are hypothetical, not implemented here...

//  getTwenty :: Account -> Maybe(String)
var getTwenty = compose(map(finishTransaction), withdraw(20));



getTwenty({ balance: 200.00});
// Maybe("Your balance is $180.00")

getTwenty({ balance: 10.00});
// Maybe(null)
```

`withdraw` nos dejará saber cuándo estamos cortos de dinero cun un `Maybe(null)`. Esta función también nos comunica su talón de Aquiles y no nos deja otra opción sino `map`ear todo lo que sigue. La diferencia es que el `null` era intencional acá. Envés de `Maybe(String)`, tenemos el `Maybe(null)` de regreso para señalar la falla en nuestra aplicación y efectivamente parar la ejecución. Es también importante denotar que: si la función `withdraw` falla, entonces `map` cortará con el resto de la computación dado que no ejecutará las funciones mapeadas, como `finishTransaction`. Esto es precisamente el comportamiento esperado ya que preferimos no actualizar nuestro libro de transacciones o mostrar un balance si no ha sido exitoso el retiro de dinero. 

## Soltando el valor

Una cosa que normalmente perdemos de visa, es que siempre hay un alto en el camino o un cambio observable; algo como una función que envían un JSON, ó que imprime algo en la pantalla, o que altera algún archivo en el sistema. No podemos retornar solamente `return`, debemos retornar algo al mundo. Podemos tomar prestada el koan del Budismo Zen: "Si un program que no tiene efectos observables se ejecuta, ¿Cómo sabemos que se ejecuta?" 


Nuestra aplicación tiene como trabajo recibir, transforma y llevar esa información a alguna parte. En nuestro contexto, debemos poder "sacar" nuestro valor de su contenedor. En efecto, un error común es tratar de sacar los valores de nuestro `Maybe` de una manera o de otra, para volver nuestro programa deterministico y obtener un resultado. Sin embargo, tenemos que entender que nuestro código, tal cual como el gato de Schrödinger, estará en dos estados y solo se determinará cuando se ejecute la última función y así tenga un flow lineal. 

Hay, sin embargo, un `escape hatch` o escotilla de escape. Podemos utilizar una función de ayuda llamada `maybe`.

```js
//  maybe :: b -> (a -> b) -> Maybe a -> b
var maybe = curry(function(x, f, m) {
  return m.isNothing() ? x : f(m.__value);
});

//  getTwenty :: Account -> String
var getTwenty = compose(
  maybe("You're broke!", finishTransaction), withdraw(20)
);


getTwenty({ balance: 200.00});
// "Your balance is $180.00"

getTwenty({ balance: 10.00});
// "You're broke!"
```

Ahora sabremos si retorna un valor estático (del tipo `finisheTransaction`) ó sí continua tratando de hacer la transacción sin el `Maybe`. Con `maybe`, estamos ante el equivalente de un flow lógico `if/else` junto con la función `map`, el análogo imperativo sería `if( x!== null){ return f(x) }`.


La introducción de `Maybe` puede causar incomodidad al inicio. Usuarios de Swift y Scala sabrán a lo que nos referimos, ya que hace parte intrínseca disfrazada de un `Option(al)`. Nos forzan a hacer revision de `null` todo el tiempo (mismo si estamos 100% seguros de que el valor existe), muchos ven está labor como innecesaria. Sin embargo, con el tiempo, se vuelve algo de segunda naturaleza y comenzaremos a apreciar el respaldo que este proceso nos da, ya que no nos permite tomar atajos con el manejo de nuestros datos.


Escribir software inseguro no nos dará tranquilidad a largo plazo, es como no construir una casa que proteja de todos los elementos. Necesitamos darle una fundación segura a nuestras funciones y `Maybe` hace justamente esto.

Finalmente, es necesario explicar que la implementación "real" de `Maybe` se hace de dos maneras: una para algo y otra para nada. Esto nos permite continuar con la parametricidad en `mao` para que valores como `null` y `undefined` puedan ser `map`eados y la cualificación universal de un valor en un functor sea respetada. En general se verán tipo cómo `Some(x) / None` ó `Just(x) / Nothing` envés de `Maybe` que hace el `null` check en su valor.

## Manejo funcional de errores

<img src="images/fists.jpg" alt="pick a hand... need a reference" />

Puede llegarles de sorpresa pero `throw/catch` no es una función pura. Cuando un error llega, envés de retornar un output de salida, sonarán muchísimas alarmas. La función se torna agresiva, escupiendo miles de ceros y unos como dardos y dagas en una batalla eléctrica en contra de input erróneo. Ahora con nuestro gran amigo `Either`, podemos tratar este caso mucho mejor y no declarar una guerra frontal contra nuestro input, podríamos, mejor, responder con un mensaje respetuoso. Analicemos el caso:

```js
var Left = function(x) {
  this.__value = x;
}

Left.of = function(x) {
  return new Left(x);
}

Left.prototype.map = function(f) {
  return this;
}

var Right = function(x) {
  this.__value = x;
}

Right.of = function(x) {
  return new Right(x);
}

Right.prototype.map = function(f) {
  return Right.of(f(this.__value));
}
```

`Left` y `Right` son dos subclases de una abstracción que llamaremos `Either`. Me salté la ceremonia de crear la super clase `Either` ya que no la usaremos, sin embargo, es importante estar conscientes de qué existe. Ahora, no hay nada nuevo aparte de que hay dos tipos. Revisemos como interactúan: 

```js
Right.of("rain").map(function(str){ return "b"+str; });
// Right("brain")

Left.of("rain").map(function(str){ return "b"+str; });
// Left("rain")

Right.of({host: 'localhost', port: 80}).map(_.prop('host'));
// Right('localhost')

Left.of("rolls eyes...").map(_.prop("host"));
// Left('rolls eyes...')
```

`Left` es una función que solo ignora nuestra petición para `map`ear sobre ella misma. `Right` funciona tal cual un `Container` (a.k.a Identidad). El poder viene de la habilidad de para poner un mensaje de error en `Left`.


Supongamos que hay una función que falle. Por ejemplo calculando la edad de un fecha de cumpleaños. Podríamos usar `Maybe(null)` para avisar la falla y salir de la rama de nuestro programa, sin embargo, eso no nos dice mucho. De pronto, nos gustaría avisar por qué falló. Hagámoslo usando `Either`.

```js
var moment = require('moment');

//  getAge :: Date -> User -> Either(String, Number)
var getAge = curry(function(now, user) {
  var birthdate = moment(user.birthdate, 'YYYY-MM-DD');
  if (!birthdate.isValid()) return Left.of("Birth date could not be parsed");
  return Right.of(now.diff(birthdate, 'years'));
});

getAge(moment(), {birthdate: '2005-12-12'});
// Right(9)

getAge(moment(), {birthdate: '20010704'});
// Left("Birth date could not be parsed")
```


Ahora, al igual que `Maybe(null)`, estamos haciendo un corto circuito a nuestra función cuando retornamos `Left`. La diferencia ahora, es que tenemos idea respecto a lo que está fallando en nuestro programa. Algo para notar es que cuando retornamos `Either(String, Number)`, el cual contiene un `String` a su izquierda y un `Number` a su derecha (`Right`). Está firma de la función es por el momento algo informal ya que no tenemos una definición exacta la super clase de `Either`, sin embargo, hemos aprendido bastante de su tipo. Nos informa si tenemos un error ó si tenemos la edad calculada. 

```js
//  fortune :: Number -> String
var fortune  = compose(concat("If you survive, you will be "), add(1));

//  zoltar :: User -> Either(String, _)
var zoltar = compose(map(console.log), map(fortune), getAge(moment()));

zoltar({birthdate: '2005-12-12'});
// "If you survive, you will be 10"
// Right(undefined)

zoltar({birthdate: 'balloons!'});
// Left("Birth date could not be parsed")
```

Cuando el `birthdate` es válido, el programa retorna un output místico a la consola para que nosotros leamos. De otra manera, nos entrega `Left` con el mensaje de error de manera explícita dentro de un contenedor. Esto es similar a a si el programa nos entregara un mensaje de error rojo en consola, sin embargo, este error nos es entregado de una manera tranquila y no actuando como un niño pequeño al cual no se le da comida. 


En este ejemplo, estamos haciendo ramas lógicas de nuestro flow de control dependiendo de la validez de la fecha de cumpleaños, y se lee de manera concisa de derecha a izquierda y no leyendo infinitos `if` y `else` tratando de encontrar donde está el error. Normalmente, moveríamos el `console.log` fuera de la función `zoltar` y `map`erala en el momento de la llamada, pero es útil ver como la rama de `Right` diverge. Para esto usamos `_` en la firma de la rama derecha para indicar que es un valor que debemos ignorar[^En algunos browsers uno debe usar `console.log(bind(console))` para que sea una función de primera clase].


Nos gustaría tomar esta oportunidad en este punto para mostrar algo que no fue evidente: `fortune`, apesar de su uso con `Either` en este ejemplo, es completamente ignorante de cualquier functor que se le entregue. Este es también el caso para `finishTransaction` en el ejemplo anterior. En el momento de la llamada, la función puede estar rodeada por `map`, lo que transforma una función que no es un functor en un functor, en términos informales. Llamamos este proceso *levantamiento*. Las funciones tienden a ser mejores trabajando con tipos de datos y no con `Containers`, lo que nos permite levantarlas en el contenedor apropiado. Esto nos lleva a funciones más simples que pueden ser alteradas para trabajar con cualquier Functor.

`Either` es perfecta para errores casuales como validaciones y también para casos más estrictos de detener errores como archivos faltantes o sockets rotos. Se le recomienda al lector remplazar de los ejemplos el `Maybe` con `Either` para tener un mejor entendimiento.

Ahora, no puedo dejar de pensar que le he hecho a `Either` una mala introducción, al presentarlo como un contenedor único para manejo de errores. `Either` captura la separación lógica (||) en un tipo. También enclaustra la idea del *Coproducto* de la teoría de categorías, la cuando se hablará en este libro, pero vale la pena leer fuera de este libro, ya que contiene varias propiedades que podemos utilizar. `Either`, es un suma canónica de tipos, ya que tiene en cuenta todos los posibles habitantes de la suma de dos tipos contenidos[^sé que esto suena a magia por lo que acá les entrego un gran [artículo](https://www.fpcomplete.com/school/to-infinity-and-beyond/pick-of-the-week/sum-types)]. Hay muchas cosas que `Either` puede ser, pero como un functor, normalmente se usa en manejo de errores.

Tal como `Maybe`, para `Either` también existe `either`, el cual funciona de manera similar pero toma dos funciones envés de un valor estático. Cada función debería retornar el mismo tipo.

```js
//  either :: (a -> c) -> (b -> c) -> Either a b -> c
var either = curry(function(f, g, e) {
  switch(e.constructor) {
    case Left: return f(e.__value);
    case Right: return g(e.__value);
  }
});

//  zoltar :: User -> _
var zoltar = compose(console.log, either(id, fortune), getAge(moment()));

zoltar({birthdate: '2005-12-12'});
// "If you survive, you will be 10"
// undefined

zoltar({birthdate: 'balloons!'});
// "Birth date could not be parsed"
// undefined
```
Finalmente, un uso para la misteriosa función `id`. Simplemente devuelve el valor de la rama `Left` para pasar el mensaje de error a `console.log`. Hicimos de la app `Fortune Telling` más robusta enforzando el manejo de error desde los internos de la función `getAge`. Entonces ó entregamos al usuario la verdad de que no puede continuar el proceso ó continuar con el proceso de manera elegante. Con esto, podemos pasar a otro tipo de functor. 

## El viejo McDonald tenía efectos secundarios..

<img src="images/dominoes.jpg" alt="dominoes.. need a reference" />

En nuestro capítulo de de funciones puras encontramos un caso particular de función pura. Esta función tenía efectos secundarios, pero omitimos esto cuando la envolvimos en otra función. Aquí está el ejemplo:

```js
//  getFromStorage :: String -> (_ -> String)
var getFromStorage = function(key) {
  return function() {
    return localStorage[key];
  }
}
```

Si no hubiéramos envuelto la función en otra función, `getFromStorage` hubiera variado su valor retornado dependiendo de las circunstancias exógenas. Con una función que la envuelve siempre tendremos los mismos resultados de regreso con los mismos valores de entrada, de tal manera que siempre retorna el item de `localStorage`. Y así como sino nada (deporto agregando una bendición) hemos limpiado nuestra conciencia y todo está perdonado.


Excepto, esto no es particularmente útil. Como un item de `Container`, no nos sirve en su contenedor original y no podemos jugar con el valor. ¿Si tan solo hubiera una manera de llegar a las entrañas del `Container` para tomar sus datos? ....... Aquí cuando presentamos `IO`

```js
var IO = function(f) {
  this.__value = f;
}

IO.of = function(x) {
  return new IO(function() {
    return x;
  });
}

IO.prototype.map = function(f) {
  return new IO(_.compose(f, this.__value));
}
```

`IO` se diferencia de los anteriores functores in que el valor de `_value` es siempre una función. No pensemos en `_value` como una función, esto es un detalle de implementación y es mejor que lo ignoremos. Lo que está sucediendo exactamente es lo que vimos con la función `getFromStorage`: `IO` retrasa la función impura a través de una función envolvente. Y como tal, pensemos en `IO` como un contenedor que retorna el valor de la función envolvente y no el `Contariner` per se. Esto es más explícito en el método `of`: Tenemos `IO(x)`, la implementación `IO(function(){ return x })` es solo para retrasar la evaluación de la función. 

Mirémosla en uso:

```js
//  io_window_ :: IO Window
var io_window = new IO(function(){ return window; });

io_window.map(function(win){ return win.innerWidth });
// IO(1430)

io_window.map(_.prop('location')).map(_.prop('href')).map(split('/'));
// IO(["http:", "", "localhost:8000", "blog", "posts"])


//  $ :: String -> IO [DOM]
var $ = function(selector) {
  return new IO(function(){ return document.querySelectorAll(selector); });
}

$('#myDiv').map(head).map(function(div){ return div.innerHTML; });
// IO('I am some inner html')
```
Aquí, `io_window` es realmente `IO` que podemos `map`ear directamente, mientras que `$` es una función que retorna un `IO` después de que ha sido llamado. Hemos escrito el `return` *conceptual* que mejor representan lo que obtenemos, salvo que en realidad, siempre será `{__value: [Functor] }`. Cuando `map`eamos sobre nuestro `IO`, ponemos está función al final de nuestra composición, la cual en contraposición se convierte en `__value` y así sucesivamente. Nuestra función `map`eada no se ejecuta, queda al final de `stack` de la computación que estamos creando, función por función, tal como cuando colocamos dominos cuidadosamente y solo tildamos el último cuando todos están puestos.

Tomemos un momento para trabajar en nuestra intuición de los functores. Si pasamos los detalles de implementación, deberíamos sentirnos como en casa `map`eado sobre cualquier contenedor, sin importar sus detalles o idiosincracias. Tenemos las leyes de Functores, los cuales revisaremos en detalle al final de este capítulo, para agradecer por dejarnos trabajar con valores inpuros sin sacrificar nuestra referencia transparencial.

Ahora, que hemos contenido la bestia (los efectos secundarios), igual tenemos que sacarlos en algún punto. Mapeando sobre nuestros `IO` a creado una computación impura and ejecutarla realmente va a crear un desastre. Entonces, ¿Cuando podemos ejecutar el gatillo con una función impura? ¿Podemos realmente ejecutar una función `IO` y casarnos de blanco en nuestra boda? Bueno la función es si, si llegas a casarte. La respuesta es sí, ya que nuestra computación mantiene su inocencia y es el que ejecuta la función que tiene que llevar la responsabilidad de los efectos secundarios. Revisemos este ejemplo de una manera más concreta:

```js

////// Our pure library: lib/params.js ///////

//  url :: IO String
var url = new IO(function() { return window.location.href; });

//  toPairs =  String -> [[String]]
var toPairs = compose(map(split('=')), split('&'));

//  params :: String -> [[String]]
var params = compose(toPairs, last, split('?'));

//  findParam :: String -> IO Maybe [String]
var findParam = function(key) {
  return map(compose(Maybe.of, filter(compose(eq(key), head)), params), url);
};

////// Impure calling code: main.js ///////

// run it by calling __value()!
findParam("searchTerm").__value();
// Maybe(['searchTerm', 'wafflehouse'])
```

Nuestra librería mantiene sus manos limpias al envolver el `url` en una `IO` y pasando la responsabilidad a que llame la función. También se habrán dado cuenta de hemos apilado todas nuestros `Containers` lo cual lo hace más fácil de razonar, es totalmente permitido tener un `IO(Maybe([x]))`, que tiene tres Functores de profundidad[^Array es claramente un container que se puede `map`ear] y todo se vuelve mucho más expresivo.

Hay algo que me ha molestado y debería rectificar inmediatamente: el `__value` de `IO` no es realmente un valor contenido, tampoco es privado. Es básicamente el pin de la granada y esa responsabilidad se le delega a quien llama la función. De tal manera que entonces llamemos la propiedad `unsafePerformIO` para recordar a los usuarios de su volatilidad.

```js
var IO = function(f) {
  this.unsafePerformIO = f;
}

IO.prototype.map = function(f) {
  return new IO(_.compose(f, this.unsafePerformIO));
}
```
Eso, ahora es mucho mejor, y en nuestro código encontramos líneas como `findParam("searchTerm").unsafePerformIO()`, lo cual es claro para nuestros usuarios y también lectores sobre lo que hace nuestra aplicación. 

`IO` será un acompañante fiel, ayudándonos a domar esas funciones impuras con efectos secundarios. Ahora, miremos un Functor con espíritu similar pero muy diferente en su uso.

## Tareas asíncronas 

Callbacks son en definición, son los escalones de las escaleras que nos llevan al infierno. Son un patrón de diseño creado por M.C. Escher, con cada callback construimos una escalera adicional que nos da claustrofobia. Sin embargo, hay mejor manera de trabajar con el código asíncrono en JavaScript, y comienza con la letra "F".

Los detalles de implementación son un poco complicados para ponerlos en este capítulo, de tal razón que usaremos `Data.Task` (conocido previamienta como `Data.Future`) de la estoria de Folk de [Quildrenn Motta](http://folktalejs.org/). Miremos su uso:

```js
// Node readfile example:
//=======================

var fs = require('fs');

//  readFile :: String -> Task Error String
var readFile = function(filename) {
  return new Task(function(reject, result) {
    fs.readFile(filename, 'utf-8', function(err, data) {
      err ? reject(err) : result(data);
    });
  });
};

readFile("metamorphosis").map(split('\n')).map(head);
// Task("One morning, as Gregor Samsa was waking up from anxious dreams, he discovered that
// in bed he had been changed into a monstrous verminous bug.")


// jQuery getJSON example:
//========================

//  getJSON :: String -> {} -> Task Error JSON
var getJSON = curry(function(url, params) {
  return new Task(function(reject, result) {
    $.getJSON(url, params, result).fail(reject);
  });
});

getJSON('/video', {id: 10}).map(_.prop('title'));
// Task("Family Matters ep 15")

// We can put normal, non futuristic values inside as well
Task.of(3).map(function(three){ return three + 1 });
// Task(4)
```

Las funciones que estoy llamando `reject` y `result` son nuestros callbacks de error o éxito, respectivamente. Como se puede ver, simplemente `map`eamos sobre `Task` para trabajar nuestro valor futuro como si estuviera ahí para nosotros.

Si están familiarizados con promesas, a este punto reconocerán que la función `map` hace las veces de `then` con `Task` jugando el papel de nuestra promesa. No se preocupen si no las conocen sin embargo, ya que no las estaremos usando, y tampoco son funciones puras, pero la analogía se mantiene.

Como `IO`, `Task` esperará pacientemente a que le demos la luz verde antes de ejecutarse. De hecho, porque espera a nuestro comando, `IO` es efectivamente entregado a `Task` para todas las cosas asíncronas; `readFile` y `getJSON` no requieren un container `IO` de más para ser puro. Aún meas, `Task` trabaja de manera similar a cuando `map`eamos sobre ella: estamos colocando instrucciones para el futuro. Esto puede ser un acto sofisticado de tecnología en procastinación. 

Para correr `Task`, tenemos que llamar el métedo `fork`. Esto funciona como `unsafePerformIO`, pero como su nombre suguiere, hará un fork (ramificación) de nuestro proceso sin bloquear nuestro `thread`. Esto puede ser implementado en formas numerosas con `threads`, miremos como podemos hacer esto con `fork`:

```js
// Pure application
//=====================
// blogTemplate :: String

//  blogPage :: Posts -> HTML
var blogPage = Handlebars.compile(blogTemplate);

//  renderPage :: Posts -> HTML
var renderPage = compose(blogPage, sortBy('date'));

//  blog :: Params -> Task Error HTML
var blog = compose(map(renderPage), getJSON('/posts'));


// Impure calling code
//=====================
blog({}).fork(
  function(error){ $("#error").html(error.message); },
  function(page){ $("#main").html(page); }
);

$('#spinner').show();
```

Al llamar `fork`, `Task` se apresura en buscar algunos posts y renderizarlos en la página. Mientras tanto, vamos a mostrar el spinner, ya que `fork` no espera por la respuesta. Finalmente, mostraremos sea el mensaje de error o renderizar en la página lo que nuestro `getJSON` muestre, sea exitoso o no. 

Tomemos un momento para considerar qué tan linear es nuestro `control flow` (o linea de control). Solo leamos de abajo para arriba, de izquierda a derecha sin importar que nuestro programa haga algunos saltos adicionales en el momento de ejecución. Esto hace que leer y razonar nuestro código sea más sencillo que antes, sin tener que ejecutar los callbacks en nuestra cabeza tratando de seguir la línea de ejecución.

Adicional a eso, `Task` también sé a tragado un `Either`, lo tiene que hacer para manejar valores futuros ya que nuestro control flow normal no aplica en mundo asíncronos. Esto es perfecto, ya que hace manejo de errores por defecto.

Ahora, no es de creer que con `Task`, `IO` e `Either` no vamos a necesitar más Functores. Tratemos de seguir este ejemplo que es más hipotético, sin embargo no deja de ser ilustrativo: 

```js
// Postgres.connect :: Url -> IO DbConnection
// runQuery :: DbConnection -> ResultSet
// readFile :: String -> Task Error String

// Pure application
//=====================

//  dbUrl :: Config -> Either Error Url
var dbUrl = function(c) {
  return (c.uname && c.pass && c.host && c.db)
    ? Right.of("db:pg://"+c.uname+":"+c.pass+"@"+c.host+"5432/"+c.db)
    : Left.of(Error("Invalid config!"));
}

//  connectDb :: Config -> Either Error (IO DbConnection)
var connectDb = compose(map(Postgres.connect), dbUrl);

//  getConfig :: Filename -> Task Error (Either Error (IO DbConnection))
var getConfig = compose(map(compose(connectDb, JSON.parse)), readFile);


// Impure calling code
//=====================
getConfig("db.json").fork(
  logErr("couldn't read file"), either(console.log, map(runQuery))
);
```

En este ejemplo, todavía estamos usando `Either` con `IO` desde la ramificación de éxito de `readFile`. `Task` es responsable de las los efectos secundarios de leer un archivo asíncrono, pero tenemos que lidiar con las validaciones de configuración con `Either` y conexiones de db con `IO`. Así que, todavía tenemos trabajo para nuestros Functores para todas las cosas asíncronas.

Podría seguir explicando, pero no hay nada más que eso, es tan simple como un `map`.

En práctica, es muy probable tener múltiples llamados asíncronos en un workflow y tampoco tenemos containers para todas las APIs para manejar correctamente este escenario. Sin embargo, no debemos preocuparnos, miraremos las mónadas muy pronto, pero por el momento, examinemos las matemáticas que hacen esto posible.


## Un destello de la teoría

Como mencionamos antes, functores viene de la teoría de categorías y satisfacen ciertas reglas. Primero exploremos algunas propiedades que son útiles.

```js
// identity
map(id) === id;

// composition
compose(map(f), map(g)) === map(compose(f, g));
```

La regla de la *identidad* es simple, pero importante. Estás reglas son simples pedazos de código que podemos correr en nuestros functores y validar su legitimidad. 

```js
var idLaw1 = map(id);
var idLaw2 = id;

idLaw1(Container.of(2));
//=> Container(2)

idLaw2(Container.of(2));
//=> Container(2)
```

Como se puede puede ver, son iguales. Ahora miremos la composición.

```js
var compLaw1 = compose(map(concat(" world")), map(concat(" cruel")));
var compLaw2 = map(compose(concat(" world"), concat(" cruel")));

compLaw1(Container.of("Goodbye"));
//=> Container('Goodbye cruel world')

compLaw2(Container.of("Goodbye"));
//=> Container('Goodbye cruel world')
```

En la teoría de categoría, functores toman objetos y morfirmos de una cateoría y la mapean (ó la transladan a otra categoría). Por definición, esta nueva categoría tiene que tener una identidad y la habilidad de componer morfismos, pero no tenemos que comprobarlo porque las reglas antes mencionadas aseguran que esto ocurre. 

Depronto nuestra definición de categoría todavía no es clara. Se puede pensar en una categoría como una red de objetos con morfirmos que los conectan. De tal manera que un Functor mapeariea de una categoriea a la otra sin romper esta red. Si un objeto `a` está en nuestra categoría de orígen `C`, cuando mapeamos esta categorêa `D` con un functor `F`, nos referimos a ese objeto `F a`. Depronto es mejor si lo pensamos como un diagrama:

<img src="images/catmap.png" alt="Categories mapped" />

Por ejemplo, `Maybe` mapea nuestra categoría de tipos y funciones a otra categoría en donde cada objeto pueda no existir y cada morfismo tiene un `null` check. Logramos esto en el código al envolver cada función con `map` y cada tipo con un Functor. Sabemos que cada uno de nuestros tipos normales y Functores podrán ser compuestos en nuestro nuevo mundo. Técnicamente hablando, cada Functor, en nuestro código `map`ea a una sub categoría de tipos y funciones, lo cual hace que todos los functores, endofunctores, pero para nuestros propósitos los pensaremos como otra categoría.

Podemos visualizar el `map`eo de morfirmos y sus correspondientes objetos en este diagrama: 

<img src="images/functormap.png" alt="functor diagram" />

En adición a visualizar los morfirmos `map`eados de una categoría a otra con el functor `F`, podemos ver que el diagrama conmuta, queriendo decir que, si uno sigue sus flechas cada ruta produce el mismo tipo. Cada ruta significa un comportamiento deferente, pero al final llegan al mismo tipo. Este formalismo nos da un principio para razonar nuestro código, podemos aplicar formulas sin interpretar cada posibilidad. Miremos esto con un ejemplo:

```js
//  topRoute :: String -> Maybe String
var topRoute = compose(Maybe.of, reverse);

//  bottomRoute :: String -> Maybe String
var bottomRoute = compose(map(reverse), Maybe.of);


topRoute("hi");
// Maybe("ih")

bottomRoute("hi");
// Maybe("ih")
```

Or visually:

<img src="images/functormapmaybe.png" alt="functor diagram 2" />

Podemos, instantaneamente ver y refactorizar código basado en propiedades de cada functor. 

Los Functores también se puede agrupar uno sobre el otro:

```js
var nested = Task.of([Right.of("pillows"), Left.of("no sleep for you")]);

map(map(map(toUpperCase)), nested);
// Task([Right("PILLOWS"), Left("no sleep for you")])
```

Lo que tenemos acá con `nested` es un array furturo de elemento que pueden ser errores. Entonces `map`eamos para quitar cada capa y ejecutar nuestra función en los elementos. No vemos ningún callback, if/else o loops; solo contenido explícito. Si tenemos, sin embargo, que `map(map(map(f)))`. Para esto podemos componer functores (Inreíble!)

```js
var Compose = function(f_g_x){
  this.getCompose = f_g_x;
}

Compose.prototype.map = function(f){
  return new Compose(map(map(f), this.getCompose));
}

var tmd = Task.of(Maybe.of("Rock over London"))

var ctmd = new Compose(tmd);

map(concat(", rock on, Chicago"), ctmd);
// Compose(Task(Maybe("Rock over London, rock on, Chicago")))

ctmd.getCompose;
// Task(Maybe("Rock over London, rock on, Chicago"))
```

Aquí, un sólo `map`. Composición de functores es una regla asociativa y anteriormente, definimos `Container`, que realmente se llama Functor `Identidad`. Si tenemos identidad y composición tenemos una categoría. Esta categoría en particular tiene categorías como objetos y functores como morfirmos, lo que es suficiente para hacer que nuestro cerebro explote. Por el momento no vamos a indagar más en esto, pero es bueno apreciar las implicaciones arquitectónicas, o sólo simples abstracciones en el patrón.


## En Conclusión. 

Hemos visto diferentes functores, but hay una infinidad de ellos. Algunas omisiones notables son estructuras de datos iterables como árboles, listas, mapas, pares y bueno muchas más. `eventStrems` y `observables` son también functores. Otros pueden ser encapsulaciones o sólo para modelar tipos. Los Functores son omnipresentes y se usan de manera extensiva en este libro. 

¿Cómo sería llamar una funcion con multiples functores como argumentos? ¿Qué tal trabajar con una secuencia ordenada de funciones impuras o acciones asíncronas? Todavía no tenemos todas las herramientas para trabajar. En el siguiente capítulo vamos a trabajar con monadas.

[Chapter 9: Monadic Onions](ch9.md)

## Exercises

```js
require('../../support');
var Task = require('data.task');
var _ = require('ramda');

// Exercise 1
// ==========
// Use _.add(x,y) and _.map(f,x) to make a function that increments a value
// inside a functor

var ex1 = undefined



//Exercise 2
// ==========
// Use _.head to get the first element of the list
var xs = Identity.of(['do', 'ray', 'me', 'fa', 'so', 'la', 'ti', 'do']);

var ex2 = undefined



// Exercise 3
// ==========
// Use safeProp and _.head to find the first initial of the user
var safeProp = _.curry(function (x, o) { return Maybe.of(o[x]); });

var user = { id: 2, name: "Albert" };

var ex3 = undefined


// Exercise 4
// ==========
// Use Maybe to rewrite ex4 without an if statement

var ex4 = function (n) {
  if (n) { return parseInt(n); }
};

var ex4 = undefined



// Exercise 5
// ==========
// Write a function that will getPost then toUpperCase the post's title

// getPost :: Int -> Future({id: Int, title: String})
var getPost = function (i) {
  return new Task(function(rej, res) {
    setTimeout(function(){
      res({id: i, title: 'Love them futures'})  
    }, 300)
  });
}

var ex5 = undefined



// Exercise 6
// ==========
// Write a function that uses checkActive() and showWelcome() to grant access
// or return the error

var showWelcome = _.compose(_.add( "Welcome "), _.prop('name'))

var checkActive = function(user) {
 return user.active ? Right.of(user) : Left.of('Your account is not active')
}

var ex6 = undefined



// Exercise 7
// ==========
// Write a validation function that checks for a length > 3. It should return
// Right(x) if it is greater than 3 and Left("You need > 3") otherwise

var ex7 = function(x) {
  return undefined // <--- write me. (don't be pointfree)
}



// Exercise 8
// ==========
// Use ex7 above and Either as a functor to save the user if they are valid or
// return the error message string. Remember either's two arguments must return
// the same type.

var save = function(x){
  return new IO(function(){
    console.log("SAVED USER!");
    return x + '-saved';
  });
}

var ex8 = undefined
```