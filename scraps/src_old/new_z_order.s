use gfx gui


type blit_item
  id
  object
  gfx
  sx sx2   // Screenspace X coords
  sy sy2   // Screenspace Y coords
  x x2     // Worldspace bounding box x
  y y2     // Worldspace bounding box y
  z z2     // Worldspace bounding box z
  sxleft   // Screenspace bounding box left extent    (LNT x coord)
  sxright  // Screenspace bounding box right extent   (RFT x coord)
  sxtop    // Screenspace bounding box top x coord    (LFT x coord)
  sytop    // Screenspace bounding box top extent     (LFT y coord)
  sxbot    // Screenspace bounding box bottom x coord (RNB x coord) ss origin
  sybot    // Screenspace bounding box bottom extent  (RNB y coord) ss origin
  f32x32   // flag: 32x32 flat (floor tile)
  flat     // flag: floor tile with 0 height
  occl     // flag: occludes other tiles
  solid    // flag
  draw     // flag
  roof     // flag
  noisy    // flag
  anim     // flag: tile is animated
  trans    // flag: tile is transparent
  fixed    // flag
  land     // flag
  occluded  // Set true if occluded
  clipped  // Clipped to RenderSurface
  order // Rendering order. -1 is not yet drawn


compare_items A B =
| BothFlat = A.flat and B.flat //flat tiles are floor tiles
| when BothFlat
  | when A.z2 <> B.z2: leave A.z2 < B.z2
  // Equal z
  | when A.anim <> B.anim:
    | leave A.anim < B.anim // allows animation overlay on top of static tiles
  | when A.trans <> B.trans:
    | leave A.trans < B.trans // allows overlay on top of other tiles
  | when A.draw <> B.draw: leave A.draw > B.draw 
  | when A.solid <> B.solid: leave A.solid > B.solid
  | when A.occl <> B.occl: leave A.occl > B.occl 
  | when A.f32x32 <> B.f32x32: leave A.f32x32 > B.f32x32
| less BothFlat
  | when A.z2 << B.z: leave 1
  | when A.z >> B.z2: leave 0
| when A.x << B.x2: leave 1
| when A.x2 >> B.x: leave 0
| when A.y << B.y2: leave 1
| when A.y2 >> B.y: leave 0
| when A.z < B.z: leave 1
| when A.z > B.z: leave 0
| when (A.z2+A.z)/2 << B.z: leave 1
| when A.z >> (B.z2+B.z)/2: leave 0
| when (A.x+A.x2)/2 << B.x2: leave 1
| when A.x2 >> (B.x+B.x2)/2: leave 0
| when (A.y+A.y2)/2 << B.y2: leave 1
| when A.y2 >> (B.y+B.y2)/2: leave 0
| when A.x+A.y <> B.x+B.y: leave A.x+A.y < B.x+B.y
| when A.x2+A.y2 <> B.x2+B.y2: leave A.x2+A.y2 < B.x2+B.y2
| when A.x <> B.x: leave A.x < B.x
| when A.y <> B.y: leave A.y < B.y
| leave A.id < B.id

type item{x y z xd yd zd gfx} id

type test.widget{unit block} mx my serial objects/dup{100}
| $add_item{item{50   50 0 37 37 64 $unit}}
| $add_item{item{200  100 0 64 64 64 $block}}
| $add_item{item{400  100 64 64 64 64 $block}}


test.add_item Item =
| Item.id <= $serial
| Item.gfx.xy <= [0 0]
| $objects.$serial <= Item
| !$serial+1
| Item.id

test.w = 512
test.h = 512

test.input In =
| case In
  [mice_move _ X,Y]
    | $mx <= X
    | $my <= Y
    | O = $objects.0
    | when O:
      | O.x <= ($mx/2 + $my)
      | O.y <= ($my - $mx/2) 

to_iso X,Y,Z = [X-Y (X+Y)/2-Z]

