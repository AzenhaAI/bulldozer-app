import sharp from '/Users/kirillshpara/Projects/alfacat/node_modules/sharp/lib/index.js';
import { writeFileSync } from 'node:fs';
const SH='/Users/kirillshpara/Projects/bulldozer_app/store/screenshots/ios-6.9-66/';
const ICON='/Users/kirillshpara/Projects/bulldozer_app/store/icon-512.png';
const [,, outDir, name, Ws, Hs] = process.argv;
const W=+Ws, H=+Hs;
const tall = H/W > 0.6;
const PH = Math.round(H*(tall?0.76:0.86)), PW = Math.round(PH*1320/2868);
const R = Math.round(PW*0.13), B = Math.round(PW*0.028);
const cx = Math.round(W*(tall?0.69:0.70));
const px = cx - Math.round(PW/2), py = Math.round((H-PH)/2);

async function sidePhone(file, deg, scale){
  const w=Math.round(PW*scale), h=Math.round(PH*scale), r=Math.round(R*scale), b=Math.round(B*scale);
  const img=await sharp(SH+file).resize(w,h,{fit:'fill'}).png().toBuffer();
  const mask=Buffer.from(`<svg width="${w}" height="${h}"><rect width="${w}" height="${h}" rx="${r}" fill="#fff"/></svg>`);
  const scr=await sharp(img).composite([{input:mask,blend:'dest-in'}]).png().toBuffer();
  const frame=Buffer.from(`<svg width="${w+2*b}" height="${h+2*b}"><rect x="1" y="1" width="${w+2*b-2}" height="${h+2*b-2}" rx="${r+b}" fill="#1b1f23" stroke="#3a4148" stroke-width="3"/></svg>`);
  const ph=await sharp(frame).composite([{input:scr,left:b,top:b}]).png().toBuffer();
  // darken a little so the live phone in front reads first
  const dim=Buffer.from(`<svg width="${w+2*b}" height="${h+2*b}"><rect width="100%" height="100%" rx="${r+b}" fill="#000" fill-opacity="0.28"/></svg>`);
  const d=await sharp(ph).composite([{input:dim}]).png().toBuffer();
  return sharp(d).rotate(deg,{background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer({resolveWithObject:true});
}
const fs = tall ? {ico:300, title:230, sub:78, gap:150} : {ico:250, title:190, sub:70, gap:110};
const tx = Math.round(W*0.075);
const blockH = fs.ico + 60 + fs.title + 40 + fs.sub*2.6;
const ty0 = Math.round((H-blockH)/2);
const titleY = ty0 + fs.ico + 60 + fs.title*0.8;
const sub1Y = titleY + fs.sub*1.7, sub2Y = sub1Y + fs.sub*1.3;
const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
<defs><radialGradient id="g" cx="70%" cy="35%" r="80%"><stop offset="0" stop-color="#3d2c05"/><stop offset="1" stop-color="#0b0d0f"/></radialGradient></defs>
<rect width="${W}" height="${H}" fill="url(#g)"/>
<text x="${tx}" y="${titleY}" font-family="Inter, Helvetica Neue, Arial" font-weight="800" font-size="${fs.title}" fill="#eef1f3">Bull<tspan fill="#ffb000">Dozer</tspan></text>
<text x="${tx+6}" y="${sub1Y}" font-family="Inter, Helvetica Neue, Arial" font-size="${fs.sub}" fill="#9aa4ad">Open data on 232 countries,</text>
<text x="${tx+6}" y="${sub2Y}" font-family="Inter, Helvetica Neue, Arial" font-size="${fs.sub}" fill="#9aa4ad">with Ask AI that checks its figures.</text>
</svg>`);
const icoMask=Buffer.from(`<svg width="${fs.ico}" height="${fs.ico}"><rect width="${fs.ico}" height="${fs.ico}" rx="${Math.round(fs.ico*0.225)}" fill="#fff"/></svg>`);
const ico=await sharp(ICON).resize(fs.ico,fs.ico).composite([{input:icoMask,blend:'dest-in'}]).png().toBuffer();
const L=await sidePhone('3-stats.png',-7,0.88), Rr=await sidePhone('6-geo.png',7,0.88);
const off=Math.round(PW*(tall?0.76:0.80));
const lx=cx-off-Math.round(L.info.width/2), ly=Math.round(H/2-L.info.height/2+PH*0.03);
const rx=cx+off-Math.round(Rr.info.width/2), ry=Math.round(H/2-Rr.info.height/2+PH*0.03);
const bezel=Buffer.from(`<svg width="${PW+2*B}" height="${PH+2*B}"><rect x="1" y="1" width="${PW+2*B-2}" height="${PH+2*B-2}" rx="${R+B}" fill="#1b1f23" stroke="#4a525a" stroke-width="3"/></svg>`);
const shadow=Buffer.from(`<svg width="${W}" height="${H}"><defs><filter id="f"><feGaussianBlur stdDeviation="${Math.round(PW*0.05)}"/></filter></defs><rect x="${px-B}" y="${py-B+Math.round(PH*0.02)}" width="${PW+2*B}" height="${PH+2*B}" rx="${R+B}" fill="#000" fill-opacity="0.55" filter="url(#f)"/></svg>`);
await sharp(bg).composite([
  {input:ico,left:tx,top:ty0},
  {input:L.data,left:lx,top:ly},{input:Rr.data,left:rx,top:ry},
  {input:shadow,left:0,top:0},
  {input:bezel,left:px-B,top:py-B},
]).flatten({background:'#0b0d0f'}).removeAlpha().png().toFile(`${outDir}/${name}-bg.png`);
await sharp({create:{width:PW,height:PH,channels:3,background:'#000'}}).composite([{input:Buffer.from(`<svg width="${PW}" height="${PH}"><rect width="${PW}" height="${PH}" rx="${R}" fill="#fff"/></svg>`)}]).png().toFile(`${outDir}/${name}-mask.png`);
writeFileSync(`${outDir}/${name}.json`, JSON.stringify({W,H,PW,PH,px,py}));
console.log(name,{W,H,PW,PH,px,py});
