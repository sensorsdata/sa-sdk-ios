//
// SAConstants.h
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark - typedef
/**
 * @abstract
 * Debug 模式，用于检验数据导入是否正确。该模式下，事件会逐条实时发送到 SensorsAnalytics，并根据返回值检查
 * 数据导入是否正确。
 *
 * @discussion
 * Debug 模式的具体使用方式，请参考:
 *  http://www.sensorsdata.cn/manual/debug_mode.html
 *
 * Debug模式有三种选项:
 *   SensorsAnalyticsDebugOff - 关闭 DEBUG 模式
 *   SensorsAnalyticsDebugOnly - 打开 DEBUG 模式，但该模式下发送的数据仅用于调试，不进行数据导入
 *   SensorsAnalyticsDebugAndTrack - 打开 DEBUG 模式，并将数据导入到 SensorsAnalytics 中
 */
typedef NS_ENUM(NSInteger, SensorsAnalyticsDebugMode) {
    SensorsAnalyticsDebugOff,
    SensorsAnalyticsDebugOnly,
    SensorsAnalyticsDebugAndTrack,
};

/**
 * @abstract
 * TrackTimer 接口的时间单位。调用该接口时，传入时间单位，可以设置 event_duration 属性的时间单位。
 *
 * @discuss
 * 时间单位有以下选项：
 *   SensorsAnalyticsTimeUnitMilliseconds - 毫秒
 *   SensorsAnalyticsTimeUnitSeconds - 秒
 *   SensorsAnalyticsTimeUnitMinutes - 分钟
 *   SensorsAnalyticsTimeUnitHours - 小时
 */
typedef NS_ENUM(NSInteger, SensorsAnalyticsTimeUnit) {
    SensorsAnalyticsTimeUnitMilliseconds,
    SensorsAnalyticsTimeUnitSeconds,
    SensorsAnalyticsTimeUnitMinutes,
    SensorsAnalyticsTimeUnitHours
};


/**
 * @abstract
 * AutoTrack 中的事件类型
 *
 * @discussion
 *   SensorsAnalyticsEventTypeAppStart - $AppStart
 *   SensorsAnalyticsEventTypeAppEnd - $AppEnd
 *   SensorsAnalyticsEventTypeAppClick - $AppClick
 *   SensorsAnalyticsEventTypeAppViewScreen - $AppViewScreen
 */
typedef NS_OPTIONS(NSInteger, SensorsAnalyticsAutoTrackEventType) {
    SensorsAnalyticsEventTypeNone      = 0,
    SensorsAnalyticsEventTypeAppStart      = 1 << 0,
    SensorsAnalyticsEventTypeAppEnd        = 1 << 1,
    SensorsAnalyticsEventTypeAppClick      = 1 << 2,
    SensorsAnalyticsEventTypeAppViewScreen = 1 << 3,
};

/**
 * @abstract
 * 网络类型
 *
 * @discussion
 *   SensorsAnalyticsNetworkTypeNONE - NULL
 *   SensorsAnalyticsNetworkType2G - 2G
 *   SensorsAnalyticsNetworkType3G - 3G
 *   SensorsAnalyticsNetworkType4G - 4G
 *   SensorsAnalyticsNetworkTypeWIFI - WIFI
 *   SensorsAnalyticsNetworkTypeALL - ALL
 *   SensorsAnalyticsNetworkType5G - 5G   
 */
typedef NS_OPTIONS(NSInteger, SensorsAnalyticsNetworkType) {
    SensorsAnalyticsNetworkTypeNONE         = 0,
    SensorsAnalyticsNetworkType2G API_UNAVAILABLE(macos, tvos)    = 1 << 0,
    SensorsAnalyticsNetworkType3G API_UNAVAILABLE(macos, tvos)    = 1 << 1,
    SensorsAnalyticsNetworkType4G API_UNAVAILABLE(macos, tvos)    = 1 << 2,
    SensorsAnalyticsNetworkTypeWIFI     = 1 << 3,
    SensorsAnalyticsNetworkTypeALL      = 0xFF,
#ifdef __IPHONE_14_1
    SensorsAnalyticsNetworkType5G API_UNAVAILABLE(macos, tvos)   = 1 << 4
#endif
};

/// 事件类型
typedef NS_OPTIONS(NSUInteger, SAEventType) {
    SAEventTypeTrack = 1 << 0,
    SAEventTypeSignup = 1 << 1,
    SAEventTypeBind = 1 << 2,
    SAEventTypeUnbind = 1 << 3,

    SAEventTypeProfileSet = 1 << 4,
    SAEventTypeProfileSetOnce = 1 << 5,
    SAEventTypeProfileUnset = 1 << 6,
    SAEventTypeProfileDelete = 1 << 7,
    SAEventTypeProfileAppend = 1 << 8,
    SAEventTypeIncrement = 1 << 9,

    SAEventTypeItemSet = 1 << 10,
    SAEventTypeItemDelete = 1 << 11,

    SAEventTypeDefault = 0xF,
    SAEventTypeAll = 0xFFFFFFFF,
};

typedef NSString *SALimitKey NS_TYPED_EXTENSIBLE_ENUM;
FOUNDATION_EXTERN SALimitKey const SALimitKeyIDFA;
FOUNDATION_EXTERN SALimitKey const SALimitKeyIDFV;

typedef NS_ENUM(NSInteger, SAResourcesLanguage) {
    SAResourcesLanguageChinese,
    SAResourcesLanguageEnglish,
};


/// SDK Internal notifications, please should not use
extern NSNotificationName const SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION;

