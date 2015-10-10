# Capitulo 3: Pura Felicidad con Funciones Puras

## Oh ser puro otra vez

Una cosa que necesitamos para comenzar correctamente es la idea de una función pura.

>Una función pura es una función que, dada la misma entrada, siempre devolverá la misma salida y no contiene ningún efecto secundario observable.

Por ejemplo `slice` y `splice`. Son dos funciones que hacen exactamente lo mismo - de una forma muy diferente, pero lo mismo al fin y al cabo. Decimos que `slice` es *pura* porque devuelve la misma salida para cada entrada cada vez, garantizado. `splice`, sin embargo, se comerá su array y lo escupirá cambiado permanentemente, que es un efecto observable.

```js
var xs = [1,2,3,4,5];

// pure
xs.slice(0,3);
//=> [1,2,3]

xs.slice(0,3);
//=> [1,2,3]

xs.slice(0,3);
//=> [1,2,3]


// impura
xs.splice(0,3);
//=> [1,2,3]

xs.splice(0,3);
//=> [4,5]

xs.splice(0,3);
//=> []
```

En programación funcional, no nos gustan las funciones inmanejables como `splice` que mutan datos. Esto nunca valdrá ya que estamos luchando por tener funciones confiables que devuelven la misma salida cada vez, no funciones que hacen un desastre tras su paso como `splice`.

Veamos otro ejemplo.

```js
// impura
var minimum = 21;

var checkAge = function(age) {
  return age >= minimum;
};



// pura
var checkAge = function(age) {
  var minimum = 21;
  return age >= minimum;
};
```

En la parte impura, `checkAge` depende de la variable mutable `minumun` para determinar el resultado. En otras palabras, depende del estado del sistema, lo que es decepcionante porque incremente la carga cognitiva a través de la introducción de un entorno externo.

