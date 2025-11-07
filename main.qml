import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    visible: true
    width: 1100
    height: 680
    visibility: "Windowed"
    title: qsTr("Media Player")

    // State
    property int currentIndex: -1
    property string filterText: ""
    property real progress: player.duration > 0 ? player.position / player.duration : 0

    function formatTime(ms) {
        var s = Math.max(0, Math.floor((ms||0) / 1000));
        var m = Math.floor(s / 60);
        var r = (s % 60).toString().padStart(2, '0');
        return m + ":" + r;
    }

    function selectTrack(index, autoplay) {
        if (index < 0 || index >= trackModel.count) return;
        currentIndex = index;
        player.source = trackModel.get(currentIndex).url;
        player.position = 0;
        if (autoplay === undefined || autoplay) player.play();
    }

    function nextTrack() {
        if (shuffleBtn.status === 1) {
            var idx = currentIndex;
            if (trackModel.count > 1) {
                var guard = 0;
                while (idx === currentIndex && guard < 20) {
                    idx = Math.floor(Math.random() * trackModel.count);
                    guard++;
                }
            } else if (trackModel.count === 1) {
                idx = 0;
            }
            if (idx !== -1) selectTrack(idx);
        } else {
            if (trackModel.count > 0)
                selectTrack((currentIndex + 1) % trackModel.count);
        }
    }

    function prevTrack() {
        if (shuffleBtn.status === 1) {
            var idx = currentIndex;
            if (trackModel.count > 1) {
                var guard = 0;
                while (idx === currentIndex && guard < 20) {
                    idx = Math.floor(Math.random() * trackModel.count);
                    guard++;
                }
            } else if (trackModel.count === 1) {
                idx = 0;
            }
            if (idx !== -1) selectTrack(idx);
        } else {
            if (trackModel.count > 0)
                selectTrack((currentIndex - 1 + trackModel.count) % trackModel.count);
        }
    }

    function addFiles(urlList) {
        if (!urlList || urlList.length === 0) return;
        var exts = [".mp3", ".wav", ".flac", ".ogg", ".m4a", ".aac"];
        for (var i = 0; i < urlList.length; ++i) {
            var u = urlList[i].toString();
            var lower = u.toLowerCase();
            var ok = false;
            for (var k=0;k<exts.length;++k) if (lower.endsWith(exts[k])) { ok = true; break; }
            if (!ok) continue;
            var fname = decodeURIComponent(u.split('/').pop());
            var title = fname.replace(/\.[^/.]+$/, "");
            trackModel.append({ title: title, artist: "", cover: "qrc:/Image/music.png", url: u, durationMs: 0 });
        }
        if (currentIndex === -1 && trackModel.count > 0) selectTrack(0, false);
    }

    function clearPlaylist() {
        trackModel.clear();
        currentIndex = -1;
        player.stop();
        player.source = "";
    }

    function removeTrack(idx) {
        if (idx < 0 || idx >= trackModel.count) return;
        var wasCurrent = (idx === currentIndex);
        trackModel.remove(idx);
        if (trackModel.count === 0) {
            currentIndex = -1;
            player.stop();
            player.source = "";
            return;
        }
        if (wasCurrent) {
            var ni = Math.min(idx, trackModel.count - 1);
            selectTrack(ni, true);
        } else if (idx < currentIndex) {
            currentIndex = currentIndex - 1;
        }
    }

    // Data
    ListModel { id: trackModel }

    // Media
    AudioOutput { id: audioOut }
    MediaPlayer {
        id: player
        audioOutput: audioOut
        loops: repeatBtn.status === 1 ? MediaPlayer.Infinite : 1
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia && repeatBtn.status !== 1) {
                nextTrack();
            }
        }
        onDurationChanged: {
            if (currentIndex >= 0 && currentIndex < trackModel.count) {
                trackModel.set(currentIndex, { durationMs: player.duration })
            }
        }
    }

    FileDialog {
        id: openDialog
        title: qsTr("Chọn bài hát")
        fileMode: FileDialog.OpenFiles
        nameFilters: [
            "Audio files (*.mp3 *.wav *.flac *.ogg *.m4a *.aac)",
            "All files (*)"
        ]
        onAccepted: addFiles(selectedFiles)
    }

    // No window toolbar; UI controls live inside content like the mock

    // Background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2c1344" }
            GradientStop { position: 1.0; color: "#201039" }
        }
    }

    // Content layout: sidebar + now-playing
    GridLayout {
        columns: 2
        columnSpacing: 16
        rowSpacing: 16
        anchors.fill: parent
        anchors.margins: 16

        // Sidebar (Playlist)
        Frame {
            Layout.row: 0
            Layout.column: 0
            Layout.fillHeight: true
            Layout.preferredWidth: Math.max(260, Math.min(380, root.width * 0.25))
            Layout.minimumWidth: 220
            Layout.maximumWidth: 460
            padding: 12
            background: Rectangle { radius: 10; color: "#151526"; border.color: "#26263A" }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Image { source: "qrc:/Image/music.png"; width: 18; height: 18; fillMode: Image.PreserveAspectFit }
                    Label { text: qsTr("My Playlist"); color: "white"; font.bold: true; Layout.fillWidth: true }
                    ToolButton { // + button
                        width: 28; height: 28; hoverEnabled: true
                        onClicked: openDialog.open()
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Thêm bài...")
                        contentItem: Label { text: "+"; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 14; color: "#7a2df1" }
                    }
                    ToolButton { // clear button
                        width: 28; height: 28; hoverEnabled: true
                        onClicked: clearPlaylist()
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Xóa hết")
                        contentItem: Label { text: "×"; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 14; color: "#3b2b67" }
                    }
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search music...")
                    onTextChanged: filterText = text.toLowerCase()
                }

                ListView {
                    id: playlistView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: trackModel
                    delegate: Rectangle {
                        width: playlistView.width
                        height: visible ? 72 : 0
                        radius: 10
                        color: index === currentIndex ? "#2b2b4a" : "#1d1d35"
                        border.color: "#34345a"
                        visible: !filterText || title.toLowerCase().indexOf(filterText) !== -1 || artist.toLowerCase().indexOf(filterText) !== -1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10
                            Image { source: cover; width: 48; height: 48; fillMode: Image.PreserveAspectFit }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: title; color: "white"; elide: Text.ElideRight }
                                Label { text: artist; color: "#B0B0C8"; elide: Text.ElideRight; font.pixelSize: 12 }
                            }
                            Label {
                                text: (typeof durationMs !== 'undefined' && durationMs > 0) ? formatTime(durationMs) : ""
                                color: "#B0B0C8"; horizontalAlignment: Text.AlignRight
                            }
                            ToolButton {
                                width: 24; height: 24
                                contentItem: Label { text: "×"; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: removeTrack(index)
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: selectTrack(index, true) }
                    }
                }

                // Import Music button at the bottom like the mock
                Button {
                    Layout.fillWidth: true
                    text: qsTr("Import Music")
                    onClicked: openDialog.open()
                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Image { source: "qrc:/Image/music.png"; width: 16; height: 16 }
                        Label { text: qsTr("Import Music"); color: "white"; Layout.fillWidth: true }
                    }
                    background: Rectangle {
                        radius: 10
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#ff5bb1" }
                            GradientStop { position: 1; color: "#ff6e7f" }
                        }
                    }
                }
            }
        }

        // Right content
        ColumnLayout {
            Layout.row: 0
            Layout.column: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Album art + title
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Math.min(400, root.height * 0.5)

                Rectangle {
                    id: artCard
                    width: Math.min(parent.width * 0.5, parent.height)
                    height: width
                    radius: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#3f2b96" }
                        GradientStop { position: 1.0; color: "#a8c0ff" }
                    }
                    Image {
                        anchors.centerIn: parent
                        source: trackModel.count > 0 && currentIndex >= 0 ? trackModel.get(currentIndex).cover : "qrc:/Image/music.png"
                        fillMode: Image.PreserveAspectFit
                        width: parent.width * 0.32
                        height: width
                    }
                }
            }

            // Titles
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: (currentIndex >= 0 && trackModel.count > 0) ? trackModel.get(currentIndex).title : ""
                    color: "white"
                    font.pixelSize: 28
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: (currentIndex >= 0 && trackModel.count > 0) ? trackModel.get(currentIndex).artist : ""
                    color: "#D0D0E0"
                }
            }

            // Progress
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: formatTime(player.position); color: "#cccccc" }
                    Item { Layout.fillWidth: true }
                    Label { text: formatTime(player.duration); color: "#cccccc" }
                }
                Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, player.duration)
                    value: player.position
                    onMoved: player.position = value
                }
            }

