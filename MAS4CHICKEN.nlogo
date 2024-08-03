extensions [ nw bitmap ]

breed [clients client]
breed [waiters waiter]
breed [chefs chef]
breed [nodes node]

clients-own [
  waiting-time
  waiting-threshold
  time
  quantity
  ;served
  ;satisfaction
  chef-id
  food-ready
  time-go
]
waiters-own [
  ;chef-id
  ;client-id
  location
  path
  orders
  delay
]
chefs-own [
  food-time
  working-time
  delay
]

globals [
  ;; Info general de las parcelas
  patch-data
  ;; Parcelas específicas
  polleria-patches
  cocina-patches
  staff-patches
  mesas-patches
  ;; Nodos
  ;mesa-node
  ; cocina-node  ; Spawn de cocineros
  ; entrada-node ; Spawn de comensales
  ; staff-node   ; Spawn de meseros
  ;; Misceláneos
  total-waiting-time
  happy-clients
  unhappy-clients
]

to loadMap
  let file user-file
  set patch-data []

  if (file != false) [
    file-open file
    while [not file-at-end?] [
      set patch-data sentence patch-data (list(list file-read file-read file-read))
    ]

    user-message "¡Mapa cargado exitosamente!"
    file-close
  ]
end

to loaddefaultMap [file]
  set patch-data []

  if (file != false) [
    file-open file
    while [not file-at-end?] [
      set patch-data sentence patch-data (list(list file-read file-read file-read))
    ]

    user-message "¡Mapa cargado exitosamente!"
    file-close
  ]
end

to showMap
  ifelse (is-list? patch-data) [
    foreach patch-data [ three-tuple ->
      ask patch first three-tuple item 1 three-tuple [ set pcolor last three-tuple ]
    ]
  ] [
    user-message "AVISO: Se requiere haber cargado el mapa."
  ]

  display
end

to setup

  ;;show patch-data
  ifelse (patch-data = 0)
  [;; cargar mapa por defecto
    clear-all
    ifelse (Mapa = 0)
    [loaddefaultMap "./mapGenerator/MAS4CHICKEN_map0.txt"]
    [ ifelse (Mapa = 1)
      [loaddefaultMap "./mapGenerator/MAS4CHICKEN_map1.txt"]
      [loaddefaultMap "./mapGenerator/MAS4CHICKEN_map2.txt"]
    ]
    showMap
    user-message "Mapa por defecto"
  ]
  [showMap]

  reset-ticks
  set total-waiting-time []
  set happy-clients 0
  set unhappy-clients 0

  let legend bitmap:import "./assets/images/leyenda.png"
  bitmap:copy-to-drawing legend 0 0

  let LOGO bitmap:import "./assets/images/Logo MAS4CHICKEN.png"
  bitmap:copy-to-drawing LOGO 350 0

  ask clients [die]
  ask waiters [die]
  ask chefs [die]
  ask nodes [die]
  ask links [die]
  clear-plot

  set MESEROS   max list 1 MESEROS
  set COCINEROS max list 1 COCINEROS

  set polleria-patches patches with [pcolor = yellow]
  set mesas-patches patches with [pcolor = brown]
  set cocina-patches patches with [pcolor = (gray - 1)]
  set staff-patches patches with [pcolor = gray]
  set-patch-size 20

  ask patches with [pcolor != 0] [ sprout-nodes 1]
  ask nodes [ create-links-with nodes-on neighbors]

  ask nodes [
    set hidden? true
    ;;set shape "dot"
    ;;set size 1
    ;;set label who
  ]

  ; ask patch 0 0 [
  ;   set entrada-node one-of nodes-at 5 5
  ;   set mesa-node one-of nodes-at -5 5
  ;   set cocina-node one-of nodes-at 5 -5
  ; ]

  create-waiters MESEROS [
    set color 123
    set size 2

    ;;show location

    set path []
    set label orders
    set label-color black
    set shape "waiter-icon3"
    set color blue

    let c one-of staff-patches
    set xcor [pxcor] of c
    set ycor [pycor] of c

    set delay 0
    set location one-of nodes-here
    move-to location
  ]

  create-chefs COCINEROS [
    ;;set color magenta
    set size 2
    set food-time ((random 5) + 10) * 60

    set label-color black
    set shape "chef-icon3"
    set color white

    let c one-of cocina-patches
    set xcor [pxcor] of c
    set ycor [pycor] of c
    set working-time 0
    set label working-time / 60
    ; setxy [pxcor pycord] of one-of cocina-patches
  ]

  ask links [set color 7]

