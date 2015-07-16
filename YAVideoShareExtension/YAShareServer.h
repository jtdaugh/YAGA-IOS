//
//  YAShareServer.h
//  Yaga
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 *  Lightweight server object based on \c YAServer that is just used for getting a user's groups
 */
@interface YAShareServer : NSObject

+ (YAShareServer *)sharedServer;

@end
