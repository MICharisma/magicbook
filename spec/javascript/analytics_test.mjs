import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import test from "node:test"
import vm from "node:vm"

async function harness({ readyState = undefined, drive = true, withUmami = true } = {}) {
  const events = []
  const umamiEvents = []
  const listeners = new Map()
  const timers = new Map()
  const storage = new Map()
  let now = 0
  let nextTimer = 0
  const metadata = { page_type: "tags.index", path: "/tags", signed_in: false, enabled: true }
  const root = {
    readyState,
    visibilityState: "visible",
    focused: true,
    hasFocus() { return this.focused },
    querySelector(selector) {
      if (selector.includes("app-analytics")) return { content: JSON.stringify(metadata) }
      return null
    },
    addEventListener(name, callback) { listeners.set(name, callback) }
  }

  const context = vm.createContext({
    URL,
    queueMicrotask,
    document: root,
    window: {
      Turbo: { session: { drive } },
      location: { origin: "https://wayswemage.com", hostname: "wayswemage.com", href: "https://wayswemage.com/tags" },
      addEventListener() {},
      umami: withUmami ? { track: (name, payload) => umamiEvents.push({ name, payload }) } : undefined
    },
    sessionStorage: { getItem: key => storage.get(key), setItem: (key, value) => storage.set(key, value) },
    performance: { now: () => now },
    setTimeout: (callback, delay) => { timers.set(++nextTimer, { callback, at: now + delay }); return nextTimer },
    clearTimeout: id => timers.delete(id),
    ahoy: { configure() {}, track: (name, properties) => events.push({ name, properties }) }
  })

  const source = await readFile(new URL("../../app/javascript/analytics.js", import.meta.url), "utf8")
  const module = new vm.SourceTextModule(source, { context })
  await module.link(() => new vm.SyntheticModule([], () => {}, { context }))
  await module.evaluate()

  function advance(milliseconds) {
    const target = now + milliseconds
    while (true) {
      const next = [...timers].sort((a, b) => a[1].at - b[1].at)[0]
      if (!next || next[1].at > target) break
      now = next[1].at
      timers.delete(next[0])
      next[1].callback()
    }
    now = target
  }

  return { events, umamiEvents, root, metadata, listeners, advance, analytics: module.namespace }
}

test("boots once when Turbo Drive is disabled and avoids duplicate initial page_viewed", async () => {
  const app = await harness({ readyState: "complete", drive: false })
  await new Promise(resolve => setTimeout(resolve, 0))
  assert.equal(app.events.filter(event => event.name === "page_viewed").length, 1)

  const turboFirst = await harness({ readyState: "loading", drive: false })
  turboFirst.listeners.get("turbo:load")()
  turboFirst.listeners.get("DOMContentLoaded")()
  await new Promise(resolve => setTimeout(resolve, 0))
  assert.equal(turboFirst.events.filter(event => event.name === "page_viewed").length, 1)
})

test("engagement, cleanPath token scrubbing, and Umami custom events work without duplicating page_viewed", async () => {
  const app = await harness()
  assert.equal(app.analytics.cleanPath("/magic-link/secret-token?x=1"), "/magic-link/:token")

  app.analytics.pageAnalytics.start()
  app.analytics.track("tag_panel_opened")
  app.advance(20000)

  assert.equal(app.events.filter(event => event.name === "page_engaged").length, 1)
  assert.equal(app.umamiEvents.some(event => event.name === "tag_panel_opened"), true)
  assert.equal(app.umamiEvents.some(event => event.name === "page_viewed"), false)
})

test("opt-out disables events and missing window.umami is safe", async () => {
  const noUmami = await harness({ withUmami: false })
  noUmami.analytics.pageAnalytics.start()
  noUmami.analytics.track("card_role_assigned", { role_id: "1" })
  assert.equal(noUmami.events.some(event => event.name === "card_role_assigned"), true)

  const optedOut = await harness()
  optedOut.metadata.enabled = false
  optedOut.analytics.pageAnalytics.start()
  optedOut.analytics.track("tag_panel_opened")
  optedOut.advance(30000)
  assert.equal(optedOut.events.length, 0)
  assert.equal(optedOut.umamiEvents.length, 0)
})
