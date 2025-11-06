import QtQuick 2.0

MouseArea {
    id: control
    property string icon_default: ""
    property string icon_pressed: ""
    // Keep for compatibility; released icon maps to default
    property string icon_released: ""
    property int iconSize: 24
    implicitWidth: iconSize
    implicitHeight: iconSize

    Image {
        id: img
        // Bind source to pressed state so it always reflects icon_default changes
        source: control.pressed ? icon_pressed : icon_default
        width: control.iconSize
        height: control.iconSize
        fillMode: Image.PreserveAspectFit
    }
}
