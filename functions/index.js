const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onDocumentWritten, onDocumentCreated} = require('firebase-functions/v2/firestore');
const {onCall} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();

// Runs every day at 6:00 AM UTC (adjust timezone as needed)
exports.dailyPlanPromotion = onSchedule({
  schedule: '0 6 * * *',
  timeZone: 'America/New_York', // Change to your preferred timezone
}, async (event) => {
  const db = getFirestore();
  
  console.log('🔄 Starting daily plan promotion check...');
  
  try {
    const now = Timestamp.now();
    const nowDate = now.toDate();
    console.log(`📅 Checking for plans that should start by: ${nowDate.toISOString()}`);
    
    // Query all clients with upcoming plans that should start today or earlier
    const clientsQuery = await db.collection('clients')
      .where('nextPlanStartDate', '<=', now)
      .where('nextPlanId', '!=', null)
      .get();
    
    if (clientsQuery.empty) {
      console.log('✅ No plans need promotion today');
      return;
    }
    
    console.log(`📋 Found ${clientsQuery.size} clients with plans to promote`);
    
    const batch = db.batch();
    let promotionCount = 0;
    const promotedClients = [];
    
    clientsQuery.forEach((doc) => {
      const clientData = doc.data();
      const clientRef = doc.ref;
      
      console.log(`🔄 Promoting plan for client: ${clientData.name} (${doc.id})`);
      console.log(`   Next plan: ${clientData.nextPlanId}`);
      console.log(`   Start date: ${clientData.nextPlanStartDate.toDate().toISOString()}`);
      
      // Promote the upcoming plan to current plan
      batch.update(clientRef, {
        // Move next plan to current
        currentPlanId: clientData.nextPlanId,
        currentPlanStartDate: clientData.nextPlanStartDate,
        currentPlanEndDate: clientData.nextPlanEndDate,
        
        // Clear next plan fields
        nextPlanId: null,
        nextPlanStartDate: null,
        nextPlanEndDate: null,
        
        // Add metadata
        lastPromotionDate: now,
        promotionMethod: 'cloud-function'
      });
      
      promotedClients.push({
        id: doc.id,
        name: clientData.name,
        planId: clientData.nextPlanId
      });
      
      promotionCount++;
    });
    
    // Execute all promotions in a single batch
    await batch.commit();
    
    console.log(`✅ Successfully promoted ${promotionCount} plans:`);
    promotedClients.forEach(client => {
      console.log(`   - ${client.name}: Plan ${client.planId}`);
    });
    
    // Optional: Add analytics or notifications here
    // You could send notifications to trainers about promoted plans
    
  } catch (error) {
    console.error('❌ Error during plan promotion:', error);
    throw error; // This will trigger Cloud Function retry logic
  }
  
  console.log('🎉 Daily plan promotion check completed');
});

// Optional: Manual trigger function for testing
exports.manualPlanPromotion = onSchedule({
  schedule: 'every 24 hours', // This won't actually run, it's just for manual testing
}, async (event) => {
  // This is the same logic as above, but can be triggered manually for testing
  // You can call this via: firebase functions:shell
  return exports.dailyPlanPromotion(event);
});

// =============================================================================
// NOTIFICATION FUNCTIONS
// =============================================================================

// Helper function to check quiet hours (10:00 PM - 7:00 AM)
function isQuietHours() {
  const now = new Date();
  const hour = now.getHours();
  return hour >= 22 || hour < 7; // 10 PM to 7 AM
}

// Helper function to send notification
async function sendNotification(fcmToken, title, body, data = {}) {
  if (!fcmToken) {
    console.log('❌ No FCM token provided');
    return false;
  }
  
  // Skip notifications during quiet hours
  if (isQuietHours()) {
    console.log('🌙 Skipping notification due to quiet hours');
    return false;
  }
  
  try {
    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data,
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    const response = await getMessaging().send(message);
    console.log('✅ Notification sent successfully:', response);
    return true;
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    return false;
  }
}

// Helper function to get user notification settings and FCM token
async function getUserNotificationData(userId, userType) {
  const db = getFirestore();
  
  try {
    const userDoc = await db.collection(userType === 'trainer' ? 'trainers' : 'clients').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log(`❌ User not found: ${userId}`);
      return null;
    }
    
    const userData = userDoc.data();
    const notificationsEnabled = userData.notificationsEnabled !== false; // Default to true
    const fcmToken = userData.fcmToken;
    
    return {
      fcmToken,
      notificationsEnabled,
      userData
    };
  } catch (error) {
    console.error('❌ Error getting user notification data:', error);
    return null;
  }
}

