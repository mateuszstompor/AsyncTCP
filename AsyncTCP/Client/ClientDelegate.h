//
//  ClientDelegate.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 15/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class Connection;

@protocol ClientDelegate<NSObject>
-(void)connectionHasBeenEstablished: (Connection *) connection;
@end

NS_ASSUME_NONNULL_END
