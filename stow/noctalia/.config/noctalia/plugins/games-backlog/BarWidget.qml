import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var mainInst: pluginApi?.mainInstance ?? null
    readonly property bool isPanelOpen: pluginApi?.isPanelOpen ?? false
    readonly property bool isSelected: isPanelOpen

    readonly property string screenName: screen ? screen.name : ""
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

    readonly property int playingCount: mainInst?.playingCount ?? 0
    readonly property int backlogCount: mainInst?.backlogCount ?? 0
    readonly property int completedCount: mainInst?.completedCount ?? 0
    readonly property bool hasCounts: (playingCount + backlogCount + completedCount) > 0

    readonly property bool useAccentContrast: isSelected || mouseArea.containsMouse
    readonly property color playingColor: useAccentContrast ? contentColor : "white"
    readonly property color backlogColor: useAccentContrast ? contentColor : "#B0B0B0"
    readonly property color completedColor: useAccentContrast ? contentColor : "#4CAF50"

    readonly property color capsuleBgColor: {
        if (isSelected) return mouseArea.containsMouse ? Qt.darker(Color.mPrimary, 1.08) : Color.mPrimary;
        return mouseArea.containsMouse ? Color.mHover : Style.capsuleColor;
    }
    readonly property color contentColor: isSelected
        ? Color.mOnPrimary
        : (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)

    implicitWidth: visualCapsule.width
    implicitHeight: visualCapsule.height

    Rectangle {
        id: visualCapsule
        anchors.centerIn: parent
        width: Math.max(root.capsuleHeight, iconRow.implicitWidth + Style.marginM * 2)
        height: root.capsuleHeight
        radius: Style.radiusL
        color: root.capsuleBgColor
        border.color: root.isSelected ? Color.mPrimary : Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Behavior on color { ColorAnimation { duration: Style.animationFast } }

        Row {
            id: iconRow
            anchors.centerIn: parent
            spacing: root.hasCounts ? Style.marginS : 0

            NIcon {
                icon: "device-gamepad-2"
                color: root.contentColor
            }

            Row {
                visible: root.hasCounts
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.marginXXS

                NText {
                    text: String(root.playingCount)
                    font.bold: true
                    pointSize: Style.fontSizeS
                    color: root.playingColor
                }

                NText {
                    text: "/"
                    font.bold: true
                    pointSize: Style.fontSizeS
                    color: root.contentColor
                }

                NText {
                    text: String(root.backlogCount)
                    font.bold: true
                    pointSize: Style.fontSizeS
                    color: root.backlogColor
                }

                NText {
                    text: "/"
                    font.bold: true
                    pointSize: Style.fontSizeS
                    color: root.contentColor
                }

                NText {
                    text: String(root.completedCount)
                    font.bold: true
                    pointSize: Style.fontSizeS
                    color: root.completedColor
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            TooltipService.hide();
            if (pluginApi) pluginApi.togglePanel(root.screen, root);
        }

        onEntered: {
            TooltipService.show(root, "Games Backlog", BarService.getTooltipDirection(root));
        }

        onExited: TooltipService.hide()
    }
}
