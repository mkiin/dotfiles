_: {
  # ASRock の RGB LED コントローラーは ABS_X/Y/Z/RX/RY/RZ を含む 9 軸を申告するため joydev が
  # ゲームパッドと誤認識し js0 を占有する。Steam/SDL がこれをパッド 1 番として掴むと、
  # ABS_Z/ABS_RZ が LT/RT に対応してしまい起動直後からトリガー押しっぱなしになる。
  services.udev.extraRules = ''
    SUBSYSTEM=="input", ATTRS{idVendor}=="26ce", ATTRS{idProduct}=="01a2", ENV{ID_INPUT_JOYSTICK}=""
    SUBSYSTEM=="input", KERNEL=="js*", ATTRS{idVendor}=="26ce", ATTRS{idProduct}=="01a2", MODE="0000"
  '';
}
