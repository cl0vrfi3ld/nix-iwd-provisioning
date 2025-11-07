# provisioning.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.iwd-eduroam;
  iwdConfigDir = "/var/lib/iwd";
in
{
  options = {
    iwd-eduroam = {
      enable = mkEnableOption "provision iwd for eduroam files via nix";
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
    config = (
      mkMerge [
        { }
        (
          let
            p1ID = cfg.phase1Identity;
            domain = cfg.domain;
            caCert = cfg.caCert;
            domainMask = cfg.serverDomainMask;
            uname = cfg.username;
            psswd = cfg.password;
            hash = cfg.passwordHash;
            # TODO: embed cacert in cfg file
            eduroamFile = "eduroam.8021x";
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
          mkIf cfg.enable {
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
  };
}
