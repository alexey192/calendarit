const functions = require('firebase-functions');
const { onCall } = require('firebase-functions/v2/https');
const { onRequest } = require('firebase-functions/v2/https');
const cors = require('cors')({ origin: true });
const { onMessagePublished } = require('firebase-functions/v2/pubsub');

const admin = require('firebase-admin');
const { google } = require('googleapis');
const fetch = require('node-fetch');

admin.initializeApp();

// 🔔 1. Subscribe to Gmail Push
exports.subscribeToGmailPush = onRequest((req, res) => {
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
          labelIds: ['INBOX'],
          topicName: 'projects/calendarit-464412/topics/gmail-watch-topic',
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
  const message = event.data?.json;
  if (!message || !message.emailAddress || !message.historyId) return;

  const userEmail = message.emailAddress;
  const historyId = message.historyId;

  const data = message.json;

  if (!userEmail || !historyId) return;

  // 🔍 Find the Gmail account
  const usersSnapshot = await admin.firestore().collectionGroup('gmailAccounts').where('email', '==', userEmail).get();
  if (usersSnapshot.empty) return;

  const accountDoc = usersSnapshot.docs[0];
  const { accessToken, refreshToken } = accountDoc.data();
  const [uid, , accountId] = accountDoc.ref.path.split('/');

  const oAuth2Client = new google.auth.OAuth2();
  oAuth2Client.setCredentials({ access_token: accessToken, refresh_token: refreshToken });

  const gmail = google.gmail({ version: 'v1', auth: oAuth2Client });

  const accountRef = admin.firestore().collection('users').doc(uid).collection('gmailAccounts').doc(accountId);
  const lastHistoryId = (await accountRef.get()).data().lastHistoryId;

  const historyRes = await gmail.users.history.list({
    userId: 'me',
    startHistoryId: lastHistoryId,
    historyTypes: ['messageAdded'],
  });

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

    const prompt = `You are a smart assistant that reads the content of emails and extracts structured event information for a personal calendar... (truncated for brevity)`;

    const fullPrompt = `${prompt}\n\n${subject}\n\n${body}`;
    const openAiRes = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${functions.config().openai.key}`,
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

    const openAiJson = await openAiRes.json();
    const text = openAiJson.choices?.[0]?.message?.content?.trim();

    if (!text || !text.includes('|')) continue; // No structured output

    const [location, title, description, date, tag] = text.split('|').map(s => s.trim());
    if (!title || !date) continue;

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
