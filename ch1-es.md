# Capítulo 1: Que estamos haciendo?

## Presentación

Hola soy el Profesor Franklin Risby, un placer el conocerte. Vamos a estar un tiempo juntos. Supuestamente voy a enseñarte un poco sobre programación funcional. Pero basta de hablar sobre mí, ¿qué tal tú? Espero que estés familiarizado con el lenguaje JavaScript, que tengas un poco de experiencía con programación Orientada a Objectos, y que te apetezca convertirte en un programador a seguir. No necesitas tener un Doctorado en Entomología, solo necesitas saber como encontrar y solucionar algunos bugs.

No voy asumir ningún conocimiento previo sobre programación funcional porque ya sabemos que sucede cuando uno asume mucho, pero espero que te hayas encontrado con ciertos problemas al trabajar con estados mutables, efectos secundarios no restringidos, y diseño sin principios. Ahora que ya nos hemos presentado, vamos a ello.

El propósito de este capítulo es dar una noción de lo que es escribir programación funcional. Tenemos que tener algunas ideas sobre que hace a un programa *funcional* o acabaremos escribiendo garabatos, evitando objetos a toda costa - un esfuerzo sin sentido. Necesitamos una diana donde apuntar nuestro código y una brújula celestial para cuando las aguas se vuelvan violentas.

Hay ciertos principios de programación, varios acrónimos que nos guiarán a través de los túneles oscuros de cualquier aplicación:  DRY (don't repeat yourself, "no te repitas"), acoplamiento débil alta cohesión, YAGNI (ya ain't gonna need it, "no lo vas a necesitar"), principio de mínima sorpresa, única responsabilidad, etc.

No voy a elaborar una lista de cada guía que he oído durante años... la cuestión es que sostenga de manera funcional, aunque sea meramente tangencial a nuestra meta.
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

Quién en la faz de la tierra, sería capaz de crear esta abominación? Es irrazonablemente dificil mantener el rastro del estado mutable interno. Y, por si no fuera suficiente, la respuesta es incorrecta! Debería de ser `16`, pero `flock_a` ha sido alterado permanentemente en el proceso. Pobre `flock_a`. Esto es anarquía en I.T.! Esto es aritmética de animales salvajes!

Si no entiendes este programa, no pasa nada, yo tampoco lo entiendo. La cuestión es que el estado y los valores mutables son difíciles de seguir, incluso en un ejemplo tan pequeño.

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

Ah sí, esas antiguas propiedades matemáticas serán de ayuda. No te preocupes si no las sabes todas de memoria. Para muchos de nosotros, hace mucho desde que hemos revisitado esta información. Vamos a ver si podemos utilizar estas propiedades para simplificar nuestra pequeña aplicación de gaviotas.

```js
// Línea original
add(multiply(flock_b, add(flock_a, flock_c)), multiply(flock_a, flock_b));

// Aplica la propiedad de identidad y elimina el 'add' extra
// (add(flock_a, flock_c) == flock_a)
add(multiply(flock_b, flock_a), multiply(flock_a, flock_b));

// Aplica la propiedad distributiva para así obtener el resultado
multiply(flock_b, add(flock_a, flock_a));
```

Brillante! Solo con una llamada a una función basta, sin hacer falta escribir más código. Usamos `add` y `multiply` en su completo, aunque no hay necesidad de re-escribirlas - seguramente hay librerías ya escritas que nos proporcionen `add` y `multiply`.

A lo mejor estarás pensando "que pícaro, al poner este ejemplo". O "programas del mundo real no son tan simples y no se pueden razonar de esta manera". Hemos seleccionado este ejemplo porque casi todos sabemos que es una suma y multiplicación. Aquí podemos observar fácilmente como las matemáticas pueden ser útiles.

No te desanimes, a lo largo de este libro hablaremos un poco de teoría de la categoría, aplicar teoría, y cálculo lambda para escribir ejemplos del mundo real, teniendo la misma simplicidad y resultados que nuestro ejemplo de las gaviotas. No necesitas ser un matemático, será como utilizar otro framework o api.

A lo mejor te sorprende oír que podamos escribir por completo, un programa utilizando programación funcional como hemos mostrado en el ejemplo de arriba. Programas que tienen propiedades seguras. Programas cortos, pero fáciles de razonar. Programas que no tienes porque reinventar la rueda una y otra cada vez. No tener leyes es bueno si eres un criminal, pero en este libro, vamos a agradecer y obedecer las leyes matemáticas.

Utilizaremos teoría para cada pieza que encaje bien y educadamente. Vamos a representar nuestro problema con términos genéricos y que se puedan componer en pequeñas piezas, y así luego explotar sus propiedades para nuestro beneficio. Se necesita más disciplina que el enfoque de programación imperativa[^Más adelante definiremos programación imperativa, por ahora, solo hablaremos de programación funcional], pero lo que obtendrás a cambio, al trabajar con framework basado en principios matemáticos te sorprenderá.

Hemos visto un destello de nuestra estrella del norte funcional, pero necesitamos entender unos cuantos conceptos antes de empezar nuestro viaje.

[Capítulo 2: Funciones de primera clase](ch2-es.md)
