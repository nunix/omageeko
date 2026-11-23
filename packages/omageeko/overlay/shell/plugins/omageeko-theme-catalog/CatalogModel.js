// Pure helpers for ThemeCatalog.qml: labels, filtering, the rendered window
// and the thumbnail fetch order. No QML types, so they stay easy to reason about.

// The directory omarchy-theme-install clones a repo into.
function installedName(repo) {
  return String(repo || "").split("/").pop().replace(/\.git$/, "")
    .replace(/^omarchy-/, "").replace(/-theme$/, "").toLowerCase()
}

// 1234 -> 1.2k
function shortCount(n) {
  if (n >= 1000) return Math.floor(n / 1000) + "." + Math.floor(n % 1000 / 100) + "k"
  return String(n)
}

// YYYY-MM-DD -> 3d, 5w, 4mo, 2y
function age(date, now) {
  var then = Date.parse(date + "T00:00:00Z")
  if (isNaN(then)) return ""
  var days = Math.max(0, Math.floor((now - then) / 86400000))
  if (days < 14) return days + "d"
  if (days < 60) return Math.floor(days / 7) + "w"
  if (days < 365) return Math.floor(days / 30) + "mo"
  return Math.floor(days / 365) + "y"
}

function appsText(apps) {
  if (apps === 0) return "colors only"
  return apps === 1 ? "1 app" : apps + " apps"
}

// "Name · 12 apps · ★ 1.2k · ↻ 3w · installed" ("current" for the applied
// one): also what the filter searches.
function label(theme, installed, current, now) {
  var parts = [String(theme.name || "").replace(/\//g, " "), appsText(theme.apps)]
  if (theme.stars !== null && theme.stars !== undefined) parts.push("★ " + shortCount(theme.stars))
  if (theme.updated) parts.push("↻ " + age(theme.updated, now))
  if (current) parts.push("current")
  else if (installed) parts.push("installed")
  return parts.join(" · ")
}

function matchingIndices(labels, filterText) {
  var needle = String(filterText || "").toLowerCase()
  var out = []
  for (var i = 0; i < labels.length; i++) {
    if (!needle || labels[i].toLowerCase().indexOf(needle) !== -1) out.push(i)
  }
  return out
}

// Keep the rendered carousel independent of the size of the collection.
function visibleWindow(indices, selectedIndex, radius) {
  var position = indices.indexOf(selectedIndex)
  if (position < 0) position = 0
  var items = []
  for (var i = Math.max(0, position - radius); i < Math.min(indices.length, position + radius + 1); i++) {
    items.push({ themeIndex: indices[i], relativeIndex: i - position })
  }
  return items
}

// Preserve overlapping delegates as selection moves, including their decoded
// images. Replacing the entire model on every keypress makes previews flicker.
function syncWindow(model, items) {
  var wanted = {}
  for (var i = 0; i < items.length; i++) wanted[items[i].themeIndex] = true
  for (var i = model.count - 1; i >= 0; i--) {
    if (!wanted[model.get(i).themeIndex]) model.remove(i)
  }
  for (var i = 0; i < items.length; i++) {
    var existing = i
    while (existing < model.count && model.get(existing).themeIndex !== items[i].themeIndex) existing++
    if (existing === model.count) {
      model.insert(i, items[i])
    } else {
      if (existing !== i) model.move(existing, i, 1)
      model.setProperty(i, "relativeIndex", items[i].relativeIndex)
    }
  }
}

// Themes whose thumbnails to fetch, nearest the selection first: the
// selected one, then alternately the next and previous matches out to radius.
function fetchOrder(indices, selectedIndex, radius) {
  var position = indices.indexOf(selectedIndex)
  if (position < 0) return []
  var out = [indices[position]]
  for (var d = 1; d <= radius; d++) {
    if (position + d < indices.length) out.push(indices[position + d])
    if (position - d >= 0) out.push(indices[position - d])
  }
  return out
}
