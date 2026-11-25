{ config, lib, ... }:
{
  options.modules.desktop.zzz-dialogue.enable =
    lib.mkEnableOption "the ZZZ dialogue preset for input-remapper";

  config = lib.mkIf config.modules.desktop.zzz-dialogue.enable {
    # keyd already grabs the physical keyboard, so listen to its output.
    xdg.configFile."input-remapper-2/presets/keyd virtual keyboard/ZZZ.json".text = builtins.toJSON [
      {
        input_combination = [
          {
            type = 1; # EV_KEY
            code = 66; # KEY_F8
          }
        ];
        target_uinput = "keyboard";
        # key() waits once before release and once after. Keep taps visible across game frames.
        macro_key_sleep_ms = 50;
        output_symbol = "toggle(key(KEY_1).wait(400))";
      }
    ];
  };
}
