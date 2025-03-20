{ lib, stdenv, fetchFromGitHub, makeWrapper, docker, docker-compose, writeShellScriptBin, buildEnv }:

let
  supabaseConfig = stdenv.mkDerivation rec {
    pname = "supabase-config";
    version = "1.25.02";

    src = fetchFromGitHub {
      owner = "supabase";
      repo = "supabase";
      rev = "${version}";  # Use actual git tag
      sha256 = "sha256-p+4t6a/pSxQ7sOyxajAV6sfzjWb02O4ROElTVsYIuAo="; # Replace with actual hash
    };

    installPhase = ''
      mkdir -p $out/share/supabase

      cp -r * $out/share/supabase/
    '';
  };

  exampleConfig = ./example.env;

  # Create scripts as before...
  initScript = writeShellScriptBin "supabase-init" ''
    #!/usr/bin/env bash
    set -e
    
    ENV_FILE=''${ENV_FILE:-${exampleConfig}}
    SUPABASE_LOCAL=''${SUPABASE_LOCAL:-$HOME/.local/share/supabase}

    mkdir -p $SUPABASE_LOCAL

    cd $SUPABASE_LOCAL
    
    sudo cp -rf ${supabaseConfig}/share/supabase/docker .

    cd ./docker

    sudo cp -f $ENV_FILE ./.env

    echo $PWD

    sudo ${docker-compose}/bin/docker-compose pull
  '';

  startScript = writeShellScriptBin "supabase-start" ''
    #!/usr/bin/env bash
    set -e
    
    SUPABASE_LOCAL=''${SUPABASE_LOCAL:-$HOME/.local/share/supabase}
 
    # Create data directories if needed

    cd $SUPABASE_LOCAL
    mkdir -p data
        
    # Use environment variables to override paths in docker-compose
    export POSTGRES_DATA_DIR=$SUPABASE_LOCAL/data/postgres
    export STORAGE_DATA_DIR=$SUPABASE_LOCAL/data/storage
    echo $PWD
    cd docker

    echo "Starting Supabase services..."
    sudo ${docker-compose}/bin/docker-compose up -d
    
    echo "Supabase is now running."
    echo "- Studio UI: http://localhost:8000"
  '';

  # Modified stop script that uses the store path
  stopScript = writeShellScriptBin "supabase-stop" ''
    #!/usr/bin/env bash
    SUPABASE_LOCAL=''${SUPABASE_LOCAL:-$HOME/.local/share/supabase}

    cd $SUPABASE_LOCAL/docker

    sudo ${docker-compose}/bin/docker-compose down
  '';


in 
  # Use buildEnv instead of manual linking
  buildEnv {
    name = "supabase";
    
    paths = [
      supabaseConfig
      initScript
      startScript
      stopScript
      docker
      docker-compose
    ];    
  }