import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// omageeko: session restore (docs/session-restore.md). Shown while a saved
// session is waiting to be restored after login, restoring, or came back
// incomplete; hidden otherwise, like the update button beside it. Left click
// restores; right click (or `omarchy-shell shell toggle omageeko.session-restore`,
// the menu's System › Session) opens a card with the "Restore at login" switch.
BarWidget {
  id: root
  moduleName: "omageeko.session-restore"

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  property var status: ({ state: "hidden", auto: false, windows: 0, saved: "", sameMonitors: false, main: "", missing: [] })
  property bool popupOpen: false
  property bool autoPending: false

  readonly property string sessionState: status.state || "hidden"
  readonly property bool hasSession: (status.windows || 0) > 0
  readonly property bool shown: sessionState === "pending" || sessionState === "restoring" || sessionState === "partial"
  readonly property string savedTime: {
    var saved = String(status.saved || "")
    var date = saved ? new Date(saved) : null
    return date && !isNaN(date.getTime())
      ? date.toLocaleString(Qt.locale(Commons.I18n.formatLocale), "ddd HH:mm") : ""
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function run(args) {
    if (root.bar) root.bar.run("omageeko-session-restore " + args)
  }

  // Shape contract for shell.summon/hide/toggle (Bar.findPanelWidget).
  // Opened from the menu while hidden, the button has no size yet and a popup
  // anchored to it is refused, so show the button first and open a beat later.
  property bool revealed: false
  readonly property bool opened: popupOpen || revealed
  function open() {
    refresh()
    if (shown || popupOpen) {
      popupOpen = true
    } else {
      revealed = true
      revealTimer.restart()
    }
  }
  function close() {
    revealTimer.stop()
    popupOpen = false
    revealed = false
  }

  Timer {
    id: revealTimer
    interval: 80
    onTriggered: root.popupOpen = true
  }

  visible: shown || revealed || popupOpen
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  ShellIpc {
    target: "omageeko.session-restore"

    function refresh(): void {
      root.broadcast("refresh")
    }
  }

  Process {
    id: statusProc
    command: ["omageeko-session-restore", "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(String(text || "").trim())
          if (parsed && typeof parsed === "object") {
            root.status = parsed
            root.autoPending = false
          }
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 300000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // A restore takes up to a minute; follow it without waiting for the slow timer.
  Timer {
    interval: 2000
    running: root.sessionState === "restoring"
    repeat: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.sessionState === "restoring" ? "󰔟" : root.sessionState === "partial" ? "󰀦" : "󰁯"
    active: root.sessionState === "partial"
    slotSize: Style.bar.statusSlot
    tooltipText: root.popupOpen ? ""
      : root.sessionState === "restoring" ? strings.t("tooltip.restoring")
      : root.sessionState === "partial" ? strings.t("tooltip.partial")
      : strings.t("tooltip.pending").arg(strings.tn("windows", root.status.windows || 0).arg(root.status.windows || 0)).arg(root.savedTime)

    onPressed: function(b) {
      if (b === Qt.LeftButton && root.sessionState === "pending") root.run("restore")
      else if (root.popupOpen) root.close()
      else root.open()
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        text: strings.t("title")
        color: root.bar ? root.bar.foreground : Commons.Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.subtitle
        font.bold: true
        width: parent.width
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        text: root.hasSession
          ? strings.tn("windows", root.status.windows).arg(Commons.I18n.formatNumber(root.status.windows)) + " · " + strings.t("saved").arg(root.savedTime)
          : strings.t("nothingSaved")
        color: root.bar ? root.bar.foreground : Commons.Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        width: parent.width
        wrapMode: Text.Wrap
      }

      Text {
        visible: root.hasSession
        textFormat: Text.PlainText
        text: root.status.sameMonitors ? strings.t("sameMonitors") : strings.t("monitorsChanged").arg(root.status.main || "")
        color: Qt.darker(root.bar ? root.bar.foreground : Commons.Color.foreground, 1.3)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
        width: parent.width
        wrapMode: Text.Wrap
      }

      Text {
        visible: root.sessionState === "partial" && (root.status.missing || []).length > 0
        // Window classes come from apps: plain text only.
        textFormat: Text.PlainText
        text: strings.t("notPlaced").arg((root.status.missing || []).slice(0, 8).join(", "))
        color: Commons.Color.urgent
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
        width: parent.width
        wrapMode: Text.Wrap
      }

      Toggle {
        width: parent.width
        label: strings.t("auto.label")
        description: strings.t("auto.description")
        foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        // Optimistic: the knob moves now, the next status read confirms it.
        checked: root.autoPending ? !root.status.auto : !!root.status.auto
        onClicked: {
          root.autoPending = !root.autoPending
          root.run(root.status.auto ? "auto off" : "auto on")
        }
      }

      Row {
        spacing: Style.space(6)

        Button {
          text: strings.t("action.restore")
          bordered: true
          enabled: root.hasSession && root.sessionState !== "restoring"
          opacity: enabled ? 1 : 0.5
          onClicked: { root.run("restore"); root.close() }
        }

        Button {
          text: strings.t("action.save")
          bordered: true
          onClicked: root.run("save")
        }

        Button {
          text: strings.t("action.dismiss")
          bordered: true
          visible: root.sessionState === "pending" || root.sessionState === "partial"
          onClicked: { root.run("dismiss"); root.close() }
        }

        Button {
          text: strings.t("action.log")
          bordered: true
          onClicked: {
            if (root.bar) root.bar.run("omarchy-launch-editor \"${XDG_STATE_HOME:-$HOME/.local/state}/omageeko/session-restore.log\"")
            root.close()
          }
        }
      }
    }
  }
}
