#import "../lib.typ" as gp

#let title = [Examples in README]

#align(center,
    text(17pt)[
        *#title*
    ]
)

Neoplot is a Typst package to use #link("http://www.gnuplot.info/")[gnuplot] in Typst.

#gp.exec("set term svg size 420,160")

Execute gnuplot commands:
````typ
#gp.exec(
    kind: "command",
    ```gnuplot
    reset;
    set samples 1000;
    plot sin(x),
         cos(x)
    ```
)
````
#gp.exec(
    kind: "command",
    ```gnuplot
    reset;
    set samples 1000;
    plot sin(x),
         cos(x)
    ```
)

Execute a gnuplot script:
````typ
#gp.exec(
    ```gnuplot
    reset
    # Can add comments since it is a script
    set samples 1000
    # Use a backslash to extend commands
    plot sin(x), \
         cos(x)
    ```
)
````
#gp.exec(
    ```gnuplot
    reset
    # Can add comments since it is a script
    set samples 1000
    # Use a backslash to extend commands
    plot sin(x), \
         cos(x)
    ```
)

To read a data file:
#raw(
    block: true,
    read("data/datafile.dat")
)

````typ
#gp.exec(
    ```gnuplot
    $data <<EOD
    0  0
    2  4
    4  0
    EOD
    plot $data with linespoints
    ```
)
````
#gp.exec(
    ```gnuplot
    $data <<EOD
    0  0
    2  4
    4  0
    EOD
    plot $data with linespoints
    ```
)

or
```typ
#gp.exec(
    // Use a datablock since Typst doesn't support WASI
    "$data <<EOD\n" +
    // Load "data/datafile.dat" using Typst
    read("data/datafile.dat") +
    "EOD\n" +
    "plot $data with linespoints"
)
```
#gp.exec(
    // Use a datablock since Typst doesn't support WASI
    "$data <<EOD\n" +
    // Load "data/datafile.dat" using Typst
    read("data/datafile.dat") +
    "EOD\n" +
    "plot $data with linespoints"
)

To print ```gnuplot $data```:
```typ
#gp.exec("print $data")
```
#gp.exec("print $data")
