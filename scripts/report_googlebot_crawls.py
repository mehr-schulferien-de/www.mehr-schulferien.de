#!/usr/bin/env python3
"""Read combined Nginx logs and print aggregates for forward/reverse-verified Googlebot.
Run on the log host; never writes logs or exports client addresses.
"""
import argparse,collections,concurrent.futures,datetime,gzip,glob,json,re,socket,urllib.parse
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--start', required=True, help='First included local log date, YYYY-MM-DD')
parser.add_argument('--end', required=True, help='Exclusive end date, YYYY-MM-DD')
parser.add_argument('--log-dir', default='/var/log/nginx')
args = parser.parse_args()
first_date = datetime.date.fromisoformat(args.start)
end_date = datetime.date.fromisoformat(args.end)
if first_date >= end_date:
    parser.error('--start must precede --end')
first=args.start; last=args.end
pattern=re.compile(r'^(\S+) \S+ \S+ \[([^]]+)\] "(\S+) (\S+) [^"]*" (\d{3}) (\d+|-) "[^"]*" "([^"]*)"')
by_ip=collections.defaultdict(collections.Counter); sizes=collections.defaultdict(collections.Counter)
statuses=collections.defaultdict(collections.Counter); days=collections.Counter(); malformed=0

def group(url):
 p=urllib.parse.urlsplit(url); path=p.path; q=urllib.parse.parse_qs(p.query,keep_blank_values=True)
 if 'today' in q:return 'today parameter'
 if path.startswith('/urlaubsplaner'):return 'vacation planners'
 if path.startswith('/briefe/'):return 'school letter tools'
 if path.startswith(('/ist-schultag/','/ist-feiertag/')):return 'specific date queries'
 if path.startswith(('/land/','/cities/','/schools/')):return 'legacy redirect paths'
 if path.startswith('/ferien/'):
  if re.search(r'/20\d\d$',path) and re.search(r'/(stadt|schule)/',path):return 'city/school year redirects'
  if '/bundesland/' in path:return 'state holiday pages'
  if '/stadt/' in path:return 'city holiday pages'
  if '/schule/' in path:return 'school holiday pages'
  return 'other holiday paths'
 if re.match(r'^/[a-z-]+ferien(?:/|$)',path):return 'season pages'
 if path.startswith(('/brueckentage/','/feiertage/','/ist-heute-','/ist-am-')):return 'other holiday landing pages'
 return 'unattributed paths (shared log)'
files=[]
for p in glob.glob(args.log_dir.rstrip('/') + '/access.log*'):
    stamp = re.search(r'access\.log-(\d{8})(?:\.gz)?$', p)
    if p.endswith('access.log') or (stamp and first_date <= datetime.datetime.strptime(stamp[1], '%Y%m%d').date() <= end_date + datetime.timedelta(days=1)):
        files.append(p)
if not files:
    parser.error('No access.log or dated access.log-YYYYMMDD files found')
for file in sorted(files):
 op=gzip.open if file.endswith('.gz') else open
 with op(file,'rt',errors='replace') as f:
  for line in f:
   if 'Googlebot' not in line:continue
   m=pattern.match(line)
   if not m: malformed+=1;continue
   ip,dt,method,url,status,size,ua=m.groups()
   day=datetime.datetime.strptime(dt[:11],'%d/%b/%Y').strftime('%Y-%m-%d')
   if not first<=day<last:continue
   g=group(url); by_ip[ip][g]+=1; sizes[ip][g]+=int(size) if size!='-' else 0
   statuses[ip][g+' '+status]+=1;days[day]+=1
socket.setdefaulttimeout(4)
def verify(ip):
 try:
  name=socket.gethostbyaddr(ip)[0].lower().rstrip('.')
  if not name.endswith(('.googlebot.com','.google.com')):return ip,False
  addresses={x[4][0] for x in socket.getaddrinfo(name,None)}
  return ip,ip in addresses
 except (OSError,socket.timeout):return ip,False
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool: verified=dict(pool.map(verify,by_ip))
counts=collections.Counter(); byte_counts=collections.Counter(); codes=collections.Counter()
for ip,ok in verified.items():
 if ok:counts.update(by_ip[ip]);byte_counts.update(sizes[ip]);codes.update(statuses[ip])
print(json.dumps({'period':f'{first} through {end_date - datetime.timedelta(days=1)} (local dates in log)','files':len(files),'candidate_ip_count':len(by_ip),'verified_ip_count':sum(verified.values()),'unverified_requests':sum(sum(by_ip[ip].values()) for ip,ok in verified.items() if not ok),'malformed_googlebot_lines':malformed,'verified_groups':[{'group':g,'requests':n,'body_bytes':byte_counts[g]} for g,n in counts.most_common()],'verified_statuses':dict(codes),'candidate_requests_by_day':dict(sorted(days.items())),'limitations':['Shared combined log has no hostname; only recognizable site-specific paths are attributable. Root, assets and unknown paths cannot be assigned reliably.','Log has response-body byte counts but no request or upstream timing.','DNS verification is performed at analysis time; lookup failures remain unverified.']},ensure_ascii=False,indent=2))
