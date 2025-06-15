import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';

const HotelForm = ({ hotel, onSave, onCancel }) => {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    latitude: '',
    longitude: '',
    address: '',
    phone: '',
    email: '',
    booking_url: '',
    rating: '',
    amenities: [],
    home_office_amenities: [],
    images: []
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const { token } = useAuth();
  const API_BASE_URL = process.env.REACT_APP_BACKEND_URL;

  // Predefined amenities
  const amenityOptions = [
    'wifi', 'pool', 'gym', 'spa', 'restaurant', 'bar', 'parking', 
    'pet-friendly', 'air-conditioning', 'room-service', 'laundry', 'concierge'
  ];

  const homeOfficeOptions = [
    'fast-wifi', 'desk', 'monitor', 'printer', 'meeting-room', 
    'quiet-zone', 'ergonomic-chair', 'power-outlets', 'business-center',
    'video-conference', 'private-workspace', '24-7-access'
  ];

  useEffect(() => {
    if (hotel) {
      setFormData({
        name: hotel.name || '',
        description: hotel.description || '',
        price: hotel.price?.toString() || '',
        latitude: hotel.latitude?.toString() || '',
        longitude: hotel.longitude?.toString() || '',
        address: hotel.address || '',
        phone: hotel.phone || '',
        email: hotel.email || '',
        booking_url: hotel.booking_url || '',
        rating: hotel.rating?.toString() || '',
        amenities: hotel.amenities || [],
        home_office_amenities: hotel.home_office_amenities || [],
        images: hotel.images || []
      });
    }
  }, [hotel]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const toggleAmenity = (amenity, isHomeOffice = false) => {
    const field = isHomeOffice ? 'home_office_amenities' : 'amenities';
    setFormData(prev => {
      const currentAmenities = prev[field];
      const newAmenities = currentAmenities.includes(amenity)
        ? currentAmenities.filter(a => a !== amenity)
        : [...currentAmenities, amenity];
      
      return {
        ...prev,
        [field]: newAmenities
      };
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // Validation
    if (!formData.name || !formData.price || !formData.latitude || !formData.longitude || !formData.address) {
      setError('Please fill in all required fields');
      setLoading(false);
      return;
    }

    try {
      const requestData = {
        name: formData.name,
        description: formData.description,
        price: parseFloat(formData.price),
        latitude: parseFloat(formData.latitude),
        longitude: parseFloat(formData.longitude),
        address: formData.address,
        phone: formData.phone,
        email: formData.email,
        booking_url: formData.booking_url,
        rating: formData.rating ? parseFloat(formData.rating) : null,
        amenities: formData.amenities,
        home_office_amenities: formData.home_office_amenities,
        images: formData.images
      };

      let url = `${API_BASE_URL}/api/hotels`;
      let method = 'POST';

      if (hotel) {
        url = `${API_BASE_URL}/api/hotels/${hotel.id}`;
        method = 'PUT';
      }

      const response = await fetch(url, {
        method: method,
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestData),
      });

      if (response.ok) {
        onSave();
      } else {
        const errorData = await response.json();
        setError(errorData.detail || 'Failed to save hotel');
      }
    } catch (error) {
      setError('Network error occurred');
      console.error('Error saving hotel:', error);
    } finally {
      setLoading(false);
    }
  };

  const getCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setFormData(prev => ({
            ...prev,
            latitude: position.coords.latitude.toString(),
            longitude: position.coords.longitude.toString()
          }));
        },
        (error) => {
          console.error('Error getting location:', error);
          alert('Unable to get current location. Please enter manually.');
        }
      );
    } else {
      alert('Geolocation is not supported by this browser');
    }
  };

  return (
    <div className="bg-white rounded-lg shadow card p-6">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900">
          {hotel ? 'Edit Hotel' : 'Add New Hotel'}
        </h2>
        <p className="text-gray-600 mt-1">
          {hotel ? 'Update your hotel information' : 'Create a new hotel listing for remote workers'}
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
            {error}
          </div>
        )}

        {/* Basic Information */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Hotel Name *
            </label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleChange}
              required
              className="form-input w-full px-3 py-2 border rounded-lg"
              placeholder="Enter hotel name"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Price per Night (€) *
            </label>
            <input
              type="number"
              name="price"
              value={formData.price}
              onChange={handleChange}
              required
              min="0"
              step="0.01"
              className="form-input w-full px-3 py-2 border rounded-lg"
              placeholder="0.00"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Description
          </label>
          <textarea
            name="description"
            value={formData.description}
            onChange={handleChange}
            rows={4}
            className="form-input w-full px-3 py-2 border rounded-lg"
            placeholder="Describe your hotel and what makes it perfect for remote work..."
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Address *
          </label>
          <input
            type="text"
            name="address"
            value={formData.address}
            onChange={handleChange}
            required
            className="form-input w-full px-3 py-2 border rounded-lg"
            placeholder="Full address of your hotel"
          />
        </div>

        {/* Location */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Latitude *
            </label>
            <div className="flex">
              <input
                type="number"
                name="latitude"
                value={formData.latitude}
                onChange={handleChange}
                required
                step="any"
                className="form-input flex-1 px-3 py-2 border rounded-l-lg"
                placeholder="51.5074"
              />
              <button
                type="button"
                onClick={getCurrentLocation}
                className="px-3 py-2 bg-gray-100 border border-l-0 rounded-r-lg hover:bg-gray-200 text-sm"
              >
                📍
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Longitude *
            </label>
            <input
              type="number"
              name="longitude"
              value={formData.longitude}
              onChange={handleChange}
              required
              step="any"
              className="form-input w-full px-3 py-2 border rounded-lg"
              placeholder="-0.1278"
            />
          </div>
        </div>

        {/* Contact Information */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Phone Number
            </label>
            <input
              type="tel"
              name="phone"
              value={formData.phone}
              onChange={handleChange}
              className="form-input w-full px-3 py-2 border rounded-lg"
              placeholder="+1 234 567 8900"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Email Address
            </label>
            <input
              type="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              className="form-input w-full px-3 py-2 border rounded-lg"
              placeholder="hotel@example.com"
            />
          </div>
        </div>

        {/* Booking and Rating */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Booking URL
            </label>
            <input
              type="url"
              name="booking_url"
              value={formData.booking_url}
              onChange={handleChange}
              className="form-input w-full px-3 py-2 border rounded-lg"
              placeholder="https://booking.com/your-hotel"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Rating (1-5)
            </label>
            <input
              type="number"
              name="rating"
              value={formData.rating}
              onChange={handleChange}
              min="1"
              max="5"
              step="0.1"
              className="form-input w-full px-3 py-2 border rounded-lg"
              placeholder="4.5"
            />
          </div>
        </div>

        {/* General Amenities */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            General Amenities
          </label>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {amenityOptions.map(amenity => (
              <label key={amenity} className="flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.amenities.includes(amenity)}
                  onChange={() => toggleAmenity(amenity)}
                  className="custom-checkbox mr-2"
                />
                <span className="text-sm text-gray-700 capitalize">{amenity.replace('-', ' ')}</span>
              </label>
            ))}
          </div>
        </div>

        {/* Home Office Amenities */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            🏠 Home Office Features
          </label>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {homeOfficeOptions.map(amenity => (
              <label key={amenity} className="flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.home_office_amenities.includes(amenity)}
                  onChange={() => toggleAmenity(amenity, true)}
                  className="custom-checkbox mr-2"
                />
                <span className="text-sm text-gray-700 capitalize">{amenity.replace('-', ' ')}</span>
              </label>
            ))}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex justify-end space-x-4 pt-6 border-t">
          <button
            type="button"
            onClick={onCancel}
            className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={loading}
            className="btn-primary px-6 py-2 rounded-lg text-white disabled:opacity-50"
          >
            {loading ? (
              <div className="flex items-center">
                <div className="spinner w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-2"></div>
                Saving...
              </div>
            ) : (
              hotel ? 'Update Hotel' : 'Create Hotel'
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default HotelForm;