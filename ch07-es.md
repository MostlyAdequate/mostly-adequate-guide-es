# Hindley-Milner y yo

## ¿Cuál es tu tipo?
Si eres nuevo a la programación funcional, no tomará mucho tiempo en verte perdido en firmas de tipos de datos de las funciones. Los tipos, son el meta lenguaje que permite a cualquier persona de cualquier contexto, comunicarse de manera sucinta y efectiva. En la mayoría de las veces están escritas en un sistema llamado "Hindley-Minler", la cual estaremos examinando en este capítulo.

Cuando trabajamos con funciones puras, las firmas de tipos de datos tienen un poder expresivo, que con el Español (o inglés) no pueden lograr. Estas firmas suspiran al oído los secretos íntimos de la función. En una sola línea, expresan el comportamiento e intención. Podemos derivar "Teoremas Gratis" de ellos. Los tipos también pueden ser inferidos, así que no tienen que ser explícitos con anotaciones de tipo. Pueden ser afinados a lo más granular ó dejarse generales y abstractos. No solo son útiles al momento de compilar, sino que son excelente documentación. Es por lo cual, las firmas de tipos tienen un papel angular en la programación funcional, mucho más de lo que se asume al principio.  

JavaScript es un lenguaje dinámico, pero eso no significa que omita los tipos. Todavía trabajamos, con strings, números, booleanos, y más. Es solo que no hay un integración al nivel del lenguaje que mantega esta información en nuestras cabezas. Sin embargo, si usamos las firmas como documentación, podemos usar comentarios para evitar este problema.

