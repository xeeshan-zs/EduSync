
// Web implementation
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui'; // for VoidCallback

class PwaHelper {
  // Use dynamic because BeforeInstallPromptEvent is not in dart:html
  dynamic _deferredPrompt;
  bool _ready = false;

  Future<void> init(VoidCallback onStateChange) async {
    void checkForPrompt() {
      // Use js_util to get the property safely from the window object
      final jsPrompt = js_util.getProperty(html.window, 'deferredPrompt');
      if (jsPrompt != null) {
        _deferredPrompt = jsPrompt;
        if (!_ready) {
           _ready = true;
           onStateChange();
        }
      }
    }

    // Check immediately
    checkForPrompt();

    // Listen for the event using the string name
    html.window.on['beforeinstallprompt'].listen((event) {
      // event.preventDefault(); // allow native browser prompt
      _deferredPrompt = event;
      _ready = true;
      onStateChange();
    });
    
    // Listen for custom event
    html.window.addEventListener('pwa_prompt_ready', (event) {
       checkForPrompt();
    });
  }

  bool get canInstall => _ready && _deferredPrompt != null;

  Future<void> installApp() async {
    if (_deferredPrompt != null) {
      // Call prompt() dynamically
      js_util.callMethod(_deferredPrompt, 'prompt', []);
      
      // userChoice returns a Promise, convert it to Future
      final userChoicePromise = js_util.getProperty(_deferredPrompt, 'userChoice');
      final userChoice = await js_util.promiseToFuture(userChoicePromise);
      
      // Access outcome property dynamically
      final outcome = js_util.getProperty(userChoice, 'outcome');
      
      print('User choice: $outcome');
      
      if (outcome == 'accepted') {
        _deferredPrompt = null;
        _ready = false;
      }
    }
  }
}
