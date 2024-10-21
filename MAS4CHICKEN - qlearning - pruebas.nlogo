extensions [fetch bitmap qlearningextension]

breed [clients client]
breed [waiters waiter]
breed [chefs chef]
breed [nodes node]
Breed[Walkers Walker]

clients-own [
  waiting-time
  waiting-threshold
  time
  quantity
  ;served
  ;satisfaction
  chef-id           ; posicion del chef asignado
  food-ready
  time-go
  goto
  location          ; posición del cliente
  is-waiting
  is-done
  assigned-table
  entry-point
]
waiters-own [
  ;chef-id
  ;client-id
  location          ; posición del mesero
  initial-location
  path              ; Lista de nodos de destino ej. punto central del mesero, cliente, cocinero, etc.
  orders
  delay             ; Delay del mesero (de 0 a 5 minutos)
  food-waiter
  client-id         ; posición del cliente asignado
]
chefs-own [
  food-time
  working-time
  delay              ; Delay del mesero (de 0 a 5 minutos)
  pos-clients        ; Lista de posiciones de los clientes
  time-clients       ; Lista de tiempo prepación
  location           ; posición del chef
]

Walkers-own[reward-list]
patches-own [reward]

globals [
  patch-data         ; Info general de las parcelas
  polleria-patches   ; Parcelas específicas
  cocina-patches
  staff-patches
  staff-main-patch
  mesas-patches
  total-waiting-time ; Lista de tiempo de espera
  happy-clients      ; Cantidad de clientes satisfechos
  unhappy-clients    ; Cantidad de clientes insatisfechos
  waiter-area        ; Punto central del mesero
  entrada-patches
  max-waiters
  max-chefs
  max-clients        ; Maxima cantidad de clientes
  targetx
  targety
  iteracion
  end-learning
  Meseros-optimo
  Cocineros-optimo
]

to-report bla
  report "c"

end

