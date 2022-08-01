# Los Ejercicios Más Adecuados

## Información General

Todos los ejercicios del libro pueden completarse de dos maneras:

- en el navegador (utilizando la versión del libro publicada en [gitbook.io](https://mostly-adequate.gitbooks.io/mostly-adequate-guide/))
- en tu editor y terminal, usando `npm`

En cada carpeta llamada `ch**` de esta carpeta `exercises/`, encontrarás tres tipos de archivos:

- exercises
- solutions
- validations

Los ejercicios están estructurados con un enunciado en un comentario, seguido por una función incompleta o incorrecta. Por ejemplo, el `exercise_a` del `ch04` luce así:


```js
// Refactor to remove all arguments by partially applying the function.

// words :: String -> [String]
const words = str => split(' ', str);
```

Siguiendo el enunciado, tu objetivo es refactorizar la función `words` que se te proporciona. Una vez hecho, 
tu propuesta puede ser verificada ejecutando:

```
npm run ch04
```

Alternativamente, también puedes echar un vistazo al archivo con la solución que corresponda: en este caso
`solution_a.js`. 

> Los archivos `validation_*.js` realmente no forman parte de los ejercicios, pero son utilizados
> internamente para verificar tu propuesta y dar pistas cuando procede. El lector curioso 
> puede echarles un ojo :).

¡Ahora ve y aprende algo de programación funcional λ!

## Sobre Los Apéndices

Aviso importante: el ejecutor de los ejercicios se encarga de traer al contexto
de ejecución todas las estructuras de datos y funciones de los apéndices. Por esto, 
¡puedes dar por hecho que cualquier función presente en los apéndices está
disponible para que puedas utilizarla! Increíble, ¿verdad?
