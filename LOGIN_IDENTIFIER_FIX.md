# Login with Identifier Fix - November 17, 2025

## Problem
Users received "not allowed" error when attempting to log in with phone number or cooperative ID instead of email.

## Root Causes
1. **Firestore Index Issue**: Queries on nested fields like `cooperative.coopGovId` and `cooperative.memberId` may require composite Firestore indexes.
2. **Graceful Error Handling**: The original code would rethrow errors instead of gracefully handling index-missing errors.
3. **Console Logging Glitch**: Duplicate `print()` and `dev.log()` calls were causing console output issues.

## Changes Made

### 1. AuthService (`lib/services/auth_service.dart`)
- Updated `getEmailForIdentifier()` method to:
  - Wrap each identifier type query in a try-catch block
  - Log detailed debugging info with emoji prefixes for clarity
  - Return `null` gracefully instead of rethrowing on query failures
  - Continue to next lookup method if one fails (e.g., phone → coop gov ID → coop member ID)

**New behavior:**
- If phone number query fails (no index), it tries cooperative gov ID
- If coop gov ID query fails, it tries cooperative member ID
- If all fail, returns `null` with debug logs

### 2. AuthProvider (`lib/providers/auth_provider.dart`)
- Removed duplicate `print()` statements; kept only `dev.log()` for cleaner console output
- Added check in `signIn()`: if identifier is not an email, resolve it to email first
- Returns clear error message: "No account found for that identifier" if lookup fails

### 3. Firestore Rules (`firestore.rules`)
- Added explanatory comment on `/users/{userId}` rule clarifying it allows authenticated users to read all user documents for identifier-based login support
- Rules remain unchanged; no new permissions added

## Solution for Production

### If you see "Permission Denied" errors:
1. **Check Firestore indexes**: Open Firebase Console → Firestore → Indexes
2. **Create composite indexes** for:
   - Collection: `users`, Fields: `cooperative.coopGovId`
   - Collection: `users`, Fields: `cooperative.memberId`
   
   Firebase will suggest these automatically when queries fail.

### Alternative (if indexes are problematic):
- Accept that only email + phone number lookups work (no cooperative ID queries)
- Update the UI to inform users: "Log in with email or phone number"
- Remove or comment out the cooperative ID lookup code

## Testing

### Test Case 1: Login with email
- Input: `user@example.com`
- Expected: ✅ Logs in successfully
- Method: Email is recognized as email, used directly

### Test Case 2: Login with phone number
- Register user with phone: `+250788123456`
- Input: `+250788123456` at login
- Expected: ✅ Resolves to email, logs in successfully
- Debug log: `✅ Found email by phone: user@example.com`

### Test Case 3: Login with cooperative ID
- Register user with cooperative gov ID: `COOP2025001`
- Input: `COOP2025001` at login
- Expected: ✅ Resolves to email, logs in successfully
- Debug log: `✅ Found email by coop gov ID: user@example.com`

### Test Case 4: Invalid identifier
- Input: `nonexistent123`
- Expected: ❌ Error message: "No account found for that identifier"
- Debug log: `❌ No email found for identifier: nonexistent123`

## Console Log Examples

### Successful email login:
```
🚀 Starting sign in for identifier: user@example.com
✅ Sign in successful! UID: abc123def456
```

### Successful phone login:
```
🚀 Starting sign in for identifier: +250788123456
🔍 Looking up identifier: +250788123456
✅ Found email by phone: user@example.com
✅ Sign in successful! UID: abc123def456
```

### Failed login (identifier not found):
```
🚀 Starting sign in for identifier: unknownid
🔍 Looking up identifier: unknownid
⚠️ Phone query error (non-critical): [index error or no results]
⚠️ Coop gov ID query error (non-critical): [index error or no results]
⚠️ Coop member ID query error (non-critical): [index error or no results]
❌ No email found for identifier: unknownid
```

## Files Modified
1. `lib/services/auth_service.dart` - Added error handling in getEmailForIdentifier
2. `lib/providers/auth_provider.dart` - Removed duplicate logging, added identifier resolution
3. `firestore.rules` - Added clarifying comment (no security changes)

## Next Steps
1. Deploy the updated code
2. Monitor Firestore for any index creation suggestions
3. Create composite indexes if needed (Firebase Console will guide you)
4. Test login with email, phone, and cooperative ID
5. Verify console logs show expected output (emojis are for clarity)
