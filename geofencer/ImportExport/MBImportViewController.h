//
//  MBImportViewController.h
//  Fence
//
//  Created by Moshe Berman on 9/19/12.
//
//

#import <UIKit/UIKit.h>

#import "MBGeofenceCollection.h"

@interface MBImportViewController : UIViewController

- (id) initWithFences:(MBGeofenceCollection *)collection;

@end
