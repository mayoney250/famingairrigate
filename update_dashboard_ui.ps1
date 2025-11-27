# Script to update dashboard UI to use live sensor data
# Run this from the project root: .\update_dashboard_ui.ps1

$file = "lib\screens\dashboard\dashboard_screen.dart"
$content = Get-Content $file -Raw

Write-Host "Updating dashboard_screen.dart UI components..." -ForegroundColor Cyan

# 1. Update _buildWeatherAndGauge method (line 383)
$oldWeatherGauge = 'final avg = dashboardProvider.avgSoilMoisture;'
$newWeatherGauge = @'
final liveSensor = dashboardProvider.liveSensorData;
    final avg = liveSensor?.soilMoisture;
    final isStale = liveSensor?.isStale ?? false;
'@

$content = $content -replace [regex]::Escape($oldWeatherGauge), $newWeatherGauge

Write-Host "Updated _buildWeatherAndGauge" -ForegroundColor Green

# 2. Update _buildFullWidthSoilCard method (line 473) - This is the HERO SECTION
$oldFullWidth = @'
  Widget _buildFullWidthSoilCard(DashboardProvider dashboardProvider) {
    final avg = dashboardProvider.avgSoilMoisture;
    final daily = dashboardProvider.dailyWaterUsage;
'@

$newFullWidth = @'
  Widget _buildFullWidthSoilCard(DashboardProvider dashboardProvider) {
    final liveSensor = dashboardProvider.liveSensorData;
    final avg = liveSensor?.soilMoisture;
    final isStale = liveSensor?.isStale ?? false;
    final stalenessMsg = liveSensor?.stalenessMessage ?? '';
    final daily = dashboardProvider.dailyWaterUsage;
'@

$content = $content -replace [regex]::Escape($oldFullWidth), $newFullWidth

Write-Host "Updated _buildFullWidthSoilCard (HERO SECTION)" -ForegroundColor Green

# 3. Add staleness warning to hero section - find the status container and add warning
$oldStatusContainer = @'
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Status: ${avg != null && avg < 40 ? "Dry" : (avg != null && avg > 80 ? "Wet" : "Optimal")}',
                  style: const TextStyle(
                    color: FamingaBrandColors.primaryOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
'@

$newStatusContainer = @'
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      liveSensor?.moistureStatusText ?? 
                      'Status: ${avg != null && avg < 40 ? "Dry" : (avg != null && avg > 80 ? "Wet" : "Optimal")}',
                      style: const TextStyle(
                        color: FamingaBrandColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isStale)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber, size: 14, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'Sensor offline: $stalenessMsg',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
'@

$content = $content -replace [regex]::Escape($oldStatusContainer), $newStatusContainer

Write-Host "Added staleness warning to hero section" -ForegroundColor Green

# 4. Update _buildSoilMoistureCard method (line 957)
$oldSoilCard = @'
  Widget _buildSoilMoistureCard(DashboardProvider dashboardProvider) {
    final avg = dashboardProvider.avgSoilMoisture;
'@

$newSoilCard = @'
  Widget _buildSoilMoistureCard(DashboardProvider dashboardProvider) {
    final liveSensor = dashboardProvider.liveSensorData;
    final avg = liveSensor?.soilMoisture;
'@

$content = $content -replace [regex]::Escape($oldSoilCard), $newSoilCard

Write-Host "Updated _buildSoilMoistureCard" -ForegroundColor Green

# 5. Update soil moisture label text to say "Current Field Moisture" instead of average
$oldLabel = "context.l10n.soilMoisture"
$newLabel = "'Current Field Moisture'"

# Only replace in specific contexts to avoid breaking other uses
$content = $content -replace "Text\(\s*context\.l10n\.soilMoisture,\s*style: const TextStyle\(color: FamingaBrandColors\.textSecondary, fontSize: 14\),\s*\)", @"
Text(
                'Current Field Moisture',
                style: const TextStyle(color: FamingaBrandColors.textSecondary, fontSize: 14),
              )
"@

Write-Host "Updated label to 'Current Field Moisture'" -ForegroundColor Green

# Save the file
$content | Set-Content $file -NoNewline

Write-Host ""
Write-Host "Dashboard UI updated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Changes made:" -ForegroundColor Yellow
Write-Host "1. Replaced avgSoilMoisture with liveSensorData.soilMoisture"
Write-Host "2. Added staleness detection (isStale check)"
Write-Host "3. Added staleness warning in hero section (red warning box)"
Write-Host "4. Updated label from 'Soil Moisture' to 'Current Field Moisture'"
Write-Host "5. Using moistureStatusText from Firestore when available"
Write-Host ""
Write-Host "Next: Hot reload the app to see changes!" -ForegroundColor Cyan
Write-Host ""
