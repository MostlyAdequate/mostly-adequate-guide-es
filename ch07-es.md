# Capítulo 07: Hindley-Milner y Yo

## ¿Cuál Es Tu Tipo?
Si tu llegada al mundo funcional es reciente, no tardarás en verte de firmas de tipo hasta las rodillas. Los tipos son el meta lenguaje que permite a personas de todos los ámbitos comunicarse de forma sucinta y eficaz. La mayoría de las veces están escritas en un sistema llamado "Hindley-Milner" que examinaremos juntos en este capítulo.

Cuando trabajamos con funciones puras, las firmas de tipo tienen un poder expresivo que el inglés no puede lograr [*ni el español*]. Estas firmas te susurran al oído los íntimos secretos de una función. En una única y compacta línea exponen comportamiento e intención. Podemos derivar "teoremas gratuitos" de ellas. Los tipos pueden ser inferidos, así que no hay necesidad de anotaciones de tipo explícitas. Pueden afinarse al detalle o dejarse como algo general y abstracto. No solo son útiles para comprobaciones en tiempo de compilación, sino que resultan ser la mejor documentación posible disponible. Las firmas de tipos juegan, por tanto, un papel importante en la programación funcional; mucho más de lo que cabría esperar en un principio.  

JavaScript es un lenguaje dinámico, pero eso no significa que evitemos los tipos por completo. Seguimos trabajando con strings, números, booleanos, etc. Es solo que no hay una integración a nivel de lenguaje, por lo que mantenemos esta información en nuestras cabezas. No hay de que preocuparse, podemos utilizar comentarios para servir a nuestro propósito dado que usamos las firmas como documentación.

