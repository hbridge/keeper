#import "DFTypedefs.h"




// Permission types
DFPermissionType const DFPermissionRemoteNotifications = @"RemoteNotifications";
DFPermissionType const DFPermissionLocation = @"Location";
DFPermissionType const DFPermissionPhotos = @"Photos";
DFPermissionType const DFPermissionContacts = @"Contacts";


// Permission states
DFPermissionStateType const DFPermissionStateNotRequested = @"NotRequested";
DFPermissionStateType const DFPermissionStateRequested = @"Requested";
DFPermissionStateType const DFPermissionStatePreRequestedNotNow = @"PreRequestedNotNow";
DFPermissionStateType const DFPermissionStatePreRequestedYes = @"PreRequestedYes";
DFPermissionStateType const DFPermissionStateGranted = @"Granted";
DFPermissionStateType const DFPermissionStateDenied = @"Denied";
DFPermissionStateType const DFPermissionStateUnavailable = @"Unavailable";
DFPermissionStateType const DFPermissionStateRestricted = @"Restricted";

DFUIActionType DFUIActionButtonPress = @"ButtonPress";
DFUIActionType DFUIActionDoubleTap = @"DoubleTap";

DFPeanutActionType DFPeanutActionFavorite = 0;
DFPeanutActionType DFPeanutActionAddedPhotos = 2;
DFPeanutActionType DFPeanutActionComment = 4;
DFPeanutActionType DFPeanutActionEvalPhoto = 5;
DFPeanutActionType DFPeanutActionSuggestedPhoto = 6;