Puede que no parezca mucho en este ejemplo, pero esta dependencia sobre estado es una de las mayores contribuciones a la complejidad del sistema[^http://www.curtclifton.net/storage/papers/MoseleyMarks06a.pdf]. Esta `checkAge` puede devolver un resultado diferente dependiendo de factores externos a la entrada, lo que no solo la descalifica como pura, sino que también nos obliga a esforzarnos mentalmente cada vez que razonamos acerca del software.

Por otro lado, su forma pura, es completamente auto suficiente. También podemos hacer que  `minimun` sea inmutable, y que preserve la pureza ya que el estado nunca cambia. Para hacer esto, debemos crear un objeto "congelado" (freeze).

```js
var immutableState = Object.freeze({
  minimum: 21
});
```

## Los efectos secundarios puede incluir... 

Miremos un poco mas estos "efectos secundarios" para mejorar nuestra intuición. ¿Entonces, que es este indudablemente nefasto "efecto secundario" mencionado en la definición de *función pura*? Nos referiremos a *efecto* como cualquier cosa que ocurra en nuestra nuestro computación ademas del calculo de un resultado.

No hay nada intrínsecamente malo acerca de los efectos y lo usaremos por todos lados en futuros capítulos. Es la parte *secundaria* la que tiene connotaciones negativas. El agua por si misma no es inherentemente una incubadora de larvas, es el *estancamiento* lo que produce los enjambres, y os aseguro, los efectos *secundarios* son un criadero similar en vuestros propios programas.

>Un *efecto secundario* es un cambio de estado del sistema o una *interacción observable* con el mundo exterior que ocurre durante el calculo de un resultado. 

Los efectos secundarios pueden incluir, pero no limitarse a

  * cambios en el sistema de ficheros
  * insertar un registro en una base de datos
  * hacer llamadas http
  * mutaciones
  * imprimir en la pantalla / loguear
  * obtener entrada del usuario
  * consultar el DOM
  * acceder el estado del sistema
  
Y el listado sigue y sigue. Cualquier interacción con el mundo exterior de una función es un efecto secundario, lo que es un echo que puede llevar a sospechar de la practicidad de programar sin ellos. La filosofía de la programación funcional postula que los efectos secundarios son la causa principal de comportamientos incorrectos.

No es que tengamos prohibidos usarlos, mas bien queremos contenerlos y ejecutarlos de manera controlada. Aprenderemos como hacerlo cuando lleguemos a los functors y monads en capítulos posteriores, pero por ahora, trataremos de mantener estas funciones insidiosas apartadas de nuestras funciones puras.

Los efectos secundarios descalifican a una función de ser *pura* y tiene sentido: las funciones puras, por definición, deben devolver siempre la misma salida dada la misma entrada, lo que no es posible de garantizar cuando se esta lidiando con asuntos fuera de nuestra función local.

Echemos una mirada mas de cerca a porque insistimos en la misma salida por entrada. Atentos, vamos a ver matemática de octavo grado. 


## Matemática de octavo grado

De mathisfun.com:

> Una función es una relación especial entre valores: 
> Cada valor de su entrada devuelve exactamente un valor de salida.

En otras palabras, es solo una relación entre dos valores: la entrada y la salida. Aunque cada entrada tiene exactamente una salida, esa salida no tiene que ser necesariamente única por entrada. El siguiente diagrama muestra un función perfectamente valida de `x` a `y`;

<img src="images/function-sets.gif" />[^http://www.mathsisfun.com/sets/function.html]

Para contrastar, el siguiente diagrama muestra una relación que *no* es una función ya que el valor de entrada `5` apunta a diferentes salidas: 

<img src="images/relation-not-function.gif" />[^http://www.mathsisfun.com/sets/function.html]

Las funciones pueden ser descritas como un set de pares con su posicion (entrada, salida): `[(1,2), (3,6), (5,10)]`[^Parece que esta función dobla su entrada].

O tal vez una tabla: 
<table> <tr> <th>Entrada</th> <th>Salida</th> </tr> <tr> <td>1</td> <td>2</td> </tr> <tr> <td>2</td> <td>4</td> </tr> <tr> <td>3</td> <td>6</td> </tr> </table>

O incluso como un gráfico con `x` como la entrada e `y` como la salida:

<img src="images/fn_graph.png" width="300" height="300" />

No hay necesidad de los detalles de implementación si la entrada dicta la salida. Ya que las funciones son simplemente mapeos de entradas a salida, uno puede simplemente apuntar los valores en objetos y ejecutarlos con `[]` en lugar de `()`.

```js
var toLowerCase = {"A":"a", "B": "b", "C": "c", "D": "d", "E": "e", "D": "d"};

toLowerCase["C"];
//=> "c"

var isPrime = {1:false, 2: true, 3: true, 4: false, 5: true, 6:false};

isPrime[3];
//=> true
```

Por supuesto, puedes querer calcular en lugar de apuntar valores, pero esto ilustra una forma diferente de pensar acerca de funciones. [^Debes estar pensando "que pasa con las funciones con múltiples paramentos?". Ciertamente, eso presenta un pequeño inconveniente cuando se piensa en términos matemáticos. Por ahora, podemos empaquetarlos en un array o simplemente pensar en ellos como el objeto `argumento` como la entrada. Cuando aprendamos sobre *currying*, veremos como podemos modelar directamente la definición de una función.]

Aquí viene la revelación dramática: Las funciones puras *son* funciones matemáticas y son todo sobre lo que trata la programación funcional. Programar con estos pequeños angeles puede tener grandes beneficios. Observemos algunas razones de porque estamos dispuestos a recorrer grandes distancias para preservar la pureza.

## Los argumentos de la pureza

### Almacenable en cache

Para empezar, las funciones puras siempre pueden tener un cache por entrada. Esto se hace típicamente con una técnica llamada memoización: 

```js
var squareNumber  = memoize(function(x){ return x*x; });

squareNumber(4);
//=> 16

squareNumber(4); // returns cache for input 4
//=> 16

squareNumber(5);
//=> 25

squareNumber(5); // returns cache for input 5
//=> 25
```

Aquí hay una implementación simplificada, aunque haya disponibles muchas implementaciones mas robustas.

```js
var memoize = function(f) {
  var cache = {};

  return function() {
    var arg_str = JSON.stringify(arguments);
    cache[arg_str] = cache[arg_str] || f.apply(f, arguments);
    return cache[arg_str];
  };
};
```

Algo a tener en cuenta es que se puede transformar funciones impuras en puras al retrasar su evaluación: 

```js
var pureHttpCall = memoize(function(url, params){
  return function() { return $.getJSON(url, params); }
});
```

Lo interesante aquí es que realmente no hacemos la llamada http - en su lugar devolvemos una función que lo hará cuando sea llamada. Esta función es pura porque siempre devolverá la misma salida dada la misma entrada: la función que hará en particular esa llamada dada la `url` y `params`. 

Nuestra función `memoize` funciona bien, aunque no guarda en cache los resultados de la llamada http, mas bien guarda en cache la función generada.

Esto todavía no es muy útil, pero pronto aprenderemos algunos trucos que harán que lo sea. La lección es que podemos guardar en cache cada función sin importar cuan destructivas parezcan.

### Portables / Auto-documentadas

Las funciones puras son completamente auto contenidas. Todo lo que la función necesita se le pasa en bandeja de plata. Considera esto por un momento... Como puede esto ser beneficioso? Para empezar, las dependencias de la funcion son explicitas, por lo tanto mas fácilmente de ver y entender - ningún cosa rara por detrás.

```js
//impure
var signUp = function(attrs) {
  var user = saveUser(attrs);
  welcomeUser(user);
};

//pure
var signUp = function(Db, Email, attrs) {
  return function() {
    var user = saveUser(Db, attrs);
    welcomeUser(Email, user);
  };
};
```

Este ejemplo demuestra que la función pura debe ser honesta acerca de sus dependencias y, como tal, debe decirnos exactamente que hace. Solo por su firma, sabemos que usará una `Db`, `Email`, and `attrs` y ya es algo interesante al menos.

Aprenderemos como hacer funciones puras como esta sin mas que aplazar la evaluación, pero debería quedar claro que la forma pura es mucho mas informativa que su astuta contraparte que trama Dios sabe que.

Algo mas a tener en cuenta es que estamos forzados a "inyectar" dependencias, o pasarlas como argumentos, lo que hace que nuestra aplicación mas flexible porque hemos parametrizado nuestra base de datos o cliente de email o lo que sea[^No te preocupes, veremos una forma menos tedioso de lo que suena]. Si decidimos usar una Db diferente solo debemos llamar nuestra función con ella. Si nos encontramos escribiendo una nueva aplicación en la que nos gustaría reutilizar esta función confiable, simplemente pasar a esta función el `Db` e `Email` que tengas en ese momento.

En un entorno JavaScript, la portabilidad puede significar serializar y enviar funciones por un socket.  Puede significar ejecutar toda la aplicacion en Web Workers. La portabilidad es un rasgo poderoso.

Al contrario que los "típicos" métodos y procedimientos en programación imperativa que están enraizados profundamente en sus entornos a través de estado, dependencias, y efectos, las funciones puras pueden ejecutar en cualquier sitio que desee nuestro corazón.

¿Cuando fue la ultima vez que copiaste un método en una nueva app? Una de mis citas favoritas proviene del creador de Erlang, Joe Armstrong: "El problema con los lenguajes orientados a objetos es que tienen todo ese entorno implícito que llevan a todos lados. Querías una banana pero tienes un gorila sosteniendo una banana... y la jungla entera". 

### Testeable

Luego, nos damos cuenta que las funciones puras hacen los tests mucho mas fácil. No necesitamos mockear una pasarela de pagos "real" o configurar y verificar el estado del mundo después de cada test. Simplemente pasar entrada a la función y verificar la salida.

De hecho, encontramos que la comunidad funcional descubriendo nuevas herramientas de test que pueden bombardear nuestra función con entradas generadas y verificar que sus propiedades se mantienen en la salida. Esta fuera del alcance de este libro, pero les insisto encarecidamente que busquen prueben *Quickcheck* - una herramienta de pruebas que esta hecha a medida de un entorno puramente funcional.

### Razonable

Muchos creen que la mayor victoria cuando trabajas con funciones puras es la *transparencia referencial*. Un trozo de código es referencialmente transparente cuando puede ser substituido por su código evaluado sin cambiar el comportamiento del programa.

Ya que las funciones puras devuelven la misma salida dada la misma entrada, podemos confiar en que siempre devuelvan siempre los mismos resultados y por tanto preserven la transparencia referencial. 
Veamos un ejemplo.

```js

var Immutable = require("immutable");

var decrementHP = function(player) {
  return player.set("hp", player.get("hp")-1);
};

var isSameTeam = function(player1, player2) {
  return player1.get("team") === player2.get("team");
};

var punch = function(player, target) {
  if (isSameTeam(player, target)) {
    return target;
  } else {
    return decrementHP(target);
  }
};

var jobe = Immutable.Map({name:"Jobe", hp:20, team: "red"});
var michael = Immutable.Map({name:"Michael", hp:20, team: "green"});

punch(jobe, michael);
//=> Immutable.Map({name:"Michael", hp:19, team: "green"})
```

`decrementHP`, `isSameTeam` y `punch` son todas puras y por tanto referencialmente transparentes. Podemos usar la técnica llamada *razonamiento ecuacional* en donde se puede sustituir "iguales por iguales" para razonar sobre el código. Es un poco como evaluar manualmente el codigo sin tener en cuenta las peculiaridades de la evaluación programática. Usando transparencia referencial, juguemos con este código un poco.

Primero reemplazaremos la función `isSameTeam`.

```js
var punch = function(player, target) {
  if (player.get("team") === target.get("team")) {
    return target;
  } else {
    return decrementHP(target);
  }
};
```

Ya que nuestros datos son inmutables, podemos simplemente reemplazar los equipos por sus valores reales

```js
var punch = function(player, target) {
  if ("red" === "green") {
    return target;
  } else {
    return decrementHP(target);
  }
};
```

Podemos ver en este caso que la condición es falsa y por lo tanto podemos quitar toda la rama del `if`.

```js
var punch = function(player, target) {
  return decrementHP(target);
};

```

Y si tambien reemplazamos `decrementHP`, vemos que, en este caso, `punch` se convierte en una llamada a decrementar `hp` en 1.

```js
var punch = function(player, target) {
  return target.set("hp", target.get("hp")-1);
};
```

Esta habilidad de razonar acerca del código es excelente para refactorizar y entender código en general. De hecho, utilizamos esta técnica para refactorizar nuestro programa de bandada de gaviotas. Utilizamos razonamiento ecuacional para aprovechar las propiedades de adición y multiplicación. Ciertamente, utilizaremos estas técnicas en todo el libro.

### Código paralelo

Finalmente, y aquí esta el coup de grâce,  podemos ejecutar cualquier función pura en paralelo ya que no necesita acceder a memoria compartida y no puede, por definición, tener una condición de carrera debido a algún efecto secundario.

Esto es muy posible tanto en un servidor con entorno js con hilos como en un navegador con web workers aunque la cultura actual parece evitarlo debido a la complejidad cuando se trata con funciones impuras.

## En Resumen

Hemos visto que son las funciones puras y porque nosotros, como programadores funcionales, creemos que son "la guinda del pastel". De aquí en adelante, nos esforzaremos en escribir todas nuestras funciones de una forma pura. Necesitaremos de algunas herramientas extras para ayudarnos, pero mientras tanto, trataremos de separar las funciones impuras del resto del código puro. 

Escribir programas con funciones puras es un poco laborioso sin herramientas extras en nuestro cinturón de herramientas. Tenemos que hacer malabares con los datos pasando argumentos para todos lados, tenemos prohibido usar estado, sin mencionar efectos secundarios. ¿Como es que uno escribe estos programas masoquistas? Vamos a obtener una nueva herramienta llamada curry.

[Capitulo 4: Currying](ch4-es.md)
