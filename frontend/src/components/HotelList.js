import React from 'react';

const HotelList = ({ hotels, onEdit, onDelete }) => {
  if (hotels.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow card p-12 text-center">
        <div className="text-6xl mb-4">🏨</div>
        <h3 className="text-xl font-semibold text-gray-900 mb-2">No Hotels Yet</h3>
        <p className="text-gray-600 mb-6">
          Start by adding your first hotel to our remote work platform
        </p>
        <button
          onClick={() => {}}
          className="btn-primary px-6 py-2 rounded-lg text-white"
        >
          Add Your First Hotel
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {hotels.map((hotel) => (
        <div key={hotel.id} className="bg-white rounded-lg shadow card p-6">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center space-x-3 mb-3">
                <h3 className="text-xl font-semibold text-gray-900">{hotel.name}</h3>
                {hotel.rating && (
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                    ⭐ {hotel.rating}
                  </span>
                )}
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                  Active
                </span>
              </div>

              <p className="text-gray-600 mb-3">{hotel.address}</p>
              
              {hotel.description && (
                <p className="text-gray-700 mb-4 line-clamp-2">{hotel.description}</p>
              )}

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div className="flex items-center text-sm text-gray-600">
                  <span className="font-medium text-2xl text-blue-600 mr-2">€{hotel.price}</span>
                  <span>per night</span>
                </div>
                
                {hotel.phone && (
                  <div className="flex items-center text-sm text-gray-600">
                    <span className="mr-2">📞</span>
                    <span>{hotel.phone}</span>
                  </div>
                )}
                
                {hotel.email && (
                  <div className="flex items-center text-sm text-gray-600">
                    <span className="mr-2">✉️</span>
                    <span>{hotel.email}</span>
                  </div>
                )}
              </div>

              {/* Home Office Features */}
              {hotel.home_office_amenities && hotel.home_office_amenities.length > 0 && (
                <div className="mb-4">
                  <h4 className="text-sm font-medium text-gray-900 mb-2">🏠 Home Office Features</h4>
                  <div className="flex flex-wrap gap-2">
                    {hotel.home_office_amenities.slice(0, 6).map(amenity => (
                      <span key={amenity} className="badge badge-success">
                        {amenity.replace('-', ' ')}
                      </span>
                    ))}
                    {hotel.home_office_amenities.length > 6 && (
                      <span className="badge badge-success">
                        +{hotel.home_office_amenities.length - 6} more
                      </span>
                    )}
                  </div>
                </div>
              )}

              {/* General Amenities */}
              {hotel.amenities && hotel.amenities.length > 0 && (
                <div className="mb-4">
                  <h4 className="text-sm font-medium text-gray-900 mb-2">✨ General Amenities</h4>
                  <div className="flex flex-wrap gap-2">
                    {hotel.amenities.slice(0, 8).map(amenity => (
                      <span key={amenity} className="badge badge-primary">
                        {amenity.replace('-', ' ')}
                      </span>
                    ))}
                    {hotel.amenities.length > 8 && (
                      <span className="badge badge-primary">
                        +{hotel.amenities.length - 8} more
                      </span>
                    )}
                  </div>
                </div>
              )}

              {/* Booking URL */}
              {hotel.booking_url && (
                <div className="mb-4">
                  <a
                    href={hotel.booking_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center text-blue-600 hover:text-blue-800 text-sm font-medium"
                  >
                    🔗 View Booking Page
                    <svg className="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                    </svg>
                  </a>
                </div>
              )}

              {/* Location */}
              <div className="text-xs text-gray-500">
                📍 {hotel.latitude.toFixed(4)}, {hotel.longitude.toFixed(4)}
              </div>
            </div>

            {/* Actions */}
            <div className="flex flex-col space-y-2 ml-4">
              <button
                onClick={() => onEdit(hotel)}
                className="px-4 py-2 text-sm font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
              >
                Edit
              </button>
              <button
                onClick={() => onDelete(hotel.id)}
                className="px-4 py-2 text-sm font-medium text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
              >
                Delete
              </button>
              <a
                href={`/?lat=${hotel.latitude}&lng=${hotel.longitude}&zoom=15`}
                target="_blank"
                rel="noopener noreferrer"
                className="px-4 py-2 text-sm font-medium text-green-600 bg-green-50 rounded-lg hover:bg-green-100 transition-colors text-center"
              >
                View on Map
              </a>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default HotelList;