to setup
  clear-all

  set-current-plot "Ave Reward Per Episode"
  set-plot-y-range -10 10

  ask patches [set reward -1]
  set max-waiters 10
  set max-chefs 10

  fetch:url-async "https://raw.githubusercontent.com/u201922331/MAS4CHICKEN/main/assets/images/leyenda.png" [
    contents ->
    let legend bitmap:from-base64 contents
    bitmap:copy-to-drawing legend 0 0
  ]
  fetch:url-async "https://raw.githubusercontent.com/u201922331/MAS4CHICKEN/main/assets/images/Logo%20MAS4CHICKEN.png" [
    contents ->
    let logo bitmap:from-base64 contents
    bitmap:copy-to-drawing logo 660 0
  ]

  ; Cargar el mapa
  set patch-data [[-12	12	0]	[-11	12	0]	[-10	12	0]	[-9	12	0]	[-8	12	0]	[-7	12	0]	[-6	12	0]	[-5	12	0]	[-4	12	0]	[-3	12	0]	[-2	12	0]	[-1	12	27]	[0	12	0]	[1	12	0]	[2	12	0]	[3	12	0]	[4	12	0]	[5	12	0]	[6	12	0]	[7	12	0]	[8	12	0]	[9	12	0]	[10	12	0]	[11	12	0]	[12	12	0]	[-12	11	0]	[-11	11	45]	[-10	11	45]	[-9	11	45]	[-8	11	45]	[-7	11	45]	[-6	11	45]	[-5	11	45]	[-4	11	45]	[-3	11	45]	[-2	11	45]	[-1	11	45]	[0	11	45]	[1	11	45]	[2	11	45]	[3	11	45]	[4	11	45]	[5	11	45]	[6	11	45]	[7	11	45]	[8	11	45]	[9	11	45]	[10	11	45]	[11	11	45]	[12	11	0]	[-12	10	0]	[-11	10	45]	[-10	10	45]	[-9	10	35]	[-8	10	36]	[-7	10	45]	[-6	10	45]	[-5	10	35]	[-4	10	36]	[-3	10	45]	[-2	10	45]	[-1	10	35]	[0	10	36]	[1	10	45]	[2	10	45]	[3	10	35]	[4	10	36]	[5	10	45]	[6	10	45]	[7	10	35]	[8	10	36]	[9	10	45]	[10	10	45]	[11	10	45]	[12	10	0]	[-12	9	0]	[-11	9	45]	[-10	9	45]	[-9	9	45]	[-8	9	45]	[-7	9	45]	[-6	9	45]	[-5	9	45]	[-4	9	45]	[-3	9	45]	[-2	9	45]	[-1	9	45]	[0	9	45]	[1	9	45]	[2	9	45]	[3	9	45]	[4	9	45]	[5	9	45]	[6	9	45]	[7	9	45]	[8	9	45]	[9	9	45]	[10	9	45]	[11	9	45]	[12	9	0]	[-12	8	0]	[-11	8	45]	[-10	8	45]	[-9	8	45]	[-8	8	45]	[-7	8	45]	[-6	8	45]	[-5	8	45]	[-4	8	45]	[-3	8	45]	[-2	8	45]	[-1	8	45]	[0	8	45]	[1	8	45]	[2	8	45]	[3	8	45]	[4	8	45]	[5	8	45]	[6	8	45]	[7	8	45]	[8	8	45]	[9	8	45]	[10	8	45]	[11	8	45]	[12	8	0]	[-12	7	0]	[-11	7	45]	[-10	7	45]	[-9	7	35]	[-8	7	36]	[-7	7	45]	[-6	7	45]	[-5	7	35]	[-4	7	36]	[-3	7	45]	[-2	7	45]	[-1	7	35]	[0	7	36]	[1	7	45]	[2	7	45]	[3	7	35]	[4	7	36]	[5	7	45]	[6	7	45]	[7	7	35]	[8	7	36]	[9	7	45]	[10	7	45]	[11	7	45]	[12	7	0]	[-12	6	0]	[-11	6	45]	[-10	6	45]	[-9	6	45]	[-8	6	45]	[-7	6	45]	[-6	6	45]	[-5	6	45]	[-4	6	45]	[-3	6	45]	[-2	6	45]	[-1	6	45]	[0	6	45]	[1	6	45]	[2	6	45]	[3	6	45]	[4	6	45]	[5	6	45]	[6	6	45]	[7	6	45]	[8	6	45]	[9	6	45]	[10	6	45]	[11	6	45]	[12	6	0]	[-12	5	0]	[-11	5	45]	[-10	5	45]	[-9	5	45]	[-8	5	45]	[-7	5	45]	[-6	5	45]	[-5	5	45]	[-4	5	45]	[-3	5	45]	[-2	5	45]	[-1	5	45]	[0	5	45]	[1	5	45]	[2	5	45]	[3	5	45]	[4	5	45]	[5	5	45]	[6	5	45]	[7	5	45]	[8	5	45]	[9	5	45]	[10	5	45]	[11	5	45]	[12	5	0]	[-12	4	0]	[-11	4	45]	[-10	4	45]	[-9	4	35]	[-8	4	36]	[-7	4	45]	[-6	4	45]	[-5	4	35]	[-4	4	36]	[-3	4	45]	[-2	4	45]	[-1	4	35]	[0	4	36]	[1	4	45]	[2	4	45]	[3	4	35]	[4	4	36]	[5	4	45]	[6	4	45]	[7	4	35]	[8	4	36]	[9	4	45]	[10	4	45]	[11	4	45]	[12	4	0]	[-12	3	0]	[-11	3	45]	[-10	3	45]	[-9	3	45]	[-8	3	45]	[-7	3	45]	[-6	3	45]	[-5	3	45]	[-4	3	45]	[-3	3	45]	[-2	3	45]	[-1	3	45]	[0	3	45]	[1	3	45]	[2	3	45]	[3	3	45]	[4	3	45]	[5	3	45]	[6	3	45]	[7	3	45]	[8	3	45]	[9	3	45]	[10	3	45]	[11	3	45]	[12	3	0]	[-12	2	0]	[-11	2	45]	[-10	2	45]	[-9	2	45]	[-8	2	45]	[-7	2	45]	[-6	2	45]	[-5	2	45]	[-4	2	45]	[-3	2	45]	[-2	2	45]	[-1	2	45]	[0	2	45]	[1	2	45]	[2	2	45]	[3	2	45]	[4	2	45]	[5	2	45]	[6	2	45]	[7	2	45]	[8	2	45]	[9	2	45]	[10	2	45]	[11	2	45]	[12	2	0]	[-12	1	0]	[-11	1	45]	[-10	1	45]	[-9	1	35]	[-8	1	36]	[-7	1	45]	[-6	1	45]	[-5	1	35]	[-4	1	36]	[-3	1	45]	[-2	1	45]	[-1	1	35]	[0	1	36]	[1	1	45]	[2	1	45]	[3	1	35]	[4	1	36]	[5	1	45]	[6	1	45]	[7	1	35]	[8	1	36]	[9	1	45]	[10	1	45]	[11	1	45]	[12	1	0]	[-12	0	0]	[-11	0	45]	[-10	0	45]	[-9	0	45]	[-8	0	45]	[-7	0	45]	[-6	0	45]	[-5	0	45]	[-4	0	45]	[-3	0	45]	[-2	0	45]	[-1	0	45]	[0	0	45]	[1	0	45]	[2	0	45]	[3	0	45]	[4	0	45]	[5	0	45]	[6	0	45]	[7	0	45]	[8	0	45]	[9	0	45]	[10	0	45]	[11	0	45]	[12	0	0]	[-12	-1	0]	[-11	-1	45]	[-10	-1	45]	[-9	-1	45]	[-8	-1	45]	[-7	-1	45]	[-6	-1	45]	[-5	-1	45]	[-4	-1	45]	[-3	-1	45]	[-2	-1	45]	[-1	-1	45]	[0	-1	45]	[1	-1	45]	[2	-1	45]	[3	-1	45]	[4	-1	45]	[5	-1	45]	[6	-1	45]	[7	-1	45]	[8	-1	45]	[9	-1	45]	[10	-1	45]	[11	-1	45]	[12	-1	0]	[-12	-2	0]	[-11	-2	45]	[-10	-2	45]	[-9	-2	35]	[-8	-2	36]	[-7	-2	45]	[-6	-2	45]	[-5	-2	35]	[-4	-2	36]	[-3	-2	45]	[-2	-2	45]	[-1	-2	35]	[0	-2	36]	[1	-2	45]	[2	-2	45]	[3	-2	35]	[4	-2	36]	[5	-2	45]	[6	-2	45]	[7	-2	35]	[8	-2	36]	[9	-2	45]	[10	-2	45]	[11	-2	45]	[12	-2	0]	[-12	-3	0]	[-11	-3	45]	[-10	-3	45]	[-9	-3	45]	[-8	-3	45]	[-7	-3	45]	[-6	-3	45]	[-5	-3	45]	[-4	-3	45]	[-3	-3	45]	[-2	-3	45]	[-1	-3	45]	[0	-3	45]	[1	-3	45]	[2	-3	45]	[3	-3	45]	[4	-3	45]	[5	-3	45]	[6	-3	45]	[7	-3	45]	[8	-3	45]	[9	-3	45]	[10	-3	45]	[11	-3	45]	[12	-3	0]	[-12	-4	0]	[-11	-4	45]	[-10	-4	45]	[-9	-4	45]	[-8	-4	45]	[-7	-4	45]	[-6	-4	45]	[-5	-4	45]	[-4	-4	45]	[-3	-4	45]	[-2	-4	45]	[-1	-4	45]	[0	-4	45]	[1	-4	45]	[2	-4	45]	[3	-4	45]	[4	-4	45]	[5	-4	45]	[6	-4	45]	[7	-4	45]	[8	-4	45]	[9	-4	45]	[10	-4	45]	[11	-4	45]	[12	-4	0]	[-12	-5	0]	[-11	-5	45]	[-10	-5	45]	[-9	-5	45]	[-8	-5	45]	[-7	-5	45]	[-6	-5	45]	[-5	-5	45]	[-4	-5	45]	[-3	-5	45]	[-2	-5	45]	[-1	-5	45]	[0	-5	45]	[1	-5	45]	[2	-5	45]	[3	-5	45]	[4	-5	45]	[5	-5	45]	[6	-5	45]	[7	-5	45]	[8	-5	45]	[9	-5	45]	[10	-5	45]	[11	-5	45]	[12	-5	0]	[-12	-6	0]	[-11	-6	0]	[-10	-6	0]	[-9	-6	0]	[-8	-6	0]	[-7	-6	0]	[-6	-6	0]	[-5	-6	0]	[-4	-6	5]	[-3	-6	6]	[-2	-6	5]	[-1	-6	0]	[0	-6	0]	[1	-6	0]	[2	-6	0]	[3	-6	0]	[4	-6	0]	[5	-6	0]	[6	-6	0]	[7	-6	0]	[8	-6	0]	[9	-6	0]	[10	-6	0]	[11	-6	0]	[12	-6	0]	[-12	-7	0]	[-11	-7	5]	[-10	-7	5]	[-9	-7	5]	[-8	-7	5]	[-7	-7	5]	[-6	-7	5]	[-5	-7	5]	[-4	-7	5]	[-3	-7	5]	[-2	-7	5]	[-1	-7	5]	[0	-7	4]	[1	-7	4]	[2	-7	4]	[3	-7	4]	[4	-7	4]	[5	-7	4]	[6	-7	4]	[7	-7	4]	[8	-7	4]	[9	-7	4]	[10	-7	4]	[11	-7	4]	[12	-7	0]	[-12	-8	0]	[-11	-8	5]	[-10	-8	5]	[-9	-8	5]	[-8	-8	5]	[-7	-8	5]	[-6	-8	5]	[-5	-8	5]	[-4	-8	5]	[-3	-8	5]	[-2	-8	5]	[-1	-8	5]	[0	-8	4]	[1	-8	4]	[2	-8	4]	[3	-8	4]	[4	-8	4]	[5	-8	4]	[6	-8	4]	[7	-8	4]	[8	-8	4]	[9	-8	4]	[10	-8	4]	[11	-8	4]	[12	-8	0]	[-12	-9	0]	[-11	-9	5]	[-10	-9	5]	[-9	-9	5]	[-8	-9	5]	[-7	-9	5]	[-6	-9	5]	[-5	-9	5]	[-4	-9	5]	[-3	-9	5]	[-2	-9	5]	[-1	-9	5]	[0	-9	4]	[1	-9	4]	[2	-9	4]	[3	-9	4]	[4	-9	4]	[5	-9	4]	[6	-9	4]	[7	-9	4]	[8	-9	4]	[9	-9	4]	[10	-9	4]	[11	-9	4]	[12	-9	0]	[-12	-10	0]	[-11	-10	5]	[-10	-10	5]	[-9	-10	5]	[-8	-10	5]	[-7	-10	5]	[-6	-10	5]	[-5	-10	5]	[-4	-10	5]	[-3	-10	5]	[-2	-10	5]	[-1	-10	5]	[0	-10	4]	[1	-10	4]	[2	-10	4]	[3	-10	4]	[4	-10	4]	[5	-10	4]	[6	-10	4]	[7	-10	4]	[8	-10	4]	[9	-10	4]	[10	-10	4]	[11	-10	4]	[12	-10	0]	[-12	-11	0]	[-11	-11	5]	[-10	-11	5]	[-9	-11	5]	[-8	-11	5]	[-7	-11	5]	[-6	-11	5]	[-5	-11	5]	[-4	-11	5]	[-3	-11	5]	[-2	-11	5]	[-1	-11	5]	[0	-11	4]	[1	-11	4]	[2	-11	4]	[3	-11	4]	[4	-11	4]	[5	-11	4]	[6	-11	4]	[7	-11	4]	[8	-11	4]	[9	-11	4]	[10	-11	4]	[11	-11	4]	[12	-11	0]	[-12	-12	0]	[-11	-12	0]	[-10	-12	0]	[-9	-12	0]	[-8	-12	0]	[-7	-12	0]	[-6	-12	0]	[-5	-12	0]	[-4	-12	0]	[-3	-12	0]	[-2	-12	0]	[-1	-12	0]	[0	-12	0]	[1	-12	0]	[2	-12	0]	[3	-12	0]	[4	-12	0]	[5	-12	0]	[6	-12	0]	[7	-12	0]	[8	-12	0]	[9	-12	0]	[10	-12	0]	[11	-12	0]	[12	-12	0]]
  foreach patch-data [ three-tuple ->
    ask patch first three-tuple item 1 three-tuple [ set pcolor last three-tuple ]
  ]

  let border-patches black
  set polleria-patches patches with [pcolor = yellow]   ; Parcelas del patio de comida
  set mesas-patches patches with [pcolor = brown]       ; Parcelas de las mesas
  set max-clients (count mesas-patches)                 ; Maxima cantidad de clientes es la máxima cantidad de mesas
  ask patches with [pcolor = (brown + 1)] [set pcolor brown] ; Diseño

  set cocina-patches patches with [pcolor = (gray - 1)] ; Parcelas de la zona de cocina
  set staff-patches patches with [pcolor = gray]        ; Parcelas de la zona de meseros
  set staff-main-patch patches with [pcolor = (gray + 1)]
  set entrada-patches patches with [pcolor = (orange + 2)] ; Parcelas de la zona de entrada/salida
  ;set-patch-size 20

  ask patches with [pcolor != border-patches] [ sprout-nodes 1]    ; Agente nodo
  ask nodes [
    create-links-with nodes-on neighbors4
    set hidden? true
  ]

  create-turtles 1 [                      ; Punto central del mesero
    set hidden? true
    move-to one-of staff-main-patch
    set waiter-area one-of nodes-here
  ]

  ask patch (1 + random MESEROS) (1 + random COCINEROS) [
    sprout-walkers 1 [set color yellow set hidden? True]
    set Meseros-optimo pxcor
    set Cocineros-optimo pycor
  ]

  ask Walkers [
    qlearningextension:state-def-extra ["xcor" "ycor"] [bla]
    (qlearningextension:actions [goUp] [goDown] [goLeft] [goRight])
    qlearningextension:reward [rewardFunc]
    qlearningextension:end-episode [isEndState] resetEpisode
    qlearningextension:action-selection "e-greedy" [0.5 0.08]
    qlearningextension:learning-rate 1
    qlearningextension:discount-factor 0.75

    ; used to create the plot
    create-temporary-plot-pen (word who)
    set-plot-pen-color color
    set reward-list []
  ]
  set iteracion 0
  set end-learning false
