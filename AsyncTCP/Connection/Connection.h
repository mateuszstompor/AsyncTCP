//
//  Connection.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ConnectionState.h"
#import "ConnectionHandle.h"
#import "NetworkManageable.h"
#import "IONetworkHandleable.h"

NS_ASSUME_NONNULL_BEGIN

@interface Connection: NSObject<ConnectionHandle>
-(instancetype) initWithAddress: (struct sockaddr_in) address
                  addressLength: (socklen_t) addressLength
                     descriptor: (int) descriptor
                      chunkSize: (ssize_t) chunkSize;
-(instancetype) initWithAddress: (struct sockaddr_in) address
                  addressLength: (socklen_t) addressLength
                     descriptor: (int) descriptor
                      chunkSize: (ssize_t) chunkSize
              notificationQueue: (dispatch_queue_t) notificationQueue;
-(instancetype) initWithAddress: (struct sockaddr_in) address
                  addressLength: (socklen_t) addressLength
                     descriptor: (int) descriptor
                      chunkSize: (ssize_t) chunkSize
              notificationQueue: (dispatch_queue_t) notificationQueue
                      ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
                 networkManager: (NSObject<NetworkManageable>*) networkManager;
-(void)performIO;
-(NSTimeInterval)lastInteractionInterval;
@end

NS_ASSUME_NONNULL_END
