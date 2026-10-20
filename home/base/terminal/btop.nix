{ ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "noctalia";
      theme_background = false;
      truecolor = true;
      rounded_corners = true;
      terminal_sync = true;
      graph_symbol = "braille";

      shown_boxes = "cpu mem net proc";
      update_ms = 1000;

      cpu_single_graph = false;
      show_gpu_info = "Auto";
      show_coretemp = true;
      show_cpu_watts = true;
      clock_format = "%X";

      mem_graphs = true;
      show_disks = true;
      show_swap = true;

      net_auto = true;
      net_sync = true;

      proc_sorting = "memory";
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
    };
  };
}
