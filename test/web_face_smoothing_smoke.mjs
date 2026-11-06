import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {spawn} from 'node:child_process';
const root=path.resolve('web');
let browser;
const html=`<div style="width:640px;height:480px"><video autoplay muted playsinline></video></div><script type="module">
import '/face_filter/face_filter.mjs';
try {
 const source=document.createElement('canvas'); source.width=640; source.height=480;
 const ctx=source.getContext('2d');ctx.fillStyle='rgb(30,70,120)';ctx.fillRect(0,0,640,480);
 const video=document.querySelector('video');video.srcObject=source.captureStream(10);await video.play();
 const ready=await window.digiFaceFilter.start(.35);if(!ready)throw Error('Filter did not start');
 const bytes=await window.digiFaceFilter.capture();const bitmap=await createImageBitmap(new Blob([bytes],{type:'image/png'}));
 if(bitmap.width!==640||bitmap.height!==480)throw Error('Resolution changed');
 ctx.drawImage(bitmap,0,0);const pixel=ctx.getImageData(320,240,1,1).data;
 if(Math.abs(pixel[0]-30)>3||Math.abs(pixel[1]-70)>3||Math.abs(pixel[2]-120)>3)throw Error('No-face frame changed');
 window.digiFaceFilter.stop();if(video.parentElement.querySelector('canvas'))throw Error('Overlay not removed');
 video.srcObject.getTracks().forEach(t=>t.stop());
 await fetch('/result',{method:'POST',body:'PASS: model load, live preview, PNG capture, no-face preservation, cleanup'});
} catch(e){await fetch('/result',{method:'POST',body:'FAIL: '+e.stack});}
</script>`;
const server=http.createServer((req,res)=>{
 if(req.url==='/result'){let body='';req.on('data',c=>body+=c);req.on('end',()=>{console.log(body);res.end('ok');finish(body.startsWith('PASS')?0:1);});return;}
 if(req.url==='/'){res.setHeader('Content-Type','text/html');res.end(html);return;}
 const file=path.resolve(root,'.'+decodeURIComponent(req.url.split('?')[0]));
 if(!file.startsWith(root+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.setHeader('Content-Type',file.endsWith('.mjs')||file.endsWith('.js')?'text/javascript':file.endsWith('.wasm')?'application/wasm':'application/octet-stream');fs.createReadStream(file).pipe(res);
});
const timeout=setTimeout(()=>{console.error('Browser smoke test timed out');finish(1)},60000);
function finish(code){clearTimeout(timeout);browser?.kill();server.close();process.exitCode=code;setTimeout(()=>process.exit(code),500);}
server.listen(0,'127.0.0.1',()=>{
 const exe=process.env.EDGE_PATH||'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';
 const profile=path.resolve('.dart_tool/face-filter-browser-test');
 browser=spawn(exe,['--headless=new','--disable-gpu','--no-first-run','--autoplay-policy=no-user-gesture-required','--user-data-dir='+profile,'http://127.0.0.1:'+server.address().port],{windowsHide:true,stdio:'ignore'});
 browser.on('error',e=>{console.error(e);finish(1)});
});
