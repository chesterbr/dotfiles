// Let Firefox read chrome/userChrome.css on startup.
// Required for the macOS-style window/tab theming in chrome/userChrome.css.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Stop a lone tap of Alt/Option from focusing/opening the menu bar (easy to hit
// by accident). Alt+letter accelerators and Alt+Tab still work; F10 still
// reveals the menu on purpose. Firefox-only — no Toshy/global remap involved.
user_pref("ui.key.menuAccessKeyFocuses", false);
