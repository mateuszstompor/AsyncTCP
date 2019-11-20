//
//  ClientLifeCycleTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface ClientLifeCycleTests : XCTestCase
{
    Client * client;
}
@end

@implementation ClientLifeCycleTests
-(void)setUp {
    struct ClientConfiguration configuration;
    configuration.port = 5001;
    configuration.eventLoopMicrosecondsDelay = 50;
    configuration.connectionTimeout = 5;
    configuration.chunkSize = 50;
    configuration.address = "localhost";
    client = [[Client alloc] initWithConfiguration:configuration];
}
-(void)testLifecycleState {
    XCTAssertFalse([client isRunning]);
    [client boot];
    NSPredicate * clientIsRunning = [NSPredicate predicateWithFormat:@"isRunning == YES"];
    [self waitForExpectations:@[[self expectationForPredicate:clientIsRunning
                                          evaluatedWithObject:client handler:nil]] timeout:10];
    [client shutDown];
    NSPredicate * clientIsStopped = [NSPredicate predicateWithFormat:@"isRunning == NO"];
    [self waitForExpectations:@[[self expectationForPredicate:clientIsStopped
                                          evaluatedWithObject:client handler:nil]] timeout:10];
    
}
@end
