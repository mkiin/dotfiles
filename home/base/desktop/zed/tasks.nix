{ ... }:
{
  programs.zed-editor = {
    mutableUserTasks = false;

    userTasks = [
      {
        label = "lazygit";
        command = "lazygit";
        cwd = "$ZED_WORKTREE_ROOT";
        use_new_terminal = true;
        allow_concurrent_runs = false;
        hide = "on_success";
      }
    ];
  };
}
