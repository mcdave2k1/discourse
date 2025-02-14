import { getSetting as getThemeSetting } from "discourse/lib/theme-settings-store";
import { registerUnbound } from "discourse-common/lib/helpers";
import I18n from "discourse-i18n";

registerUnbound("theme-i18n", (themeId, key, params) => {
  return I18n.t(`theme_translations.${themeId}.${key}`, params);
});

registerUnbound(
  "theme-prefix",
  (themeId, key) => `theme_translations.${themeId}.${key}`
);

registerUnbound("theme-setting", (themeId, key) => {
  return getThemeSetting(themeId, key);
});
