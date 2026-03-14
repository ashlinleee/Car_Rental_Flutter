// home_screen.dart — Main discovery screen for browsing and searching rental cars.
//
// Responsibilities:
//   - Captures trip context (state, place, pickup/drop spots, date/time)
//   - Calls ApiService to load categories and cars (with server-side filtering)
//   - Applies additional client-side sorting/filtering for offline consistency
//   - Renders car results and opens details with the selected trip context

import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/car_card.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ── State/place + nearby pickup/drop spots ──────────────────────────────
const Map<String, List<String>> _kStateToPlaces = {
  'Maharashtra': ['Mumbai', 'Pune', 'Nagpur'],
  'Karnataka': ['Bangalore', 'Mysore', 'Mangalore'],
  'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai'],
  'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad'],
  'Delhi': ['New Delhi', 'Dwarka', 'Rohini'],
};

const Map<String, List<String>> _kNearbyPickupSpots = {
  'Maharashtra|Mumbai': ['Andheri Station', 'Bandra Terminus', 'Mumbai Airport T2'],
  'Maharashtra|Pune': ['Shivajinagar', 'Pune Junction', 'Pune Airport'],
  'Maharashtra|Nagpur': ['Sitabuldi', 'Nagpur Junction', 'Nagpur Airport'],
  'Karnataka|Bangalore': ['Indiranagar', 'Majestic', 'Kempegowda Airport'],
  'Karnataka|Mysore': ['Mysore Palace Gate', 'Mysore Junction', 'KC Layout'],
  'Karnataka|Mangalore': ['Mangalore Central', 'Lalbagh Circle', 'Mangalore Airport'],
  'Tamil Nadu|Chennai': ['T Nagar', 'Chennai Central', 'Chennai Airport'],
  'Tamil Nadu|Coimbatore': ['Gandhipuram', 'Coimbatore Junction', 'Coimbatore Airport'],
  'Tamil Nadu|Madurai': ['Periyar Bus Stand', 'Madurai Junction', 'Madurai Airport'],
  'Telangana|Hyderabad': ['Hitech City', 'Secunderabad', 'RGIA Airport'],
  'Telangana|Warangal': ['Hanamkonda', 'Warangal Station', 'Kazipet'],
  'Telangana|Nizamabad': ['Phulong', 'Nizamabad Station', 'Bodhan Circle'],
  'Delhi|New Delhi': ['Connaught Place', 'New Delhi Station', 'IGI Airport T3'],
  'Delhi|Dwarka': ['Dwarka Sector 21', 'Dwarka Mor', 'IGI Airport T1'],
  'Delhi|Rohini': ['Rohini East', 'Rithala', 'Pitampura'],
};

const Map<String, List<String>> _kNearbyDropSpots = {
  'Maharashtra|Mumbai': ['Lower Parel', 'Dadar West', 'Navi Mumbai Vashi'],
  'Maharashtra|Pune': ['Kothrud', 'Hinjewadi', 'Viman Nagar'],
  'Maharashtra|Nagpur': ['Dharampeth', 'Sadar', 'MIHAN'],
  'Karnataka|Bangalore': ['Whitefield', 'Koramangala', 'Jayanagar'],
  'Karnataka|Mysore': ['VV Mohalla', 'Kuvempunagar', 'Nazarbad'],
  'Karnataka|Mangalore': ['Bejai', 'Surathkal', 'Pumpwell'],
  'Tamil Nadu|Chennai': ['OMR Perungudi', 'Anna Nagar', 'Tambaram'],
  'Tamil Nadu|Coimbatore': ['RS Puram', 'Peelamedu', 'Saravanampatti'],
  'Tamil Nadu|Madurai': ['KK Nagar', 'Anna Nagar', 'Thiruparankundram'],
  'Telangana|Hyderabad': ['Banjara Hills', 'Gachibowli', 'Kukatpally'],
  'Telangana|Warangal': ['Subedari', 'Nakkalagutta', 'Enumamula'],
  'Telangana|Nizamabad': ['Arsapally', 'Vinayak Nagar', 'Sai Nagar'],
  'Delhi|New Delhi': ['Karol Bagh', 'South Extension', 'Vasant Kunj'],
  'Delhi|Dwarka': ['Sector 10', 'Janakpuri', 'Uttam Nagar'],
  'Delhi|Rohini': ['Sector 3', 'Shalimar Bagh', 'Model Town'],
};

