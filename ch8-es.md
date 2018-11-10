# Tupperware

## El gran Contenedor 

<img src="images/jar.jpg" alt="http://blog.dwinegar.com/2011/06/another-jar.html" />

Todos hemos visto como crear programas que conducen data por un tubo compuesto de series de funciones puras. Son especificaciones declarativas de este comportamiento. Pero ¿Cómo controlar el flujo, manejor de errores, acciones asíncronas, estado y pero aún los `side effects` ó efectos secundarios? En este capítulo, vamos a descubrir la fundación sobre la cual estas abastracciones están construidas. 


Primero vamos a crear un contenedor. Este contenedor debe contener cualquier tipo de valor; como un ziplock que solo contiene puding de tapioca, sin embargo, si solo lo contiene no nos dará mucho valor. Mejor debe ser un objeto, pero no le daremos métodos ni proppiedades en el sentido OO (Programación dirigida a objetos). Trataremoes este objeto como un baúl y que guarda nuestros datos.

```js
var Container = function(x) {
  this.__value = x;
}

Container.of = function(x) { return new Container(x); };
```

Aquí está nuestro primer contenedor. Lo hemos llamado, inteligentemente, `Container` (Contenedor). Usarémos `Container.of` como un constructor que nos ahora el trabajo de tener que escribir la terrible palabra `new` en nuestro código. Hay algo que esconde la palabra `of` que no es evidente, pero por ahora, pensemos como la manera correcta de guardar nuestros datos en el contenedor. 

Entonces, revicemos nuestro baúl 

```js
Container.of(3)
//=> Container(3)


Container.of("hotdogs")
//=> Container("hotdogs")


Container.of(Container.of({name: "yoda"}))
//=> Container(Container({name: "yoda" }))
```

Si estamos usando `node` as ejecutar este código se vería `{__value: x}` aunque nosotros construimos un `Container(x)`. Chrome nos dará en consola la propiedad del tipo; sin embargo, esto no importa, siempre y cuando entendamos como se ve el `Container`. En algunos ambientes uno puede sobre escribir la propiedad `inspect` si se quiere, pero no seremos tan metódicos. Para el alcance de este libro, escribirémos el output conceptual como si hubiéramos sobre escrito la propiedad `inspect`, esto es mucho más descriptivo que el valor `{__value:x}`, lo anterior también aplica por simples razónes estéticas. 


Continuemos aclarando temas antes de continuar:

* `Container` es un objeto con una propiedad. Muchos contenedores solo contienen una cosa, claro, no están limitados a una. Hemos llamado esta propiedad arbitrariamente `__value`

* La propiedad `__value` no puede ser de un tipo específico de lo contrario nuestro `Container` no sería un container. 


* Una vez datos entran en nuestro `Contariner` se mantiene ahí. Nosotros *prodríamos* sacarlo usando `__value`, pero eso anularía el ejercicio.

Las rasones por las cuales estámos haciendo esto, serán más claras en el trasncurso del capítulo, por el momento han de creerme.

## Mi primer Functor

Dado que hemos guardado nuestro dato en nuestro contenedor, tenemos que tener una manera de ejecutar funciones sobre él.

```js
// (a -> b) -> Container a -> Container b
Container.prototype.map = function(f){
  return Container.of(f(this.__value))
}
```

Si ven, es tal cual la famosa funcion de Array `map`, expecto que tenemos un `Container a` y no un `[a]`. Esto funciona escencialmente de la misma manera:

```js
Container.of(2).map(function(two){ return two + 2 })
//=> Container(4)


Container.of("flamethrowers").map(function(s){ return s.toUpperCase() })
//=> Container("FLAMETHROWERS")


Container.of("bombs").map(_.concat(' away')).map(_.prop('length'))
//=> Container(10)
```

Nosotros podemos trabajar con el valor sin nunca sacarlo de nuestro `Container`. Esto es algo increíble. Nuestro valor en el `Container` es entregado a la función `map` para que podamos trabajarlo y luego retornalo a su `Container` para guardarlo de manera segura. Como resultado de nunca salir de `Container`, podríamos continuar usando `map`, pasando funciones a nuestro antojo. Podríamos inclusive cambiar el tipo como se demostró en el último ejemplo de los tres últimos. 


