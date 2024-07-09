#import "../lib.typ" as gp

#let title = [Examples in README]

#align(center,
    text(17pt)[
        *#title*
    ]
)

Neoplot is a Typst package to use #link("http://www.gnuplot.info/")[gnuplot] in Typst.

#let _ = gp.eval("set term svg size 420,160")

Execute gnuplot commands as a *one-line* command:
```typ
#image.decode(
    gp.eval("
        set samples 1000;
        set xlabel 'x axis';
        set ylabel 'y axis';
        plot sin(x),
             cos(x)
    ")
)
```
#image.decode(
    gp.eval("
        set samples 1000;
        set xlabel 'x axis';
        set ylabel 'y axis';
        plot sin(x),
             cos(x)
    ")
)

is the equivalent of
```typ
#image.decode(
    gp.eval("set samples 1000;set xlabel 'x axis';set ylabel 'y axis';plot sin(x),cos(x)")
)
```
#image.decode(
    gp.eval("set samples 1000;set xlabel 'x axis';set ylabel 'y axis';plot sin(x),cos(x)")
)

Execute a gnuplot script:
````typ
#image.decode(
    gp.exec(
        ```gnuplot
        # Can add comments since this is a script
        set samples 1000
        set xlabel 'x axis'
        set ylabel 'y axis'
        # Use a backslash to extend commands
        plot sin(x), \
             cos(x)
        ```
    )
)
````
#image.decode(
    gp.exec(
        ```gnuplot
        # Can add comments since this is a script
        set samples 1000
        set xlabel 'x axis'
        set ylabel 'y axis'
        # Use a backslash to extend commands
        plot sin(x), \
             cos(x)
        ```
    )
)

To read a data file:
#raw(
    block: true,
    read("data/datafile.dat")
)

```typ
#image.decode(
    gp.exec(
        // Use a datablock since Typst doesn't support WASI
        "$data <<EOD\n" +
        // Load "data/datafile.dat" using Typst
        read("data/datafile.dat") +
        "EOD\n" +
        "plot $data w lp"
    )
)
```
#image.decode(
    gp.exec(
        // Use a datablock since Typst doesn't support WASI
        "$data <<EOD\n" +
        // Load "data/datafile.dat" using Typst
        read("data/datafile.dat") +
        "EOD\n" +
        "plot $data w lp"
    )
)

is equivalent to
````typ
#image.decode(
    gp.exec(
        ```gnuplot
        $data <<EOD
        0  0
        2  4
        4  0
        EOD
        plot $data w lp
        ```
    )
)
````
#image.decode(
    gp.exec(
        ```gnuplot
        $data <<EOD
        0  0
        2  4
        4  0
        EOD
        plot $data w lp
        ```
    )
)
