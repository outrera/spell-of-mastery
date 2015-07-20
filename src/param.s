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
| Main = $params.main
| for BName,Bank $params: for PName,Params Bank: for Key,Value Params:
  | case Value [`.` SPName SKey]
    | less got Main.SPName and got Main.SPName.SKey:
      | bad "[BName]/[PName].txt/[Key]: missing main/[SPName].txt/[SKey]"
    | $params.BName.PName.Key <= Main.SPName.SKey
| for ActName,Act $params.acts:
  | Act.name <= ActName
  | Act.before_table <= Act.before.group{2}.table
  | Act.after_table <= Act.after.group{2}.table
  | when no Act.title: Act.title <= ActName.replace{_ ' '}
export load_params