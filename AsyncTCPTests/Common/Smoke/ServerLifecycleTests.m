//
//  ServerLifecycleTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface ServerLifecycleTests : XCTestCase
{
    Server * server;
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
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testLifecycleState {
    XCTAssertFalse([server isRunning]);
    [server boot];
    NSPredicate * serverIsRunning = [NSPredicate predicateWithFormat:@"isRunning == true"];
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
@end
