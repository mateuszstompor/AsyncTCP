//
//  ClientLifeCycleTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

#import "CountingThreadFactory.h"

@interface ClientLifeCycleTests : XCTestCase
{
    Client * client;
    CountingThreadFactory * threadFactory;
}
@end

@implementation ClientLifeCycleTests
-(void)setUp {
    ClientConfiguration * configuration = [[ClientConfiguration alloc] initWithAddress:@"localhost"
                                                                                  port:5001
                                                                             chunkSize:50
                                                                     connectionTimeout:5
                                                            eventLoopMicrosecondsDelay:40];
    threadFactory = [CountingThreadFactory new];
    client = [[Client alloc] initWithConfiguration:configuration
                                 notificationQueue:[Dispatch new]
                                    networkManager:[NetworkManager new]
                                       lockFactory:[ResourceLockFactory new]
                                     threadFactory:threadFactory
                                     systemWrapper: [SystemWrapper new]];
}
-(void)testLifecycleState {
    XCTAssertFalse([client isRunning]);
    [client boot];
    NSPredicate * clientIsRunning = [NSPredicate predicateWithFormat:@"isRunning == YES"];
    [self waitForExpectations:@[[self expectationForPredicate:clientIsRunning
                                          evaluatedWithObject:client handler:nil]] timeout:10];
    [client shutDown: YES];
    NSPredicate * clientIsStopped = [NSPredicate predicateWithFormat:@"isRunning == NO"];
    [self waitForExpectations:@[[self expectationForPredicate:clientIsStopped
                                          evaluatedWithObject:client handler:nil]] timeout:10];
}
-(void)testMultipleBoots {
    XCTAssertEqual(threadFactory.instancesCreated, 0);
    for(int i=0; i<RETRIES; ++i) {
        [client boot];
    }
    XCTAssertEqual(threadFactory.instancesCreated, 1);
    [client shutDown: YES];
}
-(void)testMultipleLifeCycles {
    for(int i=0; i<RETRIES; ++i) {
        XCTAssertEqual(threadFactory.instancesCreated, i);
        [client boot];
        XCTAssertEqual(threadFactory.instancesCreated, i+1);
        [client shutDown:YES];
    }
}
-(void)testMultipleShutdowns {
    [client boot];
    for(int i=0; i<RETRIES; ++i) {
        [client shutDown: YES];
    }
}
@end
