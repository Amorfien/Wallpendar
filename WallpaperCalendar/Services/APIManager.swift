//
//  APIManager.swift
//  FSWP
//
//  Created by Pavel Grigorev on 24.02.2023.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case decodingError
}

final class APIManager {

    func getImage(width: CGFloat, height: CGFloat, mode: ImageMode, completion: @escaping (Result<Data, Error>) -> ()) {
        let tunnel = "https://"
        let server = "picsum.dev"
        let endpoint = "/\(Int(width))/\(Int(height))"
        let urlStr = tunnel + server + endpoint + mode.rawValue
        guard let apiURL = URL(string: urlStr) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var request = URLRequest(url: apiURL)
        request.cachePolicy = .reloadIgnoringCacheData
        request.timeoutInterval = 5
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data else {
                if let error {
                    completion(.failure(error))
                }
                return
            }
            completion(.success(data))
        }
        task.resume()
    }
}

enum ImageMode: String, CaseIterable {
    case standart = ""
    case grayscale = "?grayscale=1" // 0-1
    case blur1 = "?blur=3" // 0...10
    case blur2 = "?blur=7"

    var title: String {
        switch self {
        case .standart:
            return "Standart"
        case .grayscale:
            return "Grayscale"
        case .blur1:
            return "Weak Blur"
        case .blur2:
            return "Strong Blur"
        }
    }
}
