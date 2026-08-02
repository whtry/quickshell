import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets.common

StyledFlickable {
    id: root

    clip: true
    contentWidth: width
    contentHeight: contentColumn.y + contentColumn.implicitHeight + 24

    readonly property real pageContentWidth: 600
    readonly property var systemMonitorMetrics: [
        ({ "id": "cpu", "title": qsTr("CPU 占用"),
           "icon": "memory" }),
        ({ "id": "temperature", "title": qsTr("CPU 温度"),
           "icon": "device_thermostat" }),
        ({ "id": "gpu", "title": qsTr("GPU 占用"),
           "icon": "developer_board" }),
        ({ "id": "cpuPower", "title": qsTr("CPU 功耗"),
           "icon": "bolt" }),
        ({ "id": "gpuPower", "title": qsTr("GPU 功耗"),
           "icon": "electric_bolt" }),
        ({ "id": "disk", "title": qsTr("硬盘占用"),
           "icon": "hard_drive" })
    ]
    readonly property var extensionComponents: [
        ({ "id": "appLauncher", "title": qsTr("顶栏应用启动器"),
           "description": qsTr("在顶栏左侧显示应用启动按钮"),
           "icon": "apps" }),
        ({ "id": "codexUsage", "title": qsTr("Codex 用量"),
           "description": qsTr("显示 Codex 账户剩余额度；需要安装 codexbar"),
           "icon": "data_object" }),
        ({ "id": "powerProfiles", "title": qsTr("电源模式选择器"),
           "description": qsTr("在快速设置中显示节能、平衡和性能模式"),
           "icon": "speed" }),
        ({ "id": "batteryRing", "title": qsTr("电源键电量显示"),
           "description": qsTr("仅在检测到电池时显示所选电量效果"),
           "icon": "battery_full" }),
        ({ "id": "powerProfileRefreshRate",
           "title": qsTr("电源模式联动刷新率"),
           "description": qsTr("节能模式选择约 60 Hz，其他模式选择当前分辨率的最高刷新率"),
           "icon": "display_settings" })
    ]
    readonly property var templatePrograms: [
        ({
            "id": "btop",
            "title": "btop",
            "icon": "monitoring"
        }),
        ({
            "id": "cava",
            "title": "Cava",
            "icon": "graphic_eq"
        }),
        ({
            "id": "kitty",
            "title": "Kitty",
            "icon": "terminal"
        }),
        ({
            "id": "fcitx5",
            "title": "Fcitx5",
            "icon": "keyboard"
        }),
        ({
            "id": "niri",
            "title": "Niri",
            "icon": "window"
        }),
        ({
            "id": "yazi",
            "title": "Yazi",
            "icon": "folder"
        }),
        ({
            "id": "zsh_prompt",
            "title": "Zsh prompt",
            "icon": "code"
        })
    ]

    ColumnLayout {
        id: contentColumn

        width: Math.min(root.pageContentWidth,
            Math.max(0, root.width - 48))
        x: Math.max(24, (root.width - width) / 2)
        y: 28
        spacing: Appearance.spacing.medium

        InlineStatusBanner {
            Layout.fillWidth: true
            visible: ThemeService.generating
            message: qsTr("正在为已启用的程序生成 Matugen 配色…")
            iconName: "progress_activity"
        }

        SettingsSection {
            Layout.fillWidth: true
            title: qsTr("Shell 外观")
            supportingText: qsTr("控制 Clavis 顶栏、侧边栏、设置中心和弹出面板是否跟随主题的深浅色变化。")

            SettingsRow {
                Layout.fillWidth: true
                iconName: "contrast"
                title: qsTr("Clavis 界面跟随深浅色")
                supportingText: PersonalizationConfig.shellFollowThemeMode
                    ? qsTr("已跟随；日出日落自动模式也会同步改变 Shell 配色")
                    : qsTr("已关闭；应用仍会切换，Clavis 保持当前配色")

                trailing: StyledSwitch {
                    checked: PersonalizationConfig.shellFollowThemeMode
                    Accessible.name: qsTr("Clavis 界面跟随深浅色")
                    onToggled:
                        ThemeService.setShellFollowThemeMode(checked)
                }
            }

        }

        SettingsSection {
            Layout.fillWidth: true
            title: qsTr("顶栏系统监控")
            supportingText: qsTr("选择鼠标悬停在右上角内存指标时展开显示的内容。内存用量始终作为折叠状态的主指标。")

            Repeater {
                model: root.systemMonitorMetrics

                SettingsRow {
                    required property var modelData

                    Layout.fillWidth: true
                    iconName: modelData.icon
                    title: modelData.title
                    supportingText:
                        PersonalizationConfig
                            .isBarSystemMonitorMetricEnabled(modelData.id)
                        ? qsTr("悬停展开时显示")
                        : qsTr("已隐藏")

                    trailing: StyledSwitch {
                        checked:
                            PersonalizationConfig
                                .isBarSystemMonitorMetricEnabled(
                                    modelData.id)
                        Accessible.name:
                            qsTr("显示%1").arg(modelData.title)
                        onToggled:
                            PersonalizationConfig
                                .setBarSystemMonitorMetricEnabled(
                                    modelData.id, checked)
                    }
                }
            }

        }

        SettingsSection {
            Layout.fillWidth: true
            title: qsTr("扩展组件")
            supportingText: qsTr("这些功能不是 Clavis 的通用默认组件，可按设备和使用习惯单独启用。")

            Repeater {
                model: root.extensionComponents

                SettingsRow {
                    required property var modelData

                    Layout.fillWidth: true
                    iconName: modelData.icon
                    title: modelData.title
                    supportingText: modelData.description

                    trailing: StyledSwitch {
                        checked: PersonalizationConfig
                            .isExtensionEnabled(modelData.id)
                        Accessible.name:
                            qsTr("启用%1").arg(modelData.title)
                        onToggled: PersonalizationConfig
                            .setExtensionEnabled(modelData.id, checked)
                    }
                }
            }

            SettingsRow {
                Layout.fillWidth: true
                visible: PersonalizationConfig
                    .isExtensionEnabled("batteryRing")
                iconName: "battery_android_frame_full"
                title: qsTr("电量显示样式")
                supportingText:
                    PersonalizationConfig.powerButtonBatteryStyle === "wave"
                    ? qsTr("淡色按钮内用深色波浪高度表示剩余电量")
                    : qsTr("在电源按钮外围用进度圆环表示剩余电量")

                trailing: StyledButtonGroup {
                    model: PersonalizationConfig.powerButtonBatteryStyles
                    currentValue:
                        PersonalizationConfig.powerButtonBatteryStyle
                    style: StyledButtonGroup.Style.Tonal
                    buttonHeight: 34
                    horizontalPadding: 16
                    onValueSelected: value => PersonalizationConfig
                        .setPowerButtonBatteryStyle(value)
                }
            }

            SettingsRow {
                Layout.fillWidth: true
                visible: PersonalizationConfig
                    .isExtensionEnabled("batteryRing")
                    && PersonalizationConfig.powerButtonBatteryStyle
                        === "wave"
                iconName: "animation"
                title: qsTr("波浪动画")
                supportingText:
                    PersonalizationConfig.waveBatteryAnimationEnabled
                    ? qsTr("液面持续流动") : qsTr("液面保持静止")

                trailing: StyledSwitch {
                    checked:
                        PersonalizationConfig.waveBatteryAnimationEnabled
                    Accessible.name: qsTr("启用波浪动画")
                    onToggled: PersonalizationConfig
                        .setWaveBatteryAnimationEnabled(checked)
                }
            }

            SettingsRow {
                Layout.fillWidth: true
                visible: PersonalizationConfig
                    .isExtensionEnabled("batteryRing")
                    && PersonalizationConfig.powerButtonBatteryStyle
                        === "wave"
                enabled: PersonalizationConfig.waveBatteryAnimationEnabled
                iconName: "battery_saver"
                title: qsTr("动画跟随节能模式")
                supportingText:
                    PersonalizationConfig
                        .waveBatteryAnimationFollowPowerProfile
                    ? qsTr("进入节能模式时自动暂停波浪")
                    : qsTr("所有电源模式下都保持动画")

                trailing: StyledSwitch {
                    checked: PersonalizationConfig
                        .waveBatteryAnimationFollowPowerProfile
                    Accessible.name: qsTr("动画跟随节能模式")
                    onToggled: PersonalizationConfig
                        .setWaveBatteryAnimationFollowPowerProfile(checked)
                }
            }
        }

        SettingsSection {
            Layout.fillWidth: true
            title: qsTr("Matugen 模板生成")
            supportingText: qsTr("壁纸或主题变化时，仅为已启用的程序生成模板。Quickshell 配色始终生成。关闭开关不会删除已有配色文件。")

            Repeater {
                model: root.templatePrograms

                SettingsRow {
                    required property var modelData

                    Layout.fillWidth: true
                    iconName: modelData.icon
                    title: modelData.title
                    supportingText:
                        PersonalizationConfig
                            .isMatugenTemplateEnabled(modelData.id)
                        ? qsTr("生成并更新 Matugen 配色")
                        : qsTr("已停止后续生成；现有配色文件会保留")

                    trailing: StyledSwitch {
                        enabled: !ThemeService.generating
                        checked: PersonalizationConfig
                            .isMatugenTemplateEnabled(modelData.id)
                        Accessible.name:
                            qsTr("启用 %1 Matugen 模板")
                                .arg(modelData.title)
                        onToggled:
                            ThemeService.setMatugenTemplateEnabled(
                                modelData.id, checked)
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
        }
    }
}
