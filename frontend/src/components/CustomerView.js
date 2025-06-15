import React, { useState, useEffect, useCallback } from 'react';
import { Link } from 'react-router-dom';
import Map, { Marker, Popup } from 'react-map-gl/mapbox';
import 'mapbox-gl/dist/mapbox-gl.css';

const MAPBOX_TOKEN = process.env.REACT_APP_MAPBOX_TOKEN;
const API_BASE_URL = process.env.REACT_APP_BACKEND_URL;

// Check if we have a valid Mapbox token
const hasValidMapboxToken = MAPBOX_TOKEN && MAPBOX_TOKEN.startsWith('pk.') && !MAPBOX_TOKEN.includes('placeholder');

const CustomerView = () => {
  const [viewState, setViewState] = useState({
    longitude: 10.0,
    latitude: 51.0,
    zoom: 6
  });
  
  const [hotels, setHotels] = useState([]);
  const [selectedHotel, setSelectedHotel] = useState(null);
  const [loading, setLoading] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [filters, setFilters] = useState({
    minPrice: '',
    maxPrice: '',
    amenities: '',
    homeOfficeAmenities: '',
    minRating: '',
    radius: 50000
  });

  // Predefined amenities for easy selection
  const commonAmenities = ['wifi', 'pool', 'gym', 'spa', 'restaurant', 'bar', 'parking', 'pet-friendly'];
  const homeOfficeAmenities = ['fast-wifi', 'desk', 'monitor', 'printer', 'meeting-room', 'quiet-zone', 'ergonomic-chair', 'power-outlets'];

  const fetchHotels = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        latitude: viewState.latitude.toString(),
        longitude: viewState.longitude.toString(),
        radius: filters.radius.toString()
      });
      
      if (filters.minPrice) params.append('min_price', filters.minPrice);
      if (filters.maxPrice) params.append('max_price', filters.maxPrice);
      if (filters.amenities) params.append('amenities', filters.amenities);
      if (filters.homeOfficeAmenities) params.append('home_office_amenities', filters.homeOfficeAmenities);
      if (filters.minRating) params.append('min_rating', filters.minRating);
      
      const response = await fetch(`${API_BASE_URL}/api/hotels/search?${params}`);
      const data = await response.json();
      setHotels(data);
    } catch (error) {
      console.error('Error fetching hotels:', error);
    } finally {
      setLoading(false);
    }
  }, [viewState.latitude, viewState.longitude, filters]);

  useEffect(() => {
    fetchHotels();
  }, [fetchHotels]);

  const handleFilterChange = (key, value) => {
    setFilters(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const toggleAmenity = (amenity, isHomeOffice = false) => {
    const key = isHomeOffice ? 'homeOfficeAmenities' : 'amenities';
    const currentAmenities = filters[key] ? filters[key].split(',').map(a => a.trim()) : [];
    
    if (currentAmenities.includes(amenity)) {
      const newAmenities = currentAmenities.filter(a => a !== amenity);
      handleFilterChange(key, newAmenities.join(','));
    } else {
      const newAmenities = [...currentAmenities, amenity];
      handleFilterChange(key, newAmenities.join(','));
    }
  };

  const clearFilters = () => {
    setFilters({
      minPrice: '',
      maxPrice: '',
      amenities: '',
      homeOfficeAmenities: '',
      minRating: '',
      radius: 50000
    });
  };

  const openBookingUrl = (hotel) => {
    if (hotel.booking_url) {
      window.open(hotel.booking_url, '_blank');
    }
  };

  return (
    <div className="relative h-screen">
      {/* Header */}
      <div className="absolute top-0 left-0 right-0 z-10 bg-white shadow-lg">
        <div className="px-6 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <h1 className="text-2xl font-bold gradient-text">🏨 Remote Work Hotels</h1>
            <span className="text-sm text-gray-600">Find hotels perfect for remote work</span>
          </div>
          <div className="flex items-center space-x-4">
            <button
              onClick={() => setShowFilters(!showFilters)}
              className="btn-secondary px-4 py-2 rounded-lg font-medium"
            >
              🔍 Filters {hotels.length > 0 && `(${hotels.length})`}
            </button>
            <Link
              to="/login"
              className="btn-primary px-4 py-2 rounded-lg text-white font-medium"
            >
              Hotel Owner? Sign In
            </Link>
          </div>
        </div>
      </div>

      {/* Filter Panel */}
      {showFilters && (
        <div className="absolute top-20 left-6 z-20 bg-white rounded-lg shadow-xl border max-w-md w-full filter-panel p-6 fade-in">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold">Filter Hotels</h3>
            <button
              onClick={() => setShowFilters(false)}
              className="text-gray-400 hover:text-gray-600"
            >
              ✕
            </button>
          </div>

          <div className="space-y-4">
            {/* Price Range */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Price Range (€/night)</label>
              <div className="flex space-x-2">
                <input
                  type="number"
                  placeholder="Min"
                  value={filters.minPrice}
                  onChange={(e) => handleFilterChange('minPrice', e.target.value)}
                  className="form-input flex-1 px-3 py-2 border rounded-lg"
                />
                <input
                  type="number"
                  placeholder="Max"
                  value={filters.maxPrice}
                  onChange={(e) => handleFilterChange('maxPrice', e.target.value)}
                  className="form-input flex-1 px-3 py-2 border rounded-lg"
                />
              </div>
            </div>

            {/* Rating */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Minimum Rating</label>
              <select
                value={filters.minRating}
                onChange={(e) => handleFilterChange('minRating', e.target.value)}
                className="form-input w-full px-3 py-2 border rounded-lg"
              >
                <option value="">Any Rating</option>
                <option value="3">3+ Stars</option>
                <option value="4">4+ Stars</option>
                <option value="4.5">4.5+ Stars</option>
              </select>
            </div>

            {/* Search Radius */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Search Radius: {(filters.radius / 1000).toFixed(0)}km
              </label>
              <input
                type="range"
                min="5000"
                max="200000"
                step="5000"
                value={filters.radius}
                onChange={(e) => handleFilterChange('radius', e.target.value)}
                className="w-full"
              />
            </div>

            {/* General Amenities */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">General Amenities</label>
              <div className="flex flex-wrap gap-2">
                {commonAmenities.map(amenity => (
                  <button
                    key={amenity}
                    onClick={() => toggleAmenity(amenity)}
                    className={`px-3 py-1 rounded-full text-sm border transition-colors ${
                      filters.amenities.includes(amenity)
                        ? 'bg-blue-500 text-white border-blue-500'
                        : 'bg-white text-gray-700 border-gray-300 hover:border-blue-300'
                    }`}
                  >
                    {amenity}
                  </button>
                ))}
              </div>
            </div>

            {/* Home Office Amenities */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">🏠 Home Office Features</label>
              <div className="flex flex-wrap gap-2">
                {homeOfficeAmenities.map(amenity => (
                  <button
                    key={amenity}
                    onClick={() => toggleAmenity(amenity, true)}
                    className={`px-3 py-1 rounded-full text-sm border transition-colors ${
                      filters.homeOfficeAmenities.includes(amenity)
                        ? 'bg-green-500 text-white border-green-500'
                        : 'bg-white text-gray-700 border-gray-300 hover:border-green-300'
                    }`}
                  >
                    {amenity}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex space-x-2 pt-4">
              <button
                onClick={clearFilters}
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                Clear All
              </button>
              <button
                onClick={() => setShowFilters(false)}
                className="flex-1 btn-primary px-4 py-2 rounded-lg text-white"
              >
                Apply Filters
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Loading Indicator */}
      {loading && (
        <div className="absolute top-24 right-6 z-20 bg-white rounded-lg shadow-lg px-4 py-2">
          <div className="flex items-center space-x-2">
            <div className="spinner w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full"></div>
            <span className="text-sm text-gray-600">Loading hotels...</span>
          </div>
        </div>
      )}

      {/* Map */}
      <Map
        {...viewState}
        onMove={evt => setViewState(evt.viewState)}
        mapboxAccessToken={MAPBOX_TOKEN}
        style={{ width: '100%', height: '100%', marginTop: '72px' }}
        mapStyle="mapbox://styles/mapbox/streets-v12"
      >
        {/* Hotel Markers */}
        {hotels.map((hotel) => (
          <Marker
            key={hotel.id}
            longitude={hotel.longitude}
            latitude={hotel.latitude}
            anchor="bottom"
            onClick={e => {
              e.originalEvent.stopPropagation();
              setSelectedHotel(hotel);
            }}
          >
            <div className="custom-marker">
              €{hotel.price}
            </div>
          </Marker>
        ))}

        {/* Popup for selected hotel */}
        {selectedHotel && (
          <Popup
            longitude={selectedHotel.longitude}
            latitude={selectedHotel.latitude}
            anchor="top"
            onClose={() => setSelectedHotel(null)}
            closeOnClick={false}
          >
            <div className="p-4 min-w-80">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">{selectedHotel.name}</h3>
                  <p className="text-sm text-gray-600">{selectedHotel.address}</p>
                </div>
                {selectedHotel.rating && (
                  <div className="flex items-center bg-yellow-100 px-2 py-1 rounded">
                    <span className="text-yellow-600 text-sm">⭐ {selectedHotel.rating}</span>
                  </div>
                )}
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-2xl font-bold text-blue-600">€{selectedHotel.price}</span>
                  <span className="text-sm text-gray-500">per night</span>
                </div>

                {selectedHotel.description && (
                  <p className="text-sm text-gray-700">{selectedHotel.description}</p>
                )}

                {selectedHotel.distance && (
                  <p className="text-xs text-gray-500">
                    📍 {Math.round(selectedHotel.distance / 1000)} km away
                  </p>
                )}

                {/* Home Office Amenities */}
                {selectedHotel.home_office_amenities.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-900 mb-1">🏠 Home Office Features</h4>
                    <div className="flex flex-wrap gap-1">
                      {selectedHotel.home_office_amenities.map(amenity => (
                        <span key={amenity} className="badge badge-success">
                          {amenity}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {/* General Amenities */}
                {selectedHotel.amenities.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-900 mb-1">✨ Amenities</h4>
                    <div className="flex flex-wrap gap-1">
                      {selectedHotel.amenities.slice(0, 6).map(amenity => (
                        <span key={amenity} className="badge badge-primary">
                          {amenity}
                        </span>
                      ))}
                      {selectedHotel.amenities.length > 6 && (
                        <span className="badge badge-primary">
                          +{selectedHotel.amenities.length - 6} more
                        </span>
                      )}
                    </div>
                  </div>
                )}

                {selectedHotel.booking_url && (
                  <button
                    onClick={() => openBookingUrl(selectedHotel)}
                    className="w-full btn-primary py-2 px-4 rounded-lg text-white font-medium"
                  >
                    Book Now 🚀
                  </button>
                )}

                {selectedHotel.phone && (
                  <div className="text-sm text-gray-600">
                    📞 {selectedHotel.phone}
                  </div>
                )}
              </div>
            </div>
          </Popup>
        )}
      </Map>

      {/* Results Summary */}
      <div className="absolute bottom-6 left-6 bg-white rounded-lg shadow-lg px-4 py-2">
        <p className="text-sm text-gray-600">
          Found <span className="font-semibold text-blue-600">{hotels.length}</span> hotels perfect for remote work
        </p>
      </div>
    </div>
  );
};

export default CustomerView;