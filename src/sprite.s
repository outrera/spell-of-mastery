use gfx util param

type sprite{Bank Name xy/[0 0]
            frames/0 faces/0 anims/[`|` [idle [0 24]]] recolors/0
            class/0 margins/0 pick_height/0
            font/Font icon/0 shadow/0 form/[`|` [4]] rect/[40 76 -4]}
  bank/Bank
  name/Name
  frames/Frames
  xy/Xy
  anims
  faces/Faces
  class/Class
  margins/Margins
  pick_height/Pick_height
  font/Font
  icon/Icon
  shadow/Shadow
  form
  rect/Rect
  recolors/Recolors
  colors/0
| XYs = []
| for Y,Hs Form.tail.i: for X,H Hs.i: when H: push [-X Y 0] XYs
| $form <= XYs.list
| $anims <= @table: map [Name@Frames] Anims.tail
  | case Frames [[`-` time N]@Fs]: Frames <= Fs{[? N]}
  | [Name Frames]
| when got $anims.death and no $anims.hit:
  | $anims.hit <= [[$anims.idle.0.0 24]] //supply default hit anim
| Attack = $anims.attack
| when no Attack:
  | Attack <= $anims.idle
  | $anims.attack <= Attack
| when no Attack.find{?0><impact}:
  | $anims.attack <= if Attack.size>1
                     then [@Attack.lead [impact 0] Attack.last]
                     else [Attack.head [impact 0]]

sprite.anim_speed AnimName =
| Anim = $anims.AnimName
| if got Anim then Anim{?1}.sum else 0

init_frames_from_list S List =
| Frames = t
| Anims = t
| for FName,G List
  | Name = FName
  | Angle = 0
  | case Name "[A]-[N]"
    | Angle <= A.int
    | Name <= N
  | X = 0
  | Y = 0
  | case Name "[N]+[XX]+[YY]"
    | X <= XX.int
    | Y <= YY.int
    | Name <= N
  | G.xy <= S.xy + [X Y]
  | have Frames.Name [0 0 0 0 0 0 0 0]
  | Frames.Name.Angle <= G
| S.frames <= Frames

init_frames S G =
| Rs = S.recolors
| CM = G.cmap
| when Rs and CM:
  | Rs = map R Rs: CM.locate{R}
  | Default = Rs.find{?<>No}
  | when got Default: S.colors <= map R Rs: if R<>No then R else No
  //| say [S.name CM.size S.colors]
| Frames = case S.frames
  [`*` W H] | map I (G.w*G.h)/(W*H): G.cut{I%(G.w/W)*W I/(G.w/W)*H W H}
  [list Ls]
     | Xs = map [N Rect] Ls:
       | [N G.cut{@Rect}]
     | G.free
     | leave: init_frames_from_list S Xs
  [@Fs] | Xs = map [X Y W H @Disp] Fs
          | R = @cut X Y W H G
          | R.xy <= Disp^($_ []=> [0 0])
          | R
        | G.free
        | Xs
  Else | [G]
| for F Frames: !F.xy + S.xy
| S.frames <= if S.faces then map F Frames [0 0 0 F 0 0 0 F] else Frames


init_frames_from_folder S Folder =
| Xs = map FName Folder.urls.keep{is.[@_ png]}{?1}
  | [FName gfx."[Folder][FName].png"]
| init_frames_from_list S Xs

init_sprites Me =
| Sprites = $sprites
| for SpriteName,Params Sprites
  | S = sprite Params.bank Params.name @Params.list.join
  | if S.frames >< folder
    then init_frames_from_folder S "[Params.filepath]/"
    else init_frames S gfx."[Params.filepath].png"
  | $sprites.SpriteName <= S
| for Name,Sprite $sprites: when!it Sprite.shadow: Sprite.shadow <= $img{it}

join_banks Bs =
| @table: @join: map BankName,Bank Bs:
                 map PName,Params Bank: "[BankName]_[PName]",Params

main.load_sprites =
| Params = load_params "[$data]/sprites/"
| $credits.graphics <= extract_params_authors Params
| $sprites <= join_banks Params
| init_sprites Me
| $effect <= $spr{ui_unit_effects}

main.img Name =
| S = $sprites."[Name]"
| less got S: bad "missing image `[Name]`"
| S.frames.0

main.spr Name =
| S = $sprites."[Name]"
| less got S: bad "missing sprite `[Name]`"
| S

export sprite