Existen herramientas de comprobación de tipos para JavaScript como [Flow](https://flow.org/) o el dialecto con tipos, [TypeScript](https://www.typescriptlang.org/). La finalidad de este libro es equiparnos con las herramientas para escribir código funcional, así que nos quedaremos con el sistema de tipos estándar utilizado en muchos lenguajes de programación funcional.


## Cuentos De Lo Críptico

Desde las polvorientas páginas de los libros de matemáticas, a través del vasto océano de papers académicos, entre publicaciones informales de blogs un sábado por la mañana, hasta en el propio código fuente, encontramos firmas de tipos de Hindley-Milner. El sistema es bien sencillo, pero merece una rápida explicación y algo de práctica para absorber completamente el pequeño lenguaje.

```js
// capitalize :: String -> String
const capitalize = s => toUpperCase(head(s)) + toLowerCase(tail(s));

capitalize('smurf'); // 'Smurf'
```

Aquí, `capitalize` recibe un `String` y retorna un `String`. No importa la implementación, es la firma de tipos lo que nos interesa.

En HM, las funciones se escriben como `a -> b` dónde `a` y `b` son variables de cualquier tipo. Así que la firma para `capitalize` se puede leer como "una función de `String` a `String`". En otras palabras, toma un `String` como entrada y retorna un `String` como salida.

Veamos otras firmas de funciones:

```js
// strLength :: String -> Number
const strLength = s => s.length;

// join :: String -> [String] -> String
const join = curry((what, xs) => xs.join(what));

// match :: Regex -> String -> [String]
const match = curry((reg, s) => s.match(reg));

// replace :: Regex -> String -> String -> String
const replace = curry((reg, sub, s) => s.replace(reg, sub));
```

`strLength` es la misma idea que antes: tomamos un `String` y te retorna un `Number`.

Las otras pueden dejarte perplejo en un principio. Sin entender del todo los detalles, siempre puedes ver al último tipo como el valor de retorno. Así que podemos interpretar `match` como: Toma un `Regex` y un `String` y te devuelve `[String]`. Pero una cosa interesante ocurre aquí y me gustaría tomarme un tiempo para explicarla, si se me permite. 

Para `match` podemos agrupar las firmas como queramos:

```js
// match :: Regex -> (String -> [String])
const match = curry((reg, s) => s.match(reg));
```

Ah si, agrupar la última parte con paréntesis revela más información. Ahora se ve como una función que toma un `Regex` y nos devuelve una función de `String` a `[String]`. Gracias al currying, este es claramente el caso: Le entregamos un `Regex` y obtenemos de vuelta una función que espera su argumento `String`. Por supuesto, no tenemos que verlo así, pero es una buena forma de entender por qué el último tipo es el que se devuelve.

```js
// match :: Regex -> (String -> [String])
// onHoliday :: String -> [String]
const onHoliday = match(/holiday/ig);
```

Cada argumento hace saltar un tipo de delante de la firma. `onHoliday` es `match` que ya tiene un `Regex`.

```js
// replace :: Regex -> (String -> (String -> String))
const replace = curry((reg, sub, s) => s.replace(reg, sub));
```

Como puedes ver en los paréntesis de `replace`, la notación extra puede ser algo ruidosa y redundante así que simplemente la omitimos. Podemos entregarle todos los argumentos a la vez si lo deseamos, así que es más fácil pensar en ello como: `replace` toma un `Regex`, un `String`, otro `String`, y te devuelve un `String`.

Unas últimas cosas:


```js
// id :: a -> a
const id = x => x;

// map :: (a -> b) -> [a] -> [b]
const map = curry((f, xs) => xs.map(f));
```

La función `id` toma cualquier tipo `a` y devuelve algo del mismo tipo `a`. Podemos usar variables en los tipos, igual que en el código. Los nombres de las variables como `a` y `b` son una convención, pero son arbitrarios y pueden ser reemplazados por el nombre que prefieras. Si son la misma variable, tienen que ser del mismo tipo. Esta es una regla importante así que vamos a repetirnos: `a -> b` puede ser cualquier tipo `a` a cualquier tipo `b`, pero ` a -> a` significa que tienen que ser del mismo tipo. Por ejemplo, `id` puede ser `String -> String` o `Number -> Number`, pero no `String -> Bool`.

`map` usa variables de tipos de forma parecida, pero esta vez introducimos `b` que puede ser del mismo tipo que `a` o no. Podemos leerla como: `map` toma una función de cualquier tipo `a` al mismo o distinto tipo `b`, luego toma un array de `a`s y devuelve un array de `b`s.

Ojalá te hayas dejado llevar por la belleza expresiva de esta firma de tipos. Nos dice literalmente lo que hace la función casi palabra por palabra. Se le da una función de `a` a `b`, un array de `a`, y nos entrega un array de `b`. Lo único sensato que puede hacer es llamar a la maldita función para cada `a`. Cualquier otra cosa sería una mentira descarada. 

Ser capaz de razonar sobre los tipos y sus implicaciones es una habilidad que te llevará lejos en el mundo funcional. No solo los artículos académicos, blogs, documentación, etcétera, se volverán más digeribles, sino que la propia firma prácticamente te enseñará su funcionalidad. Lleva práctica ganar fluidez lectora, pero si perseveras, un montón de información se volverá accesible para ti sin necesidad de leer todo el manual.

Aquí hay algunas más para ver si puedes descifrarlas por ti mismo.

```js
// head :: [a] -> a
const head = xs => xs[0];

// filter :: (a -> Bool) -> [a] -> [a]
const filter = curry((f, xs) => xs.filter(f));

// reduce :: ((b, a) -> b) -> b -> [a] -> b
const reduce = curry((f, x, xs) => xs.reduce(f, x));
```

`reduce` quizás sea la más expresiva de todas. Sin embargo, es difícil, así que no te sientas mal si te cuesta entenderla. Para los curiosos, intentaré hacer una explicación en castellano, aunque estudiar la firma por tu cuenta es mucho más instructivo.

Ejem, aquí va mi intento... revisando la firma, vemos que el primer argumento es una función que espera un tipo `b` y un tipo `a` y produce un `b`. ¿De dónde tomará todos esos `a`s y `b`s? Bueno, los siguientes argumentos en la firma son un `b`, y un array de `a`, por lo que solo podemos asumir que `b` y cada `a` serán inyectados a la función. También podemos ver que el resultado de la función es `b`, por lo que la conclusión será que el último hechizo de la función que hemos pasado será nuestro valor de salida. Conociendo lo que hace `reduce`, podemos afirmar que la investigación anterior es correcta. 

## Reduciendo las Posibilidades

Una vez que se introduce una variable de tipo, surge una curiosa propiedad llamada *[parametricidad](http://en.wikipedia.org/wiki/Parametricity)*. Esta propiedad establece que una función *actuará en todos los tipos de manera uniforme*. Investiguemos:

```js
// head :: [a] -> a
```

Observando `head`, vemos que toma `[a]` y retorna `a`. Aparte del tipo concreto `array`, no dispone de más información, y, por lo tanto, su funcionalidad se limita a trabajar solamente con el array. ¿Qué podría hacer con la variable `a` si no sabe nada de ella? En otras palabras, `a` dice que no puede ser un tipo *específico*, lo que significa que puede ser *cualquier* tipo, lo que nos deja con una función que debe funcionar de manera uniforme para *todos* los tipos concebibles. Esto es todo en lo que consiste la *parametricidad*. Adivinando la implementación, las únicas suposiciones razonables son que toma el primer, el último o un elemento aleatorio del array. El nombre `head` [*cabeza*] debería servirnos de pista.

He aquí otra más:

```js
// reverse :: [a] -> [a]
```

De la firma de tipos por sí sola, ¿qué podríamos inferir de `reverse`? De nuevo, no puede hacer nada específico a `a`. No puede cambiar `a` a otro tipo o tendríamos que introducir el tipo `b`. ¿Puede ordenar? Bueno, no, no tendría suficiente información para ordenar todos los tipos posibles. ¿Puede reordenar? Sí, supongo que puede hacerlo, pero siempre tendría que hacerlo exactamente de la misma y predecible forma. Otra posibilidad es que decida eliminar o duplicar un elemento. En cualquier caso, la cuestión es que el posible comportamiento se ve masivamente reducido por su tipo polimórfico.


Esta reducción de posibilidades nos permite utilizar buscadores de firmas de tipos como [Hoogle](https://hoogle.haskell.org/) para encontrar la función que estamos buscando. La información contenida en una firma es, en efecto, muy poderosa. 

## Teoremas Gratuitos

Además de deducir posibilidades de implementación, este tipo de razonamiento nos proporciona *teoremas gratuitamente*. Lo que sigue son algunos teoremas de ejemplo extraídos aleatoria y directamente del [artículo académico de Wadler sobre el tema](http://ttic.uchicago.edu/~dreyer/course/papers/wadler.pdf).

```js
// head :: [a] -> a
compose(f, head) === compose(head, map(f));

// filter :: (a -> Bool) -> [a] -> [a]
compose(map(f), filter(compose(p, f))) === compose(filter(p), map(f));
```

No necesitas ningún código para entender estos teoremas, se deducen directamente de los tipos. El primero dice que obtener el primer elemento del array con `head` y luego ejecutar una función `f` sobre él, es equivalente y de paso mucho más rápido que primero aplicar `f` sobre cada elemento mediante `map`  y luego aplicar `head` sobre el resultado.

Podrías pensar, bueno, eso es de sentido común. Pero la última vez que lo comprobé, los ordenadores no tenían sentido común. De hecho, han de tener una manera formal de automatizar este tipo de optimizaciones de código. Las matemáticas tienen una manera de formalizar lo intuitivo, lo cual es muy útil en medio del rígido terreno de la lógica computacional. 

El teorema `filter` es parecido. Dice que si componemos `f` y `p` para comprobar cuál debe ser filtrado, y luego aplicamos `f` via `map` (recuerda que `filter` no transformará a los elementos; su firma dice que `a` no será tocado), siempre será equivalente a mapear nuestra `f` y luego filtrar el resultado con el predicado `p`.

Estos son solo dos ejemplos, pero puedes aplicar este razonamiento a cualquier firma de tipos polimórficos y siempre se mantendrá. En JavaScript, hay disponibles algunas herramientas para declarar reglas de reescritura. También se podría hacer a través de la propia función `compose`. La fruta está al alcance de la mano y las posibilidades son infinitas. 


## Restricciones

Una última cosa a tener en cuenta es que podemos restringir los tipos a una interfaz.

```js
// sort :: Ord a => [a] -> [a]
```

Lo que vemos en el lado izquierdo de nuestra función flecha es la declaración de un hecho: `a` debe ser un `Ord`. O en otras palabras, `a` debe implementar la interfaz `Ord`. ¿Qué es `Ord` y de dónde viene? En un lenguaje con tipos sería una interfaz definida que dice que podemos ordenar los valores. Esto no solo nos dice más acerca de `a` y lo que nuestra función `sort` hace, sino que también restringe el dominio. Llamamos *restricciones de tipo* a estas declaraciones de interfaz.

```js
// assertEqual :: (Eq a, Show a) => a -> a -> Assertion
```

Aquí, tenemos dos restricciones: `Eq` y `Show`. Así podremos comprobar la igualdad de nuestras `a`s e imprimir la diferencia si no son iguales. 

Veremos más ejemplos de restricciones y la idea debería coger más forma en capítulos posteriores.

## En Resumen

Las firmas de tipo Hindley-Milner son omnipresentes en el mundo funcional. Aunque son sencillas de leer y escribir, lleva tiempo dominar la técnica de entender los programas tan solo a través de sus firmas. A partir de ahora añadiremos firmas de tipo a cada línea de código. 

[Capítulo 8: Tupperware](ch08-es.md)
