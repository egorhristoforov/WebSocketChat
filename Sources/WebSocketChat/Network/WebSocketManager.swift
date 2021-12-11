//
//  WebSocketManager.swift
//  
//
//  Created by Egor on 11.12.2021.
//

import Foundation
import RxSwift

public protocol WebSocketManager {
    typealias SubscribeResult = Result<Data?, Error>
    
    func subscribe() -> Observable<SubscribeResult>
    func send(data: Data) -> Single<Void>
    func closeConnection()
}

final class DefaultWebSocketManager: NSObject, WebSocketManager {
    enum ManagerError: Error {
        case didCloseSession(URLSessionWebSocketTask.CloseCode)
        case unknownResult
    }
    
    private var session: URLSession!
    private var task: URLSessionWebSocketTask!
    
    private let messageSubject = PublishSubject<SubscribeResult>()
    
    init(
        urlRequest: URLRequest
    ) {
        super.init()
        
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        task = session.webSocketTask(with: urlRequest)
    }
    
    func subscribe() -> Observable<SubscribeResult> {
        task.resume()
        listen()
        
        return messageSubject.asObservable()
    }
    
    func send(data: Data) -> Single<Void> {
        return .create { [weak self] single in
            self?.task.send(.data(data)) { error in
                if let error = error {
                    single(.error(error))
                } else {
                    single(.success(()))
                }
            }
            
            return Disposables.create {}
        }
    }
    
    func closeConnection() {
        task.cancel(with: .goingAway, reason: nil)
    }
    
    private func listen() {
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(message):
                switch message {
                case let .data(data):
                    self.messageSubject.onNext(.success(data))
                case let .string(string):
                    self.messageSubject.onNext(.success(string.data(using: .utf8)))
                @unknown default:
                    self.messageSubject.onNext(.failure(ManagerError.unknownResult))
                }
            case let .failure(error):
                self.messageSubject.onNext(.failure(error))
            }
            
            self.listen()
        }
    }
}

extension DefaultWebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        messageSubject.onNext(.failure(ManagerError.didCloseSession(closeCode)))
    }
}

