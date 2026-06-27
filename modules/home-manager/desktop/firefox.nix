{
  pkgs,
  username,
  ...
}: let
  buildFirefoxXpiAddon = {
    pname,
    version,
    addonId,
    url,
    sha256,
  }:
    pkgs.stdenv.mkDerivation {
      name = "${pname}-${version}";

      src = pkgs.fetchurl {inherit url sha256;};

      preferLocalBuild = true;
      allowSubstitutes = true;

      passthru = {inherit addonId;};

      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    };
in {
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";

    profiles.${username} = {
      id = 0;
      isDefault = true;

      settings = {
        extensions.autoDisableScopes = 0;
        extensions.activeThemeID = "firefox-compact-dark@mozilla.org";
        browser.search.suggest.enabled = true;
        browser.urlbar.suggest.searches = true;
        browser.urlbar.showSearchSuggestionsFirst = false;
        browser.toolbars.bookmarks.visibility = "always";
      };

      bookmarks = {
        force = true;

        settings = [
          {
            name = "Toolbar";
            toolbar = true;
            bookmarks = [
              {
                name = "Translate";
                url = "https://translate.google.com/?sl=en&tl=ru&op=translate";
              }
              {
                name = "Chat GPT";
                url = "https://chatgpt.com";
              }
              {
                name = "Deepseek";
                url = "https://chat.deepseek.com";
              }
              {
                name = "Claude Ai";
                url = "https://claude.ai/new";
              }
              {
                name = "Google Ai";
                url = "https://aistudio.google.com/prompts/new_chat";
              }
              {
                name = "Gemini";
                url = "https://gemini.google.com/app";
              }
              {
                name = "YouTube";
                url = "https://www.youtube.com";
              }
              {
                name = "GitHub";
                url = "https://github.com";
              }
            ];
          }
        ];
      };

      extensions = {
        force = true;

        packages =
          (with pkgs.nur.repos.rycee.firefox-addons; [
            darkreader
            sponsorblock
            ublock-origin
            adaptive-tab-bar-colour
            translate-web-pages
            privacy-badger
            auto-tab-discard
            vimium-c
            stylus
          ])
          ++ [
            (buildFirefoxXpiAddon (let
              version = "0.2.5";
            in {
              pname = "youtube_repeat_button";
              inherit version;

              addonId = "{28c18e92-ab27-403f-973d-49d1d0fa7665}";

              url = "https://addons.mozilla.org/firefox/downloads/file/4324915/youtube_repeat_button-${version}.xpi";
              sha256 = "sha256-IkItSOv16Lazo/XAZehrs1KI9PtUH2hUdQpBuLxnW4g=";
            }))

            (buildFirefoxXpiAddon (let
              version = "1.5";
            in {
              pname = "adless_spotify";
              inherit version;

              addonId = "{62e31096-34e6-4503-8806-3d7a6004a1f4}";

              url = "https://addons.mozilla.org/firefox/downloads/file/4098050/adless_spotify-${version}.xpi";
              sha256 = "sha256-U+bQndQkg0NDIfRmSAwu3rbD6Cx+GrC/I43uPs+CMRQ=";
            }))
          ];
      };

      search = {
        force = true;

        default = "google";
        privateDefault = "google";

        order = [
          "MyNix Options"
          "HomeM Options"
          "Nix Options"
          "Nix Packages"
          "google"
          "yandex"
          "wikipedia"
          "Docker Img"
        ];

        engines = {
          "google".definedAliases = ["@g"];

          "wikipedia".definedAliases = ["@wk"];

          "yandex" = {
            definedAliases = ["@y"];
            urls = [
              {
                template = "https://yandex.ru/search?text={searchTerms}";
              }
            ];
          };

          "Nix Packages" = {
            definedAliases = ["@np"];
            urls = [
              {
                template = "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&query={searchTerms}";
              }
            ];
          };

          "Nix Options" = {
            definedAliases = ["@no"];
            urls = [
              {
                template = "https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&query={searchTerms}";
              }
            ];
          };

          "Home-Manager Options" = {
            definedAliases = ["@hmo"];
            urls = [
              {
                template = "https://home-manager-options.extranix.com/?query={searchTerms}&release=master";
              }
            ];
          };

          "MyNix Options" = {
            definedAliases = ["@nxo"];
            urls = [
              {
                template = "https://mynixos.com/search?q={searchTerms}";
              }
            ];
          };

          "Docker Img" = {
            definedAliases = ["@dckr"];
            urls = [
              {
                template = "https://hub.docker.com/search?q={searchTerms}";
              }
            ];
          };

          bing.metaData.hidden = true;
          ddg.metaData.hidden = true;
        };
      };
    };
  };

  home.sessionVariables.BROWSER = "firefox";
}
