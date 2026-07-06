import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    readonly property string bearMac: pluginApi?.pluginSettings?.bearMac ?? ""
    readonly property string bearIp: pluginApi?.pluginSettings?.bearIp ?? ""
    readonly property int pollIntervalSecs: pluginApi?.pluginSettings?.pollInterval ?? 30

    property bool isOnline: false
    property bool isChecking: false
    property bool isConnecting: false

    function checkStatus() {
        if (bearIp === "" || isChecking)
            return;
        isChecking = true;
        pingProcess.running = false;
        pingProcess.running = true;
    }

    function wakePC() {
        if (bearMac === "")
            return;
        Quickshell.execDetached(["wol", bearMac]);
        ToastService.showNotice("Moonlight", "Magic packet sent to Bear-PC", "wifi");
    }

    function connectMoonlight() {
        if (bearIp === "")
            return;
        isConnecting = true;
        connectTimer.start();
        Quickshell.execDetached(["sh", "-c", "prime-run moonlight stream \"" + bearIp + "\" Desktop"]);
    }

    Process {
        id: pingProcess
        command: ["ping", "-c", "1", "-W", "2", root.bearIp]
        running: false

        onExited: code => {
            root.isOnline = (code === 0);
            root.isChecking = false;
        }
    }

    Timer {
        id: pollTimer
        interval: root.pollIntervalSecs * 1000
        repeat: true
        running: root.bearIp !== ""
        triggeredOnStart: true
        onTriggered: root.checkStatus()
    }

    Timer {
        id: connectTimer
        interval: 3000
        repeat: false
        onTriggered: root.isConnecting = false
    }
}
