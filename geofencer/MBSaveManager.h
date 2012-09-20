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

- (BOOL) deleteFenceNamed:(NSString *)name;

#pragma mark - File Import Methods

- (NSUInteger) numberOfJSONFilesAvailableForImport;
- (NSUInteger) numberOfXMLFilesAvailableForImport;

- (NSArray *) XMLFilesAvailableForImport;
- (NSArray *) JSONFilesAvailableForImport;
@end
