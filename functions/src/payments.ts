import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

// Initialize Stripe
const stripe = new Stripe(functions.config().stripe.secret_key, {
  apiVersion: '2023-10-16',
});

interface CreatePaymentIntentRequest {
  amount: number;
  currency: string;
  userId: string;
  schoolId: string;
  description?: string;
  metadata?: { [key: string]: string };
}

interface ProcessMpesaPaymentRequest {
  phoneNumber: string;
  amount: number;
  userId: string;
  schoolId: string;
  description?: string;
}

// Create Stripe payment intent
export const createPaymentIntent = functions.https.onCall(async (data: CreatePaymentIntentRequest, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { amount, currency, userId, schoolId, description, metadata } = data;

  try {
    // Verify user exists and is active
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const user = userDoc.data();
    if (!user?.isActive) {
      throw new functions.https.HttpsError('permission-denied', 'User account is not active');
    }

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: currency.toLowerCase(),
      description: description || 'School transport payment',
      metadata: {
        userId,
        schoolId,
        ...metadata,
      },
    });

    // Store payment record in Firestore
    const paymentRef = admin.firestore().collection('payments').doc();
    await paymentRef.set({
      id: paymentRef.id,
      userId,
      schoolId,
      stripePaymentIntentId: paymentIntent.id,
      amount,
      currency,
      status: 'pending',
      description,
      metadata: metadata || {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      paymentIntentId: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      paymentId: paymentRef.id,
    };
  } catch (error) {
    console.error('Error creating payment intent:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create payment intent');
  }
});

// Handle Stripe webhook
export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'] as string;
  const endpointSecret = functions.config().stripe.webhook_secret;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    res.status(400).send('Webhook signature verification failed');
    return;
  }

  try {
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentSuccess(event.data.object as Stripe.PaymentIntent);
        break;
      case 'payment_intent.payment_failed':
        await handlePaymentFailure(event.data.object as Stripe.PaymentIntent);
        break;
      case 'payment_intent.canceled':
        await handlePaymentCancellation(event.data.object as Stripe.PaymentIntent);
        break;
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.status(200).send('Webhook handled successfully');
  } catch (error) {
    console.error('Error handling webhook:', error);
    res.status(500).send('Webhook handling failed');
  }
});

