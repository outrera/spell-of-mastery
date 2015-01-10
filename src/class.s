use gfx common util

type class{Bank Name type/static empty/0 sprite/'images_dummy'}
  bank/Bank name/Name type/Type empty/Empty sprite/Sprite

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
    | R.sprite <= $sprites.(R.sprite)
    | "[BankName]_[Name]",R

export class
