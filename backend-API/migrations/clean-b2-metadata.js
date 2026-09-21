require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { db } = require('../config/firebase');

const FIELD_MAP = {
  enseignements: ['imageKey', 'audioKey', 'artworkUrl', 'audioUrl'],
  textes_resumes: ['pdfKey', 'coverImageKey', 'pdfUrl', 'coverImageUrl'],
};

const DRY = process.argv.includes('--dry');

async function exportBackup() {
  const backup = {};
  for (const col of Object.keys(FIELD_MAP)) {
    const snap = await db.collection(col).get();
    backup[col] = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  }
  const file = path.join(__dirname, `backup-${new Date().toISOString().slice(0, 10)}.json`);
  fs.writeFileSync(file, JSON.stringify(backup, null, 2));
  console.log('📦 Backup écrit:', file);
  return backup;
}

async function main() {
  const backup = await exportBackup();

  for (const [col, fields] of Object.entries(FIELD_MAP)) {
    const docs = backup[col];
    let toClean = 0;
    const deletions = [];

    for (const doc of docs) {
      const present = fields.filter(f => doc[f] !== undefined);
      if (present.length) {
        toClean++;
        deletions.push({ id: doc.id, fields: present });
      }
    }

    console.log(`\n=== ${col}: ${toClean}/${docs.length} docs avec métadonnées B2 ===`);
    deletions.forEach(d => console.log('  -', d.id, '->', d.fields.join(', ')));

    if (DRY || toClean === 0) continue;

    for (const d of deletions) {
      const update = {};
      d.fields.forEach(f => { update[f] = require('firebase-admin').firestore.FieldValue.delete(); });
      await db.collection(col).doc(d.id).update(update);
      console.log(`  ✅ ${d.id}: ${d.fields.length} champ(s) supprimé(s)`);
    }
  }

  if (DRY) {
    console.log('\n⚠️ Mode DRY-RUN : aucune modification effectuée');
  }
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });