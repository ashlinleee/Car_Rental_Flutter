# Car Rental Backend API

A Node.js/Express REST API server for the Car Rental Booking application. This backend provides endpoints for managing cars, bookings, and categories.

## Features

- **RESTful API**: Clean and organized API endpoints
- **Car Management**: CRUD operations for car listings
- **Booking System**: Create, read, and cancel bookings
- **Search & Filter**: Advanced filtering by category, price, availability
- **Data Validation**: Input validation and error handling
- **CORS Support**: Cross-origin resource sharing enabled
- **Security**: Helmet middleware for security headers
- **Logging**: Request logging with Morgan

## API Endpoints

### Cars

- `GET /api/cars` - Get all cars (with optional filters)
- `GET /api/cars/:id` - Get car by ID
- `GET /api/categories` - Get all car categories

#### Query Parameters for `/api/cars`:

- `category` - Filter by car category
- `available` - Filter by availability (true/false)
- `minPrice` - Minimum price per day
- `maxPrice` - Maximum price per day
- `search` - Search by name, brand, or category

### Bookings

- `POST /api/bookings` - Create a new booking
- `GET /api/bookings` - Get all bookings
- `GET /api/bookings/:id` - Get booking by ID
- `DELETE /api/bookings/:id` - Cancel a booking

### Health Check

- `GET /health` - Server health status

## Installation

1. **Navigate to backend directory**

   ```bash
   cd backend
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Start the development server**

   ```bash
   npm run dev
   ```

   Or for production:

   ```bash
   npm start
   ```

The server will start on `http://localhost:3000`

## Dependencies

- **express**: Web framework for Node.js
- **cors**: Cross-origin resource sharing middleware
- **body-parser**: Body parsing middleware
- **helmet**: Security middleware
- **morgan**: HTTP request logger
- **uuid**: UUID generation for booking IDs

## Development Dependencies

- **nodemon**: Development server with auto-restart

## API Usage Examples

### Get All Cars

```bash
curl -X GET http://localhost:3000/api/cars
```

### Get Cars by Category

```bash
curl -X GET "http://localhost:3000/api/cars?category=SUV"
```

### Search Cars

```bash
curl -X GET "http://localhost:3000/api/cars?search=toyota"
```

### Create a Booking

```bash
curl -X POST http://localhost:3000/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "carId": "1",
    "customerName": "John Doe",
    "customerEmail": "john@example.com",
    "customerPhone": "+1234567890",
    "startDate": "2024-01-15",
    "endDate": "2024-01-20",
    "totalPrice": 229.95
  }'
```

## Response Format

All API responses follow this format:

```json
{
  "success": true,
  "data": {
    /* response data */
  },
  "message": "Optional message",
  "total": "Optional total count"
}
```

Error responses:

```json
{
  "success": false,
  "message": "Error message",
  "error": "Detailed error (in development)"
}
```

## Data Models

### Car Model

```json
{
  "id": "string",
  "name": "string",
  "brand": "string",
  "category": "string",
  "pricePerDay": "number",
  "imageUrl": "string",
  "seats": "number",
  "transmission": "string",
  "fuelType": "string",
  "rating": "number",
  "isAvailable": "boolean",
  "features": ["array of strings"],
  "description": "string"
}
```

### Booking Model

```json
{
  "id": "string",
  "carId": "string",
  "customerName": "string",
  "customerEmail": "string",
  "customerPhone": "string",
  "startDate": "Date",
  "endDate": "Date",
  "totalPrice": "number",
  "status": "string",
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

## Environment Variables

You can set these environment variables:

- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment mode (development/production)

## Development

### Scripts

- `npm start`: Start production server
- `npm run dev`: Start development server with nodemon
- `npm test`: Run tests (to be implemented)

### Adding New Endpoints

1. Define the route in `server.js`
2. Add validation and error handling
3. Update this README with the new endpoint

### Database Integration

Currently using in-memory storage. To integrate with a real database:

1. Install database driver (e.g., `mongoose` for MongoDB, `pg` for PostgreSQL)
2. Create database models
3. Replace in-memory arrays with database queries
4. Add connection configuration

## Security Features

- **Helmet**: Sets various HTTP headers for security
- **CORS**: Configured for cross-origin requests
- **Input Validation**: Basic validation on all endpoints
- **Error Handling**: Centralized error handling middleware

## Future Enhancements

- [ ] Database integration (MongoDB/PostgreSQL)
- [ ] Authentication & Authorization (JWT)
- [ ] Rate limiting
- [ ] API documentation (Swagger)
- [ ] Unit and integration tests
- [ ] Docker containerization
- [ ] Environment-based configuration
- [ ] Logging to files
- [ ] Payment integration
- [ ] Email notifications
- [ ] Car image upload
- [ ] Availability calendar
- [ ] Booking conflicts prevention
- [ ] Admin dashboard endpoints

## Testing

To test the API endpoints, you can use:

- **Postman**: Import the collection from `/docs/postman_collection.json`
- **cURL**: Use the examples provided above
- **Thunder Client**: VS Code extension for API testing
- **Insomnia**: REST client application

## Production Deployment

For production deployment:

1. Set `NODE_ENV=production`
2. Use a process manager like PM2
3. Set up reverse proxy (Nginx)
4. Configure SSL/TLS certificates
5. Set up monitoring and logging
6. Use a real database
7. Implement caching (Redis)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Make sure all tests pass
5. Submit a pull request

## License

This project is for educational purposes as part of the ITM Skills University Case Study 31.
