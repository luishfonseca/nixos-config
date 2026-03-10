{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    unstable.claude-code
  ];

  persist.home = {
    files = [".claude.json"];
    directories = [".claude"];
  };
}
