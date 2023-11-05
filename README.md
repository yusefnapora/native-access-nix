# native-access-nix

> A nix flake to install VSTs and content made by [Native Instruments](https://native-instruments.com) on linux using wine.

## About

Native Instruments makes some great software instruments, but they only officially support macOS and Windows.

Luckily, most of their stuff runs great using wine and an awesome tool called [yabridge](https://github.com/robbert-vdh/yabridge),
but you need their special installer program called Native Access in order to activate things so they'll actually run.

The current version of Native Access is based on electron and doesn't run via wine, but they make the "legacy" installer available for older operating systems, and it does run with wine, provided you can sweet-talk the wine config just right.

This repo contains a [nix flake](https://nixos.wiki/wiki/Flakes) to make Native Access easily installable on NixOS. It should hopefully work on other distros with nix installed, but I haven't tested it. If you try it, let me know with an issue or something and I'll update the readme.

## Prerequisites

- An x86_64 linux machine with nix that's been configured to use flakes.
- The `udisks2` service and `udisksctl` command, for mounting ISO images. 
  - On NixOS, set `services.udisks2.enable = true;` in your config.
  - Other distros will likely have this installed by default.

## Installation

### Installing with `nix profile install`

With a flake-enabled nix, you can install `native-access` to your user profile with:

```bash
nix profile install github:yusefnapora/native-access-nix
```

### As an input to a NixOS system flake

If you manage your NixOS system with flakes, you can take this flake as an input by adding it to your `flake.nix`:


```nix
{
  inputs.native-access-nix = {
    url = "github:yusefnapora/native-access-nix";

    # The following line is optional, but will use less disk space,
    # since it uses your existing nixpkgs input. If you use this and
    # native-access doesn't work, try removing it - there's a chance
    # that your current version of nixpkgs has an incompatible version
    # of wine.
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, native-access-nix, ...}@inputs: {
    # The details here depend on how you configure your nixos systems.
    # In my config, I pass the `inputs` field into the `specialArgs`
    # field of `nixpkgs.lib.nixosSystem`, which makes it available to
    # the modules that define the system.

    # here's a minimal example:
    nixosConfigurations = { 
      your-hostname = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          # should point to a nixos module that defines your system config
          ./configuration.nix
        ];
      };
    };
  }
}
```

The example above assumes that you have a file called `configuration.nix` that sets up your system.

In your nixos config, add this to install the `native-access` command:

```nix
{ pkgs, inputs, ... }:
{
  environment.systemPackages = [ 
    inputs.native-access-nix.packages.x86_64-linux.native-access
  ];

  # make sure to enable the udisks2 service, so you can use the ISO install script:
  services.udisks2.enable = true;

  # add the rest of your config...
}
```

## Usage

Once installed, you should have a `native-access` command in your `$PATH`, and a desktop entry that will launch Native Access using your window manager's launcher.

I recommend using the `native-access` command from a terminal on the first run, since it does a bunch of setup on the first run that could potentially fail, and it's nice to have the console output visible if that happens. You should expect to see a bunch of output from wine, and eventually you should see some lines like this:

```
----------------------------
| Installing Native Access |
----------------------------
```

Then yet more wine debug cruft while the Native Access installer runs, followed by:

```
-------------------------
| Installation complete |
-------------------------
```

After a bit more wine debug info, the app should launch and ask you to log in to your Native Access account.

### Installing plugins

Some things (especially large content libraries) will fail to install and show a message about being unable to mount an ISO image.

To work around this, the flake also includes a script called `ni-plugin-install`, which will mount ISO images, find the first `.exe` file inside, and run it with wine. The script supports both `.zip` files and `.iso` files, although zip files should work directly via Native Access, so you'll probably only need it for ISOs.

When Native Access fails to install a plugin, run `ni-plugin-install`. 

Assuming you're using the default Native Access download location, it should show you a list of files and ask you to select one. If you changed the download location, you can set the `NI_DOWNLOADS_DIR` environment variable to the location you set before running the script, or you can pass the script the path to the ISO file as its first argument, which will prevent the script from prompting you to choose a file altogether.

Once the file is chosen, the script will try to mount the ISO and run the installer with wine, unmounting the ISO when the install completes. Once the install is finished, re-launch Native Access to complete the registration. You should see a success message popup and the new plugin should be in the "installed" section of the app.

## Using `yabridge` to load plugins into your linux DAW

This flake creates a wine prefix at `~/.wine-nix/native-access`, and the default VST install location for 64-bit plugins is `"~/.wine-nix/native-access/drive_c/Program Files/Native Instruments/VSTPlugins 64 bit"`. To setup yabridge, run:

```bash
yabridgectl add "~/.wine-nix/native-access/drive_c/Program Files/Native Instruments/VSTPlugins 64 bit"
```

Whenever you add new plugins, run `yabridge sync` to make them visible to your Linux DAWs.

See the [yabridge readme](https://github.com/robbert-vdh/yabridge) for more usage info.

