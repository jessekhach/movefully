const {onSchedule} = require('firebase-functions/v2/scheduler');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');

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