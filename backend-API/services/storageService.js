const b2 = require('./b2Service');
const s3 = require('./s3Service');

const provider = process.env.STORAGE_PROVIDER
  || (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_BUCKET_NAME ? 's3' : 'b2');

const storage = provider === 's3' ? s3 : b2;

module.exports = {
  provider,
  ...storage,
};