end

to go
  if ticks = 8 * 60 * 60
  [ stop ]
  ;; Intervalor clientes
  if remainder ticks (INTERVALO-CLIENTES * 60) = 0 [
    ask one-of mesas-patches [
      let posclient one-of nodes-here
      let length-wait 0
      let poschef 0

      let w first sort-by [[a b] -> [ orders ] of a < [ orders ] of b ] waiters
      ask w [
        set orders orders + 1
        set label orders
        set label-color black
        let poswaiter 0
        ifelse empty? path
        [
          set poswaiter one-of nodes-here
        ][
          let p last path
          ifelse is-list? p
          [
            let l one-of p
            set poswaiter l
          ]
          [
           set poswaiter p
          ]
        ]

        let time-chef 0

        let c first sort-by [[a b] -> [ working-time ] of a < [ working-time ] of b ] chefs
        ask c [
          set poschef one-of nodes-here
          set working-time working-time + food-time
          set time-chef working-time
        ]

        let path1 path-from-to poswaiter posclient
        foreach path1 [x -> set path lput x path]

        let path2 path-from-to posclient poschef
        foreach path2 [x -> set path lput x path]

        ;;foreach range time-to-prepare [x -> set path lput poschef path]

        ;;let path3 path-from-to poschef posclient
        ;;foreach path3 [x -> set path lput x path]

        set length-wait (length path + time-chef)

        ;;set total-waiting-time lput length path total-waiting-time
      ]

      sprout-clients 1
      [
        set quantity (random 3) + 1
        show quantity
        set waiting-time length-wait
        if quantity = 1
        [ set waiting-threshold ((random 5) + 10) * 60
          set shape "client-icon"
        ]
        if quantity = 2
        [ set waiting-threshold ((random 5) + 15) * 60
          set shape "client-icon2"
        ]
        if quantity = 3
        [ set waiting-threshold ((random 5) + 20) * 60
          set shape "client-icon3"
        ]

        set time 0
        set time-go length-wait
        set color lime

        set size 2
        set label-color black
        set chef-id poschef
        set food-ready false
      ]
    ]
  ]
  ;; Intervalo Chef
  if remainder (ticks + 1) (INTERVALO-DEMORA * 60) = 0 [
    let r random 2
    ifelse r = 0
    [;; mesero
      if any? waiters with [empty? path]
      [
        let w one-of waiters with [empty? path]
        ask w [
          set color cyan
          set delay 5 * 60
          repeat 5 * 60 [ set path lput (one-of nodes-here) path]
        ]
      ]
    ]
    [;; cocinero
      if any? chefs with [working-time = 0]
      [
        let c one-of chefs with [working-time = 0]
        ask c [
          set color cyan
          set delay 5 * 60
          set working-time delay
        ]
      ]
    ]
  ]
  ;;ask clients [
  ;;  if not served [set waiting-time waiting-time + 1]
  ;;]
  ask waiters [
    let new-location 0

    set delay delay - 1
    if delay = 0 [ set color blue]

    ifelse empty? path
    [
      set new-location one-of [link-neighbors] of location
      move-to new-location
      set location new-location
    ]
    [
      let p first path
      ;;show p
      ;;show path
      ifelse is-list? p
      [
        let l one-of p
        set new-location l
        set path remove-item 0 path
        move-to new-location
        set location new-location
      ]
      [
        set new-location p
        set path remove-item 0 path
        move-to new-location
        set location new-location
      ]
    ]
  ]
  ask clients [
    set waiting-time waiting-time - 1
    set time time + 1

    ifelse time >  waiting-threshold [set color red]
    [ifelse time > (waiting-threshold / 2) [set color yellow]
      [set color lime]]

    if waiting-time = 0 [
      ifelse food-ready = true [
        die
      ]
      [
        let poschef chef-id
        let posclient one-of nodes-here
        let length-wait 0

        let w first sort-by [[a b] -> [ orders ] of a < [ orders ] of b ] waiters
        ask w [
          set orders orders + 1
          set label orders
          let poswaiter one-of nodes-here

          let path1 path-from-to poswaiter poschef
          foreach path1 [x -> set path lput x path]

          let path2 path-from-to poschef posclient
          foreach path2 [x -> set path lput x path]

          ;;foreach range time-to-prepare [x -> set path lput poschef path]

          ;;let path3 path-from-to poschef posclient
          ;;foreach path3 [x -> set path lput x path]

          set length-wait length path

        ]
        let total-time (length-wait + time-go)
        ifelse total-time >= waiting-threshold
        [ set unhappy-clients unhappy-clients + 1 ]
        [ set happy-clients happy-clients + 1 ]

        set total-waiting-time lput  total-time total-waiting-time
        set waiting-time length-wait
        set food-ready true
      ]
    ]

    set label precision (time / 60) 2
    set label-color black
  ]

  ask chefs [
    set working-time working-time - 1
    set delay delay - 1
    if delay = 0 [set color white ]
    if working-time < 0 [ set working-time 0 ]
    set label precision (working-time / 60) 2
  ]
  tick