Momento, si seguimos llamando la función `map`, pareciera que creamos una especie de composición! ¿Qué tipo de magía matemática está ocurriendo? Bueno hemos descubierto los *Functores*.


> Un Functor es un tipo que implementa la función `map` y obecede ciertas reglas

Si, *Functor* es simplemente una interface con un contrato. Inclusive, podríamos haberlo llamado *Mappable*, pero no sería tan sofisticado como llamarlo *Functor*. Los Functores viene de la teoriá de categoría y revisaremos con detalle las matemáticas hacia el final del capítulo, por ahora, trabajaremos con la intuición y las aplicaciones prácticas para esta estraña interface

¿Cual podría ser la razón para guardar todo en un `Container` y luego usar `map` para llegar a él? Pues la respuesta se revela sola si hacemos otra pregunta: ¿Qué ganamos en delegar al `Container` que llame funciones por nosotros? Bueno, esto es una abstracción de llamado de funciones. Cuando aplicamos `map` a una funcion, le pedimos al container que llame la función por nosotros. Este es un concepto muy poderoso.

## El talvez de Schrödinger

<img src="images/cat.png" alt="cool cat, need reference" />

Los `Container`s son un concepto aburrido. De hecho, se le suelen llamar `Identidad` y tienen el mismo impacto como nuestras funciones `id`[^de nuevo, acá hay un link matemático que veremos cuando el tiempo sea el indicado]. Sin embargo, hay otros Functores de forma de contenedores que implementan una función `map`, que provee comportamientos específicos mientras se mapean. Defínamos entonces:  

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

Ahora, `maybe` se mucho como un `Container` con un cambio menor: primero revisa si hay un valor antes de llamar la función que se le entrega. Esto tiene el effecto de omitir esos fatidiosos nulls mientras `map`eamos los datos[^Nota: esta implementación es mínima y es solo de fines pedagócos]

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


La notación de punto (dot sintax) esta bien y funcional, pero por rasones antes mecionadas en la primera parte, nos gustaría mantener nuestro estilo `pointfree`, o libre de variables tácitas. Afortunadamente, `map` está completamente equipada para delegar cualquier Functor que recibe:

```js
//  map :: Functor f => (a -> b) -> f a -> f b
var map = curry(function(f, any_functor_at_all) {
  return any_functor_at_all.map(f);
});
```

Esto es perfecto, ya que podemos continuar con la composición como habíamos descrito anteriormente usando `map`. Este es el caso también con el `map` de ramda.js. Usaremos la notación de punto (dot notation) cuando es instructiva y la versión `pointfree` cuando sea conveniente. ¿Notaron cómo agregué algo nuevo a la firma de la función? `Functor f =>` nos dice que `f` debe ser un Functor. No era algo extraordinario, pero creí conveniente decirlo.  

## Casos de uso

En la vida real, típicamente vemos `Maybe` usado en funciones que puedan fallar al retornanos un resultado.

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

`safeHead` es como nuestro normal `_.head`, pero con `type safety` ó seguridad de tipos. Una cosa curiosa pasa cuando `Maybe` es introducido en nuestro código; somos forzados a manejar esos estados obscuros que retornan `null`. La función `safeHead` es honesta y de manera directa nos dice sus posibilidades de falla, por lo cual nos entrega un `Maybe` para informarnos de esto. También, estámos más que solo informados, porque estámos forzados a `map`ear para llegar al valor y dejarlo guardado dentro del objeto `Maybe`. Essencialmente, este es un `null` revisado por la función `safeHead`. Ahora, podemos dormir más tranquilos sabiendo que un `null` no aparecerá donde menos lo esperamos. APIs que utilicen este concepto garantizarán un software más seguro. 

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

`withdraw` nos dejará saber cuando estamos cortos de dinero cun un `Maybe(null)`. Esta función también nos comunica su talón de aquiles y no nos deja otra opción sino `map`ear todo lo que sigue. La diferencia es que el `null` era intencional acá. Envés de `Maybe(String)`, tenemos el `Maybe(null)` de regreso para señalar la falla en nuestra aplicación y effectivamente parar la ejecución. Es también importante denotar que: si la función `withdraw` falla, entonces `map` cortará con el resto de la computación dado que no ejecutará las funciones mapeadas, como `finishTransaction`. Esto es precisamente el comportamiento esperado ya que preferimos no actualizar nuestro libro de transcciones o mostrar un balance si no ha sido exitoso el retiro de dinero. 

