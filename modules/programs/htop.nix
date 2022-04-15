{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.htop; in
{
  options.lhf.programs.htop.enable = mkEnableOption "htop";

  config.programs.htop = mkIf cfg.enable {
    enable = true;
    settings = {
      hide_kernel_threads = 1;
      hide_userland_threads = 1;
      shadow_other_users = 0;
      show_program_path = 0;
      highlight_base_name = 1;
      highlight_deleted_exe = 1;
      highlight_megabytes = 1;
      highlight_threads = 1;
      highlight_changes = 0;
      highlight_changes_delay_secs = 5;
      find_comm_in_cmdline = 1;
      strip_exe_from_cmdline = 1;
      show_merged_command = 0;
      tree_view = 1;
      header_margin = 1;
      cpu_count_from_one = 0;
      show_cpu_usage = 1;
      show_cpu_frequency = 1;
      show_cpu_temperature = 1;
      update_process_names = 1;
      color_scheme = 0;
      enable_mouse = 1;
      hide_function_bar = 0;
    };
  };
}
