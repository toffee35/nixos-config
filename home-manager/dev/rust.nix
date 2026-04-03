{
  pkgs,
  username,
  ...
}: {
  home = {
    packages = with pkgs; [
      rustc
      cargo

      rust-analyzer
      clippy

      rustfmt
      maturin

      jetbrains.rust-rover
    ];

    sessionVariables = {
      RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    };
  };

  programs.vscode.profiles.${username}.extensions = with pkgs.vscode-extensions; [
    rust-lang.rust-analyzer
    tamasfe.even-better-toml
    vadimcn.vscode-lldb
    serayuzgur.crates
  ];
}
