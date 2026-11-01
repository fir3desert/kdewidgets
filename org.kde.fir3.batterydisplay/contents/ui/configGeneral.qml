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
    property alias cfg_previewAnimation: previewCheck.checked
    property alias cfg_animateWhenFull: fullCheck.checked
    property string cfg_chargingAnimationStyle

    // Plasma 6 also sets these "Default" values on the page; declaring them
    // avoids "Setting initial properties failed" warnings.
    property bool cfg_colorizeDefault
    property int cfg_warningLevelDefault
    property int cfg_criticalLevelDefault
    property bool cfg_chargingAnimationDefault
    property bool cfg_previewAnimationDefault
    property bool cfg_animateWhenFullDefault
    property string cfg_chargingAnimationStyleDefault

    // Translated models for the family/style selectors (the catalog lives in a
    // .pragma library script, which has no access to i18n).
    function familyModel() {
        return AnimationStyles.groups.map(function(g) { return { name: i18n(g.name) }; });
    }

    function styleModel(group) {
        return AnimationStyles.groups[group].styles.map(function(st) {
            return { text: i18n(st.text), value: st.value };
        });
    }

    // The combos are synchronised imperatively: a ComboBox breaks its
    // currentIndex binding as soon as the user picks an item, which left the
    // style list out of date after changing family.
    property bool ready: false

    function syncCombos() {
        if (!page.ready) {
            return;
        }
        const style = page.cfg_chargingAnimationStyle || "sweep";
        const group = AnimationStyles.groupIndexForStyle(style);
        animFamilyCombo.model = page.familyModel();
        animFamilyCombo.currentIndex = group;
        const styles = AnimationStyles.groups[group].styles;
        animStyleCombo.model = page.styleModel(group);
        let idx = 0;
        for (let i = 0; i < styles.length; i++) {
            if (styles[i].value === style) {
                idx = i;
                break;
            }
        }
        animStyleCombo.currentIndex = idx;
    }

    onCfg_chargingAnimationStyleChanged: page.syncCombos()
    Component.onCompleted: {
        page.ready = true;
        page.syncCombos();
    }

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
        QQC2.CheckBox { id: colorizeCheck; Kirigami.FormData.label: i18n("Colors:"); text: i18n("Change color depending on level and charging") }
        QQC2.SpinBox {
            id: warningSpin
            objectName: "warningSpin"
            Kirigami.FormData.label: i18n("Orange below (%):")
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
            Kirigami.FormData.label: i18n("Red below (%):")
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
        QQC2.Label { text: i18n("When colors are enabled, the normal state uses the text color; below those levels it shows orange/red (also while charging), and when charging above them, green."); font: Kirigami.Theme.smallFont; opacity: 0.7; wrapMode: Text.WordWrap }
        QQC2.CheckBox { id: chargingCheck; Kirigami.FormData.label: i18n("Animation:"); text: i18n("Animate while charging") }
        QQC2.CheckBox { id: fullCheck; text: i18n("Keep animating when plugged in at full charge"); enabled: chargingCheck.checked }
        QQC2.CheckBox { id: previewCheck; text: i18n("Preview animation (without charging)"); enabled: chargingCheck.checked }
        QQC2.ComboBox {
            id: animFamilyCombo
            Kirigami.FormData.label: i18n("Animation family:")
            enabled: chargingCheck.checked
            textRole: "name"
            onActivated: function(index) {
                const styles = AnimationStyles.groups[index].styles;
                if (styles && styles.length > 0) {
                    page.cfg_chargingAnimationStyle = styles[0].value;
                }
            }
        }
        QQC2.ComboBox {
            id: animStyleCombo
            Kirigami.FormData.label: i18n("Animation style:")
            enabled: chargingCheck.checked
            textRole: "text"
            valueRole: "value"
            onActivated: function(index) {
                const styles = AnimationStyles.groups[animFamilyCombo.currentIndex].styles;
                if (styles && index >= 0 && index < styles.length) {
                    page.cfg_chargingAnimationStyle = styles[index].value;
                }
            }
        }
    }
}
