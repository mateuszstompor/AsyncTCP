//
//  ServerLifecycleTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface CountingThreadFactory: ThreadFactory
@property (atomic) int instancesCreated;
@end

@implementation CountingThreadFactory
-(NSObject<Threadable> *)createNewThreadWithTarget:(id)target selector:(SEL)selector name: (NSString *) name {
    id newThread = [super createNewThreadWithTarget:target selector:selector name: name];
    _instancesCreated += 1;
    return newThread;
}
@end


@interface ServerLifecycleTests: XCTestCase
{
    Server * server;
    CountingThreadFactory * factory;
}
@end

@implementation ServerLifecycleTests
-(void)setUp {
    struct ServerConfiguration configuration;
    configuration.port = 5005;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 2;
    configuration.connectionTimeout = 3;
    configuration.chunkSize = 50;
    factory = [CountingThreadFactory new];
    server = [[Server alloc] initWithConfiguratoin:configuration
                                 notificationQueue:[Dispatch new]
                                    networkManager:[NetworkManager new]
                                     threadFactory:factory
                                       lockFactory:[ResourceLockFactory new]];
}
-(void)testLifecycleState {
    XCTAssertFalse([server isRunning]);
    [server boot];
    NSPredicate * serverIsRunning = [NSPredicate predicateWithFormat:@"isRunning == YES"];
    [self waitForExpectations:@[[self expectationForPredicate:serverIsRunning
                                          evaluatedWithObject:server handler:nil]] timeout:10];
    [server shutDown];
    NSPredicate * serverIsStopped = [NSPredicate predicateWithFormat:@"isRunning == NO"];
    [self waitForExpectations:@[[self expectationForPredicate:serverIsStopped
                                          evaluatedWithObject:server handler:nil]] timeout:10];
}
-(void)testConnectedClientsCountAfterBoot {
    XCTAssertEqual([server connectedClientsCount], 0);
    [server boot];
    NSPredicate * connectedClientsCount = [NSPredicate predicateWithFormat:@"connectedClientsCount == 0"];
    [self waitForExpectations:@[[self expectationForPredicate:connectedClientsCount
                                          evaluatedWithObject:server handler:nil]] timeout:10];
    [server shutDown];
    XCTAssertEqual([server connectedClientsCount], 0);
}
-(void)testRepeatableBoots {
    XCTAssertEqual(factory.instancesCreated, 0);
    [server boot];
    XCTAssertEqual(factory.instancesCreated, 1);
    [server boot];
    XCTAssertEqual(factory.instancesCreated, 1);
    [server boot];
    [server boot];
    [server boot];
    XCTAssertEqual(factory.instancesCreated, 1);
    [server shutDown];
    XCTAssertEqual(factory.instancesCreated, 1);
}
-(void)testRepeatableShutdowns {
    XCTAssertEqual(factory.instancesCreated, 0);
    [server boot];
    XCTAssertEqual(factory.instancesCreated, 1);
    [server shutDown];
    [server shutDown];
    [server shutDown];
    [server shutDown];
    XCTAssertEqual(factory.instancesCreated, 1);
}
@end
