//
//  YAShareServer.m
//  Yaga
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <AVFoundation/AVFoundation.h>

#import "YAShareServer.h"
#import "Constants.h"
#import "NSDictionary+ResponseObject.h"
#import "NSData+Hex.h"
#import "NSString+Hash.h"

@implementation YAShareVideoCaption

@end


@interface YAShareServer ()

@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, strong) NSString *base_api;

@property (nonatomic, strong) AFHTTPRequestOperationManager *jsonOperationsManager;
@property (nonatomic, strong) AFHTTPRequestOperationManager *xmlOperationsManager;

@end

static YAShareServer *_sharedServer = nil;

@implementation YAShareServer

#pragma mark - Singleton

+ (YAShareServer *)sharedServer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedServer = [[YAShareServer alloc] init];
    });
    
    return _sharedServer;
}

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _base_api = [NSString stringWithFormat:@"%@:%@%@", HOST, PORT, API_ENDPOINT];
        _jsonOperationsManager = [AFHTTPRequestOperationManager manager];
        _jsonOperationsManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        _xmlOperationsManager = [AFHTTPRequestOperationManager manager];
        _xmlOperationsManager.responseSerializer = [AFXMLParserResponseSerializer serializer];
        _xmlOperationsManager.operationQueue.maxConcurrentOperationCount = 1;
        _xmlOperationsManager.requestSerializer.timeoutInterval = 60;
        
        _authToken = [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] objectForKey:YA_RESPONSE_TOKEN];
        
        if(self.authToken.length) {
            NSString *tokenString = [NSString stringWithFormat:@"Token %@", self.authToken];
            AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
            [requestSerializer setValue:tokenString forHTTPHeaderField:@"Authorization"];
            self.jsonOperationsManager.requestSerializer = requestSerializer;
        }
    }
    
    return self;
}

#pragma mark - Requests

- (void)getGroupsWithCompletion:(responseBlock)completion publicGroups:(BOOL)publicGroups
{
    if (!self.authToken.length)
        return;
    
    NSString *api = [NSString stringWithFormat:publicGroups ? API_PUBLIC_GROUPS_TEMPLATE : API_GROUPS_TEMPLATE, self.base_api];
    
    DLog(@"updating groups from server... public: %@", publicGroups ? @"Yes" : @"No");
    
    [self.jsonOperationsManager GET:api parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
        DLog(@"updated");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"can't fetch remote groups, error: %@", error.localizedDescription);
        completion(nil, error);
    }];
}


