{ modulesPath, nixboot, ... }: {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  # To show boot messages from initrd with the mainline kernel:
  boot.initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];

  # Host a netboot server.
  services.pixiecore = {
    enable = true;
    mode = "boot";
    debug = true;
    openFirewall = true;
    initrd = toString nixboot.packages.x86_64-linux.initrd;
    kernel = toString nixboot.packages.x86_64-linux.kernel;
  };

  # Enable login from workstation.
  services.openssh.enable = true;

  # Allow sudo without password, if the user is using an authorized ssh key.
  security.sudo.enable = true;
  security.pam.enableSSHAgentAuth = true;

  # User management.
  users.users.pi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ ./ssh.pub ];
  };
}
