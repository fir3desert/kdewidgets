import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property real percent: 0
    property bool hasBattery: true
    property bool charging: false
    property bool chargingAnimation: true
    property bool vertical: false
    property color tintColor: Kirigami.Theme.textColor
    property string animationStyle: "sweep"

    readonly property real clampedPercent: Math.max(0, Math.min(100, root.percent))
    readonly property bool animating: root.hasBattery && root.charging && root.chargingAnimation
    readonly property bool sweeps: root.animating && (root.animationStyle === "sweep" || root.animationStyle === "double")
    readonly property bool secondSweep: root.animating && root.animationStyle === "double"
    readonly property bool breathing: root.animating && root.animationStyle === "pulse"
    readonly property bool glowing: root.animating && root.animationStyle === "glow"
    readonly property bool boltAnim: root.animating && root.animationStyle === "bolt"
    readonly property bool lightningAnim: root.animating && root.animationStyle === "lightning"
    readonly property bool waveAnim: root.animating && root.animationStyle === "wave"
    readonly property bool stripesAnim: root.animating && root.animationStyle === "stripes"
    readonly property bool cometAnim: root.animating && root.animationStyle === "comet"
    readonly property bool heartbeatAnim: root.animating && root.animationStyle === "heartbeat"
    readonly property bool neonAnim: root.animating && root.animationStyle === "neon"
    readonly property bool twinCometAnim: root.animating && root.animationStyle === "twin"
    readonly property bool snakeAnim: root.animating && root.animationStyle === "snake"
    readonly property bool orbitAnim: root.animating && root.animationStyle === "orbit"
    readonly property bool spiralAnim: root.animating && root.animationStyle === "spiral"
    readonly property bool pendulumAnim: root.animating && root.animationStyle === "pendulum"
    readonly property bool scannerAnim: root.animating && root.animationStyle === "scanner"
    readonly property bool neonTwinAnim: root.animating && root.animationStyle === "neon2"
    readonly property bool neonWaveAnim: root.animating && root.animationStyle === "neonwave"
    readonly property bool neonBoltAnim: root.animating && root.animationStyle === "neonbolt"
    readonly property bool neonSpinAnim: root.animating && root.animationStyle === "neonspin"
    readonly property bool fireflyAnim: root.animating && root.animationStyle === "firefly"
    readonly property bool rippleAnim: root.animating && root.animationStyle === "ripple"
    readonly property bool auroraAnim: root.animating && root.animationStyle === "aurora"
    readonly property bool matrixAnim: root.animating && root.animationStyle === "matrix"

    property real chargePulse
    SequentialAnimation on chargePulse {
        running: root.animating
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 950; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 950; easing.type: Easing.InOutSine }
    }

    property real breath
    SequentialAnimation on breath {
        running: root.breathing
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 1000; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 1000; easing.type: Easing.InOutSine }
    }

    // Heartbeat: two quick pulses followed by a pause, like an ECG.
    property real heartbeatPulse
    SequentialAnimation on heartbeatPulse {
        running: root.heartbeatAnim
        loops: Animation.Infinite
        NumberAnimation { from: 0.0; to: 1.0; duration: 110; easing.type: Easing.OutQuad }
        NumberAnimation { from: 1.0; to: 0.25; duration: 120; easing.type: Easing.InQuad }
        NumberAnimation { from: 0.25; to: 0.85; duration: 110; easing.type: Easing.OutQuad }
        NumberAnimation { from: 0.85; to: 0.0; duration: 240; easing.type: Easing.InQuad }
        PauseAnimation { duration: 760 }
        onRunningChanged: if (!running) root.heartbeatPulse = 0
    }

    // Celebration when reaching 100 %: a single flash with sparks, only once.
    property bool celebrating: false
    property real celebrationProgress: 0
    property int previousPercent: clampedPercent

    onClampedPercentChanged: {
        if (root.clampedPercent >= 100 && root.previousPercent < 100) {
            root.startCelebration();
        }
        root.previousPercent = root.clampedPercent;
    }

    function startCelebration() {
        if (!root.hasBattery || !root.chargingAnimation) {
            return;
        }
        root.celebrationProgress = 0;
        root.celebrating = true;
        celebrationCanvas.requestPaint();
    }

    readonly property color outlineColor: {
        if (!root.hasBattery) return Qt.alpha(root.tintColor, 0.55)
        if (root.charging) {
            const pulse = root.heartbeatAnim ? root.heartbeatPulse : root.chargePulse
            return Qt.alpha(root.tintColor, 0.55 + 0.45 * pulse)
        }
        return root.tintColor
    }

    readonly property real fillOpacity: root.breathing
        ? 0.30 + 0.26 * root.breath
        : (root.heartbeatAnim ? 0.30 + 0.30 * root.heartbeatPulse : 0.30)
    readonly property color numberColor: root.hasBattery ? root.tintColor : Kirigami.Theme.disabledTextColor

    readonly property real nubLength: Math.max(2, Math.round((root.vertical ? root.height : root.width) * 0.055))
    readonly property real nubThickness: Math.round((root.vertical ? root.width : root.height) * 0.44)

    // Region occupied by the fill inside the battery body. It is used
    // to clip the animations so they do not enter the empty part.
    readonly property rect fillRect: {
        const m = body.innerInset;
        if (root.vertical) {
            const h = body.usableHeight * root.clampedPercent / 100;
            return Qt.rect(m, body.height - m - h, body.usableWidth, h);
        }
        const w = body.usableWidth * root.clampedPercent / 100;
        return Qt.rect(m, m, w, body.usableHeight);
    }
    readonly property real fillRadius: Math.max(1, body.radius - body.lineWidth - 1)
    readonly property real stripeSpacing: Math.max(5, body.thickness * 0.32)

    function clipToFill(ctx) {
        const r = root.fillRect;
        ctx.beginPath();
        ctx.roundedRect(r.x, r.y, r.width, r.height, root.fillRadius, root.fillRadius);
        ctx.clip();
    }

    // Point on the body outline for t in [0, 1), clockwise from the top-left
    // straight edge. Shared by the outline-based animations.
    function perimeterPoint(t) {
        const inset = Math.max(1, body.lineWidth / 2);
        const x = inset;
        const y = inset;
        const w = Math.max(0, body.width - inset * 2);
        const h = Math.max(0, body.height - inset * 2);
        const radius = Math.max(1, body.radius - inset);
        const straightW = Math.max(0, w - radius * 2);
        const straightH = Math.max(0, h - radius * 2);
        const arc = Math.PI * radius / 2;
        const perimeter = 2 * straightW + 2 * straightH + 4 * arc;

        if (perimeter <= 0) {
            return Qt.point(x + w / 2, y + h / 2);
        }

        let d = (((t % 1) + 1) % 1) * perimeter;

        if (d <= straightW) {
            return Qt.point(x + radius + d, y);
        }
        d -= straightW;

        if (d <= arc) {
            const a = -Math.PI / 2 + (d / arc) * (Math.PI / 2);
            return Qt.point(x + w - radius + radius * Math.cos(a),
                            y + radius + radius * Math.sin(a));
        }
        d -= arc;

        if (d <= straightH) {
            return Qt.point(x + w, y + radius + d);
        }
        d -= straightH;

        if (d <= arc) {
            const a = (d / arc) * (Math.PI / 2);
            return Qt.point(x + w - radius + radius * Math.cos(a),
                            y + h - radius + radius * Math.sin(a));
        }
        d -= arc;

        if (d <= straightW) {
            return Qt.point(x + w - radius - d, y + h);
        }
        d -= straightW;

        if (d <= arc) {
            const a = Math.PI / 2 + (d / arc) * (Math.PI / 2);
            return Qt.point(x + radius + radius * Math.cos(a),
                            y + h - radius + radius * Math.sin(a));
        }
        d -= arc;

        if (d <= straightH) {
            return Qt.point(x, y + h - radius - d);
        }
        d -= straightH;

        const a = Math.PI + (d / arc) * (Math.PI / 2);
        return Qt.point(x + radius + radius * Math.cos(a),
                        y + radius + radius * Math.sin(a));
    }

    Rectangle {
        id: nub
        x: root.vertical ? (root.width - width)/2 : root.width - width
        y: root.vertical ? 0 : (root.height - height)/2
        width: root.vertical ? root.nubThickness : root.nubLength
        height: root.vertical ? root.nubLength : root.nubThickness
        radius: Math.min(1.5, root.nubLength/2)
        color: root.outlineColor
        opacity: 0.85
    }

    Rectangle {
        id: body
        x: 0
        y: root.vertical ? root.nubLength : 0
        width: root.vertical ? root.width : root.width - root.nubLength
        height: root.vertical ? root.height - root.nubLength : root.height
        color: "transparent"
        readonly property real thickness: root.vertical ? body.width : body.height
        readonly property real lineWidth: Math.max(1.5, body.thickness * 0.065)
        readonly property real innerInset: body.lineWidth + Math.max(1.5, body.thickness * 0.025)
        readonly property real usableWidth: Math.max(0, body.width - body.innerInset*2)
        readonly property real usableHeight: Math.max(0, body.height - body.innerInset*2)
        radius: Math.min(8, body.thickness * 0.22)
        border.width: body.lineWidth
        border.color: root.outlineColor
    }

    Rectangle {
        id: glow
        anchors.fill: body
        anchors.margins: -Math.max(2, Math.round(body.lineWidth * 1.6))
        radius: body.radius + Math.max(2, Math.round(body.lineWidth * 1.6))
        color: "transparent"
        border.width: Math.max(2, Math.round(body.lineWidth * 1.6))
        border.color: root.tintColor
        visible: root.glowing
        property real glowOpacity: 0
        opacity: glow.glowOpacity
        SequentialAnimation on glowOpacity {
            running: glow.visible
            loops: Animation.Infinite
            NumberAnimation { from: 0.0; to: 0.7; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.7; to: 0.0; duration: 800; easing.type: Easing.InOutSine }
        }
    }

    Rectangle {
        id: fill
        visible: root.hasBattery && root.clampedPercent > 0
        x: body.x + body.innerInset
        y: root.vertical ? body.y + body.height - body.innerInset - height : body.y + body.innerInset
        width: root.vertical ? body.usableWidth : body.usableWidth * root.clampedPercent / 100
        height: root.vertical ? body.usableHeight * root.clampedPercent / 100 : body.usableHeight
        radius: Math.max(1, body.radius - body.lineWidth - 1)
        color: Qt.alpha(root.tintColor, root.fillOpacity)
        clip: false

        Behavior on width { enabled: !root.vertical; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: root.vertical; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on color { enabled: !root.breathing && !root.heartbeatAnim; ColorAnimation { duration: 220 } }

        Rectangle {
            id: shine
            visible: root.sweeps
            width: root.vertical ? fill.width : Math.max(4, Math.round(fill.width * 0.18))
            height: root.vertical ? Math.max(4, Math.round(fill.height * 0.18)) : fill.height
            color: Qt.rgba(1,1,1,0.38)
            property real sweepPos
            x: root.vertical ? 0 : shine.sweepPos
            y: root.vertical ? shine.sweepPos : 0
            SequentialAnimation on sweepPos { running: shine.visible && !root.vertical; loops: Animation.Infinite; NumberAnimation { from: -shine.width; to: fill.width; duration: 1100; easing.type: Easing.InOutQuad } PauseAnimation { duration: 220 } }
            SequentialAnimation on sweepPos { running: shine.visible && root.vertical; loops: Animation.Infinite; NumberAnimation { from: -shine.height; to: fill.height; duration: 1100; easing.type: Easing.InOutQuad } PauseAnimation { duration: 220 } }
        }
        Rectangle {
            id: shine2
            visible: root.secondSweep
            width: root.vertical ? fill.width : Math.max(4, Math.round(fill.width * 0.13))
            height: root.vertical ? Math.max(4, Math.round(fill.height * 0.13)) : fill.height
            color: Qt.rgba(1,1,1,0.24)
            property real sweepPos
            x: root.vertical ? 0 : shine2.sweepPos
            y: root.vertical ? shine2.sweepPos : 0
            SequentialAnimation on sweepPos { running: shine2.visible && !root.vertical; loops: Animation.Infinite; PauseAnimation { duration: 520 } NumberAnimation { from: -shine2.width; to: fill.width; duration: 1100; easing.type: Easing.InOutQuad } PauseAnimation { duration: 240 } }
            SequentialAnimation on sweepPos { running: shine2.visible && root.vertical; loops: Animation.Infinite; PauseAnimation { duration: 520 } NumberAnimation { from: -shine2.height; to: fill.height; duration: 1100; easing.type: Easing.InOutQuad } PauseAnimation { duration: 240 } }
        }

    }

    Text {
        id: number
        anchors.centerIn: body
        width: Math.max(0, body.width - body.innerInset*2)
        height: Math.max(0, body.height * 0.84)
        text: root.hasBattery ? Math.round(root.clampedPercent) : "—"
        color: root.numberColor
        font.bold: true
        font.pixelSize: Math.max(7, Math.round(body.thickness * 0.63))
        fontSizeMode: Text.Fit
        minimumPixelSize: 6
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.PlainText
        z: 3
    }

    // Thunderstorm ("bolt"): zigzag lightning bolts drawn at random
    // positions inside the battery body, flashing continuously while
    // charging, like a small electrical storm.
    Canvas {
        id: boltCanvas

        objectName: "boltCanvas"
        anchors.fill: body
        visible: root.boltAnim
        z: 2

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.boltAnim || width <= 0 || height <= 0) {
                return;
            }

            // Faint background glow, as if it were lighting up the storm.
            if (Math.random() < 0.18) {
                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.07);
                ctx.fillRect(0, 0, width, height);
            }

            const strikes = 2 + Math.floor(Math.random() * 3);
            for (let s = 0; s < strikes; s++) {
                // Every now and then a bolt is skipped so the storm
                // does not blink at a regular cadence.
                if (Math.random() < 0.20) {
                    continue;
                }

                const x = width * (0.08 + Math.random() * 0.84);
                const top = height * (Math.random() < 0.5 ? 0.02 : 0.12);
                const bottom = height * (0.98 - Math.random() * 0.12);
                const jitter = Math.max(2.5, width * 0.14);
                const segments = 6;
                const points = [[x, top]];

                for (let i = 1; i < segments; i++) {
                    const t = i / segments;
                    points.push([
                        Math.max(2, Math.min(width - 2,
                            x + (Math.random() - 0.5) * jitter * 2)),
                        top + (bottom - top) * t
                    ]);
                }
                points.push([
                    Math.max(2, Math.min(width - 2,
                        x + (Math.random() - 0.5) * jitter)),
                    bottom
                ]);

                ctx.beginPath();
                ctx.moveTo(points[0][0], points[0][1]);
                for (let i = 1; i < points.length; i++) {
                    ctx.lineTo(points[i][0], points[i][1]);
                }
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.shadowColor = "#cfefff";
                ctx.shadowBlur = Math.max(3, height * 0.22);

                // Outer halo.
                ctx.lineWidth = Math.max(2.5, height * 0.18);
                ctx.strokeStyle = Qt.rgba(0.65, 0.88, 1, 0.20);
                ctx.stroke();

                // Bright core of the bolt.
                ctx.lineWidth = Math.max(1, height * 0.06);
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.55 + Math.random() * 0.45);
                ctx.stroke();

                // Secondary branch, to make it look like a real lightning bolt.
                if (Math.random() < 0.70) {
                    const point = points[1 + Math.floor(Math.random() * (points.length - 2))];
                    const direction = Math.random() < 0.5 ? -1 : 1;
                    const length = (bottom - top) * 0.22;

                    ctx.beginPath();
                    ctx.moveTo(point[0], point[1]);
                    ctx.lineTo(point[0] + direction * jitter * (0.6 + Math.random() * 0.6),
                               point[1] + length * 0.5);
                    ctx.lineTo(point[0] + direction * jitter * (0.9 + Math.random() * 0.8),
                               point[1] + length);
                    ctx.lineWidth = Math.max(0.8, height * 0.045);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.45 + Math.random() * 0.4);
                    ctx.stroke();
                }
            }
        }

        Timer {
            interval: 80
            repeat: true
            running: boltCanvas.visible
            onTriggered: boltCanvas.requestPaint()
        }
    }

    // "lightning" style: a single fixed horizontal bolt inside a plasma
    // halo. The bolt and its arcs flicker in place, without moving from
    // right to left.
    Canvas {
        id: lightningCanvas

        objectName: "lightningCanvas"
        anchors.fill: body
        visible: root.lightningAnim
        z: 2

        onVisibleChanged: if (visible) requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.lightningAnim || width <= 0 || height <= 0) {
                return;
            }

            const margin = Math.max(2, body.innerInset + 1);
            const startX = Math.min(margin, width / 2);
            const endX = Math.max(width - margin, startX + 1);
            const boltLength = Math.max(8, endX - startX);
            const centerY = height / 2;
            const centerX = width / 2;
            const glowRadius = Math.max(2, height * 0.30);
            const glowStretch = Math.max(1, centerX / glowRadius);

            // Continuous plasma halo along the whole bolt, without stray
            // dots in the background.
            ctx.save();
            ctx.translate(centerX, centerY);
            ctx.scale(glowStretch, 1);
            const plasma = ctx.createRadialGradient(0, 0, 0, 0, 0, glowRadius);
            plasma.addColorStop(0.0, "rgba(220,245,255,0.42)");
            plasma.addColorStop(0.28, "rgba(190,225,255,0.18)");
            plasma.addColorStop(0.60, "rgba(120,180,255,0.06)");
            plasma.addColorStop(1.0, "rgba(80,150,255,0.0)");
            ctx.fillStyle = plasma;
            ctx.beginPath();
            ctx.arc(0, 0, glowRadius, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();

            // Single horizontal zigzag bolt.
            const jitter = Math.max(1.5, height * 0.18);
            const segments = 7;
            const points = [[startX, centerY]];

            for (let i = 1; i < segments; i++) {
                const t = i / segments;
                points.push([
                    startX + boltLength * t,
                    centerY + (Math.random() - 0.5) * jitter * 2
                ]);
            }
            points.push([endX, centerY]);

            ctx.beginPath();
            ctx.moveTo(points[0][0], points[0][1]);
            for (let i = 1; i < points.length; i++) {
                ctx.lineTo(points[i][0], points[i][1]);
            }
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.shadowColor = "#9fd2f0";
            ctx.shadowBlur = Math.max(2, height * 0.14);

            // Bolt halo.
            ctx.lineWidth = Math.max(1.8, height * 0.11);
            ctx.strokeStyle = Qt.rgba(0.59, 0.84, 1, 0.16);
            ctx.stroke();

            // Bright core.
            ctx.lineWidth = Math.max(1, height * 0.045);
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.55 + Math.random() * 0.30);
            ctx.stroke();
        }

        Timer {
            interval: 70
            repeat: true
            running: lightningCanvas.visible
            onTriggered: lightningCanvas.requestPaint()
        }
    }

    // Liquid wave: the surface of the fill ripples. When horizontal, the
    // wave runs along the right edge (the charging front); when vertical,
    // along the top edge.
    Canvas {
        id: waveCanvas

        objectName: "waveCanvas"
        anchors.fill: body
        visible: root.waveAnim
        z: 2

        property real phase: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: waveCanvas.visible
            onTriggered: {
                waveCanvas.phase += 0.10;
                waveCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.waveAnim) {
                return;
            }

            const fr = root.fillRect;
            if (fr.width <= 1 || fr.height <= 1) {
                return;
            }

            ctx.save();
            root.clipToFill(ctx);

            const shortSide = root.vertical ? fr.height : fr.width;
            const span = root.vertical ? fr.width : fr.height;
            const amp = Math.max(1.2, Math.min(3, shortSide * 0.10));
            const step = Math.max(2, span / 28);
            const halo = Math.max(1.6, body.lineWidth * 0.9);

            for (let layer = 0; layer < 2; layer++) {
                const phase = waveCanvas.phase + layer * Math.PI * 0.7;
                ctx.beginPath();
                if (root.vertical) {
                    const baseY = fr.y + 1 + layer * amp * 0.8;
                    for (let d = 0; d <= span + step; d += step) {
                        const t = Math.min(1, d / span);
                        const y = baseY + Math.sin(t * Math.PI * 2 + phase) * amp;
                        if (d === 0) {
                            ctx.moveTo(fr.x, y);
                        } else {
                            ctx.lineTo(fr.x + d, y);
                        }
                    }
                } else {
                    const baseX = fr.x + fr.width - 1 - layer * amp * 0.8;
                    for (let d = 0; d <= span + step; d += step) {
                        const t = Math.min(1, d / span);
                        const x = baseX + Math.sin(t * Math.PI * 2 + phase) * amp;
                        if (d === 0) {
                            ctx.moveTo(x, fr.y);
                        } else {
                            ctx.lineTo(x, fr.y + d);
                        }
                    }
                }
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.strokeStyle = Qt.rgba(1, 1, 1, layer === 0 ? 0.16 : 0.30);
                ctx.lineWidth = layer === 0 ? halo : Math.max(0.8, body.lineWidth * 0.45);
                ctx.stroke();
            }

            ctx.restore();
        }
    }

    // Moving stripes: diagonal bands sweeping across the fill, like an
    // animated progress bar.
    Canvas {
        id: stripesCanvas

        objectName: "stripesCanvas"
        anchors.fill: body
        visible: root.stripesAnim
        z: 2

        property real offset: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 50
            repeat: true
            running: stripesCanvas.visible
            onTriggered: {
                stripesCanvas.offset = (stripesCanvas.offset
                    + root.stripeSpacing * 0.12) % root.stripeSpacing;
                stripesCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.stripesAnim) {
                return;
            }

            const fr = root.fillRect;
            if (fr.width <= 1 || fr.height <= 1) {
                return;
            }

            ctx.save();
            root.clipToFill(ctx);

            const spacing = root.stripeSpacing;
            ctx.lineWidth = Math.max(1.2, spacing * 0.34);
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.20);
            ctx.lineCap = "butt";

            for (let start = -fr.height - spacing + stripesCanvas.offset;
                    start < fr.width + spacing; start += spacing) {
                ctx.beginPath();
                ctx.moveTo(fr.x + start, fr.y + fr.height);
                ctx.lineTo(fr.x + start + fr.height, fr.y);
                ctx.stroke();
            }

            ctx.restore();
        }
    }

    // Comet: a bright dot with a tail crosses the fill and repeats.
    Canvas {
        id: cometCanvas

        objectName: "cometCanvas"
        anchors.fill: body
        visible: root.cometAnim
        z: 2

        property real progress: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 40
            repeat: true
            running: cometCanvas.visible
            onTriggered: {
                cometCanvas.progress += 0.014;
                if (cometCanvas.progress > 1.30) {
                    cometCanvas.progress = 0;
                }
                cometCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.cometAnim || cometCanvas.progress > 1) {
                return;
            }

            const fr = root.fillRect;
            if (fr.width <= 1 || fr.height <= 1) {
                return;
            }

            ctx.save();
            root.clipToFill(ctx);

            const travel = Math.max(0, Math.min(1, cometCanvas.progress));
            const shortSide = root.vertical ? fr.width : fr.height;
            const trailT = Math.max(0, travel - 0.38);

            function cometPoint(t) {
                if (root.vertical) {
                    return {
                        x: fr.x + fr.width / 2 + Math.sin(t * Math.PI * 2) * fr.width * 0.15,
                        y: fr.y + fr.height - t * fr.height
                    };
                }
                return {
                    x: fr.x + t * fr.width,
                    y: fr.y + fr.height / 2 + Math.sin(t * Math.PI * 2) * fr.height * 0.15
                };
            }

            const head = cometPoint(travel);
            const tail = cometPoint(trailT);

            if (travel - trailT > 0.01) {
                const gradient = ctx.createLinearGradient(tail.x, tail.y, head.x, head.y);
                gradient.addColorStop(0, "rgba(255,255,255,0)");
                gradient.addColorStop(0.55, "rgba(255,255,255,0.18)");
                gradient.addColorStop(1, "rgba(255,255,255,0.62)");
                ctx.strokeStyle = gradient;
                ctx.lineWidth = Math.max(1.2, shortSide * 0.10);
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(tail.x, tail.y);
                ctx.lineTo(head.x, head.y);
                ctx.stroke();
            }

            const glowRadius = Math.max(2.5, shortSide * 0.38);
            const glow = ctx.createRadialGradient(head.x, head.y, 0, head.x, head.y, glowRadius);
            glow.addColorStop(0, "rgba(255,255,255,0.85)");
            glow.addColorStop(0.35, "rgba(255,255,255,0.35)");
            glow.addColorStop(1, "rgba(255,255,255,0)");
            ctx.fillStyle = glow;
            ctx.beginPath();
            ctx.arc(head.x, head.y, glowRadius, 0, Math.PI * 2);
            ctx.fill();

            ctx.restore();
        }
    }

    // Perimeter neon: a point of light travels around the body outline.
    Canvas {
        id: neonCanvas

        objectName: "neonCanvas"
        anchors.fill: body
        visible: root.neonAnim
        z: 2

        property real progress: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: neonCanvas.visible
            onTriggered: {
                neonCanvas.progress = (neonCanvas.progress + 0.018) % 1;
                neonCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.neonAnim || width <= 2 || height <= 2) {
                return;
            }

            const inset = Math.max(1, body.lineWidth / 2);
            const x = inset;
            const y = inset;
            const w = width - inset * 2;
            const h = height - inset * 2;
            const radius = Math.max(1, body.radius - inset);
            const straightW = Math.max(0, w - radius * 2);
            const straightH = Math.max(0, h - radius * 2);
            const arc = Math.PI * radius / 2;
            const perimeter = 2 * straightW + 2 * straightH + 4 * arc;

            if (perimeter <= 0) {
                return;
            }

            function perimeterPoint(t) {
                let d = (((t % 1) + 1) % 1) * perimeter;

                if (d <= straightW) {
                    return { x: x + radius + d, y: y };
                }
                d -= straightW;

                if (d <= arc) {
                    const a = -Math.PI / 2 + (d / arc) * (Math.PI / 2);
                    return {
                        x: x + w - radius + radius * Math.cos(a),
                        y: y + radius + radius * Math.sin(a)
                    };
                }
                d -= arc;

                if (d <= straightH) {
                    return { x: x + w, y: y + radius + d };
                }
                d -= straightH;

                if (d <= arc) {
                    const a = (d / arc) * (Math.PI / 2);
                    return {
                        x: x + w - radius + radius * Math.cos(a),
                        y: y + h - radius + radius * Math.sin(a)
                    };
                }
                d -= arc;

                if (d <= straightW) {
                    return { x: x + w - radius - d, y: y + h };
                }
                d -= straightW;

                if (d <= arc) {
                    const a = Math.PI / 2 + (d / arc) * (Math.PI / 2);
                    return {
                        x: x + radius + radius * Math.cos(a),
                        y: y + h - radius + radius * Math.sin(a)
                    };
                }
                d -= arc;

                if (d <= straightH) {
                    return { x: x, y: y + h - radius - d };
                }
                d -= straightH;

                const a = Math.PI + (d / arc) * (Math.PI / 2);
                return {
                    x: x + radius + radius * Math.cos(a),
                    y: y + radius + radius * Math.sin(a)
                };
            }

            // Trail: several dots with decreasing opacity.
            for (let k = 7; k >= 0; k--) {
                const point = perimeterPoint(neonCanvas.progress - k * 0.016);
                const strength = 1 - k / 8;
                ctx.beginPath();
                ctx.arc(point.x, point.y,
                    Math.max(1, body.lineWidth * (0.45 + 0.75 * strength)),
                    0, Math.PI * 2);
                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.08 + 0.52 * strength * strength);
                ctx.fill();
            }

            // Neon head with a halo.
            const head = perimeterPoint(neonCanvas.progress);
            const glowRadius = Math.max(2, body.lineWidth * 2.4);
            const glow = ctx.createRadialGradient(head.x, head.y, 0,
                head.x, head.y, glowRadius);
            glow.addColorStop(0, "rgba(255,255,255,0.85)");
            glow.addColorStop(0.4, "rgba(255,255,255,0.30)");
            glow.addColorStop(1, "rgba(255,255,255,0)");
            ctx.fillStyle = glow;
            ctx.beginPath();
            ctx.arc(head.x, head.y, glowRadius, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    // Twin comet: two comets crossing the fill in opposite directions.
    Canvas {
        id: twinCanvas

        objectName: "twinCanvas"
        anchors.fill: body
        visible: root.twinCometAnim
        z: 2

        property real progress: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 40
            repeat: true
            running: twinCanvas.visible
            onTriggered: {
                twinCanvas.progress += 0.012;
                if (twinCanvas.progress > 1.15) {
                    twinCanvas.progress = 0;
                }
                twinCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const fr = root.fillRect;
            if (!root.twinCometAnim || fr.width <= 1 || fr.height <= 1) {
                return;
            }

            ctx.save();
            root.clipToFill(ctx);

            const shortSide = root.vertical ? fr.width : fr.height;
            const glowRadius = Math.max(2.5, shortSide * 0.34);
            const trail = 0.34;

            function pathPoint(t) {
                if (root.vertical) {
                    return {
                        x: fr.x + fr.width / 2 + Math.sin(t * Math.PI * 2) * fr.width * 0.15,
                        y: fr.y + fr.height * (1 - t)
                    };
                }
                return {
                    x: fr.x + fr.width * t,
                    y: fr.y + fr.height / 2 + Math.sin(t * Math.PI * 2) * fr.height * 0.15
                };
            }

            function drawComet(headT, tailT) {
                if (headT < 0 || headT > 1) {
                    return;
                }
                const head = pathPoint(headT);
                const tail = pathPoint(Math.max(0, Math.min(1, tailT)));

                if (Math.abs(head.x - tail.x) + Math.abs(head.y - tail.y) > 1) {
                    const gradient = ctx.createLinearGradient(tail.x, tail.y, head.x, head.y);
                    gradient.addColorStop(0, "rgba(255,255,255,0)");
                    gradient.addColorStop(0.6, "rgba(255,255,255,0.20)");
                    gradient.addColorStop(1, "rgba(255,255,255,0.65)");
                    ctx.strokeStyle = gradient;
                    ctx.lineWidth = Math.max(1.2, shortSide * 0.09);
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.moveTo(tail.x, tail.y);
                    ctx.lineTo(head.x, head.y);
                    ctx.stroke();
                }

                const glow = ctx.createRadialGradient(head.x, head.y, 0,
                    head.x, head.y, glowRadius);
                glow.addColorStop(0, "rgba(255,255,255,0.85)");
                glow.addColorStop(0.35, "rgba(255,255,255,0.30)");
                glow.addColorStop(1, "rgba(255,255,255,0)");
                ctx.fillStyle = glow;
                ctx.beginPath();
                ctx.arc(head.x, head.y, glowRadius, 0, Math.PI * 2);
                ctx.fill();
            }

            drawComet(twinCanvas.progress, twinCanvas.progress - trail);
            drawComet(1 - twinCanvas.progress, 1 - twinCanvas.progress + trail);

            ctx.restore();
        }
    }

    // Snake: a persistent wavy trail that turns around at the edges.
    Canvas {
        id: snakeCanvas

        objectName: "snakeCanvas"
        anchors.fill: body
        visible: root.snakeAnim
        z: 2

        property real phase: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: snakeCanvas.visible
            onTriggered: {
                snakeCanvas.phase += 0.030;
                snakeCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const fr = root.fillRect;
            if (!root.snakeAnim || fr.width <= 1 || fr.height <= 1) {
                return;
            }

            ctx.save();
            root.clipToFill(ctx);

            const shortSide = root.vertical ? fr.width : fr.height;
            const headT = 0.5 - 0.5 * Math.cos(snakeCanvas.phase);
            const dir = Math.sin(snakeCanvas.phase) >= 0 ? 1 : -1;
            const count = 20;

            function snakePoint(t) {
                const p = Math.max(0, Math.min(1, t));
                if (root.vertical) {
                    return {
                        x: fr.x + fr.width / 2 + Math.sin(p * Math.PI * 2.4) * fr.width * 0.28,
                        y: fr.y + fr.height * (1 - p)
                    };
                }
                return {
                    x: fr.x + fr.width * p,
                    y: fr.y + fr.height / 2 + Math.sin(p * Math.PI * 2.4) * fr.height * 0.28
                };
            }

            const head = snakePoint(headT);
            let previous = head;
            for (let i = 1; i <= count; i++) {
                const point = snakePoint(headT - dir * i * 0.014);
                const strength = 1 - i / (count + 1);
                ctx.beginPath();
                ctx.moveTo(previous.x, previous.y);
                ctx.lineTo(point.x, point.y);
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.05 + 0.55 * strength * strength);
                ctx.lineWidth = Math.max(1, shortSide * (0.05 + 0.07 * strength));
                ctx.lineCap = "round";
                ctx.stroke();
                previous = point;
            }

            const glowRadius = Math.max(2.2, shortSide * 0.30);
            const glow = ctx.createRadialGradient(head.x, head.y, 0,
                head.x, head.y, glowRadius);
            glow.addColorStop(0, "rgba(255,255,255,0.85)");
            glow.addColorStop(0.35, "rgba(255,255,255,0.28)");
            glow.addColorStop(1, "rgba(255,255,255,0)");
            ctx.fillStyle = glow;
            ctx.beginPath();
            ctx.arc(head.x, head.y, glowRadius, 0, Math.PI * 2);
            ctx.fill();

            ctx.restore();
        }
    }

    // Orbit: glowing electrons circling inside the fill.
    Canvas {
        id: orbitCanvas

        objectName: "orbitCanvas"
        anchors.fill: body
        visible: root.orbitAnim
        z: 2

        property real phase: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: orbitCanvas.visible
            onTriggered: {
                orbitCanvas.phase += 0.030;
                orbitCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const fr = root.fillRect;
            if (!root.orbitAnim || fr.width <= 1 || fr.height <= 1) {
                return;
            }

            ctx.save();
            root.clipToFill(ctx);

            const cx = fr.x + fr.width / 2;
            const cy = fr.y + fr.height / 2;
            const rx = fr.width * 0.34;
            const ry = fr.height * 0.32;
            const shortSide = Math.min(fr.width, fr.height);

            ctx.save();
            ctx.translate(cx, cy);
            ctx.scale(1, ry / rx);
            ctx.beginPath();
            ctx.arc(0, 0, rx, 0, Math.PI * 2);
            ctx.strokeStyle = "rgba(255,255,255,0.10)";
            ctx.lineWidth = Math.max(0.8, shortSide * 0.02);
            ctx.stroke();
            ctx.restore();

            const glowRadius = Math.max(2, shortSide * 0.30);
            for (let k = 0; k < 3; k++) {
                const angle = orbitCanvas.phase + k * Math.PI * 2 / 3;
                const x = cx + Math.cos(angle) * rx;
                const y = cy + Math.sin(angle) * ry;
                const glow = ctx.createRadialGradient(x, y, 0, x, y, glowRadius);
                glow.addColorStop(0, "rgba(255,255,255,0.85)");
                glow.addColorStop(0.35, "rgba(255,255,255,0.28)");
                glow.addColorStop(1, "rgba(255,255,255,0)");
                ctx.fillStyle = glow;
                ctx.beginPath();
                ctx.arc(x, y, glowRadius, 0, Math.PI * 2);
                ctx.fill();
            }

            ctx.restore();
        }
    }

    // Spiral: a light point opens outwards from the center in a spiral.
    Canvas {
        id: spiralCanvas

        objectName: "spiralCanvas"
        anchors.fill: body
        visible: root.spiralAnim
        z: 2

        property real phase: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: spiralCanvas.visible
            onTriggered: {
                spiralCanvas.phase = (spiralCanvas.phase + 0.020) % 1;
                spiralCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const fr = root.fillRect;
            if (!root.spiralAnim || fr.width <= 1 || fr.height <= 1) {
                return;
            }

            ctx.save();
            root.clipToFill(ctx);

            const cx = fr.x + fr.width / 2;
            const cy = fr.y + fr.height / 2;
            const rx = fr.width * 0.44;
            const ry = fr.height * 0.42;
            const shortSide = Math.min(fr.width, fr.height);
            const headT = spiralCanvas.phase;

            function spiralPoint(t) {
                const p = Math.max(0, Math.min(1, t));
                const angle = p * Math.PI * 4.4;
                return {
                    x: cx + Math.cos(angle) * rx * p,
                    y: cy + Math.sin(angle) * ry * p
                };
            }

            const head = spiralPoint(headT);
            let previous = head;
            for (let i = 1; i <= 22; i++) {
                const point = spiralPoint(headT - i * 0.010);
                const strength = 1 - i / 23;
                ctx.beginPath();
                ctx.moveTo(previous.x, previous.y);
                ctx.lineTo(point.x, point.y);
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.06 + 0.50 * strength * strength);
                ctx.lineWidth = Math.max(1, shortSide * (0.05 + 0.06 * strength));
                ctx.lineCap = "round";
                ctx.stroke();
                previous = point;
            }

            const glowRadius = Math.max(2, shortSide * 0.28);
            const glow = ctx.createRadialGradient(head.x, head.y, 0,
                head.x, head.y, glowRadius);
            glow.addColorStop(0, "rgba(255,255,255,0.85)");
            glow.addColorStop(0.4, "rgba(255,255,255,0.25)");
            glow.addColorStop(1, "rgba(255,255,255,0)");
            ctx.fillStyle = glow;
            ctx.beginPath();
            ctx.arc(head.x, head.y, glowRadius, 0, Math.PI * 2);
            ctx.fill();

            ctx.restore();
        }
    }

    // Pendulum: a glowing bob swings across the fill with a short trail.
    Canvas {
        id: pendulumCanvas

        objectName: "pendulumCanvas"
        anchors.fill: body
        visible: root.pendulumAnim
        z: 2

        property real phase: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: pendulumCanvas.visible
            onTriggered: {
                pendulumCanvas.phase += 0.045;
                pendulumCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const fr = root.fillRect;
            if (!root.pendulumAnim || fr.width <= 1 || fr.height <= 1) {
                return;
            }

            ctx.save();
            root.clipToFill(ctx);

            const cx = fr.x + fr.width / 2;
            const pivotY = fr.y + fr.height * 0.14;
            const length = fr.height * 0.80;
            const maxAngle = 0.85;
            const shortSide = Math.min(fr.width, fr.height);

            function bobPoint(p) {
                const a = Math.sin(p) * maxAngle;
                return {
                    x: cx + Math.sin(a) * length,
                    y: pivotY + Math.cos(a) * length
                };
            }

            const head = bobPoint(pendulumCanvas.phase);

            // Rod.
            ctx.beginPath();
            ctx.moveTo(cx, pivotY);
            ctx.lineTo(head.x, head.y);
            ctx.strokeStyle = "rgba(255,255,255,0.12)";
            ctx.lineWidth = Math.max(0.8, shortSide * 0.03);
            ctx.stroke();

            // Trail.
            for (let k = 8; k >= 1; k--) {
                const point = bobPoint(pendulumCanvas.phase - k * 0.075);
                const strength = 1 - k / 9;
                ctx.beginPath();
                ctx.arc(point.x, point.y,
                    Math.max(1, shortSide * (0.05 + 0.10 * strength)),
                    0, Math.PI * 2);
                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.05 + 0.35 * strength * strength);
                ctx.fill();
            }

            const glowRadius = Math.max(2.2, shortSide * 0.30);
            const glow = ctx.createRadialGradient(head.x, head.y, 0,
                head.x, head.y, glowRadius);
            glow.addColorStop(0, "rgba(255,255,255,0.85)");
            glow.addColorStop(0.4, "rgba(255,255,255,0.25)");
            glow.addColorStop(1, "rgba(255,255,255,0)");
            ctx.fillStyle = glow;
            ctx.beginPath();
            ctx.arc(head.x, head.y, glowRadius, 0, Math.PI * 2);
            ctx.fill();

            ctx.restore();
        }
    }

    // Scanner: a thin bright line sweeps the fill back and forth.
    Canvas {
        id: scannerCanvas

        objectName: "scannerCanvas"
        anchors.fill: body
        visible: root.scannerAnim
        z: 2

        property real phase: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 40
            repeat: true
            running: scannerCanvas.visible
            onTriggered: {
                scannerCanvas.phase += 0.035;
                scannerCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const fr = root.fillRect;
            if (!root.scannerAnim || fr.width <= 1 || fr.height <= 1) {
                return;
            }

            ctx.save();
            root.clipToFill(ctx);

            const t = 0.5 - 0.5 * Math.cos(scannerCanvas.phase);
            const span = root.vertical ? fr.height : fr.width;
            const band = Math.max(3, span * 0.06);
            const shortSide = root.vertical ? fr.width : fr.height;

            if (root.vertical) {
                const y = fr.y + fr.height * (1 - t);
                const gradient = ctx.createLinearGradient(0, y - band, 0, y + band);
                gradient.addColorStop(0, "rgba(255,255,255,0)");
                gradient.addColorStop(0.5, "rgba(255,255,255,0.28)");
                gradient.addColorStop(1, "rgba(255,255,255,0)");
                ctx.fillStyle = gradient;
                ctx.fillRect(fr.x, y - band, fr.width, band * 2);

                ctx.beginPath();
                ctx.moveTo(fr.x, y);
                ctx.lineTo(fr.x + fr.width, y);
            } else {
                const x = fr.x + fr.width * t;
                const gradient = ctx.createLinearGradient(x - band, 0, x + band, 0);
                gradient.addColorStop(0, "rgba(255,255,255,0)");
                gradient.addColorStop(0.5, "rgba(255,255,255,0.28)");
                gradient.addColorStop(1, "rgba(255,255,255,0)");
                ctx.fillStyle = gradient;
                ctx.fillRect(x - band, fr.y, band * 2, fr.height);

                ctx.beginPath();
                ctx.moveTo(x, fr.y);
                ctx.lineTo(x, fr.y + fr.height);
            }

            ctx.strokeStyle = "rgba(255,255,255,0.75)";
            ctx.lineWidth = Math.max(1, shortSide * 0.05);
            ctx.shadowColor = "#ffffff";
            ctx.shadowBlur = Math.max(3, shortSide * 0.4);
            ctx.stroke();

            ctx.restore();
        }
    }

    // Twin neon: two points of light travel around the outline, opposite
    // each other.
    Canvas {
        id: neonTwinCanvas

        objectName: "neonTwinCanvas"
        anchors.fill: body
        visible: root.neonTwinAnim
        z: 2

        property real progress: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: neonTwinCanvas.visible
            onTriggered: {
                neonTwinCanvas.progress = (neonTwinCanvas.progress + 0.018) % 1;
                neonTwinCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.neonTwinAnim || width <= 2 || height <= 2) {
                return;
            }

            function drawHead(t) {
                for (let k = 7; k >= 0; k--) {
                    const point = root.perimeterPoint(t - k * 0.016);
                    const strength = 1 - k / 8;
                    ctx.beginPath();
                    ctx.arc(point.x, point.y,
                        Math.max(1, body.lineWidth * (0.45 + 0.75 * strength)),
                        0, Math.PI * 2);
                    ctx.fillStyle = Qt.rgba(1, 1, 1, 0.08 + 0.52 * strength * strength);
                    ctx.fill();
                }

                const head = root.perimeterPoint(t);
                const glowRadius = Math.max(2, body.lineWidth * 2.4);
                const glow = ctx.createRadialGradient(head.x, head.y, 0,
                    head.x, head.y, glowRadius);
                glow.addColorStop(0, "rgba(255,255,255,0.85)");
                glow.addColorStop(0.4, "rgba(255,255,255,0.30)");
                glow.addColorStop(1, "rgba(255,255,255,0)");
                ctx.fillStyle = glow;
                ctx.beginPath();
                ctx.arc(head.x, head.y, glowRadius, 0, Math.PI * 2);
                ctx.fill();
            }

            drawHead(neonTwinCanvas.progress);
            drawHead(neonTwinCanvas.progress + 0.5);
        }
    }

    // Neon wave: a lit segment of the outline travels around the body.
    Canvas {
        id: neonWaveCanvas

        objectName: "neonWaveCanvas"
        anchors.fill: body
        visible: root.neonWaveAnim
        z: 2

        property real progress: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: neonWaveCanvas.visible
            onTriggered: {
                neonWaveCanvas.progress = (neonWaveCanvas.progress + 0.012) % 1;
                neonWaveCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.neonWaveAnim || width <= 2 || height <= 2) {
                return;
            }

            const span = 0.20;
            const samples = 26;
            let previous = root.perimeterPoint(neonWaveCanvas.progress - span);

            for (let i = 1; i <= samples; i++) {
                const t = neonWaveCanvas.progress - span + span * i / samples;
                const point = root.perimeterPoint(t);
                const strength = i / samples;

                ctx.beginPath();
                ctx.moveTo(previous.x, previous.y);
                ctx.lineTo(point.x, point.y);
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.04 + 0.62 * strength * strength);
                ctx.lineWidth = Math.max(1.4, body.lineWidth * (0.9 + 1.1 * strength));
                ctx.lineCap = "round";
                ctx.stroke();
                previous = point;
            }

            const head = root.perimeterPoint(neonWaveCanvas.progress);
            const glowRadius = Math.max(2, body.lineWidth * 2.6);
            const glow = ctx.createRadialGradient(head.x, head.y, 0,
                head.x, head.y, glowRadius);
            glow.addColorStop(0, "rgba(255,255,255,0.85)");
            glow.addColorStop(0.4, "rgba(255,255,255,0.28)");
            glow.addColorStop(1, "rgba(255,255,255,0)");
            ctx.fillStyle = glow;
            ctx.beginPath();
            ctx.arc(head.x, head.y, glowRadius, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    // Perimeter bolt: a small zigzag lightning travels around the outline.
    Canvas {
        id: neonBoltCanvas

        objectName: "neonBoltCanvas"
        anchors.fill: body
        visible: root.neonBoltAnim
        z: 2

        property real progress: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: neonBoltCanvas.visible
            onTriggered: {
                neonBoltCanvas.progress = (neonBoltCanvas.progress + 0.016) % 1;
                neonBoltCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.neonBoltAnim || width <= 2 || height <= 2) {
                return;
            }

            const head = root.perimeterPoint(neonBoltCanvas.progress);
            const behind = root.perimeterPoint(neonBoltCanvas.progress - 0.004);
            let tx = head.x - behind.x;
            let ty = head.y - behind.y;
            const length = Math.max(1, Math.sqrt(tx * tx + ty * ty));
            tx /= length;
            ty /= length;
            const px = -ty;
            const py = tx;

            const boltLength = Math.max(4, body.thickness * 1.1);
            const boltWidth = Math.max(2, body.thickness * 0.35);
            const points = [
                [-0.5, 0],
                [-0.18, 1],
                [0.10, -1],
                [0.5, 0]
            ];

            ctx.beginPath();
            for (let i = 0; i < points.length; i++) {
                const along = points[i][0] * boltLength;
                const side = points[i][1] * boltWidth * 0.5;
                const x = head.x + tx * along + px * side;
                const y = head.y + ty * along + py * side;
                if (i === 0) {
                    ctx.moveTo(x, y);
                } else {
                    ctx.lineTo(x, y);
                }
            }

            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.shadowColor = "#cfefff";
            ctx.shadowBlur = Math.max(3, body.thickness * 0.5);

            ctx.lineWidth = Math.max(2, body.thickness * 0.16);
            ctx.strokeStyle = "rgba(200,240,255,0.30)";
            ctx.stroke();

            ctx.lineWidth = Math.max(1, body.thickness * 0.06);
            ctx.strokeStyle = "rgba(255,255,255,0.90)";
            ctx.stroke();

            ctx.shadowBlur = 0;
        }
    }

    // Neon spin: a rotating band of light runs around the whole outline.
    Canvas {
        id: neonSpinCanvas

        objectName: "neonSpinCanvas"
        anchors.fill: body
        visible: root.neonSpinAnim
        z: 2

        property real phase: 0

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 45
            repeat: true
            running: neonSpinCanvas.visible
            onTriggered: {
                neonSpinCanvas.phase += 0.030;
                neonSpinCanvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.neonSpinAnim || width <= 2 || height <= 2) {
                return;
            }

            // Faint base outline so the whole body is always visible.
            ctx.beginPath();
            for (let i = 0; i <= 64; i++) {
                const point = root.perimeterPoint(i / 64);
                if (i === 0) {
                    ctx.moveTo(point.x, point.y);
                } else {
                    ctx.lineTo(point.x, point.y);
                }
            }
            ctx.strokeStyle = "rgba(255,255,255,0.10)";
            ctx.lineWidth = Math.max(1, body.lineWidth * 1.1);
            ctx.stroke();

            const segments = 96;
            for (let i = 0; i < segments; i++) {
                const t0 = i / segments;
                const t1 = (i + 1) / segments;
                const a = t0 * Math.PI * 2;
                const wave = Math.pow(0.5 + 0.5 * Math.cos(a * 1.0 - neonSpinCanvas.phase), 3);
                const point = root.perimeterPoint(t0);
                const next = root.perimeterPoint(t1);

                ctx.beginPath();
                ctx.moveTo(point.x, point.y);
                ctx.lineTo(next.x, next.y);
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.05 + 0.70 * wave);
                ctx.lineWidth = Math.max(1, body.lineWidth * (0.9 + 1.4 * wave));
                ctx.lineCap = "round";
                ctx.stroke();
            }
        }
    }

    // 100 % celebration: central flash and sparks flying outwards.
    Canvas {
        id: celebrationCanvas

        objectName: "celebrationCanvas"
        anchors.fill: body
        visible: root.celebrating
        z: 2

        onVisibleChanged: if (visible) requestPaint()

        Timer {
            interval: 40
            repeat: true
            running: celebrationCanvas.visible
            onTriggered: {
                root.celebrationProgress += 0.030;
                if (root.celebrationProgress >= 1) {
                    root.celebrating = false;
                    root.celebrationProgress = 0;
                } else {
                    celebrationCanvas.requestPaint();
                }
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.celebrating || width <= 2 || height <= 2) {
                return;
            }

            const progress = Math.max(0, Math.min(1, root.celebrationProgress));
            const cx = width / 2;
            const cy = height / 2;
            const minSide = Math.min(width, height);
            const maxSide = Math.max(width, height);
            const fade = 1 - progress;

            // 1) Lit outline: noticeable from the very first frame even on
            // small batteries, because it runs around the whole perimeter.
            const inset = Math.max(0.8, body.lineWidth / 2);
            const ringFade = Math.max(0, 1 - progress * 2.2);
            if (ringFade > 0) {
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.62 * ringFade);
                ctx.lineWidth = Math.max(1.2, body.lineWidth * 1.5);
                ctx.beginPath();
                ctx.roundedRect(inset, inset, width - inset * 2, height - inset * 2,
                    Math.max(1, body.radius - inset), Math.max(1, body.radius - inset));
                ctx.stroke();
            }

            // 2) Light wash: a large flash covering most of the body from
            // the very first instant, fading out gradually.
            const flashRadius = Math.max(minSide * 0.42, maxSide * (0.34 + progress * 0.62));
            const flash = ctx.createRadialGradient(cx, cy, 0, cx, cy, flashRadius);
            flash.addColorStop(0, Qt.rgba(1, 1, 1, 0.68 * fade));
            flash.addColorStop(0.45, Qt.rgba(1, 1, 1, 0.38 * fade));
            flash.addColorStop(0.78, Qt.rgba(root.tintColor.r, root.tintColor.g,
                root.tintColor.b, 0.30 * fade));
            flash.addColorStop(1, Qt.rgba(root.tintColor.r, root.tintColor.g,
                root.tintColor.b, 0));
            ctx.fillStyle = flash;
            ctx.beginPath();
            ctx.arc(cx, cy, flashRadius, 0, Math.PI * 2);
            ctx.fill();

            // 3) Shockwave: a ring expanding from the center and fading out.
            const waveT = Math.min(1, progress / 0.62);
            if (waveT < 1) {
                const waveRadius = minSide * (0.20 + waveT * 1.15);
                const waveFade = (1 - waveT) * (1 - waveT);
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.70 * waveFade);
                ctx.lineWidth = Math.max(1.1, minSide * 0.09 * (1 - waveT) + 0.6);
                ctx.beginPath();
                ctx.arc(cx, cy, waveRadius, 0, Math.PI * 2);
                ctx.stroke();
            }

            // 4) Radial sparks with trails.
            const count = 18;
            const reach = maxSide * 0.62;
            ctx.lineCap = "round";
            for (let i = 0; i < count; i++) {
                const angle = (i / count) * Math.PI * 2 + 0.18;
                const speed = 0.55 + ((i * 37) % 100) / 160;
                const distance = progress * reach * speed;
                const px = cx + Math.cos(angle) * distance;
                const py = cy + Math.sin(angle) * distance * 0.72;
                const tail = Math.max(1.4, minSide * 0.16 * (1 - progress * 0.5));
                const tx = px - Math.cos(angle) * tail;
                const ty = py - Math.sin(angle) * tail * 0.72;
                const alpha = Math.max(0, fade * (0.45 + 0.45 * ((i * 13) % 100) / 100));

                ctx.strokeStyle = Qt.rgba(1, 1, 1, alpha);
                ctx.lineWidth = Math.max(0.9, minSide * 0.05);
                ctx.beginPath();
                ctx.moveTo(tx, ty);
                ctx.lineTo(px, py);
                ctx.stroke();

                // Bright tip of the spark.
                ctx.fillStyle = Qt.rgba(1, 1, 1, Math.min(1, alpha * 1.25));
                ctx.beginPath();
                ctx.arc(px, py, Math.max(0.8, minSide * 0.035), 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }
}
