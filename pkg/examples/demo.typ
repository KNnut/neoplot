#import "../lib.typ" as gp

#let title = [Gnuplot demos]
#let subtitle = [in Typst]

#align(
  center,
  text(17pt)[
    *#title*
  ]
    + text(12pt)[
      *#subtitle*
    ],
)

```typ gp.exec(kind: "command", command)``` can be used to run gnuplot commands:

#figure(
  gp.exec(
    kind: "command",
    width: 55%,
    "set term svg size 500, 400; set xrange[-2.5*pi:2.5*pi]; set yrange[-1.3:1.3]; plot sin(x), cos(x)",
  ),
  caption: "Graphs of Sine and Cosine",
)

```typ gp.exec(script)``` can be used to run a gnuplot script:

#figure(
  grid(
    columns: 2,
    rows: 2,
    gutter: 0pt,
    gp.exec(
      width: 90%,
      ```gnuplot
      reset
      set term svg size 600, 400
      set grid
      set samples 21
      set isosample 11
      set xlabel "X axis" offset -3,-2
      set ylabel "Y axis" offset 3,-2
      set zlabel "Z axis" offset -5
      set title "3D surface from a function"
      set label 1 "This is the surface boundary" at -10,-5,150 center
      set arrow 1 from -10,-5,120 to -10,0,0 nohead
      set arrow 2 from -10,-5,120 to 10,0,0 nohead
      set arrow 3 from -10,-5,120 to 0,10,0 nohead
      set arrow 4 from -10,-5,120 to 0,-10,0 nohead
      set xrange [-10:10]
      set yrange [-10:10]
      splot x*y
      ```,
    ),
    gp.exec(
      width: 90%,
      ```gnuplot
      reset
      set grid nopolar
      set grid xtics nomxtics ytics nomytics noztics nomztics nortics nomrtics \
       nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics
      set grid layerdefault lt 0 linecolor 0 linewidth 0.500, lt 0 linecolor 0 linewidth 0.500
      set samples 21, 21
      set isosamples 11, 11
      set style data lines
      set title "3D surface from a function"
      set xlabel "X axis"
      set xlabel offset character -3, -2, 0 font "" textcolor lt -1 norotate
      set xrange [ -10.0000 : 10.0000 ] noreverse nowriteback
      set x2range [ * : * ] noreverse writeback
      set ylabel "Y axis"
      set ylabel offset character 3, -2, 0 font "" textcolor lt -1 rotate
      set yrange [ -10.0000 : 10.0000 ] noreverse nowriteback
      set y2range [ * : * ] noreverse writeback
      set zlabel "Z axis"
      set zlabel offset character -5, 0, 0 font "" textcolor lt -1 norotate
      set zrange [ * : * ] noreverse writeback
      set cbrange [ * : * ] noreverse writeback
      set rrange [ * : * ] noreverse writeback
      splot x**2+y**2, x**2-y**2, (x**3+y**3)/10
      ```,
    ),
    grid.cell(
      colspan: 2,
      gp.exec(
        width: 60%,
        ```gnuplot
        reset
        set term svg size 600, 300
        set title "Mandelbrot function"
        unset parametric
        set mapping cartesian
        set view 60,30,1,1
        set auto
        set isosamples 60
        set hidden3d
        compl(a,b)=a*{1,0}+b*{0,1}
        mand(z,a,n) = n<=0 || abs(z)>100 ? 1:mand(z*z+a,a,n-1)+1
        splot [-2:1][-1.5:1.5] mand({0,0},compl(x,y),30)
        ```,
      ),
    ),
  ),
  caption: "surface1.dem",
)

Notice that Typst caches the results for Wasm functions:
```typ
#gp.exec("reset")                   // Will be executed
#gp.exec(kind: "command", "reset")  // Will be executed
#gp.exec(kind: "command", "reset;") // Will be executed

#gp.exec("reset")                   // Won't be executed, returns the cached result
#gp.exec("reset;")                  // Will be executed
#gp.exec("reset;")                  // Won't be executed, returns the cached result
```

