//
// Created by Derek on 13/6/20.
// Copyright (c) 2013 DerekTu. All rights reserved.


#import "StatCalculator.h"

@interface StatCalculator ()

@property (nonatomic)NSMutableArray* valueList;

@end


@implementation StatCalculator

- (id)init
{
    self = [super init];
    if (self) {
        self.trimRange = 0.0;
        self.maxSampleCount = 100;
    }
    return self;
}


- (id)initWithMaxSampleCount:(int)maxSampleCount
{
    if (![self init])
        return nil;

    self.maxSampleCount = maxSampleCount;

    return self;
}

- (id)initWithMaxSampleCount:(int)maxSampleCount trimRange:(double)trimRange
{
    if (![self init])
        return nil;

    self.maxSampleCount = maxSampleCount;
    self.trimRange = trimRange;

    return self;
}

- (NSMutableArray*)valueList
{
    if (_valueList == nil)
        _valueList = [[NSMutableArray alloc]init];

    return _valueList;
}

- (void)setMaxSampleCount:(int)maxSampleCount
{
    // trim current valueList if necessary
    //  => remove older entries
    //
    _maxSampleCount = maxSampleCount;

    if (maxSampleCount < self.valueList.count) {
        [self.valueList removeObjectsInRange:NSMakeRange(0, self.valueList.count - maxSampleCount)];

        [self calculate];
    }
}

- (void)setTrimRange:(double)trimRange
{
    _trimRange = trimRange;

    [self calculate];
}

- (void)addSampleAsNSNumber:(NSNumber*)value;
{
    [self.valueList addObject:value];

    if (self.valueList.count > self.maxSampleCount)
        [self.valueList removeObjectAtIndex:0];

    [self calculate];
}

- (void)addSample:(double)value
{
    [self addSampleAsNSNumber:@(value)];
}

- (double)getLatestSampleValue:(int)lastN
{
    if (lastN < 0 || lastN >= self.valueList.count)
        return 0;

    return [self.valueList[self.valueList.count - lastN - 1] doubleValue];
}

- (void)calculate
{
    _stat.sampleCount = 0;
    _stat.minValue = 0;
    _stat.maxValue = 0;
    _stat.meanValue = 0;

    if (self.valueList.count == 0)
        return;

    // Sort
    //
    NSMutableArray* arrayDup = [[NSMutableArray alloc] initWithArray:self.valueList copyItems:YES];
    [arrayDup sortUsingComparator:^(id obj1, id obj2){
        double value1 = [(NSNumber*)obj1 doubleValue];
        double value2 = [(NSNumber*)obj2 doubleValue];
        if (value1 < value2)
            return NSOrderedAscending;
        else if (value1 > value2)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];

    // Calculate the trim range
    //

    // Calculate min/max/average value
    //
    double sum = 0;
    int count = 0;
    double minT = DBL_MAX;
    double maxT = DBL_MIN;

    int itemTrimmed = (int)((double)self.valueList.count * self.trimRange / 100.0);
    for (int i = itemTrimmed; i < self.valueList.count - itemTrimmed; i++) {
        double value = [self.valueList[i] doubleValue];
        sum += value;
        if (value > maxT) maxT = value;
        if (value < minT) minT = value;
        count++;
    }

    if (count > 0) {
        _stat.minValue = minT;
        _stat.maxValue = maxT;
        _stat.meanValue = sum / count;
        _stat.sampleCount = self.valueList.count;
    }
}


@end
