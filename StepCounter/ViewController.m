//
//  ViewController.m
//  StepCounter
//
//  Created by Joe on 15/6/11.
//  Copyright (c) 2015年 Joe. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController ()
{
    UILabel *lbHKData;
    UILabel *lbCMData;
    NSDateFormatter *formatter;
}
@property (nonatomic, strong) CMPedometer *pedometer;
@property (nonatomic, strong) HKHealthStore *healthStore;
@end

@implementation ViewController

- (void)queryHealthData
{
    HKQuantityType *stepType =[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    NSDate *now = [NSDate date];
    
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay
                                               fromDate:now];
    
    NSDate *beginOfDay = [calendar dateFromComponents:components];
    
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:beginOfDay endDate:now options:HKQueryOptionStrictStartDate];
    
    HKStatisticsQuery *squery = [[HKStatisticsQuery alloc] initWithQuantityType:stepType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            HKQuantity *quantity = result.sumQuantity;
            double step = [quantity doubleValueForUnit:[HKUnit countUnit]];
            lbHKData.text = [NSString stringWithFormat:@"%.0f",step];
        });
    }];
    [self.healthStore executeQuery:squery];
}

- (void)readHealthKitData
{
    if([HKHealthStore isHealthDataAvailable])
    {
        HKQuantityType *stepType =[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        [self.healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObject:stepType] completion:^(BOOL success, NSError *error) {
            if(success)
            {
                [self queryHealthData];
            }
        }];
    }else{
        lbHKData.text = @"0";
    }
}

- (void)readCoreMotionData
{
    if([CMPedometer isStepCountingAvailable])
    {
        NSDate *now = [NSDate date];
        
        NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay
                                                   fromDate:now];
        
        NSDate *beginOfDay = [calendar dateFromComponents:components];
        [self.pedometer queryPedometerDataFromDate:beginOfDay toDate:now withHandler:^(CMPedometerData *pedometerData, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(error)
                {
                    lbCMData.text = @"0";
                }else{
                    lbCMData.text = [NSString stringWithFormat:@"%ld",pedometerData.numberOfSteps.integerValue];
                }
            });
        }];
    }else{
        lbCMData.text = @"0";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGFloat viewWidth = self.view.frame.size.width;
    
    UILabel *lbToday = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, viewWidth, 30)];
    [lbToday setFont:[UIFont systemFontOfSize:20]];
    [lbToday setTextAlignment:NSTextAlignmentCenter];
    [lbToday setText:@"Today's Step"];
    [self.view addSubview:lbToday];
    
    UILabel *lbHK = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, viewWidth/2, 30)];
    [lbHK setFont:[UIFont systemFontOfSize:20]];
    [lbHK setTextAlignment:NSTextAlignmentCenter];
    [lbHK setText:@"HealthKit"];
    [self.view addSubview:lbHK];
    
    lbHKData = [[UILabel alloc] initWithFrame:CGRectMake(0, 150, viewWidth/2, 50)];
    [lbHKData setFont:[UIFont systemFontOfSize:40]];
    [lbHKData setTextAlignment:NSTextAlignmentCenter];
    [lbHKData setText:@"0"];
    [self.view addSubview:lbHKData];
    
    UILabel *lbCM = [[UILabel alloc] initWithFrame:CGRectMake(viewWidth/2, 100, viewWidth/2, 30)];
    [lbCM setFont:[UIFont systemFontOfSize:20]];
    [lbCM setTextAlignment:NSTextAlignmentCenter];
    [lbCM setText:@"CoreMotion"];
    [self.view addSubview:lbCM];
    
    lbCMData = [[UILabel alloc] initWithFrame:CGRectMake(viewWidth/2, 150, viewWidth/2, 50)];
    [lbCMData setFont:[UIFont systemFontOfSize:40]];
    [lbCMData setTextAlignment:NSTextAlignmentCenter];
    [lbCMData setText:@"0"];
    [self.view addSubview:lbCMData];
    
    self.pedometer = [[CMPedometer alloc] init];
    [self readCoreMotionData];
    [self.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        [self readCoreMotionData];
    }];
    
    self.healthStore = [[HKHealthStore alloc] init];
    [self readHealthKitData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
