import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

FocusScope {
    id: root

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 280 * Style.uiScaleRatio
    property real contentPreferredHeight: Math.ceil(card.implicitHeight + Style.marginM * 2)
    readonly property bool allowAttach: true

    anchors.fill: parent
    focus: visible

    readonly property var mainInst: pluginApi?.mainInstance ?? null
    readonly property bool isOnline: mainInst?.isOnline ?? false
    readonly property bool isChecking: mainInst?.isChecking ?? false
    readonly property bool isConnecting: mainInst?.isConnecting ?? false
    readonly property bool configured: (mainInst?.bearIp ?? "") !== ""

    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus();
            mainInst?.checkStatus();
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NBox {
                id: card
                Layout.fillWidth: true
                implicitHeight: Math.ceil(cardContent.implicitHeight + Style.marginM * 2)

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NIcon {
                            icon: "moon-stars"
                            color: Color.mPrimary
                            pointSize: Style.fontSizeL * 1.4
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            NText {
                                text: "Moonlight"
                                pointSize: Style.fontSizeL
                                font.bold: true
                                color: Color.mOnSurface
                            }

                            RowLayout {
                                spacing: Style.marginS

                                Rectangle {
                                    width: Math.round(6 * Style.uiScaleRatio)
                                    height: width
                                    radius: width / 2
                                    color: {
                                        if (!root.configured) return Qt.alpha(Color.mOnSurface, 0.3);
                                        if (root.isChecking) return Qt.alpha(Color.mOnSurface, 0.4);
                                        return root.isOnline ? "#4CAF50" : "#F44336";
                                    }
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 400 } }

                                    SequentialAnimation on opacity {
                                        running: root.isChecking
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.3; duration: 600 }
                                        NumberAnimation { to: 1.0; duration: 600 }
                                    }
                                }

                                NText {
                                    text: {
                                        if (!root.configured) return "Not configured";
                                        if (root.isChecking) return "Checking…";
                                        return root.isOnline ? "Bear-PC is online" : "Bear-PC is offline";
                                    }
                                    pointSize: Style.fontSizeS
                                    color: Qt.alpha(Color.mOnSurface, 0.65)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: Style.borderS
                        color: Qt.alpha(Color.mOutline, 0.3)
                        visible: root.configured
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: actionButton.implicitHeight
                        visible: root.configured

                        Rectangle {
                            id: actionButton
                            width: parent.width
                            implicitHeight: Math.round(48 * Style.uiScaleRatio)
                            radius: Style.radiusL
                            color: {
                                if (!root.isOnline) {
                                    return btnMouse.containsMouse
                                        ? Qt.alpha(Color.mPrimary, 0.22)
                                        : Qt.alpha(Color.mPrimary, 0.15);
                                }
                                return btnMouse.containsMouse
                                    ? Qt.darker(Color.mPrimary, 1.05)
                                    : Color.mPrimary;
                            }
                            border.color: Color.mPrimary
                            border.width: Style.borderS

                            Behavior on color { ColorAnimation { duration: Style.animationFast } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Style.marginS

                                NIcon {
                                    icon: root.isOnline ? "monitor-play" : "wifi"
                                    color: root.isOnline ? Color.mOnPrimary : Color.mPrimary
                                    pointSize: Style.fontSizeM
                                }

                                NText {
                                    text: {
                                        if (root.isConnecting) return "Launching…";
                                        return root.isOnline ? "Connect to Bear-PC" : "Wake Bear-PC";
                                    }
                                    font.bold: true
                                    color: root.isOnline ? Color.mOnPrimary : Color.mPrimary
                                    pointSize: Style.fontSizeM
                                }
                            }

                            MouseArea {
                                id: btnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.isConnecting

                                onClicked: {
                                    if (root.isOnline) {
                                        mainInst?.connectMoonlight();
                                    } else {
                                        mainInst?.wakePC();
                                    }
                                    pluginApi?.closePanel();
                                }
                            }
                        }
                    }

                    NText {
                        Layout.fillWidth: true
                        visible: !root.configured
                        text: "Set Bear-PC's IP and MAC in plugin settings."
                        color: Qt.alpha(Color.mOnSurface, 0.55)
                        pointSize: Style.fontSizeS
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
