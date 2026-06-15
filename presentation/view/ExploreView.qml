import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../componentes"

Flickable {
    id: exploreView

    contentHeight: exploreContent.height + MochaDS.Theme.spacing.xxl
    clip: true

    Column {
        id: exploreContent

        width: parent.width
        spacing: 24

        // Header Banner Card
        MochaDS.Card {
            width: parent.width - MochaDS.Theme.spacing.lg
            height: 180
            variant: "accent"
            accentPosition: "left"
            customAccentColor: MochaDS.Theme.colors.mauve
            backgroundColor: "mantle"
            headerSeparator: false
            footerSeparator: false

            Column {
                anchors.fill: parent
                anchors.margins: MochaDS.Theme.spacing.lg
                spacing: MochaDS.Theme.spacing.sm

                Text {
                    text: "Central de Aplicativos Arch"
                    font.family: MochaDS.Theme.typography.familyBold
                    font.pixelSize: MochaDS.Theme.typography.sizeH1
                    color: MochaDS.Theme.colors.text
                }

                Text {
                    text: "Gerencie Pacotes Oficiais (Pacman), AUR e Flatpaks em uma única interface moderna com design Mocha."
                    font.family: MochaDS.Theme.typography.family
                    font.pixelSize: MochaDS.Theme.typography.sizeLg
                    color: MochaDS.Theme.colors.subtext1
                }

                Row {
                    spacing: MochaDS.Theme.spacing.md

                    MochaDS.Badge {
                        text: "Pacman"
                        variant: "primary"
                    }

                    MochaDS.Badge {
                        text: "AUR"
                        variant: "warning"
                    }

                    MochaDS.Badge {
                        text: "Flatpak"
                        variant: "secondary"
                    }

                }

            }

        }

        // Section 1: Package Sources (3 columns)
        Text {
            text: "Fontes de Pacotes"
            font.family: MochaDS.Theme.typography.familyMedium
            font.pixelSize: MochaDS.Theme.typography.sizeXl
            color: MochaDS.Theme.colors.text
        }

        Flow {
            width: parent.width
            spacing: MochaDS.Theme.spacing.lg

            MochaDS.Card {
                title: "Repositórios Oficiais"
                subtitle: "Pacotes pacman do Arch Linux"
                icon: "package"
                variant: "accent"
                accentPosition: "top"
                customAccentColor: MochaDS.Theme.colors.blue
                width: Math.max(260, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                height: 130

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("system");
                    }
                }

            }

            MochaDS.Card {
                title: "AUR (Community)"
                subtitle: "Arch User Repository"
                icon: "users"
                variant: "accent"
                accentPosition: "top"
                customAccentColor: MochaDS.Theme.colors.yellow
                width: Math.max(260, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                height: 130

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("yay");
                    }
                }

            }

            MochaDS.Card {
                title: "Flatpak (Flathub)"
                subtitle: "Aplicativos sandbox universais"
                icon: "box"
                variant: "accent"
                accentPosition: "top"
                customAccentColor: MochaDS.Theme.colors.teal
                width: Math.max(260, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                height: 130

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("flatpak");
                    }
                }

            }

        }

        // Section 2: Popular Categories (4 columns)
        Text {
            text: "Categorias Populares"
            font.family: MochaDS.Theme.typography.familyMedium
            font.pixelSize: MochaDS.Theme.typography.sizeXl
            color: MochaDS.Theme.colors.text
        }

        Flow {
            width: parent.width
            spacing: MochaDS.Theme.spacing.lg

            MochaDS.Card {
                title: "Desenvolvimento"
                icon: "code"
                variant: "tonal"
                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                height: 90

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("development");
                    }
                }

            }

            MochaDS.Card {
                title: "Jogos"
                icon: "gamepad-2"
                variant: "tonal"
                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                height: 90

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("game");
                    }
                }

            }

            MochaDS.Card {
                title: "Gráficos"
                icon: "image"
                variant: "tonal"
                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                height: 90

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("graphics");
                    }
                }

            }

            MochaDS.Card {
                title: "Produtividade"
                icon: "briefcase"
                variant: "tonal"
                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                height: 90

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("office");
                    }
                }

            }

        }

        // Section 3: Recommended (4 columns)
        Text {
            text: "Populares & Recomendados"
            font.family: MochaDS.Theme.typography.familyMedium
            font.pixelSize: MochaDS.Theme.typography.sizeXl
            color: MochaDS.Theme.colors.text
        }

        Flow {
            width: parent.width
            spacing: MochaDS.Theme.spacing.lg

            MochaDS.Card {
                title: "VS Code"
                subtitle: "Editor de código"
                icon: "code"
                variant: "accent"
                accentPosition: "top"
                customAccentColor: MochaDS.Theme.colors.blue
                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                height: 120

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("visual-studio-code");
                    }
                }

            }

            MochaDS.Card {
                title: "GIMP"
                subtitle: "Editor de imagens"
                icon: "image"
                variant: "accent"
                accentPosition: "top"
                customAccentColor: MochaDS.Theme.colors.green
                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                height: 120

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("gimp");
                    }
                }

            }

            MochaDS.Card {
                title: "VLC Player"
                subtitle: "Reprodutor de mídia"
                icon: "play"
                variant: "accent"
                accentPosition: "top"
                customAccentColor: MochaDS.Theme.colors.peach
                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                height: 120

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("vlc");
                    }
                }

            }

            MochaDS.Card {
                title: "Firefox"
                subtitle: "Navegador Web"
                icon: "globe"
                variant: "accent"
                accentPosition: "top"
                customAccentColor: MochaDS.Theme.colors.red
                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                height: 120

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.searchFor("firefox");
                    }
                }

            }

        }

    }

    ScrollBar.vertical: ScrollBar {
    }
}