test.draw FB BX BY =
| CamX,CamY,CamZ = 0,0,0
| CamSX = (CamX - CamY) // Screenspace bounding box bottom x coord
| CamSY = (CamX - CamY)/2 - CamZ // Screenspace bounding box bottom extent
| FB.clear{#00A0A0}
| Os = $objects.skip{0}
| Bs = map O Os
  | B = blit_item
  | B.object <= O
  | B.id <= O.id
  | B.gfx <= O.gfx
  | B.x <= O.x //xright
  | B.y <= O.y //xnear
  | B.z <= O.z //zbot
  | B.x2 <= O.x - O.xd/2
  | B.y2 <= O.y - O.yd/2
  | B.z2 <= O.z + O.zd/2
  | B.flat <= O.zd >< 0

    // Screenspace bounding box left extent    (LNT x coord)
  | B.sxleft <= B.x2 - B.y - CamSX
    // Screenspace bounding box right extent   (RFT x coord)
  | B.sxright <= B.x/2 - B.y2/2 - CamSX

    // Screenspace bounding box top x coord    (LFT x coord)
  | B.sxtop <= B.x2 - B.y2- CamSX
    // Screenspace bounding box top extent     (LFT y coord)
  | B.sytop <= B.x2/2 + B.y2/2 - B.z2 - CamSY

    // Screenspace bounding box bottom x coord (RNB x coord)
  | B.sxbot <= B.x - B.y - CamSX
    // Screenspace bounding box bottom extent  (RNB y coord)
  | B.sybot <= B.x/2 + B.y/2 - B.z - CamSY
    // Real Screenspace coords
  | B.sx <= B.sxbot - B.gfx.xy.0 // Left
  | B.sy <= B.sybot - B.gfx.xy.1 // Top
  | B.sx2 <= B.sx + B.gfx.w // Right
  | B.sy2 <= B.sy + B.gfx.h // Bottom
  | B
| Bs = Bs.sort{&compare_items}
| for B Bs:
  | G = B.gfx
  | P = [-CamSX -CamSY]
  | ZD = B.object.zd
  | P1 = to_iso{B.x2,B.y2,B.z} - [0 ZD] + P
  | P2 = to_iso{B.x2,B.y,B.z} - [0 ZD] + P
  | P3 = to_iso{B.x,B.y2,B.z} - [0 ZD] + P
  | P4 = to_iso{B.x,B.y,B.z} - [0 ZD] + P
  | P5 = to_iso{B.x2,B.y,B.z} + P
  | P6 = to_iso{B.x,B.y2,B.z} + P
  | P7 = to_iso{B.x,B.y,B.z} + P
  | P8 = to_iso{B.x2,B.y2,B.z} + P
  | FB.blit{P7.0-G.w/2 P7.1-G.h B.gfx}
  | for A,B [P5,P7 P6,P7 P5,P8 P6,P8
             P5,P2 P6,P3 P8,P1 P7,P4
             P2,P4 P3,P4 P2,P1 P3,P1]
    | FB.line{#00FF00 A B}


    /*
                Bounding Box layout

           1    
         /   \      
       /       \     1 = Left  Far  Top LFT --+
     2           3   2 = Left  Near Top LNT -++
     | \       / |   3 = Right Far  Top RFT +-+
     |   \   /   |   4 = Right Near Top RNT +++
     |     4     |   5 = Left  Near Bot LNB -+-
     |     |     |   6 = Right Far  Bot RFB +--
     5     |     6   7 = Right Near Bot RNB ++- 
       \   |   /     8 = Left  Far  Bot LFB --- (not shown)
         \ | /    
           7    

    */


Unit = gfx '/Users/nikita/Downloads/work/newz/unit.png'
Block = gfx '/Users/nikita/Downloads/work/newz/block.png'
CH = gfx '/Users/nikita/Downloads/work/newz/ch.png'
CH.xy <= -11,-10
T = test Unit Block


gui T cursor/CH