//
//  WebSocketChatClientTests.swift
//  
//
//  Created by Egor on 11.12.2021.
//

import XCTest
import RxSwift
import RxTest
@testable import WebSocketChat

final class WebSocketChatClientTests: XCTestCase {
    static var allTests = [
        ("testReceiveSimpleJSON", testReceiveSimpleJSON),
        ("testReceiveSimpleJSONOptional", testReceiveSimpleJSONOptional),
        ("testReceiveComplexJSON", testReceiveComplexJSON),
        ("testReceiveInvalidJSON", testReceiveInvalidJSON),
        ("testReceiveNetworkError", testReceiveNetworkError),
        ("testDidCloseConnectionManually", testDidCloseConnectionManually),
        ("testSendSimpleJSON", testSendSimpleJSON),
    ]
    
    private var mockWebSocketManager: MockWebSocketManager!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!
    
    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
        mockWebSocketManager = MockWebSocketManager()
        disposeBag = DisposeBag()
    }
    
    func testReceiveSimpleJSON() {
        // Setup
        struct SimpleJSONExample: Decodable, Equatable {
            let messageText: String
        }
        
        struct SendType: Encodable {}
        
        typealias ReceiveType = SimpleJSONExample
        
        let client = WebSocketChatClient<ReceiveType, SendType>(
            webSocketManager: mockWebSocketManager,
            decoder: .default,
            encoder: .default
        )
        
        // Received messages
        let messages = scheduler.createObserver(ReceiveType.self)
        
        client.subscribe()
            .compactMap { result -> ReceiveType? in
                if case let .success(message) = result {
                    return message
                } else {
                    return nil
                }
            }
            .subscribe(onNext: { message in
                messages.onNext(message)
            })
            .disposed(by: disposeBag)
        
        // Send MOCK messages
        simulateJSONEvents(
            events: [
                .next(
                    10,
                    """
                    {
                    \"message_text\": \"test\"
                    }
                    """
                ),
                .next(
                    20,
                    """
                    {
                    \"message_text\": \"\"
                    }
                    """
                ),
            ]
        )
        
        scheduler.start()

        XCTAssertEqual(messages.events, [
            .next(10, SimpleJSONExample(messageText: "test")),
            .next(20, SimpleJSONExample(messageText: "")),
        ])
    }
    
    func testReceiveSimpleJSONOptional() {
        // Setup
        struct SimpleJSONExample: Decodable, Equatable {
            let messageText: String?
        }
        
        struct SendType: Encodable {}
        
        typealias ReceiveType = SimpleJSONExample
        
        let client = WebSocketChatClient<ReceiveType, SendType>(
            webSocketManager: mockWebSocketManager,
            decoder: .default,
            encoder: .default
        )
        
        // Received messages
        let messages = scheduler.createObserver(ReceiveType.self)
        
        client.subscribe()
            .compactMap { result -> ReceiveType? in
                if case let .success(message) = result {
                    return message
                } else {
                    return nil
                }
            }
            .subscribe(onNext: { message in
                messages.onNext(message)
            })
            .disposed(by: disposeBag)
        
        // Send MOCK messages
        simulateJSONEvents(
            events: [
                .next(
                    10,
                    """
                    {
                    \"message_text\": \"test123\"
                    }
                    """
                ),
                .next(
                    20,
                    """
                    {}
                    """
                ),
            ]
        )
        
        scheduler.start()

        XCTAssertEqual(messages.events, [
            .next(10, SimpleJSONExample(messageText: "test123")),
            .next(20, SimpleJSONExample(messageText: nil)),
        ])
    }
    
    func testReceiveComplexJSON() {
        // Setup
        struct ComplexJSONExample: Decodable, Equatable {
            struct Tag: Decodable, Equatable {
                let id: Int
                let name: String
            }
            
            struct Coordinate: Decodable, Equatable {
                let longitude: Double
                let latitude: Double
            }
            
            let id: Int
            let senderName: String
            let date: Date
            let text: String
            let tags: [Tag]
            let coordinate: Coordinate
        }
        
        struct SendType: Encodable {}
        
        typealias ReceiveType = ComplexJSONExample
        
        let client = WebSocketChatClient<ReceiveType, SendType>(
            webSocketManager: mockWebSocketManager,
            decoder: .default,
            encoder: .default
        )
        
        // Received messages
        let messages = scheduler.createObserver(ReceiveType.self)
        
        client.subscribe()
            .compactMap { result -> ReceiveType? in
                if case let .success(message) = result {
                    return message
                } else {
                    return nil
                }
            }
            .subscribe(onNext: { message in
                messages.onNext(message)
            })
            .disposed(by: disposeBag)
        
        // Send MOCK messages
        simulateJSONEvents(
            events: [
                .next(
                    10,
                    """
                    {
                        \"id\": 123,
                        \"sender_name\": \"Egor Hristoforov\",
                        \"date\": \"2021-12-11T20:13:44+0000\",
                        \"text\": \"Hello, World!\",
                        \"tags\": [
                            {
                                \"id\": 1,
                                \"name\": "Tag 1"
                            },
                            {
                                \"id\": 2,
                                \"name\": "Tag 2"
                            }
                        ],
                        \"coordinate\": {
                            \"longitude\": 1.23,
                            \"latitude\": 3.21
                        }
                    }
                    """
                ),
            ]
        )
        
        scheduler.start()

        XCTAssertEqual(messages.events, [
            .next(
                10,
                ComplexJSONExample(
                    id: 123,
                    senderName: "Egor Hristoforov",
                    date: createDate(year: 2021, month: 12, day: 11, hour: 20, minute: 13, second: 44),
                    text: "Hello, World!",
                    tags: [
                        .init(id: 1, name: "Tag 1"),
                        .init(id: 2, name: "Tag 2"),
                    ],
                    coordinate: .init(
                        longitude: 1.23,
                        latitude: 3.21
                    )
                )
            )
        ])
    }
    
    func testReceiveInvalidJSON() {
        // Setup
        struct SimpleJSONExample: Decodable, Equatable {
            let messageText: String
        }
        
        struct SendType: Encodable {}
        
        typealias ReceiveType = SimpleJSONExample
        
        let client = WebSocketChatClient<ReceiveType, SendType>(
            webSocketManager: mockWebSocketManager,
            decoder: .default,
            encoder: .default
        )
        
        // Received messages
        let messages = scheduler.createObserver(Error.self)
        
        client.subscribe()
            .compactMap { result -> Error? in
                if case let .failure(error) = result {
                    return error
                } else {
                    return nil
                }
            }
            .subscribe(onNext: { error in
                messages.onNext(error)
            })
            .disposed(by: disposeBag)
        
        // Send MOCK messages
        simulateJSONEvents(
            events: [
                .next(
                    10,
                    """
                    {
                    \"wrong_param_name\": \"test\"
                    }
                    """
                ),
                .next(
                    20,
                    """
                    {}
                    """
                ),
            ]
        )
        
        scheduler.start()

        XCTAssertEqual(messages.events.count, 2)
        
        messages.events.forEach { event in
            guard let error = event.value.element as? WebSocketChatClient<ReceiveType, SendType>.ClientError,
                  error == .decodeError
            else {
                XCTFail()
                return
            }
        }
    }
    
    func testReceiveNetworkError() {
        // Setup
        struct SimpleJSONExample: Decodable, Equatable {
            let messageText: String
        }
        
        struct SendType: Encodable {}
        
        typealias ReceiveType = SimpleJSONExample
        
        let client = WebSocketChatClient<ReceiveType, SendType>(
            webSocketManager: mockWebSocketManager,
            decoder: .default,
            encoder: .default
        )
        
        // Received messages
        let messages = scheduler.createObserver(Error.self)
        
        client.subscribe()
            .compactMap { result -> Error? in
                if case let .failure(error) = result {
                    return error
                } else {
                    return nil
                }
            }
            .subscribe(onNext: { error in
                messages.onNext(error)
            })
            .disposed(by: disposeBag)
        
        // Send MOCK messages
        simulateErrorEvents(
            events: [
                .next(10, NSError(domain: "WebSocketChatClientTests.Error1", code: 1, userInfo: nil)),
                .next(20, DefaultWebSocketManager.ManagerError.didCloseSession(.internalServerError)),
                .next(30, DefaultWebSocketManager.ManagerError.unknownResult),
            ]
        )
        
        scheduler.start()

        XCTAssertEqual(messages.events.count, 3)
        
        guard let error1 = messages.events[0].value.element.flatMap({ $0 as NSError }),
              error1.domain == "WebSocketChatClientTests.Error1"
        else {
            XCTFail()
            return
        }
        
        guard let error2 = messages.events[1].value.element as? DefaultWebSocketManager.ManagerError,
              error2 == .didCloseSession(.internalServerError)
        else {
            XCTFail()
            return
        }
        
        guard let error3 = messages.events[2].value.element as? DefaultWebSocketManager.ManagerError,
              error3 == .unknownResult
        else {
            XCTFail()
            return
        }
    }
    
    func testDidCloseConnectionManually() {
        // Setup
        struct SimpleJSONExample: Decodable, Equatable {
            let messageText: String
        }
        
        struct SendType: Encodable {}
        
        typealias ReceiveType = SimpleJSONExample
        
        let client = WebSocketChatClient<ReceiveType, SendType>(
            webSocketManager: mockWebSocketManager,
            decoder: .default,
            encoder: .default
        )
        
        XCTAssertFalse(mockWebSocketManager.didCloseConnection)
        client.closeConnection()
        XCTAssertTrue(mockWebSocketManager.didCloseConnection)
    }
    
    func testSendSimpleJSON() {
        // Setup
        struct ReceiveType: Decodable {}
        
        struct SimpleJSONExample: Encodable, Equatable {
            let message: String
        }
        
        typealias SendType = SimpleJSONExample
        
        let client = WebSocketChatClient<ReceiveType, SendType>(
            webSocketManager: mockWebSocketManager,
            decoder: .default,
            encoder: .default
        )
        
        // Success send results
        let messages = scheduler.createObserver(Void.self)
        
        // Simulate user sends message
        scheduler.createColdObservable([
            .next(10, SimpleJSONExample(message: "test 123")),
            .next(20, SimpleJSONExample(message: "Hello, World!")),
        ])
        .flatMap { message in
            client.send(message: message)
        }
        .subscribe(onNext: { _ in
            messages.onNext(())
        }, onError: { error in
            messages.onError(error)
        })
        .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(messages.events.count, 2)
        
        messages.events.forEach {
            guard case .next = $0.value else {
                XCTFail()
                return
            }
        }
    }
}

extension WebSocketChatClientTests {
    private func simulateJSONEvents(events: [Recorded<Event<String>>]) {
        scheduler.createColdObservable(events)
            .subscribe { event in
                self.mockWebSocketManager.simulate(json: event.element)
            }.disposed(by: disposeBag)
    }
    
    private func simulateErrorEvents(events: [Recorded<Event<Error>>]) {
        scheduler.createColdObservable(events)
            .subscribe { event in
                guard let error = event.element else { return }
                self.mockWebSocketManager.simulate(error: error)
            }.disposed(by: disposeBag)
    }
    
    private func createDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int
    ) -> Date {
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(abbreviation: "UTC")
        components.hour = hour
        components.minute = minute
        components.second = second

        let calendar = Calendar(identifier: .gregorian)
        
        return calendar.date(from: components)!
    }
}

extension DefaultWebSocketManager.ManagerError: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.unknownResult, .unknownResult):
            return true
        case let (.didCloseSession(lhsCode), .didCloseSession(rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
}
