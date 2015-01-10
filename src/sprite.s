use gfx common util

DummyGfx = gfx 1 1

type sprite{Bank Name height/1 empty/0 displacement/0 frames/0}
  bank/Bank name/Name height/Height empty/Empty
  frames/Frames displacement/Displacement

init_frames S G =
| S.frames <= case S.frames
  [`*` W H] | map I (G.w*G.h)/(W*H): G.cut{I%(G.w/W)*W I/(G.w/W)*H W H}
  [@Fs] | Fs{(@cut @? G)}
  Else | [G]

load_params Params File =
| less File.exists: bad "cant open [File]"
| for Key,Value File.get.utf8.parse{src File}.tail{}{?1.0,?2.0}
  | case Value [`,` A B]
    | Value <= Value^| @r [`,` A B] => [@A^r B]
                     | X => [X]
  | Params.Key <= Value

main.load_sprites =
| Folder = "[$data]/sprites/"
| $sprites <= @table: @join: map BankName Folder.folders
  | RootParams = t
  | ParamsFile = "[Folder][BankName].txt"
  | when ParamsFile.exists: load_params RootParams ParamsFile
  | BankFolder = "[Folder][BankName]/"
  | map Name BankFolder.urls.keep{is.[@_ png]}{?1}
    | Params = RootParams.deep_copy
    | ParamsFile = "[BankFolder][Name].txt"
    | when ParamsFile.exists: load_params Params ParamsFile
    | S = sprite BankName Name @Params.list.join
    | init_frames S gfx."[BankFolder][Name].png"
    | "[BankName]_[Name]",S

export sprite
