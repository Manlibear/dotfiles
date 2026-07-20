import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

FocusScope {
    id: root

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    anchors.fill: parent
    focus: visible

    readonly property var mainInst: pluginApi?.mainInstance ?? null

    property bool searchMode: false

    readonly property var sectionModel: [
        { key: "playing", label: "Playing", games: mainInst?.playingGames ?? [] },
        { key: "backlog", label: "Backlog", games: mainInst?.backlogGames ?? [] },
        { key: "completed", label: "Completed", games: mainInst?.completedGames ?? [] }
    ]

    readonly property real thumbWidth: 114 * Style.uiScaleRatio
    readonly property real thumbHeight: thumbWidth * 4 / 3
    readonly property real flowSpacing: Style.marginS + 4
    readonly property int gridColumns: 4
    // Scrollbar reserve mirrors NScrollView's rightPadding calc (handleWidth + marginXS).
    readonly property real scrollbarReserve: Math.round(6 * Style.uiScaleRatio) + Style.marginXS

    property real contentPreferredWidth: (Style.marginM * 2) + (gridColumns * thumbWidth)
        + ((gridColumns - 1) * flowSpacing) + scrollbarReserve
    property real contentPreferredHeight: 620 * Style.uiScaleRatio

    readonly property var statusMeta: ({
        "playing": { icon: "player-play-filled", label: "Mark Playing" },
        "backlog": { icon: "history", label: "Move to Backlog" },
        "completed": { icon: "circle-check-filled", label: "Mark Completed" }
    })
    readonly property var statusOrder: ["playing", "backlog", "completed"]
    readonly property var searchStatusOrder: ["playing", "backlog"]

    function otherStatuses(status) {
        return root.statusOrder.filter(s => s !== status);
    }

    function coverTooltip(game) {
        // Tooltip.qml renders with richTextEnabled: true, so a literal "\n"
        // gets collapsed like in HTML — needs an explicit <br>.
        const name = game?.name ?? "";
        const releaseDate = game?.release_date || "Unknown release date";
        return name + "<br>" + releaseDate;
    }

    function openSearch() {
        root.searchMode = true;
        searchTextField.forceActiveFocus();
    }

    function closeSearch() {
        root.searchMode = false;
        searchTextField.text = "";
        mainInst?.runSearch("");
    }

    // Shared cover-card visual for both the library sections and search
    // results — behavior (which status buttons show, what a click does)
    // branches on root.searchMode rather than needing two near-duplicate
    // delegates.
    Component {
        id: coverCardDelegate

        Rectangle {
            id: coverDelegate
            required property var modelData

            width: root.thumbWidth
            height: root.thumbHeight
            radius: Style.radiusS
            color: Color.mSurfaceVariant
            border.width: Style.borderS
            border.color: Qt.alpha(Color.mOutline, 0.5)

            readonly property bool hovered: coverHover.hovered
            readonly property var targets: root.searchMode
                ? root.searchStatusOrder
                : root.otherStatuses(coverDelegate.modelData.status)

            function handleAction(status) {
                if (root.searchMode) {
                    mainInst?.addOrMoveGame(coverDelegate.modelData, status);
                } else {
                    mainInst?.moveGame(coverDelegate.modelData.name, status);
                }
            }

            NImageRounded {
                anchors.fill: parent
                radius: parent.radius
                imagePath: mainInst ? mainInst.coverUrl(coverDelegate.modelData) : ""
                fallbackIcon: "device-gamepad-2"
                imageFillMode: Image.PreserveAspectCrop
            }

            HoverHandler {
                id: coverHover
                onHoveredChanged: {
                    if (hovered) {
                        TooltipService.show(coverDelegate, root.coverTooltip(coverDelegate.modelData));
                    } else {
                        TooltipService.hide();
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Qt.rgba(0, 0, 0, 0.6)
                visible: coverDelegate.hovered
                opacity: coverDelegate.hovered ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: Style.animationFast } }

                Column {
                    anchors.centerIn: parent
                    spacing: Style.marginS

                    Repeater {
                        model: coverDelegate.targets

                        delegate: Rectangle {
                            id: actionButton
                            required property var modelData

                            readonly property var meta: root.statusMeta[modelData]

                            width: Math.round(48 * Style.uiScaleRatio)
                            height: width
                            radius: width / 2
                            color: actionHover.hovered ? Color.mPrimary : Qt.alpha(Color.mSurface, 0.85)
                            border.width: Style.borderS
                            border.color: Qt.alpha(Color.mOutline, 0.6)

                            NIcon {
                                anchors.centerIn: parent
                                icon: actionButton.meta.icon
                                pointSize: Style.fontSizeS * 3
                                color: actionHover.hovered ? Color.mOnPrimary : Color.mOnSurface
                            }

                            HoverHandler {
                                id: actionHover
                                onHoveredChanged: {
                                    if (hovered) {
                                        TooltipService.show(actionButton, actionButton.meta.label);
                                    } else {
                                        TooltipService.show(coverDelegate, root.coverTooltip(coverDelegate.modelData));
                                    }
                                }
                            }

                            TapHandler {
                                cursorShape: Qt.PointingHandCursor
                                onTapped: {
                                    TooltipService.hide();
                                    coverDelegate.handleAction(actionButton.modelData);
                                }
                            }
                        }
                    }
                }
            }
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
                id: header
                Layout.fillWidth: true
                implicitHeight: Math.ceil(headerContent.implicitHeight + Style.marginM * 2)

                // Both the title row and the search field must report the
                // exact same height, or headerContent's implicit height
                // (and everything anchored to it) shifts by a couple of px
                // when toggling search mode.
                readonly property real rowHeight: Math.round(Style.baseWidgetSize * 1.1 * Style.uiScaleRatio)

                RowLayout {
                    id: headerContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: Style.marginM
                    anchors.topMargin: Style.marginM
                    anchors.bottomMargin: Style.marginM
                    anchors.rightMargin: Style.marginS
                    spacing: Style.marginS

                    NIcon {
                        icon: "device-gamepad-2"
                        pointSize: Style.fontSizeL
                        color: Color.mPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    RowLayout {
                        visible: !root.searchMode
                        Layout.fillWidth: true
                        Layout.preferredHeight: header.rowHeight
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Style.marginS

                        NText {
                            text: "Games Backlog"
                            pointSize: Style.fontSizeL
                            font.bold: true
                            color: Color.mOnSurface
                        }

                        NText {
                            text: (mainInst?.totalCount ?? 0) + " games tracked"
                            pointSize: Style.fontSizeS
                            color: Qt.alpha(Color.mOnSurface, 0.65)
                            topPadding: 5
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        id: searchFieldFrame
                        visible: root.searchMode
                        Layout.fillWidth: true
                        Layout.preferredHeight: header.rowHeight
                        Layout.alignment: Qt.AlignVCenter
                        radius: Style.radiusM
                        color: Color.mSurface
                        border.width: Style.borderS
                        border.color: searchTextField.activeFocus ? Color.mSecondary : Color.mOutline

                        Behavior on border.color { ColorAnimation { duration: Style.animationFast } }

                        TextField {
                            id: searchTextField
                            anchors.fill: parent
                            anchors.leftMargin: Style.marginM
                            anchors.rightMargin: Style.marginM
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            background: null
                            color: Color.mOnSurface
                            placeholderText: "Search IGDB…"
                            placeholderTextColor: Qt.alpha(Color.mOnSurfaceVariant, 0.6)
                            font.pointSize: Style.fontSizeS * Style.uiScaleRatio
                            topPadding: 0
                            bottomPadding: 0
                            leftPadding: 0
                            rightPadding: 0

                            onAccepted: mainInst?.runSearch(text)
                        }
                    }

                    NIconButton {
                        icon: root.searchMode ? "close" : "search"
                        Layout.alignment: Qt.AlignVCenter
                        tooltipText: root.searchMode ? "Close search" : "Search IGDB"
                        onClicked: {
                            if (root.searchMode) {
                                root.closeSearch();
                            } else {
                                root.openSearch();
                            }
                        }
                    }
                }
            }

            NScrollView {
                visible: !root.searchMode
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalPolicy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent.width
                    spacing: Style.marginM

                    Repeater {
                        model: root.sectionModel

                        delegate: ColumnLayout {
                            required property var modelData

                            Layout.fillWidth: true
                            spacing: Style.marginS
                            visible: modelData.games.length > 0

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginS

                                NText {
                                    text: modelData.label
                                    pointSize: Style.fontSizeM
                                    font.bold: true
                                    color: Color.mOnSurface
                                }

                                NText {
                                    text: "(" + modelData.games.length + ")"
                                    pointSize: Style.fontSizeS
                                    color: Qt.alpha(Color.mOnSurface, 0.55)
                                }

                                Item { Layout.fillWidth: true }
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: root.flowSpacing

                                Repeater {
                                    model: modelData.games
                                    delegate: coverCardDelegate
                                }
                            }
                        }
                    }

                    NText {
                        Layout.fillWidth: true
                        visible: (mainInst?.totalCount ?? 0) === 0
                        text: "No games found in library.json"
                        color: Qt.alpha(Color.mOnSurface, 0.55)
                        pointSize: Style.fontSizeS
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            ColumnLayout {
                visible: root.searchMode
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.marginM

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: (mainInst?.searchResults?.length ?? 0) === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Style.marginS

                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: mainInst?.searching ?? false
                            text: "Searching…"
                            color: Qt.alpha(Color.mOnSurface, 0.65)
                            pointSize: Style.fontSizeS
                        }

                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: (mainInst?.searchError ?? "") !== ""
                            text: mainInst?.searchError ?? ""
                            color: Color.mError
                            pointSize: Style.fontSizeS
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: !(mainInst?.searching ?? false) && (mainInst?.searchError ?? "") === ""
                            text: "Type a game name and press Enter"
                            color: Qt.alpha(Color.mOnSurface, 0.55)
                            pointSize: Style.fontSizeS
                        }
                    }
                }

                NScrollView {
                    visible: (mainInst?.searchResults?.length ?? 0) > 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalPolicy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: parent.width
                        spacing: Style.marginM

                        Flow {
                            Layout.fillWidth: true
                            spacing: root.flowSpacing

                            Repeater {
                                model: mainInst?.searchResults ?? []
                                delegate: coverCardDelegate
                            }
                        }

                        NButton {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.bottomMargin: Style.marginS
                            visible: mainInst?.searchHasMore ?? false
                            text: (mainInst?.searching ?? false) ? "Loading…" : "Load more"
                            enabled: !(mainInst?.searching ?? false)
                            outlined: true
                            onClicked: mainInst?.loadMoreSearch()
                        }
                    }
                }
            }
        }
    }
}
