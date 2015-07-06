//
//  Constants.h
//  Pic6
//
//  Created by Raj Vir on 4/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#ifndef Pic6_Constants_h
#define Pic6_Constants_h

#define APP_NAME @"Yaga"

#define IS_IPHONE4 ([UIScreen mainScreen].bounds.size.height == 480)

#define VIEW_HEIGHT ([[UIScreen mainScreen] applicationFrame].size.height + (([UIApplication sharedApplication].statusBarHidden)?0:20))
#define VIEW_WIDTH [[UIScreen mainScreen] applicationFrame].size.width

#define NUM_TILES 96
#define TILE_WIDTH (VIEW_WIDTH/2)
#define TILE_HEIGHT (IS_IPHONE4 ? TILE_WIDTH / 1.13 : (VIEW_HEIGHT/4))

#define ENLARGED_MULTIPLIER 1.85

#define ENLARGED_WIDTH TILE_WIDTH*ENLARGED_MULTIPLIER
#define ENLARGED_HEIGHT TILE_HEIGHT*ENLARGED_MULTIPLIER

#define LOADER_WIDTH 8
#define LOADER_HEIGHT 8

#define MAX_VIDEO_DURATION 15.0 

#define ELEVATOR_MARGIN 50.0
#define CAMERA_MARGIN 50.0

#define PRIMARY_COLOR [UIColor colorWithRed: 236.0f/255.0f green: 0.0f/255.0f blue:140.0f/255.0f alpha:1.0]
#define PRIMARY_COLOR_ACCENT [UIColor blackColor]
#define SECONDARY_COLOR [UIColor colorWithRed: 5.0f/255.0f green: 135.0f/255.0f blue:195.0f/255.0f alpha:1.0]
#define TERTIARY_COLOR [UIColor colorWithRed: 139.0f/255.0f green: 5.0f/255.0f blue:195.0f/255.0f alpha:1.0]

#define BIG_FONT @"Avenir"
#define BOLD_FONT @"Avenir-Black"
#define CAPTION_FONT @"AvenirNextCondensed-Bold"
#define THIN_FONT @"HelveticaNeue-UltraLight"

//notifications
#define GROUP_WILL_REFRESH_NOTIFICATION         @"GROUP_WILL_REFRESH_NOTIFICATION"
#define GROUP_DID_REFRESH_NOTIFICATION          @"GROUP_DID_REFRESH_NOTIFICATION"
#define GROUP_DID_CHANGE_NOTIFICATION           @"GROUP_DID_CHANGE_NOTIFICATION"
#define GROUPS_REFRESHED_NOTIFICATION           @"GROUPS_REFRESHED_NOTIFICATION"

#define RECORDED_VIDEO_IS_SHOWABLE_NOTIFICAITON     @"RECORDED_VIDEO_IS_SHOWABLE_NOTIFICAITON"
#define BEGIN_CREATE_GROUP_FROM_VIDEO_NOTIFICATION  @"BEGIN_CREATE_GROUP_FROM_VIDEO_NOTIFICATION"
#define DID_CREATE_GROUP_FROM_VIDEO_NOTIFICATION    @"DID_CREATE_GROUP_FROM_VIDEO_NOTIFICATION"

#define VIDEO_CHANGED_NOTIFICATION              @"VIDEO_CHANGED_NOTIFICATION"
#define VIDEO_WILL_DELETE_NOTIFICATION          @"VIDEO_WILL_DELETE_NOTIFICATION"
#define VIDEO_DID_DELETE_NOTIFICATION           @"VIDEO_DID_DELETE_NOTIFICATION"
#define OPEN_VIDEO_NOTIFICATION                 @"OPEN_VIDEO_NOTIFICATION"

#define SCROLL_TO_CELL_INDEXPATH_NOTIFICATION   @"SCROLL_TO_CELL_INDEXPATH_NOTIFICATION"

#define VIDEO_DID_DOWNLOAD_PART_NOTIFICATION    @"VIDEO_DID_DOWNLOAD_PART_NOTIFICATION"

#define OPEN_GROUP_OPTIONS_NOTIFICATION         @"OPEN_GROUP_OPTIONS_NOTIFICATION"

#define kVideoDownloadNotificationUserInfoKey   @"kVideoDownloadingNotificationName"

#define kDefaultUsername                        @"Unknown user"

#define YA_DEVICE_TOKEN                         @"YAGA_DEVICE_TOKEN"

#define kNewVideos                              @"newVideos"
#define kUpdatedVideos                          @"updatedVideos"

#define kShouldReloadVideoCell                  @"kShouldReloadVideoCell"

//first start tooltips
#define kFirstVideoRecorded                     @"kFirstVideoRecorded"
#define kCellWasAlreadyTapped                   @"kCellWasAlreadyTapped"
#define kLikeTooltipShown                       @"kLikeTooltipShown"
#define kSwipeDownShown                         @"kSwipeDownTooltipShown"

//upload gif
#define kGIFUploadCredentials                   @"kGIFUploadCredentials"

#define kShowPullDownToRefreshWhileRefreshingGroup @"kShowPullDownToRefreshWhileRefreshingGroup"

#define MIXPANEL_TOKEN @"154e8ff6623bbd104cbccc881adfd0b0"
#define MIXPANEL_DEBUG_TOKEN @"30b5e350abfdd51dad650da6c8213af6"

#define kPaginationDefaultThreshold 40

#define COMMENTS_FONT_SIZE 17.f

#define kMaxUsersShownInList (5)

#define kMaxEventsFetchedPerVideo (99)

#define kCountryCode        @"kCountryCode"

#define kFindGroupsCachedResponse @"kFindGroupsCachedResponse"

#define kLastYagaUsersRequestDate @"kLastYagaUsersRequestDate"

// Captions
#define STANDARDIZED_DEVICE_WIDTH 320.f
#define STANDARDIZED_CAPTION_PADDING 5.f
#define MAX_CAPTION_WIDTH (STANDARDIZED_DEVICE_WIDTH - (2 * STANDARDIZED_CAPTION_PADDING))
#define CAPTION_SCREEN_MULTIPLIER (VIEW_WIDTH / STANDARDIZED_DEVICE_WIDTH)
#define CAPTION_INSET_PROPORTION 0.05f
#define CAPTION_FONT_SIZE 54.0
#define CAPTION_STROKE_WIDTH 3.f

// Comments
#define COMMENTS_BOTTOM_MARGIN 50.f
#define COMMENTS_SIDE_MARGIN 9.f
#define COMMENTS_SPACE_AFTER_USERNAME 6.f
#define COMMENTS_HEIGHT_PROPORTION 0.25f
#define COMMENTS_TEXT_FIELD_HEIGHT 40.f
#define COMMENTS_SEND_WIDTH 70.f

#define recordButtonWidth 60.0f
#define GIF_GRID_UNSEEN @"gifsUnseen"

#define DEBUG_SERVER 1

#endif
