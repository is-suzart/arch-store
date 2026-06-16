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
                    text: "Configurações"
                    font.family: MochaDS.Theme.typography.familyBold
                    font.pixelSize: MochaDS.Theme.typography.sizeH1
                    color: MochaDS.Theme.colors.text
                }
                Text {
                    text: "Personalize e gerencie o comportamento da sua loja de aplicativos"
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
            title: "Aparência"
            subtitle: "Personalize a interface visual do aplicativo"
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
                            text: "Tema de Cores"
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: "Selecione uma das 4 variantes oficiais do Catppuccin"
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.Select {
                        id: themeSelect
                        width: 320
                        options: [
                            { value: "latte", label: "Catppuccin Latte (Claro)" },
                            { value: "frappe", label: "Catppuccin Frappé (Escuro Suave)" },
                            { value: "macchiato", label: "Catppuccin Macchiato (Escuro Médio)" },
                            { value: "mocha", label: "Catppuccin Mocha (Escuro Profundo)" }
                        ]
                        placeholder: "Selecione o tema..."
                        onValueChanged: function(val) {
                            if (val) {
                                backend.setConfigStr("theme_flavor", val);
                                MochaDS.Theme.flavor = val;
                                toasts.success("Tema alterado para " + selectedLabel, "Sucesso");
                            }
                        }
                    }
                }
            }
        }

        // Section 2: Fontes de Pacotes (Package Sources)
        MochaDS.Card {
            Layout.fillWidth: true
            title: "Fontes de Pacotes"
            subtitle: "Ative ou desative repositórios adicionais"
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
                            text: "Habilitar AUR (Arch User Repository)"
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: "Permite buscar e instalar pacotes mantidos pela comunidade do Arch Linux"
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.ToggleButton {
                        id: aurToggle
                        onToggled: function(state) {
                            backend.setConfigBool("enable_aur", state);
                            toasts.info("Suporte ao AUR " + (state ? "habilitado" : "desabilitado"), "Configuração salva");
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
                            text: "Habilitar Flatpak"
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: "Habilita suporte a aplicativos empacotados em formato sandbox via Flathub"
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.ToggleButton {
                        id: flatpakToggle
                        onToggled: function(state) {
                            backend.setConfigBool("enable_flatpak", state);
                            toasts.info("Suporte ao Flatpak " + (state ? "habilitado" : "desabilitado"), "Configuração salva");
                        }
                    }
                }
            }
        }

        // Section 3: Atualizações (Updates)
        MochaDS.Card {
            Layout.fillWidth: true
            title: "Atualizações"
            subtitle: "Gerencie a verificação de atualizações de pacotes"
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
                            text: "Verificar Atualizações ao Iniciar"
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: "Busca automaticamente por novos pacotes atualizáveis ao abrir a Arch Store"
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.ToggleButton {
                        id: startupUpdateToggle
                        onToggled: function(state) {
                            backend.setConfigBool("check_updates_startup", state);
                            toasts.info("Verificação inicial " + (state ? "habilitada" : "desabilitada"), "Configuração salva");
                        }
                    }
                }
            }
        }

        // Section 4: Manutenção (Maintenance)
        MochaDS.Card {
            Layout.fillWidth: true
            title: "Manutenção"
            subtitle: "Limpeza e otimização do sistema"
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
                            text: "Limpar Caches do Sistema"
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                        }
                        Text {
                            text: "Remove caches temporários do Pacman, Flatpaks não utilizados e AppStream"
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext0
                        }
                    }

                    MochaDS.Button {
                        text: "Limpar Cache"
                        icon: "trash"
                        variant: "danger"
                        size: "md"
                        onClicked: {
                            window.consoleLog = "";
                            window.currentAction = "Limpeza de Cache";
                            window.terminalModal.open = true;
                            backend.clearCache();
                        }
                    }
                }
            }
        }
    }
}
