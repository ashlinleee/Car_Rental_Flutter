// car.dart — Immutable data model representing a rental car listing.
//
// Supports JSON serialisation/deserialisation for API communication.
// Also provides a static getSampleCars() list used as a fallback
// when the backend is unreachable (network errors, local dev without server).

class Car {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double pricePerDay;
  final String imageUrl;
  final int seats;
  final String transmission;
  final String fuelType;
  final double rating;
  final bool isAvailable;
  final String? state;
  final String? place;
  final List<String> features;

  // All required fields must be supplied; optional fields have sensible defaults.
  Car({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.pricePerDay,
    required this.imageUrl,
    required this.seats,
    required this.transmission,
    required this.fuelType,
    required this.rating,
    this.isAvailable = true,
    this.state,
    this.place,
    this.features = const [],
  });

  factory Car.fromJson(Map<String, dynamic> json) {
  // Deserialises a Car from a JSON map returned by the API.
  // Uses safe defaults for every field to tolerate partial/missing data.
    return Car(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
      seats: (json['seats'] as num?)?.toInt() ?? 4,
      transmission: json['transmission'] ?? 'Automatic',
      fuelType: json['fuelType'] ?? 'Petrol',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      state: json['state'] as String?,
      place: json['place'] as String?,
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  // Serialises the Car to a Map for API requests.
  // Omits nullable/empty optional fields (state, place, features) when not set.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category,
        'pricePerDay': pricePerDay,
        'imageUrl': imageUrl,
        'seats': seats,
        'transmission': transmission,
        'fuelType': fuelType,
        'rating': rating,
        'isAvailable': isAvailable,
        if (state != null) 'state': state,
        if (place != null) 'place': place,
        if (features.isNotEmpty) 'features': features,
      };

      // Returns a hardcoded list of sample cars used as an offline fallback.
      // Covers a range of categories (Sedan, SUV, Luxury, Sports, Electric).
  static List<Car> getSampleCars() {
    return [
      Car(
        id: '1',
        name: 'Toyota Camry',
        brand: 'Toyota',
        category: 'Sedan',
        pricePerDay: 3000,
        imageUrl: 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=400',
        seats: 5,
        transmission: 'Automatic',
        fuelType: 'Petrol',
        rating: 4.5,
      ),
      Car(
        id: '2',
        name: 'Honda CR-V',
        brand: 'Honda',
        category: 'SUV',
        pricePerDay: 4500,
        imageUrl: 'https://images.unsplash.com/photo-1549924231-f129b911e442?w=400',
        seats: 7,
        transmission: 'Automatic',
        fuelType: 'Petrol',
        rating: 4.7,
      ),
      Car(
        id: '3',
        name: 'BMW 3 Series',
        brand: 'BMW',
        category: 'Luxury',
        pricePerDay: 7500,
        imageUrl: 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=400',
        seats: 5,
        transmission: 'Automatic',
        fuelType: 'Petrol',
        rating: 4.8,
      ),
      Car(
        id: '4',
        name: 'Ford Mustang',
        brand: 'Ford',
        category: 'Sports',
        pricePerDay: 6000,
        imageUrl: 'https://images.unsplash.com/photo-1584345604476-8ec5e12e42dd?w=400',
        seats: 4,
        transmission: 'Manual',
        fuelType: 'Petrol',
        rating: 4.6,
      ),
      Car(
        id: '5',
        name: 'Tesla Model 3',
        brand: 'Tesla',
        category: 'Electric',
        pricePerDay: 5500,
        imageUrl: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=400',
        seats: 5,
        transmission: 'Automatic',
        fuelType: 'Electric',
        rating: 4.9,
      ),
      Car(
        id: '6',
        name: 'Chevrolet Tahoe',
        brand: 'Chevrolet',
        category: 'SUV',
        pricePerDay: 5000,
        imageUrl: 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=400',
        seats: 8,
        transmission: 'Automatic',
        fuelType: 'Diesel',
        rating: 4.4,
      ),
    ];
  }
}