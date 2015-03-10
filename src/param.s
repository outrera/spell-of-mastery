load_params Params File =
| less File.exists: bad "cant open [File]"
| Xs = File.get.utf8.parse{src File}^|$_ [[]] => []
| for Key,Value Xs{?1.0,?2.0}
  | case Value [`,` A B]
    | Value <= Value^| @r [`,` A B] => [@A^r B]
                     | X => [X]
  | Params.Key <= Value

main.load_params =
| Folder = "[$data]params/"
| $params <= @table: map BankName Folder.folders
  | RootParams = t
  | ParamsFile = "[Folder][BankName].txt"
  | when ParamsFile.exists: load_params RootParams ParamsFile
  | BankFolder = "[Folder][BankName]/"
  | Bank = @table: map Name BankFolder.urls.keep{is.[@_ txt]}{?1}
    | Params = RootParams.deep_copy
    | load_params Params "[BankFolder][Name].txt"
    | Name,Params
  | BankName,Bank
| for ActType,Act $params.acts: Act.type <= ActType

export load_params