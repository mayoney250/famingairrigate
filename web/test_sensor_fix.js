// COMPREHENSIVE TEST SCRIPT FOR SENSOR DATA FIX
// Copy and paste this entire script into your browser console (F12)

console.log('🧪 ===== SENSOR DATA FIX VERIFICATION TEST =====');
console.log('');

// Step 1: Clear all caches
console.log('📋 STEP 1: Clearing all caches...');
try {
    await indexedDB.deleteDatabase('hive');
    await indexedDB.deleteDatabase('sensorDataCache');
    await indexedDB.deleteDatabase('flowMeterCache');
    console.log('✅ All caches cleared successfully');
} catch (e) {
    console.log('⚠️ Error clearing caches:', e);
}

console.log('');
console.log('📋 STEP 2: Checking Firestore data...');

// Step 2: Verify data exists in Firestore
const fieldId = 'Efi0W7TYyMqQvycxedWK'; // Your field ID
try {
    const snapshot = await firebase.firestore()
        .collection('sensorData')
        .where('fieldId', '==', fieldId)
        .orderBy('timestamp', 'desc')
        .limit(5)
        .get();

    console.log(`✅ Found ${snapshot.docs.length} sensor readings in Firestore`);

    if (snapshot.docs.length > 0) {
        console.log('📊 Sample data:');
        snapshot.docs.forEach((doc, i) => {
            const data = doc.data();
            console.log(`   Reading ${i + 1}:`, {
                soilMoisture: data.soilMoisture,
                temperature: data.temperature,
                humidity: data.humidity,
                timestamp: data.timestamp?.toDate()
            });
        });
    } else {
        console.log('❌ NO DATA FOUND IN FIRESTORE!');
        console.log('   Please add sensor data to Firestore first.');
        console.log('   Collection: sensorData');
        console.log('   Required fields: fieldId, soilMoisture, temperature, humidity, timestamp');
    }
} catch (error) {
    console.error('❌ Error querying Firestore:', error);
    if (error.code === 'failed-precondition') {
        console.log('⚠️ MISSING INDEX! Create composite index:');
        console.log('   Collection: sensorData');
        console.log('   Fields: fieldId (Ascending) + timestamp (Descending)');
    }
}

console.log('');
console.log('📋 STEP 3: Instructions to verify fix...');
console.log('');
console.log('1️⃣ Reload the page now: location.reload()');
console.log('2️⃣ Watch the browser console for these logs:');
console.log('   - "📭 Cache empty for [fieldId], fetching from Firestore..."');
console.log('   - "🔍 [SENSOR FETCH] Starting fetch for fieldId: ..."');
console.log('   - "🔍 [SENSOR FETCH] Query completed. Found X documents"');
console.log('   - "✅ Returning X fresh sensor readings for [fieldId]"');
console.log('');
console.log('3️⃣ Check the dashboard UI:');
console.log('   - Sensor data should appear on field cards');
console.log('   - Soil moisture, temperature, humidity should display');
console.log('   - No "No data" or empty states');
console.log('');
console.log('4️⃣ Reload again (without clearing cache):');
console.log('   - Should see: "📦 Returning X cached sensor readings"');
console.log('   - Data should appear INSTANTLY (from cache)');
console.log('');
console.log('🧪 ===== TEST PREPARATION COMPLETE =====');
console.log('Run: location.reload() to start the test');
