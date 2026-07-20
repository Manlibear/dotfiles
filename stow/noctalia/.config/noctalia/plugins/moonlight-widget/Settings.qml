import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: rootSettings
    property var pluginApi: null

    // Pass constraints safely up to Noctalia v4's dialog framework
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: Style.marginM

        NText {
            text: "Bear-PC IP Address"
            Layout.fillWidth: true
        }

        NTextInput {
            id: ipField
            Layout.fillWidth: true
            placeholderText: "e.g. 192.168.1.100"
            text: rootSettings.pluginApi?.pluginSettings?.bearIp ?? ""

            // activeFocus checks ensure changes only write back when you type
            onTextChanged: {
                if (activeFocus && rootSettings.pluginApi && rootSettings.pluginApi.pluginSettings) {
                    rootSettings.pluginApi.pluginSettings.bearIp = text;
                    rootSettings.pluginApi.saveSettings();
                }
            }
        }

        NText {
            text: "Bear-PC MAC Address"
            Layout.fillWidth: true
        }

        NTextInput {
            id: macField
            Layout.fillWidth: true
            placeholderText: "e.g. AA:BB:CC:DD:EE:FF"
            text: rootSettings.pluginApi?.pluginSettings?.bearMac ?? ""

            onTextChanged: {
                if (activeFocus && rootSettings.pluginApi && rootSettings.pluginApi.pluginSettings) {
                    rootSettings.pluginApi.pluginSettings.bearMac = text;
                    rootSettings.pluginApi.saveSettings();
                }
            }
        }

        NText {
            text: "Status poll interval (seconds)"
            Layout.fillWidth: true
        }

        NTextInput {
            id: intervalField
            Layout.fillWidth: true
            placeholderText: "30"
            text: String(rootSettings.pluginApi?.pluginSettings?.pollInterval ?? 30)
            inputMethodHints: Qt.ImhDigitsOnly

            onTextChanged: {
                if (activeFocus) {
                    const val = parseInt(text);
                    if (!isNaN(val) && val > 0 && rootSettings.pluginApi && rootSettings.pluginApi.pluginSettings) {
                        rootSettings.pluginApi.pluginSettings.pollInterval = val;
                        rootSettings.pluginApi.saveSettings();
                    }
                }
            }
        }
    }
}
