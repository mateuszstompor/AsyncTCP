//
//  StateTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 04/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface StateTests: XCTestCase
{
    Client * client;
}
@end

@implementation StateTests
-(void)setUp {
    ClientConfiguration * configuration = [[ClientConfiguration alloc] initWithAddress:@"localhost"
                                                                                  port:5001
                                                                             chunkSize:50
                                                                     connectionTimeout:5
                                                            eventLoopMicrosecondsDelay:50
                                                         errorsBeforeConnectionClosing:3];
    client = [[Client alloc] initWithConfiguration:configuration];
}
-(void)testInitialState {
    XCTAssertFalse([client isRunning]);
    [client boot];
    NSPredicate * clientRunning = [NSPredicate predicateWithFormat:@"isRunning == YES"];
    [self waitForExpectations:@[[self expectationForPredicate:clientRunning
                                          evaluatedWithObject:client
                                                      handler:nil]] timeout:10];
    [client shutDown:YES];
    XCTAssertFalse([client isRunning]);
}
@end