Existen herramientas para chequear los tipos en JavaScript cómo [Flow](http://flowtype.org/) ó el dialecto tipado [TypeScript](http://www.typescriptlang.org/).


## Historias del más allá

Desde lás páginas empolvadas de los libros de matemática, por un oceano de papers académicos, pasando por blog post casuales de domingo en la mañana, hasta en los anales del código base, vamos a toparnos con firmas de Hindley-Milner. El sistema es bien sencillo, pero requiere una explicación sencilla y un poco de práctica para absorber completamente este lenguaje.

```js
//  capitalize :: String -> String
var capitalize = function(s){
  return toUpperCase(head(s)) + toLowerCase(tail(s));
}

capitalize("smurf");
//=> "Smurf"
```

Acá, `capitalize` recibe un `String` y retorna un `String`. Por ahora no nos importa la implementación, es la firma de tipos que nos interesa.

En HM, las funciones se escriben como `a -> b` dónde `a` y `b` son variables de cualquier tipo. Entonces las firma para `capitalize` se puede leer como "una función de `String` a `String`". Ó en otras palabras, toma un `String` cómo parámetro inicial y retorna un `String` como salida.

Revisemos otras firmas de funciones:

```js
//  strLength :: String -> Number
var strLength = function(s){
  return s.length;
}

//  join :: String -> [String] -> String
var join = curry(function(what, xs){
  return xs.join(what);
});

//  match :: Regex -> String -> [String]
var match = curry(function(reg, s){
  return s.match(reg);
});

//  replace :: Regex -> String -> String -> String
var replace = curry(function(reg, sub, s){
  return s.replace(reg, sub);
});
```

`strLength` tiene la misma idea que la firma anterior: Recibe un `String` y retorna un `Number`.

Las otras firmas, pueden parecer más complejas a primera vista. Sin entrar en detalles de la implementación, siempre podríamos comenzar a ver el tipo que retorna la función. Entonces para `match` podemos interpretarla como: Toma un `Regex` y un `String` y retorna `[String]`. Pero, hay algo interesante ocurriendo acá que me gustaría tomar un tiempo para explicar. 

Para `match` podemos agrupar las firmas como queramos:

```js
//  match :: Regex -> (String -> [String])
var match = curry(function(reg, s){
  return s.match(reg);
});
```

Ajá!, agrupando la última parte en paréntesis revela más información. Ahora, leemos que es una función que recibe un `Regex` y retorna una función que va de `String` a `[String]`. Gracias al Currying, este es claramente el caso: Le entregamos un `Regex` y nos entrega una función de regreso que espera él parámetro `String`. Claro, no necesariamente tenemos que interpretarla de esta manera. Pero, es una buena manera de entender porqué el último tipo es el que retorna.

```js
//  match :: Regex -> (String -> [String])

//  onHoliday :: String -> [String]
var onHoliday = match(/holiday/ig);
```

Cada argumento pasa un tipo en frente de la firma. `onHoliday` y `match` tiene ya un `Regex`.

```js
//  replace :: Regex -> (String -> (String -> String))
var replace = curry(function(reg, sub, s){
  return s.replace(reg, sub);
});
```

Cómo se puede ver en el paréntesis más grande de `replase`, la notación extra puede volverse ruidosa y redundante, así que simplemente la omitiremos. Podemos entregarle todos los argumentos al tiempo si decidiéramos hacerlo ya que es más simple razonar la como: `replace` toma como argumentos un `Regex`, un `String`, otro `String`, y retorna un `String`.

Unas cosas sin embargo a mencionar acá:


```js
//  id :: a -> a
var id = function(x){ return x; }

//  map :: (a -> b) -> [a] -> [b]
var map = curry(function(f, xs){
  return xs.map(f);
});
```

La función `id` toma cualquier dato del tipo `a` y retorna algo del mismo tipo `a`. Podemos usar las variables en los tipos, así como lo hacemos en el código. Variables como `a` y `b` son convenciones, pero son arbitrarias y pueden ser remplazadas con cualquier cosa que queramos. Si son la misma variable, tienen que ser del mismo tipo. Esta es una regla que vale la pena reiterar, `a -> b` pueden ser cualquier tipo `a` y `b`, pero ` a -> a` significa que tienen que ser del mismo tipo. Por ejemplo, `id` puede ser `String -> String` ó `Number -> Number`, pero no `String -> Bool`.

`map` al igual, usa tipos variables, pero esta vez introducimos `b` que puede ó no ser del mismo tipo que `a`. Podemos entonces leer la función como: `map` toma cualquier tipo `a` para retornar el mismo o diferente tipo `b`, luego toma un array de `a`s para retornar un array de `b`s.

Ojalá, el lector haya sido agobiado por la belleza de este sistema de firma. Nos dice, de manera literal, qué está pasando en la función paso por paso. Nos dice que una función que va de `a` a `b`, un array de `a` nos devuelve un array de `b`. A este punto lo único sensible para hacer, si no se cree en la firma, es ejecutar la función. 

Ser capaces de razonar acerca de los tipos y sus implicaciones es una habilidad que nos llevará muy lejos en el mundo de la programación funcional. No solo papers académicos, blogs, documentación se volverá más digerible, pero la firma prácticamente nos dira a los oídos su funcionalidad. Toma práctica convertirse en un lector ávido, pero si se es perseverante, cantidades infinitas de información será ahora accesible sin necesidad de leer todo el manual (RTFMing de sus siglas en inglés).

Acá hay otros ejemplos para que el lector busque descifraras

```js
//  head :: [a] -> a
var head = function(xs){ return xs[0]; }

//  filter :: (a -> Bool) -> [a] -> [a]
var filter = curry(function(f, xs){
  return xs.filter(f);
});

//  reduce :: (b -> a -> b) -> b -> [a] -> b
var reduce = curry(function(f, x, xs){
  return xs.reduce(f, x);
});
```
`reduce` es deporto, la más expresiva de todas. Es la más engañosa, sin embargo, no debe sintiese mal al no poder interpretarla del todo. Para los curiosos, intentaré hacer una explicación en Español para el ciudadano de a pie, claro está, hacer este ejercicio por su propia cuenta resultará aún más instructivo.

Revisando la firma, vemos que el primer argumento es una función que espera un `b` y una `a` y retorna un `b`. De dónde tomará todas las `a`s y `b`s? Bueno, el siguiente argumento de la función es `b`, y un array de `a`, por lo que podemos asumir de que `b` y cada uno de los `a` serán inyectados a la función. También podemos ver que el resultado de la función es `b`, entonces nuestra conclusión es que esto es lo que será parte de nuestro valor de salida. Ahora, conociendo lo que `reduce` hace, podemos decir que la investigación es correcta. 

## Limitando las posibilidades

Una vez una variable de tipo es introducida, una propiedad curiosa emerge llamada *parametricidad*[^http://en.wikipedia.org/wiki/Parametricity]. Esta propiedad dice que una función actuará *en todos los tipos de manera uniforme*. Investiguemos:

```js
// head :: [a] -> a
```

Mirando a `head`, podemos ver que toma `[a]` y retorna `a`. Aparte de el tipo concreto de `array`, no tenemos mas información disponible, por lo que su funcionalidad está limitada a trabajar con el array únicamente. ¿Qué podría hacer la función con la variable `a` si no sabe nada de ella? en otras palabras, `a` dice que no puede ser un tipo *específico*, lo que significa que puede ser *cualquier* tipo, lo que nos deja con una función que debe funcionar de manera uniforme para *cada* tipo concebible. Esto es lo que *parametricidad* significa. Adivinando, podemos asumir que toma el primer, último o algún elemento aleatorio del array y lo retorna, ahora la palabra `head` (cabeza) debería de darnos la última pista.

Acá tenemos otro:

```js
// reverse :: [a] -> [a]
```

De la firma de tipos sola, que podríamos inferir de ¿`reverse` (reversa)?. De nuevo, no puede ser nada específico a `a`. No puede cambiar `a` a otro tipo o de lo contrario tendríamos que introducir el tipo `b` en la firma. Puede hacer un `sort` (ordenar), bueno, no tiene la suficiente información para ejecutar esa acción. ¿Puede reorganizar los elementos? Sí, se podría asumir esto, pero tendría que hacerlo siempre de la misma manera. Otra posibilidad es que pueda decidir remover ó duplicar elementos. Cualquiera sea el caso, el punto es que comportamiento se puede reducir considerablemente solo por su tipo polifórmico.


Esta reducción de posibilidades nos permite el uso de buscadores de funciones a través de las firmas como por ejemplo [Hoogle](https://www.haskell.org/hoogle) para encontrar las funciones que queremos implementar. La información que se entrega en la firma es de verdad muy poderosa. 

## Teoremas gratis

Además de deducir posiblidades de implementación, este tipo de razonamiento nos entregan *teoremas gratis*. Lo que sigue en este capítulo son unas ejemplos aleatorios, extraídos directamente del [paper académico de Wadler](http://ttic.uchicago.edu/~dreyer/course/papers/wadler.pdf).

```js
// head :: [a] -> a
compose(f, head) == compose(head, map(f));

// filter :: (a -> Bool) -> [a] -> [a]
compose(map(f), filter(compose(p, f))) == compose(filter(p), map(f));
```

No se necesita saber código para obtener estos teoremas directamente de los tipos. El primero dice que si obtenemos `head` de nuestro array y luego corremos la función `f` en el, es equivalente, y de paso, mucho más rápido que, sí primero hacemos `map(f)` sobre cada elemento y luego tomamos `head` a el resultado.

Se pensarían: Por supuesto, esto es sentido común. Pero la última vez que se revisó, los computadores no tienen sentido común. En efecto, los computadores deben tener una manera formalizada para automatizar este tipo de optimizaciones de código. Las matemáticas tienen una manera de formalizar lo intuitivo, lo que es muy beneficioso en medio del terreno de la lógica computacional. 

El teorema `filter` es similar. Dice que si componemos `f` y `p` para revisar cual debería ser filtrado, entonces realmente aplicando la función `f` via `map` (recordando: filter, no transforma los elementos, su firma de tipos, dice que `a` no será tocado), lo anterior es equivalente a mapear nuestros `f` y luego filtrar los resultados aplicando el predicado.


Estos son solo dos ejemplos, pero uno puede aplicar este razonamiento a cualquier firma polifórmica y esto se mantendrá. En JavaScript, hay unas herramientas disponibles para reesrcrbir reglas. Uno pesaría que se puede hacer a través de la función `compose`. Realmente este es la manera más fácil de hacerlo y las posibilidades son infinitas. 


## Limitantes

La ultima cosa a anotar es que tenemos limitantes de tipos en una interface.

```js
// sort :: Ord a => [a] -> [a]
```

Lo que se ve a la izquierda de nuestra función flecha es la declaración de hecho: `a` debe ser de tipo `Ord`. Ó en otras palabras, `a` debe implementar la interfase `Ord`. ¿Qué es `Ord` y de dónde viene? En un lenguaje de tipos sería una interface declarada que dice que están compuesta, Esto no solo nos dice más acerca de `a` y de nuestra función `sort`, sino que también nos restringe el dominio. Llamamos a estas declaraciones de interface *limitaciones de tipo*.

```js
// assertEqual :: (Eq a, Show a) => a -> a -> Assertion
```

Acá, tenemos dos limitantes: `Eq` y `Show`. Estas asegurarán que podamos revisar la igualdad de nuestros `a` e imprimir la diferencia si no son iguales. 

Verémos más ejemplos de las limitantes de tipo, esta idea tomará vuelo en los siguientes capítulos.

## En Conclusión

Las firmas de tipo Hindley-Milner son oblicuas en los lenguajes funcionales. Aunque sean simples de leer y de escribir, toma tiempo en dominar la técnica para entender programas basados solo en sus firmas. De ahora en adelante pondremos firmas de tipos a cada función en lo restante del libro. 

[Chapter 8: Tupperware](ch8-es.md)
