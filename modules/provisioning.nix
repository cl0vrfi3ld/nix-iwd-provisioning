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
  eduroamFile = "eduroam.8021x";

in
{
  options = {
    iwd-provisioning = {
      enable = mkEnableOption "provision iwd files via nix";

      eduroam = mkOption {
        type = types.submodule {
          default = { };
          description = "settings for eduroam";
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
            };
            phase1Identity = {
              type = types.str;
              # default = "";
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
              type = types.str;
              # default = "";
              example = "password123";
            };
            passwordHash = mkOption {
              type = types.str;
              # default = "";
              example = "password123";
              description = "Preferred over `eduroam.password`. The hash can be generated via `printf '%s' 'REPLACE_WITH_YOUR_PASSWORD' | iconv -t utf16le | openssl md4 -provider legacy | cut -d' ' -f2`";
            };
            caCert = mkOption {
              type = types.path;
              # default = "";
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
      }
      (
        let
          edu = config.iwd-provisioning.eduroam;
          p1ID = edu.phase1Identity;
          domain = edu.domain;
          caCert = edu.caCert;
          domainMask = edu.serverDomainMask;
          uname = edu.username;
          psswd = edu.password;
          hash = edu.passwordHash;
          # TODO: embed cacert in cfg file
          eduroamProvisioningFile = pkgs.writeText eduroamFile ''
            [Security]
            EAP-Method=PEAP
            ${lib.optionalString (p1ID != null) "EAP-Identity=${p1ID}@${domain}"}
            ${lib.optionalString (caCert != null) "EAP-PEAP-CACert=${caCert}"}
            ${lib.optionalString (domainMask != null) "EAP-PEAP-ServerDomainMask=${domainMask}.${domain}"}
            EAP-PEAP-Phase2-Method=MSCHAPV2
            EAP-PEAP-Phase2-Identity=${uname}@${edu.domain}
            ${lib.optionalString (psswd != null) "EAP-PEAP-Phase2-Password=${psswd}"}
            ${lib.optionalString (hash != null) "EAP-PEAP-Phase2-Password-Hash=${hash}"}

            [Settings]
            Autoconnect=true
          '';
        in
        mkIf edu.enable {
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
    ]);
}
