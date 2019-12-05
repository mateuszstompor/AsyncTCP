//
//  ServerLifecycleTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

#import "CountingThreadFactory.h"

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
    configuration.errorsBeforeConnectionClosing = 3;
    factory = [CountingThreadFactory new];
    server = [[Server alloc] initWithConfiguratoin:configuration
                                 notificationQueue:[Dispatch new]
                                    networkManager:[NetworkManager new]
                                     threadFactory:factory
                                       lockFactory:[ResourceLockFactory new]
                                     systemWrapper:[SystemWrapper new]];
}
-(void)testLifecycleState {
    XCTAssertFalse([server isRunning]);
    [server boot];
    NSPredicate * serverIsRunning = [NSPredicate predicateWithFormat:@"isRunning == YES"];
    [self waitForExpectations:@[[self expectationForPredicate:serverIsRunning
                                          evaluatedWithObject:server handler:nil]] timeout:10];
    [server shutDown:YES];
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
    [server shutDown:YES];
    XCTAssertEqual([server connectedClientsCount], 0);
}
-(void)testRepeatableBoots {
    XCTAssertEqual(factory.instancesCreated, 0);
    [server boot];
    XCTAssertEqual(factory.instancesCreated, 1);
    [server boot];
    XCTAssertEqual(factory.instancesCreated, 1);
    for(int i=0; i<RETRIES; ++i) {
        [server boot];
    }
    XCTAssertEqual(factory.instancesCreated, 1);
    [server shutDown:YES];
    XCTAssertEqual(factory.instancesCreated, 1);
}
-(void)testRepeatableShutdowns {
    XCTAssertEqual(factory.instancesCreated, 0);
    [server boot];
    XCTAssertEqual(factory.instancesCreated, 1);
    for(int i=0; i<RETRIES; ++i) {
        [server shutDown:YES];
    }
    XCTAssertEqual(factory.instancesCreated, 1);
}
-(void)testShutdownWithoutBoot {
    @try {
        [server shutDown:NO];
        [server shutDown:YES];
    } @catch (NSException *exception) {
        XCTFail("An exception was raised while shuting down not running server");
    }
}
@end
