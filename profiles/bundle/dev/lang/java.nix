{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    jdk
    maven
    gradle
  ];

  hm.programs.vscode.profiles.default.extensions = with pkgs.unstable.vscode-extensions; [
    redhat.java
    vscjava.vscode-java-debug
    vscjava.vscode-java-test
    vscjava.vscode-maven
    vscjava.vscode-gradle
    vscjava.vscode-java-dependency
  ];
}
