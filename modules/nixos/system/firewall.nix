{...}: {
  networking.firewall = {
    checkReversePath = "loose";

    allowedTCPPortRanges = [
      {
        from = 2000;
        to = 10000;
      }
    ];

    allowedUDPPortRanges = [
      {
        from = 2000;
        to = 10000;
      }
    ];
  };
}
