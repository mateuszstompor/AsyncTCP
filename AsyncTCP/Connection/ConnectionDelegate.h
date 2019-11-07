//
//  ConnectionDelegate.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Connection;
@protocol ConnectionHandle;

NS_ASSUME_NONNULL_BEGIN

@protocol ConnectionDelegate<NSObject>
-(void)connection: (NSObject<ConnectionHandle>*) connection chunkHasArrived: (NSData*) data;
-(void)connection: (NSObject<ConnectionHandle>*) connection stateHasChangedTo: (ConnectionState) state;
@end

NS_ASSUME_NONNULL_END
