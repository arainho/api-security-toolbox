<template>
  <div class="flex p-4 space-y-4 items-start flex-col">
    <SmartToggle
      :on="PROXY_ENABLED"
      @change="toggleSettingKey('PROXY_ENABLED')"
    >
      {{ $t("settings.proxy") }}
    </SmartToggle>
    <SmartToggle
      :on="EXTENSIONS_ENABLED"
      @change="toggleSettingKey('EXTENSIONS_ENABLED')"
    >
      {{ $t("settings.extensions") }}:
      {{
        extensionVersion != null
          ? `v${extensionVersion.major}.${extensionVersion.minor}`
          : $t("settings.extension_ver_not_reported")
      }}
    </SmartToggle>
  </div>
</template>

<script setup lang="ts">
import { defineComponent } from "@nuxtjs/composition-api"
import { KeysMatching } from "~/types/ts-utils"
import { SettingsType, toggleSetting, useSetting } from "~/newstore/settings"
import { hasExtensionInstalled } from "~/helpers/strategies/ExtensionStrategy"

const PROXY_ENABLED = useSetting("PROXY_ENABLED")
const EXTENSIONS_ENABLED = useSetting("EXTENSIONS_ENABLED")

const toggleSettingKey = <K extends KeysMatching<SettingsType, boolean>>(
  key: K
) => {
  if (key === "EXTENSIONS_ENABLED" && PROXY_ENABLED.value) {
    toggleSetting("PROXY_ENABLED")
  }
  if (key === "PROXY_ENABLED" && EXTENSIONS_ENABLED.value) {
    toggleSetting("EXTENSIONS_ENABLED")
  }
  toggleSetting(key)
}
</script>

<script lang="ts">
export default defineComponent({
  data() {
    return {
      extensionVersion: hasExtensionInstalled()
        ? window.__POSTWOMAN_EXTENSION_HOOK__.getVersion()
        : null,
    }
  },
})
</script>
