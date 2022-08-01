## FAQ

- [¿Por qué hay fragmentos de código escritos a veces con puntos y comas y a veces sin?](#por-qué-hay-fragmentos-de-código-escritos-a-veces-con-puntos-y-comas-y-a-veces-sin)
- [Librerías externas como _ (ramda) o $ (jquery), ¿no están haciendo llamadas impuras?](#librerías-externas-como-_-ramda-o--jquery-no-están-haciendo-llamadas-impuras)
- [¿Cuál es el significado de `f a` en una firma?](#cuál-es-el-significado-de-f-a-en-una-firma)
- [¿Hay disponibles ejemplos de "la vida real"?](#hay-disponibles-ejemplos-de-la-vida-real)
- [¿Por qué el libro utiliza ES5? ¿Hay disponible alguna versión con ES6?](#por-qué-el-libro-utiliza-es5-hay-disponible-alguna-versión-con-es6)
- [¿A qué viene esa función reduce?](#a-qué-viene-esa-funcion-reduce)
- [¿No podrías utilizar un inglés más simple en lugar del estilo actual?](#no-podrías-utilizar-un-ingles-más-simple-en-lugar-del-estilo-actual)
- [¿Qué es Either? ¿Qué es Future? ¿Qué es Task?](#qué-es-either-qué-es-future-qué-es-task)
- [¿De dónde vienen métodos como map, filter, compose...?](#de-dónde-vienen-métodos-como-map-filter-compose)

### ¿Por qué hay fragmentos de código escritos a veces con puntos y comas y a veces sin?

> ver [#6]

Hay dos escuelas en JavaScript, gente que los usa, y gente que no.  Nosotros hemos elegido
usarlos, y ahora, nos esforzamos en ser consistentes con la decisión. Si falta alguno, 
por favor háznoslo saber y nos ocuparemos del descuido.

### Librerías externas como _ (ramda) o $ (jquery), ¿no están haciendo llamadas impuras?

> ver [#50]

Estas dependencias están disponibles como si estuviesen en el contexto global,
parte del lenguaje.
Así que, no, las llamadas aún se pueden considerar como puras.

Para más información, dale un vistazo a [este artículo sobre los CoEffects](http://tomasp.net/blog/2014/why-coeffects-matter/)

### ¿Cuál es el significado de `f a` en una firma?

> ver [#62]

En una firma, como:

`map :: Functor f => (a -> b) -> f a -> f b`

`f` se refiere a un `functor` que puede ser, por ejemplo, Maybe o IO. Así pues, la firma 
abstrae la elección de ese functor mediante el uso de una variable de tipo, lo que básicamente 
significa que cualquier functor puede ser usado donde aparece `f` siempre que todas las `f` 
sean del mismo tipo (si el primer `f a` en la firma representa un `Maybe a`, entonces el 
segundo **no puede referirse a** un `IO b` si no que debe referirse a un `Maybe b`). Por ejemplo:

```javascript
let maybeString = Maybe.of("Patate")
let f = function (x) { return x.length }
let maybeNumber = map(f, maybeString) // Maybe(6)

// Con la siguiente 'refinada' firma:
// map :: (string -> number) -> Maybe string -> Maybe number
```

### ¿Hay disponibles ejemplos de "la vida real"?

> ver [#77], [#192]

Si aún no has llegado, puedes echar un vistazo al [Capítulo 6](https://github.com/MostlyAdequate/mostly-adequate-guide/blob/master/ch06.md), el cual presenta una aplicación sencilla sobre flick
Pronto llegarán otros ejemplos. Por cierto, ¡eres libre de compartir con nosotros tu experiencia!

### ¿Por qué el libro utiliza ES5? ¿Hay disponible alguna versión con ES6?

> ver [#83], [#235]

El libro pretende ser ampliamente accesible. Empezó antes de la salida de ES6, y, ahora que el nuevo 
standard está siendo más y más aceptado, estamos considerando hacer dos ediciones separadas con
ES5 y ES6. Miembros de la comunidad ya están trabajando en la versión ES6 (echa un vistazo a
[#235] para más información).

### ¿A qué viene esa función reduce?

> ver [#109]

Reduce, accumulate, fold, inject son funciones usuales en programación funcional utilizadas para
combinar sucesivamente los elementos de una estructura de datos. Quizás quieras ver [esta charla]
(https://www.youtube.com/watch?v=JZSoPZUoR58&ab_channel=NewCircleTraining) para obtener más
información sobre la función reduce.

### ¿No podrías utilizar un inglés más simple en lugar del estilo actual?

> ver [#176]

El libro está escrito en su propio estilo, lo cual contribuye a hacerlo consistente como un todo. Si
no estás familiarizado con el inglés, puedes verlo como un buen entrenamiento.
Sin embargo, si alguna vez necesitas ayuda para entender algún significado, ahora
hay [numerosas traducciones](https://github.com/MostlyAdequate/mostly-adequate-guide/blob/master/TRANSLATIONS.md)
disponibles que probablemente te sean de ayuda.

### ¿Qué es Either? ¿Qué es Future? ¿Qué es Task?

> ver [#194]

Vamos presentando todas estas estructuras a lo largo del libro. Por lo tanto, no encontrarás ningún uso
de una estructura que no haya sido previamente definida. No dudes en releer partes antiguas si alguna 
vez sientes incomodidad con estos tipos.
Al final habrá un glosario/vademécum que sintetizará todos estos conceptos.

### ¿De dónde vienen métodos como map, filter, compose...?

> ver [#198]

La mayor parte del tiempo, estos métodos están definidos en librerías de proveedores específicos como
`ramda` o `underscore`. Deberías también echarle un vistazo al [Apéndice A](./appendix_a-es.md), 
[Apéndice B](./appendix_b-es.md) y [Apéndice C](./appendix_c-es.md) en los cuales se definen
numerosas implementaciones utilizadas para los ejercicios. Estas funciones son realmente comunes
en programación funcional y a pesar de que sus implementaciones pueden variar un poco, sus 
significados permanecen bastante constantes entre librerías.


[#6]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/6
[#50]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/50
[#62]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/62
[#77]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/77
[#83]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/83
[#109]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/109
[#176]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/176
[#192]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/192
[#194]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/194
[#198]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/198
[#235]: https://github.com/MostlyAdequate/mostly-adequate-guide/pull/235
