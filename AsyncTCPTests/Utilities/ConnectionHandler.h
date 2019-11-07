//
//  ConnectionHandler.h
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 07/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Connection.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConnectionHandler: NSObject<ConnectionDelegate>
@property (atomic, nullable) NSMutableArray<NSData*> * data;
@end

NS_ASSUME_NONNULL_END
