import "../componentes"
import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Flickable {
    id: settingsView

    contentHeight: mainLayout.implicitHeight + MochaDS.Theme.spacing.xxl
    clip: true

    // Load configuration values from backend
    function loadConfig() {
        var flavor = backend.getConfigStr("theme_flavor");
        themeSelect.selectedValue = flavor;
        themeSelect.updateLabelFromValue();
        
        aurToggle.checked = backend.getConfigBool("enable_aur");
        flatpakToggle.checked = backend.getConfigBool("enable_flatpak");
        startupUpdateToggle.checked = backend.getConfigBool("check_updates_startup");

        var lang = backend.getConfigStr("language");
        if (lang === "en_US") languageGroup.currentIndex = 1;
        else if (lang === "es_ES") languageGroup.currentIndex = 2;
        else if (lang === "zh_CN") languageGroup.currentIndex = 3;
        else languageGroup.currentIndex = 0;
    }

    Component.onCompleted: {
        loadConfig();
    }

    ColumnLayout {
        id: mainLayout
        width: parent.width - MochaDS.Theme.spacing.xl * 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: MochaDS.Theme.spacing.xl
        spacing: MochaDS.Theme.spacing.lg

        // Header Section
        RowLayout {
            spacing: MochaDS.Theme.spacing.sm
            Layout.fillWidth: true

            MochaDS.LucideIcon {
                name: "settings"
                size: 32
                color: MochaDS.Theme.colors.primary
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: qsTr("Configurações")
                    font.family: MochaDS.Theme.typography.familyBold
                    font.pixelSize: MochaDS.Theme.typography.sizeH1
                    color: MochaDS.Theme.colors.text
                }
                Text {
                    text: qsTr("Personalize e gerencie o comportamento da sua loja de aplicativos")
                    font.family: MochaDS.Theme.typography.family
                    font.pixelSize: MochaDS.Theme.typography.sizeSm
                    color: MochaDS.Theme.colors.subtext0
                }
            }
        }

        // Horizontal Line
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: MochaDS.Theme.colors.surface0
        }

        // Section 1: Aparência (Appearance)
        MochaDS.Card {
            Layout.fillWidth: true
            title: qsTr("Aparência")
            subtitle: qsTr("Personalize a interface visual do aplicativo")
            icon: "palette"
            variant: "default"

            ColumnLayout {
                width: parent.width
                spacing: MochaDS.Theme.spacing.md

                RowLayout {
                    Layout.fillWidth: true
                    spacing: MochaDS.Theme.spacing.lg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: qsTr("Tema de Cores")
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: qsTr("Selecione uma das 4 variantes oficiais do Catppuccin")
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.Select {
                        id: themeSelect
                        width: 320
                        options: [
                            { value: "latte", label: qsTr("Catppuccin Latte (Claro)") },
                            { value: "frappe", label: qsTr("Catppuccin Frappé (Escuro Suave)") },
                            { value: "macchiato", label: qsTr("Catppuccin Macchiato (Escuro Médio)") },
                            { value: "mocha", label: qsTr("Catppuccin Mocha (Escuro Profundo)") }
                        ]
                        placeholder: qsTr("Selecione o tema...")
                        onValueChanged: function(val) {
                            if (val) {
                                backend.setConfigStr("theme_flavor", val);
                                MochaDS.Theme.flavor = val;
                                toasts.success(qsTr("Tema alterado para %1").arg(selectedLabel), qsTr("Sucesso"));
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: MochaDS.Theme.colors.surface0
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: MochaDS.Theme.spacing.lg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: qsTr("Idioma do Aplicativo")
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: qsTr("Escolha o idioma da interface (requer reiniciar o aplicativo)")
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.ButtonGroup {
                        id: languageGroup
                        expand: false
                        Layout.alignment: Qt.AlignVCenter

                        MochaDS.ButtonGroupItem {
                            text: qsTr("Padrão")
                            onClicked: {
                                backend.setConfigStr("language", "system");
                                toasts.success(qsTr("Idioma definido para o Padrão do Sistema. Reinicie o aplicativo para aplicar."), qsTr("Sucesso"));
                            }
                        }

                        MochaDS.ButtonGroupItem {
                            text: "English"
                            onClicked: {
                                backend.setConfigStr("language", "en_US");
                                toasts.success(qsTr("Idioma definido para Inglês. Reinicie o aplicativo para aplicar."), qsTr("Sucesso"));
                            }
                        }

                        MochaDS.ButtonGroupItem {
                            text: "Español"
                            onClicked: {
                                backend.setConfigStr("language", "es_ES");
                                toasts.success(qsTr("Idioma definido para Espanhol. Reinicie o aplicativo para aplicar."), qsTr("Sucesso"));
                            }
                        }

                        MochaDS.ButtonGroupItem {
                            text: "中文"
                            onClicked: {
                                backend.setConfigStr("language", "zh_CN");
                                toasts.success(qsTr("Idioma definido para Chinês. Reinicie o aplicativo para aplicar."), qsTr("Sucesso"));
                            }
                        }
                    }
                }
            }
        }

        // Section 2: Fontes de Pacotes (Package Sources)
        MochaDS.Card {
            Layout.fillWidth: true
            title: qsTr("Fontes de Pacotes")
            subtitle: qsTr("Ative ou desative repositórios adicionais")
            icon: "database"
            variant: "default"

            ColumnLayout {
                width: parent.width
                spacing: MochaDS.Theme.spacing.lg

                // AUR Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: MochaDS.Theme.spacing.lg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: qsTr("Habilitar AUR (Arch User Repository)")
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: qsTr("Permite buscar e instalar pacotes mantidos pela comunidade do Arch Linux")
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.ToggleButton {
                        id: aurToggle
                        onToggled: function(state) {
                            backend.setConfigBool("enable_aur", state);
                            toasts.info(qsTr("Suporte ao AUR %1").arg(state ? qsTr("habilitado") : qsTr("desabilitado")), qsTr("Configuração salva"));
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: MochaDS.Theme.colors.surface0
                }

                // Flatpak Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: MochaDS.Theme.spacing.lg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: qsTr("Habilitar Flatpak")
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: qsTr("Habilita suporte a aplicativos empacotados em formato sandbox via Flathub")
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.ToggleButton {
                        id: flatpakToggle
                        onToggled: function(state) {
                            backend.setConfigBool("enable_flatpak", state);
                            toasts.info(qsTr("Suporte ao Flatpak %1").arg(state ? qsTr("habilitado") : qsTr("desabilitado")), qsTr("Configuração salva"));
                        }
                    }
                }
            }
        }

        // Section 3: Atualizações (Updates)
        MochaDS.Card {
            Layout.fillWidth: true
            title: qsTr("Atualizações")
            subtitle: qsTr("Gerencie a verificação de atualizações de pacotes")
            icon: "refresh-cw"
            variant: "default"

            ColumnLayout {
                width: parent.width
                spacing: MochaDS.Theme.spacing.md

                RowLayout {
                    Layout.fillWidth: true
                    spacing: MochaDS.Theme.spacing.lg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: qsTr("Verificar Atualizações ao Iniciar")
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: qsTr("Busca automaticamente por novos pacotes atualizáveis ao abrir a Arch Store")
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.ToggleButton {
                        id: startupUpdateToggle
                        onToggled: function(state) {
                            backend.setConfigBool("check_updates_startup", state);
                            toasts.info(qsTr("Verificação inicial %1").arg(state ? qsTr("habilitada") : qsTr("desabilitada")), qsTr("Configuração salva"));
                        }
                    }
                }
            }
        }

        // Section 4: Manutenção (Maintenance)
        MochaDS.Card {
            Layout.fillWidth: true
            title: qsTr("Manutenção")
            subtitle: qsTr("Limpeza e otimização do sistema")
            icon: "trash-2"
            variant: "default"

            ColumnLayout {
                width: parent.width
                spacing: MochaDS.Theme.spacing.md

                RowLayout {
                    Layout.fillWidth: true
                    spacing: MochaDS.Theme.spacing.lg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: qsTr("Limpar Caches do Sistema")
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: qsTr("Remove caches temporários do Pacman, Flatpaks não utilizados e AppStream")
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.Button {
                        text: qsTr("Limpar Cache")
                        icon: "trash"
                        variant: "danger"
                        size: "md"
                        onClicked: {
                            window.consoleLog = "";
                            window.currentAction = qsTr("Limpeza de Cache");
                            window.terminalModal.open = true;
                            backend.clearCache();
                        }
                    }
                }
            }
        }
    }
}
