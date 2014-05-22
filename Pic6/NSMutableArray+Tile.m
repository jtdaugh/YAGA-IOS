//
//  NSMutableArray+Tile.m
//  
//
//  Created by Raj Vir on 5/20/14.
//
//

#import "NSMutableArray+Tile.h"

@implementation NSMutableArray (Tile)
- (Tile *) tileForSnapshotName:(NSString *)name {
    Tile *toReturn;
    for(Tile *tile in self){
        if([tile.data.name isEqualToString:name]){
            toReturn = tile;
        }
    }
    return toReturn;
}
@end
