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

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error, responseBody: String?)
    case encodingError(Error)
    case emptyResponse(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid HTTP response"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .decodingError(let error, let responseBody):
            var message = "Failed to decode response: \(error.localizedDescription)"
            if let body = responseBody, !body.isEmpty {
                message += "\n\nResponse body:\n\(body)"
            }
            return message
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .emptyResponse(let statusCode):
            return "Received empty response body with status code: \(statusCode)"
        }
    }
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:3000/api/v0"
    
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
        
        // Handle empty response body
        guard !data.isEmpty else {
            throw APIError.emptyResponse(statusCode: httpResponse.statusCode)
        }
        
        // Capture response body as string for error messages
        let responseBodyString = String(data: data, encoding: .utf8)
        
        do {
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase since models have explicit CodingKeys
            return try decoder.decode(U.self, from: data)
        } catch {
            // Include response body in error for debugging
            throw APIError.decodingError(error, responseBody: responseBodyString)
        }
    }
    
    // Request without body
    func request<U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        queryParameters: [String: String]? = nil,
        responseType: U.Type
    ) async throws -> U {
        // Build URL with query parameters
        guard var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        // Add query parameters if provided
        if let queryParameters = queryParameters, !queryParameters.isEmpty {
            urlComponents.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = urlComponents.url else {
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
        
        // Handle empty response body
        guard !data.isEmpty else {
            throw APIError.emptyResponse(statusCode: httpResponse.statusCode)
        }
        
        // Capture response body as string for error messages
        let responseBodyString = String(data: data, encoding: .utf8)
        
        do {
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase since models have explicit CodingKeys
            return try decoder.decode(U.self, from: data)
        } catch {
            // Include response body in error for debugging
            throw APIError.decodingError(error, responseBody: responseBodyString)
        }
    }
    
    // MARK: - Convenience Methods
    
    func get<U: Codable>(endpoint: String, responseType: U.Type) async throws -> U {
        return try await request(endpoint: endpoint, method: .get, responseType: responseType)
    }
    
    func get<U: Codable>(endpoint: String, queryParameters: [String: String]?, responseType: U.Type) async throws -> U {
        return try await request(endpoint: endpoint, method: .get, queryParameters: queryParameters, responseType: responseType)
    }
    
    func post<T: Codable, U: Codable>(endpoint: String, body: T, responseType: U.Type) async throws -> U {
        return try await request(endpoint: endpoint, method: .post, body: body, responseType: responseType)
    }
    
    func patch<T: Codable, U: Codable>(endpoint: String, body: T, responseType: U.Type) async throws -> U {
        return try await request(endpoint: endpoint, method: .patch, body: body, responseType: responseType)
    }
    
    func delete(endpoint: String) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.delete.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // TODO: Add Bearer token authentication
        // if let token = authToken {
        //     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // DELETE typically returns 200 OK, 204 No Content, or 204 with empty body
        // All of these are valid success responses
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        // Note: Empty response body is expected and valid for DELETE requests
    }
}

