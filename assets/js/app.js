// Import dependencies
import "phoenix_html"

// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
// import topbar from "../vendor/topbar.js"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Enable debugging for LiveSocket
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  dom: {
    onBeforeElUpdated(from, to){
      if(from._x_dataStack){ to._x_dataStack = from._x_dataStack; }
    }
  }
})

// Show progress bar on live navigation and form submits
// topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
// window.addEventListener("phx:page-loading-start", info => topbar.show())
// window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// Enable debug mode and expose liveSocket on window for web console debug logs and latency simulation
liveSocket.enableDebug()
window.liveSocket = liveSocket

// Add some debugging to check if LiveSocket is working
console.log("LiveSocket initialized:", liveSocket)
console.log("CSRF Token:", csrfToken)

// Add event listener to check if forms are being intercepted
document.addEventListener('DOMContentLoaded', function() {
  console.log("DOM loaded, checking for LiveView elements...")
  const liveViewElements = document.querySelectorAll('[data-phx-main]')
  console.log("Found LiveView elements:", liveViewElements.length)
  
  const forms = document.querySelectorAll('form[phx-submit]')
  console.log("Found LiveView forms:", forms.length)
  
  // Check WebSocket connection status
  setTimeout(() => {
    console.log("LiveSocket connection status:", liveSocket.isConnected())
  }, 2000)
})

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
