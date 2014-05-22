//
//  NSMutableArray+Tile.h
//  
//
//  Created by Raj Vir on 5/20/14.
//
//

#import <Foundation/Foundation.h>
#import "Tile.h"

@interface NSMutableArray (Tile)
- (Tile *) tileForSnapshotName:(NSString *)name;
@end
