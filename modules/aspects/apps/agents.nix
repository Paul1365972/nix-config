{ inputs, lib, ... }:
let
  skillsDir = inputs.self + "/skills";

  skills = lib.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
  );

  link =
    agentDir: name: lib.nameValuePair "${agentDir}/skills/${name}" { source = skillsDir + "/${name}"; };
in
{
  den.aspects.agents.homeManager.home.file = lib.listToAttrs (
    lib.concatMap (name: [
      (link ".claude" name)
      (link ".codex" name)
    ]) skills
  );
}
