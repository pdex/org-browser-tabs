window.browser = (function () {
  return window.msBrowser ||
    window.browser ||
    window.chrome;
})();

var org_browser_tabs_server_port = "";

//console.log("org-browser-tabs content script started");

function logTabs(tabs) {
  for (let tab of tabs) {
    // tab.url requires the `tabs` permission
    console.log(tab.url);
  }
}

function onError(error) {
  console.log(`Error: ${error}`);
}

function titleAndUrl(tab) {
  return {
    "title": tab.title,
    "url": tab.url
  }
}

function handleWindows(windows) {
  var windowCount = 0;
  var tabCount = 0;
  var payload = windows.map(function(window) {
    var name = "Window-" + window.id;
    windowCount += 1;
    tabCount += window.tabs.length;
    return {
      name: name,
      focused: window.focused,
      tabs: window.tabs.map(titleAndUrl)
    };
  }).reduce(function(accumulated, value){
    if (value.focused) {
      accumulated.focused = value.name;
    }
    accumulated[value.name] = value.tabs
    return accumulated;
  }, {"focused": null});
  window.browser.browserAction.setTitle({title: windowCount + " Windows / " + tabCount + " Tabs"});
  window.browser.browserAction.setBadgeText({text: tabCount.toString()});
  return {windows: windowCount,
          tabs: tabCount,
          payload: payload};
}

function transmit(windowsAndTabs) {
  // The emacs web server only understands multipart forms and chunked data.
  // So we're using a FormData object here to ferry the json payload over the wire
  //var
  xhr = new XMLHttpRequest();
  xhr.open("POST", "http://localhost:" + org_browser_tabs_server_port + "/", true);
  //var
  formData = new FormData();
  formData.append("windows", windowsAndTabs.windows);
  formData.append("tabs", windowsAndTabs.tabs);
  formData.append("payload", JSON.stringify(windowsAndTabs.payload));
  xhr.send(formData);
}


function handler(windows) {
  windowsAndTabs = handleWindows(windows);
  console.log("sending");
  transmit(windowsAndTabs);
  //console.log(windowsAndTabs);
}

function init() {
  window.browser.windows.getAll({populate: true}, handler);
}

chrome.storage.sync.get({
  port: "9090"
}, function(items) {
  org_browser_tabs_server_port = items.port;
  init();
});

function tabUpdatedListener(tabId, changeInfo, tab) {
  console.log("tab updated: " + tabId + " changeInfo: " + changeInfo);
  init();
}

function tabCreatedListener(tab) {
  console.log("tab created");
  init();
}

function tabRemovedListener(tabId, removeInfo) {
  console.log("tab removed");
  init();
}

window.browser.tabs.onCreated.addListener(tabCreatedListener);

window.browser.tabs.onUpdated.addListener(tabUpdatedListener);

window.browser.tabs.onRemoved.addListener(tabRemovedListener);
