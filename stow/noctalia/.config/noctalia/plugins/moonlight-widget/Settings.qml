import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    property var pluginApi: null
    spacing: Style.marginM

    NText {
        text: "Bear-PC IP Address"
        font.bold: true
        color: Color.mOnSurface
    }

    NTextField {
        Layout.fillWidth: true
        placeholderText: "e.g. 192.168.1.100"
        text: pluginApi?.pluginSettings?.bearIp ?? ""

        onTextChanged: {
            pluginApi.pluginSettings.bearIp = text;
            pluginApi.saveSettings();
        }
    }

    NText {
        text: "Bear-PC MAC Address"
        font.bold: true
        color: Color.mOnSurface
    }

    NTextField {
        Layout.fillWidth: true
        placeholderText: "e.g. AA:BB:CC:DD:EE:FF"
        text: pluginApi?.pluginSettings?.bearMac ?? ""

        onTextChanged: {
            pluginApi.pluginSettings.bearMac = text;
            pluginApi.saveSettings();
        }
    }

    NText {
        text: "Status poll interval (seconds)"
        font.bold: true
        color: Color.mOnSurface
    }

    NTextField {
        Layout.fillWidth: true
        placeholderText: "30"
        text: String(pluginApi?.pluginSettings?.pollInterval ?? 30)
        inputMethodHints: Qt.ImhDigitsOnly

        onTextChanged: {
            const val = parseInt(text);
            if (!isNaN(val) && val > 0) {
                pluginApi.pluginSettings.pollInterval = val;
                pluginApi.saveSettings();
            }
        }
    }
}
