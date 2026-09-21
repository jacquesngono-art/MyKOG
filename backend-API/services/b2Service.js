const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand, HeadObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

const ACCESS_KEY_ID = process.env.B2_KEY_ID;
const SECRET_ACCESS_KEY = process.env.B2_APP_KEY;
const BUCKET_NAME = process.env.B2_BUCKET;
const ENDPOINT = process.env.B2_ENDPOINT;

let s3Client;

function getClient() {
  if (!s3Client) {
    if (!ACCESS_KEY_ID || !SECRET_ACCESS_KEY || !BUCKET_NAME) {
      throw new Error('B2 non configuré : vars B2_KEY_ID, B2_APP_KEY et B2_BUCKET requises');
    }
    s3Client = new S3Client({
      region: 'us-east-005',
      endpoint: ENDPOINT || 'https://s3.us-east-005.backblazeb2.com',
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

function generateTimestampId() {
  return `${Date.now()}-${Math.round(Math.random() * 1E9)}`;
}

async function uploadFile(key, body, contentType) {
  const client = getClient();
  const command = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
    Body: body,
    ContentType: contentType,
  });
  await client.send(command);
  return { key, provider: 'b2' };
}

async function uploadBuffer(file, prefix) {
  const ext = file.originalname.split('.').pop() || 'bin';
  const key = `${prefix}/${generateTimestampId()}.${ext}`;
  return uploadFile(key, file.buffer, file.mimetype);
}

async function getDownloadUrl(key, expiresIn = 3600) {
  try {
    const client = getClient();
    const headCommand = new HeadObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    });
    await client.send(headCommand);

    const command = new GetObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    });
    return await getSignedUrl(client, command, { expiresIn });
  } catch (err) {
    const statusCode = err?.$metadata?.httpStatusCode || err?.statusCode;
    if (statusCode === 404) {
      console.warn(`⚠️ B2 objet introuvable: ${key}`);
      return null;
    }
    console.error('⚠️ B2 getDownloadUrl error:', err.message);
    return null;
  }
}

async function deleteFile(key) {
  try {
    const client = getClient();
    const command = new DeleteObjectCommand({ Bucket: BUCKET_NAME, Key: key });
    await client.send(command);
    return 'b2';
  } catch (err) {
    console.error('⚠️ B2 delete error:', err.message);
    return null;
  }
}

async function deleteR2File(key) {
  return deleteFile(key);
}

module.exports = { getClient, uploadFile, uploadBuffer, getDownloadUrl, deleteFile, deleteR2File };
