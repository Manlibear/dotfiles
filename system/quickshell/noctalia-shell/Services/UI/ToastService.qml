pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  // Simple signal-based notification system
  // actionLabel: optional label for clickable action link
  // actionCallback: optional function to call when action is clicked
  signal notify(string title, string description, string icon, string type, int duration, string actionLabel, var actionCallback, string image)
  signal dismiss

  // Convenience methods
  // image: optional path to a real app icon/avatar, takes priority over the icon glyph when set
  function showNotice(title, description = "", icon = "", duration = 3000, actionLabel = "", actionCallback = null, image = "") {
    notify(title, description, icon, "notice", duration, actionLabel, actionCallback, image);
  }

  function showWarning(title, description = "", duration = 4000, actionLabel = "", actionCallback = null, image = "") {
    notify(title, description, "", "warning", duration, actionLabel, actionCallback, image);
  }

  function showError(title, description = "", duration = 6000, actionLabel = "", actionCallback = null, image = "") {
    notify(title, description, "", "error", duration, actionLabel, actionCallback, image);
  }

  function dismissToast() {
    dismiss();
  }
}
