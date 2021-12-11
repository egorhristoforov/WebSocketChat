//
//  WebSocketChatClient.swift
//  
//
//  Created by Egor on 11.12.2021.
//

import Foundation
import RxSwift

public protocol WebSocketChatClientProtocol {
    associatedtype ReceiveMessage
    associatedtype SendMessage
    
    typealias SubscribeResult = Result<ReceiveMessage, Error>
    
    func subscribe() -> Observable<SubscribeResult>
    func send(message: SendMessage) -> Single<Void>
    func closeConnection()
}

public final class WebSocketChatClient<ReceiveMessage: Decodable, SendMessage: Encodable>: WebSocketChatClientProtocol {
    public enum ClientError: Error {
        case decodeError
        case encodeError
    }
    
    private let webSocketManager: WebSocketManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    public init(
        urlRequest: URLRequest,
        decoder: JSONDecoder,
        encoder: JSONEncoder
    ) {
        webSocketManager = DefaultWebSocketManager(urlRequest: urlRequest)
        self.decoder = decoder
        self.encoder = encoder
    }
    
    init(
        webSocketManager: WebSocketManager,
        decoder: JSONDecoder,
        encoder: JSONEncoder
    ) {
        self.webSocketManager = webSocketManager
        self.decoder = decoder
        self.encoder = encoder
    }
    
    public func subscribe() -> Observable<SubscribeResult> {
        let decoder = self.decoder
        
        let convertData: (Data?) -> ReceiveMessage? = {
            guard let data = $0 else { return nil }
            return try? decoder.decode(ReceiveMessage.self, from: data)
        }
        
        return webSocketManager.subscribe()
            .map { result -> SubscribeResult in
                switch result {
                case let .success(data):
                    guard let message = convertData(data) else {
                        return .failure(ClientError.decodeError)
                    }
                    
                    return .success(message)
                case let .failure(error):
                    return .failure(error)
                }
            }
    }
    
    public func send(
        message: SendMessage
    ) -> Single<Void> {
        guard let data = try? encoder.encode(message) else {
            return .error(ClientError.encodeError)
        }
        
        return webSocketManager.send(data: data)
    }
    
    public func closeConnection() {
        webSocketManager.closeConnection()
    }
}
