//
//  ClientConfigurationTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 17/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface ClientConfigurationTests : XCTestCase
{
    Client * client;
}
@end

@implementation ClientConfigurationTests
-(void)setUp {
    ClientConfiguration * configuration = [[ClientConfiguration alloc] initWithAddress:@"localhost"
                                                                                  port:57800
                                                                             chunkSize:30
                                                                     connectionTimeout:5
                                                            eventLoopMicrosecondsDelay:40
                                                         errorsBeforeConnectionClosing:3];
    client = [[Client alloc] initWithConfiguration:configuration];
}
-(void)testConfiguration {
    XCTAssertTrue([[client configuration].address isEqualToString:@"localhost"]);
    XCTAssertEqual([client configuration].port, 57800);
    XCTAssertEqual([client configuration].chunkSize, 30);
    XCTAssertEqual([client configuration].connectionTimeout, 5);
    XCTAssertEqual([client configuration].eventLoopMicrosecondsDelay, 40);
    XCTAssertEqual([client configuration].errorsBeforeConnectionClosing, 3);
}
@end
