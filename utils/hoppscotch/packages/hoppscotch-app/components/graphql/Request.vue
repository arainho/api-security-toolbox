<template>
  <div class="bg-primary flex p-4 top-0 z-10 sticky">
    <div class="space-x-2 flex-1 inline-flex">
      <input
        id="url"
        v-model="url"
        type="url"
        autocomplete="off"
        spellcheck="false"
        class="
          bg-primaryLight
          border border-divider
          rounded
          text-secondaryDark
          w-full
          py-2
          px-4
          hover:border-dividerDark
          focus-visible:bg-transparent focus-visible:border-dividerDark
        "
        :placeholder="$t('request.url')"
        :disabled="connected"
        @keyup.enter="onConnectClick"
      />
      <ButtonPrimary
        id="get"
        name="get"
        :label="!connected ? $t('action.connect') : $t('action.disconnect')"
        class="w-32"
        @click.native="onConnectClick"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { logHoppRequestRunToAnalytics } from "~/helpers/fb/analytics"
import { GQLConnection } from "~/helpers/GQLConnection"
import { getCurrentStrategyID } from "~/helpers/network"
import { useReadonlyStream, useStream } from "~/helpers/utils/composables"
import { gqlHeaders$, gqlURL$, setGQLURL } from "~/newstore/GQLSession"

const props = defineProps<{
  conn: GQLConnection
}>()

const connected = useReadonlyStream(props.conn.connected$, false)
const headers = useReadonlyStream(gqlHeaders$, [])

const url = useStream(gqlURL$, "", setGQLURL)

const onConnectClick = () => {
  if (!connected.value) {
    props.conn.connect(url.value, headers.value as any)

    logHoppRequestRunToAnalytics({
      platform: "graphql-schema",
      strategy: getCurrentStrategyID(),
    })
  } else {
    props.conn.disconnect()
  }
}
</script>
