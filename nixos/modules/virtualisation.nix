{ ... }:
{
  users.users.root.extraGroups = [ "docker" ];

  virtualisation = {
    arion = {
      backend = "docker";
    };
    docker.enable = true;
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
