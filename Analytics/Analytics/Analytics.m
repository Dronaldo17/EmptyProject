//
//  Analytics.m
//  Analytics
//
//  Created by doujingxuan on 13-6-17.
//  Copyright (c) 2013年 SpriteApp Inc. All rights reserved.
//

#import "Analytics.h"
#define CHANNELID @"Develop"
#define UMeng_AppKey @"513c31915270155822000004"

@implementation Analytics
/*Ronaldo    统计数据时调用的方法*/
+(void)addAnalytics:(NSString*)analyticsString{
    [MobClick event:analyticsString];
}
/*Ronaldo    对umeng和flurry初始化*/
+(void)AnalyticsStart{
    //    NSString * flurryAppkey = [NSString stringWithCString:"D49LPN8MF34IWYLS7RTR"
    //                                                 encoding:NSUTF8StringEncoding];
    //    [FlurryAnalytics startSession:flurryAppkey];
    /*stary umeng trace log*/
    [MobClick startWithAppkey:UMeng_AppKey reportPolicy:REALTIME channelId:CHANNELID];
}


@end
