use util act

normalize_curly E =
| case E
  [`{}` Name @Args] | [Name @Args{?^normalize_curly}]
  Else | E

cfg_load2 File =
| less File.exists: bad "cant open [File]"
| Xs = File.get.utf8.parse{src File}^|$_ [[]] => []
| map KV Xs
  | when KV.size <> 3 or not KV.1.is_list or not KV.2.is_list:
    | bad "entry `[KV]` in [File]"
  | Key = KV.1.0
  | Value = KV.2.0
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

main.cfg_load_folder Folder =
| @table: map BankName Folder.folders
  | RootCfgFile = "[Folder][BankName].txt"
  | RootCfgs = if RootCfgFile.exists
               then @table: cfg_load2 RootCfgFile
               else t
  | BankFolder = "[Folder][BankName]/"
  | Bank = @table: map Name BankFolder.urls.keep{is.[@_ txt]}{?1}
    | Cfg = RootCfgs.deep_copy
    | KVs = cfg_load2 "[BankFolder][Name].txt"
    | case KVs
      [[proto _] @_] | Cfg <= KVs.table
      Else | Cfg <= RootCfgs.deep_copy
           | for K,V KVs: Cfg.K <= V
    | Cfg.bank <= BankName
    | Cfg.name <= Name
    | Cfg.filepath <= "[BankFolder][Name]"
    | Name,Cfg
  | BankName,Bank

main.extract_cfg_authors Cfg =
| Authors = t
| for BankName,Items Cfg: for Name,Item Items
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

main.prepare_credits =
| GCredits = $credits.graphics.list.sort{?0<??0}
| SCredits = $credits.sound.list.sort{?0<??0}
| MCredits = $credits.music.list.sort{?0<??0}
| GCreditsT = @text: map K,Vs GCredits: "  [K]\n"
| SCreditsT = @text: map K,Vs SCredits: "  [K]\n"
| MCreditsT = @text: map K,Vs MCredits: "  [K]\n"
| $credits <= @text:
              ["SPELL OF MASTERY CREDITS\n\n"
               "Designed and Programmed by Nikita Sadkov\n\n\n"
               "GRAPHICS:\n" GCreditsT
               "\n\n\nMUSIC:\n" MCreditsT
               "\n\n\nSOUND:\n" SCreditsT
               "\n\n\nTHANKS TO:\n"
               "  Matthew Ostil\n"
               "  Anonymous supporters from lj.rossia.org who donated a few BTC"
              ]

main.cfg_handle_vars =
| Main = $cfg.main
| for BName,Bank $cfg: for PName,Cfgs Bank: for Key,Value Cfgs:
  | case Value [`.` SPName SKey]
    | less got Main.SPName and got Main.SPName.SKey:
      | bad "[BName]/[PName].txt/[Key]: missing main/[SPName].txt/[SKey]"
    | $cfg.BName.PName.Key <= Main.SPName.SKey

main.cfg_handle_prototypes =
| for BName,Bank $cfg: for PName,Cfgs Bank: when got Cfgs.proto:
  | SBName = BName
  | SPName = Cfgs.proto
  | case SPName B,P:
    | SBName <= B
    | SPName <= P
  | Proto = $cfg.SBName.SPName.deep_copy
  | for K,V Cfgs: less K><proto: Proto.K <= V
  | Bank.PName <= Proto

main.cfg_handle_acts =
| Acts = $cfg.acts
| $acts <= Acts
| SP = Acts.spawn__proto
| for N,U $cfg.unit: when U.cost: //create summon table
  | A = SP.deep_copy
  | A.icon <= "unit_[N]"
  | GoldCost,MaxPicks,PickChance = U.cost
  | A.gold <= GoldCost
  | A.maxPicks <= MaxPicks
  | A.pickChance <= PickChance
  | Acts."unit_[N]" <= A
| for Name,Act Acts: Acts.Name <= act Name @Act.list.join
| for Name,Act Acts: when Act.menu and Act.menu.0<>'<':
  | Act.menu <= map ActName Act.menu:
    | SubAct = Acts.ActName
    | less got SubAct:
      | bad "[Act.name]'s menu references undefined act [ActName]"
    | SubAct

main.load_configuration =
| $cfg <= $cfg_load_folder{"[$data]cfg/"}
| $cfg_handle_vars
| $cfg_handle_prototypes
| $cfg_handle_acts
