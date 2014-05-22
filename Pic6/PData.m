//
//  PData.m
//  Pic6
//
//  Created by Raj Vir on 5/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "PData.h"

@implementation PData

+ (id)currentUser {
    static PData *sharedPData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPData = [[self alloc] init];
    });
    return sharedPData;
}

- (id)init {
    if (self = [super init]) {
        // self.someProperty = @"Default Property Value";
    }
    
    return self;
}

- (void)initFirebase {
    self.firebase = [[[Firebase alloc] initWithUrl:@"https://pic6.firebaseIO.com"] childByAppendingPath:NODE_NAME];;
    
    [[[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", DATA]] queryLimitedToNumberOfChildren:NUM_TILES] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"new!");
    }];
}

- (void)uploadMedia:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL withParent:(NSString *)parent{
    // measure size of data
    NSLog(@"%@ size: %lu", type, (unsigned long)[data length]);
    
    // set up data object
    NSString *stringData = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    Firebase *dataObject = [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@", MEDIA]] childByAutoId];
    [dataObject setValue:stringData];
    NSString *dataPath = dataObject.name;
    
    [dataObject setValue:stringData withCompletionBlock:^(NSError *error, Firebase *ref) {
        NSFileManager * fm = [[NSFileManager alloc] init];
        NSError *err = nil;
        [fm moveItemAtURL:outputURL toURL:[self movieUrlForSnapshotName:dataPath] error:&err];
        if(err){
            NSLog(@"error: %@", err);
        }
        
        [[self.firebase childByAppendingPath:[NSString stringWithFormat:@"%@/%@", parent?REACTIONS:DATA, dataPath]] setValue:@{@"type": type, @"user":[self humanName]}];
        
    }];
    
}

- (NSString *)humanName {
    NSString *deviceName = [[UIDevice currentDevice].name lowercaseString];
    for (NSString *string in @[@"’s iphone", @"’s ipad", @"’s ipod touch", @"’s ipod",
                               @"'s iphone", @"'s ipad", @"'s ipod touch", @"'s ipod",
                               @"s iphone", @"s ipad", @"s ipod touch", @"s ipod", @"iphone"]) {
        NSRange ownershipRange = [deviceName rangeOfString:string];
        
        if (ownershipRange.location != NSNotFound) {
            return [[[deviceName substringToIndex:ownershipRange.location] componentsSeparatedByString:@" "][0]
                    stringByReplacingCharactersInRange:NSMakeRange(0,1)
                    withString:[[deviceName substringToIndex:1] capitalizedString]];
        }
    }
    
    return [UIDevice currentDevice].name;
}

- (NSURL *) movieUrlForSnapshotName:(NSString *)name {
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), name];
    NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
    return movieURL;
}


@end