- (void)uploadVideo:(NSData *)movieData withCaption:(YAShareVideoCaption *)caption toGroupWithId:(NSString*)serverGroupId withCompletion:(YAUploadVideoResponseBlock)completion {
    if (!self.authToken.length)
        return;
    
    NSAssert(serverGroupId, @"serverGroup is a required parameter");
    
    NSString *api = [NSString stringWithFormat:API_GROUP_POSTS_TEMPLATE, self.base_api, serverGroupId];
    
    NSString *userAgent = [NSString stringWithFormat:@"YAGA IOS %@", [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"]];
    [self.jsonOperationsManager.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    // match yavideo variables with server fields.
    NSDictionary *parameters = @{
                                 @"name": caption.text,
                                 @"name_x": [NSNumber numberWithFloat:caption.x],
                                 @"name_y": [NSNumber numberWithFloat:caption.y],
                                 @"rotation": [NSNumber numberWithFloat:caption.rotation],
                                 @"scale": [NSNumber numberWithFloat:caption.scale],
                                 };
    
    [self.jsonOperationsManager POST:api
                          parameters:nil
                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                 DLog(@"uploadVideoData, recieved params for S3 upload. Making multipart upload...");
                                 
                                 NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:responseObject withError:nil];
                                 NSString *videoServerId = dict[YA_RESPONSE_ID];
//                                 dispatch_async(dispatch_get_main_queue(), ^{
                                 
//                                     [video.realm beginWriteTransaction];
//                                     video.serverId = dict[YA_RESPONSE_ID];
//                                     [video.realm commitWriteTransaction];
                                 
                                     NSDictionary *meta = dict[@"meta"];
                                     NSString *videoEndpoint = meta[@"attachment"][@"endpoint"];
                                     NSDictionary *videoFields =  meta[@"attachment"][@"fields"];
                                     
                                     //save gif upload credentials for later use
//                                     NSMutableDictionary *gifsUploadCredentials = [NSMutableDictionary dictionaryWithDictionary:[[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] objectForKey:kGIFUploadCredentials]];
//                                     [gifsUploadCredentials setObject:meta[@"attachment_preview"] forKey:video.serverId];
//                                     [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setObject:gifsUploadCredentials forKey:kGIFUploadCredentials];
                                
                                 
//                                 NSError *error;
//                                 NSData *plistData = [NSData dataWithContentsOfFile:mp4Filename options:0 error:&error];
//                                 if(!plistData) {
//                                     NSLog(@"failed to read data: %@",error);
//                                 }
//                                     NSData *videoData = [[NSFileManager defaultManager] contentsAtPath:[[self class] urlFromFileName:mp4Filename].path];
                                 
//                                     [[Mixpanel sharedInstance] timeEvent:@"Upload Video"];
                                 
                                     //gif might not be there yet, it's in progress, so uploading video at once and saving credentials for uploading gif, it will be uploaded when gif operation is done
                                     [self multipartUpload:videoEndpoint withParameters:videoFields withFile:movieData videoServerId:serverGroupId completion:^(id response, NSError *error) {
//                                         [[Mixpanel sharedInstance] track:@"Upload Video"];
                                         
//                                         if ([video isInvalidated]) {
//                                             YARealmObjectUnavailableError *yaError = [YARealmObjectUnavailableError new];
//                                             completion(videoLocalId, yaError);
//                                             return;
//                                         }
                                         
                                         //empty server id in case of an error, transaction will be executed again
//                                         if(error) {
//                                             [video.realm beginWriteTransaction];
//                                             video.serverId = @"";
//                                             video.uploadedToAmazon = NO;
//                                             [video.realm commitWriteTransaction];
//                                             
//                                             //show local notification if app is in background
//                                             if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
//                                                 UILocalNotification *localNotification = [[UILocalNotification alloc] init];
//                                                 localNotification.fireDate = [NSDate date];
//                                                 localNotification.alertBody = NSLocalizedString(@"Video failed to upload", @"");
//                                                 localNotification.alertAction = NSLocalizedString(@"Retry", @"");
//                                                 localNotification.applicationIconBadgeNumber = 1;
//                                                 [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//                                             }
//                                             
//                                         }
//                                         else {
//                                             [video.realm beginWriteTransaction];
//                                             video.uploadedToAmazon = YES;
//                                             [video.realm commitWriteTransaction];
//                                             [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:video userInfo:@{kShouldReloadVideoCell:[NSNumber numberWithBool:YES]}];
//                                             
//                                             [self executePendingCopyForVideo:video];
//                                         }
                                         
                                         //call completion block when video is posted
                                         completion(response, videoServerId, error);
                                     }];
//                                 });
                                 
                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                 completion(nil, @"", error);
                             }];
}

- (void)multipartUpload:(NSString*)endpoint withParameters:(NSDictionary*)dict withFile:(NSData*)file videoServerId:(NSString*)serverId completion:(responseBlock)completion {
    
    if(!file.length) {
        DLog(@"File is 0 bytes, can't upload");
        completion(nil, [NSError errorWithDomain:@"YADomain" code:0 userInfo:@{@"response":@"File is 0 bytes, can't upload"}]);
        return;
    }
    
    AFHTTPRequestOperation *postOperation = [self.xmlOperationsManager POST:endpoint
                                                                 parameters:dict constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                     
                                                                     [formData appendPartWithFormData:file name:@"file"];
                                                                     
                                                                 } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                     completion(operation.response, nil);
//                                                                     [self.multipartUploadsInProgress removeObjectForKey:serverId];
                                                                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                     completion(nil, error);
//                                                                     [self.multipartUploadsInProgress removeObjectForKey:serverId];
                                                                 }];
    [postOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        DLog(@"uploaded %lld out of %lld", totalBytesWritten, totalBytesExpectedToWrite);
    }];
//    [self.multipartUploadsInProgress setObject:postOperation forKey:serverId];
}

#pragma mark - Helpers

+ (NSURL*)urlFromFileName:(NSString*)fileName {
    if(!fileName.length)
        return nil;
    
    NSString *path = [[[self class] cachesDirectory] stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:path];
}

+ (NSString*)cachesDirectory {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return cachePaths[0];
}


+ (void)reformatExternalVideoAtUrl:(NSURL *)videoUrl withCompletion:(videoConcatenationCompletion)completion {
    
    AVAsset *asset = [AVAsset assetWithURL:videoUrl];
    CGSize vidSize = ((AVAssetTrack *)([asset tracksWithMediaType:AVMediaTypeVideo][0])).naturalSize;
    CGSize correctSize = [[UIScreen mainScreen] bounds].size;
    
    NSString *pathToProcessedMovie = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ProcessedMovie.mp4"];
    unlink([pathToProcessedMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *outputURL = [NSURL fileURLWithPath:pathToProcessedMovie];
    
    
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = correctSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    CGFloat yMultiple = correctSize.height / vidSize.height;
    
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    CGAffineTransform finalTransform = CGAffineTransformMakeScale(yMultiple, yMultiple);
    CGFloat dx = (((vidSize.width * yMultiple) - correctSize.width) / 2.0);
    finalTransform = CGAffineTransformTranslate(finalTransform, -dx, 0);
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    exportSession.videoComposition = videoComposition;
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
    if (duration > MAXIMUM_TRIM_TOTAL_LENGTH) {
        [exportSession setTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(MAXIMUM_TRIM_TOTAL_LENGTH, 100000))];
    }
    
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void ) {
        completion(exportSession.outputURL, CMTimeGetSeconds(exportSession.timeRange.duration), nil);
    }];
    
}

@end
