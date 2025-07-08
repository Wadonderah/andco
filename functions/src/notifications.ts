import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface NotificationPayload {
  title: string;
  body: string;
  data?: { [key: string]: string };
  imageUrl?: string;
}

interface SendNotificationRequest {
  userIds?: string[];
  topics?: string[];
  payload: NotificationPayload;
  type: string;
}

// Send push notification to specific users or topics
export const sendNotification = functions.https.onCall(async (data: SendNotificationRequest, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    const { userIds, topics, payload, type } = data;
    const results: any[] = [];

    // Send to specific users
    if (userIds && userIds.length > 0) {
      // Get FCM tokens for users
      const userTokens: string[] = [];
      
      for (const userId of userIds) {
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          if (userData?.fcmToken) {
            userTokens.push(userData.fcmToken);
          }
        }
      }

      if (userTokens.length > 0) {
        const message = {
          notification: {
            title: payload.title,
            body: payload.body,
            imageUrl: payload.imageUrl,
          },
          data: {
            type,
            ...payload.data,
          },
          tokens: userTokens,
        };

        const response = await admin.messaging().sendMulticast(message);
        results.push({
          type: 'users',
          successCount: response.successCount,
          failureCount: response.failureCount,
          responses: response.responses,
        });

        // Store notifications in Firestore
        const batch = admin.firestore().batch();
        userIds.forEach(userId => {
          const notificationRef = admin.firestore().collection('notifications').doc();
          batch.set(notificationRef, {
            userId,
            type,
            title: payload.title,
            body: payload.body,
            data: payload.data || {},
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
        await batch.commit();
      }
    }

    // Send to topics
    if (topics && topics.length > 0) {
      for (const topic of topics) {
        const message = {
          notification: {
            title: payload.title,
            body: payload.body,
            imageUrl: payload.imageUrl,
          },
          data: {
            type,
            ...payload.data,
          },
          topic,
        };

        const response = await admin.messaging().send(message);
        results.push({
          type: 'topic',
          topic,
          messageId: response,
        });
      }
    }

    return { success: true, results };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

// Send pickup notification
export const sendPickupNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { childId, childName, busNumber, estimatedMinutes } = data;

  try {
    // Get child's parent
    const childDoc = await admin.firestore().collection('children').doc(childId).get();
    if (!childDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Child not found');
    }

    const child = childDoc.data();
    const parentId = child?.parentId;

    if (!parentId) {
      throw new functions.https.HttpsError('invalid-argument', 'Child has no parent assigned');
    }

    // Send notification
    return await sendNotification({
      userIds: [parentId],
      payload: {
        title: 'Bus Pickup Alert',
        body: `Bus ${busNumber} will arrive to pick up ${childName} in approximately ${estimatedMinutes} minutes.`,
        data: {
          childId,
          childName,
          busNumber,
          estimatedMinutes: estimatedMinutes.toString(),
        },
      },
      type: 'pickup_alert',
    }, context);
  } catch (error) {
    console.error('Error sending pickup notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send pickup notification');
  }
});

// Send dropoff notification
export const sendDropoffNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { childId, childName, busNumber, estimatedMinutes } = data;

  try {
    // Get child's parent
    const childDoc = await admin.firestore().collection('children').doc(childId).get();
    if (!childDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Child not found');
    }

    const child = childDoc.data();
    const parentId = child?.parentId;

    if (!parentId) {
      throw new functions.https.HttpsError('invalid-argument', 'Child has no parent assigned');
    }

    // Send notification
    return await sendNotification({
      userIds: [parentId],
      payload: {
        title: 'Bus Dropoff Alert',
        body: `Bus ${busNumber} will drop off ${childName} in approximately ${estimatedMinutes} minutes.`,
        data: {
          childId,
          childName,
          busNumber,
          estimatedMinutes: estimatedMinutes.toString(),
        },
      },
      type: 'dropoff_alert',
    }, context);
  } catch (error) {
    console.error('Error sending dropoff notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send dropoff notification');
  }
});

// Send emergency notification
export const sendEmergencyNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { schoolId, message, severity, additionalData } = data;

  try {
    // Send to school emergency topic
    return await sendNotification({
      topics: [`school_${schoolId}_emergencies`],
      payload: {
        title: `Emergency Alert - ${severity.toUpperCase()}`,
        body: message,
        data: {
          schoolId,
          severity,
          ...additionalData,
        },
      },
      type: 'emergency_alert',
    }, context);
  } catch (error) {
    console.error('Error sending emergency notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send emergency notification');
  }
});

// Send maintenance notification
export const sendMaintenanceNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { busId, busNumber, message, maintenanceType } = data;

  try {
    // Send to bus maintenance topic
    return await sendNotification({
      topics: [`bus_${busId}_maintenance`],
      payload: {
        title: 'Maintenance Alert',
        body: `Bus ${busNumber}: ${message}`,
        data: {
          busId,
          busNumber,
          maintenanceType,
        },
      },
      type: 'maintenance_alert',
    }, context);
  } catch (error) {
    console.error('Error sending maintenance notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send maintenance notification');
  }
});

// Send payment notification
export const sendPaymentNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, status, amount, currency, transactionId } = data;

  try {
    let title = 'Payment Update';
    let body = '';

    switch (status) {
      case 'success':
        title = 'Payment Successful';
        body = `Your payment of ${currency} ${amount} has been processed successfully.`;
        break;
      case 'failed':
        title = 'Payment Failed';
        body = `Your payment of ${currency} ${amount} could not be processed. Please try again.`;
        break;
      case 'pending':
        title = 'Payment Pending';
        body = `Your payment of ${currency} ${amount} is being processed.`;
        break;
      default:
        body = `Payment status update: ${status}`;
    }

    return await sendNotification({
      userIds: [userId],
      payload: {
        title,
        body,
        data: {
          status,
          amount: amount.toString(),
          currency,
          transactionId: transactionId || '',
        },
      },
      type: 'payment_status',
    }, context);
  } catch (error) {
    console.error('Error sending payment notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send payment notification');
  }
});

// Clean up old notifications (scheduled function)
export const cleanupOldNotifications = functions.pubsub.schedule('0 2 * * *').onRun(async (context) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldNotificationsQuery = admin.firestore()
      .collection('notifications')
      .where('createdAt', '<', thirtyDaysAgo);

    const snapshot = await oldNotificationsQuery.get();
    
    if (snapshot.empty) {
      console.log('No old notifications to delete');
      return;
    }

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${snapshot.size} old notifications`);
  } catch (error) {
    console.error('Error cleaning up old notifications:', error);
  }
});

export const notificationFunctions = {
  sendNotification,
  sendPickupNotification,
  sendDropoffNotification,
  sendEmergencyNotification,
  sendMaintenanceNotification,
  sendPaymentNotification,
  cleanupOldNotifications,
};
