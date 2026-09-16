{
  den.aspects.hyprland-desktop.homeManager = {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      systemd.enable = false;
      configType = "lua";
      settings = {
        monitor = {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "auto";
        };
        config.ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
      };
      extraConfig = ''
        hl.bind("SUPER + Q", hl.dsp.exec_cmd("uwsm app -- kitty"))
        hl.bind("SUPER + R", hl.dsp.exec_cmd("uwsm app -- wofi --show drun"))
        hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- kitty yazi"))
        hl.bind("SUPER + C", hl.dsp.window.close())
        hl.bind("SUPER + M", hl.dsp.exec_cmd("uwsm stop"))
        hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
        hl.bind("SUPER + F", hl.dsp.window.fullscreen())
        hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
        hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region"))

        for _, direction in ipairs({ "left", "right", "up", "down" }) do
          hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
        end
        for workspace = 1, 10 do
          local key = workspace % 10
          hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
          hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
        end
        hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
        hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
      '';
    };
  };
}
