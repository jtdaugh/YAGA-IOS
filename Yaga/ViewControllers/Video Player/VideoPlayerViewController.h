//This file is part of MyVideoPlayer.
//
//MyVideoPlayer is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//MyVideoPlayer is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with MyVideoPlayer.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoPlayerView.h"

/* Asset keys */
#define kTracksKey  @"tracks"
#define kPlayableKey  @"playable"

/* PlayerItem keys */
#define kStatusKey          @"status"
#define kCurrentItemKey	 @"currentItem"

@interface VideoPlayerViewController : UIViewController 

@property (nonatomic, copy) NSURL *URL;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) VideoPlayerView *playerView;

@property (nonatomic, assign) CGRect originalRect;
@property (nonatomic, weak) UIView *originalParentView;
@property (nonatomic, assign) BOOL pendingReplay;
@end