## Soltando el valor

Una cosa que normalmente perdemos de visa, es que siempre hay un alto en el camino o un cambio observable; algo como una función que envían un JSON, ó que imprime algo en la pantalla, o que altera algún archivo en el sistema. No podemos retorn sólamente `return`, debemos retornar algo al mundo. Podemos tomar prestada el koan del Budismo Zen: "Si un program que no tiene efectos observables se ejecuta, ¿Cómo sabemos que se ejecuta?" 


Nuestra aplicación tiene como trabajo recibir, transforma y llevar esa información a alguna parte. En nuestro contexto, debemos poder "sacar" nuestro valor de su contenedor. En efecto, un error común es tratar de sacar los valores de nuestro `Maybe` de una manera o de otra, para volver nuestro programa deterministico y obtener un resultado. Sin embargo, tenemos que enterder que nuestro código, tal cual como el gato de Schrödinger, estará en dos estados y solo se deteminará cuando se ejecute la última función y así tenga un flow lineal. 

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

We will now either return a static value (of the same type that `finishTransaction` returns) or continue on merrily finishing up the transaction sans `Maybe`. With `maybe`, we are witnessing the equivalent of an `if/else` statement whereas with `map`, the imperative analog would be: `if (x !== null) { return f(x) }`.

The introduction of `Maybe` can cause some initial discomfort. Users of Swift and Scala will know what I mean as it's baked right into the core libraries under the guise of `Option(al)`. When pushed to deal with `null` checks all the time (and there are times we know with absolute certainty the value exists), most people can't help, but feel it's a tad laborious. However, with time, it will become second nature and you'll likely appreciate the safety. After all, most of the time it will prevent cut corners and save our hides.

Writing unsafe software is like taking care to paint each egg with pastels before hurling it into traffic; like building a retirement home with materials warned against by three little pigs. It will do us well to put some safety into our functions and `Maybe` helps us do just that.

I'd be remiss if I didn't mention that the "real" implementation will split `Maybe` into two types: one for something and the other for nothing. This allows us to obey parametricity in `map` so values like `null` and `undefined` can still be mapped over and the universal qualification of the value in a functor will be respected. You'll often see types like `Some(x) / None` or `Just(x) / Nothing` instead of a `Maybe` that does a `null` check on its value.

## Pure Error Handling

<img src="images/fists.jpg" alt="pick a hand... need a reference" />

It may come as a shock, but `throw/catch` is not very pure. When an error is thrown, instead of returning an output value, we sound the alarms! The function attacks, spewing thousands of 0's and 1's like shields & spears in an electric battle against our intruding input. With our new friend `Either`, we can do better than to declare war on input, we can respond with a polite message. Let's take a look:

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

`Left` and `Right` are two subclasses of an abstract type we call `Either`. I've skipped the ceremony of creating the `Either` superclass as we won't ever use it, but it's good to be aware. Now then, there's nothing new here besides the two types. Let's see how they act:

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

`Left` is the teenagery sort and ignores our request to `map` over it. `Right` will work just like `Container` (a.k.a Identity). The power comes from the ability to embed an error message within the `Left`.

Suppose we have a function that might not succeed. How about we calculate an age from a birth date. We could use `Maybe(null)` to signal failure and branch our program, however, that doesn't tell us much. Perhaps, we'd like to know why it failed. Let's write this using `Either`.

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

Now, just like `Maybe(null)`, we are short circuiting our app when we return a `Left`. The difference, is now we have a clue as to why our program has derailed. Something to notice is that we return `Either(String, Number)`, which holds a `String` as its left value and a `Number` as its `Right`. This type signature is a bit informal as we haven't taken the time to define an actual `Either` superclass, however, we learn a lot from the type. It informs us that we're either getting an error message or the age back.

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

When the `birthdate` is valid, the program outputs its mystical fortune to the screen for us to behold. Otherwise, we are handed a `Left` with the error message plain as day though still tucked away in its container. That acts just as if we'd thrown an error, but in a calm, mild manner fashion as opposed to losing its temper and screaming like a child when something goes wrong.

