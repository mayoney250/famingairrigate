# Deploy Firestore Indexes - Instructions

## ⚠️ IMPORTANT: Deploy Indexes to Fix Reports Page

The Reports page requires a composite Firestore index to query irrigation logs efficiently.

### Quick Deploy (Recommended)

Run this command in your terminal from the project root:

```bash
firebase deploy --only firestore:indexes
```

### What This Does

This command will:
1. Read the `firestore.indexes.json` file
2. Create the required composite index for `irrigationLogs` collection
3. Enable efficient querying by `userId` and `timestamp` range

### Index Details

The new index allows queries like:
- Filter by `userId`
- Range filter on `timestamp` (between start and end dates)
- Order by `timestamp` descending

### After Deployment

1. **Wait 2-5 minutes** for the index to build (Firebase will show build progress)
2. **Hot restart** your Flutter app
3. Navigate to Settings → Reports
4. The reports should now load without errors

### If You Still See Errors

The Reports page has a **fallback mechanism**:
- If the index isn't ready, it will fetch all user logs and filter in-memory
- This is slower but ensures the app still works
- Once the index is ready, queries will be fast

### Verify Index Creation

1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: `famingairrigation`
3. Navigate to **Firestore Database** → **Indexes** tab
4. Look for: `irrigationLogs` collection with `userId` and `timestamp` fields
5. Status should show "Enabled" (may take a few minutes)

### Manual Index Creation (Alternative)

If the command fails, you can create the index manually:

1. When you see the error in your app, it includes a clickable link
2. Click the link in the error message
3. It will open Firebase Console and auto-fill the index configuration
4. Click "Create Index"
5. Wait for it to build

### Troubleshooting

**Command not found: firebase**
```bash
npm install -g firebase-tools
firebase login
```

**Permission denied**
```bash
firebase login
```
Make sure you're logged in with an account that has access to the project.

**Index already exists**
This is fine! The index might have been created automatically from the error link.

---

## Summary

The Reports page is now fully designed and integrated. Just deploy the indexes and it will work perfectly with real data from your database.
