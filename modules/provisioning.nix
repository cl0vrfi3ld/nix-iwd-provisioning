# provisioning.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.iwd-provisioning;
  iwdConfigDir = "/var/lib/iwd";

in
{
  options = {
    iwd-provisioning = {
      enable = mkEnableOption "provision iwd files via nix";

      eduroam = mkOption {
        type = types.submodule {

          options = {
            enable = mkEnableOption "enable eduroam provisioning";
            phase1Identity = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "eduroamIDENTITY";
            };
            username = mkOption {
              type = types.str;
              # default = "";
              example = "cnolan123";
            };
            serverDomainMask = mkOption {
              type = types.str;
              default = "radius";
              example = "radius.node";
            };
            domain = mkOption {
              type = types.str;
              # default = "";
              example = "university.edu";
            };
            password = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "password123";
            };
            passwordHash = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "password123";
              description = "Preferred over `eduroam.password`. The hash can be generated via `printf '%s' 'REPLACE_WITH_YOUR_PASSWORD' | iconv -t utf16le | openssl md4 -provider legacy | cut -d' ' -f2`";
            };
            caCert = mkOption {
              type = types.nullOr types.path;
              default = null;
              example = "/var/lib/iwd/ca.pem";
              description = "(optional) path to your school's eduroam CA certificate";
            };
          };
        };
      };
    };
  };
  config =

    mkIf cfg.enable (mkMerge [
      {
        assertions = [
          {
            assertion = config.networking.wireless.iwd.enable == true;
            message = "iwd must be enabled before config files can be provisioned";
          }
        ];
      }
      (
        let
          edu = config.iwd-provisioning.eduroam;

          # TODO: embed cacert in cfg file
          eduroamFileName = "eduroam.8021x";
          eduroamProvisioningFile = pkgs.writeText eduroamFileName ''
            [Security]
            EAP-Method=PEAP
            ${lib.optionalString (
              edu.phase1Identity != null
            ) "EAP-Identity=${edu.phase1Identity}@${edu.domain}"}
            ${lib.optionalString (edu.caCert != null) "EAP-PEAP-CACert=${edu.caCert}"}
            ${lib.optionalString (
              edu.serverDomainMask != null
            ) "EAP-PEAP-ServerDomainMask=${edu.serverDomainMask}.${edu.domain}"}
            EAP-PEAP-Phase2-Method=MSCHAPV2
            EAP-PEAP-Phase2-Identity=${edu.username}@${edu.domain}
            ${lib.optionalString (!builtins.isNull edu.password) "EAP-PEAP-Phase2-Password=${edu.password}"}
            ${lib.optionalString (
              !builtins.isNull edu.passwordHash
            ) "EAP-PEAP-Phase2-Password-Hash=${edu.passwordHash}"}

            [Settings]
            Autoconnect=true
          '';
        in
        mkIf edu.enable {
          assertions = [
            {
              assertion = (!builtins.isNull edu.password) || (!builtins.isNull edu.passwordHash);
              message = "either a password or a password hash must be provided";
            }
          ];
          systemd.services.iwd-provisioning_eduroam = {
            description = "Ensure the presence of eduroam provisioning files before iwd starts up";
            # Dependencies: run before iwd, and require it
            before = [ "iwd.service" ];
            wantedBy = [ "iwd.service" ];
            # the service
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = ''
                /run/current-system/sw/bin/bash -c ' \
                  mkdir -p ${iwdConfigDir} && \
                  ln -s ${eduroamProvisioningFile} ${iwdConfigDir}/${eduroamFileName} \
                '
              '';

            };
          };
        }
      )
    ]);
}
