type zmap{size depth init} data
| $data <= dup $size: dup $size: dup $depth $init

zmap.clear Value = for Ys $data: for Zs Ys: Zs.clear{Value}

zmap.set X Y Z V = $data.X.Y.Z <= V

zmap.at X Y Z = $data.X.Y.Z

zmap.getPilar X Y = $data.X.Y.take{$height{X Y}}

zmap.setPilar X Y Zs =
| Vs = $data.X.Y
| Vs.clear{$init}
| times I Zs.size: Vs.I <= Zs.I

zmap.height X Y =
| Vs = $data.X.Y
| Z = $depth
| while Z
  | !Z-1
  | when Vs.Z.id: leave Z+1
| leave 0

export zmap