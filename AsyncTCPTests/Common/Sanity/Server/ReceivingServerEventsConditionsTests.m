//
//  ReceivingServerEventsConditionsTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

#import "TCPTestsClient.h"

@interface ReceivingServerEventsHandler: NSObject<ServerDelegate>
{
    XCTestExpectation * clientConnectedExpectation;
    XCTestExpectation * clientDisconnectedExpectation;
}
-(instancetype)initWithClientConnectedExpectation: (XCTestExpectation*) clientConnectedExpectation
                    clientDisconnectedExpectation: (XCTestExpectation*) clientDisconnectedExpectation;
@end

@implementation ReceivingServerEventsHandler
-(instancetype)initWithClientConnectedExpectation: (XCTestExpectation*) clientConnectedExpectation
                    clientDisconnectedExpectation: (XCTestExpectation*) clientDisconnectedExpectation {
    self = [super init];
    if (self) {
        self->clientConnectedExpectation = clientConnectedExpectation;
        self->clientDisconnectedExpectation = clientDisconnectedExpectation;
    }
    return self;
}
-(void)newClientHasConnected: (Connection *)connection {
    if ([connection state] == active) {
        [clientConnectedExpectation fulfill];
    }
}
-(void)clientHasDisconnected:(Connection *)connection {
    if ([connection state] == closed) {
        [clientDisconnectedExpectation fulfill];
    } 
}
@end

@interface ReceivingServerEventsConditionsTests : XCTestCase
{
    Server * server;
    ReceivingServerEventsHandler * serverEventsHandler;
}
@end

@implementation ReceivingServerEventsConditionsTests
-(void)setUp {
    struct ServerConfiguration configuration;
    configuration.port = 8090;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 10;
    configuration.connectionTimeout = 3;
    configuration.chunkSize = 10;
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testConnectionStateWhenCallbacksAreReceived {
    XCTestExpectation * clientConnected = [[XCTestExpectation alloc]
                                           initWithDescription:@"Client connected and the connection is active"];
    XCTestExpectation * clientDisconnected = [[XCTestExpectation alloc]
                                              initWithDescription:@"Client disconnected and the connection is closed"];
    serverEventsHandler = [[ReceivingServerEventsHandler alloc] initWithClientConnectedExpectation:clientConnected
                                                                     clientDisconnectedExpectation:clientDisconnected];
    [server boot];
    server.delegate = serverEventsHandler;
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8090];
    [client connect];
    [self waitForExpectations:@[clientConnected] timeout:10];
    [client close];
    [self waitForExpectations:@[clientDisconnected] timeout:10];
    [server shutDown:YES];
}
@end
