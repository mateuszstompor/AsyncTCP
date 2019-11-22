//
//  SendingDataTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 21/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

#import "TCPTestsClient.h"

@interface SendingDataServerHandler: NSObject<ServerDelegate>
{
    XCTestExpectation * successfulDataSending;
    XCTestExpectation * clientHasConnected;
    XCTestExpectation * clientHasDisconnected;
    Connection * connection;
}
-(instancetype)initWithExpectectionAfterSuccessfulDataSending: (XCTestExpectation *) successfulDataSending
                                           clientHasConnected: (XCTestExpectation *) clientHasConnected
                                        clientHasDisconnected: (XCTestExpectation *) clientHasDisconnected;
-(BOOL)sendData: (NSData *) data;
@end

@implementation SendingDataServerHandler
-(instancetype)initWithExpectectionAfterSuccessfulDataSending: (XCTestExpectation *) successfulDataSending
                                           clientHasConnected: (XCTestExpectation *) clientHasConnected
                                        clientHasDisconnected: (XCTestExpectation *) clientHasDisconnected {
    self = [super init];
    if (self) {
        self->connection = nil;
        self->successfulDataSending = successfulDataSending;
        self->clientHasConnected = clientHasConnected;
        self->clientHasDisconnected = clientHasDisconnected;
    }
    return self;
}
-(void)clientHasDisconnected:(nonnull Connection *)connection {
    [clientHasDisconnected fulfill];
}
-(void)newClientHasConnected:(nonnull Connection *)connection {
    self->connection = connection;
    [clientHasConnected fulfill];
}
-(BOOL)sendData: (NSData *) data {
    [successfulDataSending fulfill];
    return [connection enqueueDataForSending:data];
}
@end

@interface SendingDataTests : XCTestCase
{
    SendingDataServerHandler * handler;
    Server * server;
}
@end

@implementation SendingDataTests
-(void)setUp {
    struct ServerConfiguration configuration;
    configuration.port = 8091;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 10;
    configuration.connectionTimeout = 5;
    configuration.chunkSize = 10;
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testEventsReceivedWhileConnectionDelegateIsNotSet {
    XCTestExpectation * clientDisconnected = [[XCTestExpectation alloc] initWithDescription:@"Client has disconnected"];
    XCTestExpectation * clientConnectedCallback = [[XCTestExpectation alloc] initWithDescription:@"Client has connected"];
    XCTestExpectation * dataSendExpectation = [[XCTestExpectation alloc] initWithDescription:@"Data send to client successfully"];
    handler = [[SendingDataServerHandler alloc] initWithExpectectionAfterSuccessfulDataSending:dataSendExpectation
                                                                            clientHasConnected:clientConnectedCallback
                                                                         clientHasDisconnected:clientDisconnected];
    server.delegate = handler;
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    [server boot];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    XCTAssertTrue([handler sendData:[@"hello" dataUsingEncoding:NSUTF8StringEncoding]]);
    [self waitForExpectations:@[clientConnectedCallback, dataSendExpectation, clientDisconnected] timeout:10 enforceOrder:YES];
    [client close];
    [server shutDown];
}
-(void)testSendingDataWhileConnectionDelegateIsNotSet {
    XCTestExpectation * clientConnected = [[XCTestExpectation alloc] initWithDescription:@"Client has connected"];
    handler = [[SendingDataServerHandler alloc] initWithExpectectionAfterSuccessfulDataSending:nil
                                                                            clientHasConnected:clientConnected
                                                                         clientHasDisconnected:nil];
    server.delegate = handler;
    [server boot];
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected, clientConnected] timeout:4];
    NSString * literalToSend = @"hello";
    NSInteger length = [literalToSend length];
    XCTAssertTrue([handler sendData:[literalToSend dataUsingEncoding:NSUTF8StringEncoding]]);
    void * buffer[length * 10];
    XCTAssertEqual([client readToBuffer:buffer size:length * 10], length);
    NSData * dataReceived = [NSData dataWithBytes:buffer length:5];
    XCTAssertTrue([[[NSString alloc] initWithData:dataReceived encoding:NSUTF8StringEncoding] isEqualToString:literalToSend]);
    [client close];
    [server shutDown];
}
-(void)testSendingDataWhileConnectionIsClosed {
    XCTestExpectation * clientDisconnected = [[XCTestExpectation alloc]
                                              initWithDescription:@"Client has disconnected"];
    handler = [[SendingDataServerHandler alloc] initWithExpectectionAfterSuccessfulDataSending:nil
                                                                            clientHasConnected:nil
                                                                         clientHasDisconnected:clientDisconnected];
    server.delegate = handler;
    [server boot];
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:4 enforceOrder:YES];
    [self waitForExpectations:@[clientDisconnected] timeout:10];
    NSString * literalToSend = @"hello";
    NSInteger length = [literalToSend length];
    XCTAssertFalse([handler sendData:[literalToSend dataUsingEncoding:NSUTF8StringEncoding]]);
    void * buffer[10];
    XCTAssertEqual([client readToBuffer:buffer size:length * 10], 0);
    [client close];
    [server shutDown];
}
@end
