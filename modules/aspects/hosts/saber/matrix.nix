{ inputs, ... }:
{
  den.aspects.saber.provides.matrix = {
    nixos =
      { config, ... }:
      {
        services.matrix-synapse = {
          enable = true;
          # OIDC needs the `authlib` python extra; without it synapse crashes at import.
          extras = [ "oidc" ];

          settings = {
            # User IDs are @paul:matrix.1365972.xyz, not @paul:1365972.xyz; changing this invalidates every account and federated device.
            server_name = "matrix.1365972.xyz";
            public_baseurl = "https://matrix.1365972.xyz/";

            database = {
              name = "psycopg2";
              args = {
                user = "synapse";
                database = "synapse";
                host = "/run/postgresql";
              };
            };

            registration_requires_token = true;
            password_config.enabled = false;
            suppress_key_server_warning = true;
          };

          # registration_shared_secret / macaroon_secret_key / form_secret come from saber.yaml.
          # The OIDC provider is rendered via sops.templates so client_secret never lands in the nix store.
          extraConfigFiles = [
            config.sops.secrets.synapse-secrets.path
            config.sops.templates."synapse-oidc.yaml".path
          ];
        };

        sops.secrets.synapse-secrets = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          owner = "matrix-synapse";
          mode = "0440";
          restartUnits = [ "matrix-synapse.service" ];
        };

        # Read only via sops.placeholder during template rendering; root-only at rest is fine.
        sops.secrets.synapse-oidc-client-secret.sopsFile = inputs.self + "/secrets/saber.yaml";

        sops.templates."synapse-oidc.yaml" = {
          owner = "matrix-synapse";
          mode = "0440";
          restartUnits = [ "matrix-synapse.service" ];
          content = ''
            oidc_providers:
              - idp_id: authentik
                idp_name: Authentik
                discover: true
                issuer: https://authentik.1365972.xyz/application/o/matrix/
                client_id: 5fef00b73ddd11fdf37a32202ac525d76c7ee77c
                client_auth_method: client_secret_post
                client_secret: ${config.sops.placeholder.synapse-oidc-client-secret}
                scopes:
                  - openid
                  - profile
                  - email
                user_mapping_provider:
                  config:
                    localpart_template: "{{ user.preferred_username }}"
                    display_name_template: "{{ user.name }}"
                    email_template: "{{ user.email }}"
          '';
        };
      };
  };
}
