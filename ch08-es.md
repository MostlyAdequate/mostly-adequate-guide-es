# Capítulo 08: Tupperware

## El Poderoso Contenedor

<img src="images/jar.jpg" alt="http://blog.dwinegar.com/2011/06/another-jar.html" />

Hemos visto como escribir programas que canalicen los datos a través de una serie de funciones puras. Son especificaciones declarativas de comportamiento. Pero ¡¿qué pasa con el control de flujo, el manejo de errores, las acciones asíncronas, el estado y me atrevo a decir, los efectos?! En este capítulo, descubriremos los cimientos sobre los que se construyen todas estas abstracciones tan útiles.

Primero crearemos un contenedor. Este contenedor debe poder contener cualquier tipo de valor; una bolsa de cierre zip que solo acepta pudin de tapioca raramente es útil. Será un objeto, pero no le daremos métodos ni propiedades en el sentido de la orientación de objetos. No, lo trataremos como si de un cofre del tesoro se tratara; una caja especial que envuelve a nuestros valiosos datos.

```js
class Container {
  constructor(x) {
    this.$value = x;
  }
  
  static of(x) {
    return new Container(x);
  }
}
```

He aquí nuestro primer contenedor. Lo hemos llamado, inteligentemente, `Container` [*Contenedor*]. Usaremos `Container.of` como un constructor que nos ahorra tener que escribir la terrible palabra clave `new` por todas partes. Hay algo más en la función `of` de lo que se ve a simple vista, pero por ahora, piensa en ella como la manera correcta de colocar valores en nuestro contenedor. 

Examinemos nuestra flamante caja nueva... 

```js
Container.of(3);
// Container(3)

Container.of('hotdogs');
// Container("hotdogs")

Container.of(Container.of({ name: 'yoda' }));
// Container(Container({ name: 'yoda' }))
```

Si estás usando node, verás `{$value: x}` aunque tengamos un `Container(x)`. Chrome mostrará el tipo correctamente, pero no importa; mientras entendamos como es un `Container` iremos bien. En algunos entornos se puede sobreescribir el método `inspect` si se quiere, pero no seremos tan minuciosos. Para este libro, escribiremos la salida conceptual como si hubiéramos sobreescrito `inspect`, ya que por razones pedagógicas y también estéticas es mucho más instructivo que `{$value: x}`. 

Aclaremos algunas cosas antes de continuar:

* `Container` es un objeto con una sola propiedad. Aunque no están limitados, muchos contenedores solo contienen una cosa. Arbitrariamente, hemos llamado `$value` [*valor*] a su propiedad.

* El valor no puede ser de un tipo específico o de lo contrario difícilmente nuestro `Container` haría honor a su nombre. 

* Una vez los datos entran en nuestro `Container` se quedan ahí. *Podríamos* sacarlos usando `.$value`, pero eso anularía el propósito.

Las razones por las cuales estamos haciendo esto quedarán claras como un tarro de cristal, pero por el momento, tendréis que ser pacientes.

## Mi Primer Funtor

Una vez que nuestro valor, sea cual sea, está en el contenedor, necesitamos una forma de ejecutar funciones sobre él.

```js
// (a -> b) -> Container a -> Container b
Container.prototype.map = function (f) {
  return Container.of(f(this.$value));
};
```

Es como el famoso `map` de Array, excepto que tenemos un `Container a` en lugar de `[a]`. Y esencialmente funciona de la misma manera:

```js
Container.of(2).map(two => two + 2); 
// Container(4)

Container.of('flamethrowers').map(s => s.toUpperCase()); 
// Container('FLAMETHROWERS')

Container.of('bombs').map(append(' away')).map(prop('length')); 
// Container(10)
```

Podemos trabajar con nuestro valor sin salir del contenedor. Esto es algo extraordinario. Nuestro valor en `Container` es entregado a la función `map` para que podamos manipularlo y después es devuelto a su contenedor para que esté a salvo. Como resultado de no salir nunca de `Container`, podemos seguir usando `map`, ejecutando funciones a nuestro antojo. Incluso podemos cambiar el tipo sobre la marcha como se demuestra en el último de los tres ejemplos. 

Espera un minuto, si seguimos llamando a `map`, ¡parece ser una especie de composición! ¿Qué magia matemática es esta? Bien amigos, acabamos de descubrir los *Funtores*.

> Un Funtor es un tipo que implementa `map` y obedece a algunas leyes

Sí, *Funtor* es simplemente una interfaz con un contrato. También podríamos haberlo llamado *Mapeable*, pero entonces, ¿dónde estaría la diversión? Los Funtores provienen de la teoría de categorías y veremos las matemáticas en detalle hacia el final del capítulo, pero por ahora, trabajemos en la intuición y los usos prácticos de esta interfaz de nombre extraño.

¿Qué razón podríamos tener para embotellar un valor y utilizar `map` para llegar a él? La respuesta se revela por si sola si escogemos mejor la pregunta: ¿Qué ganamos al pedir a nuestro contenedor que aplique funciones en nuestro lugar? Pues la abstracción de la aplicación de funciones. Cuando aplicamos una función mediante `map`, le pedimos al tipo del contenedor que la ejecute en nuestro nombre. Este es, de hecho, un concepto muy poderoso.

## El Maybe de Schrödinger

<img src="images/cat.png" alt="gato guay, necesita una referencia" />

`Container` es bastante aburrido. De hecho, se le suele llamar `Identity` [*Identidad*] y tiene más o menos el mismo impacto que nuestra función `id` (de nuevo hay una conexión matemática que veremos en el momento indicado). Sin embargo, hay otros funtores, o sea otros tipos que hacen de contenedor y que tienen su propia función `map`, que pueden proporcionar útiles comportamientos cuando mapean. Definamos uno ahora:

