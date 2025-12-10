# Read the file
$content = Get-Content "lib\screens\sensors\sensors_screen.dart" -Raw

# Find and replace the three conditional fields with the universal field dropdown
$oldPattern = @'
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
                            if \(pairingMethod == 'WiFi'\)
                              TextFormField\(
                                decoration: InputDecoration\(
                                  labelText: context\.l10n\.wifiSsid,
                                  border: OutlineInputBorder\(borderRadius: BorderRadius\.circular\(12\)\),
                                  filled: true,
                                  fillColor: scheme\.surfaceVariant\.withOpacity\(0\.3\),
                                  contentPadding: const EdgeInsets\.symmetric\(horizontal: 16, vertical: 16\),
                                \),
                                validator: \(v\) => pairingMethod == 'WiFi' && \(v == null \|\| v\.isEmpty\) \? context\.l10n\.requiredField : null,
                                onChanged: \(v\) => wifiSsid = v,
                              \),
                            if \(pairingMethod == 'LoRaWAN'\)
                              TextFormField\(
                                decoration: InputDecoration\(
                                  labelText: context\.l10n\.gatewayIdName,
                                  border: OutlineInputBorder\(borderRadius: BorderRadius\.circular\(12\)\),
                                  filled: true,
                                  fillColor: scheme\.surfaceVariant\.withOpacity\(0\.3\),
                                  contentPadding: const EdgeInsets\.symmetric\(horizontal: 16, vertical: 16\),
                                \),
                                validator: \(v\) => pairingMethod == 'LoRaWAN' && \(v == null \|\| v\.isEmpty\) \? context\.l10n\.requiredField : null,
                                onChanged: \(v\) => loraGateway = v,
                              \),
'@

$newContent = @'
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
                                    return DropdownMenuItem(
                                      value: field.id,
                                      child: Text(label),
                                    );
                                  }).toList(),
                                  validator: (v) => v == null || v.isEmpty 
                                      ? 'Please select a field' 
                                      : null,
                                  onChanged: (v) => setState(() => bleMac = v ?? ''),
                                );
                              },
                            ),
'@

$content = $content -replace $oldPattern, $newContent

Set-Content "lib\screens\sensors\sensors_screen.dart" $content -NoNewline
Write-Host "Successfully replaced conditional fields with universal field dropdown!"
