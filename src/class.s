use gfx common util

type class{Bank ClassName static/0 empty/0 sprite/images_dummy}
  bank/Bank class_name/ClassName static/Static empty/Empty sprite/Sprite

class.height = $sprite.height

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
