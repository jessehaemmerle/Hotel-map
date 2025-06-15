// MongoDB initialization script
print('Starting MongoDB initialization...');

// Switch to hotel_mapping database
db = db.getSiblingDB('hotel_mapping');

// Create collections
db.createCollection('users');
db.createCollection('hotels');

// Create indexes for better performance
print('Creating indexes...');

// User email index (unique)
db.users.createIndex({ "email": 1 }, { unique: true });
print('Created unique index on users.email');

// Hotel geospatial index
db.hotels.createIndex({ "location": "2dsphere" });
print('Created 2dsphere index on hotels.location');

// Hotel owner index
db.hotels.createIndex({ "owner_id": 1 });
print('Created index on hotels.owner_id');

// Hotel search indexes
db.hotels.createIndex({ "name": "text", "description": "text", "address": "text" });
print('Created text index on hotels for search');

db.hotels.createIndex({ "price": 1 });
print('Created index on hotels.price');

db.hotels.createIndex({ "rating": 1 });
print('Created index on hotels.rating');

db.hotels.createIndex({ "amenities": 1 });
print('Created index on hotels.amenities');

db.hotels.createIndex({ "home_office_amenities": 1 });
print('Created index on hotels.home_office_amenities');

// Create sample data
print('Creating sample hotel data...');

// Sample hotels
const sampleHotels = [
    {
        id: "sample-hotel-1",
        owner_id: "sample-owner-1",
        name: "Digital Nomad Paradise",
        description: "Perfect hotel for remote workers with high-speed internet and dedicated workspaces",
        price: 89.99,
        location: {
            type: "Point",
            coordinates: [13.4050, 52.5200] // Berlin
        },
        amenities: ["wifi", "pool", "gym", "restaurant", "bar", "parking"],
        home_office_amenities: ["fast-wifi", "desk", "ergonomic-chair", "meeting-room", "printer"],
        rating: 4.7,
        images: [],
        booking_url: "https://example.com/book-berlin",
        address: "Unter den Linden 1, Berlin, Germany",
        phone: "+49-30-12345678",
        email: "info@digitalnomadparadise.com",
        created_at: new Date()
    },
    {
        id: "sample-hotel-2", 
        owner_id: "sample-owner-2",
        name: "Remote Work Hub London",
        description: "Modern hotel in London with excellent coworking facilities",
        price: 150.00,
        location: {
            type: "Point",
            coordinates: [-0.1276, 51.5074] // London
        },
        amenities: ["wifi", "gym", "restaurant", "concierge", "laundry"],
        home_office_amenities: ["fast-wifi", "desk", "monitor", "business-center", "quiet-zone"],
        rating: 4.5,
        images: [],
        booking_url: "https://example.com/book-london",
        address: "Oxford Street 123, London, UK",
        phone: "+44-20-12345678",
        email: "info@remoteworkhub.com",
        created_at: new Date()
    },
    {
        id: "sample-hotel-3",
        owner_id: "sample-owner-3", 
        name: "Barcelona Coworking Hotel",
        description: "Beachside hotel with amazing coworking spaces and fast internet",
        price: 75.50,
        location: {
            type: "Point",
            coordinates: [2.1734, 41.3851] // Barcelona
        },
        amenities: ["wifi", "pool", "spa", "restaurant", "bar", "pet-friendly"],
        home_office_amenities: ["fast-wifi", "desk", "ergonomic-chair", "video-conference", "power-outlets"],
        rating: 4.8,
        images: [],
        booking_url: "https://example.com/book-barcelona",
        address: "Las Ramblas 456, Barcelona, Spain", 
        phone: "+34-93-12345678",
        email: "info@barcelonacoworking.com",
        created_at: new Date()
    }
];

// Insert sample hotels
db.hotels.insertMany(sampleHotels);
print(`Inserted ${sampleHotels.length} sample hotels`);

print('MongoDB initialization completed successfully!');