import requests
import json
import random
import time
import os
from typing import Dict, List, Optional, Tuple

# Get backend URL from frontend/.env
BACKEND_URL = "https://e9b4dd7d-b3a8-44d3-b08e-bd05832659cc.preview.emergentagent.com/api"

# Test data
TEST_USER = {
    "email": f"test_user_{int(time.time())}@example.com",
    "password": "Password123!",
    "name": "Test User"
}

TEST_HOTEL = {
    "name": "Remote Work Paradise",
    "description": "Perfect hotel for remote workers with amazing amenities",
    "price": 120.50,
    "latitude": 40.7128,
    "longitude": -74.0060,
    "amenities": ["wifi", "pool", "gym", "breakfast"],
    "home_office_amenities": ["desk", "ergonomic chair", "high-speed internet", "printer"],
    "rating": 4.8,
    "images": ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
    "booking_url": "https://example.com/book",
    "address": "123 Remote Work St, New York, NY 10001",
    "phone": "+1-555-123-4567",
    "email": "info@remoteworkparadise.com"
}

# Test results tracking
test_results = {
    "auth": {"passed": 0, "failed": 0, "details": []},
    "hotel_crud": {"passed": 0, "failed": 0, "details": []},
    "geospatial": {"passed": 0, "failed": 0, "details": []},
    "filtering": {"passed": 0, "failed": 0, "details": []}
}

def log_test(category: str, test_name: str, passed: bool, details: str = None):
    """Log test results"""
    result = "PASSED" if passed else "FAILED"
    print(f"[{category}] {test_name}: {result}")
    if details:
        print(f"  Details: {details}")
    
    if passed:
        test_results[category]["passed"] += 1
    else:
        test_results[category]["failed"] += 1
        test_results[category]["details"].append(f"{test_name}: {details}")

def register_user(user_data: Dict) -> Tuple[bool, Optional[Dict], str]:
    """Register a new user"""
    try:
        response = requests.post(f"{BACKEND_URL}/auth/register", json=user_data)
        if response.status_code == 200:
            return True, response.json(), "User registered successfully"
        else:
            return False, None, f"Registration failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Registration failed with exception: {str(e)}"

def login_user(email: str, password: str) -> Tuple[bool, Optional[Dict], str]:
    """Login a user"""
    try:
        response = requests.post(f"{BACKEND_URL}/auth/login", json={"email": email, "password": password})
        if response.status_code == 200:
            return True, response.json(), "User logged in successfully"
        else:
            return False, None, f"Login failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Login failed with exception: {str(e)}"

def get_user_info(token: str) -> Tuple[bool, Optional[Dict], str]:
    """Get current user info"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{BACKEND_URL}/auth/me", headers=headers)
        if response.status_code == 200:
            return True, response.json(), "User info retrieved successfully"
        else:
            return False, None, f"Get user info failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Get user info failed with exception: {str(e)}"

def create_hotel(token: str, hotel_data: Dict) -> Tuple[bool, Optional[Dict], str]:
    """Create a new hotel"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.post(f"{BACKEND_URL}/hotels", json=hotel_data, headers=headers)
        if response.status_code == 200:
            return True, response.json(), "Hotel created successfully"
        else:
            return False, None, f"Hotel creation failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Hotel creation failed with exception: {str(e)}"

def get_my_hotels(token: str) -> Tuple[bool, Optional[List], str]:
    """Get hotels owned by current user"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{BACKEND_URL}/hotels/my-hotels", headers=headers)
        if response.status_code == 200:
            return True, response.json(), "My hotels retrieved successfully"
        else:
            return False, None, f"Get my hotels failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Get my hotels failed with exception: {str(e)}"

def update_hotel(token: str, hotel_id: str, update_data: Dict) -> Tuple[bool, Optional[Dict], str]:
    """Update a hotel"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.put(f"{BACKEND_URL}/hotels/{hotel_id}", json=update_data, headers=headers)
        if response.status_code == 200:
            return True, response.json(), "Hotel updated successfully"
        else:
            return False, None, f"Hotel update failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Hotel update failed with exception: {str(e)}"

