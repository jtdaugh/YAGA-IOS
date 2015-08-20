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
#define TILE_HEIGHT TILE_WIDTH 
//(IS_IPHONE4 ? TILE_WIDTH / 1.13 : (VIEW_HEIGHT/4))

#define ENLARGED_MULTIPLIER 1.85

#define ENLARGED_WIDTH TILE_WIDTH*ENLARGED_MULTIPLIER
#define ENLARGED_HEIGHT TILE_HEIGHT*ENLARGED_MULTIPLIER

#define LOADER_WIDTH 8
#define LOADER_HEIGHT 8

#define PLAYER_TURNED_DOWN_AUDIO 0.3f

#define MIN_VIDEO_DURATION 0.5
#define MAX_VIDEO_DURATION 10.0
#define RECORDING_BACKUP_INTERVAL 60
#define MAXIMUM_TRIM_TOTAL_LENGTH 20

#define ELEVATOR_MARGIN 50.0
#define CAMERA_MARGIN 50.0

#define PRIMARY_COLOR [UIColor colorWithRed: 236.0f/255.0f green: 0.0f/255.0f blue:140.0f/255.0f alpha:1.0]
#define PRIMARY_COLOR_ACCENT [UIColor blackColor]
#define SECONDARY_COLOR [UIColor colorWithRed: 60.0f/255.0f green: 178.0f/255.0f blue:226.0f/255.0f alpha:1.0]
#define TERTIARY_COLOR [UIColor colorWithRed: 139.0f/255.0f green: 5.0f/255.0f blue:195.0f/255.0f alpha:1.0]

#define HOSTING_GROUP_COLOR PRIMARY_COLOR
#define PRIVATE_GROUP_COLOR [UIColor colorWithWhite:0.2 alpha:1]
#define PUBLIC_GROUP_COLOR [UIColor blackColor]
#define MUTED_GROUP_COLOR [UIColor colorWithWhite:0.75 alpha:1]

#define BIG_FONT @"Avenir"
#define BOLD_FONT @"Avenir-Black"
#define CAPTION_FONT @"AvenirNextCondensed-Bold"
#define THIN_FONT @"HelveticaNeue-UltraLight"

//notifications
#define GROUP_WILL_REFRESH_NOTIFICATION         @"GROUP_WILL_REFRESH_NOTIFICATION"
#define GROUP_DID_REFRESH_NOTIFICATION          @"GROUP_DID_REFRESH_NOTIFICATION"
#define GROUPS_REFRESHED_NOTIFICATION           @"GROUPS_REFRESHED_NOTIFICATION"

#define VIDEO_CHANGED_NOTIFICATION              @"VIDEO_CHANGED_NOTIFICATION"
#define VIDEO_WILL_DELETE_NOTIFICATION          @"VIDEO_WILL_DELETE_NOTIFICATION"
#define VIDEO_DID_DELETE_NOTIFICATION           @"VIDEO_DID_DELETE_NOTIFICATION"
#define VIDEO_REJECTED_OR_APPROVED_NOTIFICATION @"VIDEO_REJECTED_OR_APPROVED"
#define OPEN_VIDEO_NOTIFICATION                 @"OPEN_VIDEO_NOTIFICATION"

#define VIDEO_DID_DOWNLOAD_PART_NOTIFICATION    @"VIDEO_DID_DOWNLOAD_PART_NOTIFICATION"

#define OPEN_GROUP_OPTIONS_NOTIFICATION         @"OPEN_GROUP_OPTIONS_NOTIFICATION"
#define OPEN_GROUP_GRID_NOTIFICATION            @"OPEN_GROUP_GRID_NOTIFICATION"

#define kVideoDownloadNotificationUserInfoKey   @"kVideoDownloadingNotificationName"

#define kDefaultUsername                        @"Unknown user"

#define YA_DEVICE_TOKEN                         @"YAGA_DEVICE_TOKEN"

#define kResultsAreForPendingVideos             @"pendingVideos"
#define kNewVideos                              @"newVideos"
#define kUpdatedVideos                          @"updatedVideos"
#define kDeletedVideos                          @"deletedVideos"

#define kShouldReloadVideoCell                  @"kShouldReloadVideoCell"

//video page
#define CAPTION_DEFAULT_SCALE 0.75f
#define CAPTION_WRAPPER_INSET 100.f

#define CAPTION_BUTTON_HEIGHT 80.f
#define CAPTION_DONE_PROPORTION 0.5

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

#define kNumberOfItemsAboveToDownload 4
#define kNumberOfItemsBelowToDownload 12

#define COMMENTS_FONT_SIZE 17.f
#define LIKE_COUNT_SIZE 13.f

#define kMaxUsersShownInList (5)

#define kMaxEventsFetchedPerVideo (99)

#define kCountryCode        @"kCountryCode"

#define kFindGroupsCachedResponse @"kFindGroupsCachedResponse"

#define kLastYagaUsersRequestDate   @"kLastYagaUsersRequestDate"
#define kYagaUsersRequested         @"kYagaUsersRequested"

#define kLastPublicGroupsRequestDate @"kLastPublicGroupsRequestDate"

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

#define CAMERA_BUTTON_SIZE 140.f
#define NAV_BAR_HEIGHT 64.f

