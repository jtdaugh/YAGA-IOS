//
//  PData.h
//  Pic6
//
//  Created by Raj Vir on 5/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface PData : NSObject
+ (id)currentUser;

@property (strong, nonatomic) Firebase *firebase;
@end
