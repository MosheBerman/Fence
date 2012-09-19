//
//  MBImportViewController.m
//  Fence
//
//  Created by Moshe Berman on 9/19/12.
//
//

#import "MBImportViewController.h"

#import "MBSaveManager.h"

#import "MBGeofenceCollection.h"

@interface MBImportViewController () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *fileTableView;
@property (strong, nonatomic) MBSaveManager *saveManager;
@property (strong, nonatomic) MBGeofenceCollection *fences;
@end

@implementation MBImportViewController

- (id) initWithFences:(MBGeofenceCollection *)collection{
    
    self = [super initWithNibName:@"MBImportViewController" bundle:nil];
    
    if (self) {
        _fences = collection;
        _saveManager = [[MBSaveManager alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
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
    
    NSUInteger numberOfJSONFiles = [[self saveManager] numberOfJSONFilesAvailableForReading];
    
    NSUInteger numberOfXMLFiles = [[self saveManager] numberOfXMLFilesAvailableForReading];
    
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    }
    
    NSUInteger section = [indexPath row];
    
    [[cell textLabel] setText:@""];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return NSLocalizedString(@"JSON Files", @"A title for the section of the table which shows JSON files");
    }
    
    return NSLocalizedString(@"Property Lists", @"A title for the section of the table which shows JSON files");
}

@end
