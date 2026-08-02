pragma Singleton

import Quickshell
import qs.Common

Singleton {
    function toggle() {
        Quickshell.execDetached([
            "qs", "--path", Paths.shellDir,
            "ipc", "call", "spotlight", "toggle"
        ]);
    }
}
