import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var pluginApi: null

    readonly property string dataDir: "/home/manlibear/.local/share/gamesbacklog"
    readonly property string libraryPath: dataDir + "/library.json"
    readonly property string coversDir: dataDir + "/covers"
    readonly property string searchCoversDir: coversDir + "/.search/"
    readonly property string unknownCover: "file:///home/manlibear/Projects/GamesBacklog/assets/unknown.png"

    readonly property string venvPython: "/home/manlibear/Projects/GamesBacklog/.venv/bin/python3"
    readonly property string appScript: "/home/manlibear/Projects/GamesBacklog/app.py"

    property var allGames: []

    readonly property int searchPageSize: 20

    property bool searching: false
    property string searchError: ""
    property var searchResults: []
    property bool searchHasMore: false

    property string _searchQuery: ""
    property int _searchOffset: 0
    property bool _searchAppend: false

    readonly property var playingGames: _sortedByName(allGames.filter(g => g.status === "playing"))
    readonly property var backlogGames: _sortedByReleaseDate(allGames.filter(g => g.status === "backlog"))
    readonly property var completedGames: _sortedByName(allGames.filter(g => g.status === "completed"))

    readonly property int totalCount: allGames.length
    readonly property int playingCount: playingGames.length
    readonly property int backlogCount: backlogGames.length
    readonly property int completedCount: completedGames.length

    function _sortedByName(list) {
        return list.slice().sort((a, b) => (a.name || "").localeCompare(b.name || "", undefined, { sensitivity: "base" }));
    }

    function _sortedByReleaseDate(list) {
        return list.slice().sort((a, b) => {
            const ad = a.release_date || "";
            const bd = b.release_date || "";
            if (ad === "" && bd === "") return (a.name || "").localeCompare(b.name || "");
            if (ad === "") return 1;
            if (bd === "") return -1;
            return ad < bd ? -1 : (ad > bd ? 1 : 0);
        });
    }

    function coverUrl(game) {
        if (game && game.cover) {
            return "file://" + game.cover;
        }
        return root.unknownCover;
    }

    function moveGame(name, newStatus) {
        const updated = root.allGames.map(g => {
            return (g.name === name) ? Object.assign({}, g, { status: newStatus }) : g;
        });
        root.allGames = updated;
        libraryFile.setText(JSON.stringify({ games: updated }, null, 2) + "\n");
    }

    // Search-result covers are cached under searchCoversDir; once a result is
    // actually added to the library it needs a permanent home, same as the
    // TUI's own _promote_cover().
    function _promoteCover(coverPath) {
        if (!coverPath) return null;
        if (!coverPath.startsWith(root.searchCoversDir)) return coverPath;
        const filename = coverPath.substring(coverPath.lastIndexOf("/") + 1);
        const dest = root.coversDir + "/" + filename;
        Quickshell.execDetached(["cp", "-n", coverPath, dest]);
        return dest;
    }

    function addOrMoveGame(gameData, newStatus) {
        const idx = root.allGames.findIndex(g => g.name === gameData.name);
        let updated;
        if (idx >= 0) {
            updated = root.allGames.map((g, i) => {
                if (i !== idx) return g;
                return Object.assign({}, g, {
                    status: newStatus,
                    release_date: g.release_date || gameData.release_date || null,
                    cover: g.cover || root._promoteCover(gameData.cover)
                });
            });
        } else {
            updated = root.allGames.concat([{
                name: gameData.name,
                status: newStatus,
                release_date: gameData.release_date || null,
                cover: root._promoteCover(gameData.cover),
                skip_update: false
            }]);
        }
        root.allGames = updated;
        libraryFile.setText(JSON.stringify({ games: updated }, null, 2) + "\n");
    }

    function runSearch(query) {
        const trimmed = (query || "").trim();
        root._searchQuery = trimmed;
        if (trimmed === "") {
            root.searchResults = [];
            root.searchError = "";
            root.searchHasMore = false;
            return;
        }
        root._executeSearch(trimmed, 0, false);
    }

    function loadMoreSearch() {
        if (root.searching || root._searchQuery === "" || !root.searchHasMore) return;
        root._executeSearch(root._searchQuery, root._searchOffset, true);
    }

    function _executeSearch(query, offset, append) {
        root.searching = true;
        root.searchError = "";
        root._searchOffset = offset;
        root._searchAppend = append;
        searchProcess.command = [
            root.venvPython, root.appScript, "--search-json", query,
            "-c", String(root.searchPageSize), "--offset", String(offset)
        ];
        searchProcess.running = true;
    }

    Process {
        id: searchProcess
        stdout: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            root.searching = false;
            const out = String(searchProcess.stdout.text || "").trim();
            if (out === "") {
                root.searchError = "Search failed";
                if (!root._searchAppend) root.searchResults = [];
                root.searchHasMore = false;
                return;
            }
            try {
                const parsed = JSON.parse(out);
                if (parsed && !Array.isArray(parsed) && parsed.error) {
                    root.searchError = parsed.error;
                    if (!root._searchAppend) root.searchResults = [];
                    root.searchHasMore = false;
                } else if (Array.isArray(parsed)) {
                    root.searchResults = root._searchAppend ? root.searchResults.concat(parsed) : parsed;
                    root._searchOffset += parsed.length;
                    root.searchHasMore = parsed.length >= root.searchPageSize;
                } else {
                    root.searchError = "Search failed";
                    if (!root._searchAppend) root.searchResults = [];
                    root.searchHasMore = false;
                }
            } catch (e) {
                root.searchError = "Search failed";
                if (!root._searchAppend) root.searchResults = [];
                root.searchHasMore = false;
            }
        }
    }

    function _parse() {
        try {
            const content = libraryFile.text();
            const parsed = content ? JSON.parse(content) : { games: [] };
            root.allGames = Array.isArray(parsed.games) ? parsed.games : [];
        } catch (e) {
            root.allGames = [];
        }
    }

    FileView {
        id: libraryFile
        path: root.libraryPath
        printErrors: false
        watchChanges: true

        onLoaded: root._parse()
        onFileChanged: reload()
    }

    IpcHandler {
        target: "plugin:games-backlog"
        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.togglePanel(screen);
                });
            }
        }
    }
}