> En el [Apéndice B](./appendix_b-es.md#Maybe) se ofrece una implementación completa

```js
class Maybe {
  static of(x) {
    return new Maybe(x);
  }

  get isNothing() {
    return this.$value === null || this.$value === undefined;
  }

  constructor(x) {
    this.$value = x;
  }

  map(fn) {
    return this.isNothing ? this : Maybe.of(fn(this.$value));
  }

  inspect() {
    return this.isNothing ? 'Nothing' : `Just(${inspect(this.$value)})`;
  }
}
```

Ahora, `Maybe` se parece mucho a `Container` pero con un pequeño cambio: comprueba si tiene un valor antes de llamar a la función proporcionada. Esto tiene el efecto de evitar esos molestos nulls cuando aplicamos `map` (Ten en cuenta que esta implementación está simplificada por motivos didácticos).

```js
Maybe.of('Malkovich Malkovich').map(match(/a/ig));
// Just(True)

Maybe.of(null).map(match(/a/ig));
// Nothing

Maybe.of({ name: 'Boris' }).map(prop('age')).map(add(10));
// Nothing

Maybe.of({ name: 'Dinah', age: 14 }).map(prop('age')).map(add(10));
// Just(24)
```

Fíjate en que nuestra app no explota con errores cuando mapeamos funciones sobre nuestros valores nulos. Esto es porque `Maybe` se encargará de comprobar que el valor exista cada vez que le aplique una función.

Esta sintaxis con el punto está bien y es funcional, pero por las razones mencionadas en la Parte 1, nos gustaría mantener nuestro estilo *pointfree*. Así, `map` está totalmente equipada para delegar en cualquier funtor que reciba:

```js
// map :: Functor f => (a -> b) -> f a -> f b
const map = curry((f, anyFunctor) => anyFunctor.map(f));
```

Esto es perfecto, ya que podemos continuar con la composición como de costumbre y `map` funcionará según lo esperado. Este también es el caso con el `map` de ramda. Usaremos la sintaxis con el punto cuando sea instructiva y la versión *pointfree* cuando sea conveniente. ¿Te has dado cuenta? He introducido disimuladamente una notación adicional en nuestra firma de tipos. `Functor f =>` nos dice que `f` debe ser un Funtor. Aunque no es algo que sea complicado, sentí que debía mencionarlo.  

## Casos de Uso

En la vida real, típicamente vemos a `Maybe` usado en funciones que podrían fallar y no devolver un resultado.

```js
// safeHead :: [a] -> Maybe(a)
const safeHead = xs => Maybe.of(xs[0]);

// streetName :: Object -> Maybe String
const streetName = compose(map(prop('street')), safeHead, prop('addresses'));

streetName({ addresses: [] });
// Nothing

streetName({ addresses: [{ street: 'Shady Ln.', number: 4201 }] });
// Just('Shady Ln.')
```

`safeHead` es como nuestra `head` normal, pero con seguridad de tipos añadida. Una cosa curiosa ocurre cuando `Maybe` es introducido en nuestro código; somos forzados a manejar esos escurridizos valores `null`. La función `safeHead` es honesta y directa sobre su posible fallo; realmente no hay nada de lo que avergonzarse, así que nos devuelve un `Maybe` para informarnos sobre este asunto. Sin embargo, estamos más que solo informados, porque nos vemos obligados a aplicar map para llegar al valor que queremos, ya que está escondido dentro del objeto `Maybe`. Esencialmente, se trata de una comprobación por parte de la función `safeHead` para ver si tenemos un `null`. Ahora podemos dormir mejor por la noche sabiendo que un valor `null` no levantará su fea y decapitada cabeza cuando menos lo esperemos. Apis como esta harán que una endeble aplicación de papel y chinchetas pase a ser de madera y clavos. Garantizarán un software más seguro. 

Para indicar un fallo a veces una función puede devolver `Nothing` explícitamente. Por ejemplo:

```js
// withdraw :: Number -> Account -> Maybe(Account)
const withdraw = curry((amount, { balance }) =>
  Maybe.of(balance >= amount ? { balance: balance - amount } : null));

// Esta función es hipotética, no está implementada aquí.. ni en ningún otro sitio.
// updateLedger :: Account -> Account 
const updateLedger = account => account;

// remainingBalance :: Account -> String
const remainingBalance = ({ balance }) => `Your balance is $${balance}`;

// finishTransaction :: Account -> String
const finishTransaction = compose(remainingBalance, updateLedger);


// getTwenty :: Account -> Maybe(String)
const getTwenty = compose(map(finishTransaction), withdraw(20));

getTwenty({ balance: 200.00 }); 
// Just('Your balance is $180')

getTwenty({ balance: 10.00 });
// Nothing
```

`withdraw` nos hará saber cuando estamos cortos de dinero devolviéndonos un `Nothing`. Esta función también nos comunica su veleidad y no nos deja otra opción que aplicar `map` a todo lo que le sigue. La diferencia es que aquí el `null` es intencionado. En lugar de un `Just('..')` obtenemos el `Nothing` de regreso para señalar el error y luego nuestra aplicación detiene la ejecución de manera efectiva. Es importante destacar esto: si la función `withdraw` falla, entonces `map` cortará el resto de nuestra computación, ya que nunca ejecutará las funciones mapeadas, concretamente `finishTransaction`. Este es precisamente el comportamiento pretendido, dado que preferimos no actualizar nuestra contabilidad o mostrar un nuevo saldo si no hemos retirado fondos con éxito. 

## Liberando el Valor

Una cosa que a menudo la gente pasa por alto es que siempre habrá un final de línea; alguna función que provoca un efecto como enviar un JSON, imprimir algo en la pantalla o alterar algún archivo en el sistema, o lo que sea. No podemos entregar la salida con `return`, debemos ejecutar alguna u otra función para sacarla al mundo exterior. Podemos expresarlo como un koan del Budismo Zen: "Si un programa no tiene ningún efecto observable, ¿se ejecuta siquiera?". ¿Se ejecuta correctamente para su propia satisfacción? Sospecho que simplemente quema algunos ciclos y vuelve a dormir...

El trabajo de nuestra aplicación es recuperar, transformar y cargar con esos datos hasta el momento de la despedida y la función que lo hace ha de poder ser mapeada, para que así el valor no necesite salir del cálido vientre de su contenedor. De hecho, un error típico es tratar de sacar el valor de nuestro `Maybe` de una manera u otra como si el posible valor de su interior se fuese a materializar de repente y todo fuese a ser perdonado. Debemos entender que puede haber bifurcaciones en el código donde nuestro valor pueda no sobrevivir y alcanzar su destino. Nuestro código, al igual que el gato de Schrödinger, está en dos estados a la vez y debe mantenerse así hasta la función final. Esto da a nuestro código un flujo lineal a pesar de las ramificaciones lógicas. 

Existe, sin embargo, una vía de escape. Si preferimos devolver un valor personalizado y proseguir, podemos utilizar un pequeño ayudante llamado `maybe`.

```js
// maybe :: b -> (a -> b) -> Maybe a -> b
const maybe = curry((v, f, m) => {
  if (m.isNothing) {
    return v;
  }

  return f(m.$value);
});

// getTwenty :: Account -> String
const getTwenty = compose(maybe('You\'re broke!', finishTransaction), withdraw(20));

getTwenty({ balance: 200.00 }); 
// 'Your balance is $180.00'

getTwenty({ balance: 10.00 }); 
// 'You\'re broke!'
```

Ahora devolveremos un valor estático (del mismo tipo que devuelve `finishTransaction`) o seguiremos para finalizar alegremente la transacción sin `Maybe`. Con `maybe`, estamos ante el equivalente de una sentencia `if/else` mientras que con `map`, el análogo imperativo sería: `if (x !== null) { return f(x) }`.

Inicialmente, la introducción de `Maybe` puede causar cierta incomodidad. Los usuarios de Swift y Scala sabrán a qué me refiero, ya que está incorporado en las librerías del núcleo bajo la apariencia de `Option(al)`. Cuando se nos empuja continuamente a comprobar la presencia de `null` (y hay veces que sabemos con absoluta certeza que el valor existe), la mayoría no podemos evitar que nos parezca un poco laborioso. Sin embargo, con el tiempo, se volverá algo natural y probablemente apreciarás la seguridad. Al fin y al cabo, la mayoría de las veces evitará chapuzas y nos mantendrá a salvo.

Escribir software inseguro es como asegurarse de decorar cada huevo con pinturas pastel antes de lanzarlo al tráfico; como construir una residencia de ancianos con materiales rechazados por los tres cerditos. Nos vendrá bien poner algo de seguridad en nuestras funciones y `Maybe` nos ayuda justamente a hacer eso.

Sería negligente por mi parte si no mencionase que la implementación "real" dividirá a `Maybe` en dos tipos: uno para algo y otro para nada. Esto nos permite obedecer a la parametricidad de `map` para que valores como `null` y `undefined` puedan seguir siendo mapeados y que la calificación universal del valor como funtor siga siendo respetada. A menudo verás tipos como `Some(x) / None` o `Just(x) / Nothing` en lugar de un `Maybe` que comprueba que su valor no sea `null`.

## Manejo de Errores Puro

<img src="images/fists.jpg" alt="escoge una mano... necesita una referencia" />

Puede resultar chocante, pero `throw/catch` no es muy puro. Cuando un error es lanzado, en lugar de devolver un valor de salida, ¡hacemos sonar las alarmas! La función ataca, lanzando miles de 0 y 1 como escudos y dardos en una batalla eléctrica contra nuestra intrusa entrada. Con nuestro nuevo amigo `Either`, podemos hacer algo mejor que declarar la guerra a la entrada, podemos responder con un educado mensaje. Echemos un vistazo:

> En el [Apéndice B](./appendix_b-es.md#Either) se proporciona una implementación completa

```js
class Either {
  static of(x) {
    return new Right(x);
  }

  constructor(x) {
    this.$value = x;
  }
}

class Left extends Either {
  map(f) {
    return this;
  }

  inspect() {
    return `Left(${inspect(this.$value)})`;
  }
}

class Right extends Either {
  map(f) {
    return Either.of(f(this.$value));
  }

  inspect() {
    return `Right(${inspect(this.$value)})`;
  }
}

const left = x => new Left(x);
```

`Left` y `Right` son dos subclases de un tipo abstracto llamado `Either`. Me he saltado la ceremonia de crear la superclase `Either` ya que no la usaremos nunca, pero es bueno saber de su existencia. Ahora bien, no hay nada nuevo aquí aparte de los dos tipos. Veamos como actúan: 

```js
Either.of('rain').map(str => `b${str}`); 
// Right('brain')

left('rain').map(str => `It's gonna ${str}, better bring your umbrella!`); 
// Left('rain')

Either.of({ host: 'localhost', port: 80 }).map(prop('host'));
// Right('localhost')

left('rolls eyes...').map(prop('host'));
// Left('rolls eyes...')
```

`Left` es como un adolescente e ignora nuestra solicitud de aplicarse `map` a sí mismo. `Right` funcionará igual que `Container` (también conocido como Identidad). El poder viene de la capacidad de incrustar un mensaje de error dentro de `Left`.

Supón que tenemos una función que podría no tener éxito. Quizás una función que calcule la edad a partir de una fecha de nacimiento. Podríamos utilizar `Nothing` para avisar del fracaso y bifurcar nuestro programa, sin embargo, eso no nos dice mucho. Quizás nos gustaría saber por qué ha fallado. Escribámoslo usando `Either`.

```js
const moment = require('moment');

// getAge :: Date -> User -> Either(String, Number)
const getAge = curry((now, user) => {
  const birthDate = moment(user.birthDate, 'YYYY-MM-DD');

  return birthDate.isValid()
    ? Either.of(now.diff(birthDate, 'years'))
    : left('Birth date could not be parsed');
});

getAge(moment(), { birthDate: '2005-12-12' });
// Right(9)

getAge(moment(), { birthDate: 'July 4, 2001' });
// Left('Birth date could not be parsed')
```

Ahora bien, al igual que con `Nothing`, cuando devolvemos un `Left` estamos cortocircuitando nuestra aplicación. La diferencia es que ahora tenemos una pista de por qué nuestro programa ha descarrilado. Algo a tener en cuenta es que devolvemos `Either(String, Number)`, que contiene un `String` como su valor izquierdo (`Left`) y un `Number` como su valor derecho (`Right`). Esta firma de tipos es un poco informal, ya que no hemos dedicado tiempo suficiente para definir una superclase `Either` real, sin embargo, aprendemos mucho del tipo. Nos informa de que estamos obteniendo o bien un mensaje de error o bien la edad.

```js
// fortune :: Number -> String
const fortune = compose(concat('If you survive, you will be '), toString, add(1));

// zoltar :: User -> Either(String, _)
const zoltar = compose(map(console.log), map(fortune), getAge(moment()));

zoltar({ birthDate: '2005-12-12' });
// 'If you survive, you will be 10'
// Right(undefined)

zoltar({ birthDate: 'balloons!' });
// Left('Birth date could not be parsed')
```

Cuando `birthdate` es válido, el programa muestra su mística predicción en la pantalla para que la contemplemos. De lo contrario, se nos entrega un `Left` con el mensaje de error tan claro como el día, aunque todavía escondido en su contenedor. Esto actúa igual que si hubiésemos lanzado un error, pero de una manera más tranquila y suave en lugar de perder los estribos y gritar como un niño cuando algo sale mal.

En este ejemplo, estamos haciendo una bifurcación lógica en nuestro flujo de control dependiendo de la validez de la fecha de cumpleaños, leyéndose en una sola línea de derecha a izquierda en vez de escalar a través de las llaves de una declaración condicional. Normalmente, moveríamos el `console.log` fuera de la función `zoltar` y aplicaríamos `map` al momento de llamarla, pero es útil ver como la rama del `Right` diverge. Para esto usamos `_` en la firma de la rama derecha para indicar que es un valor que debe ser ignorado (En algunos navegadores debes usar `console.log.bind(console)` para usarlo como función de primera clase).

Me gustaría aprovechar esta oportunidad para resaltar algo que podrías haber pasado por alto: `fortune`, a pesar de su uso con `Either` en este ejemplo, es completamente ignorante de cualquier funtor que tenga a su alrededor. Este era también el caso para `finishTransaction` en el ejemplo anterior. En el momento de la llamada, una función puede ser rodeada por `map`, lo que la transforma, en términos informales, de no ser un funtor a serlo. Llamamos a este proceso *levantamiento* (*lifting*). Es mejor que las funciones trabajen con tipos de datos normales que con tipos contenedor, para luego ser levantadas al contenedor apropiado según se considere necesario. Esto conduce a funciones más simples y reutilizables que pueden ser alteradas a demanda para trabajar con cualquier funtor.

`Either` es genial para errores casuales como validaciones y también para casos más graves como archivos faltantes o sockets rotos. Prueba a reemplazar por `Either` alguno de los ejemplos de `Maybe` para obtener un mejor entendimiento.

Por otro lado, no puedo dejar de pensar que le he hecho un flaco favor a `Either` presentándolo como un simple contenedor de mensajes de error. `Either` captura la disyunción lógica (||) en un tipo. También codifica la idea de *Coproducto* de la teoría de categorías, que no se verá en este libro, aunque vale la pena leer sobre ello, ya que contiene varias propiedades a explotar. `Either` es la suma canónica de tipos (o unión disjunta de conjuntos) porque la cantidad total de posibles habitantes es la suma de los dos tipos contenidos (sé que esto suena a magia por lo que acá les entrego un [gran artículo](https://www.schoolofhaskell.com/school/to-infinity-and-beyond/pick-of-the-week/sum-types)). Hay muchas cosas que `Either` puede ser, pero como funtor, se usa por su manejo de errores.

Igual que con `Maybe`, tenemos a la pequeña `either`, que se comporta de manera similar, pero toma dos funciones en lugar de una y un valor estático. Cada función debe devolver el mismo tipo.

```js
// either :: (a -> c) -> (b -> c) -> Either a b -> c
const either = curry((f, g, e) => {
  let result;

  switch (e.constructor) {
    case Left:
      result = f(e.$value);
      break;

    case Right:
      result = g(e.$value);
      break;

    // No Default
  }

  return result;
});

// zoltar :: User -> _
const zoltar = compose(console.log, either(id, fortune), getAge(moment()));

zoltar({ birthDate: '2005-12-12' });
// 'If you survive, you will be 10'
// undefined

zoltar({ birthDate: 'balloons!' });
// 'Birth date could not be parsed'
// undefined
```

Por fin, un uso para esa misteriosa función `id`. Simplemente repite como un loro el valor de `Left` para pasar el mensaje de error a `console.log`. Hemos hecho que nuestra app de videncia sea más robusta imponiendo el manejo de error desde dentro de `getAge`. O bien abofeteamos al usuario con la dura verdad o bien continuamos con nuestro proceso. Y con esto, podemos pasar a otro tipo de funtor completamente diferente. 

## El Viejo McDonald Tenía Efectos...

<img src="images/dominoes.jpg" alt="dominó... necesita una referencia" />

En nuestro capítulo sobre la pureza vimos un peculiar ejemplo de una función pura. Esta función contenía un efecto secundario, pero la convertimos en pura envolviendo su acción en otra función. He aquí otro ejemplo de esto:

```js
// getFromStorage :: String -> (_ -> String)
const getFromStorage = key => () => localStorage[key];
```

Si no hubiéramos rodeado sus entrañas en otra función, `getFromStorage` variaría su salida dependiendo de las circunstancias externas. Con el resistente envoltorio en su sitio, siempre obtendremos la misma salida para cada entrada: una función que, al ser llamada, recuperará un elemento concreto de `localStorage`. Y así, sin más (puede que con algún Ave María) limpiamos nuestra conciencia y todo está perdonado.

Excepto que esto no es particularmente útil. Igual que con una figura de coleccionista en su empaquetado original, no podemos jugar con ella. Si tan solo hubiese una manera de alcanzar el interior del contenedor y tomar su contenido... He aquí `IO`.

```js
class IO {
  static of(x) {
    return new IO(() => x);
  }

  constructor(fn) {
    this.$value = fn;
  }

  map(fn) {
    return new IO(compose(fn, this.$value));
  }

  inspect() {
    return `IO(${inspect(this.$value)})`;
  }
}
```

`IO` se diferencia de los anteriores funtores en que su valor es siempre una función. Sin embargo, no pensemos en su `$value` como una función - esto es un detalle de implementación y mejor lo ignoramos. Lo que sucede es exactamente lo que vimos con el ejemplo de `getFromStorage`: `IO` retrasa la acción impura capturándola en una función envolvente. Como tal, pensamos en `IO` como que contiene el valor devuelto por la acción envuelta y no el envoltorio en sí mismo. Esto es evidente en la función `of`: Tenemos un `IO(x)`, el `IO(() => x)` únicamente es necesario par evitar su evaluación. Nótese que, para simplificar la lectura, mostraremos como resultado el hipotético valor contenido en el `IO`; sin embargo, en la práctica, ¡no se puede saber cuál es este valor hasta que no se hayan desencadenado los efectos! 

Veámoslo en uso:

```js
// ioWindow :: IO Window
const ioWindow = new IO(() => window);

ioWindow.map(win => win.innerWidth);
// IO(1430)

ioWindow
  .map(prop('location'))
  .map(prop('href'))
  .map(split('/'));
// IO(['http:', '', 'localhost:8000', 'blog', 'posts'])


// $ :: String -> IO [DOM]
const $ = selector => new IO(() => document.querySelectorAll(selector));

$('#myDiv').map(head).map(div => div.innerHTML);
// IO('I am some inner html')
```

Aquí, `ioWindow` es un `IO` al que podemos aplicar `map` directamente, mientras que `$` es una función que devuelve un `IO` al ser llamada. He escrito los valores de retorno *conceptuales* para expresar mejor el `IO`, aunque, en realidad, siempre será `{ $value: [Function] }`. Cuando aplicamos `map` sobre nuestro `IO`, ponemos esta función al final de una composición que, a su vez, se convierte en el nuevo `$value` y así sucesivamente. Nuestras funciones mapeadas no se ejecutan, sino que quedan adheridas al final del cálculo que estamos construyendo, función a función, como si cuidadosamente colocáramos fichas de dominó que no nos atrevemos a volcar. El resultado recuerda al patrón comando del Gang of Four o a una cola.

Tómate un momento para trabajar tu intuición sobre los funtores. Si miramos más allá de los detalles de implementación, deberíamos sentirnos como en casa mapeando cualquier contenedor, sin importar sus peculiaridades o idiosincrasias. Tenemos que agradecer este poder pseudopsíquico a las leyes de funtores, las cuales exploraremos hacia el final del capítulo. En cualquier caso, por fin podemos jugar con valores impuros sin sacrificar nuestra preciosa pureza.

Ahora bien, hemos enjaulado a la bestia, pero seguimos teniendo que liberarla en algún momento. Aplicar map sobre nuestro `IO` ha creado una poderosa computación impura y ejecutarla seguramente perturbará la paz. Entonces, ¿dónde y cuándo podemos apretar el gatillo? ¿Es posible ejecutar nuestro `IO` y seguir vistiendo de blanco en nuestra boda? La respuesta es que sí, si le damos la responsabilidad al código que lo llama. Nuestro código puro, a pesar de las nefastas conspiraciones e intrigas, mantiene su inocencia y es quien lo ejecute quien cargará con la responsabilidad de realmente ejecutar los efectos. Veamos un ejemplo para concretar esto:

```js
// url :: IO String
const url = new IO(() => window.location.href);

// toPairs :: String -> [[String]]
const toPairs = compose(map(split('=')), split('&'));

// params :: String -> [[String]]
const params = compose(toPairs, last, split('?'));

// findParam :: String -> IO Maybe [String]
const findParam = key => map(compose(Maybe.of, find(compose(eq(key), head)), params), url);

// -- Código impuro que hace la llamada--------------------------------------

// ejecútala llamando a $value()!
findParam('searchTerm').$value();
// Just(['searchTerm', 'wafflehouse'])
```

Al envolver a `url` en un `IO` y pasar la pelota a quien la llama, nuestra librería mantiene sus manos limpias. También te habrás dado cuenta de que hemos apilado nuestros contenedores; es perfectamente razonable tener un `IO(Maybe([x]))`, que tiene tres funtores de profundidad (`Array` es claramente un contenedor mapeable) y es excepcionalmente expresivo.

Hay algo que ha estado molestándome y que deberíamos rectificar inmediatamente: el `$value` de `IO` realmente no es un valor lo que contiene y tampoco es una propiedad privada. Es el pasador de la granada y está destinado, de la más pública de las maneras, a ser tirado por quien lo llame. Cambiemos el nombre de esta propiedad a `unsafePerformIO` para recordar su volatilidad a nuestros usuarios.

```js
class IO {
  constructor(io) {
    this.unsafePerformIO = io;
  }

  map(fn) {
    return new IO(compose(fn, this.unsafePerformIO));
  }
}
```

Ya está, mucho mejor. Ahora nuestro código de llamada se convierte en `findParam('searchTerm').unsafePerformIO()`, que es claro como el agua para quien use (y lea) nuestra aplicación. 

`IO` será un fiel compañero, ayudándonos a domar esas asilvestradas acciones impuras. A continuación, veremos un tipo similar en espíritu, pero que tiene un caso de uso drásticamente distinto.


## Tareas Asíncronas

Las funciones callbacks son la estrecha escalera de caracol hacia el infierno. Son el control de flujo diseñado por M.C. Escher. Con cada callback anidada que estrujamos entre la jungla de llaves y paréntesis, más se parece a jugar al limbo en una mazmorra (¡¿Cuán bajo podemos llegar?!) Me dan escalofríos claustrofóbicos solo de pensar en ellas. No hay de que preocuparse, tenemos una forma mucho mejor de tratar con código asíncrono y empieza por "F".

Los aspectos internos son demasiado complicados como para derramarlos por toda la página así que utilizaremos `Data.Task` (antes conocido como `Data.Future`) de la fantástica [Folktale](https://folktale.origamitower.com/) de Quildreen Motta. Contempla algunos ejemplos de uso:

```js
// -- Ejemplo con readFile de Node ------------------------------------------

const fs = require('fs');

// readFile :: String -> Task Error String
const readFile = filename => new Task((reject, result) => {
  fs.readFile(filename, (err, data) => (err ? reject(err) : result(data)));
});

readFile('metamorphosis').map(split('\n')).map(head);
// Task('One morning, as Gregor Samsa was waking up from anxious dreams, he discovered that
// in bed he had been changed into a monstrous verminous bug.')


// -- Ejemplo con getJSON de jQuery -----------------------------------------

// getJSON :: String -> {} -> Task Error JSON
const getJSON = curry((url, params) => new Task((reject, result) => {
  $.getJSON(url, params, result).fail(reject);
}));

getJSON('/video', { id: 10 }).map(prop('title'));
// Task('Family Matters ep 15')


// -- Contexto Mínimo por Defecto ----------------------------------------

// También podemos poner adentro valores normales, no futurísticos
Task.of(3).map(three => three + 1);
// Task(4)
```

Las funciones que estoy llamando `reject` y `result` son nuestras callback de error o éxito respectivamente. Como puedes ver, simplemente `map`eamos sobre `Task` para trabajar sobre el valor futuro como si estuviera ahí mismo a nuestro alcance. A estas alturas, `map` ya debería sernos sobradamente familiar.

Si conoces las promesas, puede que reconozcas a la función `map` como `then`, con `Task` haciendo el papel de nuestra promesa. No te preocupes si no conoces las promesas, de todos modos no las usaremos dado que no son puras, pero la analogía igualmente se mantiene.

Al igual que `IO`, `Task` esperará pacientemente a que le demos luz verde antes de ejecutarse. De hecho, dado que espera nuestra orden, `IO` está efectivamente subsumido en `Task` para todas las cosas asíncronas; `readFile` y `getJSON` no requieren un contenedor `IO` adicional para ser puros. Es más, `Task` funciona de manera similar cuando `map`eamos sobre él: estamos colocando instrucciones para el futuro igual que si colocáramos una tabla de tareas en una cápsula del tiempo; un acto de sofisticada procrastinación tecnológica.   

Para ejecutar nuestra tarea [*Task*], debemos llamar al método `fork`. Esto funciona como `unsafePerformIO`, pero como su nombre indica, bifurcará nuestro proceso y la evaluación continuará sin bloquear nuestro hilo de ejecución. Esto puede ser implementado de numerosas maneras con hilos y demás, pero aquí actuará como lo haría una llamada asíncrona normal, así que la gran rueda del bucle de eventos de JavaScript seguirá girando. Echemos un vistazo a `fork`:

```js
// -- Aplicación pura -------------------------------------------------
// blogPage :: Posts -> HTML
const blogPage = Handlebars.compile(blogTemplate);

// renderPage :: Posts -> HTML
const renderPage = compose(blogPage, sortBy(prop('date')));

// blog :: Params -> Task Error HTML
const blog = compose(map(renderPage), getJSON('/posts'));


// -- Código impuro que hace la llamada ----------------------------------------------
blog({}).fork(
  error => $('#error').html(error.message),
  page => $('#main').html(page),
);

$('#spinner').show();
```

Al llamar a `fork`, `Task` se apresura a encontrar algunos posts y renderizar la página. Mientras tanto, mostramos un spinner, ya que `fork` no va a esperar a la respuesta. Finalmente, mostraremos el mensaje de error o renderizaremos la página en la pantalla dependiendo de si la llamada a `getJSON` es exitosa o no. 

Tómate un momento para considerar lo lineal que es nuestro flujo de control aquí. Solo leemos de abajo a arriba y de derecha a izquierda, sin importar que realmente el programa vaya a hacer algunos saltos durante su ejecución. Esto hace que leer y razonar sobre nuestra aplicación sea más sencillo que tener que rebotar entre callbacks y bloques de manejo de errores.

¡Santo cielo, mira eso, `Task` también se ha tragado a `Either`! Lo tiene que hacer para manejar fallos futuros, ya que nuestro flujo de control normal no aplica en el mundo asíncrono. Todo esto está muy bien, puesto que proporciona un manejo de errores suficiente y puro listo para ser utilizado.

Incluso con `Task`, nuestros funtores `IO` y `Either` no se quedan sin trabajo. Acompáñame en un rápido ejemplo que se inclina hacia el lado más complejo e hipotético, pero que es útil para fines ilustrativos: 

```js
// Postgres.connect :: Url -> IO DbConnection
// runQuery :: DbConnection -> ResultSet
// readFile :: String -> Task Error String

// -- Aplicación pura -------------------------------------------------

// dbUrl :: Config -> Either Error Url
const dbUrl = ({ uname, pass, host, db }) => {
  if (uname && pass && host && db) {
    return Either.of(`db:pg://${uname}:${pass}@${host}5432/${db}`);
  }

  return left(Error('Invalid config!'));
};

// connectDb :: Config -> Either Error (IO DbConnection)
const connectDb = compose(map(Postgres.connect), dbUrl);

// getConfig :: Filename -> Task Error (Either Error (IO DbConnection))
const getConfig = compose(map(compose(connectDb, JSON.parse)), readFile);


// -- Código impuro que hace la llamada ----------------------------------------------

getConfig('db.json').fork(
  logErr('couldn\'t read file'),
  either(console.log, map(runQuery)),
);
```

En este ejemplo, todavía hacemos uso de `Either` e `IO` desde la rama exitosa de `readFile`. `Task` se encarga de lo impuro de leer un archivo de manera asíncrona, pero seguimos teniendo que ocuparnos de validar la configuración con `Either` y lidiar con la conexión a la base de datos con `IO`. Así que ya ves, todavía tenemos trabajo para todo tipo de cosas síncronas.

Podría continuar, pero eso es todo. Tan simple como `map`.

En la práctica, es probable que tengas múltiples tareas asíncronas en un solo flujo de trabajo y aún no hemos adquirido todas las API de contenedores como para afrontar este escenario. No te preocupes, pronto veremos cosas sobre mónadas y demás, pero primero debemos examinar las matemáticas que hacen que todo esto sea posible.


## Un Poco de Teoría

Como ya hemos dicho, los funtores proceden de la teoría de categorías y satisfacen una cuantas leyes. Exploremos primero estas útiles propiedades.

```js
// identidad
map(id) === id;

// composición
compose(map(f), map(g)) === map(compose(f, g));
```

La ley de la *identidad* es simple pero importante. Estas leyes son trozos de código ejecutables, por lo que podemos probarlas en nuestros propios funtores para validar su legitimidad. 

```js
const idLaw1 = map(id);
const idLaw2 = id;

idLaw1(Container.of(2)); // Container(2)
idLaw2(Container.of(2)); // Container(2)
```

Como ves son iguales. A continuación veamos la composición.

```js
const compLaw1 = compose(map(append(' world')), map(append(' cruel')));
const compLaw2 = map(compose(append(' world'), append(' cruel')));

compLaw1(Container.of('Goodbye')); // Container('Goodbye cruel world')
compLaw2(Container.of('Goodbye')); // Container('Goodbye cruel world')
```

En teoría de categorías los funtores toman los objetos y morfismos de una categoría y los trasladan a otra categoría distinta. Por definición, esta nueva categoría debe tener una identidad y la capacidad de componer morfismos, pero no tenemos que comprobarlo porque las leyes antes mencionadas aseguran que esto ocurre. 

Tal vez nuestra definición de categoría sea todavía algo confusa. Puedes pensar en una categoría como en una red de objetos conectados entre sí mediante morfismos. Así que un funtor mapearía una categoría a otra sin romper esta red. Si un objeto `a` está en nuestra categoría de origen `C`, cuando lo mapeamos a la categoría `D` con el funtor `F`, nos referimos a ese objeto como `F a`. Tal vez sea mejor ver un diagrama:

<img src="images/catmap.png" alt="Categorías mapeadas" />

Por ejemplo, `Maybe` mapea nuestra categoría de tipos y funciones a una categoría donde cada objeto puede no existir y cada morfismo tiene una comprobación de `null`. Logramos esto en el código rodeando cada función con `map` y cada tipo con nuestro funtor. Sabemos que cada uno de nuestros tipos normales y cada una de nuestras funciones seguirán pudiéndose componer en este nuevo mundo. Técnicamente, cada funtor en nuestro código mapea a una subcategoría de tipos y funciones que hace que todos los funtores sean de un tipo en particular llamado endofuntor, pero para nuestros propósitos consideraremos que son de otra categoría.

Podemos visualizar el mapeo de morfismos y sus correspondientes objetos mediante este diagrama: 

<img src="images/functormap.png" alt="diagrama de funtor" />

Además de visualizar el morfismo mapeado de una categoría a otra bajo el funtor `F`, vemos que el diagrama conmuta, es decir, si se siguen las flechas cada ruta produce el mismo resultado. Las distintas rutas significan diferentes comportamientos, pero siempre acabamos en el mismo tipo. Este formalismo nos permite basarnos en principios a la hora de razonar sobre nuestro código; podemos aplicar fórmulas audazmente sin tener que interpretar y examinar cada escenario individualmente. Veamos esto en un ejemplo concreto:

```js
// topRoute :: String -> Maybe String
const topRoute = compose(Maybe.of, reverse);

// bottomRoute :: String -> Maybe String
const bottomRoute = compose(map(reverse), Maybe.of);

topRoute('hi'); // Just('ih')
bottomRoute('hi'); // Just('ih')
```

O visualmente:

<img src="images/functormapmaybe.png" alt="diagrama de funtor 2" />

Instantáneamente, podemos ver y refactorizar código cuando este está basado en las propiedades que todos los funtores tienen. 

Los funtores pueden apilarse:

```js
const nested = Task.of([Either.of('pillows'), left('no sleep for you')]);

map(map(map(toUpperCase)), nested);
// Task([Right('PILLOWS'), Left('no sleep for you')])
```

Lo que aquí tenemos con `nested` es un futuro array de elementos que pueden ser errores. Aplicamos `map` para pelar cada capa y ejecutar nuestra función en los elementos. No vemos ninguna callback, if/else o bucle for; solo contenido explícito. Sin embargo, tenemos que hacer `map(map(map(f)))`. En lugar de eso podemos componer funtores. Me has oído bien:

```js
class Compose {
  constructor(fgx) {
    this.getCompose = fgx;
  }

  static of(fgx) {
    return new Compose(fgx);
  }

  map(fn) {
    return new Compose(map(map(fn), this.getCompose));
  }
}

const tmd = Task.of(Maybe.of('Rock over London'));

const ctmd = Compose.of(tmd);

const ctmd2 = map(append(', rock on, Chicago'), ctmd);
// Compose(Task(Just('Rock over London, rock on, Chicago')))

ctmd2.getCompose;
// Task(Just('Rock over London, rock on, Chicago'))
```

Ahí lo tienes, un solo `map`. La composición de funtores es asociativa y anteriormente definimos `Container` que en realidad se llama funtor `Identidad`. Si tenemos identidad y composición asociativa tenemos una categoría. Esta categoría en particular tiene categorías como objetos y funtores como morfismos, lo que es suficiente para hacer que a uno le transpire el cerebro. No profundizaremos demasiado en esto, pero es bueno apreciar las implicaciones arquitectónicas o incluso solo la simple belleza abstracta en el patrón.


## En Resumen

Hemos visto unos cuantos funtores distintos, pero hay una infinidad de ellos. Algunas omisiones notables son las estructuras de datos iterables como árboles, listas, mapas, pares, lo que sea. Los event streams [*flujos de eventos*] y los observables son ambos funtores. Otros pueden usarse para encapsular o incluso solo para el modelado de tipos. Los funtores nos rodean y los utilizaremos ampliamente a lo largo del libro. 

¿Qué pasa con la llamada a una función con múltiples funtores como argumentos? ¿Qué hay de trabajar con una secuencia ordenada de acciones impuras o asíncronas? Todavía no hemos adquirido el conjunto completo de herramientas para trabajar en este mundo de cajas. A continuación, iremos al grano y veremos las mónadas.

[Capítulo 09: Cebollas Monádicas](ch09-es.md)

## Ejercicios

{% exercise %}  
Utiliza `add` y `map` para crear una función que incremente el valor de dentro de un funtor.  
  
{% initial src="./exercises/ch08/exercise_a.js#L3;" %}  
```js  
// incrF :: Functor f => f Int -> f Int  
const incrF = undefined;  
```  
  
{% solution src="./exercises/ch08/solution_a.js" %}  
{% validation src="./exercises/ch08/validation_a.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  


---

  
Dado el siguiente objeto User:  
  
```js  
const user = { id: 2, name: 'Albert', active: true };  
```  
  
{% exercise %}  
Utiliza `safeProp` y `head` para encontrar la primera inicial del usuario.  
  
{% initial src="./exercises/ch08/exercise_b.js#L7;" %}  
```js  
// initial :: User -> Maybe String  
const initial = undefined;  
```  
  
{% solution src="./exercises/ch08/solution_b.js" %}  
{% validation src="./exercises/ch08/validation_b.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  


---


Dada la siguiente función de soporte:

```js
// showWelcome :: User -> String
const showWelcome = compose(concat('Welcome '), prop('name'));

// checkActive :: User -> Either String User
const checkActive = function checkActive(user) {
  return user.active
    ? Either.of(user)
    : left('Your account is not active');
};
```

{% exercise %}  
Escribe una función que utilice `checkActive` y `showWelcome` para conceder el acceso o devolver el error.

{% initial src="./exercises/ch08/exercise_c.js#L15;" %}  
```js
// eitherWelcome :: User -> Either String String
const eitherWelcome = undefined;
```


{% solution src="./exercises/ch08/solution_c.js" %}  
{% validation src="./exercises/ch08/validation_c.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  


---


Ahora consideremos las siguientes funciones:

```js
// validateUser :: (User -> Either String ()) -> User -> Either String User
const validateUser = curry((validate, user) => validate(user).map(_ => user));

// save :: User -> IO User
const save = user => new IO(() => ({ ...user, saved: true }));
```

{% exercise %}  
Escribe una función `validateName` que compruebe que el nombre del usuario tiene más de 3 caracteres y si no 
que devuelva un mensaje de error. Luego utiliza `either`, `showWelcome` y `save` para escribir una función `register`
para registrar al usuario y darle la bienvenida cuando la validación sea correcta.

Recuerda que los dos argumentes de either deben devolver el mismo tipo.

{% initial src="./exercises/ch08/exercise_d.js#L15;" %}  
```js
// validateName :: User -> Either String ()
const validateName = undefined;

// register :: User -> IO String
const register = compose(undefined, validateUser(validateName));
```


{% solution src="./exercises/ch08/solution_d.js" %}  
{% validation src="./exercises/ch08/validation_d.js" %}  
{% context src="./exercises/support.js" %}  
{% endexercise %}  
