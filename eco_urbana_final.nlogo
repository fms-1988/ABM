extensions [table]
patches-own [farm apt tec dist cultura trocar lucro lucro_med lucro_total lucro_total_s lucro_total_g lucro_s lucro_g prob_s prob_g k_fm prices_f]
globals [n farms  prices p_m p_s p_g c_s c_g v1 v2 v3 v4 lm_s lm_g tec1]

to setup
  ca
  random-seed 9
  soil
  farm_ceation
  crate_cultures
  distance_to_city
  market
  reset-ticks
  ask patches [ set plabel-color black ]
  ask patch -15 32 [set plabel "1" ]
  ask patch -13 3 [set plabel "2" ]
  ask patch -16 -33 [set plabel "3" ]
  ask patch 41 -33 [set plabel "4" ]
  ask patch 41 -7 [set plabel "5" ]
end

to soil ;criar solo
  ca
  ask patches [ set apt random-float 1]
  repeat 12 [diffuse apt 0.3] ; reduzir as repetições surge padrões
  ask patches [ set pcolor scale-color green apt 1 0]
  let mx max [apt] of patches
  let mn min [apt] of patches
  ask patches [ set apt (( apt - mn ) / ( mx - mn ))] ;normalize

  ;ask patches [set apt 0.5] ;formapadrão mais homogêneo
end


to farm_ceation ; criar fazenda
  ask patches [set farm -1] ;not farm is represented by (-1)
  set n 0 ; nunber of farms
  while [n != num_farms][farm_ceation_1] ; create n farms
  set farms remove-duplicates  [farm] of patches with [farm > 0]
end

to farm_ceation_1
  ask one-of patches [
    let r one-of (range 2 6 1) ;
    let x pxcor
    let y pycor
    let raio patches  with [(pxcor >= (x - r) and pxcor <= (x + r) ) and (pycor >= (y - r) and pycor <= (y + r))]
    let s count raio with [pcolor = black]
    if (s = 0) [
      ;print s
      set n (n + 1)
      ask patch x y [set farm n set pcolor red]
      ask patch x y [
        repeat (r - 1) [ask patches with [farm = n]
          [ask neighbors4 with [(farm = -1)][set farm n]]]]
      ask patches with [farm = n][ask neighbors with [farm = -1] [set pcolor black set farm n]]
    ]
]
  ask patches [set trocar "nao"]

  ;conhecimento de cada fazenda
  ask patches with[pcolor = red][set tec random-normal tec_mean 0.2]; nível tecnologico da fazenda tem que ser 1 e 0.2
end

to crate_cultures
  let culture [yellow white]
  let fronteira_sede [black red]
  ask patches with [farm > -1 and pcolor != black and pcolor != red][set pcolor one-of culture]
  ask patches with [farm > -1 and pcolor = white][set cultura "gado"]
  ask patches with [farm > -1 and pcolor = yellow][set cultura "soja"]

  ;criar tabela
  let tab_lucro_med table:make
  table:put tab_lucro_med 1 2
  ;print table:length tab_lucro_med
  ;print tab_lucro_med
  ask patches [set lucro_med tab_lucro_med]
  ask patches [set lucro_g [0]]
  ask patches [set lucro_s [0]]
  ask patches [set lucro [0]]



end

to distance_to_city
  ask patches [ set dist distance min-one-of patches with [pcolor = red] [distance myself]]
  let mx max [dist] of patches
  ask patches [set dist dist / mx]
  ask patches [set dist dist + zoom] ;tem que ser 0.5

end


to market ; criate vector with 10 elements
  ;set prices [] set prices lput random_walk prices
  set p_m [] set p_m lput random-normal p_m_s 0.05 p_m
  set p_s [] set p_s lput random-normal p_m_s 0.05 p_s
  set p_g [] set p_g lput random-normal p_m_g 0.05 p_g
  ;set c_s [] set c_s lput (last p_s * 0.5) p_s
  ;set c_g [] set c_g lput (last p_g * 0.5) p_g
  set c_s [] set c_s map [i -> i * 0.5] p_s
  set c_g [] set c_g map [i -> i * 0.5] p_g
  ;set c_g map [i -> i * 0.5] p_g  ; custo de producao do gado é 0.8  do preco do gado
end

to new_price ; new price
  set p_m lput random-normal p_m_s 0.05 p_m
  set p_s lput random-normal p_m_s 0.05 p_s
  set p_g lput random-normal p_m_g 0.1 p_g
  set c_s map [i -> i * 0.5] p_s
  set c_g map [i -> i * 0.5] p_g
  wait 0.5

end


