# Capítulo 1: Que estamos haciendo?

## Presentación

Hola soy el Profeso Franklin Risby, es un placer el conocerte. Vamos ha estar un tiempo juntos. Supuestamente voy a enseñarte un poco sobre programación funcional. Pero basta de hablar sobre mí, qué tal tú? Espero que estés familiarizado con el lenguaje JavaScript, que tengas un poco de experiencía con programación Orientada a Objectos, y que te apetezca convertirte en un programador a seguir. No necesitas tenen un Doctorado en Entomología, solo necesitas saber como encontrar y solucionar algunos bugs.

No voy asumir ningún conocimiento previo sobre programación funcional porque ya sabemos que sucede cuando asume mucho, pero espero que te hayas encontrado con ciertos problemas al trabajar con estados mudables, efectos secundarios no restringidos, y diseño sin principios. Ahora que ya nos hemos presentado, vamos a ello.

El propósito de este capítulo es dar una noción de lo que es escribir programación funcional. Tenemos que tener algunas ideas sobre que hace a un programa *funcional* o acabaremos escribiendo garabatos, evitando objectos a toda costa - un esfuerzo sin sentido. Necesitamos una diana donde apunta, una brújula celestial para cuando las aguas se vuelvan violentas.

Hay ciertos principios de programación, varios acrónimos que nos guiarán a través de los túneles oscuros de cualquier aplicación: there are some general programming principles, various acronymic credos that guide us through the dark tunnels of any application: DRY (don't repeat yourself, "no te repitas"), acoplamiento débil alta cohesión, YAGNI (ya ain't gonna need it, "no lo vas a necesitar"), principio de mínima sorpresa, única responsabilidad, etc.

No voy a elaborar una lista de cada guía que he oído durante años... la cuestión es que sostenga de manera funcional, aunque son meramente tangencial a nuestra meta.
Lo que me gustaría que te quedase como noción por ahora, antes de que nos adentremos más, es cual será nuestra intención cuando golpeemos y tecleemos; nuestro Xanadu funcional.

<!--BREAK-->

## Un breve encuentro

Vamos a empezar con un toque de locura. He aquí una aplicación de gaviotas. Cuando los rebaños se juntan, se convierten en un rebaño más grande y cuando crían, el número de gaviotas aumenta. Este código no intenta ser un buen ejemplo de código Orientado a Objectos , cuidado, este código esta para resaltar los peligros modernos de nuestro enfoque basado en asignación. Aquí tienes:

```js
var Flock = function(n) {
  this.seagulls = n;
};

Flock.prototype.conjoin = function(other) {
  this.seagulls += other.seagulls;
  return this;
};

Flock.prototype.breed = function(other) {
  this.seagulls = this.seagulls * other.seagulls;
  return this;
};

var flock_a = new Flock(4);
var flock_b = new Flock(2);
var flock_c = new Flock(0);

var result = flock_a.conjoin(flock_c)
    .breed(flock_b).conjoin(flock_a.breed(flock_b)).seagulls;
//=> 32
```

Quién en la faz de la tierra, sería capaz de crear esta abominación? Es irrazonablemente dificil mantener el rastro del estado mudable interno. Y, por si no es suficiente, la respuesta es incorrecta! Debería de ser `16`, pero `flock_a` ha sido alterado permanentemente en el proceso. Pobre `flock_a`. Esto es anarquía en I.T.! Esto es aritmética de animales salvajes!

Si no entiendes este programa, no pasa nada, yo tampoco lo entiendo. La cuestión es que el estado y los valore mudables son difíciles de seguir, incluso en un ejemplo tan pequeño.

Vamos a intentarlo otra vez, pero de forma más funcional:

```js
var conjoin = function(flock_x, flock_y) { return flock_x + flock_y };
var breed = function(flock_x, flock_y) { return flock_x * flock_y };

var flock_a = 4;
var flock_b = 2;
var flock_c = 0;

var result = conjoin(
  breed(flock_b, conjoin(flock_a, flock_c)), breed(flock_a, flock_b)
);
//=>16
```

Bueno, esta vez la respuesta es correcta. Hay menos código. La anidación de la función es un poco confusa...[^Pondremos remedio a esto en el ch5]. Es mejor, pero vamos a entrar más en detalle. Hay beneficios al llamar a cada cosa por su nombre. Una vez lo hemos hecho, vemos que estamos utilizando simple sumas/adiciones (`conjoin`) y multiplicaciones (`breed`).

No hay nada realmente especial sobre estas dos funciones, a pesar de su nombre. Vamos a renombrar nuestras funciones, revelando su verdadera identidad.

```js
var add = function(x, y) { return x + y };
var multiply = function(x, y) { return x * y };

var flock_a = 4;
var flock_b = 2;
var flock_c = 0;

var result = add(
  multiply(flock_b, add(flock_a, flock_c)), multiply(flock_a, flock_b)
);
//=>16
```
Y con esto, conseguimos el conocimiento de los antiguos:

```js
// associative
add(add(x, y), z) == add(x, add(y, z));

// commutative
add(x, y) == add(y, x);

// identity
add(x, 0) == x;

// distributive
multiply(x, add(y,z)) == add(multiply(x, y), multiply(x, z));
```

Ah si, esas antiguas propiedades matemáticas serán de ayuda. No te preocupes si no las sabes todas de memoria. Para muchos de nosotros, hace mucho desde que hemos revisitado esta información. Vamos a ver si podemos utilizar estas propiedades para simplificar nuestra pequeña aplicación de gaviotas.

```js
// Línea original
add(multiply(flock_b, add(flock_a, flock_c)), multiply(flock_a, flock_b));

// Aplica la propiedad de identidad y elimina el 'add' extra
// (add(flock_a, flock_c) == flock_a)
add(multiply(flock_b, flock_a), multiply(flock_a, flock_b));

// Aplica la propiedad distributiva para así obtener el resultado
multiply(flock_b, add(flock_a, flock_a));
```

Brilliant! We didn't have to write a lick of custom code other than our calling function. We include `add` and `multiply` definitions here for completeness, but there is really no need to write them - we surely have an `add` and `multiply` provided by some previously written library.

You may be thinking "how very strawman of you to put such a mathy example up front". Or "real programs are not this simple and cannot be reasoned about in such a way". I've chosen this example because most of us already know about addition and multiplication so it's easy to see how math can be of use to us here.

Don't despair, throughout this book, we'll sprinkle in some category theory, set theory, and lambda calculus to write real world examples that achieve the same simplicity and results as our flock of seagulls example. You needn't be a mathematician either, it will feel just like using a normal framework or api.

It may come as a surprise to hear that we can write full, everyday applications along the lines of the functional analog above. Programs that have sound properties. Programs that are terse, yet easy to reason about. Programs that don't reinvent the wheel at every turn. Lawlessness is good if you're a criminal, but in this book, we'll want to acknowledge and obey the laws of math.

We'll want to use the theory where every piece tends to fit together so politely. We'll want to represent our specific problem in terms of generic, composable bits and then exploit their properties for our own selfish benefit. It will take a bit more discipline than the "anything goes" approach of imperative[^We'll go over the precise definition of imperative later in the book, but for now it's anything other than functional programming] programming, but the payoff of working within a principled, mathematical framework will astound you.

We've seen a flicker of our functional north star, but there are a few concrete concepts to grasp before we can really begin our journey.

[Chapter 2: First Class Functions](ch2.md)
