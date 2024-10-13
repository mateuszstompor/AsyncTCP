//
//  Dispatchable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol Dispatchable<NSObject>
-(void)async: (dispatch_block_t) block;
@end

NS_ASSUME_NONNULL_END
