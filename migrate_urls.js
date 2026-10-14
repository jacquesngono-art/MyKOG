// Migration : URLs http://185.98.128.123:3001 -> https://vps123057.serveur-vps.net
require('dotenv').config({ path: '/opt/mykog-api/.env' });
const { db } = require('/opt/mykog-api/config/firebase');

const OLD = 'http://185.98.128.123:3001/mykog-api';
const NEW = 'https://vps123057.serveur-vps.net/mykog-api';

const COLLECTIONS = ['users', 'enseignements', 'textes_resumes', 'liveStreams', 'calendarEvents', 'annonces'];

(async () => {
  let total = 0;
  for (const c of COLLECTIONS) {
    const snap = await db.collection(c).get();
    for (const doc of snap.docs) {
      const d = doc.data();
      const upd = {};
      for (const k of Object.keys(d)) {
        if (typeof d[k] === 'string' && d[k].startsWith(OLD)) {
          upd[k] = d[k].replace(OLD, NEW);
        }
      }
      if (Object.keys(upd).length) {
        await doc.ref.update(upd);
        total++;
        console.log(c + '/' + doc.id, '->', Object.keys(upd).join(','));
      }
    }
  }
  console.log('MIGRATED:', total, 'docs');
  process.exit(0);
})().catch(e => { console.error('ERR:', e.message); process.exit(1); });
