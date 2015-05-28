//
//  YARealmMigrationManager.m
//  Yaga
//
//  Created by valentinkovalski on 4/23/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YARealmMigrationManager.h"

@implementation YARealmMigrationManager

- (void)executeMigrations {
    NSUInteger bundleVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"YARealmSchemaVersion"] integerValue];
    
    [RLMRealm setSchemaVersion:bundleVersion
                forRealmAtPath:[RLMRealm defaultRealmPath]
            withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
//                if (oldSchemaVersion < 1) {
//                    // The enumerateObjects:block: method iterates
//                    // over every 'Person' object stored in the Realm file
//                    [migration enumerateObjects:Person.className
//                                          block:^(RLMObject *oldObject, RLMObject *newObject) {
//                                              
//                                              // combine name fields into a single field
//                                              newObject[@"fullName"] = [NSString stringWithFormat:@"%@ %@",
//                                                                        oldObject[@"firstName"],
//                                                                        oldObject[@"lastName"]];
//                                          }];
//                }
            }];

}

@end
