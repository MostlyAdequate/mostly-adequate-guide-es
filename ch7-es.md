# Hindley-Milner y yo

## Cuál es tú tipo?
Si eres nuevo en el mundo funcional, no tardará mucho hasta que te encuentres metido de lleno con firmas con tipado. Tipos son el meta lenguaje que permite a la gente con diferentes conocimientos, comunicarse de manera efectiva. La mayoría estan escritas bajo el sistema llamado "Hindley-Milner", el cual examinaremos en este capítulo.

Cuando trabajamos con funciones puras, firmas con tipado tienen un poder expresivo, donde el lenguaje Español no puede competir. Estas firmas te susurran al oído los secretos de la función. Con una única y compacta línea, exponen el comportamiento y intención. Podemos derivar "teoremas libres" a partir de estas firmas. Tipos pueden ser deducidos, con lo que no hay necesidad de anotaciones explicitas. Se pueden They can be tuned to fine point precision or left general and abstract. They are not only useful for compile time checks, but also turn out to be the best possible documentation available. Type signatures thus play an important part in functional programming - much more than you might first expect.

JavaScript es un lenguaje dinámico, pero no significa que evitemos tipado por completo. Seguimos trabajando con cadenas, números, booleanos, etc. Lo único es que no hay ningún lenguaje a ese nivel, con lo que mantenemos esa información en nuestras cabezas. No te preocupes, como utilizamos firmas para documentar, podemos utilizar comentarios que nos sirvan de propósito.