async function handlePaymentSuccess(paymentIntent: Stripe.PaymentIntent) {
  const { userId, schoolId } = paymentIntent.metadata;

  // Update payment record
  const paymentsQuery = await admin.firestore()
    .collection('payments')
    .where('stripePaymentIntentId', '==', paymentIntent.id)
    .get();

  if (!paymentsQuery.empty) {
    const paymentDoc = paymentsQuery.docs[0];
    await paymentDoc.ref.update({
      status: 'completed',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send success notification
    await admin.firestore().collection('notifications').add({
      userId,
      type: 'payment_success',
      title: 'Payment Successful',
      body: `Your payment of ${paymentIntent.currency.toUpperCase()} ${(paymentIntent.amount / 100).toFixed(2)} has been processed successfully.`,
      data: {
        paymentIntentId: paymentIntent.id,
        amount: (paymentIntent.amount / 100).toString(),
        currency: paymentIntent.currency.toUpperCase(),
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update user's payment status or subscription
    await updateUserPaymentStatus(userId, schoolId, 'active');
  }
}

async function handlePaymentFailure(paymentIntent: Stripe.PaymentIntent) {
  const { userId } = paymentIntent.metadata;

  // Update payment record
  const paymentsQuery = await admin.firestore()
    .collection('payments')
    .where('stripePaymentIntentId', '==', paymentIntent.id)
    .get();

  if (!paymentsQuery.empty) {
    const paymentDoc = paymentsQuery.docs[0];
    await paymentDoc.ref.update({
      status: 'failed',
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send failure notification
    await admin.firestore().collection('notifications').add({
      userId,
      type: 'payment_failed',
      title: 'Payment Failed',
      body: `Your payment of ${paymentIntent.currency.toUpperCase()} ${(paymentIntent.amount / 100).toFixed(2)} could not be processed. Please try again.`,
      data: {
        paymentIntentId: paymentIntent.id,
        amount: (paymentIntent.amount / 100).toString(),
        currency: paymentIntent.currency.toUpperCase(),
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handlePaymentCancellation(paymentIntent: Stripe.PaymentIntent) {
  const { userId } = paymentIntent.metadata;

  // Update payment record
  const paymentsQuery = await admin.firestore()
    .collection('payments')
    .where('stripePaymentIntentId', '==', paymentIntent.id)
    .get();

  if (!paymentsQuery.empty) {
    const paymentDoc = paymentsQuery.docs[0];
    await paymentDoc.ref.update({
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function updateUserPaymentStatus(userId: string, schoolId: string, status: string) {
  // Update user's payment status
  await admin.firestore().collection('users').doc(userId).update({
    paymentStatus: status,
    lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Update children's access status
  const childrenSnapshot = await admin.firestore()
    .collection('children')
    .where('parentId', '==', userId)
    .where('schoolId', '==', schoolId)
    .get();

  const batch = admin.firestore().batch();
  childrenSnapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      hasActivePayment: status === 'active',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
}

// Process M-Pesa payment (placeholder - requires M-Pesa API integration)
export const processMpesaPayment = functions.https.onCall(async (data: ProcessMpesaPaymentRequest, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { phoneNumber, amount, userId, schoolId, description } = data;

  try {
    // Verify user exists and is active
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    // Store payment record in Firestore
    const paymentRef = admin.firestore().collection('payments').doc();
    await paymentRef.set({
      id: paymentRef.id,
      userId,
      schoolId,
      phoneNumber,
      amount,
      currency: 'KES',
      status: 'pending',
      paymentMethod: 'mpesa',
      description: description || 'School transport payment',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // TODO: Integrate with M-Pesa Daraja API
    // This is a placeholder implementation
    console.log(`M-Pesa payment initiated for ${phoneNumber}: KES ${amount}`);

    return {
      paymentId: paymentRef.id,
      status: 'pending',
      message: 'M-Pesa payment initiated. Please complete the payment on your phone.',
    };
  } catch (error) {
    console.error('Error processing M-Pesa payment:', error);
    throw new functions.https.HttpsError('internal', 'Failed to process M-Pesa payment');
  }
});

// M-Pesa webhook handler (placeholder)
export const mpesaWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const { Body } = req.body;
    const { stkCallback } = Body;

    if (stkCallback) {
      const { MerchantRequestID, CheckoutRequestID, ResultCode, ResultDesc } = stkCallback;

      // Find payment record by checkout request ID
      const paymentsQuery = await admin.firestore()
        .collection('payments')
        .where('checkoutRequestId', '==', CheckoutRequestID)
        .get();

      if (!paymentsQuery.empty) {
        const paymentDoc = paymentsQuery.docs[0];
        const payment = paymentDoc.data();

        if (ResultCode === 0) {
          // Payment successful
          await paymentDoc.ref.update({
            status: 'completed',
            mpesaReceiptNumber: stkCallback.CallbackMetadata?.Item?.find((item: any) => item.Name === 'MpesaReceiptNumber')?.Value,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send success notification
          await admin.firestore().collection('notifications').add({
            userId: payment.userId,
            type: 'payment_success',
            title: 'M-Pesa Payment Successful',
            body: `Your M-Pesa payment of KES ${payment.amount} has been processed successfully.`,
            data: {
              paymentId: payment.id,
              amount: payment.amount.toString(),
              currency: 'KES',
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Update user's payment status
          await updateUserPaymentStatus(payment.userId, payment.schoolId, 'active');
        } else {
          // Payment failed
          await paymentDoc.ref.update({
            status: 'failed',
            failureReason: ResultDesc,
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send failure notification
          await admin.firestore().collection('notifications').add({
            userId: payment.userId,
            type: 'payment_failed',
            title: 'M-Pesa Payment Failed',
            body: `Your M-Pesa payment of KES ${payment.amount} could not be processed. ${ResultDesc}`,
            data: {
              paymentId: payment.id,
              amount: payment.amount.toString(),
              currency: 'KES',
              reason: ResultDesc,
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    }

    res.status(200).json({ ResultCode: 0, ResultDesc: 'Success' });
  } catch (error) {
    console.error('Error handling M-Pesa webhook:', error);
    res.status(500).json({ ResultCode: 1, ResultDesc: 'Error processing callback' });
  }
});

// Get payment history
export const getPaymentHistory = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, limit = 20, startAfter } = data;

  try {
    let query = admin.firestore()
      .collection('payments')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(limit);

    if (startAfter) {
      const startAfterDoc = await admin.firestore().collection('payments').doc(startAfter).get();
      query = query.startAfter(startAfterDoc);
    }

    const snapshot = await query.get();
    const payments = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return { payments };
  } catch (error) {
    console.error('Error getting payment history:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get payment history');
  }
});

export const paymentFunctions = {
  createPaymentIntent,
  stripeWebhook,
  processMpesaPayment,
  mpesaWebhook,
  getPaymentHistory,
};