// =============================================================================
// CLIENT NOTIFICATIONS
// =============================================================================

// Send workout reminders (runs twice daily at 8 AM and 6 PM)
exports.sendWorkoutReminders = onSchedule({
  schedule: '0 8,18 * * *', // 8 AM and 6 PM UTC
  timeZone: 'America/New_York',
}, async (event) => {
  if (isQuietHours()) return;
  
  const db = getFirestore();
  console.log('🏃‍♀️ Starting workout reminder notifications...');
  
  try {
    const clientsQuery = await db.collection('clients').get();
    let remindersSent = 0;
    
    for (const clientDoc of clientsQuery.docs) {
      const clientData = clientDoc.data();
      const notificationData = await getUserNotificationData(clientDoc.id, 'client');
      
      if (!notificationData || !notificationData.notificationsEnabled) {
        continue;
      }
      
      // Check if client has a current plan
      if (clientData.currentPlanId) {
        const success = await sendNotification(
          notificationData.fcmToken,
          'Time for your workout! 💪',
          `Don't forget to complete today's workout. You've got this!`,
          {
            type: 'workout_reminder',
            clientId: clientDoc.id
          }
        );
        
        if (success) remindersSent++;
      }
    }
    
    console.log(`✅ Sent ${remindersSent} workout reminders`);
  } catch (error) {
    console.error('❌ Error sending workout reminders:', error);
  }
});

// Trigger when a plan is assigned to a client
exports.onPlanAssigned = onDocumentWritten('clients/{clientId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  
  if (!after) return; // Document deleted
  
  // Check if a new plan was assigned
  const hadPlan = before?.currentPlanId;
  const hasPlan = after.currentPlanId;
  
  if (!hadPlan && hasPlan) {
    console.log(`📋 New plan assigned to client: ${event.params.clientId}`);
    
    const notificationData = await getUserNotificationData(event.params.clientId, 'client');
    
    if (notificationData && notificationData.notificationsEnabled) {
      await sendNotification(
        notificationData.fcmToken,
        'New workout plan assigned! 🎯',
        'Your trainer has assigned you a new workout plan. Check it out!',
        {
          type: 'plan_assigned',
          clientId: event.params.clientId,
          planId: hasPlan
        }
      );
    }
  }
});

// Trigger when a client message is created
exports.onClientMessageCreated = onDocumentCreated('conversations/{conversationId}/messages/{messageId}', async (event) => {
  const messageData = event.data?.data();
  
  if (!messageData || messageData.senderType !== 'client') {
    return; // Only notify trainers of client messages
  }
  
  console.log(`💬 New client message in conversation: ${event.params.conversationId}`);
  
  try {
    const db = getFirestore();
    
    // Get conversation to find trainer
    const conversationDoc = await db.collection('conversations').doc(event.params.conversationId).get();
    const conversationData = conversationDoc.data();
    
    if (!conversationData) return;
    
    const trainerId = conversationData.trainerId;
    const clientId = conversationData.clientId;
    
    // Get client name
    const clientDoc = await db.collection('clients').doc(clientId).get();
    const clientName = clientDoc.data()?.name || 'A client';
    
    // Get trainer notification data
    const notificationData = await getUserNotificationData(trainerId, 'trainer');
    
    if (notificationData && notificationData.notificationsEnabled) {
      await sendNotification(
        notificationData.fcmToken,
        `New message from ${clientName}`,
        messageData.content.substring(0, 100) + (messageData.content.length > 100 ? '...' : ''),
        {
          type: 'client_message',
          conversationId: event.params.conversationId,
          clientId,
          trainerId
        }
      );
    }
  } catch (error) {
    console.error('❌ Error sending client message notification:', error);
  }
});

// =============================================================================
// TRAINER NOTIFICATIONS  
// =============================================================================

