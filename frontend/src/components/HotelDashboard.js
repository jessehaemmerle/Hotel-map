import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import HotelForm from './HotelForm';
import HotelList from './HotelList';

const HotelDashboard = () => {
  const [activeTab, setActiveTab] = useState('hotels');
  const [hotels, setHotels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingHotel, setEditingHotel] = useState(null);
  const { user, logout, token } = useAuth();

  console.log('HotelDashboard rendered, user:', user, 'token:', token);

  const API_BASE_URL = process.env.REACT_APP_BACKEND_URL;

  useEffect(() => {
    fetchHotels();
  }, []);

  const fetchHotels = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/hotels/my-hotels`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setHotels(data);
      }
    } catch (error) {
      console.error('Error fetching hotels:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleHotelSaved = () => {
    fetchHotels();
    setEditingHotel(null);
    setActiveTab('hotels');
  };

  const handleEditHotel = (hotel) => {
    setEditingHotel(hotel);
    setActiveTab('add-hotel');
  };

  const handleDeleteHotel = async (hotelId) => {
    if (!window.confirm('Are you sure you want to delete this hotel?')) {
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/api/hotels/${hotelId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        fetchHotels();
      }
    } catch (error) {
      console.error('Error deleting hotel:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="spinner w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-600">Loading your dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold gradient-text">🏨 Hotel Dashboard</h1>
              <div className="ml-6 flex items-center space-x-4">
                <span className="text-sm text-gray-600">Welcome, {user?.name}</span>
                <div className="w-2 h-2 bg-green-400 rounded-full status-online"></div>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <a
                href="/"
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:text-blue-700 text-sm font-medium"
              >
                View Public Site →
              </a>
              <button
                onClick={logout}
                className="text-gray-600 hover:text-gray-800 text-sm font-medium"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow card p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-full bg-blue-100">
                <span className="text-2xl">🏨</span>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Total Hotels</p>
                <p className="text-2xl font-semibold text-gray-900">{hotels.length}</p>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-lg shadow card p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-full bg-green-100">
                <span className="text-2xl">✅</span>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Active Listings</p>
                <p className="text-2xl font-semibold text-gray-900">{hotels.length}</p>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-lg shadow card p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-full bg-yellow-100">
                <span className="text-2xl">💰</span>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Avg. Price</p>
                <p className="text-2xl font-semibold text-gray-900">
                  €{hotels.length > 0 ? Math.round(hotels.reduce((sum, h) => sum + h.price, 0) / hotels.length) : 0}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div className="border-b border-gray-200 mb-8">
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveTab('hotels')}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'hotels'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              My Hotels ({hotels.length})
            </button>
            <button
              onClick={() => {
                setActiveTab('add-hotel');
                setEditingHotel(null);
              }}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'add-hotel'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {editingHotel ? 'Edit Hotel' : 'Add New Hotel'}
            </button>
          </nav>
        </div>

        {/* Tab Content */}
        <div className="fade-in">
          {activeTab === 'hotels' && (
            <HotelList
              hotels={hotels}
              onEdit={handleEditHotel}
              onDelete={handleDeleteHotel}
            />
          )}
          
          {activeTab === 'add-hotel' && (
            <HotelForm
              hotel={editingHotel}
              onSave={handleHotelSaved}
              onCancel={() => {
                setEditingHotel(null);
                setActiveTab('hotels');
              }}
            />
          )}
        </div>
      </div>
    </div>
  );
};

export default HotelDashboard;