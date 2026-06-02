{ ... }:
{
  den.aspects.saber.provides.mosquitto = {
    nixos = {
      # Anonymous is safe only because the listener is bound to 127.0.0.1.
      services.mosquitto = {
        enable = true;
        listeners = [
          {
            address = "127.0.0.1";
            port = 1883;
            omitPasswordAuth = true;
            settings.allow_anonymous = true;
            acl = [ "topic readwrite #" ];
          }
        ];
      };
    };
  };
}