class _HomeScreenState extends State<HomeScreen> {
  List<Car> _cars = [];
  List<String> _categories = ['All'];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _isBackendConnected = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showCollapsedTitle = false;

  // ── Search form state ────────────────────────────────────
  String _selectedLocation = '';
  String _selectedState = '';
  String _selectedPlace = '';
  String _selectedPickupSpot = '';
  String _selectedDropoffSpot = '';
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _dropoffDate;
  TimeOfDay? _dropoffTime;
  bool _hasSearched = false;

  // ── Filter/Sort state ────────────────────────────────────
  String _sortBy = 'default';        // 'default' | 'price_asc' | 'price_desc' | 'rating_desc' | 'name_asc'
  double _minPrice = 0;
  double _maxPrice = 20000;
  bool? _availableOnly;              // null = all, true = available only
  String? _selectedFuelType;         // null = all
  String? _selectedTransmission;     // null = all
  int? _minSeats;                    // null = any

  // Pending values shown in bottom sheet before Apply
  String _pendingSortBy = 'default';
  double _pendingMinPrice = 0;
  double _pendingMaxPrice = 20000;
  bool? _pendingAvailableOnly;
  String? _pendingFuelType;
  String? _pendingTransmission;
  int? _pendingMinSeats;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleHeaderTitleOnScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleHeaderTitleOnScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleHeaderTitleOnScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow = _scrollController.offset > 80;
    if (shouldShow != _showCollapsedTitle && mounted) {
      setState(() => _showCollapsedTitle = shouldShow);
    }
  }

  // ── Search form helpers ──────────────────────────────────
  String _fmt(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}'; 
  String _dateParam(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  bool get _canSearch =>
      _selectedState.isNotEmpty &&
      _selectedPlace.isNotEmpty &&
      _selectedPickupSpot.isNotEmpty &&
      _selectedDropoffSpot.isNotEmpty &&
      _pickupDate != null &&
      _pickupTime != null &&
      _dropoffDate != null &&
      _dropoffTime != null;

  void _clearSearch() {
    setState(() {
      _hasSearched = false;
      _selectedLocation = '';
      _selectedState = '';
      _selectedPlace = '';
      _selectedPickupSpot = '';
      _selectedDropoffSpot = '';
      _pickupDate = null;
      _pickupTime = null;
      _dropoffDate = null;
      _dropoffTime = null;
    });
    _loadData();
  }

  Future<void> _pickDate(bool isPickup) async {
    final now = DateTime.now();
    final initial = isPickup
        ? (_pickupDate ?? now)
        : (_dropoffDate ?? (_pickupDate ?? now).add(const Duration(days: 1)));
    final first = isPickup ? now : (_pickupDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2E7D32),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          // reset dropoff if it's before new pickup
          if (_dropoffDate != null && !_dropoffDate!.isAfter(picked)) {
            _dropoffDate = null;
          }
        } else {
          _dropoffDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isPickup) async {
    final initial = isPickup
        ? (_pickupTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_dropoffTime ?? const TimeOfDay(hour: 9, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2E7D32),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isPickup) { _pickupTime = picked; }
        else { _dropoffTime = picked; }
      });
    }
  }

  bool get _hasActiveFilters =>
      _availableOnly != null ||
      _minPrice > 0 ||
      _maxPrice < 20000 ||
      _sortBy != 'default' ||
      _selectedFuelType != null ||
      _selectedTransmission != null ||
      _minSeats != null;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Run all data calls in parallel to keep initial load and refresh snappy.
    final results = await Future.wait([
      ApiService.isBackendAvailable(),
      ApiService.getCars(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        available: _hasSearched ? null : _availableOnly,
        sortBy: _sortBy == 'default' ? null : _sortBy,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 20000 ? _maxPrice : null,
        pickupDate:  _hasSearched && _pickupDate != null  ? _dateParam(_pickupDate!)  : null,
        pickupTime:  _hasSearched && _pickupTime != null  ? _fmtTime(_pickupTime!)   : null,
        dropoffDate: _hasSearched && _dropoffDate != null ? _dateParam(_dropoffDate!) : null,
        dropoffTime: _hasSearched && _dropoffTime != null ? _fmtTime(_dropoffTime!)  : null,
        state: _selectedState.isNotEmpty ? _selectedState : null,
        place: _selectedPlace.isNotEmpty ? _selectedPlace : null,
      ),
      ApiService.getCategories(),
    ]);

    if (mounted) {
      final backendAvailable = results[0] as bool;
      var cars = results[1] as List<Car>;
      final fetchedCategories = results[2] as List<String>;

      // Apply sort + filters client-side (ensures they work even when offline)
      cars = _applySortAndFilter(cars);

      setState(() {
        _cars = cars;
        _isBackendConnected = backendAvailable;
        _categories = ['All', ...fetchedCategories.where((c) => c != 'All')];
        _isLoading = false;
      });
    }
  }

  List<Car> _applySortAndFilter(List<Car> cars) {
    // Apply search locally (needed for offline fallback)
    var result = cars.where((car) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!car.name.toLowerCase().contains(q) &&
            !car.brand.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_selectedCategory != 'All' && car.category != _selectedCategory) {
        return false;
      }
      if (_availableOnly == true && !car.isAvailable) return false;
      if (_minPrice > 0 && car.pricePerDay < _minPrice) return false;
      if (_maxPrice < 20000 && car.pricePerDay > _maxPrice) return false;
      if (_selectedFuelType != null && car.fuelType != _selectedFuelType) return false;
      if (_selectedTransmission != null && car.transmission != _selectedTransmission) return false;
      if (_minSeats != null && car.seats < _minSeats!) return false;
      // Offline fallback: when date searched, only show isAvailable cars
      if (_hasSearched && !car.isAvailable) return false;
      return true;
    }).toList();

    // Apply sort
    switch (_sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
      case 'price_desc':
        result.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
      case 'rating_desc':
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case 'name_asc':
        result.sort((a, b) => a.name.compareTo(b.name));
    }

    return result;
  }

  void _openFilterSheet() {
    // Seed pending state with current values before opening
    _pendingSortBy = _sortBy;
    _pendingMinPrice = _minPrice;
    _pendingMaxPrice = _maxPrice;
    _pendingAvailableOnly = _availableOnly;
    _pendingFuelType = _selectedFuelType;
    _pendingTransmission = _selectedTransmission;
    _pendingMinSeats = _minSeats;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialSortBy: _pendingSortBy,
        initialMinPrice: _pendingMinPrice,
        initialMaxPrice: _pendingMaxPrice,
        initialAvailableOnly: _pendingAvailableOnly,
        initialFuelType: _pendingFuelType,
        initialTransmission: _pendingTransmission,
        initialMinSeats: _pendingMinSeats,
        onApply: (sortBy, minPrice, maxPrice, availableOnly, fuelType, transmission, minSeats) {
          setState(() {
            _sortBy = sortBy;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _availableOnly = availableOnly;
            _selectedFuelType = fuelType;
            _selectedTransmission = transmission;
            _minSeats = minSeats;
          });
          _loadData();
        },
        onReset: () {
          setState(() {
            _sortBy = 'default';
            _minPrice = 0;
            _maxPrice = 20000;
            _selectedFuelType = null;
            _selectedTransmission = null;
            _minSeats = null;
          });
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.green,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Sliver AppBar with gradient header ──
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              centerTitle: false,
              titleSpacing: 16,
              title: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  opacity: _showCollapsedTitle ? 1 : 0,
                  child: const Text(
                    'BRUMM',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    AuthService().isLoggedIn ? Icons.account_circle : Icons.person_outline,
                    color: Colors.white,
                  ),
                  tooltip: AuthService().isLoggedIn ? 'My Account' : 'Sign In',
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AuthService().isLoggedIn ? '/profile' : '/login',
                    );
                    if (result == true) setState(() {});
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Brumm',
                                    style: TextStyle(color: Colors.white70, fontSize: 15),
                                  ),
                                  Text(
                                    'Drive more. Worry less.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              _buildConnectionBadge(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Search form card ──
            SliverToBoxAdapter(child: _buildSearchForm()),

            // ── Active search banner ──
            if (_hasSearched)
              SliverToBoxAdapter(child: _buildActivSearchBanner()),

            // ── Text search bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildSearchBar(),
              ),
            ),

            // ── Category chips ──
            SliverToBoxAdapter(child: _buildCategoryChips()),

            // ── Results count + sort/filter bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isLoading
                          ? 'Loading vehicles...'
                          : '${_cars.length} vehicle${_cars.length != 1 ? 's' : ''} found',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        // Sort dropdown
                        _buildSortButton(),
                        const SizedBox(width: 8),
                        // Filter button
                        _buildFilterButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Loading / Empty / Grid ──
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => _buildShimmerCard(),
                    childCount: 6,
                  ),
                ),
              )
            else if (_cars.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => CarCard(
                      car: _cars[index],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/car_details',
                        arguments: {
                          'car': _cars[index],
                          'selectedState': _selectedState,
                          'selectedPlace': _selectedPlace,
                          'pickupSpot': _selectedPickupSpot,
                          'dropoffSpot': _selectedDropoffSpot,
                          'pickupDate': _pickupDate,
                          'pickupTime': _pickupTime,
                          'dropoffDate': _dropoffDate,
                          'dropoffTime': _dropoffTime,
                        },
                      ),
                    ),
                    childCount: _cars.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    final sortLabels = {
      'default': 'Default',
      'price_asc': 'Price ↑',
      'price_desc': 'Price ↓',
      'rating_desc': 'Top Rated',
      'name_asc': 'Name A-Z',
    };
    final isActive = _sortBy != 'default';

    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() => _sortBy = value);
        _loadData();
      },
      itemBuilder: (_) => sortLabels.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    Icon(
                      _sortBy == e.key ? Icons.check : Icons.sort,
                      size: 16,
                      color: _sortBy == e.key ? Colors.green[700] : Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Text(e.value,
                        style: TextStyle(
                          color: _sortBy == e.key ? Colors.green[700] : null,
                          fontWeight: _sortBy == e.key ? FontWeight.bold : null,
                        )),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[700] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? Colors.green[700]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.sort, size: 14, color: isActive ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              sortLabels[_sortBy] ?? 'Sort',
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down,
                size: 16, color: isActive ? Colors.white : Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return InkWell(
      onTap: _openFilterSheet,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _hasActiveFilters ? Colors.orange[700] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _hasActiveFilters ? Colors.orange[700]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              _hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              size: 14,
              color: _hasActiveFilters ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Filter',
              style: TextStyle(
                fontSize: 12,
                color: _hasActiveFilters ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _activeFilterCount.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_sortBy != 'default') count++;
    if (_availableOnly != null) count++;
    if (_minPrice > 0 || _maxPrice < 20000) count++;
    if (_selectedFuelType != null) count++;
    if (_selectedTransmission != null) count++;
    if (_minSeats != null) count++;
    return count;
  }

  Widget _buildConnectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _isBackendConnected
            ? Colors.green.withValues(alpha: 0.25)
            : Colors.orange.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isBackendConnected ? Colors.greenAccent : Colors.orangeAccent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isBackendConnected ? Icons.cloud_done : Icons.cloud_off,
            color: _isBackendConnected ? Colors.greenAccent : Colors.orangeAccent,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _isBackendConnected ? 'Live' : 'Offline',
            style: TextStyle(
              color: _isBackendConnected ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // \u2500\u2500 Location + date/time search form \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  Widget _buildSearchForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // \u2500 Location \u2500
            _formLabel(Icons.location_on_outlined, 'Location Details'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _selectorTile(
                    label: _selectedState.isNotEmpty ? _selectedState : 'Select state',
                    icon: Icons.map_outlined,
                    selected: _selectedState.isNotEmpty,
                    onTap: _showStatePicker,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _selectorTile(
                    label: _selectedPlace.isNotEmpty ? _selectedPlace : 'Select place',
                    icon: Icons.location_city,
                    selected: _selectedPlace.isNotEmpty,
                    onTap: _selectedState.isNotEmpty ? _showPlacePicker : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _selectorTile(
                    label: _selectedPickupSpot.isNotEmpty ? _selectedPickupSpot : 'Pickup spot',
                    icon: Icons.my_location_outlined,
                    selected: _selectedPickupSpot.isNotEmpty,
                    onTap: _selectedPlace.isNotEmpty ? () => _showSpotPicker(true) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _selectorTile(
                    label: _selectedDropoffSpot.isNotEmpty ? _selectedDropoffSpot : 'Drop spot',
                    icon: Icons.place_outlined,
                    selected: _selectedDropoffSpot.isNotEmpty,
                    onTap: _selectedPlace.isNotEmpty ? () => _showSpotPicker(false) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // \u2500 Pickup date + time \u2500
            _formLabel(Icons.directions_car_outlined, 'Pick-up Date & Time'),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: _dateTile(
                  _pickupDate != null ? _fmt(_pickupDate!) : 'Select date',
                  Icons.calendar_today_outlined,
                  _pickupDate != null,
                  () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTile(
                  _pickupTime != null ? _fmtTime(_pickupTime!) : 'Select time',
                  Icons.access_time_outlined,
                  _pickupTime != null,
                  () => _pickTime(true),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // \u2500 Dropoff date + time \u2500
            _formLabel(Icons.flag_outlined, 'Drop-off Date & Time'),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: _dateTile(
                  _dropoffDate != null ? _fmt(_dropoffDate!) : 'Select date',
                  Icons.calendar_today_outlined,
                  _dropoffDate != null,
                  () => _pickDate(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTile(
                  _dropoffTime != null ? _fmtTime(_dropoffTime!) : 'Select time',
                  Icons.access_time_outlined,
                  _dropoffTime != null,
                  () => _pickTime(false),
                ),
              ),
            ]),
            const SizedBox(height: 18),

            // \u2500 Search button \u2500
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _canSearch
                    ? () {
                        setState(() => _hasSearched = true);
                        _loadData();
                      }
                    : null,
                icon: const Icon(Icons.search, size: 20),
                label: const Text(
                  'Search Available Cars',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  disabledForegroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formLabel(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
              letterSpacing: 0.3,
            ),
          ),
        ],
      );

  Widget _dateTile(String label, IconData icon, bool filled, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: filled ? const Color(0xFF2E7D32) : Colors.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: filled ? Colors.black87 : Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _selectorTile({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: selected ? const Color(0xFF2E7D32) : Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected
                        ? Colors.black87
                        : onTap == null
                            ? Colors.grey[400]
                            : Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: onTap == null ? Colors.grey[300] : Colors.grey[400],
              ),
            ],
          ),
        ),
      );

  String _placeKey() => '$_selectedState|$_selectedPlace';

  List<String> _dropOptionsForPlace() {
    final key = _placeKey();
    final pickupCluster = _kNearbyPickupSpots[key] ?? const <String>[];
    final configured = _kNearbyDropSpots[key] ?? const <String>[];
    final base = pickupCluster.isNotEmpty ? pickupCluster : configured;

    if (_selectedPickupSpot.isEmpty) return base;

    final options = <String>[_selectedPickupSpot];
    for (final item in base) {
      if (item != _selectedPickupSpot) options.add(item);
    }
    return options;
  }

  void _showStatePicker() {
    final states = _kStateToPlaces.keys.toList()..sort();
    _showOptionPicker(
      title: 'Select State',
      options: states,
      selectedValue: _selectedState,
      onSelect: (state) {
        setState(() {
          _selectedState = state;
          _selectedPlace = '';
          _selectedPickupSpot = '';
          _selectedDropoffSpot = '';
          _selectedLocation = '';
        });
      },
    );
  }

  void _showPlacePicker() {
    final places = _kStateToPlaces[_selectedState] ?? [];
    _showOptionPicker(
      title: 'Select Place in $_selectedState',
      options: places,
      selectedValue: _selectedPlace,
      onSelect: (place) {
        setState(() {
          _selectedPlace = place;
          _selectedPickupSpot = '';
          _selectedDropoffSpot = '';
          _selectedLocation = '$_selectedPlace, $_selectedState';
        });
      },
    );
  }

  void _showSpotPicker(bool isPickup) {
    final key = _placeKey();
    final options = isPickup
        ? (_kNearbyPickupSpots[key] ?? const <String>[])
        : _dropOptionsForPlace();
    if (options.isEmpty) return;

    _showOptionPicker(
      title: isPickup ? 'Nearby Pickup Spots' : 'Nearby Drop Spots',
      options: options,
      selectedValue: isPickup ? _selectedPickupSpot : _selectedDropoffSpot,
      onSelect: (spot) {
        setState(() {
          if (isPickup) {
            _selectedPickupSpot = spot;
            final allowedDrop = _dropOptionsForPlace();
            if (_selectedDropoffSpot.isNotEmpty && !allowedDrop.contains(_selectedDropoffSpot)) {
              _selectedDropoffSpot = '';
            }
          } else {
            _selectedDropoffSpot = spot;
          }
        });
      },
    );
  }

  void _showOptionPicker({
    required String title,
    required List<String> options,
    required String selectedValue,
    required void Function(String value) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final value = options[i];
                final selected = value == selectedValue;
                return ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: selected ? const Color(0xFF2E7D32) : Colors.grey,
                    size: 20,
                  ),
                  title: Text(
                    value,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? const Color(0xFF2E7D32) : Colors.black87,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xFF2E7D32), size: 18)
                      : null,
                  onTap: () {
                    onSelect(value);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActivSearchBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_selectedLocation  \u2022  Pickup: $_selectedPickupSpot  \u2022  Drop: $_selectedDropoffSpot  \u2022  ${_pickupDate != null ? _fmt(_pickupDate!) : ''} ${_pickupTime != null ? _fmtTime(_pickupTime!) : ''}  \u2192  ${_dropoffDate != null ? _fmt(_dropoffDate!) : ''} ${_dropoffTime != null ? _fmtTime(_dropoffTime!) : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _clearSearch,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close, size: 16, color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search by car name or brand...',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _loadData();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _loadData();
      },
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedCategory = category);
                  _loadData();
                },
                selectedColor: Colors.green[700],
                backgroundColor: Colors.grey[100],
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, color: Colors.grey[200], width: double.infinity),
                  const SizedBox(height: 6),
                  Container(height: 10, color: Colors.grey[200], width: 80),
                  const Spacer(),
                  Container(height: 14, color: Colors.grey[200], width: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Cars Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
                _sortBy = 'default';
                _minPrice = 0;
                _maxPrice = 15000;
                _availableOnly = null;
              });
              _loadData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter/Sort Bottom Sheet ──────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final String initialSortBy;
  final double initialMinPrice;
  final double initialMaxPrice;
  final bool? initialAvailableOnly;
  final String? initialFuelType;
  final String? initialTransmission;
  final int? initialMinSeats;
  final void Function(
    String sortBy,
    double minPrice,
    double maxPrice,
    bool? availableOnly,
    String? fuelType,
    String? transmission,
    int? minSeats,
  ) onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.initialSortBy,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialAvailableOnly,
    required this.initialFuelType,
    required this.initialTransmission,
    required this.initialMinSeats,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sortBy;
  late RangeValues _priceRange;
  late bool? _availableOnly;
  String? _fuelType;
  String? _transmission;
  int? _minSeats;

  static const double _minBound = 0;
  static const double _maxBound = 20000;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy;
    _priceRange = RangeValues(widget.initialMinPrice, widget.initialMaxPrice);
    _availableOnly = widget.initialAvailableOnly;
    _fuelType = widget.initialFuelType;
    _transmission = widget.initialTransmission;
    _minSeats = widget.initialMinSeats;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onReset();
                    },
                    child: const Text('Reset All', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            // Content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Sort options
                  const Text(
                    'Sort By',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: {
                      'default': 'Default',
                      'price_asc': 'Price: Low → High',
                      'price_desc': 'Price: High → Low',
                      'rating_desc': 'Top Rated',
                      'name_asc': 'Name A–Z',
                    }.entries.map((e) {
                      final isSelected = _sortBy == e.key;
                      return GestureDetector(
                        onTap: () => setState(() => _sortBy = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green[700] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.green[700]! : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            e.value,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Price range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Price Range',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${_priceRange.start.toInt()} – ₹${_priceRange.end.toInt()}/day',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RangeSlider(
                    values: _priceRange,
                    min: _minBound,
                    max: _maxBound,
                    divisions: 30,
                    activeColor: Colors.green[700],
                    inactiveColor: Colors.grey[200],
                    labels: RangeLabels(
                      '₹${_priceRange.start.toInt()}',
                      '₹${_priceRange.end.toInt()}',
                    ),
                    onChanged: (values) => setState(() => _priceRange = values),
                  ),
                  const SizedBox(height: 24),

                  // ── Fuel Type ─────────────────────────────
                  const Text(
                    'Fuel Type',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _labelChip('Any', _fuelType == null, () => setState(() => _fuelType = null)),
                      _labelChip('Petrol', _fuelType == 'Petrol', () => setState(() => _fuelType = _fuelType == 'Petrol' ? null : 'Petrol')),
                      _labelChip('Diesel', _fuelType == 'Diesel', () => setState(() => _fuelType = _fuelType == 'Diesel' ? null : 'Diesel')),
                      _labelChip('Electric', _fuelType == 'Electric', () => setState(() => _fuelType = _fuelType == 'Electric' ? null : 'Electric')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Transmission ──────────────────────────
                  const Text(
                    'Transmission',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _labelChip('Any', _transmission == null, () => setState(() => _transmission = null)),
                      _labelChip('Automatic', _transmission == 'Automatic', () => setState(() => _transmission = _transmission == 'Automatic' ? null : 'Automatic')),
                      _labelChip('Manual', _transmission == 'Manual', () => setState(() => _transmission = _transmission == 'Manual' ? null : 'Manual')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Seating Capacity ──────────────────────
                  const Text(
                    'Seating Capacity',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _labelChip('Any', _minSeats == null, () => setState(() => _minSeats = null)),
                      _labelChip('4+', _minSeats == 4, () => setState(() => _minSeats = _minSeats == 4 ? null : 4)),
                      _labelChip('5+', _minSeats == 5, () => setState(() => _minSeats = _minSeats == 5 ? null : 5)),
                      _labelChip('7+', _minSeats == 7, () => setState(() => _minSeats = _minSeats == 7 ? null : 7)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Availability ──────────────────────────
                  const Text(
                    'Availability',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _availChip('All Cars', null),
                      const SizedBox(width: 10),
                      _availChip('Available Only', true),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            // Apply button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApply(
                      _sortBy,
                      _priceRange.start,
                      _priceRange.end,
                      _availableOnly,
                      _fuelType,
                      _transmission,
                      _minSeats,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _availChip(String label, bool? value) {
    final isSelected = _availableOnly == value;
    return GestureDetector(
      onTap: () => setState(() => _availableOnly = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _labelChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

