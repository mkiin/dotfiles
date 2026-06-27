{ config, dotfilesDir, ... }:

{
  _module.args.dotLink = subdir: name:
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${subdir}/${name}";
}