end

to-report path-from-to [source target]
  let p []
  ask source [

    set p nw:turtles-on-path-to target
  ]
  report p
end

to-report get-waiting-time
  ifelse empty? total-waiting-time
  [ report 0 ]
  [ let totalsec mean total-waiting-time
    report totalsec / 60
  ]
end

to-report get-hours
  report floor (ticks / 3600)
end

to-report get-minutes
  let h floor (ticks / 3600)
  report floor ((ticks - h * 3600) / 60)
end

to-report get-seconds
  let h floor (ticks / 3600)
  let m floor ((ticks - h * 3600) / 60)
  report ticks - (h * 3600) - (m * 60)
end

to-report get-satisfaction
  ifelse (happy-clients + unhappy-clients) = 0
  [report 0]
  [report 100 * (happy-clients / (happy-clients + unhappy-clients))]
end
@#$#@#$#@
GRAPHICS-WINDOW
57
182
1685
1811
-1
-1
20.0
1
14
1
1
1
0
0
0
1
-40
40
-40
40
0
0
1
ticks
30.0

INPUTBOX
43
22
135
82
Meseros
4.0
1
0
Number

INPUTBOX
139
22
231
82
Cocineros
3.0
1
0
Number

SLIDER
240
22
412
55
Intervalo-Clientes
Intervalo-Clientes
0
10
5.0
0.1
1
min
HORIZONTAL

BUTTON
430
76
511
109
Inicializar
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
431
120
503
153
Simular
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
549
10
749
55
Tiempo promedio de espera (min)
get-waiting-time
5
1
11

PLOT
548
55
748
205
Trabajo total por tiempo transcurrido
Tiempo
Trabajo total
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (sum [waiting-time] of clients) / 60"

BUTTON
430
32
531
65
Cargar mapa
loadMap
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
58
134
108
179
Hrs
get-hours
0
1
11

MONITOR
106
134
156
179
Min
get-minutes
0
1
11

MONITOR
155
134
205
179
Seg
get-seconds
0
1
11

MONITOR
768
11
909
56
Clientes satisfechos
happy-clients
0
1
11

MONITOR
768
58
908
103
Clientes no satisfechos
unhappy-clients
17
1
11

SLIDER
241
67
413
100
Intervalo-Demora
Intervalo-Demora
0
60
5.0
5
1
min
HORIZONTAL

MONITOR
769
105
908
150
% Clientes satisfechos
get-satisfaction
2
1
11

CHOOSER
240
111
413
156
Mapa
Mapa
0 1 2
2

@#$#@#$#@
## ¿QUÉ ES?

