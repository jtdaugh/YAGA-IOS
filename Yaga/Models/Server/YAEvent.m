//
//  YAEvent.m
//  Yaga
//
//  Created by Jesse on 6/1/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAEvent.h"
#import "YAUser.h"

@implementation YAEvent

+ (YAEvent *)eventWithSnapshot:(FDataSnapshot *)snapshot {
    YAEvent *event = [YAEvent new];
    if (![snapshot.key length]) {
        return nil;
    }
    event.key = snapshot.key;
    event.username = snapshot.value[@"username"];

    NSString *type = snapshot.value[@"type"];
    if ([type isEqualToString:@"comment"]) {
        event.eventType = YAEventTypeComment;
        event.comment = snapshot.value[@"comment"];
    } else if ([type isEqualToString:@"like"]) {
        event.eventType = YAEventTypeLike;
    } else if ([type isEqualToString:@"post"]) {
        event.eventType = YAEventTypePost;
        event.timestamp = snapshot.value[@"timestamp"];
    } else {
        return nil;
    }
    return event;
}

+ (YAEvent *)eventForCreationOfVideo:(YAVideo *)video {
    YAEvent *event = [YAEvent new];
    event.eventType = YAEventTypePost;
    event.username = video.creator;
    event.timestamp = [[YAUser currentUser] formatDate:video.createdAt];
    return event;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"username"] = self.username;
    switch (self.eventType) {
        case YAEventTypeComment:
            dict[@"type"] = @"comment";
            dict[@"comment"] = self.comment;
            break;
        case YAEventTypeLike:
            dict[@"type"] = @"like";
            break;
        case YAEventTypePost:
            dict[@"type"] = @"post";
            dict[@"username"] = self.username;
            dict[@"timestamp"] = self.timestamp;
            break;
    }
    return dict;
}
@end
