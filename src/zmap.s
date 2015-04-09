ZMapHeight = 64
type zmap{Size} size/Size data/(dup Size: dup Size: dup ZMapHeight 0)

zmap.clear Value =
| for Ys $data: for Zs Ys: for I Zs.size: Zs.I <= Value

// gets cube at P in the form of [Value OriginXYZ EdgeLength]
zmap.get XYZ =
| X,Y,Z = XYZ
| [$data.X.Y.Z XYZ 1]

zmap.set X,Y,Z V =
| $data.X.Y.Z <= V

zmap.at X,Y,Z = $data.X.Y.Z

// get column of voxels at X,Y in the form of [@_[Count Id]@_]
zmap.getPilar X Y =
| Xs = ($data.X.Y){[1 ?]}
| on Xs | @r$_ [@H A,V B,&V @T] => [@H @[A+B,V @T]^r]

zmap.setPilar X Y Ys =
| Vs = $data.X.Y
| Z = 0
| for Count,V Ys
  | while Count
    | Vs.Z <= V
    | !Z+1
    | !Count-1

zmap.height X Y = ZMapHeight - $getPilar{X Y}.last.0

export zmap