MAS4CHICKEN es un simulador basado en Sistemas Multiagente, el cual simulará el comportamiento entre Cocineros, Meseros y Comensales.

## ¿CÓMO FUNCIONA?

Primero, se tiene que cargar el mapa a evaluar. Luego, se tienen que ajustar los parámetros deseados. Una vez que estos estén adecuadamente configurados, se procede a iniciar la simulación.

## ¿CÓMO SE USA?

Empezamos por cargar el mapa del restaurante deseado.Una vez completado este paso, procedemos a "Inicializar el programa". Este proceso depende de varios factores: el mapa cargado, el número de meseros y de cocineros, el intervalo de clientes, y el Intervalo de demora del personal. Al inicializar el programa, se generarán los nodos sobre los cuales se desplazarán los agentes. Asimismo, se generarán los agentes en sus respectivos espacios.

Para empezar la simulación, se debe presionar "Simular". Durante la ejecución del modelo, se puede modificar una variable llamada "Intervalo-Clientes", el cual determina el intervalo de tiempo cuando un nuevo cliente aparecerá en el sistema, e "Intervalo-Demora", el cual determina el intervalo de tiempo cuando un mesero o cocinero pasa a un estado no disponible, esto representa el tiempo empleado en los servicios higiénicos, un accidente no grave, o una llamada importante.

Para monitorear el desempeño de los agentes, se tienen los siguientes elementos:

- Tiempo promedio de espera (min).
- Gráfica del trabajo total por tiempo transcurrido.
- Contador de HH:MM:SS.
- Conteo de Clientes Satisfechos/No Satisfechos.
- Porcentaje de Clientes Satisfechos.


## PARA PROBAR

Previo a la inicialización, se pueden modificar tres variables: El conteo de cocineros y meseros, y el intervalo de clientes. Las dos primeras tienen que ser valores mayores a 1. La variable de intervalo de clientes puede ser modificada incluso durante la ejecución. Esta se encuentra en un rango de 1 a 100. Recordar que esta indica intervalo de llegade de nuevos clientes.

## EXTENDIENDO EL MODELO

Se puede extender el modelo añadiendo visualización en 3D y ejecutando algorítmos de grafos más sofisticados.

## A TOMAR EN CUENTA

El presente modelo está diseñado para ser ejecutado en la versión de escritorio de NetLogo, debido a que la versión web carece de ciertas características tales como: entrada/salida de archivos, librerías como nw (grafos) manejo de imágenes (bitmap), etc.

## CRÉDITOS Y REFERENCIAS

El modelo forma parte de una tesis para obtener el titulo profesional de ciencias de la computación, los autores son:

- Nander Emanuel Meléndez Huamanchumo
- Jack Yefri Cruz Mamani

Se puede acceder a este modelo y a todos sus componentes a través del siguiente enlace de Github: https://github.com/u201922331/MAS4CHICKEN
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

chef-icon
false
0
Circle -2064490 true false 92 92 118
Rectangle -16777216 true false 120 135 135 150
Rectangle -16777216 true false 165 135 180 150
Line -16777216 false 120 180 180 180
Rectangle -16777216 true false 120 165 180 180
Rectangle -1 true false 105 45 195 120
Rectangle -1 true false 90 30 105 45
Rectangle -1 true false 120 30 120 45
Rectangle -1 true false 105 30 120 45
Rectangle -1 true false 135 30 165 45
Rectangle -1 true false 180 30 195 45
Rectangle -1 true false 195 30 210 45
Rectangle -1 true false 75 210 225 315

chef-icon2
false
0
Circle -2064490 true false 92 92 118
Rectangle -16777216 true false 120 135 135 150
Rectangle -16777216 true false 165 135 180 150
Line -16777216 false 120 180 180 180
Rectangle -16777216 true false 120 165 180 180
Rectangle -1 true false 105 45 195 120
Rectangle -13840069 true false 90 30 105 45
Rectangle -1 true false 120 30 120 45
Rectangle -13840069 true false 105 30 120 45
Rectangle -13840069 true false 135 30 165 45
Rectangle -13840069 true false 180 30 195 45
Rectangle -13840069 true false 195 30 210 45
Rectangle -1 true false 75 210 225 315
Rectangle -13840069 true false 75 210 225 300
Rectangle -13840069 true false 105 45 195 120

