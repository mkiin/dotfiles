pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Bluetooth の状態と操作。値は BlueZ が持つので、ここでは保持せず参照と導出だけを行う。
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    // アダプタが無い場合の既定値をここで決め、利用側に null 安全を書かせない。
    readonly property bool powered: root.adapter?.enabled ?? false
    readonly property bool scanning: root.adapter?.discovering ?? false

    // 表示順: 接続中 → ペアリング済み → 名前順
    readonly property var devices: [...Bluetooth.devices.values].sort((left, right) => {
        if (left.connected !== right.connected)
            return right.connected - left.connected;
        if (left.bonded !== right.bonded)
            return right.bonded - left.bonded;
        return left.name.localeCompare(right.name);
    })

    readonly property var connectedDevices: root.devices.filter(device => device.connected)

    function togglePower(): void {
        if (root.adapter)
            root.adapter.enabled = !root.adapter.enabled;
    }

    function toggleScan(): void {
        if (root.adapter)
            root.adapter.discovering = !root.adapter.discovering;
    }

    // 押したときの遷移。処理中はキャンセル、未ペアならペアリングから始める。
    function toggleDevice(device): void {
        if (!device)
            return;
        if (device.pairing)
            device.cancelPair();
        else if (device.connected)
            device.disconnect();
        else if (device.bonded)
            device.connect();
        else
            device.pair();
    }

    function forget(device): void {
        if (device)
            device.forget();
    }

    // 自動再接続の許可。接続時に暗黙で立てず、明示操作でのみ変える。
    function setTrusted(device, trusted: bool): void {
        if (device)
            device.trusted = trusted;
    }
}
