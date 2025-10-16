_: let
  # Generate a random hex key and save it to /keys
  genKey = key: ''
    mkdir -p /keys
    od -Anone -x -N 32 /dev/random | tr -d [:blank:] | tr -d '\n' > /keys/${key}
    chmod 600 /keys/${key}
  '';
in {
  inherit genKey;
}
