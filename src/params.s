load_params Params File =
| less File.exists: bad "cant open [File]"
| Xs = File.get.utf8.parse{src File}.tail^|$_ [[]] => []
| for Key,Value Xs{?1.0,?2.0}
  | case Value [`,` A B]
    | Value <= Value^| @r [`,` A B] => [@A^r B]
                     | X => [X]
  | Params.Key <= Value

export load_params