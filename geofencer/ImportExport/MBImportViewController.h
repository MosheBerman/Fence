//
//  MBImportViewController.h
//  Fence
//
//  Created by Moshe Berman on 9/19/12.
//
//

#import <UIKit/UIKit.h>

#import "MBGeofenceCollection.h"

typedef NSUInteger FileMode
;
enum kFileManagerMode {
    kFileImport = 0,
    kFileExport = 1,
    kFileOpen = 2
    };

@interface MBImportViewController : UIViewController

- (id) initWithFences:(MBGeofenceCollection *)collection andMode:(FileMode)mode;

@end
