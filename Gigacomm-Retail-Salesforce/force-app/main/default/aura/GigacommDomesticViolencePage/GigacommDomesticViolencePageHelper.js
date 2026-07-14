/* eslint-disable no-unused-expressions, no-unused-vars, no-console */
({
  disguisePageTitle: function () {
    document.title = "Gigacomm";
  },
  exitPage: function () {
    var safeUrl = "https://www.bom.gov.au/";

    // Disguise the page in browser history by replacing the title
    // and URL with something neutral before navigating away.
    try {
      document.title = "Gigacomm";
      window.history.replaceState(null, "Gigacomm", window.location.origin);
    } catch (e) {
      // Gracefully continue if replaceState is restricted.
    }

    // Navigate the current tab to the safe site.
    // Using replace() so the current page URL is not kept in history.
    window.location.replace(safeUrl);
  }
});
