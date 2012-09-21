//
//  MBImportViewController.m
//  Fence
//
//  Created by Moshe Berman on 9/19/12.
//
//

#import "MBFileManagerViewController.h"

#import "MBSaveManager.h"

typedef void(^MBFileOperationCompletionBlock)(BOOL successful);

@interface MBFileManagerViewController () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *fileTableView;
@property (strong, nonatomic) MBSaveManager *saveManager;
@property (strong, nonatomic) MBGeofenceCollection *fences;
@property (strong, nonatomic) NSMutableArray *actionQueue;
@property (assign, nonatomic) FileMode mode;
@end

@implementation MBFileManagerViewController

- (id) initWithFences:(MBGeofenceCollection *)collection andMode:(FileMode)mode{
    
    self = [super initWithNibName:@"MBFileManagerViewController" bundle:nil];
    
    if (self) {
        _fences = collection;
        _saveManager = [[MBSaveManager alloc] init];
        _actionQueue = [@[] mutableCopy];
        _mode = mode;
    }
    
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configureButtons];
    
    NSString *title = NSLocalizedString(@"Import Fences", @"Title for the import view.");
    
    if ([self mode] == kFileOpen) {
        title = NSLocalizedString(@"Open Fence", @"Title for the Open Fence view");
    }else if([self mode] == kFileExport){
        title = NSLocalizedString(@"Export Fences", @"Title for the export view.");
    }

    [self setTitle:title];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setFileTableView:nil];
    [super viewDidUnload];
}

#pragma mark - UITableView Delegate 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    NSUInteger numberOfJSONFiles = [[self saveManager] numberOfJSONFilesAvailableForImport];
    
    if ([self mode] == kFileOpen) {
        numberOfJSONFiles = [[self saveManager] numberOfJSONFilesAvailableForOpen];
    }else if([self mode] == kFileExport){
        numberOfJSONFiles = [[self saveManager] numberOfJSONFilesAvailableForExport];
    }

    return MAX(numberOfJSONFiles, 1);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
    }
    
    NSUInteger row = [indexPath row];
    
    NSArray *results = [[self saveManager] JSONFilesAvailableForImport];
    
    if ([self mode] == kFileOpen) {
        results = [[self saveManager] JSONFilesAvailableForOpen];
    }else if([self mode] == kFileExport){
        results = [[self saveManager] JSONFilesAvailableForExport];
    }
    
    
    NSString *title = NSLocalizedString(@"No Fences", @"A label for when there's no fence.");
    
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    
    [[cell textLabel] setTextColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
    
    if ([results count]) {
        title = results[row];
        [[cell textLabel] setTextAlignment:NSTextAlignmentLeft];
        [[cell textLabel] setTextColor:[UIColor blackColor]];
        
        [cell setAccessoryType:UITableViewCellEditingStyleNone];
        
        title = results[row];
    }
    
    [[cell textLabel] setText:title];
    
    if ([[self actionQueue] containsObject:title]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *availableItems = [[self saveManager] JSONFilesAvailableForExport];
    NSInteger index = [indexPath row];
    NSString *selectedObject = availableItems[index];
    
    if(![[self actionQueue] containsObject:selectedObject]){
        [[self actionQueue] addObject:selectedObject];
    }else{
        [[self actionQueue] removeObject:selectedObject];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return NSLocalizedString(@"GeoJSON Files", @"A title for the section of the table which shows JSON files");
}

#pragma mark - UIBarButton Items

- (void) configureButtons{
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStyleDone target:self action:@selector(importAndDismiss)];
    
    NSString *title = NSLocalizedString(@"Import", @"A button for the import view to begin the import process.");
    
    if ([self mode] == kFileOpen) {
        title = NSLocalizedString(@"Open", @"A button to open files");
        [doneButton setAction:@selector(openFences)];
    }else if([self mode] == kFileExport){
        title = NSLocalizedString(@"Export", @"A button to export files");
        [doneButton setAction:@selector(exportAndDismiss)];
    }
    
    [doneButton setTitle:title];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(importAndDismiss)];
    
    [[self navigationItem] setRightBarButtonItem:doneButton];
    
    [[self navigationItem] setLeftBarButtonItem:cancelButton];
}

- (void) importAndDismiss{
    [self importFences:[self actionQueue] completion:^(BOOL successful) {
        if (successful) {
           [self dismiss];
        }else{
            //  TODO: Failed to import, show some sort of error.
        }
    }];
}

- (void) exportAndDismiss{
    [self exportFences:[self actionQueue] completion:^(BOOL successful) {
        if (successful) {
            [self dismiss];
        }else{
            //  TODO: Failed to import, show some sort of error.
        }
    }];
}

- (void) openFences{
    [self openFences:[self actionQueue] completion:^(BOOL successful) {
        if (successful) {
            [self dismiss];
        }else{
            //  TODO: Failed to import, show some sort of error.
        }
    }];
}



- (void) dismiss{
    [[[self navigationController] presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Import/Export/Open Method

- (void) importFences:(NSArray *)fencesToImport completion:(MBFileOperationCompletionBlock)completion{
 
    BOOL successful = YES;
    
    for (NSString *fenceName in [self actionQueue]) {
        
        //  Copy fences over to caches directory
        //  fail if a fence fails.
        
        MBGeofence *fence = [[self saveManager] fenceWithNameInDocumentsDirectory:fenceName];
        
        if (![[self saveManager] saveFenceToLibrary:fence]){
            successful = NO;
            break;
        }
    }
    
    if (completion) {
        completion(successful);
    }
}

- (void) exportFences:(NSArray *)fencesToImport completion:(MBFileOperationCompletionBlock)completion{
    
    BOOL successful = YES;
    
    for (NSString *fenceName in [self actionQueue]) {
        
        //  Copy fences over to documents directory
        //  fail if a fence fails.
        
                MBGeofence *fence = [[self saveManager] fenceWithNameInLibrary:fenceName];
        
        if (![[self saveManager] saveFenceToDocumentsDirectory:fence]){
            successful = NO;
            break;
        }
    }
    
    if (completion) {
        completion(successful);
    }
}


- (void) openFences:(NSArray *)fencesToImport completion:(MBFileOperationCompletionBlock)completion{
    
    BOOL successful = YES;
    
    for (NSString *fenceName in [self actionQueue]) {
        
        //  Copy fences over to the fence colletion
        //  fail if a fence fails.
        
        MBGeofence *fence = [[self saveManager] fenceWithNameInLibrary:fenceName];
        
        [[self fences] addFence:fence andMakeActive:NO];
        
    }
    
    if (completion) {
        completion(successful);
    }
}

@end
