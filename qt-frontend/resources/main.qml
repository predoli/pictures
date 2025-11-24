import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: window
    width: 800
    height: 480
    visible: true
    title: qsTr("Digital Photo Frame")
    // visibility: Window.FullScreen // Uncomment for production

    property int currentIndex: 0
    property bool isPaused: false
    property bool showControls: false
    property int totalCount: backend.model ? backend.model.rowCount() : 0
    
    // Double buffering for cross-fade
    property bool useLayerA: true
    property var currentImageData: null

    onTotalCountChanged: {
        if (totalCount > 0 && currentImageData === null) {
            currentIndex = 0
            updateImage()
        }
    }

    function updateImage() {
        if (totalCount === 0) return
        
        var data = backend.model.get(currentIndex)
        currentImageData = data
        
        if (useLayerA) {
            imageA.source = "file://" + data.filePath
            // imageA will fade in, imageB will fade out
        } else {
            imageB.source = "file://" + data.filePath
            // imageB will fade in, imageA will fade out
        }
    }

    // Timer for slideshow
    Timer {
        id: slideshowTimer
        interval: 10000 // 10 seconds
        running: !isPaused && totalCount > 0
        repeat: true
        onTriggered: {
            nextImage()
        }
    }

    // Timer to hide controls
    Timer {
        id: hideControlsTimer
        interval: 3000
        onTriggered: showControls = false
    }

    function nextImage() {
        if (totalCount > 0) {
            currentIndex = (currentIndex + 1) % totalCount
            useLayerA = !useLayerA
            updateImage()
        }
    }

    function previousImage() {
        if (totalCount > 0) {
            currentIndex = (currentIndex - 1 + totalCount) % totalCount
            useLayerA = !useLayerA
            updateImage()
        }
    }

    function togglePause() {
        isPaused = !isPaused
    }

    function showControlsOverlay() {
        showControls = true
        hideControlsTimer.restart()
    }

    Rectangle {
        anchors.fill: parent
        color: "black"

        // Image Display - Double Layer
        Item {
            anchors.fill: parent
            
            Image {
                id: imageA
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                opacity: useLayerA ? 1.0 : 0.0
                visible: opacity > 0
                asynchronous: true
                Behavior on opacity { NumberAnimation { duration: 1000 } }
            }
            
            Image {
                id: imageB
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                opacity: !useLayerA ? 1.0 : 0.0
                visible: opacity > 0
                asynchronous: true
                Behavior on opacity { NumberAnimation { duration: 1000 } }
            }
            
            // Loading / Error / Empty states
            Text {
                anchors.centerIn: parent
                color: "#ccc"
                font.pixelSize: 18
                text: "Loading images..."
                visible: backend.isLoading && totalCount === 0
            }
            
            Text {
                anchors.centerIn: parent
                color: "#ff6b6b"
                font.pixelSize: 18
                text: backend.error
                visible: backend.error !== ""
            }
            
            Text {
                anchors.centerIn: parent
                color: "#ccc"
                font.pixelSize: 18
                text: "No images available"
                visible: !backend.isLoading && backend.error === "" && totalCount === 0
            }
        }

        // Mouse Area for interaction
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!showControls) {
                    showControlsOverlay()
                } else {
                    nextImage()
                    showControlsOverlay() // Keep controls visible but reset timer
                }
            }
        }

        // Image Info Overlay
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 20
            width: infoColumn.width + 20
            height: infoColumn.height + 20
            color: "#B3000000" // Semi-transparent black
            radius: 5
            opacity: showControls && totalCount > 0 ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            ColumnLayout {
                id: infoColumn
                anchors.centerIn: parent
                
                Text {
                    text: currentImageData ? currentImageData.filename : ""
                    color: "white"
                    font.pixelSize: 14
                }
                Text {
                    text: (currentIndex + 1) + " of " + totalCount
                    color: "white"
                    font.pixelSize: 14
                }
            }
        }

        // Controls Overlay
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 20
            width: controlsRow.width + 40
            height: controlsRow.height + 30
            color: "#CC000000"
            radius: 15
            opacity: showControls ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            RowLayout {
                id: controlsRow
                anchors.centerIn: parent
                spacing: 10

                Button {
                    text: isPaused ? "Play" : "Pause"
                    onClicked: {
                        togglePause()
                        showControlsOverlay()
                    }
                }

                // Sort Buttons
                RowLayout {
                    spacing: 0
                    Button {
                        text: "Name Asc"
                        highlighted: backend.ordering === "name_asc"
                        onClicked: {
                            backend.setOrdering("name_asc")
                            showControlsOverlay()
                        }
                    }
                    Button {
                        text: "Name Desc"
                        highlighted: backend.ordering === "name_desc"
                        onClicked: {
                            backend.setOrdering("name_desc")
                            showControlsOverlay()
                        }
                    }
                }

                RowLayout {
                    spacing: 0
                    Button {
                        text: "Date Asc"
                        highlighted: backend.ordering === "date_asc"
                        onClicked: {
                            backend.setOrdering("date_asc")
                            showControlsOverlay()
                        }
                    }
                    Button {
                        text: "Date Desc"
                        highlighted: backend.ordering === "date_desc"
                        onClicked: {
                            backend.setOrdering("date_desc")
                            showControlsOverlay()
                        }
                    }
                }

                Button {
                    text: "Random"
                    highlighted: backend.ordering === "random"
                    onClicked: {
                        backend.setOrdering("random")
                        showControlsOverlay()
                    }
                }
            }
        }
    }

    // Keyboard Handling
    Item {
        focus: true
        Keys.onSpacePressed: {
            togglePause()
            showControlsOverlay()
        }
        Keys.onLeftPressed: {
            previousImage()
            showControlsOverlay()
        }
        Keys.onRightPressed: {
            nextImage()
            showControlsOverlay()
        }
    }
}
