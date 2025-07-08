import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Schedule maintenance
export const scheduleMaintenance = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { busId, scheduledDate, type, description } = data;

  try {
    // Verify user has permission
    const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    const user = userDoc.data();
    
    if (!user || (user.role !== 'schoolAdmin' && user.role !== 'superAdmin')) {
      throw new functions.https.HttpsError('permission-denied', 'Access denied');
    }

    // Create maintenance record
    const maintenanceRef = admin.firestore().collection('maintenance').doc();
    await maintenanceRef.set({
      id: maintenanceRef.id,
      busId,
      scheduledDate: new Date(scheduledDate),
      type,
      description,
      status: 'scheduled',
      createdBy: context.auth.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { maintenanceId: maintenanceRef.id };
  } catch (error) {
    console.error('Error scheduling maintenance:', error);
    throw new functions.https.HttpsError('internal', 'Failed to schedule maintenance');
  }
});

export const maintenanceFunctions = {
  scheduleMaintenance,
};
