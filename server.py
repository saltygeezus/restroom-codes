import json, sqlite3, time, os
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
DB=os.path.join(os.path.dirname(os.path.abspath(__file__)),'data.db')
def db():
    c=sqlite3.connect(DB); c.row_factory=sqlite3.Row; return c
def init():
    c=db(); c.executescript('''create table if not exists restrooms(id integer primary key,name text,address text,lat real,lng real,notes text,created real);
    create table if not exists codes(id integer primary key,restroom_id int,code text,created real,up int default 0,down int default 0,last_up real);''')
    if not c.execute('select count(*) from restrooms').fetchone()[0]:
        now=time.time()
        for n,a,la,ln,code,notes in [("EXAMPLE – Coffee Shop (demo)","Market St, San Francisco",37.7897,-122.4011,"1234 (EXAMPLE)","Demo entry, not a real code. Customers only."),
            ("EXAMPLE – Grocery Store (demo)","Mission St, San Francisco",37.7599,-122.4148,"#5678 (EXAMPLE)","Demo entry. Ask cashier."),
            ("EXAMPLE – Bookstore (demo)","Valencia St, San Francisco",37.7648,-122.4216,"0000* (EXAMPLE)","Demo entry, not real.")]:
            r=c.execute('insert into restrooms(name,address,lat,lng,notes,created) values(?,?,?,?,?,?)',(n,a,la,ln,notes,now-86400*3)).lastrowid
            c.execute('insert into codes(restroom_id,code,created,up,down,last_up) values(?,?,?,?,?,?)',(r,code,now-86400*3,3,1,now-86400))
    c.commit()
def listing():
    c=db(); out=[]
    for r in c.execute('select * from restrooms order by id'):
        d=dict(r); d['codes']=[dict(x) for x in c.execute('select * from codes where restroom_id=? order by created desc',(r['id'],))]; out.append(d)
    return out
class H(SimpleHTTPRequestHandler):
    def __init__(s,*a,**k): super().__init__(*a,directory=os.path.join(os.path.dirname(os.path.abspath(__file__)),'static'),**k)
    def js(s,o,st=200):
        b=json.dumps(o).encode(); s.send_response(st); s.send_header('Content-Type','application/json'); s.send_header('Content-Length',len(b)); s.end_headers(); s.wfile.write(b)
    def body(s): return json.loads(s.rfile.read(int(s.headers.get('Content-Length',0)) or 0) or b'{}')
    def do_GET(s):
        if s.path.startswith('/api/restrooms'): return s.js(listing())
        super().do_GET()
    def do_POST(s):
        try: b=s.body()
        except Exception: return s.js({'error':'bad json'},400)
        c=db(); now=time.time(); p=s.path
        if p=='/api/restrooms':
            name=str(b.get('name','')).strip()[:120]; code=str(b.get('code','')).strip()[:40]
            try: lat=float(b['lat']); lng=float(b['lng'])
            except Exception: return s.js({'error':'location required'},400)
            if not name or not code: return s.js({'error':'name and code required'},400)
            r=c.execute('insert into restrooms(name,address,lat,lng,notes,created) values(?,?,?,?,?,?)',(name,str(b.get('address',''))[:200],lat,lng,str(b.get('notes',''))[:300],now)).lastrowid
            c.execute('insert into codes(restroom_id,code,created) values(?,?,?)',(r,code,now)); c.commit(); return s.js({'id':r})
        parts=p.strip('/').split('/')
        if len(parts)==4 and parts[1]=='restrooms' and parts[3]=='codes':
            code=str(b.get('code','')).strip()[:40]
            if not code: return s.js({'error':'code required'},400)
            c.execute('insert into codes(restroom_id,code,created) values(?,?,?)',(int(parts[2]),code,now)); c.commit(); return s.js({'ok':1})
        if len(parts)==4 and parts[1]=='codes' and parts[3] in('up','down'):
            if parts[3]=='up': c.execute('update codes set up=up+1,last_up=? where id=?',(now,int(parts[2])))
            else: c.execute('update codes set down=down+1 where id=?',(int(parts[2]),))
            c.commit(); return s.js({'ok':1})
        s.js({'error':'not found'},404)
init()
ThreadingHTTPServer(('0.0.0.0',int(os.environ.get('PORT',8765))),H).serve_forever()
