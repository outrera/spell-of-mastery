use gfx util param

type sprite{Bank Name height/1 xy/[0 0]
            frames/0 faces/0 anims/[`|` [idle [0 24]]]
            class/0 margins/0 pick_height/0 speed/24}
  bank/Bank
  name/Name
  height/Height
  frames/Frames
  xy/Xy
  anims
  faces/Faces
  class/Class
  margins/Margins
  pick_height/Pick_height
  speed/Speed // how many cycles it takes to move between cells
| $anims <= @table: map [Name@Frames] Anims.tail
  | case Frames [[`-` time N]@Fs]: Frames <= Fs{[? N]}
  | [Name Frames]

sprite.anim_speed AnimName =
| Anim = $anims.AnimName
| if got Anim then Anim{?1}.sum else 0

init_frames S G =
| Frames = case S.frames
  [`*` W H] | map I (G.w*G.h)/(W*H): G.cut{I%(G.w/W)*W I/(G.w/W)*H W H}
  [@Fs] | map [X Y W H @Disp] Fs
          | R = @cut X Y W H G
          | R.xy <= Disp^($_ []=> [0 0])
          | R
  Else | [G]
| for F Frames: !F.xy + S.xy
| S.frames <= if S.faces then map F Frames [0 0 0 F 0 0 0 F] else Frames

init_frames_from_folder S Folder =
| Frames = t
| Anims = t
| for I,FName Folder.urls.keep{is.[@_ png]}{?1}.i
  | "[Angle]-[FrameName]" = FName
  | G = gfx."[Folder][FName].png"
  | G.xy <= S.xy //+ [X.int Y.int]
  | have Frames.FrameName [0 0 0 0 0 0 0 0]
  | Frames.FrameName.(Angle.int) <= G
| S.frames <= Frames

draw_iso_line Color X,Y Size Step Axis G =
| ICount = Size.abs
| JCount = Step.abs
| S = Size.sign
| if Axis >< 0
  then times I ICount: times J JCount: G.set{X+I*Step+J Y+I*S Color}
  else times I ICount: times J JCount: G.set{X+I*S Y+I*Step+J Color}

generate_base_tile Fill XUnit YUnit ZUnit =
| Color = #00a0a0
| A = [XUnit/2  0]
| B = [0        YUnit/2]
| C = [XUnit/2  YUnit]
| D = [XUnit    YUnit/2]
| G = gfx XUnit YUnit+2
| G.clear{#FF000000}
| G.xy <= 0,-ZUnit
| when Fill
  | G.triangle{Color A B C}
  | G.triangle{Color A B D}
  | G.triangle{Color B C D}
| draw_iso_line 0 [0 YUnit/2] -YUnit/2 2 0 G
| draw_iso_line 0 [XUnit-2 YUnit/2] -YUnit/2 -2 0 G
| draw_iso_line 0 [0 YUnit/2] YUnit/2 2 0 G
| draw_iso_line 0 [XUnit-2 YUnit/2] YUnit/2 -2 0 G
| G

main.load_sprites =
| Folder = "[$data]/sprites/"
| $sprites <= @table: @join: map BankName Folder.folders
  | RootParams = t
  | ParamsFile = "[Folder][BankName].txt"
  | when ParamsFile.exists: load_params RootParams ParamsFile
  | BankFolder = "[Folder][BankName]/"
  | map Name BankFolder.urls.keep{is.[@_ txt]}{?1}
    | Params = RootParams.deep_copy
    | ParamsFile = "[BankFolder][Name].txt"
    | when ParamsFile.exists: load_params Params ParamsFile
    | S = sprite BankName Name @Params.list.join
    | if S.frames >< folder
      then init_frames_from_folder S "[BankFolder][Name]/"
      else init_frames S gfx."[BankFolder][Name].png"
    //| have S.margins
    //  | S.margins <= S.frames.(S.anims.idle.0.0).margins
    | "[BankName]_[Name]",S
| Base = generate_base_tile $params.editor.opaque_base 64 32 8
| $sprites.tiles_base_ <= sprite tiles base_ frames/[Base]

export sprite
