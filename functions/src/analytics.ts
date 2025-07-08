import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Generate analytics data
export const generateAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { schoolId, period = 'month' } = data;

  try {
    // Verify user has permission
    const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    const user = userDoc.data();
    
    if (!user || (user.role !== 'schoolAdmin' && user.role !== 'superAdmin')) {
      throw new functions.https.HttpsError('permission-denied', 'Access denied');
    }

    // Calculate date range based on period
    const endDate = new Date();
    const startDate = new Date();
    
    switch (period) {
      case 'week':
        startDate.setDate(endDate.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(endDate.getMonth() - 1);
        break;
      case 'year':
        startDate.setFullYear(endDate.getFullYear() - 1);
        break;
    }

    // Get analytics data
    const [tripsSnapshot, checkInsSnapshot, incidentsSnapshot] = await Promise.all([
      admin.firestore()
        .collection('trips')
        .where('createdAt', '>=', startDate)
        .where('createdAt', '<=', endDate)
        .get(),
      admin.firestore()
        .collection('checkins')
        .where('timestamp', '>=', startDate)
        .where('timestamp', '<=', endDate)
        .get(),
      admin.firestore()
        .collection('incidents')
        .where('createdAt', '>=', startDate)
        .where('createdAt', '<=', endDate)
        .get(),
    ]);

    const analytics = {
      totalTrips: tripsSnapshot.size,
      totalCheckIns: checkInsSnapshot.size,
      totalIncidents: incidentsSnapshot.size,
      period,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
    };

    return analytics;
  } catch (error) {
    console.error('Error generating analytics:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate analytics');
  }
});

export const analyticsFunction = {
  generateAnalytics,
};
