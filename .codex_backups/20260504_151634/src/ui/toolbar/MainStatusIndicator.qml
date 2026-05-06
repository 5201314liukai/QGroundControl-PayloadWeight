/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0

RowLayout {
    id:         _root
    spacing:    0

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property var    _vehicleInAir:      _activeVehicle ? _activeVehicle.flying || _activeVehicle.landing : false
    property bool   _vtolInFWDFlight:   _activeVehicle ? _activeVehicle.vtolInFwdFlight : false
    property bool   _armed:             _activeVehicle ? _activeVehicle.armed : false
    property real   _margins:           ScreenTools.defaultFontPixelWidth
    property real   _spacing:           ScreenTools.defaultFontPixelWidth / 2
    property bool   _healthAndArmingChecksSupported: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.supported : false

    property bool   _weightSampling:            false
    property bool   _samplingWeightAvailable:   false
    property real   _samplingWeightValue:       0
    property string _samplingWeightText:        qsTr("--")
    property var    _weightRecords:             []
    property int    _selectedWeightRecordIndex: -1
    property real   _weightTotalKg:             0

    function _hasCurrentWeight() {
        return _activeVehicle && _activeVehicle.payloadWeightAvailable
    }

    function _safeWeightValue() {
        if (_hasCurrentWeight()) {
            var value = Number(_activeVehicle.payloadWeight)
            return isNaN(value) ? 0 : value
        }
        return 0
    }

    function _formatWeight(weightValue) {
        var value = Number(weightValue)
        if (isNaN(value)) {
            return qsTr("--")
        }
        return value.toFixed(2) + qsTr(" kg")
    }

    function _currentWeightText() {
        return _hasCurrentWeight() ? _activeVehicle.payloadWeightText : qsTr("--")
    }

    function _displayWeightText() {
        if (_weightSampling) {
            return _samplingWeightAvailable ? _samplingWeightText : qsTr("--")
        }
        return _selectedRecordText()
    }

    function _recordLabels() {
        var labels = []
        for (var i = 0; i < _weightRecords.length; i++) {
            labels.push(_weightRecords[i].label)
        }
        return labels
    }

    function _selectedRecord() {
        if (_selectedWeightRecordIndex >= 0 && _selectedWeightRecordIndex < _weightRecords.length) {
            return _weightRecords[_selectedWeightRecordIndex]
        }
        return null
    }

    function _selectedRecordText() {
        var record = _selectedRecord()
        return record ? record.weightText : qsTr("--")
    }

    function _selectedRecordLabel() {
        var record = _selectedRecord()
        return record ? record.label : qsTr("未选择")
    }

    function _appendWeightRecord(weightValue, weightText) {
        var value = Number(weightValue)
        if (isNaN(value)) {
            return
        }

        var nextNumber = _weightRecords.length + 1
        var nextRecord = {
            number: nextNumber,
            label: qsTr("第%1次").arg(nextNumber),
            weightValue: value,
            weightText: weightText && weightText.length > 0 ? weightText : _formatWeight(value)
        }

        var newRecords = _weightRecords.slice(0)
        newRecords.push(nextRecord)
        _weightRecords = newRecords
        _selectedWeightRecordIndex = newRecords.length - 1
        _weightTotalKg = _weightTotalKg + value
    }

    function _clearWeightRecords() {
        _weightRecords = []
        _selectedWeightRecordIndex = -1
        _weightTotalKg = 0
        _weightSampling = false
        _samplingWeightAvailable = false
        _samplingWeightValue = 0
        _samplingWeightText = qsTr("--")
    }

    Connections {
        target: _activeVehicle

        function onPayloadWeightChanged() {
            if (_weightSampling) {
                _samplingWeightAvailable = _hasCurrentWeight()
                _samplingWeightValue = _safeWeightValue()
                _samplingWeightText = _currentWeightText()
            }
        }
    }

    QGCLabel {
        id:             mainStatusLabel
        text:           mainStatusText()
        font.pointSize: _vehicleInAir ? ScreenTools.defaultFontPointSize : ScreenTools.largeFontPointSize

        property string _commLostText:      qsTr("通信丢失")
        property string _readyToFlyText:    qsTr("可飞行")
        property string _notReadyToFlyText: qsTr("未就绪")
        property string _disconnectedText:  qsTr("未连接")
        property string _armedText:         qsTr("已解锁")
        property string _flyingText:        qsTr("飞行中")
        property string _landingText:       qsTr("降落中")

        function mainStatusText() {
            var statusText
            if (_activeVehicle) {
                if (_communicationLost) {
                    _mainStatusBGColor = "red"
                    return mainStatusLabel._commLostText
                }
                if (_activeVehicle.armed) {
                    _mainStatusBGColor = "green"

                    if (_healthAndArmingChecksSupported) {
                        if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                            if (_activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                                _mainStatusBGColor = "#6B6500"
                            }
                        } else {
                            _mainStatusBGColor = "red"
                        }
                    }

                    if (_activeVehicle.flying) {
                        return mainStatusLabel._flyingText
                    } else if (_activeVehicle.landing) {
                        return mainStatusLabel._landingText
                    } else {
                        return mainStatusLabel._armedText
                    }
                } else {
                    if (_healthAndArmingChecksSupported) {
                        if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                            if (_activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                                _mainStatusBGColor = "#6B6500"
                            } else {
                                _mainStatusBGColor = "green"
                            }
                            return mainStatusLabel._readyToFlyText
                        } else {
                            _mainStatusBGColor = "red"
                            return mainStatusLabel._notReadyToFlyText
                        }
                    } else if (_activeVehicle.readyToFlyAvailable) {
                        if (_activeVehicle.readyToFly) {
                            _mainStatusBGColor = "green"
                            return mainStatusLabel._readyToFlyText
                        } else {
                            _mainStatusBGColor = "#6B6500"
                            return mainStatusLabel._notReadyToFlyText
                        }
                    } else {
                        if (_activeVehicle.allSensorsHealthy && _activeVehicle.autopilot.setupComplete) {
                            _mainStatusBGColor = "green"
                            return mainStatusLabel._readyToFlyText
                        } else {
                            _mainStatusBGColor = "#6B6500"
                            return mainStatusLabel._notReadyToFlyText
                        }
                    }
                }
            } else {
                _mainStatusBGColor = qgcPal.brandingPurple
                return mainStatusLabel._disconnectedText
            }
        }

        QGCMouseArea {
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            height:                 _root.height
            enabled:                _activeVehicle
            onClicked:              mainWindow.showIndicatorPopup(mainStatusLabel, sensorStatusInfoComponent)
        }
    }

    Item {
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        height:                 1
    }

    Rectangle {
        id:               payloadWeightPanel
        visible:          true
        color:            "#3B2F05"
        border.color:     "#F7C948"
        border.width:     1
        radius:           ScreenTools.defaultFontPixelHeight * 0.4
        implicitWidth:    payloadWeightRow.implicitWidth + ScreenTools.defaultFontPixelWidth * 2.0
        implicitHeight:   Math.max(payloadWeightRow.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.8, _root.height * 0.72)
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            id:                 payloadWeightRow
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelWidth * 0.75

            QGCLabel {
                text:           qsTr("重量")
                color:          "#F7C948"
                font.pointSize: ScreenTools.defaultFontPointSize + 1
                font.bold:      true
            }

            QGCLabel {
                text:           _currentWeightText()
                color:          "white"
                font.pointSize: ScreenTools.largeFontPointSize + 1
                font.bold:      true
            }
        }

        QGCMouseArea {
            anchors.fill: parent
            onClicked:    mainWindow.showIndicatorPopup(payloadWeightPanel, weightRecordComponent)
        }
    }

    Item {
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        height:                 1
    }

    FlightModeMenuIndicator {
        id:                     flightModeMenu
        Layout.preferredHeight: _root.height
        fontPointSize:          _vehicleInAir ?  ScreenTools.largeFontPointSize : ScreenTools.defaultFontPointSize
        visible:                _activeVehicle
    }

    Item {
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        height:                 1
        visible:                vtolModeLabel.visible
    }

    QGCLabel {
        id:                     vtolModeLabel
        Layout.preferredHeight: _root.height
        verticalAlignment:      Text.AlignVCenter
        text:                   _vtolInFWDFlight ? qsTr("固定翼(VTOL)") : qsTr("多旋翼(VTOL)")
        font.pointSize:         ScreenTools.largeFontPointSize
        visible:                _activeVehicle ? _activeVehicle.vtol && _vehicleInAir : false

        QGCMouseArea {
            anchors.fill:   parent
            onClicked:      mainWindow.showIndicatorPopup(vtolModeLabel, vtolTransitionComponent)
        }
    }

    Component {
        id: weightRecordComponent

        Rectangle {
            width:          Math.max(weightRecordLayout.implicitWidth + (_margins * 2), ScreenTools.defaultFontPixelWidth * 42)
            height:         weightRecordLayout.implicitHeight + (_margins * 2)
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            color:          qgcPal.window
            border.color:   qgcPal.text

            ColumnLayout {
                id:                 weightRecordLayout
                anchors.margins:    _margins
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                spacing:            _spacing

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("称重记录")
                    font.pointSize:     ScreenTools.largeFontPointSize
                    font.bold:          true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: _spacing

                    QGCButton {
                        text:       qsTr("开始")
                        enabled:    !_weightSampling && _hasCurrentWeight()
                        onClicked: {
                            _weightSampling = true
                            _samplingWeightAvailable = _hasCurrentWeight()
                            _samplingWeightValue = _safeWeightValue()
                            _samplingWeightText = _currentWeightText()
                        }
                    }

                    QGCButton {
                        text:       qsTr("停止")
                        enabled:    _weightSampling
                        onClicked: {
                            if (_weightSampling) {
                                _samplingWeightAvailable = _hasCurrentWeight()
                                _samplingWeightValue = _safeWeightValue()
                                _samplingWeightText = _currentWeightText()
                                _weightSampling = false

                                if (_samplingWeightAvailable) {
                                    _appendWeightRecord(_samplingWeightValue, _samplingWeightText)
                                }
                            }
                        }
                    }

                    QGCButton {
                        text:       qsTr("清空")
                        enabled:    _weightRecords.length > 0 || _weightSampling
                        onClicked:  _clearWeightRecords()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    QGCLabel {
                        text:       _weightSampling ? qsTr("状态: 采集中") : qsTr("状态: 已停止")
                        color:      _weightSampling ? qgcPal.colorGreen : qgcPal.text
                        font.bold:  true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    color: qgcPal.windowShade
                    radius: ScreenTools.defaultFontPixelHeight * 0.35
                    border.color: qgcPal.text
                    border.width: 1
                    implicitHeight: ScreenTools.defaultFontPixelHeight * 4.4

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelWidth
                        spacing: ScreenTools.defaultFontPixelHeight * 0.2

                        QGCLabel {
                            text:           qsTr("本次重量")
                            color:          "#F7C948"
                            font.bold:      true
                        }

                        QGCLabel {
                            text:           _displayWeightText()
                            color:          "white"
                            font.pointSize: ScreenTools.largeFontPointSize + 3
                            font.bold:      true
                        }

                        QGCLabel {
                            text:       qsTr("实时数据: %1").arg(_currentWeightText())
                            color:      qgcPal.text
                        }
                    }
                }

                QGCLabel {
                    text:       qsTr("记录选择")
                    font.bold:  true
                }

                QGCComboBox {
                    Layout.fillWidth: true
                    model: _weightRecords.length > 0 ? _recordLabels() : [qsTr("暂无记录")]
                    enabled: _weightRecords.length > 0
                    currentIndex: _weightRecords.length > 0 ? Math.max(0, _selectedWeightRecordIndex) : 0
                    onActivated: {
                        if (_weightRecords.length > 0) {
                            _selectedWeightRecordIndex = currentIndex
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: _spacing
                    columnSpacing: ScreenTools.defaultFontPixelWidth * 2

                    QGCLabel {
                        text: qsTr("已记录次数")
                        font.bold: true
                    }

                    QGCLabel {
                        text: _weightRecords.length.toString()
                    }

                    QGCLabel {
                        text: qsTr("选中记录")
                        font.bold: true
                    }

                    QGCLabel {
                        text: _selectedRecordLabel()
                    }

                    QGCLabel {
                        text: qsTr("选中重量")
                        font.bold: true
                    }

                    QGCLabel {
                        text: _selectedRecordText()
                    }

                    QGCLabel {
                        text: qsTr("总质量")
                        font.bold: true
                    }

                    QGCLabel {
                        text: _weightRecords.length > 0 ? _formatWeight(_weightTotalKg) : qsTr("--")
                        color: "#F7C948"
                        font.bold: true
                    }
                }
            }
        }
    }

    Component {
        id: sensorStatusInfoComponent

        Rectangle {
            width:          flickable.width + (_margins * 2)
            height:         flickable.height + (_margins * 2)
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            color:          qgcPal.window
            border.color:   qgcPal.text

            QGCFlickable {
                id:                 flickable
                anchors.margins:    _margins
                anchors.top:        parent.top
                anchors.left:       parent.left
                width:              mainLayout.width
                height:             mainWindow.contentItem.height - (indicatorPopup.padding * 2) - (_margins * 2)
                flickableDirection: Flickable.VerticalFlick
                contentHeight:      mainLayout.height
                contentWidth:       mainLayout.width

                ColumnLayout {
                    id:         mainLayout
                    spacing:    _spacing

                    QGCButton {
                        Layout.leftMargin:  _healthAndArmingChecksSupported ? width / 2 : 0
                        Layout.alignment:   _healthAndArmingChecksSupported ? Qt.AlignLeft : Qt.AlignHCenter
                        enabled:            _armed || !_healthAndArmingChecksSupported || _activeVehicle.healthAndArmingCheckReport.canArm
                        text:               _armed ?  qsTr("上锁") : (forceArm ? qsTr("强制解锁") : qsTr("解锁"))

                        property bool forceArm: false

                        onPressAndHold: forceArm = true

                        onClicked: {
                            if (_armed) {
                                mainWindow.disarmVehicleRequest()
                            } else {
                                if (forceArm) {
                                    mainWindow.forceArmVehicleRequest()
                                } else {
                                    mainWindow.armVehicleRequest()
                                }
                            }
                            forceArm = false
                            mainWindow.hideIndicatorPopup()
                        }
                    }

                    QGCLabel {
                        Layout.alignment:   Qt.AlignHCenter
                        text:               qsTr("传感器状态")
                        visible:            !_healthAndArmingChecksSupported
                    }

                    GridLayout {
                        rowSpacing:     _spacing
                        columnSpacing:  _spacing
                        rows:           _activeVehicle.sysStatusSensorInfo.sensorNames.length
                        flow:           GridLayout.TopToBottom
                        visible:        !_healthAndArmingChecksSupported

                        Repeater {
                            model: _activeVehicle.sysStatusSensorInfo.sensorNames

                            QGCLabel {
                                text: modelData
                            }
                        }

                        Repeater {
                            model: _activeVehicle.sysStatusSensorInfo.sensorStatus

                            QGCLabel {
                                text: modelData
                            }
                        }
                    }

                    QGCLabel {
                        text:               qsTr("解锁检查报告:")
                        visible:            _healthAndArmingChecksSupported && _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode.count > 0
                    }

                    QGCListView {
                        visible:            _healthAndArmingChecksSupported
                        anchors.margins:    ScreenTools.defaultFontPixelHeight
                        spacing:            ScreenTools.defaultFontPixelWidth
                        width:              mainWindow.width * 0.66666
                        height:             contentHeight
                        model:              _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode : null
                        delegate:           listdelegate
                    }

                    FactPanelController {
                        id: controller
                    }

                    Component {
                        id: listdelegate

                        Column {
                            width:      parent ? parent.width : 0
                            Row {
                                width:  parent.width
                                QGCLabel {
                                    id:           message
                                    text:         object.message
                                    wrapMode:     Text.WordWrap
                                    textFormat:   TextEdit.RichText
                                    width:        parent.width - arrowDownIndicator.width
                                    color:        object.severity == "error" ? qgcPal.colorRed : object.severity == "warning" ? qgcPal.colorOrange : qgcPal.text
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (object.description != "")
                                                object.expanded = !object.expanded
                                        }
                                    }
                                }

                                QGCColoredImage {
                                    id:                     arrowDownIndicator
                                    height:                 1.5 * ScreenTools.defaultFontPixelWidth
                                    width:                  height
                                    source:                 "/qmlimages/arrow-down.png"
                                    color:                  qgcPal.text
                                    visible:                object.description != ""
                                    MouseArea {
                                        anchors.fill:       parent
                                        onClicked:          object.expanded = !object.expanded
                                    }
                                }
                            }
                            Rectangle {
                                property var margin:      ScreenTools.defaultFontPixelWidth
                                id:                       descriptionRect
                                width:                    parent.width
                                height:                   description.height + margin
                                color:                    qgcPal.windowShade
                                visible:                  false
                                Connections {
                                    target:               object
                                    function onExpandedChanged() {
                                        if (object.expanded) {
                                            description.height = description.preferredHeight
                                        } else {
                                            description.height = 0
                                        }
                                    }
                                }

                                Behavior on height {
                                    NumberAnimation {
                                        id: animation
                                        duration: 150
                                        onRunningChanged: {
                                            descriptionRect.visible = animation.running || object.expanded
                                        }
                                    }
                                }
                                QGCLabel {
                                    id:                 description
                                    anchors.centerIn:   parent
                                    width:              parent.width - parent.margin * 2
                                    height:             0
                                    text:               object.description
                                    textFormat:         TextEdit.RichText
                                    wrapMode:           Text.WordWrap
                                    clip:               true
                                    property var fact:  null
                                    onLinkActivated: {
                                        if (link.startsWith("param://")) {
                                            var paramName = link.substr(8);
                                            fact = controller.getParameterFact(-1, paramName, true)
                                            if (fact != null) {
                                                paramEditorDialogComponent.createObject(mainWindow).open()
                                            }
                                        } else {
                                            Qt.openUrlExternally(link);
                                        }
                                    }
                                }

                                Component {
                                    id: paramEditorDialogComponent

                                    ParameterEditorDialog {
                                        title:          qsTr("编辑参数")
                                        fact:           description.fact
                                        destroyOnClose: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: vtolTransitionComponent

        Rectangle {
            width:          mainLayout.width   + (_margins * 2)
            height:         mainLayout.height  + (_margins * 2)
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            color:          qgcPal.window
            border.color:   qgcPal.text

            QGCButton {
                id:                 mainLayout
                anchors.margins:    _margins
                anchors.top:        parent.top
                anchors.left:       parent.left
                text:               _vtolInFWDFlight ? qsTr("切换到多旋翼") : qsTr("切换到固定翼")

                onClicked: {
                    if (_vtolInFWDFlight) {
                        mainWindow.vtolTransitionToMRFlightRequest()
                    } else {
                        mainWindow.vtolTransitionToFwdFlightRequest()
                    }
                    mainWindow.hideIndicatorPopup()
                }
            }
        }
    }
}

