var mode;
var enabled = false;
var scheme = '';
var timeoutId = null;

var filterMap = {
  '0': 'url("#hc_extension_off")',
  '1': 'url("#hc_extension_highcontrast")',
  '2': 'url("#hc_extension_grayscale")',
  '3': 'url("#hc_extension_invert")',
  '4': 'url("#hc_extension_invert_grayscale")',
  '5': 'url("#hc_extension_yellow_on_black")'
};

var svgContent = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1"><defs><filter id="hc_extension_off"><feComponentTransfer><feFuncR type="table" tableValues="0 1"/><feFuncG type="table" tableValues="0 1"/><feFuncB type="table" tableValues="0 1"/></feComponentTransfer></filter><filter id="hc_extension_highcontrast"><feComponentTransfer><feFuncR type="gamma" exponent="3.0"/><feFuncG type="gamma" exponent="3.0"/><feFuncB type="gamma" exponent="3.0"/></feComponentTransfer></filter><filter id="hc_extension_highcontrast_back"><feComponentTransfer><feFuncR type="gamma" exponent="0.33"/><feFuncG type="gamma" exponent="0.33"/><feFuncB type="gamma" exponent="0.33"/></feComponentTransfer></filter><filter id="hc_extension_grayscale"><feColorMatrix type="matrix" values="0.2126 0.7152 0.0722 0 0 0.2126 0.7152 0.0722 0 0 0.2126 0.7152 0.0722 0 0 0 0 0 1 0"/><feComponentTransfer><feFuncR type="gamma" exponent="3"/><feFuncG type="gamma" exponent="3"/><feFuncB type="gamma" exponent="3"/></feComponentTransfer></filter><filter id="hc_extension_grayscale_back"><feComponentTransfer><feFuncR type="gamma" exponent="0.33"/><feFuncG type="gamma" exponent="0.33"/><feFuncB type="gamma" exponent="0.33"/></feComponentTransfer></filter>' +
'<filter filterRes="1000" id="hc_extension_invert">' +
  '<feComponentTransfer>' +
    '<feFuncR type="table" tableValues="1 0"/>' +
    '<feFuncG type="table" tableValues="1 0"/>' +
    '<feFuncB type="table" tableValues="1 0"/>' +
  /*
    '<feFuncR type="gamma" amplitude="-1" exponent="3" offset="1"/>' +
    '<feFuncG type="gamma" amplitude="-1" exponent="3" offset="1"/>' +
    '<feFuncB type="gamma" amplitude="-1" exponent="3" offset="1"/>' +
  */
  '</feComponentTransfer>' +
'</filter><filter id="hc_extension_invert_back"><feComponentTransfer><feFuncR type="table" tableValues="1 0"/><feFuncG type="table" tableValues="1 0"/><feFuncB type="table" tableValues="1 0"/></feComponentTransfer><feComponentTransfer><feFuncR type="gamma" exponent="1.7"/><feFuncG type="gamma" exponent="1.7"/><feFuncB type="gamma" exponent="1.7"/></feComponentTransfer></filter><filter id="hc_extension_invert_grayscale"><feColorMatrix type="matrix" values="0.2126 0.7152 0.0722 0 0 0.2126 0.7152 0.0722 0 0 0.2126 0.7152 0.0722 0 0 0 0 0 1 0"/><feComponentTransfer><feFuncR type="gamma" amplitude="-1" exponent="3" offset="1"/><feFuncG type="gamma" amplitude="-1" exponent="3" offset="1"/><feFuncB type="gamma" amplitude="-1" exponent="3" offset="1"/></feComponentTransfer></filter><filter id="hc_extension_yellow_on_black"><feComponentTransfer><feFuncR type="gamma" amplitude="-1" exponent="3" offset="1"/><feFuncG type="gamma" amplitude="-1" exponent="3" offset="1"/><feFuncB type="gamma" amplitude="-1" exponent="3" offset="1"/></feComponentTransfer><feColorMatrix type="matrix" values="0.3 0.5 0.2 0 0 0.3 0.5 0.2 0 0 0 0 0 0 0 0 0 0 1 0"/></filter><filter id="hc_extension_yellow_on_black_back"><feComponentTransfer><feFuncR type="table" tableValues="1 0"/><feFuncG type="table" tableValues="1 0"/><feFuncB type="table" tableValues="1 0"/></feComponentTransfer><feComponentTransfer><feFuncR type="gamma" exponent="0.33"/><feFuncG type="gamma" exponent="0.33"/><feFuncB type="gamma" exponent="0.33"/></feComponentTransfer></filter></defs></svg>';

