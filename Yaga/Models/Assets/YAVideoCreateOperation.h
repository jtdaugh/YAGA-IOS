//
//  YAVideoCreateOperation.h
//  Yaga
//
//  Created by Iegor on 1/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import "YAGroup.h" 
#import <Foundation/Foundation.h>

@interface YAVideoCreateOperation : NSOperation
- (instancetype)initRecordingURL:(NSURL*)recordingURL group:(YAGroup*)group video:(YAVideo*)video;
@end
