//
//  NameGroupViewController.h
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NameGroupViewController : UIViewController
@property (strong, nonatomic) NSMutableArray *membersDic;
@property (nonatomic, assign) BOOL embeddedMode;

- (IBAction)unwindToGrid:(UIStoryboardSegue *)segue;
@end