#figure(
  gp.exec(
    width: 85%,
    ```gnuplot
    reset
    set term svg

    set title "Log-scaled axes defined using 'set log'"
    set label 1 "This version of the plot uses\nset logscale x\nset logscale y" at graph 0.5, 0.85, 0 center norotate back nopoint

    set dummy jw, y
    set grid xtics ytics
    set key inside center bottom vertical Right noreverse enhanced autotitle box
    set style data lines
    set xtics border out scale 1,0.5 nomirror
    set ytics border out scale 1,0.5 nomirror
    set ytics norangelimit 0.1 textcolor rgb "dark-violet"
    set y2tics border out scale 1,0.5 nomirror
    set y2tics norangelimit autofreq textcolor rgb "#56b4e9"
    set xlabel "jw (radians)"
    set ylabel "magnitude of A(jw)"
    set y2label "Phase of A(jw) (degrees)"

    set xrange [ 1.1 : 90000.0 ] noextend
    set yrange [ 0.1 : 1.0 ]

    set log x
    set log y
    set ytics nolog

    A(jw) = ({0,1}*jw/({0,1}*jw+p1)) * (1/(1+{0,1}*jw/p2))
    p1 = 10
    p2 = 10000

    plot abs(A(jw)) lt 1, 180/pi*arg(A(jw)) axes x1y2 lt 3
    ```,
  ),
  caption: "nonlinear2.dem",
)

#figure(
  gp.exec(
    width: 90%,
    ```gnuplot
    reset

    set view 49, 28, 1, 1.48
    set urange [ 5 : 35 ] noreverse nowriteback
    set vrange [ 5 : 35 ] noreverse nowriteback
    set ticslevel 0
    set format cb "%4.1f"
    set colorbox user size .03, .6 noborder
    set cbtics scale 0

    set samples 50, 50
    set isosamples 50, 50

    set title "4D data (3D Heat Map)"\
              ."\nIndependent value color-mapped onto 3D surface" offset 0,1
    set xlabel "x" offset 3, 0, 0
    set ylabel "y" offset -5, 0, 0
    set label "z" at graph 0, 0, 1.1
    set pm3d implicit at s

    Z(x,y) = 100. * (sinc(x,y) + 1.5)
    sinc(x,y) = sin(sqrt((x-20.)**2+(y-20.)**2))/sqrt((x-20.)**2+(y-20.)**2)
    color(x,y) = 10. * (1.1 + sin((x-20.)/5.)*cos((y-20.)/10.))

    splot '++' using 1:2:(Z($1,$2)):(color($1,$2)) with pm3d title "4 data columns x/y/z/color"
    ```,
  ),
  caption: "heatmaps.dem",
)

#figure(
  gp.exec(
    width: 85%,
    ```gnuplot
    reset

    set sample 300
    set yrange [-15:5]
    set xrange [-10:2]
    set grid x
    set xtics 1
    set key right center title "lgamma(x)" samplen 0

    set multiplot layout 2,1 title "Effect of 'sharpen' filter"
    plot lgamma(x) title "no filters"
    if (GPVAL_VERSION >= 6.0) {
        plot lgamma(x) sharpen title "  sharpen"
    } else {
        set label 1 center at graph 0.5, 0.5 "This copy of gnuplot does not support 'sharpen'"
        unset key; plot NaN
    }
    unset multiplot
    ```,
  ),
  caption: "sharpen.dem",
)

Datablock can be used in a script:

#figure(
  gp.exec(
    width: 90%,
    ```gnuplot
    reset

    set title "Change in rank over time"
    set title font ":Bold" offset 0,1

    $data <<EOD
    1 2 3 4 5
    1 3 4 2 5
    1 3 4 2 5
    2 1 4 3 5
    1 2 5 3 4
    2 1 4 3 5
    EOD

    set xrange [0.5:6.5]
    set yrange [5.5:0.5]
    set lmargin 7; set tmargin 5
    set border 3
    unset key

    set tics scale 0 nomirror
    set xtics 1,1,6 format "Week %.0g"
    set label 1 "Rank  " right at graph 0, 1.05
    set ytics 1,1,5
    set grid xtics

    plot for [k=1:6] $data using ($0+1):(column(k)):(0.4) with hsteps link lw 1 lc k, \
         for [k=1:6] $data using ($0+1):(column(k)):(0.4) with hsteps nolink lw 6 lc k
    ```,
  ),
  caption: "rank_sequence.dem",
)

#figure(
  gp.exec(
    width: 85%,
    ```gnuplot
    reset

    $Data <<EOD
    1 一 -30
    2 二 -60
    3 三 -90
    4 四 -120
    5 五 -150
    6 六 -180
    7 七 -210
    8 八 -240
    9 九 -270
    10 十 -300
    11 十一 -330
    12 十二 -360
    EOD

    set angle degrees
    unset key
    set title "variable color and orientation in plotstyle 'with labels'" offset 0,-2

    set xrange [0:13]
    set yrange [0:13]
    set xtics 1,1,12 nomirror
    set ytics 1,1,12 nomirror
    set border 3

    plot $Data using 1:1:2:3:0 with labels rotate variable tc variable font ",20"
    ```,
  ),
  caption: "rotate_labels.dem",
)

