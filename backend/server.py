from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel, Field, EmailStr
from typing import List, Optional
from datetime import datetime, timedelta
import os
import uuid
import jwt
from passlib.context import CryptContext
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI(title="Hotel Mapping API")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database setup
MONGO_URL = os.getenv("MONGO_URL")
DB_NAME = os.getenv("DB_NAME")
JWT_SECRET = os.getenv("JWT_SECRET")

class Database:
    client: AsyncIOMotorClient = None
    database = None

db = Database()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

# Models
class Location(BaseModel):
    type: str = "Point"
    coordinates: List[float]  # [longitude, latitude]

class User(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    email: EmailStr
    password: str
    name: str
    is_hotel_owner: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str

class Hotel(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    owner_id: str
    name: str
    description: Optional[str] = None
    price: float
    location: Location
    amenities: List[str] = []
    home_office_amenities: List[str] = []
    rating: Optional[float] = None
    images: List[str] = []
    booking_url: Optional[str] = None
    address: str
    phone: Optional[str] = None
    email: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

class HotelCreate(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    amenities: List[str] = []
    home_office_amenities: List[str] = []
    rating: Optional[float] = None
    images: List[str] = []
    booking_url: Optional[str] = None
    address: str
    phone: Optional[str] = None
    email: Optional[str] = None

class HotelUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    amenities: Optional[List[str]] = None
    home_office_amenities: Optional[List[str]] = None
    rating: Optional[float] = None
    images: Optional[List[str]] = None
    booking_url: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None

class HotelResponse(BaseModel):
    id: str
    name: str
    description: Optional[str]
    price: float
    latitude: float
    longitude: float
    amenities: List[str]
    home_office_amenities: List[str]
    rating: Optional[float]
    images: List[str]
    booking_url: Optional[str]
    address: str
    phone: Optional[str]
    email: Optional[str]
    distance: Optional[float] = None

class Token(BaseModel):
    access_token: str
    token_type: str

# Database connection
async def connect_to_mongo():
    db.client = AsyncIOMotorClient(MONGO_URL)
    db.database = db.client[DB_NAME]
    
    # Create indexes
    await db.database.hotels.create_index([("location", "2dsphere")])
    await db.database.users.create_index("email", unique=True)

async def close_mongo_connection():
    if db.client:
        db.client.close()

@app.on_event("startup")
async def startup_event():
    await connect_to_mongo()

@app.on_event("shutdown")
async def shutdown_event():
    await close_mongo_connection()

# Auth functions
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(hours=24)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm="HS256")
    return encoded_jwt

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=["HS256"])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user = await db.database.users.find_one({"id": user_id})
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user

# Auth endpoints
@app.post("/api/auth/register", response_model=Token)
async def register(user: UserCreate):
    # Check if user already exists
    existing_user = await db.database.users.find_one({"email": user.email})
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create new user
    user_dict = {
        "id": str(uuid.uuid4()),
        "email": user.email,
        "password": hash_password(user.password),
        "name": user.name,
        "is_hotel_owner": True,
        "created_at": datetime.utcnow()
    }
    
    await db.database.users.insert_one(user_dict)
    
    # Create access token
    access_token = create_access_token(data={"sub": user_dict["id"]})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/api/auth/login", response_model=Token)
async def login(user: UserLogin):
    # Find user
    db_user = await db.database.users.find_one({"email": user.email})
    if not db_user or not verify_password(user.password, db_user["password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Create access token
    access_token = create_access_token(data={"sub": db_user["id"]})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/api/auth/me")
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    return {
        "id": current_user["id"],
        "email": current_user["email"],
        "name": current_user["name"],
        "is_hotel_owner": current_user["is_hotel_owner"]
    }

# Hotel endpoints
@app.post("/api/hotels", response_model=HotelResponse)
async def create_hotel(hotel: HotelCreate, current_user: dict = Depends(get_current_user)):
    hotel_dict = {
        "id": str(uuid.uuid4()),
        "owner_id": current_user["id"],
        "name": hotel.name,
        "description": hotel.description,
        "price": hotel.price,
        "location": {
            "type": "Point",
            "coordinates": [hotel.longitude, hotel.latitude]
        },
        "amenities": hotel.amenities,
        "home_office_amenities": hotel.home_office_amenities,
        "rating": hotel.rating,
        "images": hotel.images,
        "booking_url": hotel.booking_url,
        "address": hotel.address,
        "phone": hotel.phone,
        "email": hotel.email,
        "created_at": datetime.utcnow()
    }
    
    await db.database.hotels.insert_one(hotel_dict)
    
    return HotelResponse(
        id=hotel_dict["id"],
        name=hotel.name,
        description=hotel.description,
        price=hotel.price,
        latitude=hotel.latitude,
        longitude=hotel.longitude,
        amenities=hotel.amenities,
        home_office_amenities=hotel.home_office_amenities,
        rating=hotel.rating,
        images=hotel.images,
        booking_url=hotel.booking_url,
        address=hotel.address,
        phone=hotel.phone,
        email=hotel.email
    )

@app.get("/api/hotels/my-hotels", response_model=List[HotelResponse])
async def get_my_hotels(current_user: dict = Depends(get_current_user)):
    cursor = db.database.hotels.find({"owner_id": current_user["id"]})
    hotels = await cursor.to_list(length=None)
    
    result = []
    for hotel in hotels:
        result.append(HotelResponse(
            id=hotel["id"],
            name=hotel["name"],
            description=hotel.get("description"),
            price=hotel["price"],
            latitude=hotel["location"]["coordinates"][1],
            longitude=hotel["location"]["coordinates"][0],
            amenities=hotel.get("amenities", []),
            home_office_amenities=hotel.get("home_office_amenities", []),
            rating=hotel.get("rating"),
            images=hotel.get("images", []),
            booking_url=hotel.get("booking_url"),
            address=hotel.get("address", ""),
            phone=hotel.get("phone"),
            email=hotel.get("email")
        ))
    
    return result

@app.put("/api/hotels/{hotel_id}", response_model=HotelResponse)
async def update_hotel(hotel_id: str, hotel_update: HotelUpdate, current_user: dict = Depends(get_current_user)):
    # Check if hotel exists and belongs to current user
    existing_hotel = await db.database.hotels.find_one({"id": hotel_id, "owner_id": current_user["id"]})
    if not existing_hotel:
        raise HTTPException(status_code=404, detail="Hotel not found")
    
    # Build update dict
    update_dict = {}
    if hotel_update.name is not None:
        update_dict["name"] = hotel_update.name
    if hotel_update.description is not None:
        update_dict["description"] = hotel_update.description
    if hotel_update.price is not None:
        update_dict["price"] = hotel_update.price
    if hotel_update.latitude is not None and hotel_update.longitude is not None:
        update_dict["location"] = {
            "type": "Point",
            "coordinates": [hotel_update.longitude, hotel_update.latitude]
        }
    if hotel_update.amenities is not None:
        update_dict["amenities"] = hotel_update.amenities
    if hotel_update.home_office_amenities is not None:
        update_dict["home_office_amenities"] = hotel_update.home_office_amenities
    if hotel_update.rating is not None:
        update_dict["rating"] = hotel_update.rating
    if hotel_update.images is not None:
        update_dict["images"] = hotel_update.images
    if hotel_update.booking_url is not None:
        update_dict["booking_url"] = hotel_update.booking_url
    if hotel_update.address is not None:
        update_dict["address"] = hotel_update.address
    if hotel_update.phone is not None:
        update_dict["phone"] = hotel_update.phone
    if hotel_update.email is not None:
        update_dict["email"] = hotel_update.email
    
    if update_dict:
        await db.database.hotels.update_one({"id": hotel_id}, {"$set": update_dict})
    
    # Return updated hotel
    updated_hotel = await db.database.hotels.find_one({"id": hotel_id})
    return HotelResponse(
        id=updated_hotel["id"],
        name=updated_hotel["name"],
        description=updated_hotel.get("description"),
        price=updated_hotel["price"],
        latitude=updated_hotel["location"]["coordinates"][1],
        longitude=updated_hotel["location"]["coordinates"][0],
        amenities=updated_hotel.get("amenities", []),
        home_office_amenities=updated_hotel.get("home_office_amenities", []),
        rating=updated_hotel.get("rating"),
        images=updated_hotel.get("images", []),
        booking_url=updated_hotel.get("booking_url"),
        address=updated_hotel.get("address", ""),
        phone=updated_hotel.get("phone"),
        email=updated_hotel.get("email")
    )

@app.delete("/api/hotels/{hotel_id}")
async def delete_hotel(hotel_id: str, current_user: dict = Depends(get_current_user)):
    result = await db.database.hotels.delete_one({"id": hotel_id, "owner_id": current_user["id"]})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Hotel not found")
    return {"message": "Hotel deleted successfully"}

# Public search endpoints
@app.get("/api/hotels/search", response_model=List[HotelResponse])
async def search_hotels(
    latitude: float,
    longitude: float,
    radius: float = 50000,  # 50km default
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    amenities: Optional[str] = None,
    home_office_amenities: Optional[str] = None,
    min_rating: Optional[float] = None
):
    # Build aggregation pipeline
    pipeline = [
        {
            "$geoNear": {
                "near": {
                    "type": "Point",
                    "coordinates": [longitude, latitude]
                },
                "distanceField": "distance",
                "maxDistance": radius,
                "spherical": True
            }
        }
    ]
    
    # Add filters
    match_conditions = {}
    
    if min_price is not None or max_price is not None:
        price_filter = {}
        if min_price is not None:
            price_filter["$gte"] = min_price
        if max_price is not None:
            price_filter["$lte"] = max_price
        match_conditions["price"] = price_filter
    
    if amenities:
        amenity_list = [a.strip() for a in amenities.split(",")]
        match_conditions["amenities"] = {"$in": amenity_list}
    
    if home_office_amenities:
        ho_amenity_list = [a.strip() for a in home_office_amenities.split(",")]
        match_conditions["home_office_amenities"] = {"$in": ho_amenity_list}
    
    if min_rating is not None:
        match_conditions["rating"] = {"$gte": min_rating}
    
    if match_conditions:
        pipeline.append({"$match": match_conditions})
    
    # Execute query
    cursor = db.database.hotels.aggregate(pipeline)
    hotels = await cursor.to_list(length=None)
    
    # Convert to response format
    result = []
    for hotel in hotels:
        result.append(HotelResponse(
            id=hotel["id"],
            name=hotel["name"],
            description=hotel.get("description"),
            price=hotel["price"],
            latitude=hotel["location"]["coordinates"][1],
            longitude=hotel["location"]["coordinates"][0],
            amenities=hotel.get("amenities", []),
            home_office_amenities=hotel.get("home_office_amenities", []),
            rating=hotel.get("rating"),
            images=hotel.get("images", []),
            booking_url=hotel.get("booking_url"),
            address=hotel.get("address", ""),
            phone=hotel.get("phone"),
            email=hotel.get("email"),
            distance=hotel.get("distance")
        ))
    
    return result

@app.get("/api/hotels", response_model=List[HotelResponse])
async def get_all_hotels():
    cursor = db.database.hotels.find({})
    hotels = await cursor.to_list(length=100)  # Limit to 100 for performance
    
    result = []
    for hotel in hotels:
        result.append(HotelResponse(
            id=hotel["id"],
            name=hotel["name"],
            description=hotel.get("description"),
            price=hotel["price"],
            latitude=hotel["location"]["coordinates"][1],
            longitude=hotel["location"]["coordinates"][0],
            amenities=hotel.get("amenities", []),
            home_office_amenities=hotel.get("home_office_amenities", []),
            rating=hotel.get("rating"),
            images=hotel.get("images", []),
            booking_url=hotel.get("booking_url"),
            address=hotel.get("address", ""),
            phone=hotel.get("phone"),
            email=hotel.get("email")
        ))
    
    return result

@app.get("/api/hotels/{hotel_id}", response_model=HotelResponse)
async def get_hotel(hotel_id: str):
    hotel = await db.database.hotels.find_one({"id": hotel_id})
    if not hotel:
        raise HTTPException(status_code=404, detail="Hotel not found")
    
    return HotelResponse(
        id=hotel["id"],
        name=hotel["name"],
        description=hotel.get("description"),
        price=hotel["price"],
        latitude=hotel["location"]["coordinates"][1],
        longitude=hotel["location"]["coordinates"][0],
        amenities=hotel.get("amenities", []),
        home_office_amenities=hotel.get("home_office_amenities", []),
        rating=hotel.get("rating"),
        images=hotel.get("images", []),
        booking_url=hotel.get("booking_url"),
        address=hotel.get("address", ""),
        phone=hotel.get("phone"),
        email=hotel.get("email")
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)