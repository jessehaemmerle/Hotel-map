import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';

const HotelDashboardFixed = () => {
  const [hotels, setHotels] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user, logout, token } = useAuth();

  // Use the correct environment variable access for React
  const API_BASE_URL = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8001';

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
      } else {
        console.error('Failed to fetch hotels:', response.status);
      }
    } catch (error) {
      console.error('Error fetching hotels:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ 
        minHeight: '100vh', 
        backgroundColor: '#f9fafb', 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center' 
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ 
            width: '48px', 
            height: '48px', 
            border: '4px solid #3b82f6', 
            borderTop: '4px solid transparent',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
            margin: '0 auto 16px'
          }}></div>
          <p style={{ color: '#6b7280' }}>Loading your dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f9fafb' }}>
      {/* Header */}
      <div style={{ 
        backgroundColor: 'white', 
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)', 
        borderBottom: '1px solid #e5e7eb' 
      }}>
        <div style={{ 
          maxWidth: '1280px', 
          margin: '0 auto', 
          padding: '0 16px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          height: '64px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <h1 style={{ 
              fontSize: '24px', 
              fontWeight: 'bold', 
              background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              margin: 0
            }}>
              🏨 Hotel Dashboard
            </h1>
            <div style={{ marginLeft: '24px', display: 'flex', alignItems: 'center', gap: '16px' }}>
              <span style={{ fontSize: '14px', color: '#6b7280' }}>
                Welcome, {user?.name || 'User'}
              </span>
              <div style={{ 
                width: '8px', 
                height: '8px', 
                backgroundColor: '#10b981', 
                borderRadius: '50%',
                boxShadow: '0 0 0 2px rgba(16, 185, 129, 0.2)'
              }}></div>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <a
              href="/"
              target="_blank"
              rel="noopener noreferrer"
              style={{ 
                color: '#3b82f6', 
                fontSize: '14px', 
                fontWeight: '500',
                textDecoration: 'none'
              }}
            >
              View Public Site →
            </a>
            <button
              onClick={logout}
              style={{ 
                color: '#6b7280', 
                fontSize: '14px', 
                fontWeight: '500',
                background: 'none',
                border: 'none',
                cursor: 'pointer'
              }}
            >
              Sign Out
            </button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div style={{ maxWidth: '1280px', margin: '0 auto', padding: '32px 16px' }}>
        {/* Stats Cards */}
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', 
          gap: '24px', 
          marginBottom: '32px' 
        }}>
          <div style={{ 
            backgroundColor: 'white', 
            borderRadius: '8px', 
            boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
            padding: '24px'
          }}>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <div style={{ 
                padding: '12px', 
                borderRadius: '50%', 
                backgroundColor: '#dbeafe' 
              }}>
                <span style={{ fontSize: '32px' }}>🏨</span>
              </div>
              <div style={{ marginLeft: '16px' }}>
                <p style={{ fontSize: '14px', fontWeight: '500', color: '#6b7280', margin: '0 0 4px 0' }}>
                  Total Hotels
                </p>
                <p style={{ fontSize: '32px', fontWeight: '600', color: '#111827', margin: 0 }}>
                  {hotels.length}
                </p>
              </div>
            </div>
          </div>
          
          <div style={{ 
            backgroundColor: 'white', 
            borderRadius: '8px', 
            boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
            padding: '24px'
          }}>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <div style={{ 
                padding: '12px', 
                borderRadius: '50%', 
                backgroundColor: '#d1fae5' 
              }}>
                <span style={{ fontSize: '32px' }}>✅</span>
              </div>
              <div style={{ marginLeft: '16px' }}>
                <p style={{ fontSize: '14px', fontWeight: '500', color: '#6b7280', margin: '0 0 4px 0' }}>
                  Active Listings
                </p>
                <p style={{ fontSize: '32px', fontWeight: '600', color: '#111827', margin: 0 }}>
                  {hotels.length}
                </p>
              </div>
            </div>
          </div>
          
          <div style={{ 
            backgroundColor: 'white', 
            borderRadius: '8px', 
            boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
            padding: '24px'
          }}>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <div style={{ 
                padding: '12px', 
                borderRadius: '50%', 
                backgroundColor: '#fef3c7' 
              }}>
                <span style={{ fontSize: '32px' }}>💰</span>
              </div>
              <div style={{ marginLeft: '16px' }}>
                <p style={{ fontSize: '14px', fontWeight: '500', color: '#6b7280', margin: '0 0 4px 0' }}>
                  Avg. Price
                </p>
                <p style={{ fontSize: '32px', fontWeight: '600', color: '#111827', margin: 0 }}>
                  €{hotels.length > 0 ? Math.round(hotels.reduce((sum, h) => sum + h.price, 0) / hotels.length) : 0}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Hotels List */}
        <div style={{ 
          backgroundColor: 'white', 
          borderRadius: '8px', 
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          padding: '24px'
        }}>
          <h2 style={{ 
            fontSize: '24px', 
            fontWeight: '600', 
            color: '#111827', 
            marginBottom: '24px' 
          }}>
            Your Hotels ({hotels.length})
          </h2>
          
          {hotels.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '48px 0' }}>
              <div style={{ fontSize: '96px', marginBottom: '16px' }}>🏨</div>
              <h3 style={{ 
                fontSize: '20px', 
                fontWeight: '600', 
                color: '#111827', 
                marginBottom: '8px' 
              }}>
                No Hotels Yet
              </h3>
              <p style={{ color: '#6b7280', marginBottom: '24px' }}>
                Start by adding your first hotel to our remote work platform
              </p>
              <button
                style={{
                  backgroundColor: '#3b82f6',
                  color: 'white',
                  padding: '12px 24px',
                  borderRadius: '8px',
                  border: 'none',
                  fontSize: '16px',
                  fontWeight: '500',
                  cursor: 'pointer'
                }}
                onClick={() => alert('Add hotel functionality would go here')}
              >
                Add Your First Hotel
              </button>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {hotels.map((hotel) => (
                <div 
                  key={hotel.id} 
                  style={{ 
                    border: '1px solid #e5e7eb', 
                    borderRadius: '8px', 
                    padding: '16px',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                  }}
                >
                  <div>
                    <h3 style={{ 
                      fontSize: '18px', 
                      fontWeight: '600', 
                      margin: '0 0 8px 0' 
                    }}>
                      {hotel.name}
                    </h3>
                    <p style={{ color: '#6b7280', margin: '0 0 4px 0' }}>
                      {hotel.address}
                    </p>
                    <p style={{ 
                      color: '#3b82f6', 
                      fontWeight: '600', 
                      fontSize: '16px',
                      margin: 0 
                    }}>
                      €{hotel.price}/night
                    </p>
                  </div>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      style={{
                        backgroundColor: '#dbeafe',
                        color: '#3b82f6',
                        padding: '8px 16px',
                        borderRadius: '6px',
                        border: 'none',
                        fontSize: '14px',
                        fontWeight: '500',
                        cursor: 'pointer'
                      }}
                    >
                      Edit
                    </button>
                    <button
                      style={{
                        backgroundColor: '#fee2e2',
                        color: '#dc2626',
                        padding: '8px 16px',
                        borderRadius: '6px',
                        border: 'none',
                        fontSize: '14px',
                        fontWeight: '500',
                        cursor: 'pointer'
                      }}
                    >
                      Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Add spinning animation with style tag */}
      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
};

export default HotelDashboardFixed;