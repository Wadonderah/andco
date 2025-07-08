import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Import function modules
import { notificationFunctions } from './notifications';
import { paymentFunctions } from './payments';
import { tripFunctions } from './trips';
import { reportFunctions } from './reports';
import { maintenanceFunctions } from './maintenance';
import { analyticsFunction } from './analytics';
import { scheduledFunctions } from './scheduled';
import { webhookFunctions } from './webhooks';

// Export all functions
export const notifications = notificationFunctions;
export const payments = paymentFunctions;
export const trips = tripFunctions;
export const reports = reportFunctions;
export const maintenance = maintenanceFunctions;
export const analytics = analyticsFunction;
export const scheduled = scheduledFunctions;
export const webhooks = webhookFunctions;

// Health check function
export const healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// User creation trigger
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  try {
    // Create user document in Firestore
    await admin.firestore().collection('users').doc(user.uid).set({
      uid: user.uid,
      email: user.email,
      name: user.displayName || 'User',
      phoneNumber: user.phoneNumber,
      profileImageUrl: user.photoURL,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      isVerified: user.emailVerified,
    }, { merge: true });

    console.log(`User document created for ${user.uid}`);
  } catch (error) {
    console.error('Error creating user document:', error);
  }
});

// User deletion trigger
export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  try {
    // Delete user document from Firestore
    await admin.firestore().collection('users').doc(user.uid).delete();

    // Delete user's data from other collections
    const batch = admin.firestore().batch();

    // Delete children if user is a parent
    const childrenSnapshot = await admin.firestore()
      .collection('children')
      .where('parentId', '==', user.uid)
      .get();

    childrenSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Delete notifications
    const notificationsSnapshot = await admin.firestore()
      .collection('notifications')
      .where('userId', '==', user.uid)
      .get();

    notificationsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Delete payments
    const paymentsSnapshot = await admin.firestore()
      .collection('payments')
      .where('userId', '==', user.uid)
      .get();

    paymentsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log(`User data deleted for ${user.uid}`);
  } catch (error) {
    console.error('Error deleting user data:', error);
  }
});

// Firestore triggers for real-time updates
export const onChildUpdate = functions.firestore
  .document('children/{childId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const childId = context.params.childId;

    // Check if transport assignment changed
    if (before.busId !== after.busId || before.routeId !== after.routeId) {
      // Send notification to parent
      await admin.firestore().collection('notifications').add({
        userId: after.parentId,
        type: 'transport_assignment_changed',
        title: 'Transport Assignment Updated',
        body: `${after.name}'s transport assignment has been updated.`,
        data: {
          childId,
          oldBusId: before.busId,
          newBusId: after.busId,
          oldRouteId: before.routeId,
          newRouteId: after.routeId,
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

export const onBusLocationUpdate = functions.firestore
  .document('buses/{busId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const busId = context.params.busId;

    // Check if location changed significantly
    if (before.currentLatitude !== after.currentLatitude || 
        before.currentLongitude !== after.currentLongitude) {
      
      // Get children on this bus
      const childrenSnapshot = await admin.firestore()
        .collection('children')
        .where('busId', '==', busId)
        .where('isActive', '==', true)
        .get();

      // Send location updates to parents
      const notifications: any[] = [];
      
      childrenSnapshot.docs.forEach(childDoc => {
        const child = childDoc.data();
        notifications.push({
          userId: child.parentId,
          type: 'bus_location_update',
          title: 'Bus Location Update',
          body: `Bus ${after.busNumber} location has been updated.`,
          data: {
            busId,
            busNumber: after.busNumber,
            latitude: after.currentLatitude,
            longitude: after.currentLongitude,
            childId: childDoc.id,
            childName: child.name,
          },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Batch create notifications
      if (notifications.length > 0) {
        const batch = admin.firestore().batch();
        notifications.forEach(notification => {
          const notificationRef = admin.firestore().collection('notifications').doc();
          batch.set(notificationRef, notification);
        });
        await batch.commit();
      }
    }
  });

export const onIncidentCreate = functions.firestore
  .document('incidents/{incidentId}')
  .onCreate(async (snapshot, context) => {
    const incident = snapshot.data();
    const incidentId = context.params.incidentId;

    // Send notification to school admin
    await admin.firestore().collection('notifications').add({
      userId: incident.schoolId, // This should be the school admin's user ID
      type: 'incident_reported',
      title: 'New Incident Reported',
      body: `A ${incident.severity} incident has been reported on bus ${incident.busNumber}.`,
      data: {
        incidentId,
        busId: incident.busId,
        busNumber: incident.busNumber,
        severity: incident.severity,
        reportedBy: incident.reportedBy,
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // If it's a high severity incident, send emergency notifications
    if (incident.severity === 'high' || incident.severity === 'critical') {
      // Get all parents with children on this bus
      const childrenSnapshot = await admin.firestore()
        .collection('children')
        .where('busId', '==', incident.busId)
        .where('isActive', '==', true)
        .get();

      const emergencyNotifications: any[] = [];
      
      childrenSnapshot.docs.forEach(childDoc => {
        const child = childDoc.data();
        emergencyNotifications.push({
          userId: child.parentId,
          type: 'emergency_incident',
          title: 'Emergency Incident Alert',
          body: `An emergency incident has been reported on your child's bus. Please contact the school immediately.`,
          data: {
            incidentId,
            busId: incident.busId,
            busNumber: incident.busNumber,
            severity: incident.severity,
            childId: childDoc.id,
            childName: child.name,
          },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Batch create emergency notifications
      if (emergencyNotifications.length > 0) {
        const batch = admin.firestore().batch();
        emergencyNotifications.forEach(notification => {
          const notificationRef = admin.firestore().collection('notifications').doc();
          batch.set(notificationRef, notification);
        });
        await batch.commit();
      }
    }
  });

// Error handling middleware
export const onError = functions.https.onRequest((req, res) => {
  console.error('Unhandled error:', req.body);
  res.status(500).json({ error: 'Internal server error' });
});

// CORS middleware for all HTTP functions
export const corsMiddleware = functions.https.onRequest((req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
  } else {
    res.status(404).json({ error: 'Not found' });
  }
});
