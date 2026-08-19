{ lib, stateFile ? ../terraform.tfstate }:
let
  tfstate = (builtins.fromJSON (builtins.readFile stateFile)).outputs;
  outputs = builtins.mapAttrs (_: output: output.value) tfstate;

  isNodeOutput = name: name == "terraflake" || name == "nixiform";
  meta = lib.filterAttrs (name: _: !(isNodeOutput name)) outputs;
  nodeOutputs = lib.filterAttrs (name: _: isNodeOutput name) outputs;
  nodesOutput = nodeOutputs.terraflake or nodeOutputs.nixiform;
  nodeList = if builtins.isList nodesOutput then nodesOutput else [ nodesOutput ];
  nodes = lib.listToAttrs (map (node: lib.nameValuePair node.name node) nodeList);
in
{
  inherit meta nodes;
}
