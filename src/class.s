use gfx util param

type class{bank class_name static/0 empty/0 sprite/system_dummy
           unit/0 draw_order/10 aux/0 shadow/0 moves/0 speed/1
           starts/0}
  type/"[Bank]_[Class_name]"
  static/Static
  empty/Empty
  default_sprite/Sprite
  unit/Unit
  draw_order/Draw_order
  aux/Aux
  shadow/Shadow // unit casts shadow in air
  moves/Moves // moves per turn
  speed/Speed // how many cycles it takes to move between cells
  starts/Starts // non-zero if unit starts active
  

class.height = $default_sprite.height

main.load_classes =
| Folder = "[$data]/classes/"
| $classes <= @table: @join: map BankName Folder.folders
  | RootParams = t
  | ParamsFile = "[Folder][BankName].txt"
  | when ParamsFile.exists: load_params RootParams ParamsFile
  | BankFolder = "[Folder][BankName]/"
  | map Name BankFolder.urls.keep{is.[@_ txt]}{?1}
    | Params = RootParams.deep_copy
    | ParamsFile = "[BankFolder][Name].txt"
    | when ParamsFile.exists: load_params Params ParamsFile
    | R = class BankName Name @Params.list.join
    | S = $sprites.(R.default_sprite)
    | less got S: bad "missing sprite `[R.default_sprite]`"
    | R.default_sprite <= S
    | "[BankName]_[Name]",R
| for S $sprites{}{?1}.keep{?auto_class}
  | C = class S.bank S.name @S.auto_class
  | C.default_sprite <= S
  | $classes."[S.bank]_[S.name]" <= C

export class
