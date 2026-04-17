// Generates self-contained HTML business card pages.
// All CSS and JS are inline — no external dependencies.
// Mobile-first responsive design with dark/light theme support.

/// Generates a full-featured HTML business card page with contact info,
/// social links, save/share buttons, and optional QR code.
String generateBusinessCardHtml({
  required String name,
  String? title,
  String? company,
  String? phone,
  String? email,
  String? website,
  String? linkedin,
  String? instagram,
  String? github,
  String? twitter,
  String accentColor = '#00B0FF',
  bool darkMode = true,
}) {
  final bg = darkMode ? '#0D1117' : '#F8FAFC';
  final cardBg = darkMode ? '#161B22' : '#FFFFFF';
  final textPrimary = darkMode ? '#E6EDF3' : '#1F2937';
  final textSecondary = darkMode ? '#8B949E' : '#6B7280';
  final borderColor = darkMode ? '#30363D' : '#E5E7EB';
  final dividerColor = darkMode ? '#21262D' : '#F3F4F6';
  final btnBg = darkMode ? '#21262D' : '#F3F4F6';
  final btnText = darkMode ? '#E6EDF3' : '#1F2937';

  // Build vCard string
  final vcardLines = <String>[
    'BEGIN:VCARD',
    'VERSION:3.0',
    'FN:$name',
  ];
  if (title != null) vcardLines.add('TITLE:$title');
  if (company != null) vcardLines.add('ORG:$company');
  if (phone != null) vcardLines.add('TEL:$phone');
  if (email != null) vcardLines.add('EMAIL:$email');
  if (website != null) {
    final url = website.startsWith('http') ? website : 'https://$website';
    vcardLines.add('URL:$url');
  }
  vcardLines.add('END:VCARD');
  final vcardStr = vcardLines.join('\\n');

  // Contact items
  final contactItems = StringBuffer();

  if (phone != null) {
    contactItems.write('''
<a href="tel:$phone" class="ci">
  <span class="ci-icon">${_svgPhone(accentColor)}</span>
  <span>$phone</span>
</a>''');
  }

  if (email != null) {
    contactItems.write('''
<a href="mailto:$email" class="ci">
  <span class="ci-icon">${_svgEmail(accentColor)}</span>
  <span>$email</span>
</a>''');
  }

  if (website != null) {
    final url = website.startsWith('http') ? website : 'https://$website';
    contactItems.write('''
<a href="$url" target="_blank" rel="noopener" class="ci">
  <span class="ci-icon">${_svgGlobe(accentColor)}</span>
  <span>$website</span>
</a>''');
  }

  // Social links
  final socialLinks = StringBuffer();
  if (linkedin != null) {
    final href = linkedin.startsWith('http')
        ? linkedin
        : 'https://linkedin.com/in/$linkedin';
    socialLinks.write(
        '<a href="$href" target="_blank" rel="noopener" class="sl" title="LinkedIn">${_svgLinkedin(accentColor)}</a>');
  }
  if (instagram != null) {
    final href = instagram.startsWith('http')
        ? instagram
        : 'https://instagram.com/$instagram';
    socialLinks.write(
        '<a href="$href" target="_blank" rel="noopener" class="sl" title="Instagram">${_svgInstagram(accentColor)}</a>');
  }
  if (github != null) {
    final href =
        github.startsWith('http') ? github : 'https://github.com/$github';
    socialLinks.write(
        '<a href="$href" target="_blank" rel="noopener" class="sl" title="GitHub">${_svgGithub(accentColor)}</a>');
  }
  if (twitter != null) {
    final href =
        twitter.startsWith('http') ? twitter : 'https://x.com/$twitter';
    socialLinks.write(
        '<a href="$href" target="_blank" rel="noopener" class="sl" title="Twitter">${_svgTwitter(accentColor)}</a>');
  }

  final hasSocials = linkedin != null ||
      instagram != null ||
      github != null ||
      twitter != null;
  final hasContacts = phone != null || email != null || website != null;

  // Title + company line
  final subtitleParts = <String>[];
  if (title != null) subtitleParts.add(title);
  if (company != null) subtitleParts.add(company);
  final subtitle = subtitleParts.join(' · ');

  return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>$name</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:$bg;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:16px}
