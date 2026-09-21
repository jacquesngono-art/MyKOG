const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand, HeadObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

const ACCESS_KEY_ID = process.env.AWS_ACCESS_KEY_ID;
const SECRET_ACCESS_KEY = process.env.AWS_SECRET_ACCESS_KEY;
const REGION = process.env.AWS_REGION || 'eu-north-1';
const BUCKET_NAME = process.env.AWS_BUCKET_NAME;

let s3Client;

function getClient() {
  if (!s3Client) {
    if (!ACCESS_KEY_ID || !SECRET_ACCESS_KEY || !BUCKET_NAME) {
      throw new Error('AWS S3 non configuré : vars AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY et AWS_BUCKET_NAME requises');
    }
    s3Client = new S3Client({
      region: REGION,
      credentials: {
        accessKeyId: ACCESS_KEY_ID,
        secretAccessKey: SECRET_ACCESS_KEY,
      },
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
  return { key, provider: 's3' };
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
      console.warn(`⚠️ S3 objet introuvable: ${key}`);
      return null;
    }
    console.error('⚠️ S3 getDownloadUrl error:', err.message);
    return null;
  }
}

async function deleteFile(key) {
  try {
    const client = getClient();
    const command = new DeleteObjectCommand({ Bucket: BUCKET_NAME, Key: key });
    await client.send(command);
    return 's3';
  } catch (err) {
    console.error('⚠️ S3 delete error:', err.message);
    return null;
  }
}

module.exports = { getClient, uploadFile, uploadBuffer, getDownloadUrl, deleteFile };