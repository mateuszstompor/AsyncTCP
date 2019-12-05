//
//  ServerConfigurationTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 17/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface ServerConfigurationTests : XCTestCase
{
    Server * server;
}
@end

@implementation ServerConfigurationTests
-(void)setUp {
    ServerConfiguration * configuration = [[ServerConfiguration alloc] initWithPort:57880
                                                            maximalConnectionsCount:5
                                                                          chunkSize:40
                                                                  connectionTimeout:4
                                                         eventLoopMicrosecondsDelay:40
                                                      errorsBeforeConnectionClosing:3];
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testConfiguration {
    XCTAssertEqual([server configuration].chunkSize, 40);
    XCTAssertEqual([server configuration].connectionTimeout, 4);
    XCTAssertEqual([server configuration].eventLoopMicrosecondsDelay, 40);
    XCTAssertEqual([server configuration].maximalConnectionsCount, 5);
    XCTAssertEqual([server configuration].port, 57880);
    XCTAssertEqual([server configuration].errorsBeforeConnectionClosing, 3);
}
@end
