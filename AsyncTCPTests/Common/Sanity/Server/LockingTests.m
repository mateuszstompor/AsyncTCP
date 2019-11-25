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
-(void)clientHasDisconnected:(Connection *)connection { }
@end

@implementation CountingLock
-(void)aquireLock {
    [super aquireLock];
    _aquireCounts += 1;
}
-(void)releaseLock {
    _releaseCounts += 1;
    [super releaseLock];
}
@end

@interface LockFactoryMock: NSObject<LockProducible>
{
    NSObject<Lockable>* lock;
    int count;
}
-(instancetype)initWithLock: (NSObject<Lockable>*) lock;
@end

@implementation LockFactoryMock
-(instancetype)initWithLock: (NSObject<Lockable>*) lock {
    self = [super init];
    if (self) {
        self->lock = lock;
        self->count = 0;
    }
    return self;
}
-(NSObject<Lockable> *)newLock {
    ++count;
    if (count == 1) {
        return lock;
    } else {
        return [ResourceLock new];
    }
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
    serverHandler = [[ServerHandlerLocks alloc]
                     initWithConnectionHandler:[ConnectionHandlerLocks new]];
    server = [[Server alloc] initWithConfiguratoin:configuration
                                 notificationQueue:[Dispatch new]
                                    networkManager:[NetworkManager new]
                                     threadFactory:[ThreadFactory new]
                                       lockFactory:[[LockFactoryMock alloc] initWithLock: serverLock]];
    server.delegate = serverHandler;
}
-(void)testLifeCycle {
    [serverLock aquireLock];
    XCTAssertEqual(serverLock.releaseCounts + 1, serverLock.aquireCounts);
    [serverLock releaseLock];
    [server boot];
    [serverLock aquireLock];
    XCTAssertEqual(serverLock.releaseCounts + 1, serverLock.aquireCounts);
    [serverLock releaseLock];
    [server shutDown:YES];
    [serverLock aquireLock];
    XCTAssertEqual(serverLock.releaseCounts + 1, serverLock.aquireCounts);
    [serverLock releaseLock];
}
-(void)testAfterClientConnects {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"127.0.0.1" port:8092];
    [server boot];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [serverLock aquireLock];
    XCTAssertEqual(serverLock.releaseCounts + 1, serverLock.aquireCounts);
    [serverLock releaseLock];
    [client close];
    [server shutDown:YES];
    [serverLock aquireLock];
    XCTAssertEqual(serverLock.releaseCounts + 1, serverLock.aquireCounts);
    [serverLock releaseLock];
}
-(void)testAfterSendingDataFromClient {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"127.0.0.1" port:8092];
    [server boot];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [client send:"hello" length:5];
    [serverLock aquireLock];
    XCTAssertEqual(serverLock.releaseCounts + 1, serverLock.aquireCounts);
    [serverLock releaseLock];
    [client close];
    [server shutDown:YES];
}
@end