#define recordButtonWidth 60.0f
#define GIF_GRID_UNSEEN @"gifsUnseen"

#define CAPTION_OVERWRITING_ALLOWED 1

#define DEBUG_SERVER 1

// Sharing
#define kNewGroupCellId @"postToNewGroupCell"
#define kCrosspostCellId @"crossPostCell"
#define VIEW_HEIGHT_PROPORTION 0.7f

// Server

#define API_ENDPOINT @"/yaga/api/v1"

#if (DEBUG && DEBUG_SERVER)
//#define HOST @"http://a8f4c4cc.ngrok.io"
//#define PORTNUM 80
#define HOST @"https://api-dev.yagaprivate.com"
#define PORTNUM 443
#else
#define HOST @"https://api.yagaprivate.com"
#define PORTNUM 443
#endif

#define YA_RESPONSE_ID                  @"id"
#define YA_RESPONSE_PRIVATE             @"private"
#define YA_RESPONSE_NAME                @"name"
#define YA_RESPONSE_GROUP               @"group"
#define YA_RESPONSE_NAMER               @"namer"
#define YA_RESPONSE_FONT                @"font"
#define YA_RESPONSE_NAME_X              @"name_x"
#define YA_RESPONSE_NAME_Y              @"name_y"
#define YA_RESPONSE_SCALE               @"scale"
#define YA_RESPONSE_ROTATION            @"rotation"
#define YA_RESPONSE_LIKES               @"likes"
#define YA_RESPONSE_LIKERS              @"likers"
#define YA_RESPONSE_MEMBERS             @"members"
#define YA_RESPONSE_PENDING_MEMBERS     @"pending_members"
#define YA_RESPONSE_FOLLOWER_COUNT      @"follower_count"
#define YA_RESPONSE_MEMBER_PHONE        @"phone"
#define YA_RESPONSE_MEMBER_JOINED_AT    @"joined_at"
#define YA_RESPONSE_RESULT              @"result"
#define YA_RESPONSE_RESULTS             @"results"
#define YA_RESPONSE_USER                @"user"
#define YA_RESPONSE_TOKEN               @"token"
#define YA_RESPONSE_APPROVED            @"approved"

#define YA_VIDEO_POST                   @"post"
#define YA_VIDEO_POSTS                  @"posts"
#define YA_VIDEO_ATTACHMENT             @"attachment"
#define YA_VIDEO_ATTACHMENT_PREVIEW     @"attachment_preview"
#define YA_VIDEO_READY_AT               @"ready_at"
#define YA_VIDEO_DELETED                @"deleted"
#define YA_GROUP_UPDATED_AT             @"updated_at"
#define YA_GROUP_LAST_FOREIGN_POST_ID   @"last_foreign_post_id"


//server side paging
#define YA_RESPONSE_COUNT               @"count"
#define YA_RESPONSE_NEXT                @"next"

// API

#define API_USER_PROFILE_TEMPLATE           @"%@/user/profile/"
#define API_USER_DEVICE_TEMPLATE            @"%@/user/device/"

#define API_USER_SEARCH_TEMPLATE            @"%@/user/search/"

#define API_AUTH_TOKEN_TEMPLATE             @"%@/auth/obtain/"
#define API_AUTH_BY_SMS_TEMPLATE            @"%@/auth/request/"

#define API_GROUPS_TEMPLATE                 @"%@/groups/"
#define API_PUBLIC_GROUPS_TEMPLATE          @"%@/groups/public/"
#define API_GROUP_TEMPLATE                  @"%@/groups/%@/"
#define API_GROUP_JOIN_TEMPLATE             @"%@/groups/%@/join/"
#define API_GROUP_FOLLOW_TEMPLATE           @"%@/groups/%@/follow/"

#define API_MUTE_GROUP_TEMPLATE             @"%@/groups/%@/mute/"

#define API_GROUPS_DISCOVER_TEMPLATE        @"%@/groups/discover/"

#define API_GROUP_MEMBERS_TEMPLATE          @"%@/groups/%@/members/"

#define API_GROUP_POSTS_TEMPLATE            @"%@/groups/%@/posts/"
#define API_GROUP_POST_TEMPLATE             @"%@/groups/%@/posts/%@/"

#define API_GROUP_POST_APPROVE              @"%@/groups/%@/posts/%@/approve/"
#define API_GROUP_POST_REJECT               @"%@/groups/%@/posts/%@/reject/"

#define API_GROUP_POST_LIKE                 @"%@/groups/%@/posts/%@/like/"
#define API_GROUP_POST_LIKERS               @"%@/groups/%@/posts/%@/likers/"

#define API_GROUP_POST_COPY                 @"%@/groups/%@/posts/%@/copy/"

#define API_PUBLIC_STREAM_TEMPLATE          @"%@/posts/list/?since=%lu&limit=%lu&offset=%lu"
#define API_MY_STREAM_TEMPLATE              @"%@/posts/my/?since=%lu&limit=%lu&offset=%lu"

#define API_GROUPS_SEARCH_TEMPLATE          @"%@/groups/search/?name=%@"

#define kPublicStreamGroupId                @"_PublicStream_"
#define kMyStreamGroupId                    @"_MyStream_"
#define kStreamItemsOnPage                  30
#define kPopupsShown                        @"kPopupsShown"

#endif
