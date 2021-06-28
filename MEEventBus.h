//
//  MEEventBus.h
//  BindingX
//
//  Created by ylin on 2021/6/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 事件订阅
#define MEEventSubscriber(P, OBS) [MEEventBus.shared subscriberWithProtocol:@protocol(P) observer:OBS]

// 取消订阅
#define MEEventUnSubscriber(P, OBS) [MEEventBus.shared unsubscriberWithProtocol:@protocol(P) observer:OBS]

// 取消一个订阅者的所有消息, 一般是订阅者即将销毁时
#define MEEventUnSubscriberAll(OBS) [MEEventBus.shared unsubscriberWithObserver:OBS]
#define MEEventUnSubscriberHandle(OBS) [MEEventBus.shared unsubscriberWithObserver:OBS]

// 事件发布
#define MEEventPublisher(P) ((id<P>)__protocol_dispatcher_forwarder(@protocol(P)))
id __protocol_dispatcher_forwarder(Protocol *p);

@protocol MEEventSubscriberHandle <NSObject>

/// 强引用订阅者, 默认false
@property BOOL isStrong;

/// 主线程接收消息, 默认false
@property BOOL isMain;

/// 主线程接收消息是, 是否同步 默认false
@property BOOL isSync;

@end

/**
 
 基于协议的消息事件
 较之 NSNotificationCenter, 不同之处在于
 使用协议替换NSNotificationCenter的字符串
 遵循协议订阅和发布消息, 业务中使用清晰参数清晰, 减少数据转换逻辑
 
 #注意: 只有MEEventSubscriberHandle.isStrong 为true时, unsubscriber才是必须调用的
 但是业务端也应保持自律, 显示的调用取消订阅
 
 */
@interface MEEventBus : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

+ (instancetype)shared;

// 添加订阅, 重复添加不生效, 如果相同的协议和相同的实例重复调用此方法, 会返回上一次的Handle
- (id<MEEventSubscriberHandle>)subscriberWithProtocol:(Protocol *)protocol
                                             observer:(id)observer;

// 取消订阅
- (void)unsubscriberWithProtocol:(Protocol *)protocol
                        observer:(id)observer;

// 取消订阅, 可传入添加订阅时得到的Handle或者订阅者实例
- (void)unsubscriberWithObserver:(id)observerOrHandle;

@end

NS_ASSUME_NONNULL_END
