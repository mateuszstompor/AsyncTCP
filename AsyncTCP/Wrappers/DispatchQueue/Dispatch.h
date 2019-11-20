//
//  Dispatch.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Dispatchable.h"

NS_ASSUME_NONNULL_BEGIN

@interface Dispatch: NSObject<Dispatchable>
-(instancetype)initWithDispatchQueue: (dispatch_queue_t) dispatchQueue;
@end

NS_ASSUME_NONNULL_END
