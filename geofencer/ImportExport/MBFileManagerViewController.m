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
@property (strong, nonatomic) NSMutableArray *importQueue;
@property (assign, nonatomic) FileMode mode;
@end

@implementation MBFileManagerViewController

- (id) initWithFences:(MBGeofenceCollection *)collection andMode:(FileMode)mode{
    
    self = [super initWithNibName:@"MBFileManagerViewController" bundle:nil];
    
    if (self) {
        _fences = collection;
        _saveManager = [[MBSaveManager alloc] init];
        _importQueue = [@[] mutableCopy];
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
    
    NSUInteger numberOfXMLFiles = [[self saveManager] numberOfXMLFilesAvailableForImport];
    
    if (section == 0) {
        return MAX(numberOfJSONFiles, 1);
    }
    
    return MAX(numberOfXMLFiles, 1);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
    }
    
    NSUInteger row = [indexPath row];
    
    NSUInteger section = [indexPath section];
    
    NSArray *results = [[self saveManager] JSONFilesAvailableForImport];
    
    if (section == 1) {
        results = [[self saveManager] XMLFilesAvailableForImport];
    }
    
    
    NSString *title = NSLocalizedString(@"No Fences", @"A label for when there's no fence.");
    
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    
    [[cell textLabel] setTextColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
    
    if ([results count]) {
        title = results[row];
        [[cell textLabel] setTextAlignment:NSTextAlignmentLeft];
        [[cell textLabel] setTextColor:[UIColor blackColor]];
    }
    
    [[cell textLabel] setText:title];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return NSLocalizedString(@"GeoJSON Files", @"A title for the section of the table which shows JSON files");
    }
    
    return NSLocalizedString(@"Property Lists", @"A title for the section of the table which shows JSON files");
}

#pragma mark - UIBarButton Items

- (void) configureButtons{
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", @"A button for the import view to begin the import process.") style:UIBarButtonItemStyleDone target:self action:@selector(importAndDismiss)];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(importAndDismiss)];
    
    [[self navigationItem] setRightBarButtonItem:doneButton];
    
    [[self navigationItem] setLeftBarButtonItem:cancelButton];
}

- (void) importAndDismiss{
    [self importFences:[self importQueue] completion:^(BOOL successful) {
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

#pragma mark - Import Method

- (void) importFences:(NSArray *)fencesToImport completion:(MBFileOperationCompletionBlock)completion{
 
    BOOL successful = YES;
    
    for (NSString *fence in [self importQueue]) {
        
        //  Copy fences over to caches directory
        //  fail if a fence fails.
    }
    
    if (completion) {
        completion(successful);
    }
}

@end
