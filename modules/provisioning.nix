# provisioning.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.networking.wireless.iwd.provisioning;
  iwdConfigDir = "/var/lib/iwd";
  eduroamFile = "eduroam.8021x";

in
{
  options.networking.wireless.iwd.provisioning = {
    enable = mkEnableOption "provision iwd files via nix";

    eduroam = mkOption {
      type = types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
          };
          phase1Identity = {
            type = types.str;
            example = "eduroamIDENTITY";
          };
          username = mkOption {
            type = types.str;
            example = "cnolan123";
          };
          serverDomainMask = mkOption {
            type = types.str;
            example = "radius.node";
          };
          domain = mkOption {
            type = types.str;
            example = "university.edu";
          };
          password = mkOption {
            type = types.str;
            example = "password123";
          };
          passwordHash = mkOption {
            type = types.str;
            example = "password123";
            description = "Preferred over `eduroam.password`. The hash can be generated via `printf '%s' 'REPLACE_WITH_YOUR_PASSWORD' | iconv -t utf16le | openssl md4 -provider legacy | cut -d' ' -f2`";
          };
          caCert = mkOption {
            type = types.path;
            example = "/var/lib/iwd/ca.pem";
            description = "(optional) path to your school's eduroam CA certificate";
          };
        };
      };
    };
  };
  config =

    mkIf cfg.enable (
      lib.mkMerge [
        {
        }
        (
          let
            edu = cfg.eduroam;
            # TODO: embed cacert in cfg file
            eduroamProvisioningFile = pkgs.writeText "${eduroamFile}" ''
              [Security]
              EAP-Method=PEAP
              ${lib.optionalString (edu.phase1Identity != null) "EAP-Identity=${edu.phase1Identity}@${edu.domain}"}
              ${lib.optionalString (edu.caCert != null) "EAP-PEAP-CACert=${edu.caCert}"}
              ${lib.optionalString (edu.serverDomainMask != null) "EAP-PEAP-ServerDomainMask=${edu.serverDomainMask}.${edu.domain}"}
              EAP-PEAP-Phase2-Method=MSCHAPV2
              EAP-PEAP-Phase2-Identity=${edu.username}@${edu.domain}
              ${lib.optionalString (edu.password != null) "EAP-PEAP-Phase2-Password=${edu.password}"}
              ${lib.optionalString (edu.passwordHash!= null) "EAP-PEAP-Phase2-Password-Hash=${edu.passwordHash}"}

              [Settings]
              Autoconnect=true
            '';
          in
          mkIf cfg.eduroam.enable {
            systemd.services.iwd-provisioning_eduroam = {
              description = "Ensure the presence of eduroam provisioning files before iwd starts up";
              # Dependencies: run before iwd, and require it
              # before = [ "iwd.service" ];
              # wantedBy = [ "iwd.service" ];
              # the service
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = ''
                  /run/current-system/sw/bin/bash -c ' \
                    mkdir -p ${iwdConfigDir} && \
                    cp ${eduroamProvisioningFile} ${iwdConfigDir}
                '';

              };
            };
          }
        )
      ]
    );
}
