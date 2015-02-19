
// User type
typedef UInt64 DFUserIDType;

// Photo types
typedef UInt64 DFPhotoIDType;
typedef NS_OPTIONS(unsigned int, DFImageType) {
  DFImageNone,
  DFImageFull,
  DFImageThumbnail,
};

typedef UInt64 DFShareInstanceIDType;
typedef UInt64 DFStrandIDType;
typedef UInt64 DFInviteIDType;

typedef NS_OPTIONS(unsigned int, DFFeedType) {
  DFInboxFeed,
  DFSwapsFeed,
  DFPrivateFeed,
  DFActionsFeed,
};

// Permissions
typedef NSString *DFPermissionType;
extern DFPermissionType const DFPermissionRemoteNotifications;
extern DFPermissionType const DFPermissionLocation;
extern DFPermissionType const DFPermissionPhotos;
extern DFPermissionType const DFPermissionContacts;

// Permission States
typedef NSString *DFPermissionStateType;

extern DFPermissionStateType const DFPermissionStateNotRequested;
extern DFPermissionStateType const DFPermissionStateRequested;
extern DFPermissionStateType const DFPermissionStatePreRequestedNotNow;
extern DFPermissionStateType const DFPermissionStatePreRequestedYes;
extern DFPermissionStateType const DFPermissionStateGranted;
extern DFPermissionStateType const DFPermissionStateDenied;
extern DFPermissionStateType const DFPermissionStateUnavailable;
extern DFPermissionStateType const DFPermissionStateRestricted;

// Screens
typedef enum {
  DFScreenNone = -1,
  DFScreenCamera,
  DFScreenGallery
} DFScreenType;

// Push notif types
typedef enum {
  NOTIFICATIONS_NEW_PHOTO_ID = 1,
  NOTIFICATIONS_JOIN_STRAND_ID = 2,
  NOTIFICATIONS_PHOTO_FAVORITED_ID = 3,
  NOTIFICATIONS_FETCH_GPS_ID = 4,
  NOTIFICATIONS_RAW_FIRESTARTER_ID = 5,
  NOTIFICATIONS_PHOTO_FIRESTARTER_ID = 6,
  NOTIFICATIONS_REFRESH_FEED = 7,
  NOTIFICATIONS_SOCKET_REFRESH_FEED = 8,
  NOTIFICATIONS_INVITED_TO_STRAND = 9,
  NOTIFICATIONS_ACCEPTED_INVITE = 10,
  NOTIFICATIONS_RETRO_FIRESTARTER = 11,
  NOTIFICATIONS_UNACCEPTED_INVITE_FS = 12,
  NOTIFICATIONS_PHOTO_COMMENT = 13,
  NOTIFICATIONS_NEW_SUGGESTION = 14,
} DFPushNotifType;

typedef NSString *DFUIActionType;
extern DFUIActionType DFUIActionButtonPress;
extern DFUIActionType DFUIActionDoubleTap;

typedef UInt64 DFPeanutActionType;
extern DFPeanutActionType DFPeanutActionFavorite;
extern DFPeanutActionType DFPeanutActionComment;
extern DFPeanutActionType DFPeanutActionAddedPhotos;
extern DFPeanutActionType DFPeanutActionEvalPhoto;
extern DFPeanutActionType DFPeanutActionSuggestedPhoto;

// common block type
typedef void(^DFVoidBlock)(void);
typedef void(^DFSuccessBlock)(void);
typedef void(^DFFailureBlock)(NSError *error);
typedef void (^ImageLoadCompletionBlock)(UIImage *image);

