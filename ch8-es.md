# Tupperware

## El Contenedor Poderoso

![http://blog.dwinegar.com/2011/06/another-jar.html]
(images/jar.jpg)

Hemos visto cómo escribir programas que pasan datos a través de una serie de funciones puras. Estos programas son especificaciones declarativas de comportamiento. Pero, ¿qué pasa con el control de flujo, manejo de errores, acciones asíncronas, estado? y, me atrevería a decir, ¡¿efectos?! En este capítulo, descubriremos la base sobre la que todas éstas útiles abstracciones son construidas.

Primero crearemos un contenedor. Este contenedor debe contener cualquier tipo de valor; una bolsa ziplock que contiene solamente pudín de tapioca no suele ser útil. Será un objeto, pero no le daremos propiedades y métodos en el sentido de la programación orientada a objetos. No, lo trataremos como un cofre del tesoro - una caja especial que proteje nuestros datos valiosos.

```js
var Container = function(x) {
  this.__value = x;
}

Container.of = function(x) { return new Container(x); };
```

Aquí está nuestro primer contenedor. Sabiamente lo hemos nombrado `Container`. Usaremos `Container.of` como un constructor que nos ahorra tener que escribir esa fea palabra reservada `new` por todas partes. Hay más en la función `of` de lo que parece, pero por ahora, imagínatela como la forma correcta de colocar valores en nuestro contenedor.

Examinemos nuestra nueva caja...

```js
Container.of(3)
//=> Container(3)

Container.of("hotdogs")
//=> Container("hotdogs")

Container.of(Container.of({name: "yoda"}))
//=> Container(Container({name: "yoda"}))
```

Si estás usando node, verás `{__value: x}` a pesar de que tenemos un `Container(x)`. Chrome mostrará el tipo correctamente, pero no importa; siempre y cuando entendamos lo que es un `Container`, estaremos bien. En algunos entornos puedes sobreescribir el método `inspect` si lo deseas, pero no iremos tan lejos. Para este libro escribiremos la salida conceptual como si hubiéramos sobreescrito el método `inspect` ya que es mucho más instructivo que `{__value: x}` por razones tanto pedagógicas como estéticas.

Aclaremos algunas cosas antes de continuar:

* `Container` es un objeto con una propiedad. Un montón de contenedores solo contienen una cosa, aunque no se limitan a una. Hemos llamado arbitrariamente su propiedad `__value`.

* `__value` no puede ser de un tipo específico o sino nuestro `Container` no estaría a la altura de su nombre.

* Una vez que los datos entran en el `Container` se quedan allí. *Podríamos* sacarlos usando `.__value`, pero eso iría contra nuestro propósito.

Las razones por la que estamos haciendo esto quedarán tan claras como un frasco de conservas, pero por ahora, tengan paciencia.

## Mi Primer Functor

Una vez que nuestro valor, cualquiera que sea, esté en el contenedor, necesitaremos una forma de ejecutar funciones en el.

```js
// (a -> b) -> Container a -> Container b
Container.prototype.map = function(f){
  return Container.of(f(this.__value))
}
```

¿Por qué?, es como el famoso `map` de los Arrays, excepto que tenemos `Container a` en lugar de `[a]`. Y funciona esencialmente del mismo modo:

```js
Container.of(2).map(function(two){ return two + 2 })
//=> Container(4)

Container.of("flamethrowers").map(function(s){ return s.toUpperCase() })
//=> Container("FLAMETHROWERS")

Container.of("bombs").map(_.concat(' away')).map(_.prop('length'))
//=> Container(10)
```

Podemos trabajar con nuestro valor sin necesidad de salir del `Container`. Esto es algo notable. Nuestro valor en el `Container` es entregado a la función `map` para que podamos jugar con el y después, devuelto a su `Container` para mantenerlo seguro. Como resultado de no dejar el `Container`, podemos continuar ejecutando `map` de la misma manera, ejecutando funciones como nos plazca. Incluso podemos cambiar el tipo a medida que avanzamos como se demuestra en el último de los tres ejemplos.

Espera un minuto, si seguimos llamando `map`, ¡parece que es algún tipo de composición! ¿Qué magia matemática está en acción aquí? Bueno amigos, acabamos de descubrir *Functores*.

> Un Functor es un tipo que implementa `map` y obedece ciertas leyes

Si, *Functor* es simplemente una interfaz con un contrato. Podríamos haberla nombrado fácilmente *Mappable*, pero, ¿dónde está lo *divertido*? Los Functores provienen de la teoría de categorías, ya miraremos las matemáticas con detalle al final del capítulo. pero por ahora, trabajemos en la intuición y usos prácticos para esta interfaz bizarra.

¿Qué razón podriamos tener para embotellar un valor y usar `map` para obtenerlo? La respuesta se revela si elegimos una mejor pregunta: ¿Qué ganamos con pedirle a nuestro contenedor que aplique funciones para nosotros? Bueno, La abstracción de la aplicación de la función. Cuando aplicamos `map` con una función, le pedimos al contenedor que la ejecute para nosotros. Este es un concepto muy poderoso, de hecho.

## Maybe de Schrödinger

![cool cat, need reference]
(images/cat.png)

`Container` es bastante aburrido. De hecho, usualmente es llamado `Identity` y tiene casi el mismo impacto que nuestra función `id`[^nuevamente hay una conexión matemática que revisaremos cuando sea el momento adecuado]. Sin embargo, existen otros functores, es decir, tipos muy parecidos a los contenedores que tienen una función `map`, que pueden proporcionar un comportamiento útil mientras se utiliza `map`. Definamos uno ahora.

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

Ahora, `Maybe` se parece mucho a `Container` con un ligero cambio: primero comprobará si tiene un valor antes de llamar la función dada.

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

Observa que nuestra aplicación no explota con errores mientras aplicamos funciones sobre valores nulos. Esto se debe a que `Maybe` se encargará de comprobar si hay un valor cada vez que se aplica una función.

Esta sintaxis con puntos está perfectamente bien y funcional, pero por razones mencionadas en la parte 1, nos gustaría mantener nuestro estilo Pointfree. Como suele suceder, `map` está totalmente equipado para delegar a cualquier functor que reciba.

```js
//  map :: Functor f => (a -> b) -> f a -> f b
var map = curry(function(f, any_functor_at_all) {
  return any_functor_at_all.map(f);
});
```

Esto es una delicia ya que podemos continuar con la composición de siempre y `map` funcionará como se espera. Este también es el caso del `map` de rambda. Usaremos la notación de puntos cuando sea instructiva y la versión pointfree cuando sea conveniente. ¿Te diste cuenta de eso? He introducido a escondidas una notación adicional en nuestra declaración de tipo. `Functor f =>` nos dice que `f` debe ser un Functor. No es tan difícil, pero sentí que debía mencionarlo.

## Casos de uso

En el campo, veremos que `Maybe` suele utilizarse en funciones que podrían fallar en devolver un resultado.

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

`safeHead` es como nuestra función `_.head`, pero con seguridad de tipo agregada. Ocurre una cosa curiosa cuando `Maybe` es introducido en nuestro código; nos vemos obligados a enfrentar a esos valores `null` furtivos. La función `safeHead` es honesta y sincera acerca de su posible fracaso - realmente no hay nada de que avergonzarse - así que devuelve un `Maybe` para informarnos de este asunto. Sin embargo, Estamos más que *informados*, porque nos vemos obligados a usar `map` para obtener el valor que queremos ya que está escondido en el interior del objeto `Maybe`. Esencialmente, esto es una comprobación de valores nulos forzada por la función misma `safeHead`. Ahora podemos dormir mejor por la noche sabiendo que un valor `null` no asomará su fea y decapitada cabeza cuando menos lo esperamos. APIs como ésta actualizarán una aplicación débil de papel y puntillas a una de madera y clavos. Ellas garantizarán un software más seguro.

Algunas veces, una función puede devolver un `Maybe(null)` explicitamente para indicar un fallo. Por ejemplo:

```js
//  withdraw :: Number -> Account -> Maybe(Account)
var withdraw = curry(function(amount, account) {
  return account.balance >= amount ?
    Maybe.of({balance: account.balance - amount}) :
     Maybe.of(null);
});

//  finishTransaction :: Account -> String
var finishTransaction = compose(remainingBalance, updateLedger);  // <- estas funciones compuestas son hipotéticas, no fueron implementadas aquí...

//  getTwenty :: Account -> Maybe(String)
var getTwenty = compose(map(finishTransaction), withdraw(20));



getTwenty({ balance: 200.00});
// Maybe("Your balance is $180.00")

getTwenty({ balance: 10.00});
// Maybe(null)
```

`withdraw` inclinara su nariz ante nosotros y nos retornara `Maybe(null)` si estamos cortos de dinero. Esa funcion tambien comunica su inconstancia y nos deja otra opcion para continuar `map`. La diferencia es que `null` fue intencional aqui. En vez de un `Maybe(String)`, conseguimos un `Maybe(null)` como una señal de fracaso. Y nuestra aplicacion interrumpe de manera efectiva su flujo. Es importante tener en cuenta: si `withdraw` falla, entonces `map` cortara el resto de nuestro computo puesto que ya no va a ejecutar la funcion asignada, en este caso `finishTransaction`. Este es exactamente el comportamiento previsto, preferimos no actualizar nuestro libro de contabilidad ni mostrar nuestro nuevo balance si no se retiraron con exito los fondos.


## Liberando el valor.

Una cosa que la gente suele olvidar es que siempre habra un final de linea; cualquier funcion que envia un JSON, imprime algo en la pantalla, modifica nuestro sistema de archivo o cualquier otra cosa. No podemos entregar una salida con `return`, debemos ejecutar una funcion u otra para enviarla al mundo exterior. Podemos expresarnos como un  koan zen budista: "Si el programa no tiene ningun efecto observable, ¿que ha de correr?". Se ejecuta correctamente para su propia satisfaccion? Sospecho que meramente ejecuta algunos ciclos y luego vuelve a dormir...


El trabajo de nuestra aplicacion es la recuperacion, transformacion y carga de datos a la hora de decir adios, y que la funcion que haga esto pueda ser mapeada, asi el valor no tiene que dejar la comodidad de su contenedor. De echo un error comun es tratar de remover el valor de `Maybe` de una forma u otra, como si de repente el posible valor se materializara y todo estubiera bien. Debemos entender que eso puede ser una pieza de codigo donde nuestro valor no fue echo para este fin. Nuestro codigo se parece mas al gato *Schrödinger*, es decir, dos estados al mismo tiempo, y debe mantener este echo hasta el final de la funcion. Esto hace que nuestro codigo se convierta en un flujo linal independiente de la logica aplicada.

Existe una alternativa. Se puede retornar un valor personalizado y continuar, podemos usar un pequeño helper llamado `Maybe`.


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

Vamos ahora a retornar un valor estatico ( del mismo tipo que `finishTransaction` retorna) o finalizar la transaccion sin necesidad de usar `Maybe`. Con `Maybe` estamos haciendo el equivalente a un `if/else` mientras que con `map` la analogia con impertivo seria: `if(x !== null) { return f(x); }`.


La introduccion de `Maybe` puede causar alguna molestia en un comienzo. Los usarios de Swif y Scala saben lo que significa porque estos lenguajes tienen una implementacion de forma nativa llamada `Option(al)`. Cuando tiene que lidiar con verificaciones de `null` todo el tiempo (y hay momentos en los que sabemos con absoluta certeza que el valor existe), a muchas personas les resulta muy trabajoso. Sea como sea, con el tiempo llegara a ser mas natural y nosotros probablemente disfrutemos de la seguridad que aporta. Despues de todo la mayoria de las veces esto esvitara problemas en el codigo y salvara nuestro pellejo.


Escribir codigo no seguro, es como tomar un trabajo para pintar y decorar huevos, y luego tirarlos a la calle; o construir casas con el material con que los tres cerditos contruyen. Nos hará bien poner un poco de seguridad en nuestras funciones, y `Maybe` nos ayuda justo a eso.

Seria negligente no hablar de que en una implementación "real", `Maybe` se divide en dos partes:
Una para algo y otra para nada. Esto nos permite cumplir con la parametrización de `map` de modo que valores como `undefined` o `null` pueden ser mapeados y la calificacion universal de valores de un functor seran respetados. Usted frecuentemente vera tipos como `Some(x) / None` o tambien `Just(x) / Nothing` en vez de un `Maybe` que hace un checkeo nulo en su valor.


## Manejadores de errores puros

<img src="images/fists.jpg" alt="pick a hand... need a reference" />

Puede ser un shock, pero `throw / catch`no son puros. Cuando un error es lanzado, en vez de retornar un valor de salida, hacemos sonar las alarmas!. La funcion ataca lanzando millares de ceros y unos como escudos y lanzas en una batalla frenetica contra nuestra entrada. Con nuestro nuevo amigo `Either`, podemos hacer algo mejor que declarar la guerra contra la entrada, podemos responder con un mensaje educado. Vamos a dar una hojeada.


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

`Left` y `Right` son 2 subclases de un tipo abstracto que llamamos `Either`. No vamos a hacer una ceremonia de como crear la clase base ya que no la vamos a utlizar, pero es bueno saber eso. No hay nada nuevo aqui, ademas de los 2 tipos. Vamos a ver como funcionan:


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

`Left` es como un adolescente problematico que ignora nuestra llamada a `map`. `Right` funcionara como `Container` (A.K.A Identidad). La ventaja aqui es ser capaz de 
incorporar un mensaje de error dentro de `Left`.

Imaginemos que tenemos una funcion que no tendra exito. ¿que tal si calculamos la edad a partir de la fecha de nacimiento?. Podemos usar `Maybe(null)` para señalar un fallo en nuestro programa, lo que no nos dice mucho. Tal vez quisieramos saber el motivo de la falla. Vamos a escribir esto usando `Either`.

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

Ahora, como `Maybe(null)`, estamos creando un corto circuito cuando retornamos `Left`. La diferencia es que ahora, tenemos una pista de porque nuestro programa se ha descarrilado. Algo a notar es que retornamos `Either(String, Number)`, que recive a `String` para `Left` o `Number` para `Right`. Este tipo de asignatura es un poco informal ya que no tenemos mucho tiempo para definir un `Either` real, aunque hemos aprendido mucho sobre este tipo. Eso tambien nos dice que estamos obteniendo un mensaje de error, o la edad.


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

Cuando `birthdate``es valido, el programa mostrara en pantalla la fortuna mistica. Sino mostrara `Left` con un mensaje de error claro como la luz del dia, pero aun dentro de su contenedor. Entonces se nos mostrara un error, de una manera mas tranquila y educada, a diferencia de un niño que pierde el control cuando las cosas van mal.

En este ejemplo, esamos dividiendo de forma logica nuestro flujo de control, en funcion de la validez de la fecha de nacimiento, y sin embargo, nos estamos moviendo linealmente de derecha a izquierda en lugar de escalar a trabes de las llaves de instrucciones condicionales. Por lo general movemos el `console.log` fuera de la funcion `zoltar` y se lo damos a `map` al momento de la llamada, pero es muy util para ver como difiere la rama de `Right`. Utilizamos *_* en la firma del tipo de la rama derecha para indicar que es un valor que no deberia ser ignorado (en algunos navegadores usted debe utilizar `console.log.bind(console)` para usar esto en primera clase).


Me gustaria aprobechar esta oportunidad para apuntar algo que pude haberme olvidado: `fortune` a pesar de usar `Either` en este ejemplo, no es conciente de la presencia de un Functor. Ese es el caso con `finishTransaction` del ejemplo anterior. En el momento de la llamada, la funcion puede estar envuelta en un `map`, que la transforma desde un *non-functor-function* a un *functor*, en terminos formales. Llamamos a este proceso `lifting`. Las funciones tienden a trabajar mejor con los tipos de datos normales en lugar de los tipos container, por lo tanto cuando sea necesario se hace `lifting` dentro de un contenedor adecuado. esto hace mas simple, mas funciones reutilizables pudiendo ser modificadas para trabajar con cualquier tipo de functor bajo demanda.


`Either` es genial para errores casuales como validaciones pero tambien para cosas mas serias, como detener los errores de ejecucion de archivos que faltan (missing files) o problemas de conexion de sockets. Trate de reemplazar algunos de los ejemplos de `Maybe` por `Either` para obtener mejores resultados.


Pude haber cometido un error al introducir `Either` como un mero contenedor de mensajes de error. es la disyuncion logica `OR` (A.K.A ||) en un tipo. Tambien codifica la idea de un *Coproducto* de la teoria de las categorias, que no sera abordado en este libro, pero que vale la pena leer sobre él ya que tiene muchas propiedades que pueden ser explotadas. Es una especie de suma canónica disyuntiva (suma de productos), eso es porque su numero total de posibles valores estan contenidos en dos tipos de contenedores (Se que esto es un poco dificil asi que aqui tiene un [gran articulo](https://www.fpcomplete.com/school/to-infinity-and-beyond/pick-of-the-week/sum-types)). Existen muchas cosas que `Either` puede hacer, pero como un functor, esto es usado para tratamiento de errores.


Al igual que con `Maybe` tenemos `Either` que se comporta de manera similar, pero toma dos funciones en lugar de una y un valor estatico. Cada funcion debe devolver el mismo tipo.


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

Finalmente, un uso para esa misteriosa funcion `id`. Ella simplemente retorna un `Left` para pasar un mensaje de error a `console.log`. Hacemos nuestra aplicacion mas robusta obligando un tratamiento de errores con `getAge`.   
Y con esto, estamos preparados para seguir con un tipo completamente diferente de functor.


## Old McDonald had Effects...

<img src="images/dominoes.jpg" alt="dominoes.. need a reference" />

En nuestro capitulo sobre la pureza, vimos un ejemplo particular de una función pura. Esta función contenia un efecto secundario, pero la volvimos pura envolviendo su acción en otra función.Aqui hay otro ejemplo de eso:

```javascript
//  getFromStorage :: String -> (_ -> String)
var getFromStorage = function(key) {
  return function() {
    return localStorage[key];
  };
};
```

No habiamos rodeado sus tripas en otra función,`getFromStorage` variara su salida dependiendo de las circunstancias externas. Con el robusto envoltorio en su lugar, siempre vamos a obtener la misma salida por entrada: una función que, cuando es llamada,nos retornara un item en particular desde `localStorage`. Y al igual que (tal vez lance unos cuantos ave maria) hemos aclarado nuestra conciencia y todo esta perdonado

Excepto que esto no nos es particularmente util por ahora. Al igual que una figura de accion coleccionable en su paquete original, en realidad no podemos jugar con él. Si solo hubiera una manera de alcanzar el interior del contenedor y obtener su contenido... Biemvenido a IO.


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

`IO` difiere de los functores previos en que `_value` es siempre una función. No pensamos en su `_value` como una función, igualmente- esto es un detalle de implementación y que por ahora es mejor ignorarlo. Lo que ocurre es exactamente lo que hemos visto con el ejemplo de `getFromStorage`: `IO` retrasa la acción impura, capturandola en una funcion wrapper. Como tal, pensemos que `IO` contiene el valor de retorno como una acción envuelta y no el envoltorio en si. Esto es evidente en la función `of`: tenemos una `IO(x)`, la `IO(function() {return x})` es necesario solo para evitar la evaluación.

Veamos un uso de esto:

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

Aqui, `io_window` es un IO real sobre la cual podemos hacer `map` inmediatamente, mientras que `$` es una función que retorna una `IO` despues de su llamada. He escrito los valores de retorno conceptuales para expresar mejor la `IO`, aunque en realidad, siempre sera `{ __value: [Function] }`. Cuando hacemos un `map` sobre nuetro `IO`, nos ceñimos esa función al final de una composición que, a su vez, se convierte en el nuevo `__value` y asi. Nuestras funciones asignadas no se ejecutaran, sino que se clavan con tachuelas al final de la computación que estamos construyendo, función a función, como si estuviramos colocando cuidadosamente fichas de domino que no nos atrevemos a volcar. El resultado es una reminiscencia del patron de diseño de la banda de los cuatro o una cola.

Tomese un momento para canalizar su intuición sobre los functores. Si miramos mas alla de los detalles de implementación, devemos sentirnos como en casa mapeando sobre cualquier contenedor independientemente de sus particularidades e idiosincrasias. Tenemos las leyes de los functores, las cuales vamos a explorar al final del capítulo, damos gracias por este poder pseudo-psiquico. De todos modos, por fin podemos jugar con valores impuros sin sacrificar nuestra preciosa pureza.


Ahora, hemos enjaulado la bestia, pero todavia tendremos que liberarla en algun momento. Mapeando sobre nuestra `IO` hemos construido una poderosa computación impura y ejecutarlo seguramente nos perturbara la paz. Entonces, ¿donde y cuando podemos apretar el gatillo?, ¿Es incluso posible ejecutar nuestra IO y todavia vestir de blanco en nuestra boda?. La respuesta es si, si ponemos la responsabilidad en el codigo de llamada. Nuestro codigo puro, a pesar de las conspiraciónes infames e intrigas, mantiene su inocencia y es el que la invoca el que se carga con la responsabilidadde ejecutar realmente los efectos. Veamos un ejemplo un poco mas concreto.

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

Nuestra libreria mantiene sus manos limpias envolviendo `url` en una `IO` y pasando la pelota a quien la llame. Tambien pudo haber notado que hemos acoplado nuestros contenedores; es perfectamente razonable para tener una `IO(Maybe([x]))`, que son tres functores profundos (`Array` es sin duda un tipo de contenedor mapeable) y excepcionalmente expresivo.


Hay algo que me ha estado molestando y que debemos rectificar de inmediato: `IO 's __value` no es realmente el valor que esta contenido, ni tampoco es una propiedad privada como sugiere el prefijo de subrayado. Es el pasador en la granada y que esta destinado a ser tirado por quien llame en la mas publica de las formas. Vamos a renombrar esta propiedad a `unsafePerformIO` para recordar a nuestros usuarios de su volatibilidad. 


```js
var IO = function(f) {
  this.unsafePerformIO = f;
}

IO.prototype.map = function(f) {
  return new IO(_.compose(f, this.unsafePerformIO));
}
```

Asi es, mucho mejor. Ahora nuestro codigo de invocación se hace `findParam("searchTerm").unsafePerformIO()`, que es claro como el agua para los usuarios (y lectores) de la aplicación.

`IO` sera un compañero leal, ayudandonos a domar esas salvajes y contaminantes acciones impuras. A continuación,  vamos a ver un tipo similar es esencia, pero con un caso de uso radicalmente diferente.


## Tareas ascincronas

Las callbacks son una escalera de caracol que cada vez se van haciendo mas estrechas hasta llevarnos al infierno. Son el flujo de control diseñadas por M.C Escher. Cada callback anidado es apretado entre una jungla de curly braces y parentesis, se sienten como  un limbo en la mazmorra (hasta donde es posible que llegue!). Estoy recibiendo escalofrios claustrofobicos pensando en ellos. No es para preocuparse, ya que tenemos una manera mucho mejor de tratar con codigo asyncrono y comienza con una "F".

Las partes internas son demasiado complicadas para esparcirse por toda la pagina aqui, asi que utilizaremos `Data.Task.` (previamente `Data.Future`) de Quildreen Motta's fantastic [Folktale](http://folktalejs.org/). He aqui algunos ejemplos de uso.

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
Las funciónes que estoy llamando (`reject` y `result`) son nuestros callbacks `error` y `success`, respectivamente. Como podes ver, simplemente hace un `map` sobre `Task` para trabajar con el futuro valor como si estuviera alli mismo a nuestro alcance. Ya `map` deberia ser de sobra conocido.

Si usted esta familiarizado con las promesas, usted podra reconocer la función `map` como `then` con `Task` jugando el papel de nuestra promesa. No se preocupe si usted no esta familizado con las promesas, nosotros no vamos a usarlas de todos modos porque no son puras, pero la analogia se sostiene sin embargo.

Al igual que `IO`, `Task` esperara pacientemente a que le demos luz verde antes de ejecutarse. De echo, porque espera nuestra orden, `IO` es subsumido con eficacia por `Task` para todas las tareas asyncronas; `readfile` y `getJSON` no requieren de un contenedor  `IO` complementario para ser puros. Es mas, `Task` trabaja de manera similar cuando hacemos `map` sobre él: Estamos sembrando las instrucciones para el futuro como si fuera una tabla de tareas en una capsula del tiempo- Un acto de sofisticada dilatación tecnologica. 

Para ejecutar nuestro `Task`, hay que llamar al metodo `fork`. Esto funciona igual que `unsafePerformIO`, pero como su nombre indica, esto hara un fork de nuetro proceso y la evaluación continuara sin bloquear nuestro hilo. Esto se puede implementar de muchas maneras con hilos y tales, pero en este caso actua como una llamada aincrona normal y la gran rueda de ciclo de eventos sigue girando. Veamos `fork`. 


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

Al llamar a `fork`, `Task` se apresura a buscar algunos post y renderizar la pagina. Mientras tanto, mostramos un snipper ya que `fork` no esperara por una respuesta. Finalmente, vamos a hacer que aparezca un error o renderize la pagina en la pantalla dependiendo de que si la llamada a `getJSON` tuvo exito o no.

Tome un momento para considerar como el flujo de control lineal funciona aqui. Acabamos de leer desde abajo hacia arriba,derecha a izquierda aunque el programa realmente brinque un poco alrededor durante la ejecucion. Esto hace que la lectura y el razonamiento acerca de nuestra aplicación sea mas sencillo que tener que rebotar entre callbacks y bloques de control de errores.

¡Genial, podria mirar esto, `Task` tambien ha engullido a `Either`!, debe hacerlo con el fin de controlar los errores futuristas ya que nuestro flujo normal de control no se aplica en el mundo asincrono. Todo esto esta muy bien, ya que nos proporciona un puro y suficiente manejador de errores fuera de la caja.

Incluso con `Task`, nuestros functores `IO` y `Either` no quedan exentos de trabajar. Tengan paciencia conmigo en un ejemplo rapido que se inclina hacia el lado mas complejo e hipotetico. Pero util para propositos ilustrativos.

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
En este ejemplo, seguimos haciendo uso de `Either` y `IO` desde dentro de la rama `success` de `readFile`.
`Task` se encarga de las impurezas de la lectura de un archivo de forma asincrona, pero todavia nos ocupamos de la validacion de la configuración con `Either` y discutiendo la conexión a la db con `IO`. Como podras ver,todavia estamos en el negocio para todas las tareas asincronas. 


Podria seguir, pero eso es todo lo que hay que hacer, tan smple como `map`.

En la practica, es probable que tengamos multiples tareas asincronas en un workflow y todavia no hemos adquirido por completo todas la APIs de contenedores para hacer frente a este escenario. No se preocupe, veremos las monadas, y muy pronto, pero primero, debemos examinar las matemáticas que hacen todo esto posible. 


## A Spot of Theory

Como mencionamos antes, los functores provienen de la teoria de categorías y satisfacen algunas leyes. Primero vamos a explorar estas propiedades útiles.

```js
// identity
map(id) === id;

// composition
compose(map(f), map(g)) === map(compose(f, g));
```
La ley de *identidad* es simple, pero importante. Estas leyes son bits de codigo ejecutables para que podamos introducirlos en nuestras propias funciones para validar su legitimidad.

```js
var idLaw1 = map(id);
var idLaw2 = id;

idLaw1(Container.of(2));
//=> Container(2)

idLaw2(Container.of(2));
//=> Container(2)
```

Como usted ve, son iguales. A continuación vamos a ver la composición.

```js
var compLaw1 = compose(map(concat(" world")), map(concat(" cruel")));
var compLaw2 = map(compose(concat(" world"), concat(" cruel")));

compLaw1(Container.of("Goodbye"));
//=> Container('Goodbye cruel world')

compLaw2(Container.of("Goodbye"));
//=> Container('Goodbye cruel world')
```

En la teoria de categorías, los functores toman los objetos y morfismos de una categoria y los mapea a una categoria diferente. Por definición, esta nueva categoria debe tener una identidad y la capacidad de componer morfismos, pero no necesitamos comprobarlo debido a que las leyes antes mencionadas se aceguran que estos se conservan.

Tal vez nuestra definición de una categoria sea todavia un poco difusa. Se puede pensar en una categoria como una red de objetos con morfismos que los conectan. Asi que un functor seria un mepeo de una categoria a la otra sin romper la red. Si un objeto *a* esta en nuestra categoria de fuente *c*, cuando lo mapeamos a la categoria *d* con un functor *f*, nos referimos a ese objeto como *F a* (si los pones juntos que significa?!). Quizas, es mejor mirar un diagrama.


<img src="images/catmap.png" alt="Categories mapped" />

Por ejemplo, `Maybe` mapea nuestra categoria de tipos y funciones a una categoria en la que cada objeto no puede existir y cada morfismo tiene un checkeo nulo. Esto lo logramos en el codigo rodeando cada función con `map` y cada tipo con nuestro functor. Sabemos que cada uno de nuestros tipos y funciones normales, continuaran para componerse en este nuevo mundo. Tecnicamente, cada functor en nuestro codigo se mapea a una sub-categoria de tipos y funciones lo que hace que todos los functores con esta marca sean llamados endofunctores, pero para nuestros propositos, vamos a pensar en esto como una categoria diferente.


Tambien podemos visualizar el mapeo de un morfismo y sus correspondientes objetos con este diagrama:

<img src="images/functormap.png" alt="functor diagram" />

Ademas de visualizar el morfismo mapeado de una categoria a otra bajo el functor *f*, podemos ver como el diagrama los conmuta, es decir, si se siguen las flechas, cada ruta procuce el mismo resultado. Las diferentes rutas significan diferentes comportamientos, pero siempre terminamos en el mismo tipo. Este formalismo nos da principios sobre como razonar hacerca de nuestro codigo- donde confiadamente podemos aplicar formulas sin tener que analizar ni examinar cada escenario de manera individual. Veamos un ejemplo en concreto:

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

O visualmente:

<img src="images/functormapmaybe.png" alt="functor diagram 2" />

Podemos ver instantaneamente y refactorizar el codigo basandonos en estas propiedades compartidas por todos los functores.

Los functores se pueden apilar:

```js
var nested = Task.of([Right.of("pillows"), Left.of("no sleep for you")]);

map(map(map(toUpperCase)), nested);
// Task([Right("PILLOWS"), Left("no sleep for you")])
```

Lo que tenemos aqui con `nested` es un futuro array de elementos que podrian ser errores. Nosotros aplicamos `map` para pelar cada capa y ejecutar nuestra función en los elementos. No vemos callbacks, if/else's,o bucles for; solo un contexto explicito. Nosotros sin embargo, tuvimos que alicar `map(map(map(f)))`. En cambio podemos componer functores. Si me has oido bien:

```js
var Compose = function(f,g,x){
  this.getCompose = f(g(x));
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
Ahi, un `map`. La composición de functores es asociativa y temprana, definimos `Container`,  que se llama en realidad el functor identidad. Si tenemos la identidad y la composición asociativa tenemos una categoria. Esta categoria en particular tiene categorias como objetos y functores como morfismos, lo cual es suficiente para hacerle transpirar al uno el cerebro. Nosotros no profundizaremos demasiado en esto, pero es bueno para apreciar las implicaciónes arquitectonicas o incluso solo la belleza de este patron.


## En resumen


Hemos visto diferente functores, pero hay un numero infinito. Algunas omisiones notables son las estructura de datos iterables como los arboles, listas, mapas, pares, lo que sea. Los streams de eventos y los observables ambos son functores. Otros pueden ser para la encapsulación o incluso solo para modelar un tipo. Los functores estan a nuestro alrededor y los vamos a usar extensivamente en todo el libro.

¿Que hay de llamar a una función con multiples argumentos de tipo functor?. O sobre como trabajar con una secuencia ordenada de acciones impuras o asincronas?. Todavia no hemos adquirido el conjunto de herramientas completo para trabajar en este mundo encajonado. A continuación, cortaremos con la persecución y veremos las monadas.

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
