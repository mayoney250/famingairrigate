// Firestore Data Debugging Script
// Run this in your browser console while logged into the app

console.log('=== FIRESTORE DATA DEBUG ===');

// 1. Check current user
const checkUser = async () => {
    const user = firebase.auth().currentUser;
    if (user) {
        console.log('✅ User logged in:', user.uid);
        console.log('   Email:', user.email);
        return user.uid;
    } else {
        console.log('❌ No user logged in!');
        return null;
    }
};

// 2. Check irrigation schedules
const checkSchedules = async (userId) => {
    console.log('\n--- Checking Irrigation Schedules ---');
    try {
        const snapshot = await firebase.firestore()
            .collection('irrigationSchedules')
            .where('userId', '==', userId)
            .get();

        console.log(`Found ${snapshot.docs.length} schedules`);
        snapshot.docs.forEach((doc, i) => {
            console.log(`Schedule ${i + 1}:`, doc.id, doc.data());
        });
    } catch (error) {
        console.error('❌ Error fetching schedules:', error);
    }
};

// 3. Check sensors
const checkSensors = async (farmId) => {
    console.log('\n--- Checking Sensors ---');
    console.log('Using farmId:', farmId);
    try {
        const snapshot = await firebase.firestore()
            .collection('sensors')
            .where('farmId', '==', farmId)
            .get();

        console.log(`Found ${snapshot.docs.length} sensors`);
        snapshot.docs.forEach((doc, i) => {
            console.log(`Sensor ${i + 1}:`, doc.id, doc.data());
        });
    } catch (error) {
        console.error('❌ Error fetching sensors:', error);
    }
};

// 4. List ALL collections (to see what you actually have)
const listAllCollections = async () => {
    console.log('\n--- Attempting to list collections ---');
    console.log('Note: This may not work in web apps due to security rules');
    console.log('Check Firebase Console instead: https://console.firebase.google.com');
};

// Run all checks
(async () => {
    const userId = await checkUser();
    if (userId) {
        await checkSchedules(userId);

        // You need to provide your farmId here
        const farmId = 'YOUR_FARM_ID_HERE'; // Replace with actual farm ID
        await checkSensors(farmId);
    }
    await listAllCollections();

    console.log('\n=== DEBUG COMPLETE ===');
    console.log('If you see 0 results, check:');
    console.log('1. Collection names match exactly (case-sensitive)');
    console.log('2. userId field matches your logged-in user ID');
    console.log('3. farmId field matches your selected farm');
    console.log('4. Firestore security rules allow reading');
})();
