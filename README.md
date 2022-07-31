[![cover](images/cover.png)](SUMMARY.md)

## Sobre este libro

Este es un libro sobre el paradigma funcional en general. Utilizaremos el lenguaje de programación funcional más popular del mundo: JavaScript. Algunos pueden pensar que es una mala elección ya que va en contra de la cultura que, por el momento, se siente predominantemente imperativa. Sin embargo, creo que esta es la mejor forma de aprender PF por diversas razones:

 * **Seguramente lo utilizes cada día en el trabajo.**

    Esto hace posible practicar y aplicar cada día en programas del mundo real los conocimientos adquiridos en vez de en proyectos de una sola noche o de un fin de semana con un lenguaje de PF esotérico.

 * **No tenemos que aprenderlo todo desde cero para empezar a escribir programas**

    En un lenguaje funcional puro, no puedes registrar una variable o leer un nodo DOM sin usar mónadas. Aquí podemos hacer un poco de trampas mientras aprendemos a purificar nuestra base de código. También es más fácil empezar con este lenguaje debido a su paradigma mixto y a que te puedes apoyar en lo que ya conoces mientras haya huecos en tu conocimiento.


 * **El lenguaje está completamente capacitado para escribir código funcional de primera categoría.**

    Tenemos todas las características necesarias para imitar a un lenguaje como Scala o Haskell con la ayuda de una o dos pequeñas librerías. La programación orientada a objetos domina actualmente la industria, pero es claramente torpe en JavaScript. Es similar a acampar en una autopista o bailar claqué con botas de agua. Tenemos que hacer `bind` en todos los lados para que `this` no cambie sin nosotros saberlo, tenemos varias soluciones para el extraño comportamiento cuando olvidas usar `new`, los miembros privados solo están disponibles mediante closures. Para muchos de nosotros, la PF parace más natural de todos modos.

Dicho esto, lenguajes funcionales tipados serán, sin duda alguna, el mejor lugar para programar con el estilo que se presenta en este libro. JavaScript será nuesto medio para aprender un paradigma, donde lo apliques depende de tí. Afortunadamente, las interfaces son matemáticas y, como tal, ubicuas. Te sentirás como en casa con Swiftz, Scalaz, Haskell, PureScript, y otros entornos inclinados hacia las matemáticas.


## Léelo Online

Para una mejor experiencia de lectura, [léelo online a través de Gitbook](https://mostly-adequate.gitbooks.io/mostly-adequate-guide/).

- Barra lateral de acceso rápido
- Ejercicos en el propio navegador
- Ejemplos en profundidad


## Juega Con el Código

Para que el entrenmiento sea más efectivo y no aburrirte demasiado cuando te estoy contando otra história, asegúrate de jugar con los conceptos introducidos en este libro. Algunos pueden ser difíciles de entender a la primera y se comprenden mejor cuándo te ensucias las manos.
Todas las funciones y estructuras de datos algebráicas presentadas en el libro están reunidas en los apéndices. El correspondiente código también está disponible como un módulo de npm:

```bash
$ npm i @mostly-adequate/support
```

Alternativamente, ¡los ejercicios de cada capítulo son ejecutables y pueden ser completados en tu editor! Por ejemplo, completa el `exercise_*.js` en `exercises/ch04` y después ejecuta:

```bash
$ npm run ch04
```

## Descárgalo

Encuentra **PDF** y **EPUB** pregenerados como [artefactos construídos de la última versión inglesa](https://github.com/MostlyAdequate/mostly-adequate-guide/releases/latest) 

## Hazlo tú mismo

> ⚠️ La preparación del proyecto es un poco antigua, puedes encontrarte con distintos problemas cuando lo contruyas localmente. Recomendamos el uso de node v10.22.1 y la útlima versión de Calibre si es posible. 

```
git clone https://github.com/MostlyAdequate/mostly-adequate-guide-es.git
cd mostly-adequate-guide-es/
npm install
npm run setup
npm run generate-pdf
npm run generate-epub
```

> ¡Nota! Para generar la versión ebook necesitarás instalar `ebook-convert`. [Instrucciones de
> instalación](https://gitbookio.gitbooks.io/documentation/content/build/ebookconvert.html).

# Contenido

Ver [SUMMARY-es.md](SUMMARY-es.md)

### Contribuir

Ver [CONTRIBUTING-es.md](CONTRIBUTING-es.md)

### Traducciones

Ver [TRANSLATIONS-es.md](TRANSLATIONS-es.md)

### FAQ

Ver [FAQ-es.md](FAQ-es.md)



# Planes para el futuro

* **Parte 1** (capítulos 1-7) es una guia básica. La actualizaré a medida que encuentre errores ya que esto es un borrador inicial. ¡Siéntete libre de ayudar!
* **Parte 2** (capítulos 8-13) aborda clases de tipos como functores y mónadas de forma transversal. Espero poder meterme con transformers y con una aplicacion pura.
* **Parte 3** (capítulos 14+) cruzará la delgada línea entre la programación práctica y la absurdidad académica. Veremos comónadas, f-algebras, mónadas libres, yoneda, y otras construcciones categóricas.


---


<p align="center">
  <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/deed.es">
    <img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" />
  </a>
  <br />
  Este trabajo está licenciado bajo <a rel="license" href="https://creativecommons.org/licenses/by-sa/4.0/deed.es">licencia Creative Commons Atribución-CompartirIgual 4.0 Internacional</a>.
</p>
