{

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs
          {
            config.allowUnfree = true;
            inherit system;
          };
          op-inject = pkgs.runCommandNoCC "op-inject"
          {
            buildInputs = [
              pkgs._1password
            ];
          }
          ''
            mkdir -p $out/share/op-inject
            substitute ${./op-inject.sh} $out/share/op-inject/op-inject.sh \
              --subst-var-by op ${pkgs._1password}/bin/op \
          '';
    in
        {
          default = op-inject;
        }
      );
    };
}
