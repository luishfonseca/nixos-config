{
  lib,
  inputs,
  ...
}: let
  eachSystem = f: builtins.listToAttrs (builtins.map (system: lib.nameValuePair system (f system)) (import inputs.systems));
in {
  inherit eachSystem;
}
