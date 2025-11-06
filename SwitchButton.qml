import QtQuick 2.0

MouseArea {
    id: root
    property string icon_on: ""
    property string icon_off: ""
    property int status: 0 //0-Off 1-On
    property int iconSize: 24
    implicitWidth: iconSize
    implicitHeight: iconSize
    Image {
        id: img
        source: root.status === 0 ? icon_off : icon_on
        width: root.iconSize
        height: root.iconSize
        fillMode: Image.PreserveAspectFit
    }
    onClicked: {
        if (root.status == 0){
            root.status = 1
        } else {
            root.status = 0
        }
    }
}
