import paramiko

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect('185.98.128.123', username='root', password='vfZeEJTY5Fz', timeout=15)

sftp = c.open_sftp()

# 1. Ajouter PUBLIC_API_URL dans .env si absent
with sftp.open('/opt/mykog-api/.env', 'r') as f:
    env = f.read().decode('utf-8')
if 'PUBLIC_API_URL' not in env:
    env = env.rstrip() + '\nPUBLIC_API_URL=http://185.98.128.123:3001/mykog-api\n'
    with sftp.open('/opt/mykog-api/.env', 'w') as f:
        f.write(env)
    print('.env: PUBLIC_API_URL ajouté')
else:
    print('.env: déjà présent')

SNIPPET = "const PUBLIC_API_URL = process.env.PUBLIC_API_URL || 'http://185.98.128.123:3001/mykog-api';\nconst stableFileUrl = (key) => `${PUBLIC_API_URL}/api/files/${encodeURIComponent(key)}`;\n"

patches = [
    (
        '/opt/mykog-api/controllers/textResumeController.js',
        [
            ("const { sendNotificationToAllUsers } = require('../utils/notificationHelper');\n",
             "const { sendNotificationToAllUsers } = require('../utils/notificationHelper');\n\n" + SNIPPET),
            ("async function resolvePdfUrl(docData) {\n  if (docData.pdfKey) {\n    try { return await storage.getDownloadUrl(docData.pdfKey); } catch {}\n  }\n  return docData.pdfUrl || '';\n}",
             "async function resolvePdfUrl(docData) {\n  if (docData.pdfKey) return stableFileUrl(docData.pdfKey);\n  return docData.pdfUrl || '';\n}"),
            ("async function resolveCoverUrl(docData) {\n  if (docData.coverImageKey) {\n    try { return await storage.getDownloadUrl(docData.coverImageKey); } catch {}\n  }\n  return docData.coverImageUrl || '';\n}",
             "async function resolveCoverUrl(docData) {\n  if (docData.coverImageKey) return stableFileUrl(docData.coverImageKey);\n  return docData.coverImageUrl || '';\n}"),
        ]
    ),
    (
        '/opt/mykog-api/controllers/enseignementController.js',
        [
            ("const isKeyProvider = (p) => p === 'b2' || p === 's3';\n",
             "const isKeyProvider = (p) => p === 'b2' || p === 's3';\n\n" + SNIPPET),
            ("async function resolveImageUrl(docData) {\n  if (docData.imageKey) {\n    const url = await storage.getDownloadUrl(docData.imageKey);\n    if (url) return url;\n  }\n  return docData.artworkUrl || '';\n}",
             "async function resolveImageUrl(docData) {\n  if (docData.imageKey) return stableFileUrl(docData.imageKey);\n  return docData.artworkUrl || '';\n}"),
            ("async function resolveAudioUrl(docData) {\n  if (docData.audioKey) {\n    const url = await storage.getDownloadUrl(docData.audioKey);\n    if (url) return url;\n  }\n  return docData.audioUrl || '';\n}",
             "async function resolveAudioUrl(docData) {\n  if (docData.audioKey) return stableFileUrl(docData.audioKey);\n  return docData.audioUrl || '';\n}"),
        ]
    ),
]

for path, subs in patches:
    with sftp.open(path, 'r') as f:
        content = f.read().decode('utf-8')
    ok = True
    for old, new in subs:
        if old in content:
            content = content.replace(old, new, 1)
        else:
            print(f'PATTERN NON TROUVE dans {path}:\n{old[:80]}...')
            ok = False
    if ok:
        with sftp.open(path, 'w') as f:
            f.write(content)
        print(f'PATCH OK: {path}')

sftp.close()

i, o, e = c.exec_command('pm2 restart mykog-api --update-env && sleep 4 && curl -s -m 15 http://localhost:3002/api/text-resumes | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0][\'coverImageUrl\'] if d else \'vide\')"')
print(o.read().decode('utf-8', 'replace'))
print(e.read().decode('utf-8', 'replace')[:500])

c.close()
