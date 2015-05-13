library three.logging;

import 'dart:html' show window;

warn(String msg) => window.console.warn(msg);
log(String msg) => window.console.log(msg);
error(String msg) => window.console.error(msg);
