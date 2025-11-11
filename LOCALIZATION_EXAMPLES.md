# Localization Examples - Before & After

## Example 1: Login Screen

### ❌ BEFORE (Hardcoded Strings)
```dart
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Sign in to manage your irrigation systems'),
            SizedBox(height: 32),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text('Forgot Password?'),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? "),
                TextButton(
                  onPressed: () {},
                  child: Text('Register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### ✅ AFTER (Fully Localized)
```dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              l10n.welcomeBack,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(l10n.signInToManage),
            SizedBox(height: 32),
            TextField(
              decoration: InputDecoration(
                labelText: l10n.email,
                hintText: l10n.enterEmail,
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.password,
                hintText: l10n.enterPassword,
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(l10n.forgotPassword),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: Text(l10n.login),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.dontHaveAccount),
                TextButton(
                  onPressed: () {},
                  child: Text(l10n.register),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Example 2: Settings Screen with Language Switcher

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../widgets/language_switcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        actions: const [
          LanguageSwitcher(
            showLabel: false,
            isCompact: true,
          ),
        ],
      ),
      body: ListView(
        children: [
          // Language Selection Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(languageProvider.currentLanguageName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              LanguageSwitcherDialog.show(context);
            },
          ),
          const Divider(),
          
          // Other Settings
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(l10n.notifications),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(l10n.profile),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
```

---

## Example 3: Dashboard with Dynamic Content

```dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: const [
          LanguageSwitcher(
            showLabel: false,
            isCompact: true,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            Text(
              l10n.welcomeUser,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.sensors,
                    title: l10n.activeSensors,
                    value: '12',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    icon: Icons.agriculture,
                    title: l10n.totalFields,
                    value: '5',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.water_drop,
                    title: l10n.waterSaved,
                    value: '1,234 L',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    icon: Icons.wb_sunny,
                    title: l10n.activeSystems,
                    value: '8',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              l10n.quickActions,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: Text(l10n.addSystem),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Example 4: Dialog with Localized Messages

```dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

void showNoFieldsDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.noFieldsTitle),
      content: Text(l10n.noFieldsMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to add field screen
          },
          child: Text(l10n.startNow),
        ),
      ],
    ),
  );
}

void showSuccessSnackbar(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.accountCreatedSuccess),
      action: SnackBarAction(
        label: l10n.ok,
        onPressed: () {},
      ),
    ),
  );
}
```

---

## Example 5: Form with Validation

```dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.firstName,
              hintText: l10n.enterFirstName,
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.enterFirstName;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.lastName,
              hintText: l10n.enterLastName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.enterLastName;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.email,
              hintText: l10n.enterEmail,
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.enterEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.password,
              hintText: l10n.enterPassword,
              prefixIcon: const Icon(Icons.lock),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.enterPassword;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.confirmPassword,
              hintText: l10n.reEnterPassword,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.reEnterPassword;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Process registration
              }
            },
            child: Text(l10n.register),
          ),
        ],
      ),
    );
  }
}
```

---

## Example 6: AppBar with Language Switcher

### Compact Version (Icon Only)
```dart
AppBar(
  title: Text(l10n.settings),
  actions: const [
    LanguageSwitcher(
      showLabel: false,
      isCompact: true,
    ),
    SizedBox(width: 8),
  ],
)
```

### Full Version (With Dropdown)
```dart
AppBar(
  title: Text(l10n.settings),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(80),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: const LanguageSwitcher(
        showLabel: true,
        isCompact: false,
      ),
    ),
  ),
)
```

---

## Example 7: List with Localized Items

```dart
ListView(
  children: [
    ListTile(
      leading: const Icon(Icons.dashboard),
      title: Text(l10n.dashboard),
      onTap: () {},
    ),
    ListTile(
      leading: const Icon(Icons.water),
      title: Text(l10n.irrigation),
      onTap: () {},
    ),
    ListTile(
      leading: const Icon(Icons.agriculture),
      title: Text(l10n.fields),
      onTap: () {},
    ),
    ListTile(
      leading: const Icon(Icons.sensors),
      title: Text(l10n.sensors),
      onTap: () {},
    ),
    ListTile(
      leading: const Icon(Icons.person),
      title: Text(l10n.profile),
      onTap: () {},
    ),
    ListTile(
      leading: const Icon(Icons.settings),
      title: Text(l10n.settings),
      onTap: () {},
    ),
  ],
)
```

---

## Quick Reference: Common Replacements

| Hardcoded String | Localized Version |
|-----------------|-------------------|
| `'Dashboard'` | `l10n.dashboard` |
| `'Login'` | `l10n.login` |
| `'Register'` | `l10n.register` |
| `'Email'` | `l10n.email` |
| `'Password'` | `l10n.password` |
| `'Save'` | `l10n.save` |
| `'Cancel'` | `l10n.cancel` |
| `'Delete'` | `l10n.delete` |
| `'Update'` | `l10n.update` |
| `'Settings'` | `l10n.settings` |
| `'Profile'` | `l10n.profile` |
| `'Notifications'` | `l10n.notifications` |
| `'Loading...'` | `l10n.loading` |
| `'Error'` | `l10n.error` |
| `'Success'` | `l10n.success` |

Remember: Import `AppLocalizations` and get the instance with `AppLocalizations.of(context)!` at the start of your build method!
