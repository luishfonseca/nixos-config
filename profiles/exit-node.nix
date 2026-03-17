{
  services.tailscale = {
    extraUpFlags = ["--advertise-exit-node"];
    useRoutingFeatures = "server";
  };
}
