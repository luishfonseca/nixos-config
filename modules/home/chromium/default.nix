# modules/home/chromium/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Chromium browser configuration.

{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;
    extensions = [
	  {	id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
    ];
  };

  xdg = {
  	desktopEntries.chromium-browser = {
	  name = "Chromium";
	  icon = "chromium";
	  genericName = "Web Browser";
	  exec = "chromium --force-dark-mode %U";
	  startupNotify = true;
	  categories = [ "Application" "Network" "WebBrowser" ];
	  mimeType = [
	    "text/html"
	    "text/xml"
	    "application/xhtml+xml"
	    "x-scheme-handler/http"
	    "x-scheme-handler/https"
	    "x-scheme-handler/about"
	  ];
	};
  };
}