In this example, we are logically branching our control flow depending on the validity of the birth date, yet it reads as one linear motion from right to left rather than climbing through the curly braces of a conditional statement. Usually, we'd move the `console.log` out of our `zoltar` function and `map` it at the time of calling, but it's helpful to see how the `Right` branch differs. We use `_` in the right branch's type signature to indicate it's a value that should be ignored[^In some browsers you have to use `console.log.bind(console)` to use it first class].

I'd like to take this opportunity to point out something you may have missed: `fortune`, despite its use with `Either` in this example, is completely ignorant of any functors milling about. This was also the case with `finishTransaction` in the previous example. At the time of calling, a function can be surrounded by `map`, which transforms it from a non-functory function to a functory one, in informal terms. We call this process *lifting*. Functions tend to be better off working with normal data types rather than container types, then *lifted* into the right container as deemed necessary. This leads to simpler, more reusable functions that can be altered to work with any functor on demand.

`Either` is great for casual errors like validation as well as more serious, stop the show errors like missing files or broken sockets. Try replacing some of the `Maybe` examples with `Either` to give better feedback.

Now, I can't help, but feel I've done `Either` a disservice by introducing it as merely a container for error messages. It captures logical disjunction (a.k.a `||`) in a type. It also encodes the idea of a *Coproduct* from category theory, which won't be touched on in this book, but is well worth reading up on as there's properties to be exploited. It is the canonical sum type (or disjoint union of sets) because its amount of possible inhabitants is the sum of the two contained types[^I know that's a bit hand wavy so here's a [great article](https://www.fpcomplete.com/school/to-infinity-and-beyond/pick-of-the-week/sum-types)]. There are many things `Either` can be, but as a functor, it is used for its error handling.

Just like with `Maybe`, we have little `either`, which behaves similarly, but takes two functions instead of one and a static value. Each function should return the same type:

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

Finally, a use for that mysterious `id` function. It simply parrots back the value in the `Left` to pass the error message to `console.log`. We've made our fortune telling app more robust by enforcing error handling from within `getAge`. We either slap the user with a hard truth like a high five from a palm reader or we carry on with our process. And with that, we're ready to move on to an entirely different type of functor.

## Old McDonald had Effects...

<img src="images/dominoes.jpg" alt="dominoes.. need a reference" />

In our chapter about purity we saw a peculiar example of a pure function. This function contained a side-effect, but we dubbed it pure by wrapping its action in another function. Here's another example of this:

```js
//  getFromStorage :: String -> (_ -> String)
var getFromStorage = function(key) {
  return function() {
    return localStorage[key];
  }
}
```

Had we not surrounded its guts in another function, `getFromStorage` would vary its output depending on external circumstance. With the sturdy wrapper in place, we will always get the same output per input: a function that, when called, will retrieve a particular item from `localStorage`. And just like that (maybe throw in a few Hail Mary's) we've cleared our conscience and all is forgiven.

Except, this isn't particularly useful now is it. Like a collectable action figure in its original packaging, we can't actually play with it. If only there were a way to reach inside of the container and get at its contents... Enter `IO`.

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

`IO` differs from the previous functors in that the `__value` is always a function. We don't think of its `__value` as a function, however - that is an implementation detail and we best ignore it. What is happening is exactly what we saw with the `getFromStorage` example: `IO` delays the impure action by capturing it in a function wrapper. As such, we think of `IO` as containing the return value of the wrapped action and not the wrapper itself. This is apparent in the `of` function: we have an `IO(x)`, the `IO(function(){ return x })` is just necessary to avoid evaluation.

Let's see it in use:

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

Here, `io_window` is an actual `IO` that we can `map` over straight away, whereas `$` is a function that returns an `IO` after its called. I've written out the *conceptual* return values to better express the `IO`, though, in reality, it will always be `{ __value: [Function] }`. When we `map` over our `IO`, we stick that function at the end of a composition which, in turn, becomes the new `__value` and so on. Our mapped functions do not run, they get tacked on the end of a computation we're building up, function by function, like carefully placing dominoes that we don't dare tip over. The result is reminiscent of Gang of Four's command pattern or a queue.

Take a moment to channel your functor intuition. If we see past the implementation details, we should feel right at home mapping over any container no matter its quirks or idiosyncrasies. We have the functor laws, which we will explore toward the end of the chapter, to thank for this pseudo-psychic power. At any rate, we can finally play with impure values without sacrificing our precious purity.

Now, we've caged the beast, but we'll still have to set it free at some point. Mapping over our `IO` has built up a mighty impure computation and running it is surely going to disturb the peace. So where and when can we pull the trigger? Is it even possible to run our `IO` and still wear white at our wedding? The answer is yes, if we put the onus on the calling code. Our pure code, despite the nefarious plotting and scheming, maintains its innocence and it's the caller who gets burdened with the responsibility of actually running the effects. Let's see an example to make this concrete.

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

Our library keeps its hands clean by wrapping `url` in an `IO` and passing the buck to the caller. You might have also noticed that we have stacked our containers; it's perfectly reasonable to have a `IO(Maybe([x]))`, which is three functors deep[^`Array` is most definitely a mappable container type] and exceptionally expressive.

There's something that's been bothering me and we should rectify it immediately: `IO`'s `__value` isn't really its contained value, nor is it a private property as the underscore prefix suggests. It is the pin in the grenade and it is meant to be pulled by a caller in the most public of ways. Let's rename this property to `unsafePerformIO` to remind our users of its volatility.

```js
var IO = function(f) {
  this.unsafePerformIO = f;
}

IO.prototype.map = function(f) {
  return new IO(_.compose(f, this.unsafePerformIO));
}
```

There, much better. Now our calling code becomes `findParam("searchTerm").unsafePerformIO()`, which is clear as day to users (and readers) of the application.

`IO` will be a loyal companion, helping us tame those feral impure actions. Next, we'll see a type similar in spirit, but has a drastically different use case.


## Asynchronous Tasks

Callbacks are the narrowing spiral staircase to hell. They are control flow as designed by M.C. Escher. With each nested callback squeezed in between the jungle gym of curly braces and parenthesis, they feel like limbo in an oubliette(how low can we go!). I'm getting claustrophobic chills just thinking about them. Not to worry, we have a much better way of dealing with asynchronous code and it starts with an "F".

The internals are a bit too complicated to spill out all over the page here so we will use `Data.Task` (previously `Data.Future`) from Quildreen Motta's fantastic [Folktale](http://folktalejs.org/). Behold some example usage:

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

The functions I'm calling `reject` and `result` are our error and success callbacks, respectively. As you can see, we simply `map` over the `Task` to work on the future value as if it was right there in our grasp. By now `map` should be old hat.

If you're familiar with promises, you might recognize the function `map` as `then` with `Task` playing the role of our promise. Don't fret if you aren't familiar with promises, we won't be using them anyhow because they are not pure, but the analogy holds nonetheless.

Like `IO`, `Task` will patiently wait for us to give it the green light before running. In fact, because it waits for our command, `IO` is effectively subsumed by `Task` for all things asynchronous; `readFile` and `getJSON` don't require an extra `IO` container to be pure. What's more, `Task` works in a similar fashion when we `map` over it: we're placing instructions for the future like a chore chart in a time capsule - an act of sophisticated technological procrastination.

To run our `Task`, we must call the method `fork`. This works like `unsafePerformIO`, but as the name suggests, it will fork our process and evaluation continues on without blocking our thread. This can be implemented in numerous ways with threads and such, but here it acts as a normal async call would and the big wheel of the event loop keeps on turning. Let's look at `fork`:

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

Upon calling `fork`, the `Task` hurries off to find some posts and render the page. Meanwhile, we show a spinner since `fork` does not wait for a response. Finally, we will either display an error or render the page onto the screen depending if the `getJSON` call succeeded or not.

Take a moment to consider how linear the control flow is here. We just read bottom to top, right to left even though the program will actually jump around a bit during execution. This makes reading and reasoning about our application simpler than having to bounce between callbacks and error handling blocks.

Goodness, would you look at that, `Task` has also swallowed up `Either`! It must do so in order to handle futuristic failures since our normal control flow does not apply in the async world. This is all well and good as it provides sufficient and pure error handling out of the box.

Even with `Task`, our `IO` and `Either` functors are not out of a job. Bear with me on a quick example that leans toward the more complex and hypothetical side, but is useful for illustrative purposes.

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

In this example, we still make use of `Either` and `IO` from within the success branch of `readFile`. `Task` takes care of the impurities of reading a file asynchronously, but we still deal with validating the config with `Either` and wrangling the db connection with `IO`. So you see, we're still in business for all things synchronous.

I could go on, but that's all there is to it. Simple as `map`.

In practice, you'll likely have multiple asynchronous tasks in one workflow and we haven't yet acquired the full container apis to tackle this scenario. Not to worry, we'll look at monads and such soon, but first, we must examine the maths that make this all possible.


## A Spot of Theory

As mentioned before, functors come from category theory and satisfy a few laws. Let's first explore these useful properties.

```js
// identity
map(id) === id;

// composition
compose(map(f), map(g)) === map(compose(f, g));
```

The *identity* law is simple, but important. These laws are runnable bits of code so we can try them on our own functors to validate their legitimacy.

```js
var idLaw1 = map(id);
var idLaw2 = id;

idLaw1(Container.of(2));
//=> Container(2)

idLaw2(Container.of(2));
//=> Container(2)
```

You see, they are equal. Next let's look at composition.

```js
var compLaw1 = compose(map(concat(" world")), map(concat(" cruel")));
var compLaw2 = map(compose(concat(" world"), concat(" cruel")));

compLaw1(Container.of("Goodbye"));
//=> Container('Goodbye cruel world')

compLaw2(Container.of("Goodbye"));
//=> Container('Goodbye cruel world')
```

In category theory, functors take the objects and morphisms of a category and map them to a different category. By definition, this new category must have an identity and the ability to compose morphisms, but we needn't check because the aforementioned laws ensure these are preserved.

Perhaps our definition of a category is still a bit fuzzy. You can think of a category as a network of objects with morphisms that connect them. So a functor would map the one category to the other without breaking the network. If an object `a` is in our source category `C`, when we map it to category `D` with functor `F`, we refer to that object as `F a` (If you put it together what does that spell?!). Perhaps, it's better to look at a diagram:

<img src="images/catmap.png" alt="Categories mapped" />

For instance, `Maybe` maps our category of types and functions to a category where each object may not exist and each morphism has a `null` check. We accomplish this in code by surrounding each function with `map` and each type with our functor. We know that each of our normal types and functions will continue to compose in this new world. Technically, each functor in our code maps to a sub category of types and functions which makes all functors a particular brand called endofunctors, but for our purposes, we'll think of it as a different category.

We can also visualize the mapping of a morphism and its corresponding objects with this diagram:

<img src="images/functormap.png" alt="functor diagram" />

In addition to visualizing the mapped morphism from one category to another under the functor `F`, we see that the diagram commutes, which is to say, if you follow the arrows each route produces the same result. The different routes means different behavior, but we always end at the same type. This formalism gives us principled ways to reason about our code - we can boldly apply formulas without having to parse and examine each individual scenario. Let's take a concrete example.

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

We can instantly see and refactor code based on properties held by all functors.

Functors can stack:

```js
var nested = Task.of([Right.of("pillows"), Left.of("no sleep for you")]);

map(map(map(toUpperCase)), nested);
// Task([Right("PILLOWS"), Left("no sleep for you")])
```

What we have here with `nested` is a future array of elements that might be errors. We `map` to peel back each layer and run our function on the elements. We see no callbacks, if/else's, or for loops; just an explicit context. We do, however, have to `map(map(map(f)))`. We can instead compose functors. You heard me correctly:

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

There, one `map`. Functor composition is associative and earlier, we defined `Container`, which is actually called the `Identity` functor. If we have identity and associative composition we have a category. This particular category has categories as objects and functors as morphisms, which is enough to make one's brain perspire. We won't delve too far into this, but it's nice to appreciate the architectural implications or even just the simple abstract beauty in the pattern.


## In Summary

We've seen a few different functors, but there are infinitely many. Some notable omissions are iterable data structures like trees, lists, maps, pairs, you name it. eventstreams and observables are both functors. Others can be for encapsulation or even just type modelling. Functors are all around us and we'll use them extensively throughout the book.

What about calling a function with multiple functor arguments? How about working with an order sequence of impure or async actions? We haven't yet acquired the full tool set for working in this boxed up world. Next, we'll cut right to the chase and look at monads.

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
