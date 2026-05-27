{ ... }:
{
  den.aspects.saber.provides.matrix-bridges = {
    nixos = {
      services.mautrix-signal = {
        enable = true;
        registerToSynapse = true;
        settings = {
          homeserver = {
            address = "http://127.0.0.1:8008";
            domain = "matrix.1365972.xyz";
          };
          appservice.database = {
            type = "postgres";
            uri = "postgresql:///mautrixsignal?host=/run/postgresql";
          };
          bridge.permissions = {
            "matrix.1365972.xyz" = "user";
            "@paul:matrix.1365972.xyz" = "admin";
          };
        };
      };

      services.mautrix-whatsapp = {
        enable = true;
        registerToSynapse = true;
        settings = {
          homeserver = {
            address = "http://127.0.0.1:8008";
            domain = "matrix.1365972.xyz";
          };
          appservice.database = {
            type = "postgres";
            uri = "postgresql:///mautrixwhatsapp?host=/run/postgresql";
          };
          bridge.permissions = {
            "matrix.1365972.xyz" = "user";
            "@paul:matrix.1365972.xyz" = "admin";
          };
        };
      };
    };
  };
}