to decidir_plantio
  let p1 patches with[cultura = "gado" or cultura = "soja"]
  let p2 p1 with [trocar = "nao"]
  ;ask p2 with[cultura = "gado" or cultura = "soja"][
  ask p2 [
   ;ifelse (mean lucro_s > mean lucro_g)[set prob_s prob_s + 0.03][set prob_s prob_s - 0.03]
   ifelse (lucro_total_s > lucro_total_g)[set prob_s prob_s + step_prob][set prob_g prob_g + step_prob] ; forma padrão
   ;ifelse (mean lucro_s > mean lucro_g)[set prob_s prob_s + 0.025][set prob_s prob_s - 0.025] ; forma padrão
   ;ifelse ((prob_s + random-normal 1 0.1) < 1) ; forma padrão fraco
   ifelse ((prob_s - prob_g) + random-normal 0 0.05 < 0)
   ;ifelse (lucro_total_s < lucro_total_g) ; cria muitos padrões ideal
   ;ifelse (mean lucro_s > mean lucro_g)
    [set cultura "gado" set pcolor white]
    [set cultura "soja" set pcolor yellow]
  ]
end


to-report random_walk
  let tendency 0
   ifelse (price_tendency = "up")[set tendency 1]
    [ifelse (price_tendency = "stable") [set tendency 1][set tendency 1]]
  report random-normal tendency price_volatility
end




to go2

  decidir_plantio

  ;produzir na nova área
  let culturas_color [yellow white]
  let culturas_name ["gado" "soja"]
  ask patches with [pcolor = brown][set pcolor one-of culturas_color]
  ask patches with [pcolor = white][set cultura "gado"]
  ask patches with [pcolor = yellow][set cultura "soja"]

  ;mudar de cultura caso lucro tenha sido negativo no período anterior
  let culturas patches with [cultura = "soja" or cultura = "gado"]
  ask culturas [if (trocar = "sim" and cultura = "gado") [set cultura "soja" set trocar "nao" set pcolor yellow]]
  ask culturas [if (trocar = "sim" and cultura = "soja") [set cultura "gado" set trocar "nao" set pcolor white]]


  ;lucro por hectare
  new_price
  wait 0.5
  ;let culturas [yellow white]
  ;let culturas (list yellow white)
  ;let t length prices
  let p_m1 0 ;last p_m
  let p_s1 last p_s
  let c_s1 last c_s
  let p_g1 last p_g
  let c_g1 last c_g

  foreach farms [
  x ->
  set tec1 one-of [tec] of patches with[pcolor = red and farm = x]
  ask patches with [pcolor = white][
  ;lucro por hectare
  let l (apt * p_m1) + p_g1 * (tec1 + apt - (z_g * dist)) - c_g1 * ((tec1 + apt - (z_g * dist)) ^ 2)
  set lucro lput l lucro
  ;lucro total por ha
  set lucro_total sum lucro
  ;historico do lucro do hectare
  set lucro_g lput l lucro_g
  ;lucro total gado do hectare
  set lucro_total_g sum lucro_g
  ]

  ask patches with [pcolor = yellow][
  let l (apt * p_m1) + p_s1 * (tec1 + apt - (z_s * dist)) - c_s1 * ((tec1 + apt - (z_s * dist)) ^ 2)
  set lucro lput l lucro
  ;lucro total por ha
  set lucro_total sum lucro
  ;historico do lucro do hectare
  set lucro_s lput l lucro_s
  ;lucro total soja do hectare
  set lucro_total_s sum lucro_s
  ]
  ]

  ;lucro total dafazenda
  foreach farms [
  x ->
    let l sum [lucro_total] of patches with [farm = x and pcolor != red]
    let l_s sum [lucro_total_s] of patches with [farm = x and pcolor != red]
    let l_g sum [lucro_total_g] of patches with [farm = x and pcolor != red]
    ask patches with [farm = x and pcolor = red]
    [
     set lucro lput l lucro
     set lucro_g lput l_g lucro_g
     set lucro_s lput l_s lucro_s
     set lucro_total sum lucro
     set lucro_total_s sum lucro_s
     set lucro_total_g sum lucro_g
    ]

  ]

  ;lucro total do mundo
  ;ask patches with [pcolor = red][set lucro_mundo_s lput sum lucro_total lucro_mundo_s]
  set lm_s []
  set lm_g []
  foreach farms [x -> ask patches with [farm = x and pcolor = red][set  lm_g lput lucro_total_g lm_g] ]
  foreach farms [x -> ask patches with [farm = x and pcolor = red][set  lm_s lput lucro_total_s lm_s] ]




  ;trocarde cultura

  ask patches with [pcolor = white or pcolor = yellow][if (last lucro < 0) [set trocar "sim"]]


  go3
  tick
  if ticks >= 228 [stop]



end


to go3


  ;decisao de investimento
  foreach farms [
  x ->
  let oter_farms remove x farms
  let farm_j patches with [not any? (patches in-radius 4 with [member? farm oter_farms ])]
  let farm_i farm_j with [any? (patches in-radius 4 with [farm = x])]
  ask farm_i with [pcolor = red][set v1 farm set v2 lucro_total]
  let fornt_i farm_i with [pcolor = black]
  let farm_i_in [yellow white]
  let tot int v2 / 10 ;desmatar um hectare custa 10
  repeat tot [
    ask one-of fornt_i with-max [log 10 ((0.2 * apt - 0.8 * dist)^ 2)] [
    ;ask fornt_i  [
      if (v2 > 1 ) ;and any? neighbors with [farm = -1]
      [

        set pcolor brown
        let visinhos neighbors4 with [cultura != "gado" and cultura != "soja" ]
        ask visinhos [set pcolor brown set farm x]
        ask visinhos [ask neighbors with [farm = -1] [set pcolor black set farm x]]]

      ;ask neighbors with [farm = -1] [set pcolor black set farm x]
      ;[ask one-of farm_i with[pcolor = green or pcolor = brown or pcolor = blue] [set pcolor blue set farm x]]
      ;[if (any? farm_i with [member? pcolor farm_i_in]) [ask one-of farm_i with [member? pcolor farm_i_in][set pcolor blue ] ]]
      ;[ask one-of farm_i with [ member? pcolor farm_i_in][set pcolor blue ] ]

      ask farm_i with [pcolor = red][set lucro_total lucro_total - 10 * tot ] ; pagar pelo desmatamento
    ]

  ]]
  tick

end


to l1



end





to go
  new_price
  let t length prices
  ask patches with [pcolor = red ][
  set prices_f mean (sublist prices (t - k_fm) (t)) ; horizon of prices considered by the farm
  ]

  ;decisao de investimento
  foreach farms [
  x ->
  let oter_farms remove x farms
  let farm_j patches with [not any? (patches in-radius 3 with [member? farm oter_farms ])]
  let farm_i farm_j with [any? (patches in-radius 3 with [farm = x])]
  ask farm_i with [pcolor = red][set v1 farm set v2 tec set v3 k_fm set v4 prices_f]
  let fornt_i farm_i with [pcolor = black]
  let farm_i_in [green brown]
  ask fornt_i [
      ifelse ((apt + v4) > v2 ) ;and any? neighbors with [farm = -1]
      [
        set pcolor brown
        ask neighbors with [farm = -1] [set pcolor black set farm x]]
      ;[ask one-of farm_i with[pcolor = green or pcolor = brown or pcolor = blue] [set pcolor blue set farm x]]
      [if (any? farm_i with [member? pcolor farm_i_in]) [ask one-of farm_i with [member? pcolor farm_i_in][set pcolor blue ] ]]
      ;[ask one-of farm_i with [ member? pcolor farm_i_in][set pcolor blue ] ]
    ]

  ]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
17
27
658
669
-1
-1
6.27
1
30
1
1
1
0
1
1
1
-50
50
-50
50
0
0
1
ticks
30.0

SLIDER
698
33
889
66
num_farms
num_farms
1
20
5.0
1
1
NIL
HORIZONTAL

PLOT
914
426
1114
576
Tamanho da área rual
time
ha
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count patches with [farm != -1]"

BUTTON
937
33
1010
66
setup
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
1019
32
1082
65
go
go2
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
701
10
898
28
Número de cidades
12
0.0
1

PLOT
910
255
1110
405
preco soja e gado
NIL
NIL
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -1184463 true "" "plot last p_s"
"pen-2" 1.0 0 -9276814 true "" "plot last p_g"

PLOT
909
89
1109
239
lucro do mundo
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
"soja" 1.0 0 -16777216 true "" "plot sum lm_s"
"gado" 1.0 0 -5298144 true "" "plot sum lm_g"

MONITOR
261
687
325
732
var: apt
variance [apt] of patches
3
1
11

MONITOR
332
687
412
732
mean: apt
mean [apt] of patches
3
1
11

MONITOR
429
687
527
732
dist s farm 1
(mean [apt] of patches with[farm = fazenda] / z_s) + (last [tec] of patches with[pcolor = red and farm = fazenda] / z_s) - (last p_s  / ( 2 * ((last c_s) ^ 2) * z_s))
17
1
11

INPUTBOX
768
124
831
184
z_g
0.5
1
0
Number

CHOOSER
20
682
158
727
fazenda
fazenda
1 2 3 4 5
1

SLIDER
699
286
871
319
p_m_s
p_m_s
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
689
629
861
662
zoom
zoom
0
1
0.4
0.1
1
NIL
HORIZONTAL

MONITOR
164
684
250
729
dist g farm
(mean [apt] of patches with[farm = fazenda] / z_g) + (last [tec] of patches with[pcolor = red and farm = fazenda] / z_g) - (last p_g  / ( 2 * ((last c_g) ^ 2) * z_g))
17
1
11

SLIDER
698
332
870
365
p_m_g
p_m_g
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
693
470
865
503
tec_mean
tec_mean
0
2
1.0
0.1
1
NIL
HORIZONTAL

INPUTBOX
700
124
763
184
z_s
2.5
1
0
Number

SLIDER
699
219
871
252
price_volatility
price_volatility
0.01
0.99
0.1
0.01
1
NIL
HORIZONTAL

TEXTBOX
700
195
879
225
Volatilidade dos preços
12
0.0
1

TEXTBOX
700
82
869
112
Dependência da cultura pela cidade
12
0.0
1

TEXTBOX
700
264
850
282
Preço das culturas
12
0.0
1

CHOOSER
696
379
834
424
Price_tendency
Price_tendency
"up" "stable" "down"
0

TEXTBOX
696
437
904
467
Tecnologia média das cidades
12
0.0
1

SLIDER
692
546
864
579
step_prob
step_prob
0
0.5
0.01
0.01
1
NIL
HORIZONTAL

TEXTBOX
692
519
872
549
Velocidade de aprendizado
12
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a model to analyze how the stock variables: deforestation and investment, will vary according to the flow variables: cattle price, soil fertility, knowledge of the rancher about the financial market and production techniques. At first, the model only analyzes the behavior of the rancher. There is no limit to how much it can deforest or invest. 

## HOW IT WORKS

The world will be populated with n farms. Each of them will be represented by a red pixel and will have different characteristics (knowledge about production techniques, soil fertility in the region). Each period the price of cattle will change. As the farms' investment decision takes place before the cattle sale takes place, they will have to predict this price. Those farms with the greatest predictive capacity are those with the greatest financial knowledge.
Based on the expected price, technological knowledge and soil fertility, the farms make the decision to invest in already deforested areas (blue pixel) or deforest new areas (brown pixel). The black pixel represente the frontier of the farm. 

## HOW TO USE IT

select the flow variables referring to the farms.
Then select the variables referring to the price of cattle. Then press the 'setup' button. Finally press the 'go' button. 

OBS: Red pixel represents the quarthead of the farm. Black represents its frontiers. Brown represents deforestation of new areas and blue represents investment (eg: acquisition of new machinery) to an area that was deforested before.

## THINGS TO NOTICE

Look at the graph referring to the size of the farms. It indicates the proportion of deforestation. The investment chart is also important. The greater the investment, the lesser the deforestation. 

## THINGS TO TRY

Raise the knowledge of the population. Realize that deforestation will reduce because the amount of investment has increased. The downward trend in cattle prices is also correlated with the decrease in deforestation. 

## EXTENDING THE MODEL

This model is still under construction. It is necessary to limit the capacity of farms to invest and deforest. This limitation should be based on the farms rate of return. In addition, the model must be calibrated for conditions in Brazil. 

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Da Silva, F, M. (2021).  Deforestation frontier .  https://github.com/fms-1988.  Program of Postgraduate Studies in Economics, University of Brasília, Brasília, DF.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## CREDITS AND REFERENCES

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">Deforestation Frontier </span> by <a xmlns:cc="http://creativecommons.org/ns#" href="https://github.com/fms-1988" property="cc:attributionName" rel="cc:attributionURL">Felipe Morelli</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.
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

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

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
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment_v2" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3"/>
    <metric>count patches with [farm != -1]</metric>
    <metric>count patches with [pcolor = blue]</metric>
    <metric>count patches with [pcolor = brown and farm = 1]</metric>
    <enumeratedValueSet variable="Price_tendency">
      <value value="&quot;down&quot;"/>
      <value value="&quot;up&quot;"/>
      <value value="&quot;stable&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price_volatility">
      <value value="0.01"/>
      <value value="0.15"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_farms">
      <value value="2"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Level_of_knowledge">
      <value value="&quot;low&quot;"/>
      <value value="&quot;middle&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="financial_knowledge">
      <value value="&quot;low&quot;"/>
      <value value="&quot;middle&quot;"/>
      <value value="&quot;high&quot;"/>
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
