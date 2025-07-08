import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// WhatsApp webhook handler
export const whatsappWebhook = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method === 'GET') {
      // Webhook verification
      const mode = req.query['hub.mode'];
      const token = req.query['hub.verify_token'];
      const challenge = req.query['hub.challenge'];

      if (mode === 'subscribe' && token === functions.config().whatsapp.verify_token) {
        res.status(200).send(challenge);
      } else {
        res.status(403).send('Forbidden');
      }
    } else if (req.method === 'POST') {
      // Handle incoming messages
      const body = req.body;
      
      if (body.object === 'whatsapp_business_account') {
        body.entry?.forEach((entry: any) => {
          entry.changes?.forEach((change: any) => {
            if (change.field === 'messages') {
              const messages = change.value.messages;
              messages?.forEach(async (message: any) => {
                await handleWhatsAppMessage(message);
              });
            }
          });
        });
      }

      res.status(200).send('OK');
    }
  } catch (error) {
    console.error('Error handling WhatsApp webhook:', error);
    res.status(500).send('Error');
  }
});

async function handleWhatsAppMessage(message: any) {
  try {
    const { from, text, type } = message;
    
    if (type === 'text') {
      const messageText = text.body.toLowerCase();
      
      // Simple bot responses
      if (messageText.includes('status')) {
        // Send bus status
        await sendWhatsAppMessage(from, 'Your child\'s bus is currently on route. ETA: 15 minutes.');
      } else if (messageText.includes('help')) {
        // Send help message
        await sendWhatsAppMessage(from, 'Available commands:\n- "status" - Get bus status\n- "help" - Show this help');
      }
    }
  } catch (error) {
    console.error('Error handling WhatsApp message:', error);
  }
}

async function sendWhatsAppMessage(to: string, text: string) {
  // Placeholder for WhatsApp API integration
  console.log(`Sending WhatsApp message to ${to}: ${text}`);
}

// SMS webhook handler (for Twilio or Africa's Talking)
export const smsWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const { From, Body } = req.body;
    
    // Handle incoming SMS
    console.log(`SMS from ${From}: ${Body}`);
    
    res.status(200).send('OK');
  } catch (error) {
    console.error('Error handling SMS webhook:', error);
    res.status(500).send('Error');
  }
});

export const webhookFunctions = {
  whatsappWebhook,
  smsWebhook,
};
