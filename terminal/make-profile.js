ObjC.import('AppKit');
function arch(o){ return $.NSKeyedArchiver.archivedDataWithRootObjectRequiringSecureCodingError(o, false, null); }
function c(hex, a){ a = a===undefined?1:a;
  var r=parseInt(hex.substr(1,2),16)/255, g=parseInt(hex.substr(3,2),16)/255, b=parseInt(hex.substr(5,2),16)/255;
  return arch($.NSColor.colorWithSRGBRedGreenBlueAlpha(r,g,b,a)); }
var font = $.NSFont.fontWithNameSize('HackNFM-Regular', 14);
if (!font || font.isNil()) throw "Falta la fuente Hack Nerd Font (brew install --cask font-hack-nerd-font)";
var env = $.NSProcessInfo.processInfo.environment;
function envv(k, def){ var v = env.objectForKey(k); return (v && !v.isNil()) ? ObjC.unwrap(v) : def; }
// Variantes por pestaña: NAME, BG (hex) y ALPHA opcionales (ver install.sh)
var NAME = envv('NAME', 'Farid'), BG = envv('BG', '#0f111a'), ALPHA = parseFloat(envv('ALPHA', '0.70'));
var d = $.NSMutableDictionary.alloc.init;
function set(k,v){ d.setObjectForKey(v, $(k)); }
set('name', $(NAME));
set('type', $('Window Settings'));
set('ProfileCurrentVersion', $(2.07));
set('Font', arch(font));
set('BackgroundColor', c(BG, ALPHA));
set('BackgroundBlur', $(0.6));
set('BackgroundBlurInactive', $(0.6));
set('TextColor', c('#e6edff'));
set('TextBoldColor', c('#ffffff'));
set('CursorColor', c('#ff79c6'));
set('CursorType', $(2));
set('SelectionColor', c('#3d59a1'));
var ansi = {Black:['#1b1e2b','#5c6690'],Red:['#ff5370','#ff6e85'],Green:['#50fa7b','#7dffa0'],Yellow:['#ffcb6b','#ffe08a'],
  Blue:['#5ea8ff','#82bfff'],Magenta:['#c792ea','#e0aaff'],Cyan:['#00e5ff','#6cf6ff'],White:['#c3cee3','#ffffff']};
for (var k in ansi){ set('ANSI'+k+'Color', c(ansi[k][0])); set('ANSIBright'+k+'Color', c(ansi[k][1])); }
set('columnCount', $(110)); set('rowCount', $(30));
set('UseBrightBold', $(true));
d.writeToFileAtomically($(envv('OUT')), true);
'ok';
