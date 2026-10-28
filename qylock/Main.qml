import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

// Clockwork Theme
Rectangle {
    id: root
    readonly property real s: Screen.height / 768
    width: Screen.width
    height: Screen.height
    color: root.bgColor

    // Theme Config
    // theme.conf:  themeMode=dark|light   glow=true|false
    readonly property string themeMode: config.themeMode || "dark"
    readonly property bool enableWindup: config.enableWindup === "true"
    readonly property bool enableGlow: config.glow !== "false"
    readonly property bool isLight: themeMode === "light"

    // ------------------------------------------------------------------
    // CYBERPUNK 2077 PALETTE (exact swatches)
    //   Black     #000000
    //   Yellow    #f3e600  -> hours, weekday, all ticks
    //   Red       #c5003c  -> numbers, date, active tick, stars, input, errors
    //   Dark red  #880425  -> borders, inactive / idle text
    // ------------------------------------------------------------------
    readonly property color bgColor:   isLight ? "#f6f2d4" : "#000000"
    readonly property color mainText:  isLight ? "#14120a" : "#f3e600"
    readonly property color dimText:   isLight ? "#880425" : "#c5003c"
    readonly property color subColor:  isLight ? "#880425" : "#c5003c"
    readonly property color accentMin: isLight ? "#8a8200" : "#f3e600"   // ticks
    readonly property color accentSec: isLight ? "#880425" : "#c5003c"   // input / pill glow
    readonly property color accentNum: isLight ? "#880425" : "#c5003c"   // ring numbers
    readonly property color accentHot: isLight ? "#c5003c" : "#c5003c"   // active tick / danger
    readonly property color pillColor: isLight ? "#ebe6c0" : "#000000"
    readonly property color pillBorder: isLight ? (root.isWindup ? "#c5003c" : "#bdb35a")
                                                : (root.isWindup ? "#c5003c" : "#880425")
    readonly property color pillInnerLine: root.isWindup ? root.mainText : root.accentSec
    readonly property color sparkColor: root.accentMin
    readonly property color blastColor: root.accentHot
    readonly property color userItemInactive: isLight ? "#a39b52" : "#880425"
    readonly property color inputWaitColor:   isLight ? "#8a8240" : "#880425"

    // Helper: same colour, different alpha
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // State Props
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (userModel && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property bool userMenuOpen: false
    property bool isWindup: false
    property real uiOpacity: 0
    readonly property real marginR: 80 * s

    // Time Engine
    property int curH: new Date().getHours()
    property int curM: new Date().getMinutes()
    property int curS: new Date().getSeconds()
    property int curMS: new Date().getMilliseconds()
    readonly property real localTimeMS: (curH * 3600000) + (curM * 60000) + (curS * 1000) + curMS

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            var d = new Date()
            root.curH = d.getHours()
            root.curM = d.getMinutes()
            root.curS = d.getSeconds()
            root.curMS = d.getMilliseconds()
        }
    }

    // Blast Engine
    property real windupOffset: 0
    property real windupProgress: windupOffset / 150000
    property real boomScale: 1.0
    property real boomOpacity: 0.0
    property real jitterX: 0
    property real jitterY: 0
    property real sparkIntensity: 0.0

    Timer {
        interval: 16
        running: root.isWindup
        repeat: true
        onTriggered: {
            var intensity = root.windupProgress * 32 * s
            root.jitterX = (Math.random() - 0.5) * intensity
            root.jitterY = (Math.random() - 0.5) * intensity
            root.sparkIntensity = root.windupProgress > 0.2 ? (root.windupProgress - 0.2) * 2.2 : 0
        }
    }

    NumberAnimation {
        id: windupAnim
        target: root
        property: "windupOffset"
        from: 0
        to: 150000
        duration: 1600
        easing.type: Easing.InQuint
    }

    ParallelAnimation {
        id: boomSequence
        NumberAnimation {
            target: root
            property: "boomScale"
            to: 35.0
            duration: 150
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "boomOpacity"
            to: 1.0
            duration: 120
            easing.type: Easing.InQuad
        }
    }

    readonly property real smoothSecAngle: -((localTimeMS % 60000) / 60000.0) * 360.0 - windupOffset * 10.0
    readonly property real smoothMinAngle: -((localTimeMS % 3600000) / 3600000.0) * 360.0 - windupOffset * 5.0

    // Assets
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }
    FontLoader {
        id: outfitFont
        source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : ""
    }
    TextConstants {
        id: textConstants
    }

    // Bridges
    ListView {
        id: userHelper
        model: userModel
        currentIndex: root.userIndex
        width: 1
        height: 1
        opacity: 0
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }
    ListView {
        id: sessionHelper
        model: sessionModel
        currentIndex: root.sessionIndex
        width: 1
        height: 1
        opacity: 0
        delegate: Item {
            property string sName: model.name || ""
        }
    }

    // Autofocus
    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }

    Component.onCompleted: {
        fadeIn.start()
    }
    NumberAnimation {
        id: fadeIn
        target: root
        property: "uiOpacity"
        to: 1
        duration: 350
        easing.type: Easing.OutCubic
    }

    // CORE CLOCKWORK
    Item {
        id: blastContainer
        anchors.fill: parent
        opacity: root.uiOpacity
        x: root.jitterX
        y: root.jitterY
        transform: Scale {
            origin.x: 400 * s
            origin.y: parent.height * 0.5
            xScale: root.boomScale
            yScale: root.boomScale
        }

        Item {
            id: clockContainer
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 800 * s
            height: parent.height
            readonly property real cx: 40 * s
            readonly property real cy: height * 0.5
            readonly property real minR: 320 * s
            readonly property real secR: 480 * s

            Rectangle {
                id: indicatorPill
                z: 1
                x: clockContainer.cx + 230 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 330 * s
                height: 90 * s
                radius: 45 * s
                color: root.pillColor
                border.color: root.pillBorder
                border.width: 1 * s
                Rectangle {
                    x: 170 * s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1 * s
                    height: 35 * s
                    color: root.pillInnerLine
                }
            }

            // Pill glow (dark mode only)
            Glow {
                z: 0
                anchors.fill: indicatorPill
                source: indicatorPill
                radius: 14 * s
                samples: 25
                spread: 0.05
                color: root.alpha(root.isWindup ? root.accentHot : root.accentSec, 0.35)
                transparentBorder: true
                visible: root.enableGlow && !root.isLight
            }

            Repeater {
                model: 60
                delegate: Rectangle {
                    z: 50
                    property real randA: Math.random() * 6.28
                    property real randV: 400 * s + Math.random() * 900 * s
                    x: (clockContainer.cx + 400 * s) + Math.cos(randA) * (randV * root.sparkIntensity)
                    y: (clockContainer.cy) + Math.sin(randA) * (randV * root.sparkIntensity)
                    width: (1 + Math.random() * 2) * s
                    height: (1 + 12 * root.sparkIntensity) * s
                    rotation: randA * 180 / Math.PI + 90
                    radius: width / 2
                    color: root.sparkColor
                    opacity: root.sparkIntensity * (Math.random() > 0.4 ? 1.0 : 0.2)
                    visible: root.sparkIntensity > 0
                }
            }

            // Minute ring
            Repeater {
                model: 60
                delegate: Item {
                    z: 10
                    property real base: index * 6
                    property real relAngle: {
                        var a = (base + root.smoothMinAngle) % 360
                        if (a > 180) a -= 360
                        if (a < -180) a += 360
                        return a
                    }
                    property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 4.0)
                    property bool isMajor: index % 5 == 0
                    property real disp: (base + root.smoothMinAngle) * Math.PI / 180
                    property real tx: clockContainer.cx + clockContainer.minR * Math.cos(disp)
                    property real ty: clockContainer.cy + clockContainer.minR * Math.sin(disp)
                    visible: tx > -600 * s && tx < 1800 * s
                    Rectangle {
                        x: parent.tx - width/2
                        y: parent.ty - height/2
                        width: isMajor ? 2 * s : 1 * s
                        height: isMajor ? 18 * s : 10 * s
                        color: spotlight > 0
                               ? root.alpha(root.accentHot, 0.95)
                               : root.alpha(root.accentMin, isMajor ? (isLight ? 0.85 : 1.0) : (isLight ? 0.45 : 0.7))
                        rotation: disp * 180 / Math.PI + 90
                    }
                    Text {
                        visible: isMajor
                        property real nRad: clockContainer.minR - 35 * s
                        x: clockContainer.cx + nRad * Math.cos(disp) - width/2
                        y: clockContainer.cy + nRad * Math.sin(disp) - height/2
                        text: String(index).padStart(2, '0')
                        font.family: outfitFont.name
                        font.pixelSize: 22 * s
                        font.weight: spotlight > 0.5 ? Font.Bold : Font.Normal
                        color: root.alpha(root.accentNum, spotlight > 0 ? 1.0 : 0.85)
                        rotation: disp * 180 / Math.PI
                        transformOrigin: Item.Center
                    }
                }
            }

            // Second ring
            Repeater {
                model: 60
                delegate: Item {
                    z: 10
                    property real base: index * 6
                    property real relAngle: {
                        var a = (base + root.smoothSecAngle) % 360
                        if (a > 180) a -= 360
                        if (a < -180) a += 360
                        return a
                    }
                    property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 4.0)
                    property bool isMajor: index % 5 == 0
                    property real disp: (base + root.smoothSecAngle) * Math.PI / 180
                    property real tx: clockContainer.cx + clockContainer.secR * Math.cos(disp)
                    property real ty: clockContainer.cy + clockContainer.secR * Math.sin(disp)
                    visible: tx > -600 * s && tx < 1800 * s
                    Rectangle {
                        x: parent.tx - width/2
                        y: parent.ty - height/2
                        width: isMajor ? 1.5 * s : 1 * s
                        height: isMajor ? 13 * s : 8 * s
                        color: spotlight > 0
                               ? root.alpha(root.accentHot, 0.95)
                               : root.alpha(root.accentMin, isMajor ? (isLight ? 0.85 : 1.0) : (isLight ? 0.45 : 0.7))
                        rotation: disp * 180 / Math.PI + 90
                    }
                    Text {
                        visible: isMajor
                        property real nRad: clockContainer.secR - 30 * s
                        x: clockContainer.cx + nRad * Math.cos(disp) - width/2
                        y: clockContainer.cy + nRad * Math.sin(disp) - height/2
                        text: String(index).padStart(2, '0')
                        font.family: outfitFont.name
                        font.pixelSize: 16 * s
                        font.weight: spotlight > 0.5 ? Font.Bold : Font.Normal
                        color: root.alpha(root.accentNum, spotlight > 0 ? 1.0 : 0.85)
                        rotation: disp * 180 / Math.PI
                        transformOrigin: Item.Center
                    }
                }
            }

            Text {
                id: hourText
                anchors.right: indicatorPill.left
                anchors.rightMargin: 40 * s
                anchors.verticalCenter: parent.verticalCenter
                text: String(root.curH).padStart(2, '0')
                font.family: outfitFont.name
                font.pixelSize: 110 * s
                font.weight: Font.Black
                color: root.mainText
            }
            // Hour glow (dark mode only)
            Glow {
                anchors.fill: hourText
                source: hourText
                radius: 12 * s
                samples: 25
                spread: 0.1
                color: root.alpha(root.accentMin, 0.45)
                transparentBorder: true
                visible: root.enableGlow && !root.isLight
            }
            Column {
                anchors.left: indicatorPill.right
                anchors.leftMargin: 110 * s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5 * s
                Text {
                    text: Qt.formatDate(new Date(), "dd MMM yyyy").toUpperCase()
                    font.family: outfitFont.name
                    font.pixelSize: 13 * s
                    font.letterSpacing: 4 * s
                    color: root.subColor
                }
                Text {
                    text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                    font.family: outfitFont.name
                    font.pixelSize: 18 * s
                    font.letterSpacing: 8 * s
                    font.weight: Font.Bold
                    color: root.mainText
                }
            }
        }
    }

    // Glitch blast (replaces the solid whiteout)
    // Re-rolls a flickering base colour + random horizontal slices every 35ms.
    // Edit glitchColors to change which colours appear.
    Item {
        id: glitchLayer
        anchors.fill: parent
        z: 9999
        visible: root.boomOpacity > 0

        property var glitchColors: ["#f3e600", "#c5003c", "#880425", '#f800db', '#000000']
        property color baseColor: "#000000"

        function pick() {
            return glitchColors[Math.floor(Math.random() * glitchColors.length)]
        }
        function reroll() {
            baseColor = pick()
            for (var i = 0; i < bars.count; i++) {
                var b = bars.itemAt(i)
                if (!b) continue
                b.height = (1 + Math.random() * 15) * root.s
                b.width = glitchLayer.width * (0.5 + Math.random() * 0.9)
                b.x = (Math.random() - 0.5) * 300 * root.s
                b.y = Math.random() * glitchLayer.height
                b.color = pick()
                b.visible = Math.random() > 0.2
            }
        }

        Timer {
            interval: 35
            repeat: true
            running: glitchLayer.visible
            triggeredOnStart: true
            onTriggered: glitchLayer.reroll()
        }

        Rectangle {
            anchors.fill: parent
            color: glitchLayer.baseColor
        }
        Repeater {
            id: bars
            model: 100
            delegate: Rectangle { }
        }
    }

    // State HUD
    Item {
        id: hudContainer
        anchors.fill: parent
        opacity: root.uiOpacity * (root.boomOpacity > 0 ? 0 : 1)
        Row {
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            anchors.top: parent.top
            anchors.topMargin: 50 * s
            spacing: 25 * s
            CwAction {
                label: (sessionHelper.currentItem ? sessionHelper.currentItem.sName : "Session")
                onClicked: {
                    root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                }
            }
            Rectangle {
                width: 1 * s
                height: 10 * s
                color: root.pillBorder
                anchors.verticalCenter: parent.verticalCenter
            }
            CwAction {
                label: "Reboot"
                onClicked: {
                    sddm.reboot()
                }
            }
            Rectangle {
                width: 1 * s
                height: 10 * s
                color: root.pillBorder
                anchors.verticalCenter: parent.verticalCenter
            }
            CwAction {
                label: "Shutdown"
                onClicked: {
                    sddm.powerOff()
                }
            }
        }
        Column {
            id: loginPanel
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 80 * s
            width: 350 * s
            spacing: 8 * s
            Item {
                width: parent.width
                height: 32 * s
                z: 5000
                Item {
                    id: uMenuContainer
                    anchors.bottom: userNameDisp.top
                    anchors.bottomMargin: 15 * s
                    anchors.right: parent.right
                    width: 280 * s
                    height: root.userMenuOpen ? (userModel.rowCount() * 30 * s) + 20 * s : 0
                    clip: true
                    Behavior on height {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutExpo
                        }
                    }
                    Column {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        spacing: 6 * s
                        Repeater {
                            model: userModel
                            delegate: Item {
                                width: 260 * s
                                height: 26 * s
                                property bool itemHover: uItemMa.containsMouse
                                Text {
                                    id: uItemTxt
                                    text: (model.realName || model.name || "").toUpperCase()
                                    font.family: outfitFont.name
                                    font.pixelSize: 13 * s
                                    font.letterSpacing: 2 * s
                                    color: (root.userIndex === index || itemHover) ? root.mainText : root.userItemInactive
                                    anchors.right: parent.right
                                    anchors.rightMargin: itemHover ? 30 * s : 10 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on anchors.rightMargin {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                Text {
                                    text: "✦"
                                    anchors.left: uItemTxt.right
                                    anchors.leftMargin: 8 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.accentHot
                                    opacity: itemHover ? 1.0 : 0
                                    font.pixelSize: 10 * s
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                MouseArea {
                                    id: uItemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.userIndex = index
                                        root.userMenuOpen = false
                                    }
                                }
                            }
                        }
                    }
                }
                Text {
                    id: userNameDisp
                    anchors.right: parent.right
                    anchors.rightMargin: (uMa.containsMouse || root.userMenuOpen) ? 25 * s : 0
                    text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser ? capitalizeFirst(userModel.lastUser) : "USER")).toUpperCase()
                    font.family: outfitFont.name
                    font.pixelSize: 18 * s
                    font.weight: Font.Bold
                    font.letterSpacing: 8 * s
                    color: (uMa.containsMouse || root.userMenuOpen) ? root.mainText : root.dimText
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                    Behavior on anchors.rightMargin {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Text {
                    text: "✦"
                    anchors.left: userNameDisp.right
                    anchors.leftMargin: 8 * s
                    anchors.verticalCenter: userNameDisp.verticalCenter
                    color: root.accentHot
                    opacity: (uMa.containsMouse || root.userMenuOpen) ? 1.0 : 0
                    font.pixelSize: 12 * s
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
                MouseArea {
                    id: uMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.userMenuOpen = !root.userMenuOpen
                    }
                }
            }
            Item {
                width: parent.width
                height: 30 * s
                TextInput {
                    id: passInput
                    anchors.fill: parent
                    echoMode: TextInput.Password
                    passwordCharacter: "✦"
                    color: root.accentSec
                    font.family: outfitFont.name
                    font.pixelSize: 14 * s
                    font.letterSpacing: 10 * s
                    horizontalAlignment: TextInput.AlignRight
                    verticalAlignment: TextInput.AlignVCenter
                    focus: true
                    property bool wasClicked: false
                    cursorVisible: false
                    cursorDelegate: Item { width: 0; height: 0 }
                    Keys.onReturnPressed: {
                        startLoginSequence()
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "WAITING FOR KEY"
                        font.family: outfitFont.name
                        font.pixelSize: 10 * s
                        font.letterSpacing: 4 * s
                        color: root.inputWaitColor

                        opacity: passInput.text.length === 0 ? 0.4 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                    Rectangle {
                        id: needleCursor
                        width: 1.5 * s
                        height: 12 * s
                        color: root.accentSec
                        anchors.verticalCenter: parent.verticalCenter
                        x: passInput.cursorRectangle.x
                        visible: passInput.focus && (passInput.text.length > 0 || passInput.wasClicked)

                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: needleCursor.visible
                            NumberAnimation { target: needleCursor; property: "opacity"; from: 1; to: 0.1; duration: 450 }
                            NumberAnimation { target: needleCursor; property: "opacity"; from: 0.1; to: 1; duration: 450 }
                        }
                    }
                }
                MouseArea {
                    id: pMa_FixedFinal_Simple
                    anchors.fill: parent
                    cursorShape: Qt.ArrowCursor
                    onClicked: {
                        passInput.forceActiveFocus()
                        passInput.wasClicked = true
                    }
                }
            }
            Item {
                width: parent.width
                height: 40 * s
                Text {
                    id: loginBtn
                    anchors.right: parent.right
                    anchors.rightMargin: btnMa.containsMouse ? 25 * s : 0
                    text: "ENTER KEY"
                    font.family: outfitFont.name
                    font.pixelSize: 11 * s
                    font.letterSpacing: 4 * s
                    font.weight: Font.Bold
                    color: passInput.text.length > 0 ? (btnMa.containsMouse ? root.mainText : root.dimText) : "transparent"
                    opacity: passInput.text.length > 0 ? 1.0 : 0
                    Behavior on anchors.rightMargin {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Text {
                    text: "✦"
                    anchors.left: loginBtn.right
                    anchors.leftMargin: 8 * s
                    anchors.verticalCenter: loginBtn.verticalCenter
                    color: root.accentHot
                    opacity: (btnMa.containsMouse && passInput.text.length > 0) ? 1.0 : 0
                    font.pixelSize: 10 * s
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
                MouseArea {
                    id: btnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        startLoginSequence()
                    }
                }
            }
            Text {
                id: errText
                width: parent.width
                horizontalAlignment: Text.AlignRight
                text: ""
                color: root.accentHot
                font.family: outfitFont.name
                font.pixelSize: 10 * s
                font.letterSpacing: 2 * s
            }
        }
    }

    Timer {
        id: boomTriggerTimer
        interval: 1520
        onTriggered: {
            boomSequence.start()
        }
    }
    Timer {
        id: loginCommitTimer
        interval: 1600
        onTriggered: {
            doLogin()
        }
    }
    function startLoginSequence() {
        if (passInput.text.length === 0) return
        if (root.enableWindup) {
            isWindup = true
            windupAnim.start()
            boomTriggerTimer.start()
            loginCommitTimer.start()
        } else {
            doLogin()
        }
    }
    function doLogin() {
        var uname = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : userModel.lastUser
        sddm.login(uname, passInput.text, root.sessionIndex)
    }
    function capitalizeFirst(str) {
        if (!str) return ""
        return str.charAt(0).toUpperCase() + str.slice(1)
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            isWindup = false
            windupAnim.stop()
            boomTriggerTimer.stop()
            loginCommitTimer.stop()
            root.windupOffset = 0
            root.boomScale = 1.0
            root.boomOpacity = 0.0
            root.sparkIntensity = 0
            errText.text = "ACCESS DENIED"
            passInput.text = ""
            passInput.forceActiveFocus()
            shake.start()
        }
    }
    SequentialAnimation {
        id: shake
        NumberAnimation {
            target: loginPanel
            property: "anchors.rightMargin"
            from: root.marginR
            to: root.marginR + 10 * s
            duration: 50
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: loginPanel
            property: "anchors.rightMargin"
            to: root.marginR - 10 * s
            duration: 50
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: loginPanel
            property: "anchors.rightMargin"
            to: root.marginR
            duration: 50
            easing.type: Easing.InOutSine
        }
    }
    component CwAction: Item {
        id: actItem
        width: actTxt.width + 20 * s
        height: 15 * s
        property string label: ""
        signal clicked()
        Text {
            id: actTxt
            anchors.right: parent.right
            anchors.rightMargin: actM.containsMouse ? 15 * s : 0
            text: label.toUpperCase()
            color: actM.containsMouse ? root.mainText : root.dimText
            font.family: outfitFont.name
            font.pixelSize: 10 * s
            font.letterSpacing: 3 * s
            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
            Behavior on anchors.rightMargin {
                NumberAnimation {
                    duration: 200
                }
            }
        }
        Text {
            text: "✦"
            anchors.left: actTxt.right
            anchors.leftMargin: 4 * s
            anchors.verticalCenter: actTxt.verticalCenter
            color: root.accentHot
            opacity: actM.containsMouse ? 1.0 : 0
            font.pixelSize: 8 * s
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }
        MouseArea {
            id: actM
            anchors.fill: parent
            onClicked: {
                actItem.clicked()
            }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
