//
//  LifeCycleTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <netdb.h>

#import "Server.h"
#import "IONetworkHandler.h"
#import "ServerConfiguration.h"

@interface LifeCycleTests : XCTestCase
{
    Server * asyncServer;
    struct ServerConfiguration configuration;
    NSObject<IONetworkHandleable>* ioHandler;
}
@end

@implementation LifeCycleTests
-(void)setUp {
    configuration.port = 47850;
    configuration.connectionTimeout = 5;
    configuration.chunkSize = 36;
    configuration.eventLoopMicrosecondsDelay = 400;
    configuration.maximalConnectionsCount = 1;
    ioHandler = [[IONetworkHandler alloc] init];
    asyncServer = [[Server alloc] initWithConfiguratoin:configuration ioHandler:ioHandler];
}
-(void)testBootAndShutdown {
    [asyncServer boot];
    char *hostname = "localhost";
    int sockfd;
    struct sockaddr_in serv_addr;
    struct hostent *server;
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        XCTFail("Cannot open the socket");
    }
    server = gethostbyname(hostname);
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
    [asyncServer shutDown];
    if (connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) >= 0) {
        XCTFail("Port is not closed");
    }
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    [asyncServer boot];
    if (connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) {
        XCTFail("Port is closed");
    }
    close(sockfd);
    [asyncServer shutDown];
    if (connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) >= 0) {
        XCTFail("Port is not closed");
    }
}
@end
