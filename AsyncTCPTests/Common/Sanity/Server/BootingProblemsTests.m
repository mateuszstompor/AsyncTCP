//
//  BootingProblemsTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 22/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface BootingProblemsTests : XCTestCase
{
    Server * server;
    ServerConfiguration * configuration;
}
@end

@implementation BootingProblemsTests
-(void)setUp {
    configuration = [[ServerConfiguration alloc] initWithPort:8091
                                      maximalConnectionsCount:1
                                                    chunkSize:10
                                            connectionTimeout:5
                                   eventLoopMicrosecondsDelay:10
                                errorsBeforeConnectionClosing:3];
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testBootingTwoServerOnTheSamePort {
    Server * serverB = [[Server alloc] initWithConfiguratoin: configuration];
    [server boot];
    @try {
        [serverB boot];
    } @catch (BootingException * exception) {
        XCTFail("Booting should not raise exception if the same port is used");
    }
    [serverB shutDown:YES];
    [server shutDown:YES];
}
@end
