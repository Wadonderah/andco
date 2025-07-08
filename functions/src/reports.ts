import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Generate attendance report
export const generateAttendanceReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { schoolId, startDate, endDate, format = 'json' } = data;

  try {
    // Verify user has permission
    const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    const user = userDoc.data();
    
    if (!user || (user.role !== 'schoolAdmin' && user.role !== 'superAdmin')) {
      throw new functions.https.HttpsError('permission-denied', 'Access denied');
    }

    if (user.role === 'schoolAdmin' && user.schoolId !== schoolId) {
      throw new functions.https.HttpsError('permission-denied', 'Access denied to this school');
    }

    // Get check-ins for the date range
    const checkInsSnapshot = await admin.firestore()
      .collection('checkins')
      .where('timestamp', '>=', new Date(startDate))
      .where('timestamp', '<=', new Date(endDate))
      .get();

    const attendanceData = checkInsSnapshot.docs.map(doc => doc.data());

    return { attendanceData, format };
  } catch (error) {
    console.error('Error generating attendance report:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate attendance report');
  }
});

export const reportFunctions = {
  generateAttendanceReport,
};
