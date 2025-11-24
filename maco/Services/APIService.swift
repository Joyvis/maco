//
//  APIService.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:3000/api/v1"
    
    // TODO: Add Bearer token authentication
    // private var authToken: String?
    
    private init() {}
    
    // MARK: - Generic Request Methods
    
    // Request with body
    func request<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T,
        responseType: U.Type
    ) async throws -> U {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // TODO: Add Bearer token authentication
        // if let token = authToken {
        //     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // }
        
        do {
            let encoder = JSONEncoder()
            // Using CodingKeys explicitly in request models for exact format control
            // Format: { "entity_name": { "attr1": "value" } }
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(U.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // Request without body
    func request<U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        responseType: U.Type
    ) async throws -> U {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // TODO: Add Bearer token authentication
        // if let token = authToken {
        //     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(U.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Convenience Methods
    
    func get<U: Codable>(endpoint: String, responseType: U.Type) async throws -> U {
        return try await request(endpoint: endpoint, method: .get, responseType: responseType)
    }
    
    func post<T: Codable, U: Codable>(endpoint: String, body: T, responseType: U.Type) async throws -> U {
        return try await request(endpoint: endpoint, method: .post, body: body, responseType: responseType)
    }
    
    func patch<T: Codable, U: Codable>(endpoint: String, body: T, responseType: U.Type) async throws -> U {
        return try await request(endpoint: endpoint, method: .patch, body: body, responseType: responseType)
    }
}