// Trigger when a trainer message is created
exports.onTrainerMessageCreated = onDocumentCreated('conversations/{conversationId}/messages/{messageId}', async (event) => {
  const messageData = event.data?.data();
  
  if (!messageData || messageData.senderType !== 'trainer') {
    return; // Only notify clients of trainer messages
  }
  
  console.log(`💬 New trainer message in conversation: ${event.params.conversationId}`);
  
  try {
    const db = getFirestore();
    
    // Get conversation to find client
    const conversationDoc = await db.collection('conversations').doc(event.params.conversationId).get();
    const conversationData = conversationDoc.data();
    
    if (!conversationData) return;
    
    const clientId = conversationData.clientId;
    const trainerId = conversationData.trainerId;
    
    // Get trainer name
    const trainerDoc = await db.collection('trainers').doc(trainerId).get();
    const trainerName = trainerDoc.data()?.name || 'Your trainer';
    
    // Get client notification data
    const notificationData = await getUserNotificationData(clientId, 'client');
    
    if (notificationData && notificationData.notificationsEnabled) {
      await sendNotification(
        notificationData.fcmToken,
        `New message from ${trainerName}`,
        messageData.content.substring(0, 100) + (messageData.content.length > 100 ? '...' : ''),
        {
          type: 'trainer_message',
          conversationId: event.params.conversationId,
          clientId,
          trainerId
        }
      );
    }
  } catch (error) {
    console.error('❌ Error sending trainer message notification:', error);
  }
});

// Trigger when workout is completed
exports.onWorkoutCompleted = onDocumentWritten('clients/{clientId}/workoutSessions/{sessionId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  
  if (!after) return; // Document deleted
  
  // Check if workout was just completed
  const wasCompleted = before?.isCompleted;
  const isCompleted = after.isCompleted;
  
  if (!wasCompleted && isCompleted) {
    console.log(`✅ Workout completed by client: ${event.params.clientId}`);
    
    try {
      const db = getFirestore();
      
      // Get client data to find trainer
      const clientDoc = await db.collection('clients').doc(event.params.clientId).get();
      const clientData = clientDoc.data();
      
      if (!clientData?.trainerId) return;
      
      // Get trainer notification data
      const notificationData = await getUserNotificationData(clientData.trainerId, 'trainer');
      
      if (notificationData && notificationData.notificationsEnabled) {
        await sendNotification(
          notificationData.fcmToken,
          `${clientData.name} completed a workout! 🎉`,
          'Great job! Your client just finished their workout.',
          {
            type: 'workout_completed',
            clientId: event.params.clientId,
            sessionId: event.params.sessionId
          }
        );
      }
    } catch (error) {
      console.error('❌ Error sending workout completion notification:', error);
    }
  }
});

// Check for missed workouts (runs daily at 9 PM)
exports.checkMissedWorkouts = onSchedule({
  schedule: '0 21 * * *', // 9 PM UTC
  timeZone: 'America/New_York',
}, async (event) => {
  const db = getFirestore();
  console.log('📅 Checking for missed workouts...');
  
  try {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    
    const clientsQuery = await db.collection('clients').where('currentPlanId', '!=', null).get();
    
    for (const clientDoc of clientsQuery.docs) {
      const clientData = clientDoc.data();
      
      // Check if client had a workout scheduled yesterday but didn't complete it
      const sessionsQuery = await db.collection('clients')
        .doc(clientDoc.id)
        .collection('workoutSessions')
        .where('scheduledDate', '>=', Timestamp.fromDate(yesterday))
        .where('scheduledDate', '<', Timestamp.fromDate(new Date(yesterday.getTime() + 24 * 60 * 60 * 1000)))
        .where('isCompleted', '==', false)
        .get();
      
      if (!sessionsQuery.empty) {
        // Notify client about missed workout
        const clientNotificationData = await getUserNotificationData(clientDoc.id, 'client');
        
        if (clientNotificationData && clientNotificationData.notificationsEnabled) {
          await sendNotification(
            clientNotificationData.fcmToken,
            'Don\'t worry, get back on track! 💪',
            'Yesterday\'s workout was missed, but today is a new opportunity to crush your goals!',
            {
              type: 'missed_workout_followup',
              clientId: clientDoc.id
            }
          );
        }
        
        // Notify trainer about client's missed workout
        if (clientData.trainerId) {
          const trainerNotificationData = await getUserNotificationData(clientData.trainerId, 'trainer');
          
          if (trainerNotificationData && trainerNotificationData.notificationsEnabled) {
            await sendNotification(
              trainerNotificationData.fcmToken,
              `${clientData.name} missed yesterday's workout`,
              'Consider reaching out to provide support and motivation.',
              {
                type: 'client_missed_workout',
                clientId: clientDoc.id,
                trainerId: clientData.trainerId
              }
            );
          }
        }
      }
    }
    
    console.log('✅ Missed workout check completed');
  } catch (error) {
    console.error('❌ Error checking missed workouts:', error);
  }
});

