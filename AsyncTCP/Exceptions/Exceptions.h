//
//  Exceptions.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 15/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BootingException: NSException
@end

@interface ShuttingDownException: NSException
@end

@interface IdentityCreationException: NSException
@end

NS_ASSUME_NONNULL_END
