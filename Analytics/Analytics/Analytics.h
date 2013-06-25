//
//  Analytics.h
//  Analytics
//
//  Created by doujingxuan on 13-6-17.
//  Copyright (c) 2013年 SpriteApp Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobClick.h"

@interface Analytics : NSObject

+(void)AnalyticsStart;
+(void)addAnalytics:(NSString*)analyticsString;
@end
