use gfx util param

type sprite{Bank Name height/1 xy/[0 0]
            frames/0 faces/1 anims/[`|` [idle [0 24]]]
            class/0}
  bank/Bank
  name/Name
  height/Height
  frames/Frames
  xy/Xy
  anims/Anims.tail{}{[?0 ?tail]}.table
  faces/Faces
  class/Class

init_frames S G =
| S.frames <= case S.frames
  [`*` W H] | map I (G.w*G.h)/(W*H): G.cut{I%(G.w/W)*W I/(G.w/W)*H W H}
  [@Fs] | map [X Y W H @Disp] Fs
          | R = @cut X Y W H G
          | R.xy <= Disp^($_ []=> [0 0])
          | R
  Else | [G]
| for F S.frames: !F.xy + S.xy

init_frames_from_folder S Folder =
| Anims = t
| S.frames <= map I,FName Folder.urls.keep{is.[@_ png]}{?1}.i
  | "[Dir]-[Anim]-[Index]-[Wait]+[X]+[Y]" = FName
  | G = gfx."[Folder][FName].png"
  | G.xy <= [X.int Y.int] + S.xy
  | Anims->Anim.Index <= [I Wait.int]
  | G
| S.anims <= Anims.list{}{[?0 ?1.list.sort{?0 < ??0}{?1}]}.table

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
    | "[BankName]_[Name]",S
| Base = generate_base_tile $params.editor.opaque_base 64 32 8
| $sprites.tiles_base_ <= sprite tiles base_ frames/[Base]

export sprite
