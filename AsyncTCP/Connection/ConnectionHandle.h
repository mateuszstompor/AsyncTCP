//
//  ConnectionHandle.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ConnectionDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ConnectionHandle<NSObject>
@property (atomic, nullable) NSObject<ConnectionDelegate>* delegate;
-(BOOL)enqueueDataForSending: (NSData*) data;
-(ConnectionState)state;
-(void)close;
@end

NS_ASSUME_NONNULL_END
