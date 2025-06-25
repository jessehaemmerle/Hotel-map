import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';

const HotelDashboardDebug = () => {
  const [activeTab, setActiveTab] = useState('hotels');
  const [hotels, setHotels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [debugInfo, setDebugInfo] = useState('');
  const { user, logout, token } = useAuth();

  const API_BASE_URL = process.env.REACT_APP_BACKEND_URL;

  useEffect(() => {
    console.log('HotelDashboard: Component mounted');
    console.log('User:', user);
    console.log('Token:', token);
    console.log('API_BASE_URL:', API_BASE_URL);
    
    setDebugInfo(`User: ${user?.name || 'NULL'}, Token: ${token ? 'EXISTS' : 'NULL'}, API: ${API_BASE_URL}`);
    
    if (user && token) {
      fetchHotels();
    } else {
      setLoading(false);
      setError('No user or token available');
    }
  }, [user, token]);

  const fetchHotels = async () => {
    try {
      console.log('Fetching hotels...');
      const response = await fetch(`${API_BASE_URL}/api/hotels/my-hotels`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      console.log('Response status:', response.status);
      
      if (response.ok) {
        const data = await response.json();
        console.log('Hotels data:', data);
        setHotels(data);
        setError('');
      } else {
        const errorText = await response.text();
        console.error('Error response:', errorText);
        setError(`Failed to fetch hotels: ${response.status}`);
      }
    } catch (error) {
      console.error('Fetch error:', error);
      setError(`Network error: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  console.log('Rendering dashboard, loading:', loading, 'error:', error);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="spinner w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-600">Loading dashboard...</p>
          <p className="text-sm text-gray-500 mt-2">{debugInfo}</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-600 text-xl mb-4">❌ Error</div>
          <p className="text-red-600">{error}</p>
          <p className="text-sm text-gray-500 mt-2">{debugInfo}</p>
          <button 
            onClick={() => window.location.reload()} 
            className="mt-4 px-4 py-2 bg-blue-500 text-white rounded"
          >
            Reload Page
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Debug Header */}
      <div className="bg-yellow-100 border-b border-yellow-200 p-4">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-lg font-bold text-yellow-800">🐛 Debug Mode</h1>
          <p className="text-sm text-yellow-700">{debugInfo}</p>
          <p className="text-sm text-yellow-700">Hotels count: {hotels.length}</p>
        </div>
      </div>

      {/* Main Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold text-blue-600">🏨 Hotel Dashboard</h1>
              <div className="ml-6 flex items-center space-x-4">
                <span className="text-sm text-gray-600">
                  Welcome, {user?.name || 'Unknown User'}
                </span>
                <div className="w-2 h-2 bg-green-400 rounded-full"></div>
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
          <div className="bg-white rounded-lg shadow p-6">
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
          
          <div className="bg-white rounded-lg shadow p-6">
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
          
          <div className="bg-white rounded-lg shadow p-6">
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
              onClick={() => setActiveTab('add-hotel')}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'add-hotel'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              Add New Hotel
            </button>
          </nav>
        </div>

        {/* Tab Content */}
        <div className="bg-white rounded-lg shadow p-6">
          {activeTab === 'hotels' && (
            <div>
              <h3 className="text-lg font-semibold mb-4">Your Hotels</h3>
              {hotels.length === 0 ? (
                <div className="text-center py-12">
                  <div className="text-6xl mb-4">🏨</div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">No Hotels Yet</h3>
                  <p className="text-gray-600 mb-6">
                    Start by adding your first hotel to our remote work platform
                  </p>
                  <button
                    onClick={() => setActiveTab('add-hotel')}
                    className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                  >
                    Add Your First Hotel
                  </button>
                </div>
              ) : (
                <div className="space-y-4">
                  {hotels.map((hotel) => (
                    <div key={hotel.id} className="border rounded-lg p-4">
                      <h4 className="font-semibold">{hotel.name}</h4>
                      <p className="text-gray-600">{hotel.address}</p>
                      <p className="text-blue-600 font-medium">€{hotel.price}/night</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
          
          {activeTab === 'add-hotel' && (
            <div>
              <h3 className="text-lg font-semibold mb-4">Add New Hotel</h3>
              <div className="bg-gray-50 p-8 rounded-lg text-center">
                <p className="text-gray-600">Hotel form will be displayed here</p>
                <p className="text-sm text-gray-500 mt-2">
                  This is a simplified debug version to test rendering
                </p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default HotelDashboardDebug;