// =============================================================================
// INVITATION FUNCTIONS
// =============================================================================

// Validates and retrieves invitation details for unauthenticated users
exports.validateInvitation = onCall({
  cors: true,
}, async (request) => {
  const invitationId = request.data.invitationId;
  
  if (!invitationId) {
    throw new Error('Invitation ID is required');
  }
  
  console.log(`🔍 Validating invitation: ${invitationId}`);
  
  try {
    const db = getFirestore();
    const invitationDoc = await db.collection('invitations').doc(invitationId).get();
    
    if (!invitationDoc.exists) {
      throw new Error('Invitation not found');
    }
    
    const invitationData = invitationDoc.data();
    
    // Check if invitation is still valid
    if (invitationData.status !== 'Pending') {
      throw new Error('Invitation has already been processed');
    }
    
    const now = new Date();
    const expiresAt = invitationData.expiresAt.toDate();
    
    if (now > expiresAt) {
      throw new Error('Invitation has expired');
    }
    
    // Return safe invitation data (exclude sensitive info)
    const safeInvitationData = {
      id: invitationDoc.id,
      trainerId: invitationData.trainerId,
      trainerName: invitationData.trainerName,
      clientEmail: invitationData.clientEmail,
      clientName: invitationData.clientName,
      personalNote: invitationData.personalNote,
      createdAt: invitationData.createdAt,
      expiresAt: invitationData.expiresAt,
      goal: invitationData.goal,
      injuries: invitationData.injuries,
      preferredCoachingStyle: invitationData.preferredCoachingStyle
    };
    
    console.log(`✅ Invitation validated successfully for trainer: ${invitationData.trainerName}`);
    return { invitation: safeInvitationData };
    
  } catch (error) {
    console.error(`❌ Error validating invitation ${invitationId}:`, error);
    throw error;
  }
});

// Accepts an invitation and creates client account (for authenticated users)
exports.acceptInvitation = onCall({
  cors: true,
}, async (request) => {
  const { invitationId } = request.data;
  const uid = request.auth?.uid;
  
  if (!uid) {
    throw new Error('User must be authenticated to accept invitation');
  }
  
  if (!invitationId) {
    throw new Error('Invitation ID is required');
  }
  
  console.log(`🤝 User ${uid} accepting invitation: ${invitationId}`);
  
  try {
    const db = getFirestore();
    
    // First validate the invitation
    const invitationDoc = await db.collection('invitations').doc(invitationId).get();
    
    if (!invitationDoc.exists) {
      throw new Error('Invitation not found');
    }
    
    const invitationData = invitationDoc.data();
    
    // Check if invitation is still valid
    if (invitationData.status !== 'Pending') {
      throw new Error('Invitation has already been processed');
    }
    
    const now = new Date();
    const expiresAt = invitationData.expiresAt.toDate();
    
    if (now > expiresAt) {
      throw new Error('Invitation has expired');
    }
    
    // Create client record
    const clientData = {
      id: uid,
      name: invitationData.clientName || 'Client',
      email: invitationData.clientEmail,
      trainerId: invitationData.trainerId,
      status: 'Active',
      joinedDate: Timestamp.now(),
      goal: invitationData.goal || null,
      injuries: invitationData.injuries || null,
      preferredCoachingStyle: invitationData.preferredCoachingStyle || null,
      notificationsEnabled: true,
      totalWorkoutsCompleted: 0,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now()
    };
    
    // Use a transaction to ensure consistency
    await db.runTransaction(async (transaction) => {
      // Save client to main collection
      transaction.set(db.collection('clients').doc(uid), clientData);
      
      // Save client to trainer's subcollection
      transaction.set(
        db.collection('trainers').doc(invitationData.trainerId).collection('clients').doc(uid),
        clientData
      );
      
      // Update user role
      transaction.set(db.collection('users').doc(uid), {
        role: 'client',
        name: clientData.name,
        email: clientData.email
      }, { merge: true });
      
      // Mark invitation as accepted
      transaction.update(db.collection('invitations').doc(invitationId), {
        status: 'Accepted',
        acceptedAt: Timestamp.now(),
        acceptedBy: uid
      });
    });
    
    console.log(`✅ Invitation accepted successfully. Client ${uid} linked to trainer ${invitationData.trainerId}`);
    
    return { 
      success: true, 
      client: clientData 
    };
    
  } catch (error) {
    console.error(`❌ Error accepting invitation ${invitationId}:`, error);
    throw error;
  }
}); 