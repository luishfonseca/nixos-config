{pkgs, ...}: {
  # Some common programs all hosts should have installed
  environment.systemPackages = with pkgs; [
    neovim
    git
    wget
  ];

  environment.variables.EDITOR = "nvim";
}
