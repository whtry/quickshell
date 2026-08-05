import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import qs.Common
import qs.Services

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    property var context: null
    property bool isExiting: false
    property real contentOpacity: 0
    property real contentScale: 0.98
    property real backgroundBlur: 0
    property bool startupStarted: false
    property bool startupFallbackElapsed: false

    readonly property string snapshotSource: LockSnapshot.snapshotUrl(root.screen)
    readonly property bool snapshotReady: snapshotSource !== "" && desktopSnapshotFallback.status === Image.Ready
    readonly property bool canStartStartupAnimation: snapshotReady || startupFallbackElapsed

    color: "transparent"

    onCanStartStartupAnimationChanged: maybeStartStartupAnimation()

    Component.onCompleted: maybeStartStartupAnimation()

    function focusAuth() {
        if (lockContent.opacity > 0)
            lockContent.forceAuthFocus();
    }

    function maybeStartStartupAnimation() {
        if (startupStarted || !canStartStartupAnimation)
            return;

        startupStarted = true;
        startupAnim.start();
    }

    function startExitAnimation() {
        if (isExiting)
            return;

        startupAnim.stop();
        isExiting = true;
        exitAnim.start();
    }

    Rectangle {
        id: immediateFallback
        anchors.fill: parent
        color: Appearance.colors.colLayer0Base
    }

    Image {
        id: desktopSnapshotFallback
        anchors.fill: parent
        source: root.snapshotSource
        fillMode: Image.Stretch
        asynchronous: false
        cache: false
        visible: root.snapshotSource !== ""

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: root.backgroundBlur
            blurMax: 64
            blurMultiplier: 1
        }

        onStatusChanged: root.maybeStartStartupAnimation()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.focusAuth()
    }

    Connections {
        target: root.context
        ignoreUnknownSignals: true

        function onUnlockFailed() {
            root.isExiting = false;
            root.focusAuth();
        }
    }

    Connections {
        target: root.lock

        function onUnlock() {
            root.startExitAnimation();
        }
    }

    Timer {
        id: startupFallbackTimer
        interval: 160
        running: true
        repeat: false
        onTriggered: root.startupFallbackElapsed = true
    }

    ParallelAnimation {
        id: startupAnim
        running: false
        onFinished: root.focusAuth()

        NumberAnimation {
            target: root
            property: "backgroundBlur"
            to: 1
            duration: Appearance.animation.standardLarge.duration
            easing.type: Appearance.animation.standardLarge.type
            easing.bezierCurve: Appearance.animation.standardLarge.bezierCurve
        }

        NumberAnimation {
            target: root
            property: "contentOpacity"
            to: 1
            duration: Appearance.animation.standard.duration
            easing.type: Appearance.animation.standard.type
            easing.bezierCurve: Appearance.animation.standard.bezierCurve
        }

        NumberAnimation {
            target: root
            property: "contentScale"
            to: 1
            duration: Appearance.animation.expressiveDefaultSpatial.duration
            easing.type: Appearance.animation.expressiveDefaultSpatial.type
            easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
        }
    }

    LockContent {
        id: lockContent
        anchors.fill: parent
        anchors.margins: Sizes.lockOuterPadding * 3
        context: root.context
        screenHeight: root.height
        opacity: root.contentOpacity
        scale: root.contentScale
    }

    SequentialAnimation {
        id: exitAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "contentScale"
                to: 1.02
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }

            NumberAnimation {
                target: root
                property: "contentOpacity"
                to: 0
                duration: Appearance.animation.standardSmall.duration
                easing.type: Appearance.animation.standardSmall.type
                easing.bezierCurve: Appearance.animation.standardSmall.bezierCurve
            }

            NumberAnimation {
                target: root
                property: "backgroundBlur"
                to: 0
                duration: Appearance.animation.standardLarge.duration
                easing.type: Appearance.animation.standardLarge.type
                easing.bezierCurve: Appearance.animation.standardLarge.bezierCurve
            }
        }

        onFinished: {
            if (root.context)
                root.context.finishUnlock();
            else
                root.lock.locked = false;
        }
    }
}