// Controls
            RowLayout {
                id: controlsRow
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                SwitchButton { id: shuffleBtn; icon_off: "qrc:/Image/shuffle.png"; icon_on: "qrc:/Image/shuffle-1.png"; iconSize: 32 }
                ButtonControl { icon_default: "qrc:/Image/prev.png"; icon_pressed: "qrc:/Image/hold-prev.png"; icon_released: icon_default; iconSize: 32; onClicked: prevTrack() }
                Rectangle {
                    width: 64; height: 64; radius: 32; color: "#ff5bb1"; opacity: 0.9
                    ButtonControl {
                        anchors.centerIn: parent
                        icon_default: (player.playbackState === MediaPlayer.PlayingState) ? "qrc:/Image/pause.png" : "qrc:/Image/play.png"
                        icon_pressed: (player.playbackState === MediaPlayer.PlayingState) ? "qrc:/Image/hold-pause.png" : "qrc:/Image/hold-play.png"
                        iconSize: 32
                        icon_released: icon_default
                        onClicked: { if (player.playbackState === MediaPlayer.PlayingState) player.pause(); else player.play(); }
                    }
                }
                ButtonControl { icon_default: "qrc:/Image/next.png"; icon_pressed: "qrc:/Image/hold-next.png"; icon_released: icon_default; iconSize: 32; onClicked: nextTrack() }
                SwitchButton { id: repeatBtn; icon_off: "qrc:/Image/repeat.png"; icon_on: "qrc:/Image/repeat1_hold.png"; iconSize: 32 }
            }

            // Volume (short, centered under controls)
            RowLayout {
                id: volumeRow
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: controlsRow.implicitWidth
                spacing: 8
                Label { text: qsTr("Vol"); color: "#cccccc" }
                Slider {
                    Layout.fillWidth: true
                    from: 0; to: 1; value: audioOut.volume
                    onMoved: audioOut.volume = value
                    background: Rectangle { radius: 4; color: "#4a3968"; implicitHeight: 8 }
                    handle: Rectangle { width: 12; height: 12; radius: 6; color: "#a888ff" }
                    contentItem: Item {
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 8; radius: 4
                            width: parent.width * audioOut.volume
                            color: "#a888ff"
                        }
                    }
                }
            }

            // Volume
            RowLayout { visible: false
                Layout.fillWidth: true
                spacing: 8
                Label { text: "🔊"; color: "#cccccc" }
                Slider {
                    Layout.fillWidth: true
                    from: 0; to: 1; value: audioOut.volume
                    onMoved: audioOut.volume = value
                    background: Rectangle { radius: 4; color: "#4a3968"; implicitHeight: 8 }
                    handle: Rectangle { width: 12; height: 12; radius: 6; color: "#a888ff" }
                    contentItem: Item {
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 8; radius: 4
                            width: parent.width * audioOut.volume
                            color: "#a888ff"
                        }
                    }
                }
            }
        }
    }
}
