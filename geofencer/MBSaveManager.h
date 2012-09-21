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

- (BOOL) saveFences:(MBGeofenceCollection *)fences toDirectory:(NSURL *)directory;
- (BOOL) saveFence:(MBGeofence *)fence toDirectory:(NSURL *)directory asJSON:(BOOL)useJSON;

- (BOOL) saveFenceToLibrary:(MBGeofence *)fence;
- (BOOL) saveFenceToDocumentsDirectory:(MBGeofence *)fence;

- (BOOL) deleteFenceNamed:(NSString *)name;

#pragma mark - Name to Fence Method

- (MBGeofence *) fenceWithNameInLibrary:(NSString *)name;
- (MBGeofence *) fenceWithNameInDocumentsDirectory:(NSString *)name;

#pragma mark - File Import Methods

- (NSArray *) JSONFilesAvailableForImport;
- (NSArray *) JSONFilesAvailableForExport;
- (NSArray *) JSONFilesAvailableForOpen;

- (NSUInteger) numberOfJSONFilesAvailableForImport;
- (NSUInteger) numberOfJSONFilesAvailableForExport;
- (NSUInteger) numberOfJSONFilesAvailableForOpen;

@end
