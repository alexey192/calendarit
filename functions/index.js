const { onCall } = require('firebase-functions/v2/https');
const { onRequest } = require('firebase-functions/v2/https');
const cors = require('cors')({ origin: true });
const { onMessagePublished } = require('firebase-functions/v2/pubsub');
const { google } = require('googleapis');
const fetch = require('node-fetch');
const functions = require('firebase-functions'); // v3
const admin = require('firebase-admin');
admin.initializeApp();

// 🔔 1. Subscribe to Gmail Push
exports.subscribeToGmailPushApi = onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed. Use POST.' });
      }

      const { uid, accountId } = req.body;

      if (!uid || !accountId) {
        return res.status(400).json({ error: 'Missing uid or accountId' });
      }

      const docRef = admin
        .firestore()
        .collection('users')
        .doc(uid)
        .collection('gmailAccounts')
        .doc(accountId);

      const accountDoc = await docRef.get();
      if (!accountDoc.exists) {
        return res.status(404).json({ error: 'Gmail account not found' });
      }

      const { accessToken } = accountDoc.data();
      const auth = new google.auth.OAuth2();
      auth.setCredentials({ access_token: accessToken });

      const gmail = google.gmail({ version: 'v1', auth });

      const watchResponse = await gmail.users.watch({
        userId: 'me',
        requestBody: {
          //labelIds: ['INBOX'],
          topicName: 'projects/calendar-it-31e1c/topics/gmail-watch-topic',
        },
      });

      const { historyId } = watchResponse.data;
      if (historyId) {
        await docRef.update({ lastHistoryId: historyId });
      }

      return res.status(200).json({ success: true, historyId });
    } catch (err) {
      console.error('subscribeToGmailPush error:', err);
      return res.status(500).json({ error: 'Internal server error', details: err.message });
    }
  });
});


// 📥 2. Handle Gmail Push Notifications
exports.handleGmailPush = onMessagePublished('gmail-watch-topic', async (event) => {
  console.log('📬 Gmail Push Triggered');

  const rawData = event.data?.message?.data;
  if (!rawData) {
    console.warn("⚠️ Missing data in PubSub event");
    return;
  }

  const jsonString = Buffer.from(rawData, 'base64').toString('utf8');
  const message = JSON.parse(jsonString);
  console.log("📨 Payload:", JSON.stringify(message, null, 2));

  const userEmail = message.emailAddress;
  const historyId = message.historyId;

  if (!userEmail || !historyId) {
    console.warn("⚠️ Missing userEmail or historyId");
    return;
  }

  console.log(`🔍 Looking for Gmail account with email: ${userEmail}`);

  // 🔍 Find the Gmail account
  const snapshot = await admin.firestore()
    .collectionGroup('gmailAccounts')
    .where('email', '==', userEmail)
    .get();

  if (snapshot.empty) {
    console.warn(`❌ No Gmail account found for email: ${userEmail}`);
    return;
  }

  const accountDoc = snapshot.docs[0];

  const { accessToken, refreshToken } = accountDoc.data();

  const segments = accountDoc.ref.path.split('/');
  const uid = segments[1];
  const accountId = segments[3];

  console.log(`✅ Found account. UID: ${uid}, Account ID: ${accountId}`);

  const oAuth2Client = new google.auth.OAuth2();

  oAuth2Client.setCredentials({ access_token: accessToken, refresh_token: refreshToken });
  //oAuth2Client.setCredentials({ access_token: accessToken }); // no refresh_token

  const gmail = google.gmail({ version: 'v1', auth: oAuth2Client });

  const accountRef = admin.firestore().collection('users').doc(uid).collection('gmailAccounts').doc(accountId);
  const lastHistoryId = (await accountRef.get()).data().lastHistoryId;

  console.log(`🔍 Last historyId: ${lastHistoryId}`);

  const historyRes = await gmail.users.history.list({
    userId: 'me',
    startHistoryId: lastHistoryId,
    historyTypes: ['messageAdded'],
  });

  console.log(`📜 History response: ${JSON.stringify(historyRes.data, null, 2)}`);

  const messages = historyRes.data.history?.flatMap(h => h.messages || []) || [];

  for (const msg of messages) {
    const fullMsg = await gmail.users.messages.get({
      userId: 'me',
      id: msg.id,
      format: 'full',
    });

    const payload = fullMsg.data.payload || {};
    const subjectHeader = payload.headers?.find(h => h.name === 'Subject');
    const subject = subjectHeader?.value || '';
    const body = extractBody(payload);

    const prompt = `You are a smart assistant that reads the content of emails and extracts structured event information for a personal calendar. The expected format is:
Location | Title | Description | Date | Tag`;

    const fullPrompt = `${prompt}\n\n${subject}\n\n${body}`;

    console.log(`🔍 Processing message ID: ${msg.id}`);

    console.log(`🔑 Using access token: ${process.env.OPENAI_API_KEY.substring(0, 10)}...`);
    //const openAiKey = process.env.OPENAI_API_KEY;
    const openAiKey = '[REDACTED_OPENAI_KEY]';

    const openAiRes = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${openAiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: 'You extract calendar events from emails.' },
          { role: 'user', content: fullPrompt },
        ],
        temperature: 0.2,
      }),
    });

    const responseText = await openAiRes.text();

    if (!openAiRes.ok) {
      console.error(`❌ OpenAI API error (${openAiRes.status}):`, responseText);
      throw new Error('OpenAI API error');
    }

    const openAiJson = JSON.parse(responseText);

    const text = openAiJson.choices?.[0]?.message?.content?.trim();

    console.log(`🔍 OpenAI response for message ID ${msg.id}: ${text}`);

    if (!text || !text.includes('|')) continue; // No structured output

    const [location, title, description, date, tag] = text.split('|').map(s => s.trim());
    if (!title || !date) continue;

    console.log(`📅 Extracted event: ${title} on ${date}`);

    await admin.firestore().collection('users').doc(uid).collection('events').add({
      location,
      title,
      description,
      date,
      tag,
      seen: false,
      status: 'pending',
      source: 'gmail',
      emailId: msg.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // ✅ Update historyId for future sync
  await accountRef.update({ lastHistoryId: historyId });
});


// 📦 Extract text body from Gmail payload
function extractBody(payload) {
  const getPart = (p) => {
    if (p.mimeType === 'text/plain' && p.body?.data) return p.body.data;
    if (p.mimeType === 'text/html' && p.body?.data) return p.body.data;
    if (p.parts) {
      for (const sub of p.parts) {
        const found = getPart(sub);
        if (found) return found;
      }
    }
    return null;
  };

  const data = getPart(payload);
  if (!data) return '';
  return Buffer.from(data, 'base64').toString('utf-8');
}