chef-icon3
false
0
Circle -2064490 true false 92 92 118
Rectangle -16777216 true false 120 135 135 150
Rectangle -16777216 true false 165 135 180 150
Line -16777216 false 120 180 180 180
Rectangle -16777216 true false 120 165 180 180
Rectangle -1 true false 105 45 195 120
Rectangle -13840069 true false 90 30 105 45
Rectangle -1 true false 120 30 120 45
Rectangle -13840069 true false 105 30 120 45
Rectangle -13840069 true false 135 30 165 45
Rectangle -13840069 true false 180 30 195 45
Rectangle -13840069 true false 195 30 210 45
Rectangle -1 true false 75 210 225 315
Rectangle -13840069 true false 75 210 225 300
Rectangle -13840069 true false 105 45 195 120
Rectangle -7500403 true true 90 30 120 45
Rectangle -7500403 true true 135 30 165 45
Rectangle -7500403 true true 180 30 210 45
Rectangle -7500403 true true 105 45 195 120
Rectangle -7500403 true true 75 210 225 300

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

client-icon
false
0
Circle -2064490 true false 92 92 118
Rectangle -16777216 true false 120 135 135 150
Rectangle -16777216 true false 165 135 180 150
Line -16777216 false 120 180 180 180
Rectangle -16777216 true false 120 165 180 180
Rectangle -1 true false 120 30 120 45
Rectangle -1 true false 75 210 225 315
Rectangle -7500403 true true 75 210 225 300
Polygon -7500403 true true 105 75 195 75 225 150 195 120 105 120 75 150 105 75

client-icon2
false
0
Circle -2064490 true false 182 92 118
Rectangle -16777216 true false 210 135 225 150
Rectangle -16777216 true false 255 135 270 150
Line -16777216 false 120 180 180 180
Rectangle -16777216 true false 210 165 270 180
Rectangle -1 true false 120 30 120 45
Rectangle -7500403 true true 150 210 300 300
Polygon -7500403 true true 195 75 285 75 315 150 285 120 195 120 165 150 195 75
Rectangle -7500403 true true -15 210 135 300
Circle -2064490 true false 2 92 118
Rectangle -16777216 true false 30 135 45 150
Rectangle -16777216 true false 75 135 90 150
Rectangle -16777216 true false 30 165 90 180
Polygon -7500403 true true 15 75 105 75 135 150 105 120 15 120 -15 150 15 75

client-icon3
false
0
Rectangle -7500403 true true 75 90 225 180
Circle -2064490 true false 182 92 118
Rectangle -16777216 true false 210 135 225 150
Rectangle -16777216 true false 255 135 270 150
Line -16777216 false 120 180 180 180
Rectangle -16777216 true false 210 165 270 180
Rectangle -1 true false 120 30 120 45
Rectangle -7500403 true true 150 210 300 300
Polygon -7500403 true true 195 75 285 75 315 150 285 120 195 120 165 150 195 75
Rectangle -7500403 true true -15 210 135 300
Circle -2064490 true false 2 92 118
Rectangle -16777216 true false 30 135 45 150
Rectangle -16777216 true false 75 135 90 150
Rectangle -16777216 true false 30 165 90 180
Polygon -7500403 true true 15 75 105 75 135 150 105 120 15 120 -15 150 15 75
Circle -2064490 true false 92 2 118
Polygon -7500403 true true 105 -15 195 -15 225 60 195 30 105 30 75 60 105 -15
Rectangle -16777216 true false 120 45 135 60
Rectangle -16777216 true false 165 45 180 60
Rectangle -16777216 true false 120 75 180 90

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