.card{width:100%;max-width:420px;background:$cardBg;border-radius:16px;border:1px solid $borderColor;overflow:hidden;position:relative}
.accent{height:4px;background:$accentColor}
.body{padding:28px 24px 24px}
.name{font-size:28px;font-weight:700;color:$textPrimary;line-height:1.2}
.sub{font-size:15px;color:$textSecondary;margin-top:4px}
.div{height:1px;background:$dividerColor;margin:20px 0}
.ci{display:flex;align-items:center;gap:12px;padding:10px 0;color:$textPrimary;text-decoration:none;font-size:14px;transition:opacity .2s}
.ci:hover{opacity:.8}
.ci-icon{width:36px;height:36px;border-radius:10px;background:${accentColor}18;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.ci-icon svg{width:18px;height:18px}
.socials{display:flex;gap:12px;justify-content:center;padding:4px 0}
.sl{width:44px;height:44px;border-radius:12px;background:${accentColor}14;display:flex;align-items:center;justify-content:center;transition:background .2s}
.sl:hover{background:${accentColor}28}
.sl svg{width:20px;height:20px}
.btns{display:flex;gap:10px;margin-top:8px}
.btn{flex:1;padding:12px;border:none;border-radius:12px;font-size:14px;font-weight:600;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;transition:opacity .2s}
.btn:hover{opacity:.85}
.btn-primary{background:$accentColor;color:#fff}
.btn-secondary{background:$btnBg;color:$btnText;border:1px solid $borderColor}
.qr{display:flex;justify-content:center;padding:8px 0}
.qr canvas{border-radius:8px}
.footer{text-align:center;padding:12px;font-size:11px;color:$textSecondary;opacity:.6}
</style>
</head>
<body>
<div class="card">
<div class="accent"></div>
<div class="body">
<div class="name">$name</div>
${subtitle.isNotEmpty ? '<div class="sub">$subtitle</div>' : ''}
${hasContacts ? '<div class="div"></div>$contactItems' : ''}
${hasSocials ? '<div class="div"></div><div class="socials">$socialLinks</div>' : ''}
<div class="div"></div>
<div class="qr"><canvas id="qr"></canvas></div>
<div class="btns">
<button class="btn btn-primary" onclick="saveVCF()">${_svgDownload('#fff')} Save Contact</button>
<button class="btn btn-secondary" id="shareBtn" onclick="shareCard()">${_svgShare(btnText)} Share</button>
</div>
</div>
<div class="footer">Powered by NFCC</div>
</div>
<script>
// Minimal QR Code generator (numeric/byte mode, version auto)
var QR=(function(){
function r(t){var e=[];for(var i=0;i<t.length;i++){var c=t.charCodeAt(i);if(c<128)e.push(c);else if(c<2048){e.push(192|(c>>6));e.push(128|(c&63));}else{e.push(224|(c>>12));e.push(128|((c>>6)&63));e.push(128|(c&63));}}return e;}
function g(d,v){var s=v*4+17,m=[];for(var i=0;i<s;i++){m[i]=[];for(var j=0;j<s;j++)m[i][j]=null;}
function sp(x,y,v){if(x>=0&&x<s&&y>=0&&y<s)m[y][x]=v;}
function fp(ox,oy){for(var dy=-1;dy<=7;dy++)for(var dx=-1;dx<=7;dx++){var x=ox+dx,y=oy+dy;if(x<-1||x>s||y<-1||y>s)continue;sp(ox+dx,oy+dy,(dx>=0&&dx<=6&&(dy===0||dy===6))||(dy>=0&&dy<=6&&(dx===0||dx===6))||(dx>=2&&dx<=4&&dy>=2&&dy<=4)?1:0);}}
fp(0,0);fp(s-7,0);fp(0,s-7);
for(var i=8;i<s-8;i++){sp(i,6,i%2===0?1:0);sp(6,i,i%2===0?1:0);}
if(v>=2){var ap=[];var n=Math.floor(v/7)+2;var st=v===2?s-7-6:Math.floor((s-13)/(n-1));if(st%2!==0)st++;var first=6;ap.push(first);for(var i=1;i<n;i++)ap.push(s-7-st*(n-1-i));
for(var i=0;i<ap.length;i++)for(var j=0;j<ap.length;j++){if(i===0&&j===0)continue;if(i===0&&j===ap.length-1)continue;if(i===ap.length-1&&j===0)continue;
for(var dy=-2;dy<=2;dy++)for(var dx=-2;dx<=2;dx++)sp(ap[j]+dx,ap[i]+dy,(Math.abs(dx)===2||Math.abs(dy)===2||dx===0&&dy===0)?1:0);}}
sp(8,s-8,1);
for(var i=0;i<15;i++){var bit=0;if(i<6)sp(i,8,bit);else if(i<8)sp(i+1,8,bit);else sp(s-15+i,8,bit);
if(i<8)sp(8,s-1-i,bit);else if(i<9)sp(8,15-i,bit);else sp(8,14-i,bit);}
if(v>=7){for(var i=0;i<18;i++){sp(Math.floor(i/3),s-11+i%3,0);sp(s-11+i%3,Math.floor(i/3),0);}}
return {size:s,matrix:m};}
function encode(text){
var bytes=r(text);
for(var ver=1;ver<=40;ver++){
var cap=[0,17,32,53,78,106,134,154,192,230,271,321,367,425,458,520,586,644,718,792,858,929,1003,1091,1171,1273,1367,1465,1528,1628,1732,1840,1952,2068,2188,2303,2431,2563,2699,2809,2953];
if(bytes.length<=cap[ver]-3){
var bits=[];bits.push(0,1,0,0);
var lbits=ver<=9?8:16;
var len=bytes.length;for(var i=lbits-1;i>=0;i--)bits.push((len>>i)&1);
for(var i=0;i<bytes.length;i++)for(var j=7;j>=0;j--)bits.push((bytes[i]>>j)&1);
var totalBits=cap[ver]*8;
bits.push(0,0,0,0);
while(bits.length%8!==0)bits.push(0);
while(bits.length<totalBits){bits.push(1,1,1,0,1,1,0,0);bits.push(0,0,0,1,0,0,0,1);}
bits.length=totalBits;
var r2=g([],ver);
var sz=r2.size;var mat=r2.matrix;
var idx=0;var up=true;
for(var right=sz-1;right>=1;right-=2){
if(right===6)right=5;
for(var cnt=0;cnt<sz;cnt++){
var y=up?sz-1-cnt:cnt;
for(var c=0;c<2;c++){var x=right-c;
if(mat[y][x]===null){mat[y][x]=idx<bits.length?bits[idx]:0;idx++;}}}
up=!up;}
return {size:sz,matrix:mat,version:ver};}
}
return null;}
return{encode:encode};
})();

function drawQR(){
var vc="$vcardStr";
var res=QR.encode(vc);
if(!res)return;
var cv=document.getElementById('qr');
var cs=6;
var pad=16;
cv.width=cv.height=res.size*cs+pad*2;
var ctx=cv.getContext('2d');
ctx.fillStyle='#fff';ctx.fillRect(0,0,cv.width,cv.height);
ctx.fillStyle='#000';
for(var y=0;y<res.size;y++)for(var x=0;x<res.size;x++)
if(res.matrix[y][x])ctx.fillRect(pad+x*cs,pad+y*cs,cs,cs);
}
drawQR();

function saveVCF(){
var vc="$vcardStr".replace(/\\\\n/g,"\\n");
var blob=new Blob([vc],{type:'text/vcard'});
var a=document.createElement('a');
a.href=URL.createObjectURL(blob);
a.download='${_escapeJs(name)}.vcf';
a.click();URL.revokeObjectURL(a.href);}

function shareCard(){
if(navigator.share){
navigator.share({title:'${_escapeJs(name)}',text:'Contact card for ${_escapeJs(name)}',url:window.location.href}).catch(function(){});
}else{
if(navigator.clipboard){navigator.clipboard.writeText(window.location.href);alert('Link copied to clipboard!');}
else{alert('Share not supported on this browser.');}}}

if(!navigator.share)document.getElementById('shareBtn').style.display='none';
</script>
</body>
</html>''';
}

/// Generates a compact HTML card (<1500 bytes target) for NFC tag embedding.
/// No JavaScript, no buttons — just a styled display card.
String generateCompactCardHtml({
  required String name,
  String? title,
  String? phone,
  String? email,
  String accentColor = '#00B0FF',
}) {
  final items = StringBuffer();
  if (phone != null) {
    items.write('<a href="tel:$phone" style="display:block;color:#8B949E;'
        'text-decoration:none;font-size:13px;padding:4px 0">'
        '$phone</a>');
  }
  if (email != null) {
    items.write('<a href="mailto:$email" style="display:block;color:#8B949E;'
        'text-decoration:none;font-size:13px;padding:4px 0">'
        '$email</a>');
  }

  return '<!DOCTYPE html>'
      '<html><head><meta charset="UTF-8">'
      '<meta name="viewport" content="width=device-width,initial-scale=1">'
      '<title>$name</title></head>'
      '<body style="margin:0;background:#0D1117;font-family:-apple-system,BlinkMacSystemFont,sans-serif;'
      'display:flex;align-items:center;justify-content:center;min-height:100vh;padding:16px">'
      '<div style="max-width:380px;width:100%;background:#161B22;border-radius:14px;'
      'border:1px solid #30363D;overflow:hidden">'
      '<div style="height:4px;background:$accentColor"></div>'
      '<div style="padding:24px 20px">'
      '<div style="font-size:24px;font-weight:700;color:#E6EDF3">$name</div>'
      '${title != null ? '<div style="font-size:14px;color:#8B949E;margin-top:2px">$title</div>' : ''}'
      '${(phone != null || email != null) ? '<div style="height:1px;background:#21262D;margin:16px 0"></div>$items' : ''}'
      '</div>'
      '<div style="text-align:center;padding:8px;font-size:10px;color:#484F58">NFCC</div>'
      '</div></body></html>';
}

// --- SVG icon helpers (inline, minimal) ---

String _svgPhone(String color) =>
    '<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6A19.79 19.79 0 012.12 4.18 2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z"/>'
    '</svg>';

String _svgEmail(String color) =>
    '<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    '<rect x="2" y="4" width="20" height="16" rx="2"/>'
    '<path d="M22 7l-10 6L2 7"/>'
    '</svg>';

String _svgGlobe(String color) =>
    '<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    '<circle cx="12" cy="12" r="10"/>'
    '<path d="M2 12h20M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10A15.3 15.3 0 0112 2z"/>'
    '</svg>';

String _svgLinkedin(String color) =>
    '<svg viewBox="0 0 24 24" fill="$color">'
    '<path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 01-2.063-2.065 2.064 2.064 0 112.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>'
    '</svg>';

String _svgInstagram(String color) =>
    '<svg viewBox="0 0 24 24" fill="$color">'
    '<path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>'
    '</svg>';

String _svgGithub(String color) =>
    '<svg viewBox="0 0 24 24" fill="$color">'
    '<path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/>'
    '</svg>';

String _svgTwitter(String color) =>
    '<svg viewBox="0 0 24 24" fill="$color">'
    '<path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>'
    '</svg>';

String _svgDownload(String color) =>
    '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3"/>'
    '</svg>';

String _svgShare(String color) =>
    '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/>'
    '<path d="M8.59 13.51l6.83 3.98M15.41 6.51l-6.82 3.98"/>'
    '</svg>';

/// Escapes a string for safe use inside JS string literals.
String _escapeJs(String s) =>
    s.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('"', '\\"');
