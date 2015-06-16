//
//  YAViewCountManager.m
//  Yaga
//
//  Created by Jesse on 6/15/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAViewCountManager.h"

#import <Firebase/Firebase.h>

#import "YAUser.h"

#define FIREBASE_VC_ROOT (@"https://yaga-dev.firebaseio.com/view_counts")

@interface YAViewCountManager ()

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, readwrite) NSUInteger myViewCount;
@property (nonatomic, readwrite) NSUInteger othersViewCount;

@property (nonatomic, strong) Firebase *viewCountRoot;
@property (nonatomic, strong) Firebase *currentVideoRef;

@end

@implementation YAViewCountManager

+ (instancetype)sharedManager {
    static YAViewCountManager *sharedInstance = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.viewCountRoot = [[Firebase alloc] initWithUrl:FIREBASE_VC_ROOT];
        _myViewCount = 0;
        _othersViewCount = 0;
        _videoId = nil;
    }
    return self;
}

- (void)switchVideoId:(NSString *)videoId {
    [self.currentVideoRef removeAllObservers];
    self.currentVideoRef = [self.viewCountRoot childByAppendingPath:videoId];
    __weak YAViewCountManager *weakSelf = self;
    [self.currentVideoRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        int othersCount = 0;
        for (FDataSnapshot *child in snapshot.children) {
            NSUInteger val = [child.value unsignedIntValue];
            NSString *username = child.key;
            if ([username isEqualToString:[YAUser currentUser].username]) {
                weakSelf.myViewCount = val;
            } else {
                othersCount += val;
            }
        }
        weakSelf.othersViewCount = othersCount;
        [weakSelf.viewCountDelegate updatedWithMyViewCount:weakSelf.myViewCount
                                            otherViewCount:weakSelf.othersViewCount];
    }];
}

- (void)addViewToCurrentVideo {
    [[self.currentVideoRef childByAppendingPath:[YAUser currentUser].username]
        runTransactionBlock:^FTransactionResult *(FMutableData *currentData) {
        NSNumber *value = currentData.value;
        if (currentData.value == [NSNull null]) {
            value = 0;
        }
        [currentData setValue:[NSNumber numberWithInt:(1 + [value intValue])]];
        return [FTransactionResult successWithValue:currentData];
    }];
}

- (void)killMonitoring {
    [self.currentVideoRef removeAllObservers];
}

@end
