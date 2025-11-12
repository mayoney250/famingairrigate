import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../models/forecast_day.dart';

class ForecastCard extends StatefulWidget {
  final List<ForecastDay> forecastDays;
  final bool isLoading;

  const ForecastCard({
    super.key,
    required this.forecastDays,
    this.isLoading = false,
  });

  @override
  State<ForecastCard> createState() => _ForecastCardState();
}

class _ForecastCardState extends State<ForecastCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.forecastDays.isEmpty) {
      return _buildEmptyState();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isExpanded = true),
      onExit: (_) => setState(() => _isExpanded = false),
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTodayForecast(),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded && widget.forecastDays.length > 1
                    ? Column(
                        children: [
                          const SizedBox(height: 12),
                          const Divider(
                            color: FamingaBrandColors.borderColor,
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          ...widget.forecastDays
                              .skip(1)
                              .take(4)
                              .map((day) => _buildForecastRow(day)),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.wb_sunny,
              color: FamingaBrandColors.primaryOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Weather Forecast',
              style: TextStyle(
                color: FamingaBrandColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (widget.forecastDays.length > 1)
          AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: FamingaBrandColors.textSecondary,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildTodayForecast() {
    if (widget.forecastDays.isEmpty) return const SizedBox.shrink();
    
    final today = widget.forecastDays.first;
    final weatherIcon = _getWeatherIcon(today.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FamingaBrandColors.primaryOrange.withOpacity(0.1),
            FamingaBrandColors.primaryOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            weatherIcon,
            color: FamingaBrandColors.primaryOrange,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  today.dayName,
                  style: const TextStyle(
                    color: FamingaBrandColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  today.status,
                  style: const TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.thermostat,
                      size: 16,
                      color: FamingaBrandColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${today.tempMaxString} / ${today.tempMinString}',
                      style: const TextStyle(
                        color: FamingaBrandColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.water_drop_outlined,
                      size: 14,
                      color: FamingaBrandColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      today.humidityString,
                      style: const TextStyle(
                        color: FamingaBrandColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow(ForecastDay day) {
    final weatherIcon = _getWeatherIcon(day.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: FamingaBrandColors.borderColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              day.dayName,
              style: const TextStyle(
                color: FamingaBrandColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            weatherIcon,
            color: FamingaBrandColors.primaryOrange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              day.status,
              style: const TextStyle(
                color: FamingaBrandColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Icon(
                Icons.thermostat,
                size: 14,
                color: FamingaBrandColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${day.tempMaxString}/${day.tempMinString}',
                style: const TextStyle(
                  color: FamingaBrandColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: FamingaBrandColors.primaryOrange,
              strokeWidth: 2,
            ),
            SizedBox(height: 12),
            Text(
              'Loading weather...',
              style: TextStyle(
                color: FamingaBrandColors.textSecondary,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              color: FamingaBrandColors.textSecondary,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'No weather data available',
              style: TextStyle(
                color: FamingaBrandColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String status) {
    switch (status.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
  }
}
