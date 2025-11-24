# MVP - Tech Stack & Technical Decisions

## Tech Stack

### Backend
- **Framework**: Ruby on Rails (REST API with JSON)
- **Repository**: Separate repository (`rails-api`)

### Frontend
- **Framework**: Swift/SwiftUI/SwiftData
- **Platform**: iOS (iPhone only for MVP)
- **Repository**: Separate repository (`swift-app`)
- **Data persistence**: SwiftData with API sync

### Development Approach
Start with Swift app using mock data, then connect to Rails API. This approach helps identify required API endpoints early.

## Technical Decisions

1. **Authentication**: No authentication for MVP (single user)
2. **Data entry**: Manual entry only (bank integration planned for future)
3. **API communication**: REST API with JSON
4. **Data sync**: Requires internet connection for MVP
5. **Project structure**: Separate repositories for Rails API and Swift app

## Decision Log
*Decision-making process will be documented here as features are developed*

