import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets.common

Item {
    id: root
    property bool isHovered: mouseArea.containsMouse
    readonly property int buttonSize: 28
    readonly property var battery: SystemMonitorService.battery
    readonly property bool batteryAvailable:
        battery.present === true
        && isFinite(Number(battery.chargePercent))
    readonly property real batteryLevel: batteryAvailable
        ? Math.max(0, Math.min(1, Number(battery.chargePercent) / 100))
        : 0
    readonly property bool showBatteryEffect: batteryAvailable
        && PersonalizationConfig.isExtensionEnabled("batteryRing")
    readonly property bool showBatteryRing: showBatteryEffect
        && PersonalizationConfig.powerButtonBatteryStyle === "ring"
    readonly property bool showBatteryWave: showBatteryEffect
        && PersonalizationConfig.powerButtonBatteryStyle === "wave"
    readonly property bool waveAnimationRunning:
        PersonalizationConfig.waveBatteryAnimationEnabled
        && (!PersonalizationConfig.waveBatteryAnimationFollowPowerProfile
            || PowerProfileService.profile !== "power-saver")
    readonly property bool powerSaverActive:
        PowerProfileService.profile === "power-saver"
    readonly property bool isCharging:
        batteryAvailable && battery.acOnline === true
    readonly property color batteryGreen: "#4caf50"
    readonly property color batteryOrange: "#ff9800"
    readonly property color batteryRed: "#f44336"
    readonly property color batteryGreenContainer: "#1b5e20"
    readonly property color batteryOrangeContainer: "#e65100"
    readonly property color batteryGreenOnContainer: "#c8e6c9"
    readonly property color batteryOrangeOnContainer: "#ffe0b2"
    readonly property color batteryEffectColor: powerSaverActive
        ? batteryOrange
        : (isCharging ? batteryGreen : batteryRed)
    readonly property color batteryEffectBackground: powerSaverActive
        ? batteryOrangeContainer
        : (isCharging
            ? batteryGreenContainer
            : Appearance.colors.colErrorContainer)
    readonly property color batteryEffectOnColor: powerSaverActive
        ? batteryOrangeOnContainer
        : (isCharging
            ? batteryGreenOnContainer
            : Appearance.colors.colOnErrorContainer)

    implicitHeight: buttonSize
    implicitWidth: buttonSize

    Item {
        id: buttonFace
        anchors.centerIn: parent
        width: root.buttonSize
        height: width
        scale: root.isHovered ? 1.14 : 1

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: background
            anchors.centerIn: parent
            width: root.showBatteryRing ? 21 : root.buttonSize
            height: width
            radius: height / 2
            color: root.showBatteryWave
                ? root.batteryEffectBackground
                : Appearance.colors.colError

            Behavior on color {
                ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }

        Canvas {
            id: batteryWave
            anchors.fill: parent
            visible: root.showBatteryWave
            antialiasing: true
            renderStrategy: Canvas.Threaded

            property real displayedLevel: root.batteryLevel
            property real phase: 0
            property color fillColor: root.batteryEffectColor

            Behavior on displayedLevel {
                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
            }

            Behavior on fillColor {
                ColorAnimation { duration: 260; easing.type: Easing.OutCubic }
            }

            NumberAnimation on phase {
                from: 0
                to: Math.PI * 2
                duration: 1800
                loops: Animation.Infinite
                easing.type: Easing.Linear
                running: batteryWave.visible && root.waveAnimationRunning
            }

            onPaint: {
                const context = getContext("2d")
                context.reset()

                if (displayedLevel <= 0)
                    return

                const center = width / 2
                const radius = Math.min(width, height) / 2

                context.save()
                context.beginPath()
                context.arc(center, center, radius, 0, Math.PI * 2)
                context.clip()

                if (displayedLevel >= 0.995) {
                    context.fillStyle = fillColor
                    context.fillRect(0, 0, width, height)
                    context.restore()
                    return
                }

                const levelY = height * (1 - displayedLevel)
                const amplitude = Math.min(1.6,
                    Math.max(0.7, height * 0.045))
                context.beginPath()
                context.moveTo(0,
                    levelY + Math.sin(phase) * amplitude)
                for (let x = 1; x <= width; x += 1) {
                    const y = levelY + Math.sin(
                        x * 0.34 + phase) * amplitude
                    context.lineTo(x, y)
                }
                context.lineTo(width, height)
                context.lineTo(0, height)
                context.closePath()
                context.fillStyle = fillColor
                context.fill()
                context.restore()
            }

            onDisplayedLevelChanged: requestPaint()
            onPhaseChanged: requestPaint()
            onFillColorChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: {
                if (visible)
                    requestPaint()
            }

            Component.onCompleted: requestPaint()
        }

        Canvas {
            id: batteryRing
            anchors.fill: parent
            antialiasing: true
            visible: root.showBatteryRing

            property real displayedLevel: root.batteryLevel
            // Use a solid outline track so the complete enclosure stays
            // visible against both light and dark quick-settings surfaces.
            property color trackColor: Appearance.colors.colOutlineVariant
            property color progressColor: root.batteryEffectColor

            Behavior on displayedLevel {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }

            Behavior on progressColor {
                ColorAnimation { duration: 260; easing.type: Easing.OutCubic }
            }

            onPaint: {
                const context = getContext("2d")
                context.reset()

                const center = width / 2
                const lineWidth = 2.4
                const radius = center - lineWidth / 2 - 0.4
                const startAngle = -Math.PI / 2

                context.lineWidth = lineWidth
                context.lineCap = "round"
                context.strokeStyle = trackColor
                context.beginPath()
                // Slight overlap removes the Canvas seam at the 3 o'clock
                // point, which otherwise looks like a one-pixel break.
                context.arc(center, center, radius, -0.01, Math.PI * 2 + 0.01)
                context.stroke()

                if (root.batteryAvailable && displayedLevel > 0) {
                    context.strokeStyle = progressColor
                    context.beginPath()
                    context.arc(center, center, radius,
                                startAngle,
                                startAngle + Math.PI * 2 * displayedLevel)
                    context.stroke()
                }
            }

            onDisplayedLevelChanged: requestPaint()
            onTrackColorChanged: requestPaint()
            onProgressColorChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            Component.onCompleted: requestPaint()
        }

        Text {
            id: icon
            anchors.centerIn: parent
            text: "power_settings_new"
            font.family: Sizes.fontMaterialSymbols
            font.pixelSize: 18
            font.weight: Font.Normal
            color: root.showBatteryWave
                ? root.batteryEffectOnColor
                : Appearance.colors.colOnError

            Behavior on color {
                ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([
            Paths.systemScriptsDir + "/power-menu.sh",
            PersonalizationConfig.powerMenuStyle
        ])
    }

    PopupToolTip {
        extraVisibleCondition: mouseArea.containsMouse
        text: root.batteryAvailable
            ? qsTr("电量: ") + Math.round(root.batteryLevel * 100) + "%\n"
                + qsTr("点击打开电源菜单")
            : qsTr("电源菜单")
    }
}
