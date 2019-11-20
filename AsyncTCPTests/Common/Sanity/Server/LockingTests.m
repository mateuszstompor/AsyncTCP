//
//  LockingTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

#import "Dispatch.h"
#import "TCPTestsClient.h"

@interface CountingLock: ResourceLock
@property (atomic) int aquireCounts;
@property (atomic) int releaseCounts;
@end

@interface ConnectionHandlerLocks: NSObject<ConnectionDelegate>
@end

@implementation ConnectionHandlerLocks
-(void)connection:(NSObject<ConnectionHandle> *)connection chunkHasArrived:(NSData *)data { }
-(void)connection:(NSObject<ConnectionHandle> *)connection stateHasChangedTo:(ConnectionState)state { }
@end

@interface ServerHandlerLocks: NSObject<ServerDelegate>
{
    NSObject<ConnectionDelegate>* connectionHandler;
}
-(instancetype)initWithConnectionHandler: (NSObject<ConnectionDelegate>*) connectionHandler;
@end

@implementation ServerHandlerLocks
-(instancetype)initWithConnectionHandler: (NSObject<ConnectionDelegate>*) connectionHandler {
    self = [super init];
    if (self) {
        self->connectionHandler = connectionHandler;
    }
    return self;
}
-(void)newClientHasConnected: (Connection *)connection {
    connection.delegate = connectionHandler;
}
@end

@implementation CountingLock
-(void)aquireLock {
    [super aquireLock];
    _aquireCounts += 1;
}
-(void)releaseLock {
    [super releaseLock];
    _releaseCounts += 1;
}
@end

@interface LockingTests : XCTestCase
{
    Server * server;
    CountingLock * serverLock;
    ServerHandlerLocks * serverHandler;
}
@end

@implementation LockingTests
-(void)setUp {
    struct ServerConfiguration configuration;
    configuration.port = 8092;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 10;
    configuration.connectionTimeout = 5;
    configuration.chunkSize = 1;
    serverLock = [CountingLock new];
    serverHandler = [[ServerHandlerLocks alloc] initWithConnectionHandler:[ConnectionHandlerLocks new]];
    server = [[Server alloc] initWithConfiguratoin:configuration
                                 notificationQueue:[[Dispatch alloc] initWithDispatchQueue: dispatch_get_main_queue()]
                                    networkManager:[NetworkManager new]
                                      resourceLock:serverLock
                                     threadFactory:[ThreadFactory new]];
    server.delegate = serverHandler;
}
-(void)testLifeCycle {
    XCTAssertEqual(serverLock.aquireCounts, 0);
    XCTAssertEqual(serverLock.aquireCounts, serverLock.releaseCounts);
    [server boot];
    XCTAssertNotEqual(serverLock.aquireCounts, 0);
    XCTAssertEqual(serverLock.releaseCounts, serverLock.aquireCounts);
    [server shutDown];
    XCTAssertEqual(serverLock.releaseCounts, serverLock.aquireCounts);
}
-(void)testAfterClientConnects {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"127.0.0.1" port:8092];
    [server boot];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    XCTAssertEqual(serverLock.releaseCounts, serverLock.aquireCounts);
    [client close];
    [server shutDown];
    XCTAssertEqual(serverLock.releaseCounts, serverLock.aquireCounts);
}
-(void)testAfterSendingDataFromClient {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"127.0.0.1" port:8092];
    [server boot];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [client send:"hello" length:5];
    XCTAssertEqual(serverLock.releaseCounts, serverLock.aquireCounts);
    [client close];
    [server shutDown];
}
@end
