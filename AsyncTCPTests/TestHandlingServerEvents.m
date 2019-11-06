//
//  TestHandlingServerEvents.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <netdb.h>

#import "Server.h"
#import "NetworkManager.h"
#import "IONetworkHandler.h"
#import "ServerConfiguration.h"
#import "FileDescriptorConfigurator.h"


@interface ServerHandler: NSObject<ServerDelegate>
@property (atomic, nullable) Connection * lastConnection;
@end

@implementation ServerHandler
- (instancetype)init {
    self = [super init];
    if (self) {
        self.lastConnection = nil;
    }
    return self;
}
-(void)newClientHasConnected: (Connection*) connection {
    [self setLastConnection:connection];
}
@end


@interface TestHandlingServerEvents : XCTestCase
{
    Server * asyncServer;
    ServerHandler * serverHandler;
    struct ServerConfiguration configuration;
}
@end

@implementation TestHandlingServerEvents
-(void)setUp {
    configuration.port = 47850;
    configuration.chunkSize = 36;
    configuration.connectionTimeout = 5;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 400;
    serverHandler = [[ServerHandler alloc] init];
    asyncServer = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testReceivingEvents {
    asyncServer.delegate = serverHandler;
    [asyncServer boot];
    char *hostname = "localhost";
    struct sockaddr_in serv_addr;
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        XCTFail("Cannot open the socket");
    }
    struct hostent * server = gethostbyname(hostname);
    if (server == NULL) {
        XCTFail("No such host");
    }
    bzero((char *) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    bcopy((char *)server->h_addr, (char *)&serv_addr.sin_addr.s_addr, server->h_length);
    serv_addr.sin_port = htons(configuration.port);
    if (connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) {
        XCTFail("Port is closed");
    }
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        sleep(1);
        XCTAssertNotNil(self->serverHandler.lastConnection);
        XCTAssertEqual([self->serverHandler.lastConnection state], active);
    });
    dispatch_group_notify(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        [self->asyncServer shutDown];
        XCTAssertEqual([self->serverHandler.lastConnection state], closed);
    });
}
@end
