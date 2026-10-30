import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "AnimationStyles.js" as AnimationStyles

KCM.SimpleKCM {
    id: page

    property alias cfg_colorize: colorizeCheck.checked
    property alias cfg_warningLevel: warningSpin.value
    property alias cfg_criticalLevel: criticalSpin.value
    property alias cfg_chargingAnimation: chargingCheck.checked
    property string cfg_chargingAnimationStyle: "sweep"
    property alias cfg_demoMode: demoCheck.checked
    property alias cfg_demoPercent: demoSpin.value
    property alias cfg_demoCharging: demoChargingCheck.checked

    // An editable QQC2.SpinBox does not apply the typed text until the field
    // loses focus or Enter is pressed. When clicking Apply, that could happen
    // after saving and the previous value was stored. Here the text is
    // turned into a value as soon as it is a valid number.
    //
    // Important: do not add " %" in textFromValue. The SpinBox rewrites the
    // text every time the value changes, and with the suffix the cursor
    // jumped behind the symbol: typing "23" left "2 %3" and the value ended
    // up being 0. The symbol is shown in the label.
    function typedNumber(text) {
        const match = String(text).match(/\d+/);
        return match ? parseInt(match[0], 10) : NaN;
    }

    function commitTypedValue(spin) {
        if (!spin || !spin.contentItem) {
            return;
        }
        const parsed = page.typedNumber(spin.contentItem.text);
        // While a multi-digit number is being typed it may be out of range
        // (e.g. "2" on the way to "25"). In that case the value is left alone.
        if (isNaN(parsed) || parsed < spin.from || parsed > spin.to) {
            return;
        }
        if (spin.value !== parsed) {
            spin.value = parsed;
        }
    }

    function valueFromTypedText(spin, text) {
        const parsed = page.typedNumber(text);
        if (isNaN(parsed)) {
            return spin.value;
        }
        return Math.max(spin.from, Math.min(spin.to, parsed));
    }

    Kirigami.FormLayout {
        QQC2.CheckBox { id: colorizeCheck; Kirigami.FormData.label: "Colors:"; text: "Change color depending on level and charging" }
        QQC2.SpinBox {
            id: warningSpin
            objectName: "warningSpin"
            Kirigami.FormData.label: "Orange below (%):"
            enabled: colorizeCheck.checked
            from: 5
            to: 60
            stepSize: 1
            editable: true
            valueFromText: function(text) { return page.valueFromTypedText(warningSpin, text); }
            Connections {
                target: warningSpin.contentItem
                function onTextEdited() { page.commitTypedValue(warningSpin); }
            }
        }
        QQC2.SpinBox {
            id: criticalSpin
            objectName: "criticalSpin"
            Kirigami.FormData.label: "Red below (%):"
            enabled: colorizeCheck.checked
            from: 1
            to: 30
            stepSize: 1
            editable: true
            valueFromText: function(text) { return page.valueFromTypedText(criticalSpin, text); }
            Connections {
                target: criticalSpin.contentItem
                function onTextEdited() { page.commitTypedValue(criticalSpin); }
            }
        }
        QQC2.Label { text: "When colors are enabled, the normal state uses the text color; below those levels it shows orange/red (also while charging), and when charging above them, green."; font: Kirigami.Theme.smallFont; opacity: 0.7; wrapMode: Text.WordWrap }
        QQC2.CheckBox { id: chargingCheck; Kirigami.FormData.label: "Animation:"; text: "Animate while charging" }
        QQC2.ComboBox {
            id: animFamilyCombo
            Kirigami.FormData.label: "Animation family:"
            enabled: chargingCheck.checked
            textRole: "name"
            model: AnimationStyles.groups
            currentIndex: AnimationStyles.groupIndexForStyle(page.cfg_chargingAnimationStyle)
            onActivated: {
                const styles = AnimationStyles.groups[currentIndex].styles;
                page.cfg_chargingAnimationStyle = styles[0].value;
            }
        }
        QQC2.ComboBox {
            id: animStyleCombo
            Kirigami.FormData.label: "Animation style:"
            enabled: chargingCheck.checked
            textRole: "text"
            valueRole: "value"
            model: AnimationStyles.groups[animFamilyCombo.currentIndex].styles
            currentIndex: {
                const styles = AnimationStyles.groups[animFamilyCombo.currentIndex].styles;
                for (let i = 0; i < styles.length; i++) {
                    if (styles[i].value === page.cfg_chargingAnimationStyle) {
                        return i;
                    }
                }
                return 0;
            }
            onCurrentValueChanged: {
                if (currentValue !== undefined
                        && page.cfg_chargingAnimationStyle !== currentValue) {
                    page.cfg_chargingAnimationStyle = currentValue;
                }
            }
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Preview" }
        QQC2.CheckBox { id: demoCheck; text: "Show simulated data" }
        QQC2.SpinBox {
            id: demoSpin
            objectName: "demoPercentSpin"
            Kirigami.FormData.label: "Simulated level (%):"
            enabled: demoCheck.checked
            from: 0
            to: 100
            stepSize: 1
            editable: true
            valueFromText: function(text) { return page.valueFromTypedText(demoSpin, text); }
            Connections {
                target: demoSpin.contentItem
                function onTextEdited() { page.commitTypedValue(demoSpin); }
            }
        }
        QQC2.CheckBox { id: demoChargingCheck; text: "Simulate charging"; enabled: demoCheck.checked }
    }
}
