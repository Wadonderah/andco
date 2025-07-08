import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface StartTripRequest {
  busId: string;
  routeId: string;
  driverId: string;
  type: 'pickup' | 'dropoff';
}

interface UpdateTripLocationRequest {
  tripId: string;
  latitude: number;
  longitude: number;
}

interface CompleteCheckInRequest {
  tripId: string;
  childId: string;
  stopId: string;
  method: 'manual' | 'qr' | 'face_id';
  photoUrl?: string;
}

// Start a new trip
export const startTrip = functions.https.onCall(async (data: StartTripRequest, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { busId, routeId, driverId, type } = data;

  try {
    // Verify driver is authenticated user
    if (context.auth.uid !== driverId) {
      throw new functions.https.HttpsError('permission-denied', 'Driver can only start their own trips');
    }

    // Verify bus and route exist
    const [busDoc, routeDoc] = await Promise.all([
      admin.firestore().collection('buses').doc(busId).get(),
      admin.firestore().collection('routes').doc(routeId).get(),
    ]);

    if (!busDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Bus not found');
    }

    if (!routeDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Route not found');
    }

    const bus = busDoc.data();
    const route = routeDoc.data();

    // Verify driver is assigned to this bus
    if (bus?.driverId !== driverId) {
      throw new functions.https.HttpsError('permission-denied', 'Driver not assigned to this bus');
    }

    // Check if there's already an active trip for this bus
    const activeTripQuery = await admin.firestore()
      .collection('trips')
      .where('busId', '==', busId)
      .where('status', '==', 'active')
      .get();

    if (!activeTripQuery.empty) {
      throw new functions.https.HttpsError('already-exists', 'There is already an active trip for this bus');
    }

    // Get children on this route
    const childrenSnapshot = await admin.firestore()
      .collection('children')
      .where('routeId', '==', routeId)
      .where('isActive', '==', true)
      .get();

    const childrenIds = childrenSnapshot.docs.map(doc => doc.id);

    // Create trip document
    const tripRef = admin.firestore().collection('trips').doc();
    const tripData = {
      id: tripRef.id,
      busId,
      routeId,
      driverId,
      busNumber: bus?.busNumber,
      routeName: route?.name,
      type,
      status: 'active',
      childrenIds,
      checkedInChildren: [],
      startTime: admin.firestore.FieldValue.serverTimestamp(),
      currentLocation: {
        latitude: bus?.currentLatitude || 0,
        longitude: bus?.currentLongitude || 0,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await tripRef.set(tripData);

    // Update bus status
    await admin.firestore().collection('buses').doc(busId).update({
      status: 'inTransit',
      currentTripId: tripRef.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notifications to parents
    const notifications: any[] = [];
    
    for (const childDoc of childrenSnapshot.docs) {
      const child = childDoc.data();
      notifications.push({
        userId: child.parentId,
        type: 'trip_started',
        title: `${type === 'pickup' ? 'Pickup' : 'Drop-off'} Trip Started`,
        body: `Bus ${bus?.busNumber} has started the ${type} route for ${child.name}.`,
        data: {
          tripId: tripRef.id,
          busId,
          routeId,
          childId: childDoc.id,
          childName: child.name,
          type,
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Batch create notifications
    if (notifications.length > 0) {
      const batch = admin.firestore().batch();
      notifications.forEach(notification => {
        const notificationRef = admin.firestore().collection('notifications').doc();
        batch.set(notificationRef, notification);
      });
      await batch.commit();
    }

    return { tripId: tripRef.id, status: 'started' };
  } catch (error) {
    console.error('Error starting trip:', error);
    throw new functions.https.HttpsError('internal', 'Failed to start trip');
  }
});

// Update trip location
export const updateTripLocation = functions.https.onCall(async (data: UpdateTripLocationRequest, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { tripId, latitude, longitude } = data;

  try {
    // Get trip document
    const tripDoc = await admin.firestore().collection('trips').doc(tripId).get();
    if (!tripDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Trip not found');
    }

    const trip = tripDoc.data();

    // Verify driver is authenticated user
    if (context.auth.uid !== trip?.driverId) {
      throw new functions.https.HttpsError('permission-denied', 'Only the assigned driver can update trip location');
    }

    // Update trip location
    await tripDoc.ref.update({
      currentLocation: {
        latitude,
        longitude,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update bus location
    await admin.firestore().collection('buses').doc(trip.busId).update({
      currentLatitude: latitude,
      currentLongitude: longitude,
      lastLocationUpdate: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error('Error updating trip location:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update trip location');
  }
});

// Complete child check-in
export const completeCheckIn = functions.https.onCall(async (data: CompleteCheckInRequest, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { tripId, childId, stopId, method, photoUrl } = data;

  try {
    // Get trip document
    const tripDoc = await admin.firestore().collection('trips').doc(tripId).get();
    if (!tripDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Trip not found');
    }

    const trip = tripDoc.data();

    // Verify driver is authenticated user
    if (context.auth.uid !== trip?.driverId) {
      throw new functions.https.HttpsError('permission-denied', 'Only the assigned driver can complete check-ins');
    }

    // Verify child is on this trip
    if (!trip?.childrenIds.includes(childId)) {
      throw new functions.https.HttpsError('invalid-argument', 'Child is not on this trip');
    }

    // Get child document
    const childDoc = await admin.firestore().collection('children').doc(childId).get();
    if (!childDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Child not found');
    }

    const child = childDoc.data();

    // Create check-in record
    const checkInRef = admin.firestore().collection('checkins').doc();
    const checkInData = {
      id: checkInRef.id,
      tripId,
      childId,
      childName: child?.name,
      stopId,
      driverId: trip.driverId,
      busId: trip.busId,
      routeId: trip.routeId,
      method,
      photoUrl: photoUrl || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      location: trip.currentLocation,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await checkInRef.set(checkInData);

    // Update trip with checked-in child
    const checkedInChildren = [...(trip.checkedInChildren || []), childId];
    await tripDoc.ref.update({
      checkedInChildren,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification to parent
    await admin.firestore().collection('notifications').add({
      userId: child?.parentId,
      type: trip.type === 'pickup' ? 'child_picked_up' : 'child_dropped_off',
      title: `${child?.name} ${trip.type === 'pickup' ? 'Picked Up' : 'Dropped Off'}`,
      body: `${child?.name} has been ${trip.type === 'pickup' ? 'picked up' : 'dropped off'} by bus ${trip.busNumber}.`,
      data: {
        tripId,
        childId,
        childName: child?.name,
        busId: trip.busId,
        busNumber: trip.busNumber,
        checkInId: checkInRef.id,
        timestamp: new Date().toISOString(),
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { checkInId: checkInRef.id, status: 'completed' };
  } catch (error) {
    console.error('Error completing check-in:', error);
    throw new functions.https.HttpsError('internal', 'Failed to complete check-in');
  }
});

// End trip
export const endTrip = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { tripId } = data;

  try {
    // Get trip document
    const tripDoc = await admin.firestore().collection('trips').doc(tripId).get();
    if (!tripDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Trip not found');
    }

    const trip = tripDoc.data();

    // Verify driver is authenticated user
    if (context.auth.uid !== trip?.driverId) {
      throw new functions.https.HttpsError('permission-denied', 'Only the assigned driver can end trips');
    }

    // Update trip status
    await tripDoc.ref.update({
      status: 'completed',
      endTime: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update bus status
    await admin.firestore().collection('buses').doc(trip.busId).update({
      status: 'active',
      currentTripId: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Calculate trip statistics
    const totalChildren = trip.childrenIds?.length || 0;
    const checkedInChildren = trip.checkedInChildren?.length || 0;
    const missedChildren = totalChildren - checkedInChildren;

    // Send notifications for missed children
    if (missedChildren > 0) {
      const missedChildrenIds = trip.childrenIds.filter((id: string) => 
        !trip.checkedInChildren.includes(id)
      );

      const notifications: any[] = [];
      
      for (const childId of missedChildrenIds) {
        const childDoc = await admin.firestore().collection('children').doc(childId).get();
        if (childDoc.exists) {
          const child = childDoc.data();
          notifications.push({
            userId: child?.parentId,
            type: 'child_missed',
            title: `${child?.name} Missed ${trip.type === 'pickup' ? 'Pickup' : 'Drop-off'}`,
            body: `${child?.name} was not ${trip.type === 'pickup' ? 'picked up' : 'dropped off'} during the scheduled trip.`,
            data: {
              tripId,
              childId,
              childName: child?.name,
              busId: trip.busId,
              busNumber: trip.busNumber,
              type: trip.type,
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

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

    return {
      status: 'completed',
      statistics: {
        totalChildren,
        checkedInChildren,
        missedChildren,
      },
    };
  } catch (error) {
    console.error('Error ending trip:', error);
    throw new functions.https.HttpsError('internal', 'Failed to end trip');
  }
});

// Get active trips for a driver
export const getActiveTrips = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { driverId } = data;

  try {
    // Verify driver is authenticated user or admin
    if (context.auth.uid !== driverId) {
      // Check if user is admin
      const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
      const user = userDoc.data();
      if (!user || (user.role !== 'schoolAdmin' && user.role !== 'superAdmin')) {
        throw new functions.https.HttpsError('permission-denied', 'Access denied');
      }
    }

    const tripsSnapshot = await admin.firestore()
      .collection('trips')
      .where('driverId', '==', driverId)
      .where('status', '==', 'active')
      .get();

    const trips = tripsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return { trips };
  } catch (error) {
    console.error('Error getting active trips:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get active trips');
  }
});

// Get trip history
export const getTripHistory = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { driverId, limit = 20, startAfter } = data;

  try {
    // Verify driver is authenticated user or admin
    if (context.auth.uid !== driverId) {
      // Check if user is admin
      const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
      const user = userDoc.data();
      if (!user || (user.role !== 'schoolAdmin' && user.role !== 'superAdmin')) {
        throw new functions.https.HttpsError('permission-denied', 'Access denied');
      }
    }

    let query = admin.firestore()
      .collection('trips')
      .where('driverId', '==', driverId)
      .orderBy('createdAt', 'desc')
      .limit(limit);

    if (startAfter) {
      const startAfterDoc = await admin.firestore().collection('trips').doc(startAfter).get();
      query = query.startAfter(startAfterDoc);
    }

    const snapshot = await query.get();
    const trips = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return { trips };
  } catch (error) {
    console.error('Error getting trip history:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get trip history');
  }
});

export const tripFunctions = {
  startTrip,
  updateTripLocation,
  completeCheckIn,
  endTrip,
  getActiveTrips,
  getTripHistory,
};
