//fast arithmetics for fixnum expressions

tofxn E =
| less E.is_list: leave E
| case E
  [`<=` X @Xs]
    | case X [[`.` A I]]
      | less I.is_text and not I.0.is_upcase:
        | leave [_refs A^tofxn I^tofxn Xs^tofxn]
    | leave [`<=` X Xs^tofxn]
  [esc @Xs] | leave Xs
| E <= E{?^tofxn}
| E


fxn E = tofxn E

export 'fxn'
