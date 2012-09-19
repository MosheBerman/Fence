//
//  MBSaveManager.h
//  Fence
//
//  Created by Moshe Berman on 9/19/12.
//
//

#import <Foundation/Foundation.h>

#import "MBGeofenceCollection.h"

@interface MBSaveManager : NSObject

- (void) saveAsSingleFileToCachesDirectory:(MBGeofenceCollection*)fences;
- (void) saveIndividualFencesToCachesDirectory:(MBGeofenceCollection *)fences;

- (void)saveToDocumentsDirectory:(MBGeofenceCollection *)fences;

@end
