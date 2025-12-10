$file = "lib\screens\sensors\sensors_screen.dart"
$content = Get-Content $file -Raw

# Add imports after line 12
$content = $content -replace "(import 'usb_sensor_screen\.dart'; // Import the new USB sensor screen\r?\n)", "`$1import 'package:cloud_firestore/cloud_firestore.dart';`nimport 'package:firebase_auth/firebase_auth.dart';`n"

# Replace the BLE MAC address field with dropdown
$oldBleField = @"
                            if \(pairingMethod == 'BLE'\)
                              TextFormField\(
                                decoration: InputDecoration\(
                                  labelText: context\.l10n\.bleMacAddress,
                                  border: OutlineInputBorder\(borderRadius: BorderRadius\.circular\(12\)\),
                                  filled: true,
                                  fillColor: scheme\.surfaceVariant\.withOpacity\(0\.3\),
                                  contentPadding: const EdgeInsets\.symmetric\(horizontal: 16, vertical: 16\),
                                \),
                                validator: \(v\) => pairingMethod == 'BLE' && \(v == null \|\| v\.isEmpty\) \? context\.l10n\.requiredField : null,
                                onChanged: \(v\) => bleMac = v,
                              \),
"@

$newBleField = @"
                            if (pairingMethod == 'BLE')
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('fields')
                                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  
                                  final fields = snapshot.data!.docs;
                                  
                                  if (fields.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: scheme.errorContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'No fields available. Please create a field first.',
                                        style: TextStyle(color: scheme.onErrorContainer),
                                      ),
                                    );
                                  }
                                  
                                  return DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Assign to Field',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: scheme.surfaceVariant.withOpacity(0.3),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                    value: bleMac.isEmpty ? null : bleMac,
                                    items: fields.map((field) {
                                      final data = field.data() as Map<String, dynamic>;
                                      final label = data['label'] ?? 'Unknown Field';
                                      return DropdownMenuItem(value: field.id, child: Text(label));
                                    }).toList(),
                                    validator: (v) => pairingMethod == 'BLE' && (v == null || v.isEmpty) ? 'Please select a field' : null,
                                    onChanged: (v) => setState(() => bleMac = v ?? ''),
                                  );
                                },
                              ),
"@

$content = $content -replace [regex]::Escape($oldBleField), $newBleField

Set-Content $file $content -NoNewline
Write-Host "File updated successfully!"
