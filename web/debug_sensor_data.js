// Debug script to check sensor data fetching
// Run this in browser console

console.log('=== SENSOR DATA DEBUG ===');

const checkSensorData = async () => {
    const fieldId = 'Efi0W7TYyMqQvycxedWK'; // Your field ID

    console.log('\n1. Checking Firestore directly...');
    try {
        const snapshot = await firebase.firestore()
            .collection('sensorData')
            .where('fieldId', '==', fieldId)
            .orderBy('timestamp', 'descending')
            .limit(5)
            .get();

        console.log(`✅ Found ${snapshot.docs.length} sensor readings for field ${fieldId}`);
        snapshot.docs.forEach((doc, i) => {
            const data = doc.data();
            console.log(`Reading ${i + 1}:`, {
                id: doc.id,
                soilMoisture: data.soilMoisture,
                temperature: data.temperature,
                humidity: data.humidity,
                timestamp: data.timestamp?.toDate(),
                fieldId: data.fieldId,
                userId: data.userId
            });
        });

        if (snapshot.docs.length === 0) {
            console.log('❌ No data found. Possible issues:');
            console.log('   - fieldId mismatch');
            console.log('   - Missing index (check Firebase Console for index creation link)');
            console.log('   - Security rules blocking read');
        }
    } catch (error) {
        console.error('❌ Error querying Firestore:', error);
        if (error.code === 'failed-precondition') {
            console.log('⚠️ MISSING INDEX! Click the link in the error above to create it.');
        }
    }

    console.log('\n2. Checking Hive cache...');
    try {
        // Try to access IndexedDB (where Hive stores data)
        const dbs = await indexedDB.databases();
        console.log('Available databases:', dbs.map(db => db.name));

        const hiveDb = dbs.find(db => db.name === 'hive');
        if (hiveDb) {
            console.log('✅ Hive cache exists');
            console.log('   To clear cache, run: indexedDB.deleteDatabase("hive")');
        } else {
            console.log('ℹ️ No Hive cache found (this is normal on first load)');
        }
    } catch (e) {
        console.log('ℹ️ Could not check cache:', e.message);
    }

    console.log('\n3. Checking current user...');
    const user = firebase.auth().currentUser;
    if (user) {
        console.log('✅ Logged in as:', user.uid);
        console.log('   Email:', user.email);
    } else {
        console.log('❌ Not logged in!');
    }

    console.log('\n=== DEBUG COMPLETE ===');
    console.log('\nNext steps:');
    console.log('1. If you see "MISSING INDEX" error, click the link to create it');
    console.log('2. If you see 0 readings but no errors, check fieldId matches');
    console.log('3. If you see readings, clear cache: indexedDB.deleteDatabase("hive")');
    console.log('4. Then reload the page');
};

checkSensorData();
