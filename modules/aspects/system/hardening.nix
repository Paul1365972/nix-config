# Opt-in per host: BBR/CAKE can interact awkwardly with WSL and kiosks.
{ ... }:
{
  den.aspects.hardening.nixos = {
    boot.kernelModules = [
      "tcp_bbr"
      "sch_cake"
    ];
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "cake";
      "net.ipv4.tcp_congestion_control" = "bbr";

      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.log_martians" = 1;

      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.sysrq" = 0;
    };
  };
}