function addSvgIfMissing() {
  var wrap = document.getElementById('hc_extension_svg_filters');
  if (wrap)
    return;
  if (window == window.top) console.log(window.location.href + ' HighContrast Adding SVG');
  wrap = document.createElement('span');
  wrap.id = 'hc_extension_svg_filters';
  wrap.setAttribute('hidden', '');
  wrap.innerHTML = svgContent;
  document.body.appendChild(wrap);
}

function update() {
  var html = document.documentElement;
  if (enabled) {
    if (!document.body) {
      if (window == window.top) console.log(window.location.href + '   HighContrast waiting and trying again');
      window.setTimeout(update, 100);
      return;
    }
    addSvgIfMissing();
    if (html.getAttribute('hc') != mode + scheme)
      html.setAttribute('hc', mode + scheme);
    if (html.getAttribute('hcx') != scheme)
      html.setAttribute('hcx', scheme);
    if (window == window.top) console.log(window.location.href + ' HighContrast Setting hc=' + mode + scheme + ' and hcx=' + scheme);

    if (window == window.top) {
      window.scrollBy(0, 1);
      window.scrollBy(0, -1);
    }

    /**
    if (mode == 'a') {
      html.style.webkitFilter = filterMap[scheme];
    }
    else {
      html.style.webkitFilter = 'none';
    }**/

  } else {
    html.setAttribute('hc', mode + '0');
    html.setAttribute('hcx', '0');
    window.setTimeout(function() {
      html.removeAttribute('hc');
      html.removeAttribute('hcx');
    }, 0);
    if (window == window.top) console.log(window.location.href + ' HighContrast Remove attributes');
  }
}

function onExtensionMessage(request) {
  if (window == window.top) console.log(window.location.href + ' HighContrast onExtensionMessage');
  if (enabled != request.enabled || scheme != request.scheme) {
    enabled = request.enabled;
    scheme = request.scheme;
    update();
  }
}

function onEvent(evt) {
  if (evt.keyCode == 122 /* F11 */ &&
      evt.shiftKey) {
    chrome.extension.sendRequest({'toggle_global': true});
    evt.stopPropagation();
    evt.preventDefault();
    return false;
  }
  if (evt.keyCode == 123 /* F12 */ &&
      evt.shiftKey) {
    chrome.extension.sendRequest({'toggle_site': true});
    evt.stopPropagation();
    evt.preventDefault();
    return false;
  }
  return true;
}

function init() {
  if (window == window.top) console.log(window.location.href + ' HighContrast init');
  if (window == window.top) {
    if (window == window.top) console.log(window.location.href + '   HighContrast init mode A');
    mode = 'a';
  } else {
    if (window == window.top) console.log(window.location.href + '   HighContrast init mode B');
    mode = 'b';
  }
  chrome.extension.onRequest.addListener(onExtensionMessage);
  chrome.extension.sendRequest({'init': true}, onExtensionMessage);
  document.addEventListener('keydown', onEvent, false);

  // Work around bug that causes filter to be lost when the HTML element's attributes change.
  var html = document.documentElement; 
  var config = { attributes: true, childList: false, characterData: false };
  var observer = new MutationObserver(function(mutations) {
    console.log('Updating because HTML element modified');
    observer.disconnect();
    html.removeAttribute('hc');
    html.removeAttribute('hcx');
    window.setTimeout(function() {
      update();
      window.setTimeout(function() {
        observer.observe(html, config);
      }, 0);
    }, 0);
  });
  observer.observe(html, config);
}

init();