end


to go
  set iteracion (iteracion + 1)

  reset-ticks
  set total-waiting-time []  ; Variables iniciales
  set happy-clients 0
  set unhappy-clients 0

  ask waiters [die]          ; Limpieza de agente
  ask chefs [die]
  ask clients [die]

  clear-plot
  ; Validar parámetros iniciales
  if MESEROS < 1 [
    user-message (word "El número de meseros es menor al límite permitido de 1, por lo que será ajustado automáticamente a un mínimo de 1 mesero.")
    set MESEROS 1
  ]
  if COCINEROS < 1 [
    user-message (word "El número de cocineros es menor al límite permitido de 1, por lo que será ajustado automáticamente a un mínimo de 1 cocinero.")
    set COCINEROS 1
  ]
  if MESEROS > max-waiters [
    user-message (word "El número de meseros excede el límite permitido de " max-waiters ", por lo que será ajustado automáticamente a un máximo de 20 meseros.")
    set MESEROS max-waiters
  ]
  if COCINEROS > max-chefs [
    user-message (word "El número de cocineros excede el límite permitido de " max-chefs ", por lo que será ajustado automáticamente a un máximo de 20 cocineros.")
    set COCINEROS max-chefs
  ]
  ; Colores
  let border-patches black


  create-waiters Meseros-optimo [               ; Agente mesero (waiter)
    set shape "waiter-icon3"             ; Iniciales
    set color blue
    set size 2
    set label orders                     ; Etiqueta
    set label-color black
    move-to one-of staff-patches         ; Posicion
    set location one-of nodes-here
    set initial-location location

    set path []
    set delay 0

    set food-waiter false
    set client-id one-of nodes-here
  ]

  create-chefs Cocineros-optimo [                ; Agente cocinero (chef)
    set shape "chef-icon3"                ; Iniciales
    set color white
    set size 2
    set label-color black                 ; Etiqueta
    move-to one-of cocina-patches         ; Posicion
    set location one-of nodes-here

    set food-time ((random 5) + Tiempo-preparacion) * 60

    set working-time 0
    set label working-time / 60
    set pos-clients []
    set time-clients []
  ]
  set-current-plot "Histograma del tiempo de espera"
  set-plot-x-range 1 ( 90 + 1 )
  set-current-plot "Cantidad clientes"
  clear-plot
  clear-output

  reset-ticks

  while [ticks < 2 * 60 * 60] [
    if ticks = 60 * 60 [                                              ; Simular distribución normal (1pm hora pico)
       ifelse Feriado-Fin-de-Semana = True                                 ; Simular día feriado o fin de semana
      [set INTERVALO-CLIENTES round (INTERVALO-CLIENTES - (INTERVALO-CLIENTES * 0.10))]
      [set INTERVALO-CLIENTES round (INTERVALO-CLIENTES - (INTERVALO-CLIENTES * 0.05))]
    ]
    if ticks = 90 * 60 [
      ifelse Feriado-Fin-de-Semana = True
      [set INTERVALO-CLIENTES round (INTERVALO-CLIENTES + (INTERVALO-CLIENTES * 0.10))]
      [set INTERVALO-CLIENTES round (INTERVALO-CLIENTES + (INTERVALO-CLIENTES * 0.05))]
    ]


    if remainder ticks (INTERVALO-CLIENTES * 60) = 0 [        ; Creación del cliente
      let current-clients (count clients)
      if current-clients < max-clients [
        ask one-of entrada-patches [
        let postable 0
        let poschef 0

        ask one-of mesas-patches with [not any? clients-here] [
          set postable one-of nodes-here

          let w first sort-by [[a b] -> [ orders ] of a < [ orders ] of b ] waiters
          ask w [                              ; Agente mesero (w)
            set orders orders + 1
            set label orders
            set label-color black
            let time-chef 0

            let c first sort-by [[a b] -> [ working-time ] of a < [ working-time ] of b ] chefs
            ask c [                             ; Agente chef (c)
              set poschef one-of nodes-here
              set working-time working-time + food-time

              set pos-clients lput postable pos-clients
              set time-clients lput food-time time-clients
            ]
            set path lput waiter-area path
            (foreach range (2 * 60) [ set path lput postable path])

            set path lput waiter-area path
            (foreach range 30 [ set path lput poschef path])
            set path lput waiter-area path

            output-print (word "Mesero tomando la orden del cliente en (" xcor " " ycor ")")
          ]
        ]
        sprout-clients 1                     ; Agente cliente
        [
          set quantity (random 3) + 1
          if quantity = 1                    ; Cliente individual
          [ set waiting-threshold ((random 5) + Tiempo-espera-real) * 60
            set shape "client-icon"
          ]
          if quantity = 2                    ; Cliente pareja
          [ set waiting-threshold ((random 5) + Tiempo-espera-real * 1.2) * 60
            set shape "client-icon2"
          ]
          if quantity = 3                    ; Cliente familiar
          [ set waiting-threshold ((random 5) + Tiempo-espera-real * 1.4) * 60
            set shape "client-icon3"
          ]
          set time 0                         ; Iniciales
          set color lime
          set size 2
          set label-color black              ; Label
                                             ; move-to postable                   ; Posición

          set location one-of nodes-here

          set chef-id poschef
          set food-ready false
          set is-waiting false
          set is-done false
          set assigned-table postable

          set entry-point location

          output-print (word "Llegó un cliente en (" xcor " " ycor ").")
        ]
      ]
    ]
    ]

    if remainder (ticks + 1) (INTERVALO-PAUSA * 60) = 0 [ ; Pausa del chef y mesero
      if random 2 = 0    ; Agente mesero
      [
        if any? waiters with [empty? path]
        [
          let w one-of waiters with [empty? path]
          ask w [
            set color cyan
            set delay 5 * 60
            repeat delay [ set path lput (one-of nodes-here) path]
          ]
        ]
      ]
      ;; cocinero
      if random 2 = 0           ; Agente cocinero
      [
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

    ;; ACCIONES

    ask waiters [
      let new-location 0

      set delay delay - 1                  ; Delay del mesero
      if delay = 0 [ set color blue]

      ifelse empty? path                   ; Siguiente posicion del mesero
      [
        set new-location one-of [link-neighbors] of location
        move-to new-location
        set location new-location
      ]
      [
        let destination first path
        let routes [link-neighbors] of location
        set routes routes with [pcolor != black]
        set new-location min-one-of routes [distance destination]
        face new-location
        set location new-location
        fd 1

        if [patch-here] of location = [patch-here] of destination [
          set path remove-item 0 path
          if [patch-here] of location = [patch-here] of client-id [
            output-print (word "Mesero en (" xcor " " ycor ") está llevando la orden.")
            ask clients-on location
            [
              output-print (word "Cliente en (" xcor " " ycor ") fue atendido y quedó satisfecho.")
              set color white
              set is-done true
            ]
          ]
        ]



      ]
    ]

    ask clients [
      ifelse not is-done [ ; 1. El cliente no ha terminado (o su comida o de esperar)
        ifelse is-waiting [
          set time time + 1                      ; Actualizando el tiempo
          set label precision (time / 60) 2

          if color = red [                       ; Eliminando el cliente
            output-print (word "Cliente en (" xcor " " ycor ") no fue atendido y quedó insatisfecho.")
            set is-done true
          ]

          ifelse time >  waiting-threshold        ; Actualizando el color basado en el tiempo y el threshold
          [ set color red ]
          [ ifelse time > (waiting-threshold / 2)
            [set color (yellow - 2)]
            [set color lime]
          ]
        ]
        [
          let destination assigned-table
          let routes [link-neighbors] of location
          set routes routes with [pcolor != black]
          let new-location min-one-of routes [distance destination]
          face new-location
          set location new-location
          fd 1

          if [patch-here] of location = [patch-here] of assigned-table [
            output-print (word "El cliente en (" xcor " " ycor ") está esperando al mesero...")
            set is-waiting True
          ]
        ]
      ]
      [ ; 2. Una vez terminada la espera, ir a la entrada
        let destination entry-point
        let routes [link-neighbors] of location
        set routes routes with [pcolor != black]
        let new-location min-one-of routes [distance destination]
        face new-location
        set location new-location
        fd 1

        if [patch-here] of location = [patch-here] of destination [
          ifelse time < waiting-threshold [
            set happy-clients happy-clients + 1
          ]
          [
            set unhappy-clients unhappy-clients + 1
          ]
          set total-waiting-time lput time total-waiting-time
          die
        ]
      ]
    ]

    ask chefs [
      set delay delay - 1                      ; Actualizando el delay
      if delay = 0 [set color white ]

      set working-time working-time - 1           ; Actualizando el tiempo de preparacion
      if working-time < 0 [ set working-time 0 ]
      set label precision (working-time / 60) 2

      let poschef one-of nodes-here                    ; Movimiento del mesero
      let adjacent [link-neighbors] of location
      set adjacent adjacent with [pcolor = (gray - 1)]
      let new-location one-of adjacent
      move-to new-location
      set location new-location

      if not empty? time-clients [                           ; Lista de tiempo prepación
        let timeclient first time-clients
        let posclient first pos-clients

        ifelse timeclient = 0 [                             ; Verificar si el plato esta listo
          let w first sort-by [[a b] -> [ orders ] of a < [ orders ] of b ] waiters
          ask w [
            set orders orders + 1
            set label orders
            set client-id posclient

            set path lput waiter-area path
            set path lput poschef path
            set path lput waiter-area path
            set path lput posclient path
          ]
          set time-clients remove-item 0 time-clients
          set pos-clients remove-item 0 pos-clients
          output-print (word "¡El chef en (" xcor " " ycor  ") tiene la orden lista! Esperando al mesero...")
        ]
        [
          set time-clients replace-item 0 time-clients (timeclient - 1)
        ]
      ]
    ]
    update-plot ; Histograma de tiempo de espera
    tick
  ]
  if end-learning = true [stop]

  ask Walkers [
    qlearningextension:learning
    print(qlearningextension:get-qtable)
    show (word "xcor:" xcor "ycor:" ycor)
    set Meseros-optimo xcor
    set Cocineros-optimo ycor
  ]
  if end-learning = true [stop]
end


to-report rewardFunc
  let w get-waiting-time
  ifelse w = 0 [
    set reward-list lput -100 reward-list
    report -100
  ]
  [
    set w (-1 * w)
    set reward-list lput w reward-list
    report w
  ]

end

to goUp
  if ycor + 1 != COCINEROS + 1  [
    set heading 0
    fd 1
  ]
end

to goDown
  if ycor - 1 != 0 [
    set heading 180
    fd 1
  ]
end

to goLeft
  if xcor - 1 != 0 [
    set heading 270
    fd 1
  ]
end

to goRight
  if xcor + 1 != MESEROS + 1 [
    set heading 90
    fd 1
  ]
end

to-report isEndState
  if get-waiting-time < Tiempo-espera-real [
    if iteracion > 500 [ set end-learning true ]
    report true
  ]
  report false
end

to resetEpisode
  if end-learning = false [
    setxy (1 + random MESEROS) (1 + random COCINEROS)

    ; used to update the plot
    let rew-sum 0
    let length-rew 0
    foreach reward-list [ r ->
      set rew-sum rew-sum + r
      set length-rew length-rew + 1
    ]
    let avg-rew rew-sum / length-rew

    ;set-current-plot-pen (word who)
    ;plot avg-rew

    set reward-list []
  ]
end



to-report get-waiting-time
  ifelse empty? total-waiting-time
  [ report 0 ]
  [ let totalsec mean total-waiting-time
    report totalsec / 60
  ]
end

to-report get-cocineros-optimo
  report cocineros-optimo
end

to-report get-meseros-optimo
  report meseros-optimo
end

to update-plot
  set-current-plot "Histograma del tiempo de espera"
  let total-waiting-time-minutes map [i -> round (i / 60)] total-waiting-time

  histogram total-waiting-time-minutes

  if not empty? total-waiting-time-minutes [
    let maxbar modes total-waiting-time-minutes
    let maxrange length filter [ the-item -> the-item = item 0 maxbar ] total-waiting-time-minutes
    set-plot-y-range 0 max list 10 maxrange
  ]
end

to-report get-hours
  report floor 10 + (ticks / 3600)
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

to-report get-iteracion
  report iteracion
end

to load-from-url [my-url]
  clear-all

  ; For NetLogo Web, use the Asynchronous load.
  fetch:url-async my-url [
    contents ->
    set patch-data parse-map-info contents

    foreach patch-data [ three-tuple ->
      ask patch first three-tuple item 1 three-tuple [ set pcolor last three-tuple ]
    ]
    display
  ]
end

to load-locally
  clear-all

  ifelse Version-Web [
    ; For NetLogo Web, use the Asynchronous load.
    fetch:user-file-async [
      contents ->
      set patch-data parse-map-info contents
      foreach patch-data [ three-tuple ->
        ask patch first three-tuple item 1 three-tuple [ set pcolor last three-tuple ]
      ]
      display
    ]
  ]
  [
    ; For NetLogo Desktop, use the Synchronous load.
    set patch-data parse-map-info fetch:user-file
    foreach patch-data [ three-tuple ->
      ask patch first three-tuple item 1 three-tuple [ set pcolor last three-tuple ]
    ]
    display
  ]
end

to-report parse-map-info [mapStr]
  report read-from-string mapStr
end
@#$#@#$#@
GRAPHICS-WINDOW
32
314
850
1133
-1
-1
10.0
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
47
133
139
193
Meseros
2.0
1
0
Number

INPUTBOX
143
133
235
193
Cocineros
2.0
1
0
Number

SLIDER
425
15
458
217
Intervalo-Clientes
Intervalo-Clientes
0
30
10.0
1
1
min
VERTICAL

BUTTON
475
56
560
128
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
477
134
561
202
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
568
56
768
101
Tiempo promedio de espera (min)
get-waiting-time
5
1
11

MONITOR
62
245
112
290
Hrs
get-hours
0
1
11

MONITOR
110
245
160
290
Min
get-minutes
0
1
11

MONITOR
159
245
209
290
Seg
get-seconds
0
1
11

MONITOR
780
57
921
102
Clientes satisfechos
happy-clients
0
1
11

MONITOR
931
56
1071
101
Clientes no satisfechos
unhappy-clients
17
1
11

SLIDER
240
133
412
166
Intervalo-Pausa
Intervalo-Pausa
0
60
10.0
5
1
min
HORIZONTAL

MONITOR
1083
56
1222
101
% Clientes satisfechos
get-satisfaction
2
1
11

SWITCH
48
200
233
233
Feriado-Fin-de-Semana
Feriado-Fin-de-Semana
0
1
-1000

SLIDER
239
209
418
242
Tiempo-espera-real
Tiempo-espera-real
0
60
14.0
1
1
min
HORIZONTAL

SLIDER
240
172
411
205
Tiempo-preparacion
Tiempo-preparacion
0
100
10.0
2
1
min
HORIZONTAL

PLOT
567
107
918
257
Histograma del tiempo de espera
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"PenTiempo" 1.0 1 -7500403 true "" ""

PLOT
928
107
1221
257
Cantidad clientes
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count clients"

TEXTBOX
50
109
195
128
Parámetros iniciales
14
0.0
1

TEXTBOX
475
12
625
47
Ejecutar \nsimulación
14
0.0
1

TEXTBOX
568
13
718
31
Métricas de evaluación
14
0.0
1

OUTPUT
856
313
1394
952
10

TEXTBOX
280
293
392
328
Entorno
14
0.0
1

TEXTBOX
1016
288
1346
336
Registro de eventos
14
0.0
1

TEXTBOX
44
13
233
48
Carga de mapa
14
0.0
1

INPUTBOX
44
41
261
101
Recurso-URL
NIL
1
0
String

BUTTON
271
51
411
85
Cargar Recurso
load-from-url Recurso-URL
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
271
90
412
124
Cargar Archivo
load-locally
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
304
13
413
46
Version-Web
Version-Web
1
1
-1000

PLOT
1235
57
1435
207
Ave Reward Per Episode
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

MONITOR
683
267
808
312
Iteracion
get-iteracion
17
1
11

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
  <experiment name="E1 - 10 casos" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>get-waiting-time</metric>
    <metric>get-cocineros-optimo</metric>
    <metric>get-meseros-optimo</metric>
    <metric>get-satisfaction</metric>
    <enumeratedValueSet variable="Tiempo-espera-real">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Pausa">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cocineros-optimo">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cocineros">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Meseros">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tiempo-preparacion">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Meseros-optimo">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Version-Web">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intervalo-Clientes">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Recurso-URL">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Feriado-Fin-de-Semana">
      <value value="true"/>
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
