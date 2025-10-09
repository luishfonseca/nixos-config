{profiles, ...}: {
  imports = with profiles; [
    hardware.common-cpu-amd
    hardware.common-cpu-amd-pstate
    hardware.common-cpu-amd-zenpower
  ];

  programs.ryzen-monitor-ng.enable = true;
}
