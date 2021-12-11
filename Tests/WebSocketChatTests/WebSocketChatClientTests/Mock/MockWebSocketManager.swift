//
//  MockWebSocketManager.swift
//  
//
//  Created by Egor on 11.12.2021.
//

import Foundation
import RxSwift
import WebSocketChat

final class MockWebSocketManager {
    private let subject = PublishSubject<SubscribeResult>()
    
    var didCloseConnection = false
    
    func simulate(json: String?) {
        let data = json?.data(using: .utf8)
        subject.onNext(.success(data))
    }
    
    func simulate(error: Error) {
        subject.onNext(.failure(error))
    }
}

extension MockWebSocketManager: WebSocketManager {
    func subscribe() -> Observable<SubscribeResult> {
        return subject.asObservable()
    }
    
    func send(data: Data) -> Single<Void> {
        return .just(())
    }
    
    func closeConnection() {
        didCloseConnection = true
    }
}
