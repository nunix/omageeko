import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "CatalogModel.js" as Model

// omageeko: the omarchy.org community themes in the image picker's skewed
// carousel, with the selected theme's backgrounds as thumbnails below it.
//
// Opening is instant: the index (omarchy-theme-catalog's JSON) stays parsed in
// this keepLoaded plugin, and a stale one is rebuilt behind the open overlay.
// Background thumbnails are cached on disk by git blob id; the ones missing are
// fetched for the selected theme first, then for its neighbours outwards, so
// moving through the carousel mostly lands on thumbnails already there.
Item {
  id: root

  // Injected by omarchy-shell; defaults to the session OMARCHY_PATH.
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  readonly property string home: Quickshell.env("HOME")
  readonly property string cachePath: (Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")) + "/omageeko/theme-catalog"
  readonly property string thumbDir: cachePath + "/thumbs"
  readonly property string previewDir: cachePath + "/previews"
  readonly property string catalogCommand: omarchyPath + "/bin/omarchy-theme-catalog"

  property bool opened: false
  // Down moves the keyboard into the backgrounds row, Up back to the themes.
  property bool inBackgrounds: false
  property int bgIndex: 0
  // Back in the themes row the strip returns to its start, where "+N" counts.
  onInBackgroundsChanged: if (!inBackgrounds) bgIndex = 0
  property var themes: []
  // owner/name (lower case) -> the directory it is cloned into, from
  // omarchy-theme-catalog --installed.
  property var installed: ({})
  // The applied theme's directory name (omarchy-theme-set writes it).
  property string currentThemeName: ""
  onCurrentThemeNameChanged: relabel()
  // Uninstalling: the theme waiting on the confirmation, and a one-line note
  // in the hint row (why a theme can't be removed, or that it was).
  property var pendingRemove: null
  property bool removeConfirmOpen: false
  property string notice: ""
  property var labels: []
  property int selectedIndex: 0
  property string filterText: ""
  // oid -> true once its thumbnail is on disk. Reassigned to notify bindings.
  property var thumbsReady: ({})
  property bool thumbsScanned: false
  property bool building: false
  property bool buildFailed: false
  property bool revealed: false
  // Previews stay decoded for a minute after closing, so a quick reopen shows
  // at once; then they are released instead of held for the shell's lifetime.
  property bool holdPreviews: false

  property color dimColor: Commons.Color.background
  property color foreground: Commons.Color.imagePicker.text
  property color selectedBorder: Commons.Color.imagePicker.selectedBorder
  property color unselectedBorder: Commons.Color.imagePicker.unselectedBorder

  // The glass pane takes the selected theme's own palette (its colors.toml,
  // or alacritty.toml for older themes), so each theme is read on its colors.
  // A theme without one falls back to the current Omarchy theme.
  function themeColor(key, fallback) {
    var value = currentTheme && currentTheme.colors ? String(currentTheme.colors[key] || "") : ""
    return /^#[0-9a-fA-F]{6}$/.test(value) ? value : fallback
  }
  property color glassTint: themeColor("background", dimColor)
  property color glassText: themeColor("foreground", foreground)
  property color glassAccent: themeColor("accent", themeColor("foreground", selectedBorder))
  Behavior on glassTint { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on glassText { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on glassAccent { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }

  property int expandedWidth: 768
  property int expandedHeight: 432
  property int sliceWidth: 108
  property int sliceHeight: 400
  property int sliceSpacing: -30
  property int skewOffset: 28
  property int thumbWidth: 176
  property int thumbHeight: 99
  property int thumbSpacing: 10
  property int thumbSkew: 12
  property int fetchRadius: 4
  // The glass pane is the same size for every theme: room for this many
  // backgrounds (fewer on a narrow screen) and two lines of apps.
  property int stripSlots: 6

  readonly property int previewRadius: Math.max(1, Math.min(16, Math.ceil((panel.width - expandedWidth) / (2 * (sliceWidth + sliceSpacing))) + 1))
  readonly property var matching: Model.matchingIndices(labels, filterText)
  readonly property var currentTheme: matching.indexOf(selectedIndex) !== -1 ? themes[selectedIndex] : null
  readonly property var currentBgs: currentTheme ? (currentTheme.bgs || []) : []
  readonly property int maxThumbs: Math.max(1, Math.min(stripSlots, Math.floor((panel.width - 80 - Style.space(56) + thumbSpacing) / (thumbWidth + thumbSpacing))))

  onPreviewRadiusChanged: updateVisibleItems()
  onMatchingChanged: {
    if (matching.length > 0 && matching.indexOf(selectedIndex) === -1) selectedIndex = matching[0]
    updateVisibleItems()
    queueThumbs()
  }
  onSelectedIndexChanged: {
    notice = ""
    inBackgrounds = false
    bgIndex = 0
    updateVisibleItems()
    queueThumbs()
  }
  onOpenedChanged: {
    if (opened) {
      holdTimer.stop()
      holdPreviews = true
    } else {
      revealed = false
      inBackgrounds = false
      removeConfirmOpen = false
      pendingRemove = null
      notice = ""
      holdTimer.restart()
    }
  }

  Timer {
    id: holdTimer
    interval: 60000
    onTriggered: root.holdPreviews = false
  }

  // ---------------------------------------------------------------- data

  // Cloned from this very repo: a same-named directory the user wrote is not it.
  function isInstalled(theme) {
    return !!theme && installed[String(theme.repo).toLowerCase()] === Model.installedName(theme.repo)
  }

  // The installed theme that is applied right now.
  function isCurrent(theme) {
    return isInstalled(theme) && currentThemeName === Model.installedName(theme.repo)
  }

  function relabel() {
    var now = Date.now()
    var next = []
    for (var i = 0; i < themes.length; i++)
      next.push(Model.label(themes[i], isInstalled(themes[i]), isCurrent(themes[i]), now))
    labels = next
  }

  function loadIndex(text) {
    var parsed
    try { parsed = JSON.parse(text) } catch (e) { return }
    if (!parsed || !Array.isArray(parsed.themes)) return

    // Keep the user's place across a rebuild.
    var currentRepo = currentTheme ? currentTheme.repo : ""
    themes = parsed.themes
    relabel()
    var index = 0
    for (var i = 0; currentRepo && i < themes.length; i++) {
      if (themes[i].repo === currentRepo) { index = i; break }
    }
    selectedIndex = index
    updateVisibleItems()
    queueThumbs()
  }

  FileView {
    id: currentThemeFile
    path: root.home + "/.local/state/omarchy/current/theme.name"
    blockLoading: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.currentThemeName = String(text() || "").trim()
  }

  FileView {
    id: indexFile
    path: root.cachePath + "/index.v4.json"
    blockLoading: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.loadIndex(text())
  }

  Process {
    id: buildProc
    command: [root.catalogCommand, "--build"]
    onExited: function(exitCode) {
      root.building = false
      root.buildFailed = exitCode !== 0 && root.themes.length === 0
      // The index is replaced by a rename, which a file watch can miss.
      indexFile.reload()
    }
  }

  Process {
    id: installedProc
    command: [root.catalogCommand, "--installed"]
    stdout: StdioCollector {
      onStreamFinished: {
        var set = {}
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var fields = lines[i].split("\t")
          if (fields.length === 2) set[fields[0]] = fields[1]
        }
        root.installed = set
        root.relabel()
      }
    }
  }

  Process {
    id: thumbScanProc
    command: ["find", root.thumbDir, "-maxdepth", "1", "-name", "*.jpg", "-size", "+0", "-printf", "%f\n"]
    stdout: StdioCollector {
      onStreamFinished: {
        var set = {}
        var names = String(text || "").split("\n")
        for (var i = 0; i < names.length; i++) if (names[i]) set[names[i].replace(/\.jpg$/, "")] = true
        // Merge: workers may have reported thumbnails while the scan ran.
        for (var oid in root.thumbsReady) set[oid] = true
        root.thumbsReady = set
        root.thumbsScanned = true
        root.queueThumbs()
      }
    }
  }

  // ---------------------------------------------------------- thumbnails

  property var fetchQueue: []
  property var inFlight: ({})
  property var failedThemes: ({})

  function markReady(oid) {
    if (!/^[0-9a-f]{40}$/.test(oid) || thumbsReady[oid]) return
    var next = {}
    for (var k in thumbsReady) next[k] = true
    next[oid] = true
    thumbsReady = next
  }

  // What the strip can show without scrolling, or every background of the
  // theme whose backgrounds row is being browsed.
  function thumbLimit(theme) {
    var bgs = theme.bgs || []
    return inBackgrounds && currentTheme && theme.repo === currentTheme.repo ? bgs.length : Math.min(bgs.length, maxThumbs)
  }

  function themeNeedsThumbs(index) {
    var theme = themes[index]
    if (!theme || inFlight[theme.repo] || failedThemes[theme.repo]) return false
    var bgs = theme.bgs || []
    for (var i = 0; i < thumbLimit(theme); i++)
      if (!thumbsReady[bgs[i].oid]) return true
    return false
  }

  // Debounced: holding an arrow key only fetches where the user stops.
  function queueThumbs() {
    if (opened && thumbsScanned) queueTimer.restart()
  }

  Timer {
    id: queueTimer
    interval: 90
    onTriggered: {
      root.fetchQueue = Model.fetchOrder(root.matching, root.selectedIndex, root.fetchRadius)
      root.pumpThumbs()
    }
  }

  function pumpThumbs() {
    for (var w = 0; w < workers.count; w++) {
      var worker = workers.itemAt(w)
      if (!worker || worker.running) continue
      while (fetchQueue.length > 0) {
        var index = fetchQueue.shift()
        if (!themeNeedsThumbs(index)) continue
        worker.fetch(themes[index])
        break
      }
    }
  }

  Repeater {
    id: workers
    model: 3

    delegate: Item {
      id: worker
      readonly property bool running: proc.running
      property string repo: ""
      property var oids: []

      function fetch(theme) {
        var args = [root.catalogCommand, "--thumbs", theme.repo]
        var bgs = theme.bgs || []
        var wanted = []
        // Only what the strip shows; the rest come once the row is browsed.
        for (var i = 0; i < root.thumbLimit(theme); i++) {
          if (root.thumbsReady[bgs[i].oid]) continue
          args.push(bgs[i].path + ":" + bgs[i].oid)
          wanted.push(bgs[i].oid)
        }
        oids = wanted
        repo = theme.repo
        var flight = {}
        for (var k in root.inFlight) flight[k] = true
        flight[repo] = true
        root.inFlight = flight
        proc.command = args
        proc.running = true
      }

      Process {
        id: proc
        stdout: SplitParser {
          onRead: function(line) { root.markReady(String(line).trim()) }
        }
        onExited: function(exitCode) {
          var flight = {}
          for (var k in root.inFlight) if (k !== worker.repo) flight[k] = true
          root.inFlight = flight
          // Don't retry a theme whose downloads failed until the next open.
          // Only what this run asked for counts: browsing its backgrounds
          // meanwhile may already want more.
          var missing = false
          for (var o = 0; o < worker.oids.length; o++) if (!root.thumbsReady[worker.oids[o]]) missing = true
          if (exitCode !== 0 || missing) {
            var failed = {}
            for (var f in root.failedThemes) failed[f] = true
            failed[worker.repo] = true
            root.failedThemes = failed
          }
          worker.repo = ""
          root.pumpThumbs()
        }
      }
    }
  }

  function indexOfRepo(repo) {
    for (var i = 0; i < themes.length; i++) if (themes[i].repo === repo) return i
    return -1
  }

  // ----------------------------------------------------------- selection

  ListModel { id: visibleThemes }

  function updateVisibleItems() {
    Model.syncWindow(visibleThemes, Model.visibleWindow(matching, selectedIndex, previewRadius))
  }

  function selectAdjacent(direction) {
    var position = matching.indexOf(selectedIndex)
    if (matching.length === 0) return
    if (position < 0) position = 0
    selectedIndex = matching[(position + direction + matching.length) % matching.length]
  }

  function enterBackgrounds() {
    if (inBackgrounds || currentBgs.length === 0) return
    inBackgrounds = true
    queueThumbs()
  }

  function selectBackground(direction) {
    var count = currentBgs.length
    if (count > 0) bgIndex = (bgIndex + direction + count) % count
  }

  // From the backgrounds row, the highlighted background is set once the
  // theme is in. The terminal launcher joins its arguments into one shell
  // string, so the background goes by its blob id, never by its path.
  // A theme already on disk is only applied: no clone, so no terminal either.
  function install() {
    var theme = currentTheme
    if (!theme) return
    var args = ["omarchy-theme-catalog", "--install", theme.repo]
    if (inBackgrounds && currentBgs[bgIndex]) args.push(currentBgs[bgIndex].oid)
    if (isInstalled(theme)) args[0] = catalogCommand
    else args.unshift("omarchy-launch-floating-terminal-with-presentation")
    opened = false
    filterText = ""
    Util.execArgv(args)
  }

  // Delete (or Backspace with no filter) on an installed theme asks first;
  // the applied theme stays, as removing it would pull it out from under
  // the desktop. The catalog stays open on the same theme either way.
  function requestRemove() {
    var theme = currentTheme
    if (!theme || removeProc.running) return
    if (!isInstalled(theme)) { notice = "Not installed: nothing to uninstall"; return }
    if (isCurrent(theme)) { notice = "This is the current theme: switch to another one before uninstalling it"; return }
    pendingRemove = theme
    removeConfirm.selectedIndex = 0
    removeConfirmOpen = true
  }

  function cancelRemove() {
    removeConfirmOpen = false
    pendingRemove = null
  }

  // omarchy-theme-remove does the removal (its guards and notification); the
  // catalog only rereads what is installed, which turns the badge to a cloud.
  function confirmRemove() {
    var theme = pendingRemove
    cancelRemove()
    if (!theme || !isInstalled(theme) || removeProc.running) return
    removeProc.themeName = installed[String(theme.repo).toLowerCase()]
    removeProc.command = ["omarchy-theme-remove", removeProc.themeName]
    removeProc.running = true
  }

  Process {
    id: removeProc
    property string themeName: ""
    onExited: function(exitCode) {
      root.notice = exitCode === 0 ? "Uninstalled " + themeName : "Could not uninstall " + themeName
      installedProc.running = true
    }
  }

  function cancel() {
    opened = false
    filterText = ""
  }

  // Lifecycle hooks invoked by omarchy-shell summon/hide.
  function open(payload) {
    filterText = ""
    failedThemes = ({})
    opened = true
    revealTimer.restart()
    installedProc.running = true
    thumbScanProc.running = true
    if (!buildProc.running) {
      building = themes.length === 0
      buildFailed = false
      buildProc.running = true
    }
    updateVisibleItems()
    Qt.callLater(function() { carousel.forceActiveFocus() })
  }

  function close() {
    cancel()
  }

  // A preview still decoding must not hold an invisible overlay that has the
  // keyboard grabbed: reveal anyway shortly.
  Timer {
    id: revealTimer
    interval: 250
    onTriggered: root.revealed = true
  }

  // ------------------------------------------------------------------ UI

  OverlayWindow {
    id: panel
    shown: root.opened
    shownKeyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "omageeko-theme-catalog"

    MouseArea {
      anchors.fill: parent
      onClicked: root.cancel()
    }

    Text {
      anchors.centerIn: parent
      visible: root.themes.length === 0
      textFormat: Text.PlainText
      text: root.buildFailed ? "Could not read the themes from omarchy.org" : "Reading the community themes from omarchy.org…"
      color: root.foreground
      style: Text.Outline
      styleColor: Util.alpha(root.dimColor, 0.7)
      font.pixelSize: Style.font.display
      font.weight: Font.DemiBold
    }

    Item {
      id: card
      visible: root.themes.length > 0
      opacity: root.revealed ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 120 } }
      width: Math.min(parent.width - 80, root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing) + 40)
      height: carousel.height + Style.space(30) + chrome.height
      anchors.centerIn: parent

      MouseArea { anchors.fill: parent; onClicked: {} }

      // Tempered glass below the carousel, under its text and backgrounds:
      // the selected theme's screenshot, decoded tiny and blurred, under its
      // background color. The compositor's blur is off in Omarchy, so the
      // frosting is drawn here.
      Item {
        id: glass
        anchors.top: chrome.top
        anchors.topMargin: -Style.space(12)
        anchors.bottom: chrome.bottom
        anchors.bottomMargin: -Style.space(4)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, root.maxThumbs * (root.thumbWidth + root.thumbSpacing) - root.thumbSpacing + Style.space(56))
        readonly property int radius: 18

        Rectangle {
          id: glassMask
          anchors.fill: parent
          radius: glass.radius
          visible: false
          layer.enabled: true
        }

        Item {
          anchors.fill: parent
          layer.enabled: true
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: glassMask
          }

          Rectangle { anchors.fill: parent; color: root.glassTint }

          Image {
            id: frost
            anchors.fill: parent
            source: root.holdPreviews && root.currentTheme ? Util.fileUrl(root.previewDir + "/" + root.currentTheme.slug + ".webp") : ""
            // A thumbnail-sized decode is most of the blur, and nearly free.
            sourceSize.width: 96
            sourceSize.height: 54
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            visible: false
          }

          MultiEffect {
            anchors.fill: parent
            source: frost
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.15
            opacity: frost.status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
          }

          Rectangle { anchors.fill: parent; color: Util.alpha(root.glassTint, 0.74) }

          // Sheen: light catching the top edge of the glass.
          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop { position: 0.0; color: Util.alpha(root.glassText, 0.07) }
              GradientStop { position: 0.35; color: "transparent" }
            }
          }
        }

        Rectangle {
          anchors.fill: parent
          radius: glass.radius
          color: "transparent"
          border.width: 1
          border.color: Util.alpha(root.glassAccent, 0.55)
        }
      }

      Item {
        id: carousel
        anchors.top: parent.top
        anchors.topMargin: Style.space(30)
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing)
        height: root.expandedHeight
        focus: true

        readonly property real itemStep: root.sliceWidth + root.sliceSpacing
        readonly property real previewX: (width - root.expandedWidth) / 2
        readonly property bool mirrored: LayoutMirroring.enabled

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          // The confirmation has the keyboard while it is up.
          if (root.removeConfirmOpen) {
            removeConfirm.handleKey(event)
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Escape) {
            if (root.inBackgrounds) root.inBackgrounds = false
            else if (root.filterText) root.filterText = ""
            else root.cancel()
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.enterBackgrounds()
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.inBackgrounds = false
            event.accepted = true
          } else if (root.inBackgrounds && (Util.readingKey(event) === Qt.Key_Left || Util.readingKey(event) === Qt.Key_Right)) {
            root.selectBackground(Util.readingKey(event) === Qt.Key_Right ? 1 : -1)
            event.accepted = true
          } else if (root.inBackgrounds && (event.key === Qt.Key_Home || event.key === Qt.Key_End)) {
            root.bgIndex = event.key === Qt.Key_Home ? 0 : root.currentBgs.length - 1
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.install()
            event.accepted = true
          } else if ((event.key === Qt.Key_Delete || (event.key === Qt.Key_Backspace && !root.filterText))
                     && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            root.requestRemove()
            event.accepted = true
          } else if (Util.editsFilter(event, root.filterText)) {
            root.filterText = Util.editedFilter(event, root.filterText)
            event.accepted = true
          } else if (Util.readingKey(event) === Qt.Key_Left || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab) {
            root.selectAdjacent(-1)
            event.accepted = true
          } else if (Util.readingKey(event) === Qt.Key_Right || event.key === Qt.Key_Tab) {
            root.selectAdjacent(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Home) {
            if (root.matching.length) root.selectedIndex = root.matching[0]
            event.accepted = true
          } else if (event.key === Qt.Key_End) {
            if (root.matching.length) root.selectedIndex = root.matching[root.matching.length - 1]
            event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
            root.inBackgrounds = false
            root.filterText += event.text
            event.accepted = true
          }
        }

        WheelHandler {
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          property real pending: 0
          onWheel: function(event) {
            pending += (event.angleDelta.x !== 0 ? -event.angleDelta.x : -event.angleDelta.y)
            while (Math.abs(pending) >= 120) {
              root.selectAdjacent(pending > 0 ? 1 : -1)
              pending -= pending > 0 ? 120 : -120
            }
          }
        }

        Repeater {
          id: themeCards
          model: visibleThemes

          delegate: Item {
            id: item
            required property int themeIndex
            required property int relativeIndex

            readonly property var theme: root.themes[themeIndex]
            readonly property string previewPath: theme ? root.previewDir + "/" + theme.slug + ".webp" : ""
            readonly property bool selected: themeIndex === root.selectedIndex

            readonly property real readingX: selected ? carousel.previewX : (relativeIndex < 0 ? carousel.previewX + relativeIndex * carousel.itemStep : carousel.previewX + root.expandedWidth + root.sliceSpacing + (relativeIndex - 1) * carousel.itemStep)
            x: carousel.mirrored ? carousel.width - readingX - width : readingX
            width: selected ? root.expandedWidth : root.sliceWidth
            height: selected ? root.expandedHeight : root.sliceHeight
            y: selected ? 0 : (root.expandedHeight - root.sliceHeight) / 2
            z: selected ? 100 : 50 - Math.min(Math.abs(relativeIndex), 40)

            readonly property real skAbs: Math.abs(root.skewOffset)
            readonly property real topLeft: root.skewOffset >= 0 ? skAbs : 0
            readonly property real topRight: root.skewOffset >= 0 ? width : width - skAbs
            readonly property real bottomRight: root.skewOffset >= 0 ? width - skAbs : width
            readonly property real bottomLeft: root.skewOffset >= 0 ? 0 : skAbs

            Item {
              id: maskShape
              anchors.fill: parent
              visible: false
              layer.enabled: true
              Shape {
                anchors.fill: parent
                antialiasing: true
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                  fillColor: "white"
                  strokeColor: "transparent"
                  startX: item.topLeft; startY: 0
                  PathLine { x: item.topRight; y: 0 }
                  PathLine { x: item.bottomRight; y: item.height }
                  PathLine { x: item.bottomLeft; y: item.height }
                  PathLine { x: item.topLeft; y: 0 }
                }
              }
            }

            Item {
              anchors.fill: parent
              layer.enabled: true
              layer.smooth: true
              layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: maskShape
                maskThresholdMin: 0.3
                maskSpreadAtMin: 0.3
              }

              Rectangle { anchors.fill: parent; color: root.dimColor }

              Image {
                id: image
                anchors.fill: parent
                // Decoded once at the expanded size, so selecting a slice
                // never reloads it.
                source: root.holdPreviews && item.previewPath ? Util.fileUrl(item.previewPath) : ""
                sourceSize.width: Math.ceil(root.expandedWidth * Screen.devicePixelRatio)
                sourceSize.height: Math.ceil(root.expandedHeight * Screen.devicePixelRatio)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
                opacity: status === Image.Ready ? 1 : 0
                onStatusChanged: if (item.selected && status === Image.Ready) root.revealed = true
              }

              Rectangle {
                anchors.fill: parent
                color: Util.alpha(root.dimColor, item.selected ? 0 : 0.42)
              }
            }

            Shape {
              anchors.fill: parent
              antialiasing: true
              preferredRendererType: Shape.CurveRenderer
              ShapePath {
                fillColor: "transparent"
                strokeColor: item.selected ? root.glassAccent : root.unselectedBorder
                strokeWidth: item.selected ? (root.inBackgrounds ? 2 : 3) : 1
                startX: item.topLeft; startY: 0
                PathLine { x: item.topRight; y: 0 }
                PathLine { x: item.bottomRight; y: item.height }
                PathLine { x: item.bottomLeft; y: item.height }
                PathLine { x: item.topLeft; y: 0 }
              }
            }

            // On disk (computer) or still to download (cloud), on every card.
            Rectangle {
              id: badge
              readonly property bool local: root.isInstalled(item.theme)
              anchors.top: parent.top
              anchors.right: parent.right
              anchors.topMargin: item.selected ? 14 : 10
              anchors.rightMargin: item.selected ? 16 : 10
              width: item.selected ? 44 : 32
              height: width
              radius: width / 2
              color: local ? root.selectedBorder : Util.alpha(root.dimColor, 0.88)
              border.width: 2
              border.color: local ? Util.alpha(root.dimColor, 0.6) : Util.alpha(root.foreground, 0.85)
              Behavior on width { NumberAnimation { duration: 120 } }

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: String.fromCodePoint(badge.local ? 0xF0379 : 0xF0162)
                color: badge.local ? root.dimColor : root.foreground
                font.family: Style.font.family
                font.pixelSize: Math.round(badge.width * 0.55)
              }
            }

            // The applied theme: a green check beside its computer badge.
            Rectangle {
              id: currentBadge
              visible: root.isCurrent(item.theme)
              anchors.verticalCenter: badge.verticalCenter
              anchors.right: badge.left
              anchors.rightMargin: 6
              width: badge.width
              height: width
              radius: width / 2
              color: "#2ea043"
              border.width: 2
              border.color: Util.alpha(root.dimColor, 0.6)

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: String.fromCodePoint(0xF0E1E)
                color: "white"
                font.family: Style.font.family
                font.pixelSize: Math.round(currentBadge.width * 0.6)
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: item.selected ? root.install() : (root.selectedIndex = item.themeIndex)
            }
          }
        }
      }

      Column {
        id: chrome
        anchors.top: carousel.bottom
        anchors.topMargin: Style.space(16)
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        spacing: Style.space(8)

        Text {
          width: glass.width - Style.space(40)
          anchors.horizontalCenter: parent.horizontalCenter
          textFormat: Text.PlainText
          text: root.currentTheme ? root.labels[root.selectedIndex] : (root.filterText ? Commons.I18n.t("common.noMatches") : "")
          color: root.glassText
          style: Text.Outline
          styleColor: Util.alpha(root.glassTint, 0.6)
          font.pixelSize: Style.font.display
          font.weight: Font.DemiBold
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }

        Text {
          width: glass.width - Style.space(40)
          anchors.horizontalCenter: parent.horizontalCenter
          textFormat: Text.PlainText
          text: root.currentTheme && root.currentTheme.appList ? root.currentTheme.appList : " "
          color: root.glassText
          opacity: 0.7
          style: Text.Outline
          styleColor: Util.alpha(root.glassTint, 0.6)
          font.pixelSize: Style.font.body
          horizontalAlignment: Text.AlignHCenter
          // The pane is as wide as the screenshot or the backgrounds; a long
          // list wraps onto a second line rather than leaving it.
          wrapMode: Text.WordWrap
          maximumLineCount: 2
          height: Math.ceil(appsMetrics.height * 2)
          verticalAlignment: Text.AlignTop

          FontMetrics { id: appsMetrics; font.pixelSize: Style.font.body }
          elide: Text.ElideRight
        }

        Item { width: 1; height: Style.space(4) }

        // The selected theme's backgrounds. Thumbnails are local files once
        // fetched; a missing one shows its slot until its worker reports it.
        Item {
          id: strip
          readonly property var bgs: root.currentTheme ? (root.currentTheme.bgs || []) : []
          readonly property int shown: Math.min(bgs.length, root.maxThumbs)
          // The last slot carries "+N" for the backgrounds that don't fit,
          // counting the one under the badge.
          readonly property int extra: bgs.length > shown ? bgs.length - shown + 1 : 0
          width: parent.width
          height: root.thumbHeight + 6

          WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            property real pending: 0
            onWheel: function(event) {
              root.enterBackgrounds()
              pending += (event.angleDelta.x !== 0 ? -event.angleDelta.x : -event.angleDelta.y)
              while (Math.abs(pending) >= 120) {
                root.selectBackground(pending > 0 ? 1 : -1)
                pending -= pending > 0 ? 120 : -120
              }
            }
          }

          // A carousel of its own: it scrolls to keep the highlighted
          // background in view, with a neighbour showing on each side.
          ListView {
            id: stripRow
            readonly property real step: root.thumbWidth + root.thumbSpacing
            anchors.centerIn: parent
            width: Math.max(0, strip.shown * step - root.thumbSpacing) + 6
            height: root.thumbHeight + 6
            leftMargin: 3
            rightMargin: 3
            orientation: ListView.Horizontal
            spacing: root.thumbSpacing
            clip: true
            interactive: false
            model: strip.bgs.length
            currentIndex: root.bgIndex
            highlight: Item {}
            highlightFollowsCurrentItem: true
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: strip.shown > 2 ? step + 3 : 3
            preferredHighlightEnd: strip.shown > 2 ? width - step - 3 : width - 3
            highlightMoveDuration: 160
            boundsBehavior: Flickable.StopAtBounds

              delegate: Item {
                id: slot
                required property int index
                width: root.thumbWidth
                height: stripRow.height

              Item {
                id: thumb
                readonly property int index: slot.index
                readonly property var bg: strip.bgs[index]
                readonly property bool ready: !!bg && root.thumbsReady[bg.oid] === true
                readonly property bool current: root.inBackgrounds && index === root.bgIndex
                anchors.centerIn: parent
                width: root.thumbWidth
                height: root.thumbHeight

                // Shapes and images take no clicks, so this still gets them.
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (thumb.current) {
                      root.install()
                    } else {
                      root.enterBackgrounds()
                      root.bgIndex = thumb.index
                    }
                  }
                }

                readonly property real topLeft: root.thumbSkew
                readonly property real topRight: width
                readonly property real bottomRight: width - root.thumbSkew
                readonly property real bottomLeft: 0

                Item {
                  id: thumbMask
                  anchors.fill: parent
                  visible: false
                  layer.enabled: true
                  Shape {
                    anchors.fill: parent
                    antialiasing: true
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                      fillColor: "white"
                      strokeColor: "transparent"
                      startX: thumb.topLeft; startY: 0
                      PathLine { x: thumb.topRight; y: 0 }
                      PathLine { x: thumb.bottomRight; y: thumb.height }
                      PathLine { x: thumb.bottomLeft; y: thumb.height }
                      PathLine { x: thumb.topLeft; y: 0 }
                    }
                  }
                }

                Item {
                  anchors.fill: parent
                  layer.enabled: true
                  layer.smooth: true
                  layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: thumbMask
                    maskThresholdMin: 0.3
                    maskSpreadAtMin: 0.3
                  }

                  Rectangle {
                    id: placeholder
                    anchors.fill: parent
                    color: Util.alpha(root.dimColor, 0.85)
                    SequentialAnimation on opacity {
                      running: !thumb.ready && root.opened
                      loops: Animation.Infinite
                      NumberAnimation { from: 0.85; to: 0.45; duration: 600; easing.type: Easing.InOutQuad }
                      NumberAnimation { from: 0.45; to: 0.85; duration: 600; easing.type: Easing.InOutQuad }
                    }
                  }

                  Image {
                    anchors.fill: parent
                    source: thumb.ready && root.holdPreviews ? Util.fileUrl(root.thumbDir + "/" + thumb.bg.oid + ".jpg") : ""
                    sourceSize.width: Math.ceil(root.thumbWidth * Screen.devicePixelRatio)
                    sourceSize.height: Math.ceil(root.thumbHeight * Screen.devicePixelRatio)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 90 } }
                  }

                  Rectangle {
                    anchors.fill: parent
                    color: Util.alpha(root.glassTint, root.inBackgrounds && !thumb.current ? 0.45 : 0)
                    Behavior on color { ColorAnimation { duration: 120 } }
                  }

                  Rectangle {
                    anchors.fill: parent
                    visible: !root.inBackgrounds && strip.extra > 0 && thumb.index === strip.shown - 1
                    color: Util.alpha(root.glassTint, 0.62)

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "+" + strip.extra
                      color: root.glassText
                      font.pixelSize: Style.font.displayLarge
                      font.weight: Font.DemiBold
                    }
                  }
                }

                Shape {
                  anchors.fill: parent
                  antialiasing: true
                  preferredRendererType: Shape.CurveRenderer
                  ShapePath {
                    fillColor: "transparent"
                    strokeColor: thumb.current ? root.glassAccent : root.unselectedBorder
                    strokeWidth: thumb.current ? 3 : 1
                    startX: thumb.topLeft; startY: 0
                    PathLine { x: thumb.topRight; y: 0 }
                    PathLine { x: thumb.bottomRight; y: thumb.height }
                    PathLine { x: thumb.bottomLeft; y: thumb.height }
                    PathLine { x: thumb.topLeft; y: 0 }
                  }
                }
              }
            }

          }
        }

        Text {
          width: glass.width - Style.space(40)
          anchors.horizontalCenter: parent.horizontalCenter
          textFormat: Text.PlainText
          // The filter while typing; otherwise where the keyboard is.
          readonly property var bg: root.currentBgs[root.bgIndex]
          text: root.inBackgrounds && bg ? (root.bgIndex + 1) + " / " + root.currentBgs.length + " · " + bg.path.split("/").pop().replace(/\.[^.]+$/, "") + (root.isInstalled(root.currentTheme) ? " · Enter applies with this background" : " · Enter installs with this background")
            : root.notice ? root.notice
            : root.filterText ? root.filterText
            : root.currentTheme ? (root.isCurrent(root.currentTheme) ? "✓ Current theme" : root.isInstalled(root.currentTheme) ? "Enter applies · Del uninstalls" : "Enter downloads and installs")
              + (root.currentBgs.length > 0 ? " · ↓ backgrounds" : "")
            : " "
          color: root.glassText
          opacity: (root.filterText || root.notice) && !root.inBackgrounds ? 0.85 : 0.55
          style: Text.Outline
          styleColor: Util.alpha(root.glassTint, 0.6)
          font.pixelSize: Style.font.title
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }
      }
    }

    // Omarchy's own confirmation, as the image picker asks before deleting a
    // theme: the current theme's colors, Cancel first.
    ConfirmDialog {
      id: removeConfirm
      anchors.fill: parent
      z: 10
      opened: root.removeConfirmOpen
      message: root.pendingRemove ? "Uninstall " + String(root.pendingRemove.name || "").replace(/\//g, " ") + "? It stays in the catalog and can be downloaded again." : ""
      confirmText: "Uninstall"
      background: root.dimColor
      foreground: root.foreground
      onCanceled: root.cancelRemove()
      onConfirmed: root.confirmRemove()
    }
  }
}
