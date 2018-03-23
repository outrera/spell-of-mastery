use util act

normalize_curly E =
| case E
  [`{}` Name @Args] | [Name @Args{?^normalize_curly}]
  Else | E

load_params2 File =
| less File.exists: bad "cant open [File]"
| Xs = File.get.utf8.parse{src File}^|$_ [[]] => []
| map Key,Value Xs{?1.0,?2.0}
  | case Value
    [`,` A B]
      | Value <= Value^| @r [`,` A B] => [@A^r B]
                       | X => [X]
      | Value <= Value{?^normalize_curly}
    [`{}` Name @Args]
      | Value <= normalize_curly Value
      | Value <= [Value]
    Else | Value
  | Key,Value

load_params Folder =
| @table: map BankName Folder.folders
  | RootParamsFile = "[Folder][BankName].txt"
  | RootParams = if RootParamsFile.exists
                 then @table: load_params2 RootParamsFile
                 else t
  | BankFolder = "[Folder][BankName]/"
  | Bank = @table: map Name BankFolder.urls.keep{is.[@_ txt]}{?1}
    | Params = RootParams.deep_copy
    | KVs = load_params2 "[BankFolder][Name].txt"
    | case KVs
      [[proto _] @_] | Params <= KVs.table
      Else | Params <= RootParams.deep_copy
           | for K,V KVs: Params.K <= V
    | Params.bank <= BankName
    | Params.name <= Name
    | Params.filepath <= "[BankFolder][Name]"
    | Name,Params
  | BankName,Bank

extract_params_authors Params =
| Authors = t
| for BankName,Items Params: for Name,Item Items
  | Author = Item.author
  | Origin = Item.origin
  | when got Author:
    | /*when no Origin:*/ Origin <= "[BankName]/[Name]"
    | less Author.is_list: Author <= [Author]
    | less Origin.is_list: Origin <= [Origin]
    | for A Author
      | when no Authors.A: Authors.A <= []
      | for O Origin: push O Authors.A
| for K,V Authors: Authors.K <= V.uniq
| Authors

params_handle_vars Me =
| Main = $params.main
| for BName,Bank $params: for PName,Params Bank: for Key,Value Params:
  | case Value [`.` SPName SKey]
    | less got Main.SPName and got Main.SPName.SKey:
      | bad "[BName]/[PName].txt/[Key]: missing main/[SPName].txt/[SKey]"
    | $params.BName.PName.Key <= Main.SPName.SKey

params_handle_prototypes Me =
| for BName,Bank $params: for PName,Params Bank: when got Params.proto:
  | SBName = BName
  | SPName = Params.proto
  | case SPName B,P:
    | SBName <= B
    | SPName <= P
  | Proto = $params.SBName.SPName.deep_copy
  | for K,V Params: less K><proto: Proto.K <= V
  | Bank.PName <= Proto

params_handle_acts Me =
| Acts = $params.acts
| SP = Acts.spawn__proto
| for N,U $params.unit: less U.aux: when U.summon:
  | when U.summon<>auto: N <= U.summon
  | A = SP.deep_copy
  | A.icon <= "unit_[N]"
  | Lore,Mana,Cool = U.cost
  | A.lore <= Lore
  | A.cost <= Mana
  | A.cool <= Cool
  | Acts."summon_[N]" <= A
| for Name,Act Acts: Acts.Name <= act Name @Act.list.join
| for Name,Act Acts: when Act.menu:
  | Act.menu <= map ActName Act.menu:
    | SubAct = Acts.ActName
    | less got SubAct: bad "[Act.name]'s menu references undefined act [ActName]"
    | SubAct

main.load_params =
| $params <= load_params "[$data]params/"
| params_handle_vars Me
| params_handle_prototypes Me
| params_handle_acts Me

export load_params extract_params_authors
