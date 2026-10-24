// Data layer: Supabase when configured, else localStorage demo mode.
// list() returns [{id,name,address,lat,lng,notes,created,codes:[{id,code,created,up,down,last_up}]}] (times in unix seconds).
(function(){
const U=window.SUPABASE_URL||'',K=window.SUPABASE_ANON_KEY||'';
const configured=/^https:\/\//.test(U)&&K&&!/YOUR_/.test(U+K)&&window.supabase;
const ts=t=>t?Date.parse(t)/1000:null, now=()=>Date.now()/1000;
function validate(b){const name=String(b.name||'').trim().slice(0,120),code=String(b.code||'').trim().slice(0,40);
  if(!name||!code)throw new Error('name and code required');const lat=+b.lat,lng=+b.lng;if(!isFinite(lat)||!isFinite(lng))throw new Error('location required');
  return{name,code,lat,lng,address:String(b.address||'').slice(0,200),notes:String(b.notes||'').slice(0,300)}}
let S;
if(configured){
  const sb=window.supabase.createClient(U,K);const chk=r=>{if(r.error)throw new Error(r.error.message);return r.data};
  S={demo:false,
    async list(){const[p,c]=await Promise.all([sb.from('places').select('*').order('id'),sb.from('code_stats').select('*').order('created_at',{ascending:false}).order('code_id',{ascending:false})]);
      const places=chk(p),codes=chk(c);return places.map(x=>({...x,created:ts(x.created_at),codes:codes.filter(k=>k.place_id==x.id).map(k=>({id:k.code_id,code:k.code,created:ts(k.created_at),up:+k.up,down:+k.down,last_up:ts(k.last_up)}))})).filter(x=>x.codes.length)},
    async addPlace(b){const v=validate(b);const p=chk(await sb.from('places').insert({name:v.name,address:v.address,lat:v.lat,lng:v.lng,notes:v.notes}).select('id').single());
      chk(await sb.from('codes').insert({place_id:p.id,code:v.code}));return{id:p.id}},
    async addCode(pid,code){chk(await sb.from('codes').insert({place_id:pid,code}))},
    async vote(cid,up){chk(await sb.from('votes').insert({code_id:cid,up}))}};
}else{
  const KEY='codeloo-demo-v2',ls=window.localStorage;
  const seed=()=>{const t=now()-86400;return{n:100,places:[
    [1, "Aldi", "1352 W Valley Pkwy, Escondido, CA 92029", 33.1127791, -117.1039186, "", "1352#"],
    [2, "Jimbo's Naturally", "1633 S Centre City Pkwy, Escondido, CA 92025", 33.1042504, -117.0775835, "", "7755"],
    [3, "Raising Cane's", "1280 W Valley Pkwy, Escondido, CA 92029", 33.1148151, -117.1009867, "Code from user note 'SM'", "54321"],
    [4, "Wendy's", "1530 W Valley Pkwy, Escondido, CA 92029", 33.1096071, -117.1046716, "", "5505"],
    [5, "Primos Mexican Food & Cantina", "1348 W Valley Pkwy, Escondido, CA 92029", 33.112299, -117.102936, "", "2805"],
    [6, "Ding Tea", "1815 E Valley Pkwy Ste 2, Escondido, CA 92027", 33.135699, -117.054732, "", "0198"],
    [7, "Epic Wings", "1054 W Valley Pkwy, Escondido, CA 92025", 33.1166662, -117.0968408, "", "1432#"]
  ].map(([id,name,address,lat,lng,notes,code])=>({id,name,address,lat,lng,notes,created:t,codes:[{id:id+50,code,created:t,up:0,down:0,last_up:null}]}))}};
  const get=()=>{try{return JSON.parse(ls.getItem(KEY))||seed()}catch(e){return seed()}},put=d=>ls.setItem(KEY,JSON.stringify(d));
  S={demo:true,
    async list(){const d=get();put(d);return d.places.map(p=>({...p,codes:[...p.codes].sort((a,b)=>b.created-a.created||b.id-a.id)}))},
    async addPlace(b){const v=validate(b),d=get(),id=++d.n;d.places.push({id,name:v.name,address:v.address,lat:v.lat,lng:v.lng,notes:v.notes,created:now(),codes:[{id:++d.n,code:v.code,created:now(),up:0,down:0,last_up:null}]});put(d);return{id}},
    async addCode(pid,code){const d=get(),p=d.places.find(x=>x.id==pid);if(!p)throw new Error('not found');p.codes.push({id:++d.n,code,created:now(),up:0,down:0,last_up:null});put(d)},
    async vote(cid,up){const d=get();for(const p of d.places)for(const c of p.codes)if(c.id==cid){if(up){c.up++;c.last_up=now()}else c.down++}put(d)}};
}
window.Store=S;
})();
