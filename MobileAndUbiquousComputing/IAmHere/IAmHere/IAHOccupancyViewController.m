//
//  IAHOccupancyViewController.m
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHOccupancyViewController.h"
#import "IAHOccupancyObject.h"

@interface IAHOccupancyViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *occupancyTableView;
@property (strong, nonatomic) NSArray *occupancyEntries;

@end

@implementation IAHOccupancyViewController


-(NSArray *)occupancyEntries
{
    if(!_occupancyEntries) _occupancyEntries = [[NSArray alloc]init];
    return _occupancyEntries;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.occupancyTableView.dataSource = self;
    self.occupancyTableView.delegate = self;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.occupancyTableView.tableFooterView = view;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self performFetch];
}

-(void)performFetch
{
    [self fetchOccupancy:^(id responseObject) {
        if([responseObject isKindOfClass:[NSArray class]])
        {
            __block NSMutableArray *builderArray = [[NSMutableArray alloc]init];
            NSArray *responseArray = (NSArray *)responseObject;
            [responseArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                [builderArray addObject:[[IAHOccupancyObject alloc]initWithDictionary:obj]];
                
            }];
            self.occupancyEntries = [NSArray arrayWithArray:builderArray];
        }
        [self.occupancyTableView reloadData];
    }];
}



-(void)fetchOccupancy:(completionBlockWithResponseObject)complete
{
    
}

#pragma mark - UITableViewDataSource

// the methods in this protocol are what provides the View its data
// (remember that Views are not allowed to own their data)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section (we only have one)
    return [self.occupancyEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // we must be sure to use the same identifier here as in the storyboard!
    static NSString *CellIdentifier = @"OccupancyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    IAHOccupancyObject *occupancy = self.occupancyEntries[indexPath.row];
    
    cell.textLabel.text = occupancy.name;
    
    return cell;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
