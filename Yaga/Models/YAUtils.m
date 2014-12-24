//
//  YAUtils.m
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAUtils.h"
#import "NBPhoneNumberUtil.h"
#import <CommonCrypto/CommonDigest.h>

@implementation YAUtils

+ (NSString *)readableNumberFromString:(NSString*)input {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:input defaultRegion:@"US" error:&aError];
    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&aError];
    return num;
}

+ (void)uploadVideoRecoringFromUrl:(NSURL *)localUrl completion:(uploadDataCompletionBlock)completion {
    completion(nil);
    //NSData *videoData = [NSData dataWithContentsOfURL:localUrl];
    //val TODO:
    
    //    // measure size of data
    //    NSLog(@"%@ size: %lu", type, (unsigned long)[data length]);
    //
    //    // set up data object
    //    NSString *videoData = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    ////    Firebase *dataObject = [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@", MEDIA]] childByAutoId];
    ////    NSString *dataPath = dataObject.name;
    //
    //    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:outputURL options:nil];
    //    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    //    [imageGenerator setAppliesPreferredTrackTransform:YES];
    //    //    UIImage* image = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
    //    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMake(0,1) actualTime:nil error:nil];
    //
    //    UIImage *image = [[UIImage imageWithCGImage:imageRef] imageScaledToFitSize:CGSizeMake(VIEW_WIDTH, VIEW_HEIGHT/2)];
    //    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
    //    //NSString *imageString = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    //
    //    NSArray *colors = [image getColors];
    //
    //    //    for(NSString *color in colors){
    //    //        NSLog(@"color: %@", color);
    //    //    }
    //
    ////    [dataObject setValue:@{@"video":videoData, @"thumb":imageString} withCompletionBlock:^(NSError *error, Firebase *ref) {
    ////    }];
    //
    //    //    NSMutableDictionary *clique = (NSMutableDictionary *)[PFUser currentUser][@"clique"];
    //    //    [clique setObject:@1 forKeyedSubscript:[PFUser currentUser][@"phoneHash"]];
    //
    //    //    for(NSString *hash in clique){
    //    //        NSLog(@"hash: %@", hash);
    //    //        NSString *escapedHash = [hash stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    //    //        NSString *path = [NSString stringWithFormat:@"%@/%@/%@", STREAM, escapedHash, dataPath];
    //    //        [[[[CNetworking currentUser] firebase] childByAppendingPath:path] setValue:@{@"type": type, @"user":(NSString *)[[CNetworking currentUser] userDataForKey:@"username"], @"colors":colors}];
    //    //    }
    //
    //    NSLog(@"group id: %@", self.YAGroup.groupId);
    //
    //    NSFileManager * fm = [[NSFileManager alloc] init];
    //    NSError *err = nil;
    //    [fm moveItemAtURL:outputURL toURL:[[self tempFilename] movieUrl] error:&err];
    //    [imageData writeToURL:[[self tempFilename] imageUrl] options:NSDataWritingAtomic error:&err];
    //
    //    if(err){
    //        NSLog(@"error: %@", err);
    //    }
    //
}

+ (UIColor*)inverseColor:(UIColor*)color {
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

+ (NSString*)cachesDirectory {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return cachePaths[0];
}

+ (NSString *)hashedStringFromString:(NSString *)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    
    // This is an iOS5-specific method.
    // It takes in the data, how much data, and then output format, which in this case is an int array.
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    // Parse through the CC_SHA256 results (stored inside of digest[]).
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

+ (NSURL*)urlFromFileName:(NSString*)fileName {
    NSString *path = [[YAUtils cachesDirectory] stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:path];
}
@end
