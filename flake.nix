{
  description = "flake for elixir-phoenix";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "github:flox/nixpkgs/unstable";
  outputs = {
    self,
    nixpkgs,
  }:
  #let
  #     # to work with older version of flakes
  #     lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  #     # Generate a user-friendly version number.
  #     version = builtins.substring 0 8 lastModifiedDate;
  #     # System types to support.
  #     supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  #     # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
  #     forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  #     # Nixpkgs instantiated for supported system types.
  #     nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  #   in
  {
    packages.x86_64-linux.default = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
      packages = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang;
    in
      packages.mixRelease rec {
        mixNixDeps = with pkgs; import ./mix_deps.nix { inherit lib beamPackages; };  
        pname = "hello-phoenix";
        version = "0.0.0";
        # "self" defaults to the root of your project.
        # amend the path if it is non-standard with `self + "/src";`, for example
        src = ./.;

        MIX_ENV = "prod";

        # nix will create a "fixed output derivation" based on
        # the total package of fetched mix dependencies, identified by a hash
        # mixFodDeps = packages.fetchMixDeps {
        #   inherit version src pname;
        #   # nix will complain when you build, since it can't verify the hash of the deps ahead of time.
        #   # In the error message, it will tell you the right value to replace this with
        #   sha256 = pkgs.lib.fakeSha256;
        #   #sha256 = "sha256-GvT+lzfIJ+SVfx/oN1rfKIK+W4kJo3eaE7mnWd3fhc8=";
        #   # if you have build time environment variables, you should add them here
        #   #MY_VAR="value";
        #   buildInputs = [];

        #   propagatedBuildInputs = [];
        # };
      };

    devShells.x86_64-linux.default = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
    in 
    pkgs.mkShell {
        buildInputs = with pkgs; [alejandra bat bats beam.packages.erlangR25.elixir_1_14 docker-compose entr hivemind jq mix2nix nomad postgresql_14 graphviz python3 unixtools.netstat inotify-tools];

        shellHook = ''
        #set -x
        if [ -f $PWD/.env ]; then
            source .env
            mkdir -p .nix-mix .nix-hex
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-mix
            # make hex from Nixpkgs available
            # `mix local.hex` will install hex into MIX_HOME and should take precedence
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
            export LANG=C.UTF-8
            # keep your shell history in iex
            export ERL_AFLAGS="-kernel shell_history enabled"
            # Postgres environment variables
            export PGDATA=$PWD/postgres_data
            export PGHOST=$PWD/postgres
            export LOG_PATH=$PWD/postgres/LOG
            export PGDATABASE=postgres
            export DATABASE_URL="postgresql:///postgres?host=$PGHOST"
            if [ ! -d $PWD/postgres ]; then
            mkdir -p $PWD/postgres
            fi
            if [ ! -d $PGDATA ]; then
            echo 'Initializing postgresql database...'
            initdb $PGDATA --username $PGUSER -A md5 --pwfile=<(echo $PGPASS) --auth=trust >/dev/null
            echo "listen_addresses='*'" >> postgres_data/postgresql.conf
            echo "unix_socket_directories='$PWD/postgres'" >> postgres_data/postgresql.conf
            echo "unix_socket_permissions=0700" >> $PWD/postgres_data/postgresql.conf
            fi
            #psql -p 5435 postgres -c 'create extension if not exists postgis' || true
            # This creates mix variables and data folders within your project, so as not to pollute your system
            echo 'To run the services configured here, you can run the `hivemind` command'
            echo `${pkgs.beam.packages.erlangR25.elixir_1_14}/bin/mix --version`
            echo `${pkgs.beam.packages.erlangR25.elixir_1_14}/bin/iex --version`
        fi
      '';
    };  
  };
}