def delete_hotel(token: str, hotel_id: str) -> Tuple[bool, Optional[Dict], str]:
    """Delete a hotel"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.delete(f"{BACKEND_URL}/hotels/{hotel_id}", headers=headers)
        if response.status_code == 200:
            return True, response.json(), "Hotel deleted successfully"
        else:
            return False, None, f"Hotel deletion failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Hotel deletion failed with exception: {str(e)}"

def get_all_hotels() -> Tuple[bool, Optional[List], str]:
    """Get all hotels"""
    try:
        response = requests.get(f"{BACKEND_URL}/hotels")
        if response.status_code == 200:
            return True, response.json(), "All hotels retrieved successfully"
        else:
            return False, None, f"Get all hotels failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Get all hotels failed with exception: {str(e)}"

def get_hotel_by_id(hotel_id: str) -> Tuple[bool, Optional[Dict], str]:
    """Get a hotel by ID"""
    try:
        response = requests.get(f"{BACKEND_URL}/hotels/{hotel_id}")
        if response.status_code == 200:
            return True, response.json(), "Hotel retrieved successfully"
        else:
            return False, None, f"Get hotel failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Get hotel failed with exception: {str(e)}"

def search_hotels(params: Dict) -> Tuple[bool, Optional[List], str]:
    """Search hotels with filters"""
    try:
        response = requests.get(f"{BACKEND_URL}/hotels/search", params=params)
        if response.status_code == 200:
            return True, response.json(), "Hotel search successful"
        else:
            return False, None, f"Hotel search failed with status {response.status_code}: {response.text}"
    except Exception as e:
        return False, None, f"Hotel search failed with exception: {str(e)}"

def test_authentication():
    """Test authentication system"""
    print("\n=== Testing Authentication System ===\n")
    
    # Test user registration
    success, register_data, message = register_user(TEST_USER)
    log_test("auth", "User Registration", success, message)
    
    if not success:
        print("Cannot continue authentication tests without registration")
        return None
    
    token = register_data["access_token"]
    
    # Test user login
    success, login_data, message = login_user(TEST_USER["email"], TEST_USER["password"])
    log_test("auth", "User Login", success, message)
    
    if success:
        token = login_data["access_token"]
    
    # Test JWT token validation
    success, user_data, message = get_user_info(token)
    log_test("auth", "JWT Token Validation", success, message)
    
    # Test invalid token
    success, user_data, message = get_user_info("invalid_token")
    log_test("auth", "Invalid Token Rejection", not success, "Should reject invalid token")
    
    return token

def test_hotel_crud(token: str):
    """Test hotel CRUD operations"""
    if not token:
        print("Cannot test hotel CRUD without authentication token")
        return None
    
    print("\n=== Testing Hotel CRUD Operations ===\n")
    
    # Create hotel
    success, hotel_data, message = create_hotel(token, TEST_HOTEL)
    log_test("hotel_crud", "Create Hotel", success, message)
    
    if not success:
        print("Cannot continue hotel CRUD tests without creating a hotel")
        return
    
    hotel_id = hotel_data["id"]
    
    # Get my hotels
    success, my_hotels, message = get_my_hotels(token)
    log_test("hotel_crud", "Get My Hotels", success, message)
    
    if success:
        found = any(hotel["id"] == hotel_id for hotel in my_hotels)
        log_test("hotel_crud", "Hotel in My Hotels List", found, 
                 "Created hotel should be in my hotels list")
    
    # Get hotel by ID
    success, hotel, message = get_hotel_by_id(hotel_id)
    log_test("hotel_crud", "Get Hotel by ID", success, message)
    
    if success:
        log_test("hotel_crud", "Hotel Data Integrity", 
                 hotel["name"] == TEST_HOTEL["name"] and 
                 hotel["price"] == TEST_HOTEL["price"],
                 "Hotel data should match what was created")
    
    # Update hotel
    update_data = {
        "name": "Updated Hotel Name",
        "price": 150.75
    }
    success, updated_hotel, message = update_hotel(token, hotel_id, update_data)
    log_test("hotel_crud", "Update Hotel", success, message)
    
    if success:
        log_test("hotel_crud", "Hotel Update Integrity", 
                 updated_hotel["name"] == update_data["name"] and 
                 updated_hotel["price"] == update_data["price"],
                 "Hotel data should be updated correctly")
    
    # Delete hotel
    success, delete_result, message = delete_hotel(token, hotel_id)
    log_test("hotel_crud", "Delete Hotel", success, message)
    
    # Verify deletion
    success, hotel, message = get_hotel_by_id(hotel_id)
    log_test("hotel_crud", "Hotel Deletion Verification", not success, 
             "Hotel should not be found after deletion")
    
    return hotel_id

def test_geospatial_search(token: str):
    """Test geospatial search functionality"""
    if not token:
        print("Cannot test geospatial search without authentication token")
        return
    
    print("\n=== Testing Geospatial Search ===\n")
    
    # Create a hotel for testing
    test_hotel = TEST_HOTEL.copy()
    test_hotel["name"] = f"Geo Test Hotel {int(time.time())}"
    success, hotel_data, message = create_hotel(token, test_hotel)
    
    if not success:
        log_test("geospatial", "Create Test Hotel", False, message)
        return
    
    hotel_id = hotel_data["id"]
    
    # Test nearby search (should find the hotel)
    search_params = {
        "latitude": TEST_HOTEL["latitude"],
        "longitude": TEST_HOTEL["longitude"],
        "radius": 1000  # 1km radius
    }
    success, results, message = search_hotels(search_params)
    log_test("geospatial", "Nearby Hotel Search", success, message)
    
    if success:
        found = any(hotel["id"] == hotel_id for hotel in results)
        log_test("geospatial", "Find Nearby Hotel", found, 
                 "Should find hotel within specified radius")
        
        if found and len(results) > 0:
            has_distance = all("distance" in hotel for hotel in results)
            log_test("geospatial", "Distance Calculation", has_distance, 
                     "All results should include distance field")
    
    # Test far away search (should not find the hotel)
    far_search_params = {
        "latitude": TEST_HOTEL["latitude"] + 1,  # ~111km away
        "longitude": TEST_HOTEL["longitude"],
        "radius": 10000  # 10km radius
    }
    success, far_results, message = search_hotels(far_search_params)
    
    if success:
        not_found = not any(hotel["id"] == hotel_id for hotel in far_results)
        log_test("geospatial", "Far Away Hotel Search", not_found, 
                 "Should not find hotel outside specified radius")
    
    # Clean up
    delete_hotel(token, hotel_id)

def test_advanced_filtering(token: str):
    """Test advanced filtering functionality"""
    if not token:
        print("Cannot test advanced filtering without authentication token")
        return
    
    print("\n=== Testing Advanced Filtering ===\n")
    
    # Create hotels with different properties for testing
    hotels = []
    
    # Hotel 1: Budget hotel with basic amenities
    budget_hotel = TEST_HOTEL.copy()
    budget_hotel["name"] = f"Budget Hotel {int(time.time())}"
    budget_hotel["price"] = 75.0
    budget_hotel["amenities"] = ["wifi", "breakfast"]
    budget_hotel["home_office_amenities"] = ["desk"]
    budget_hotel["rating"] = 3.5
    success, hotel_data, _ = create_hotel(token, budget_hotel)
    if success:
        hotels.append({"id": hotel_data["id"], "type": "budget"})
    
    # Hotel 2: Mid-range hotel with good amenities
    midrange_hotel = TEST_HOTEL.copy()
    midrange_hotel["name"] = f"Mid-range Hotel {int(time.time())}"
    midrange_hotel["price"] = 120.0
    midrange_hotel["amenities"] = ["wifi", "pool", "gym", "breakfast"]
    midrange_hotel["home_office_amenities"] = ["desk", "ergonomic chair"]
    midrange_hotel["rating"] = 4.0
    success, hotel_data, _ = create_hotel(token, midrange_hotel)
    if success:
        hotels.append({"id": hotel_data["id"], "type": "midrange"})
    
    # Hotel 3: Luxury hotel with premium amenities
    luxury_hotel = TEST_HOTEL.copy()
    luxury_hotel["name"] = f"Luxury Hotel {int(time.time())}"
    luxury_hotel["price"] = 250.0
    luxury_hotel["amenities"] = ["wifi", "pool", "gym", "spa", "restaurant", "breakfast"]
    luxury_hotel["home_office_amenities"] = ["desk", "ergonomic chair", "high-speed internet", "printer", "meeting room"]
    luxury_hotel["rating"] = 4.8
    success, hotel_data, _ = create_hotel(token, luxury_hotel)
    if success:
        hotels.append({"id": hotel_data["id"], "type": "luxury"})
    
    if len(hotels) < 3:
        log_test("filtering", "Create Test Hotels", False, "Failed to create all test hotels")
        # Clean up any hotels that were created
        for hotel in hotels:
            delete_hotel(token, hotel["id"])
        return
    
    # Test 1: Price range filter
    price_params = {
        "latitude": TEST_HOTEL["latitude"],
        "longitude": TEST_HOTEL["longitude"],
        "radius": 10000,
        "min_price": 100,
        "max_price": 200
    }
    success, results, message = search_hotels(price_params)
    log_test("filtering", "Price Range Filter", success, message)
    
    if success:
        # Should find midrange but not budget or luxury
        found_midrange = any(hotel["id"] == hotels[1]["id"] for hotel in results)
        not_found_budget = not any(hotel["id"] == hotels[0]["id"] for hotel in results)
        not_found_luxury = not any(hotel["id"] == hotels[2]["id"] for hotel in results)
        
        log_test("filtering", "Price Range Results", 
                 found_midrange and not_found_budget and not_found_luxury,
                 "Should only find hotels in the specified price range")
    
    # Test 2: Amenities filter
    amenities_params = {
        "latitude": TEST_HOTEL["latitude"],
        "longitude": TEST_HOTEL["longitude"],
        "radius": 10000,
        "amenities": "pool,spa"
    }
    success, results, message = search_hotels(amenities_params)
    log_test("filtering", "Amenities Filter", success, message)
    
    if success:
        # Should find luxury but not budget (midrange has pool but not spa)
        found_luxury = any(hotel["id"] == hotels[2]["id"] for hotel in results)
        not_found_budget = not any(hotel["id"] == hotels[0]["id"] for hotel in results)
        
        log_test("filtering", "Amenities Filter Results", 
                 found_luxury and not_found_budget,
                 "Should only find hotels with specified amenities")
    
    # Test 3: Home office amenities filter
    ho_params = {
        "latitude": TEST_HOTEL["latitude"],
        "longitude": TEST_HOTEL["longitude"],
        "radius": 10000,
        "home_office_amenities": "printer,meeting room"
    }
    success, results, message = search_hotels(ho_params)
    log_test("filtering", "Home Office Amenities Filter", success, message)
    
    if success:
        # Should find luxury but not budget or midrange
        found_luxury = any(hotel["id"] == hotels[2]["id"] for hotel in results)
        not_found_budget = not any(hotel["id"] == hotels[0]["id"] for hotel in results)
        not_found_midrange = not any(hotel["id"] == hotels[1]["id"] for hotel in results)
        
        log_test("filtering", "Home Office Filter Results", 
                 found_luxury and not_found_budget and not_found_midrange,
                 "Should only find hotels with specified home office amenities")
    
    # Test 4: Rating filter
    rating_params = {
        "latitude": TEST_HOTEL["latitude"],
        "longitude": TEST_HOTEL["longitude"],
        "radius": 10000,
        "min_rating": 4.5
    }
    success, results, message = search_hotels(rating_params)
    log_test("filtering", "Rating Filter", success, message)
    
    if success:
        # Should find luxury but not budget or midrange
        found_luxury = any(hotel["id"] == hotels[2]["id"] for hotel in results)
        not_found_budget = not any(hotel["id"] == hotels[0]["id"] for hotel in results)
        not_found_midrange = not any(hotel["id"] == hotels[1]["id"] for hotel in results)
        
        log_test("filtering", "Rating Filter Results", 
                 found_luxury and not_found_budget and not_found_midrange,
                 "Should only find hotels with rating above threshold")
    
    # Test 5: Combined filters
    combined_params = {
        "latitude": TEST_HOTEL["latitude"],
        "longitude": TEST_HOTEL["longitude"],
        "radius": 10000,
        "min_price": 100,
        "max_price": 300,
        "amenities": "pool,gym",
        "min_rating": 4.0
    }
    success, results, message = search_hotels(combined_params)
    log_test("filtering", "Combined Filters", success, message)
    
    if success:
        # Should find luxury and midrange but not budget
        found_luxury = any(hotel["id"] == hotels[2]["id"] for hotel in results)
        found_midrange = any(hotel["id"] == hotels[1]["id"] for hotel in results)
        not_found_budget = not any(hotel["id"] == hotels[0]["id"] for hotel in results)
        
        log_test("filtering", "Combined Filter Results", 
                 found_luxury and found_midrange and not_found_budget,
                 "Should correctly apply multiple filters")
    
    # Clean up
    for hotel in hotels:
        delete_hotel(token, hotel["id"])

def run_all_tests():
    """Run all tests"""
    print("\n===== STARTING BACKEND API TESTS =====\n")
    
    # Test authentication first
    token = test_authentication()
    
    if token:
        # Test hotel CRUD operations
        test_hotel_crud(token)
        
        # Test geospatial search
        test_geospatial_search(token)
        
        # Test advanced filtering
        test_advanced_filtering(token)
    
    # Print summary
    print("\n===== TEST SUMMARY =====\n")
    for category, results in test_results.items():
        total = results["passed"] + results["failed"]
        if total > 0:
            pass_rate = (results["passed"] / total) * 100
            print(f"{category.upper()}: {results['passed']}/{total} passed ({pass_rate:.1f}%)")
            
            if results["failed"] > 0:
                print("  Failed tests:")
                for detail in results["details"]:
                    print(f"  - {detail}")
    
    print("\n===== END OF TESTS =====\n")

if __name__ == "__main__":
    run_all_tests()