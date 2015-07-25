//
//  YAProgressView.h
//  Yaga
//
//  Created by valentinkovalski on 2/3/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "UCZProgressView.h"

@interface YAProgressView : UCZProgressView
- (void)setCustomText:(NSString*)text;
- (void)configureIndeterminatePercent:(CGFloat)percent;
@end
