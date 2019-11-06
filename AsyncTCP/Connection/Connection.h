//
//  Connection.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ConnectionState.h"
#import "ConnectionDelegate.h"
#import "../IO/IONetworkHandleable.h"
#import "../NetworkManager/NetworkManageable.h"


NS_ASSUME_NONNULL_BEGIN

@interface Connection : NSObject
@property (atomic, nullable) NSObject<ConnectionDelegate>* delegate;
-(instancetype) initWithAddress: (struct sockaddr_in) address
                  addressLength: (socklen_t) addressLength
                     descriptor: (int) descriptor
                      chunkSize: (ssize_t) chunkSize
                      ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
                 networkManager: (NSObject<NetworkManageable>*) networkManager;
-(BOOL)enqueueDataForSending: (NSData*) data;
-(void)performIO;
-(ConnectionState)state;
-(void)requestClosing;
-(NSTimeInterval)lastInteractionInterval;
@end

NS_ASSUME_NONNULL_END
