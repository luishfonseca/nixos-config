{
  python3Packages,
  age,
  sops,
  openssh,
  mkpasswd,
}:
with python3Packages;
  buildPythonPackage rec {
    name = "prepare-secrets";
    src = ./.;
    pyproject = true;
    build-system = [setuptools];
    propagatedBuildInputs = [
      ruamel-yaml
      age
      sops
      openssh
      mkpasswd
    ];
    preBuild = ''
      echo "setuptools.setup(name='${name}', scripts=['${name}.py'])" > setup.py
    '';
    postInstall = ''
      mv -v $out/bin/${name}.py $out/bin/${name}
    '';
  }
