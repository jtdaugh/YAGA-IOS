//
//  YAEvent.h
//  Yaga
//
//  Created by Jesse on 6/1/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

typedef NS_ENUM(NSUInteger, YAEventType) {
    YAEventTypeComment,
    YAEventTypeLike,
    YAEventTypePost,
};

@interface YAEvent : NSObject

@property (nonatomic, assign) YAEventType eventType;

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSString *timestamp;

- (NSDictionary *)toDictionary;

+ (YAEvent *)eventWithSnapshot:(FDataSnapshot *)snapshot;
+ (YAEvent *)eventForCreationOfVideo:(YAVideo *)video;


@end
