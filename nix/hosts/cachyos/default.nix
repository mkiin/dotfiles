{ nixRoot, ... }:

{
  imports = [
    (nixRoot + /home)
    (nixRoot + /linux)
  ];
}
