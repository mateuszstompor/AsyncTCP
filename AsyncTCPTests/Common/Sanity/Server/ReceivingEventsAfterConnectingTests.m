//
//  ReceivingEventsAfterConnectingTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

#import "TCPTestsClient.h"

@interface ServerEventsHandler: NSObject<ServerDelegate>
{
    XCTestExpectation* clientConnectedExpectation;
}
-(instancetype)initWithClientConnectedExpectation: (XCTestExpectation*) expectation;
@end

@implementation ServerEventsHandler
-(instancetype)initWithClientConnectedExpectation: (XCTestExpectation*) expectation {
    self = [super init];
    if (self) {
        clientConnectedExpectation = expectation;
    }
    return self;
}
-(void)newClientHasConnected: (Connection *)connection {
    [clientConnectedExpectation fulfill];
}
-(void)clientHasDisconnected:(Connection *)connection {
    
}
@end

@interface ReceivingEventsAfterConnectingTests : XCTestCase
{
    Server * server;
    ServerEventsHandler * serverEventsHandler;
}
@end

@implementation ReceivingEventsAfterConnectingTests
-(void)setUp {
    struct ServerConfiguration configuration;
    configuration.port = 8090;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 10;
    configuration.connectionTimeout = 3;
    configuration.chunkSize = 10;
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testReceivingEventsWhenClientConnectsAndDelegateIsSet {
    XCTestExpectation * delegateHasReceivedEvent = [[XCTestExpectation alloc]
                                                    initWithDescription:@"Make sure that delegate receives an event when new client connects"];
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8090];
    serverEventsHandler = [[ServerEventsHandler alloc] initWithClientConnectedExpectation:delegateHasReceivedEvent];
    server.delegate = serverEventsHandler;
    [server boot];
    [client connect];
    [self waitForExpectations:@[delegateHasReceivedEvent] timeout:10 enforceOrder:YES];
    [client close];
    [server shutDown];
}
-(void)testReceivingEventsWhenClientConnectsAndDelegateIsNotSet {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8090];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [server boot];
    [self waitForExpectations:@[clientHasConnected] timeout:10];
    [client close];
    [server shutDown];
}
@end
