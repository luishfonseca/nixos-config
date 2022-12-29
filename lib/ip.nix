{ ... }: {
  cidr2mask = cidr:
    let
      pow = n: p: if p == 0 then 1 else n * pow n (p - 1);
      oct = n: builtins.bitXor 255 ((pow 2 (8 - n)) - 1);
      mask = n: o:
        if n > 8 then
          "255." + mask (n - 8) (o + 1)
        else
          toString (oct n) + (if o < 3 then "." + mask 0 (o + 1) else "");
    in
    mask cidr 0;
}