Hay herramientas de tipado disponibles para JavaScript como [Flow](http://flowtype.org/) o el dialecto [TypeScript](http://www.typescriptlang.org/). La intención de este libro es el equiparte con las herramientas necesarias para escribir código funcional, así que escogemos el sistema de tipado estándar utilizado en los lenguajes funcionales.


## Cuentos de la críptica

Desde los antiguos libros de matemáticas, a través los grandes mares de papeles blancos, entre los blogs posts de un sábado por la mañana, y en el código mismo, entontramos las firmas de tipado de  Hindley-Milner. El sistema es bastante simple, pero necesita explicación y practica si se quiere absorber este pequeño lenguaje.

```js
//  capitalize :: String -> String
var capitalize = function(s){
  return toUpperCase(head(s)) + toLowerCase(tail(s));
}

capitalize("smurf");
//=> "Smurf"
```

Aquí, `capitalize` toma una `String` y devuelve una `String`. No te fijes en la implementación, solo estamos interesados en la firma de tipado.

En HM, las funciones están escritas como `a -> b` donde `a` y `b` son variables de cualquier tipo. Así las firmas para `capitalize` se pueden leer como "una función de `String` a `String`". En otras palabras, toma una `String` como su entrada y devuelve una `String` como su sálida.

Vamos a ver más firmas para funciones:

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

`strLength` representa la misma idea que antes: toma una `String` y devuelve un `Number`.

Las otras quizás te dejen perplejo a primera vista. Sin enterder por completo los detalles, siempre puedes ver el tipo del valor que se devolverá. Así `match` se puede interpretar como: Toma un `Regex` y una `String` y devuelve `[String]`. Pero hay algo interesante aquí que me gustaría explicar:

Para `match` somos libres de agrupar las firmas tal que así:

```js
//  match :: Regex -> (String -> [String])
var match = curry(function(reg, s){
  return s.match(reg);
});
```

Ah sí, agrupar la última parte en parentesís muestra mucha más información. Ahora se ve como una función que toma una `Regex` y devuelve una función de `String` a `[String]`. Debido al currying, este es el caso: dale un `Regex` y obtenemos una función esperando por su argumento `String`. Por supuesto, no tenemos que pensar en ello de esta manera, pero es bueno entender porque el último tipo es el tipo que será devuelto.

```js
//  match :: Regex -> (String -> [String])

//  onHoliday :: String -> [String]
var onHoliday = match(/holiday/ig);
```

Each argument pops one type off the front of the signature. `onHoliday` is `match` that already has a `Regex`.

```js
//  replace :: Regex -> (String -> (String -> String))
var replace = curry(function(reg, sub, s){
  return s.replace(reg, sub);
});
```

As you can see with the full parenthesis on `replace`, the extra notation can get a little noisy and redundant so we simply omit them. We can give all the arguments at once if we choose so it's easier to just think of it as: `replace` takes a `Regex`, a `String`, another `String` and returns you a `String`.

A few last things here:


```js
//  id :: a -> a
var id = function(x){ return x; }

//  map :: (a -> b) -> [a] -> [b]
var map = curry(function(f, xs){
  return xs.map(f);
});
```

The `id` function takes any old type `a` and returns something of the same type `a`. We're able to use variables in types just like in code. Variable names like `a` and `b` are convention, but they are arbitrary and can be replaced with whatever name you'd like. If they are the same variable, they have to be the same type. That's an important rule so let's reiterate: `a -> b` can be any type `a` to any type `b`, but `a -> a` means it has to be the same type. For example, `id` may be `String -> String` or `Number -> Number`, but not `String -> Bool`.

`map` similarly uses type variables, but this time we introduce `b` which may or may not be the same type as `a`. We can read it as: `map` takes a function from any type `a` to the same or different type `b`, then takes an array of `a`'s and results in an array of `b`'s.

Hopefully, you've been overcome by the expressive beauty in this type signature. It literally tells us what the function does almost word for word. It's given a function from `a` to `b`, an array of `a`, and it delivers us an array of `b`. The only sensible thing for it to do is call the bloody function on each `a`. Anything else would be a bold face lie.

Being able to reason about types and their implications is a skill that will take you far in the functional world. Not only will papers, blogs, docs, etc, become more digestible, but the signature itself will practically lecture you on its functionality. It takes practice to become a fluent reader, but if you stick with it, heaps of information will become available to you sans RTFMing.

Here's a few more just to see if you can decipher them on your own.

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

`reduce` is perhaps, the most expressive of all. It's a tricky one, however, so don't feel inadequate should you struggle with it. For the curious, I'll try to explain in English though working through the signature on your own is much more instructive.

Ahem, here goes nothing....looking at the signature, we see the first argument is a function that expects a `b`, an `a`, and produces a `b`. Where might it get these `a`s and `b`s? Well, the following arguments in the signature are a `b` and an array of `a`s so we can only assume that the `b` and each of those `a`s will be fed in. We also see that the result of the function is a `b` so the thinking here is our final incantation of the passed in function will be our output value. Knowing what reduce does, we can state that the above investigation is accurate.


## Narrowing the possibility

Once a type variable is introduced, there emerges a curious property called *parametricity*[^http://en.wikipedia.org/wiki/Parametricity]. This property states that a function will *act on all types in a uniform manner*. Let's investigate:

```js
// head :: [a] -> a
```

Looking at `head`, we see that it takes `[a]` to `a`. Besides the concrete type `array`, it has no other information available and, therefore, its functionality is limited to working on the array alone. What could it possibly do with the variable `a` if it knows nothing about it? In other words, `a` says it cannot be a *specific* type, which means it can be *any* type, which leaves us with a function that must work uniformly for *every* conceivable type. This is what *parametricity* is all about. Guessing at the implementation, the only reasonable assumptions are that it takes the first, last, or a random element from that array. The name `head` should tip us off.

Here's another one:

```js
// reverse :: [a] -> [a]
```

From the type signature alone, what could `reverse` possibly be up to? Again, it cannot do anything specific to `a`. It cannot change `a` to a different type or we'd introduce a `b`. Can it sort? Well, no, it wouldn't have enough information to sort every possible type. Can it re-arrange?  Yes, I suppose it can do that, but it has to do so in exactly the same predictable way. Another possibility is that it may decide to remove or duplicate an element. In any case, the point is, the possible behaviour is massively narrowed by its polymorphic type.

This narrowing of possibility allows us to use type signature search engines like [Hoogle](https://www.haskell.org/hoogle) to find a function we're after. The information packed tightly into a signature is quite powerful indeed.

## Free as in theorem

Besides deducing implementation possibilities, this sort of reasoning gains us *free theorems*. What follows are a few random example theorems lifted directly from [Wadler's paper on the subject](http://ttic.uchicago.edu/~dreyer/course/papers/wadler.pdf).

```js
// head :: [a] -> a
compose(f, head) == compose(head, map(f));

// filter :: (a -> Bool) -> [a] -> [a]
compose(map(f), filter(compose(p, f))) == compose(filter(p), map(f));
```


You don't need any code to get these theorems, they follow directly from the types. The first one says that if we get the `head` of our array, then run some function `f` on it, that is equivalent to, and incidentally, much faster than, if we first `map(f)` over every element then take the `head` of the result.

You might think, well that's just common sense. But last I checked, computers don't have common sense. Indeed, they must have a formal way to automate these kind of code optimizations. Maths has a way of formalizing the intuitive, which is helpful amidst the rigid terrain of computer logic.

The `filter` theorem is similar. It says that if we compose `f` and `p` to check which should be filtered, then actually apply the `f` via `map` (remember filter, will not transform the elements - its signature enforces that `a` will not be touched), it will always be equivalent to mapping our `f` then filtering the result with the `p` predicate.

These are just two examples, but you can apply this reasoning to any polymorphic type signature and it will always hold. In JavaScript, there are some tools available to declare rewrite rules. One might also do this via the `compose` function itself. The fruit is low hanging and the possibilities are endless.

## Constraints

One last thing to note is that we can constrain types to an interface.

```js
// sort :: Ord a => [a] -> [a]
```

What we see on the left side of our fat arrow here is the statement of a fact: `a` must be an `Ord`. Or in other words, `a` must implement the `Ord` interface. What is `Ord` and where did it come from? In a typed language it would be a defined interface that says we can order the values. This not only tells us more about the `a` and what our `sort` function is up to, but also restricts the domain. We call these interface declarations *type constraints*.

```js
// assertEqual :: (Eq a, Show a) => a -> a -> Assertion
```

Here, we have two constraints: `Eq` and `Show`. Those will ensure that we can check equality of our `a`s and print the difference if they are not equal.

We'll see more examples of constraints and the idea should take more shape in later chapters.


## In Summary

Hindley-Milner type signatures are ubiquitous in the functional world. Though they are simple to read and write, it takes time to master the technique of understanding programs through signatures alone. We will add type signatures to each line of code from here on out.

[Chapter 8: Tupperware](ch8.md)
