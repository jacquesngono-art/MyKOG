const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const cloudinary = require('../config/cloudinary');

const ACCOUNT_ID = process.env.CF_ACCOUNT_ID;
const ACCESS_KEY_ID = process.env.R2_ACCESS_KEY_ID;
const SECRET_ACCESS_KEY = process.env.R2_SECRET_ACCESS_KEY;
const BUCKET_NAME = process.env.R2_BUCKET_NAME;
const ENDPOINT = process.env.R2_ENDPOINT;

let s3Client;

function getClient() {
  if (!s3Client) {
    if (!ACCOUNT_ID || !ACCESS_KEY_ID || !SECRET_ACCESS_KEY) {
      throw new Error('R2 non configuré : vars CF_ACCOUNT_ID, R2_ACCESS_KEY_ID et R2_SECRET_ACCESS_KEY requises');
    }
    s3Client = new S3Client({
      region: 'auto',
      endpoint: ENDPOINT || `https://${ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: ACCESS_KEY_ID,
        secretAccessKey: SECRET_ACCESS_KEY,
      },
      forcePathStyle: true,
      requestHandler: new (require('@smithy/node-http-handler').NodeHttpHandler)({
        connectionTimeout: 15000,
        socketTimeout: 120000,
      }),
    });
  }
  return s3Client;
}

async function r2Upload(key, body, contentType) {
  const client = getClient();
  const command = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
    Body: body,
    ContentType: contentType,
  });
  await client.send(command);
}

function generateTimestampId() {
  return `${Date.now()}-${Math.round(Math.random() * 1E9)}`;
}

async function uploadFile(key, body, contentType) {
  try {
    await r2Upload(key, body, contentType);
    return { key, provider: 'r2' };
  } catch (err) {
    if (err.name === 'Error' && (err.message?.includes('EPROTO') || err.message?.includes('handshake') || err.code === 'ENOTFOUND')) {
      console.warn('⚠️ R2 S3 endpoint inaccessible, fallback Cloudinary');
    } else {
      throw err;
    }
  }

  const result = await new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      { resource_type: 'auto', folder: key.split('/').slice(0, -1).join('/'), public_id: key.split('/').pop().replace(/\.[^.]+$/, '') },
      (error, result) => {
        if (error) reject(error);
        else resolve(result);
      }
    );
    uploadStream.end(body);
  });

  return { key: result.public_id, provider: 'cloudinary', url: result.secure_url };
}

async function uploadBuffer(file, prefix) {
  const ext = file.originalname.split('.').pop() || 'bin';
  const key = `${prefix}/${generateTimestampId()}.${ext}`;
  return uploadFile(key, file.buffer, file.mimetype);
}

async function getDownloadUrl(key, expiresIn = 604800) {
  try {
    const client = getClient();
    const command = new GetObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    });
    return await getSignedUrl(client, command, { expiresIn });
  } catch {
    return null;
  }
}

async function deleteR2File(key) {
  try {
    const client = getClient();
    const command = new DeleteObjectCommand({ Bucket: BUCKET_NAME, Key: key });
    await client.send(command);
    return 'r2';
  } catch (err) {
    if (err.name === 'Error' && (err.message?.includes('EPROTO') || err.message?.includes('handshake') || err.code === 'ENOTFOUND')) {
      console.warn('⚠️ R2 delete endpoint inaccessible, skipping R2 deletion');
    } else {
      throw err;
    }
  }
  return null;
}

module.exports = { uploadFile, uploadBuffer, getDownloadUrl, deleteR2File };
