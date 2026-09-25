{
  config,
  node,
  ...
}:
{
  config = {
    mailserver = {
      enable = true;
      fqdn = "mail.friikod.se";
      domains = [ "friikod.se" ];

      # A list of all login accounts. To create the password hashes, use
      # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
      accounts = {
        "linus@friikod.se" = {
          hashedPasswordFile = config.age.secrets.linusPass.path;
        };
        "carolin@friikod.se" = {
          hashedPasswordFile = config.age.secrets.carroPass.path;
        };
        "handyman@friikod.se" = {
          hashedPasswordFile = config.age.secrets.handymanPass.path;
        };
      };

      x509.useACMEHost = config.mailserver.fqdn;

      stateVersion = 5;
    };

    services.nginx = {
      enable = true;
      virtualHosts.${config.mailserver.fqdn} = {
        enableACME = true;
        forceSSL = true;
      };
    };

    age.secrets.linusPass = {
      rekeyFile = ../secrets/linus_mail_pass.age;
      generator.script = "passphrase";
    };
    age.secrets.carroPass = {
      rekeyFile = ../secrets/carro_mail_pass.age;
      generator.script = "passphrase";
    };
    age.secrets.handymanPass = {
      rekeyFile = ../secrets/handyman_mail_pass.age;
      generator.script = "passphrase";
    };
  };
}