waiter-icon
false
0
Circle -2064490 true false 92 92 118
Rectangle -16777216 true false 120 135 135 150
Rectangle -16777216 true false 165 135 180 150
Line -16777216 false 120 180 180 180
Rectangle -16777216 true false 120 165 180 180
Rectangle -1 true false 120 30 120 45
Rectangle -1 true false 75 210 225 300
Circle -6459832 true false 105 90 30
Circle -6459832 true false 120 90 30
Circle -6459832 true false 135 90 30
Circle -6459832 true false 150 90 30
Circle -6459832 true false 165 90 30
Circle -6459832 true false 330 135 30
Rectangle -16777216 true false 120 210 135 240
Rectangle -16777216 true false 165 210 180 240
Rectangle -16777216 true false 135 225 150 225
Rectangle -16777216 true false 135 210 165 225

waiter-icon2
false
0
Circle -2064490 true false 92 92 118
Rectangle -16777216 true false 120 135 135 150
Rectangle -16777216 true false 165 135 180 150
Line -16777216 false 120 180 180 180
Rectangle -16777216 true false 120 165 180 180
Rectangle -1 true false 120 30 120 45
Rectangle -1 true false 75 210 225 300
Circle -6459832 true false 105 90 30
Circle -6459832 true false 120 90 30
Circle -6459832 true false 135 90 30
Circle -6459832 true false 150 90 30
Circle -6459832 true false 165 90 30
Circle -6459832 true false 330 135 30
Rectangle -16777216 true false 120 210 135 240
Rectangle -16777216 true false 165 210 180 240
Rectangle -16777216 true false 135 225 150 225
Rectangle -16777216 true false 135 210 165 225
Rectangle -13840069 true false 75 210 120 300
Rectangle -13840069 true false 120 240 225 300
Rectangle -13840069 true false 135 225 165 240
Rectangle -13840069 true false 180 210 225 255

waiter-icon3
false
0
Circle -2064490 true false 92 92 118
Rectangle -16777216 true false 120 135 135 150
Rectangle -16777216 true false 165 135 180 150
Line -16777216 false 120 180 180 180
Rectangle -16777216 true false 120 165 180 180
Rectangle -1 true false 120 30 120 45
Rectangle -1 true false 75 210 225 300
Circle -6459832 true false 105 90 30
Circle -6459832 true false 120 90 30
Circle -6459832 true false 135 90 30
Circle -6459832 true false 150 90 30
Circle -6459832 true false 165 90 30
Circle -6459832 true false 330 135 30
Rectangle -16777216 true false 120 210 135 240
Rectangle -16777216 true false 165 210 180 240
Rectangle -16777216 true false 135 225 150 225
Rectangle -16777216 true false 135 210 165 225
Rectangle -7500403 true true 75 210 120 300
Rectangle -7500403 true true 120 240 210 315
Rectangle -7500403 true true 180 210 225 300
Rectangle -7500403 true true 135 225 165 240

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="E1" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="28800"/>
    <metric>get-waiting-time</metric>
    <metric>get-satisfaction</metric>
    <enumeratedValueSet variable="Meseros">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cocineros">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mapa">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Clientes">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Demora">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="E2" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="28800"/>
    <metric>get-waiting-time</metric>
    <metric>get-satisfaction</metric>
    <enumeratedValueSet variable="Meseros">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cocineros">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mapa">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Clientes">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Demora">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="E3" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="28800"/>
    <metric>get-waiting-time</metric>
    <metric>get-satisfaction</metric>
    <enumeratedValueSet variable="Meseros">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cocineros">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mapa">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Clientes">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Demora">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="E4" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="28800"/>
    <metric>get-waiting-time</metric>
    <metric>get-satisfaction</metric>
    <enumeratedValueSet variable="Meseros">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cocineros">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mapa">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Clientes">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Demora">
      <value value="11"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="E5" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="28800"/>
    <metric>get-waiting-time</metric>
    <metric>get-satisfaction</metric>
    <enumeratedValueSet variable="Meseros">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cocineros">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mapa">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Clientes">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Demora">
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="E6" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="28800"/>
    <metric>get-waiting-time</metric>
    <metric>get-satisfaction</metric>
    <enumeratedValueSet variable="Meseros">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cocineros">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mapa">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Clientes">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Demora">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
