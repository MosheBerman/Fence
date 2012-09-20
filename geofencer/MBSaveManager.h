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

- (BOOL) saveFences:(MBGeofenceCollection *)fences toDirectory:(NSURL *)directory;
- (BOOL) saveFence:(MBGeofence *)fence toDirectory:(NSURL *)directory asJSON:(BOOL)useJSON;

- (void)saveToDocumentsDirectory:(MBGeofenceCollection *)fences;


#pragma mark - File Import Methods

- (NSUInteger) numberOfJSONFilesAvailableForImport;
- (NSUInteger) numberOfXMLFilesAvailableForImport;

- (NSArray *) XMLFilesAvailableForImport;
- (NSArray *) JSONFilesAvailableForImport;
@end
