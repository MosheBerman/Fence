//
//  MBImportViewController.h
//  Fence
//
//  Created by Moshe Berman on 9/19/12.
//
//

#import <UIKit/UIKit.h>

#import "MBGeofenceCollection.h"

#define kDidHideFileManagerNotification @"did hide file manager"

typedef NSUInteger FileMode;

enum kFileManagerMode {
    kFileImport = 0,
    kFileExport = 1,
    kFileOpen = 2
    };

@interface MBFileManagerViewController : UIViewController

- (id) initWithFences:(MBGeofenceCollection *)collection andMode:(FileMode)mode;

@end
