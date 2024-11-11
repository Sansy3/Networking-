import Foundation

public enum NetworkError: Error {
    case invalidURL
    case httpResponseError
    case statusCodeError(statusCode: Int)
    case noData
    case decodeError(error: Error)
}

public protocol NetworkServiceProtocol {
     func fetchData<T: Codable>(
        urlString: String,
        completion: @escaping @Sendable (Result<T, NetworkError>) -> Void
    )
}

public final class NetworkService: NetworkServiceProtocol {
    
    public init() { }
    
    public func fetchData<T: Codable>(urlString: String, completion: @escaping @Sendable (Result<T, NetworkError>) -> Void) {
        let url = URL(string: urlString)
        
        guard let url else {
            completion(.failure(.invalidURL))
            return
        }
        
        let urlRequest = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            let decoder = JSONDecoder()
            
            if let error {
                print(error)
                completion(.failure(.decodeError(error: error)))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(.httpResponseError))
                print(response as Any)
                return
            }
            
            guard (200...299).contains(response.statusCode) else {
                completion(.failure(.statusCodeError(statusCode: response.statusCode)))
                return
            }
            
            guard let data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let fetchedData = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(fetchedData))
                }
            } catch {
                print(error.localizedDescription)
                completion(.failure(.decodeError(error: error)))
            }
        }.resume()
    }
}
