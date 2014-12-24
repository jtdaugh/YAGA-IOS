//
//  YAUtils.h
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^uploadDataCompletionBlock)(NSError *error);

@interface YAUtils : NSObject
+ (NSString *)readableNumberFromString:(NSString*)input;
+ (void)uploadVideoRecoringFromUrl:(NSURL *)localUrl completion:(uploadDataCompletionBlock)completion;
+ (UIColor*)inverseColor:(UIColor*)color;
+ (NSString*)cachesDirectory;
+ (NSString *)hashedStringFromString:(NSString *)input;
+ (NSURL*)urlFromFileName:(NSString*)fileName;
@end
