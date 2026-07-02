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
    readonly property bool isOnline: mainInst?.isOnline ?? false
    readonly property bool isChecking: mainInst?.isChecking ?? false

    readonly property string screenName: screen?.name ?? ""
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    readonly property bool isSelected: isPanelOpen

    readonly property color capsuleBgColor: {
        if (isSelected) return mouseArea.containsMouse ? Qt.darker(Color.mPrimary, 1.08) : Color.mPrimary;
        return mouseArea.containsMouse ? Color.mHover : Style.capsuleColor;
    }
    readonly property color contentColor: isSelected
        ? Color.mOnPrimary
        : (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)
    readonly property color statusDotColor: {
        if (isChecking) return Qt.alpha(Color.mOnSurface, 0.4);
        return isOnline ? "#4CAF50" : "#F44336";
    }

    readonly property real contentWidth: row.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: root.capsuleBgColor
        radius: Style.radiusL
        border.color: root.isSelected ? Color.mPrimary : Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Behavior on color { ColorAnimation { duration: Style.animationFast } }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                icon: "moon-stars"
                color: root.contentColor
                pointSize: root.barFontSize
            }

            Rectangle {
                width: Math.round(7 * Style.uiScaleRatio)
                height: width
                radius: width / 2
                color: root.statusDotColor
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 400 } }

                SequentialAnimation on opacity {
                    running: root.isChecking
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 600 }
                    NumberAnimation { to: 1.0; duration: 600 }
                }
                opacity: root.isChecking ? 1.0 : 1.0
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
            const tip = root.isOnline ? "Bear-PC is online" : "Bear-PC is offline";
            TooltipService.show(root, tip, BarService.getTooltipDirection(root));
        }

        onExited: TooltipService.hide()
    }
}
