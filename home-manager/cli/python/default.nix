_:

{
  xdg.configFile."pip/pip.conf".text = ''
    [global]
    index-url = https://ftp.jaist.ac.jp/pub/PyPI/simple/
    trusted-host = ftp.jaist.ac.jp
  '';

  xdg.configFile."uv/uv.toml".text = ''
    [[index]]
    url = "https://ftp.jaist.ac.jp/pub/PyPI/simple/"
    default = true

    [[index]]
    url = "https://pypi.org/simple/"

    [[index]]
    name = "pytorch"
    url = "https://download.pytorch.org/whl/cu128"
  '';
}
