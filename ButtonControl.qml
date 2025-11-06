import QtQuick 2.0

MouseArea {
    id: control
    property string icon_default: ""
    property string icon_pressed: ""
    // Keep for compatibility; released icon maps to default
    property string icon_released: ""
    implicitWidth: img.width
    implicitHeight: img.height

    Image {
        id: img
        // Bind source to pressed state so it always reflects icon_default changes
        source: control.pressed ? icon_pressed : icon_default
    }
}
