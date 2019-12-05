//
//  SocketPortCollisionTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 02/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface SocketPortCollisionTests: XCTestCase
{
    Server * server;
}
@end

@implementation SocketPortCollisionTests
-(void)setUp {
    ServerConfiguration * configuration = [[ServerConfiguration alloc] initWithPort:9000
                                                            maximalConnectionsCount:1
                                                                          chunkSize:10
                                                                  connectionTimeout:3
                                                         eventLoopMicrosecondsDelay:10
                                                      errorsBeforeConnectionClosing:3];
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testCollidingPorts {
    int serverSocket;
    struct sockaddr_in address;
        serverSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (serverSocket == -1) {
        XCTFail("Socket creation failed");
    }
    bzero(&address, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    address.sin_port = htons(9000);
    if ((bind(serverSocket, (struct sockaddr*)&address, sizeof(address))) != 0) {
        XCTFail("Could not bind port");
    }
    if ((listen(serverSocket, 5)) != 0) {
        XCTFail("Could not start listening");
    }
    @try {
        [server boot];
        XCTFail("Boot should not be successful when port cannot be reused");
    } @catch(BootingException * exception) {
        
    } @finally {
        [server shutDown:true];
        if (close(serverSocket) != 0) {
            XCTFail("Could not close the socket");
        }
    }
}
@end
