<template>
  <div class="flex">
    <SmartItem
      svg="log-out"
      :label="`${$t('auth.logout')}`"
      :outline="outline"
      @click.native="
        () => {
          $emit('confirm-logout')
          confirmLogout = true
        }
      "
    />
    <SmartConfirmModal
      :show="confirmLogout"
      :title="`${$t('confirm.logout')}`"
      @hide-modal="confirmLogout = false"
      @resolve="logout"
    />
  </div>
</template>

<script lang="ts">
import { defineComponent } from "@nuxtjs/composition-api"
import { signOutUser } from "~/helpers/fb/auth"

export default defineComponent({
  props: {
    outline: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      confirmLogout: false,
    }
  },
  methods: {
    async logout() {
      try {
        await signOutUser()
        this.$toast.success(`${this.$t("auth.logged_out")}`, {
          icon: "vpn_key",
        })
      } catch (e) {
        console.error(e)
        this.$toast.error(`${this.$t("error.something_went_wrong")}`, {
          icon: "error_outline",
        })
      }
    },
  },
})
</script>
