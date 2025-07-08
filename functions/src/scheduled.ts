import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Daily maintenance check
export const dailyMaintenanceCheck = functions.pubsub.schedule('0 6 * * *').onRun(async (context) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Check for buses needing maintenance
    const busesSnapshot = await admin.firestore()
      .collection('buses')
      .where('nextMaintenanceDate', '<=', tomorrow)
      .where('isActive', '==', true)
      .get();

    const notifications: any[] = [];

    busesSnapshot.docs.forEach(doc => {
      const bus = doc.data();
      notifications.push({
        type: 'maintenance_reminder',
        title: 'Maintenance Due',
        body: `Bus ${bus.busNumber} is due for maintenance.`,
        data: {
          busId: doc.id,
          busNumber: bus.busNumber,
          dueDate: bus.nextMaintenanceDate,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Send notifications to school admins
    if (notifications.length > 0) {
      const batch = admin.firestore().batch();
      notifications.forEach(notification => {
        const notificationRef = admin.firestore().collection('notifications').doc();
        batch.set(notificationRef, notification);
      });
      await batch.commit();
    }

    console.log(`Processed ${notifications.length} maintenance reminders`);
  } catch (error) {
    console.error('Error in daily maintenance check:', error);
  }
});

// Weekly report generation
export const weeklyReportGeneration = functions.pubsub.schedule('0 8 * * 1').onRun(async (context) => {
  try {
    // Generate weekly reports for all schools
    const schoolsSnapshot = await admin.firestore().collection('schools').get();
    
    for (const schoolDoc of schoolsSnapshot.docs) {
      const schoolId = schoolDoc.id;
      
      // Generate attendance report
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(endDate.getDate() - 7);

      const checkInsSnapshot = await admin.firestore()
        .collection('checkins')
        .where('timestamp', '>=', startDate)
        .where('timestamp', '<=', endDate)
        .get();

      const reportData = {
        schoolId,
        period: 'week',
        startDate,
        endDate,
        totalCheckIns: checkInsSnapshot.size,
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Store report
      await admin.firestore().collection('reports').add(reportData);
    }

    console.log(`Generated weekly reports for ${schoolsSnapshot.size} schools`);
  } catch (error) {
    console.error('Error generating weekly reports:', error);
  }
});

export const scheduledFunctions = {
  dailyMaintenanceCheck,
  weeklyReportGeneration,
};
