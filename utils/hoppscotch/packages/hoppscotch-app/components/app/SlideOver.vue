<template>
  <div>
    <transition v-if="show" name="fade" appear>
      <div class="inset-0 transition-opacity z-20 fixed" @keydown.esc="close()">
        <div
          class="bg-primaryLight opacity-90 inset-0 absolute"
          tabindex="0"
          @click="close()"
        ></div>
      </div>
    </transition>
    <aside
      class="
        bg-primary
        flex flex-col
        h-full
        max-w-full
        transform
        transition
        top-0
        ease-in-out
        right-0
        w-96
        z-30
        duration-300
        fixed
        overflow-auto
      "
      :class="show ? 'shadow-xl translate-x-0' : 'translate-x-full'"
    >
      <slot name="content"></slot>
    </aside>
  </div>
</template>

<script setup lang="ts">
import { onMounted, watch } from "@nuxtjs/composition-api"

const props = defineProps<{
  show: Boolean
}>()

const emit = defineEmits<{
  (e: "close"): void
}>()

watch(
  () => props.show,
  (show) => {
    if (process.client) {
      if (show) document.body.style.setProperty("overflow", "hidden")
      else document.body.style.removeProperty("overflow")
    }
  }
)

onMounted(() => {
  document.addEventListener("keydown", (e) => {
    if (e.keyCode === 27 && props.show) close()
  })
})

const close = () => {
  emit("close")
}
</script>
