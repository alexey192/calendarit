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
  oAuth2Client.setCredentials({
    access_token: accessToken,
    refresh_token: refreshToken,
  });

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

    const prompt = `
You are an intelligent email event analyzer. I will provide you with the full body of an email. Your task is to:

1. Determine whether the email contains any information about an event or multiple events.

2. If **no** event is mentioned, respond with:
  {
    "containsEvent": false
  }

3. If **one or more** events are mentioned, respond with a JSON object in this structure:
  {
    "containsEvent": true,
    "events": [
      {
        "title": string,
        "location": string,
        "start": ISO 8601 timestamp (e.g., "2025-07-15T14:00:00") or null if no time/date is provided,
        "end": ISO 8601 timestamp or null (see rules below),
        "isTimeSpecified": boolean (true if a specific time is given, false if only date or general reference is given),
        "description": string (a concise summary of the event),
        "category": one of the following fixed values:
          "Sport", "Music", "Education", "Work", "Health", "Arts & Culture", "Social & Entertainment", "Others"
      }
    ]
  }

Rules:
- start = null if no date/time is provided.
- end = null if start is null.
- If start exists and end is missing but isTimeSpecified is true, set end = start + 1 hour.
- isTimeSpecified = false for all-day or date-only events.
- Use ISO 8601 for timestamps.
- reply only with a json object, no additional text.
`;

    const fullPrompt = `${prompt}\n\nSubject: ${subject}\n\nEmail Body:\n${body}`;

    //const openAiKey = process.env.OPENAI_API_KEY || 'your-key-here';
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
          { role: 'system', content: 'You extract structured calendar events from emails.' },
          { role: 'user', content: fullPrompt },
        ],
        temperature: 0.2,
      }),
    });

    const json = await openAiRes.json();

    if (!openAiRes.ok) {
      console.error(`❌ OpenAI API error (${openAiRes.status}):`, JSON.stringify(json));
      continue;
    }

    let content = json.choices?.[0]?.message?.content?.trim() || '';
    // Remove markdown formatting if present
    if (content.startsWith('```json')) {
      content = content.replace(/^```json\s*/, '').replace(/\s*```$/, '');
    }

    let parsed;
    try {
      parsed = JSON.parse(content);
    } catch (err) {
      console.error(`❌ Failed to parse JSON content for msg ${msg.id}`, content);
      continue;
    }

    console.log(`📄 Parsed response for msg ${msg.id}:`, JSON.stringify(parsed, null, 2));
    console.log(`📄 Parsed response for msg ${msg.id}:`, JSON.stringify(parsed, null, 2));

    if (!parsed.containsEvent || !Array.isArray(parsed.events)) {
      console.log(`📭 No events found in message ${msg.id}`);
      continue;
    }

    for (const evt of parsed.events) {
      const {
        title,
        location,
        start,
        end,
        isTimeSpecified,
        description,
        category
      } = evt;

      if (!title || !description || !category) {
        console.warn(`⚠️ Skipping invalid event structure in message ${msg.id}`);
        continue;
      }

      const validCategories = [
        "Sport", "Music", "Education", "Work", "Health",
        "Arts & Culture", "Social & Entertainment", "Others"
      ];
      if (!validCategories.includes(category)) {
        console.warn(`⚠️ Invalid category "${category}" in message ${msg.id}`);
        continue;
      }

      // - If start exists and end is missing set end = start + 1 hour.
      /*let eventEnd = end ?
        new Date(end) :
        (start ? new Date(new Date(start).getTime() + 60 * 60 * 1000) : null);*/
        function fromUtcPlus2ToUtc(isoString) {
          const localDate = new Date(isoString);
          const utcTimestamp = localDate.getTime() - 2 * 60 * 60 * 1000;
          return new Date(utcTimestamp);
        }

        const eventStart = start ? fromUtcPlus2ToUtc(start) : null;
        const eventEnd = end
          ? fromUtcPlus2ToUtc(end)
          : (eventStart ? new Date(eventStart.getTime() + 60 * 60 * 1000) : null);


      await admin.firestore().collection('users').doc(uid).collection('events').add({
        title,
        location: location || '',
        //start: start ? new Date(start) : null,
        //end: end ? new Date(end) : null,
        start: eventStart,
        end: eventEnd,
        description,
        category,
        seen: false,
        status: 'pending',
        source: 'gmail',
        emailId: msg.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Saved event from Gmail: ${title}`);
    }
  }

  // ✅ Update lastHistoryId
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


