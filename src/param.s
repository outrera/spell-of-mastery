load_params File =
| less File.exists: bad "cant open [File]"
| Xs = File.get.utf8.parse{src File}^|$_ [[]] => []
| map Key,Value Xs{?1.0,?2.0}
  | case Value [`,` A B]
    | Value <= Value^| @r [`,` A B] => [@A^r B]
                     | X => [X]
  | Key,Value

main.load_params =
| Folder = "[$data]params/"
| $params <= @table: map BankName Folder.folders
  | ParamsFile = "[Folder][BankName].txt"
  | RootParams = if ParamsFile.exists then @table: load_params ParamsFile else t
  | BankFolder = "[Folder][BankName]/"
  | Bank = @table: map Name BankFolder.urls.keep{is.[@_ txt]}{?1}
    | Params = RootParams.deep_copy
    | KVs = load_params "[BankFolder][Name].txt"
    | case KVs
      [[proto _] @_] | Params <= KVs.table
      Else | Params <= RootParams.deep_copy
           | for K,V KVs: Params.K <= V
    | Name,Params
  | BankName,Bank
| Main = $params.main
| for BName,Bank $params: for PName,Params Bank: for Key,Value Params:
  | case Value [`.` SPName SKey]
    | less got Main.SPName and got Main.SPName.SKey:
      | bad "[BName]/[PName].txt/[Key]: missing main/[SPName].txt/[SKey]"
    | $params.BName.PName.Key <= Main.SPName.SKey
| for BName,Bank $params: for PName,Params Bank: when got Params.proto:
  | SBName = BName
  | SPName = Params.proto
  | case SPName B,P:
    | SBName <= B
    | SPName <= P
  | Proto = $params.SBName.SPName.deep_copy
  | for K,V Params: less K><proto: Proto.K <= V
  | Bank.PName <= Proto
| for ActName,Act $params.acts:
  | Act.name <= ActName
  | Act.before_table <= Act.before.group{2}.table
  | Act.after_table <= Act.after.group{2}.table
  | when no Act.title: Act.title <= ActName.replace{_ ' '}

export load_params