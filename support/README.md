# La Más Que Adecuada Guía de Programación Funcional - Soporte

## Información General 

Este paquete contiene todas las funciones y estructuras de datos referenciadas en los 
apéndices de [La Guía del Profesor Frisby en su Mayor Parte Adecuada para la Programación Funcional](https://github.com/MostlyAdequate/mostly-adequate-guide-es).

Estas funciones tienen un propósito pedagógico y no pretenden que sean utilizadas en
ningún entorno en producción. Son sin embargo, un buen material de aprendizaje para
cualquiera interesado en la programación funcional.

## Cómo instalarlo

La versión en inglés del paquete está disponible en `npm` y puede instalarse mediante el siguiente conjuro:

```
npm install @mostly-adequate/support
```

## Cómo utilizarlo

El módulo no está estructurado de ninguna forma en particular, todo está plano y exportado
desde la raíz (el lector curioso puede echar un vistazo rápido al `index.js` para quedar convencido).

Además, todas la funciones del nivel superior, están currificadas para que no tengas que preocuparte de
llamar a `curry` en ninguna de ellas.

Por ejemplo:

```js
const { Maybe, liftA2, append, concat, reverse } = require('@mostly-adequate/support');

const a = Maybe.of("yltsoM").map(reverse);
const b = Maybe.of("Adequate").map(concat(" "));

liftA2(append)(b)(a);
// Just("Mostly Adequate")
```
