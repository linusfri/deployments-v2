{
  lib,
  node,
  nodes,
  infrastructureMeta ? { },
  ...
}:
{
  options.infrastructure = {
    node = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      description = "Infrastructure data for this host.";
    };

    nodes = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      readOnly = true;
      description = "All infrastructure nodes indexed by name.";
    };

    meta = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      description = "Non-node OpenTofu outputs.";
    };
  };

  config.infrastructure = {
    inherit node nodes;
    meta = infrastructureMeta;
  };
}
