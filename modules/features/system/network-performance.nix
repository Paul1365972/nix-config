{
  den.aspects.network-performance.nixos = {
    boot.kernelModules = [
      "tcp_bbr"
      "sch_cake"
    ];
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "cake";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };
}