Read and plot a data file using datablock:

#gp.exec("reset")
#figure(
  gp.exec(
    width: 85%,
    "$data <<EOD\n"
      + read("data/silver.dat")
      + "EOD\n"
      + ```gnuplot
      set title "Error on y represented by filledcurve shaded region"
      set xlabel "Time (sec)"
      set ylabel "Rate"
      set grid xtics mxtics ytics mytics
      set log y
      Shadecolor = "#80E0A080"
      plot $data using 1:($2+$3):($2-$3) \
          with filledcurve fc rgb Shadecolor \
          title "Shaded error region", \
          '' using 1:2 smooth mcspline lw 2 \
          title "Monotonic spline through data"
      ```.text,
  ),
  caption: "errorbars.dem",
)

#figure(
  gp.exec(
    width: 85%,
    ```gnuplot
    reset

    set title "Demo of enhanced text mode using a single UTF-8 encoded font\nThere is another demo that shows how to use a separate Symbol font"
    set xrange [-1:1]
    set yrange [-0.5:1.1]
    set format xy "%.1f"
    set arrow from 0.5, -0.5 to 0.5, 0.0 nohead

    set label 1 at -0.65, 0.95
    set label 1 "Superscripts and subscripts:" tc lt 3

    set label 3 at -0.55, 0.85
    set label 3 'A_{j,k} 10^{-2}  x@^2_k    x@_0^{-3/2}y'

    set label 5 at -0.55, 0.7
    set label 5 "Space-holders:" tc lt 3
    set label 6 at -0.45, 0.6
    set label 6 "<&{{/=20 B}ig}> <&{x@_0^{-3/2}y}> holds space for"
    set label 7 at -0.45, 0.5
    set label 7 "<{{/=20 B}ig}> <{x@_0^{-3/2}y}>"

    set label 8 at -0.9, -0.2
    set label 8 "Overprint\n(v should be centred over d)" tc lt 3
    set label 9 at -0.85, -0.4
    set label 9 " ~{abcdefg}{0.8v}"

    set label 10 at -.40, 0.35
    set label 10 "UTF-8 encoding does not require Symbol font:" tc lt 3
    set label 11 at -.30, 0.2
    set label 11 "{/*1.5 ∫@_{/=9.6 0}^{/=12 ∞}} {e^{-{μ}^2/2} d}{μ=(π/2)^{1/2}}"

    set label 21 at 0.5, -.1
    set label 21 "Left  ^{centered} ƒ(αβγδεζ)" left
    set label 22 at 0.5, -.2
    set label 22 "Right ^{centered} ƒ(αβγδεζ)" right
    set label 23 at 0.5, -.3
    set label 23 "Center^{centered} ƒ(αβγδεζ)" center

    set label 30 at -.9, 0.0 "{/:Bold Bold} and {/:Italic Italic} markup"

    set key title " "
    plot sin(x)**2 lt 2 lw 2 title "sin^2(x)"
    ```,
  ),
  caption: "enhanced_utf8.dem",
)

#figure(
  gp.exec(
    width: 85%,
    ```gnuplot
    reset
    set view equal xy
    set zzeroaxis; set xzeroaxis; set yzeroaxis
    set xyplane at 0
    unset border
    unset key
    unset xtics
    unset ytics
    set ztics axis

    set arrow 1 from 0,0,0 to 1,0,0 head filled lw 1.5
    set label 1 at 1.2,0,0 "X" center
    set arrow 2 from 0,0,0 to 0,1,0 head filled lw 1.5
    set label 2 at 0,1.2,0 "Y" center
    set arrow 3 from 0,0,0 to 0,0,21 head filled lw 1.5
    set label 3 at 0,0,23 "Z" center

    set view 60, 30, 1., 1.75

    set multiplot layout 1,3

    set view azimuth 0.
    set title 'azimuth 0' offset 0,2
    splot sample [t=0:20] '+' using (cos($1)):(sin($1)):($1) with lines lw 2

    set title 'azimuth 10' offset 0,2
    set view azimuth 10.
    replot

    set title 'azimuth 60' offset 0,2
    set view azimuth 60.
    replot

    unset multiplot
    ```,
  ),
  caption: "azimuth.dem",
)

#figure(
  gp.exec(
    width: 90%,
    "test",
  ),
  caption: "The current terminal",
)

#figure(
  gp.exec(
    width: 90%,
    "reset; set palette viridis; test palette",
  ),
  caption: "The current palette",
)
