//
//  CNetworking.h
//  Pic6
//
//  Created by Raj Vir on 7/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CNetworking;

@protocol CNetworkingDelegate <NSObject>
@optional
- (void)test;
@end

@interface CNetworking : NSObject
@property (nonatomic,assign)id delegate;
@property (strong, nonatomic) NSMutableDictionary *userData;

+ (id)currentUser;

- (void) saveUserData:(NSObject *)value forKey:(NSString *)key;
- (void) loadUserData;
- (NSObject *) userDataForKey:(NSString *)key;

- (void)trySomething;

@end
