
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface Purchaser : NSObject<SKPaymentTransactionObserver>

- (void)addObserverForProduct:(NSString *)productId block:(void(^)(SKPaymentTransaction *transaction))block;
- (void)buyProduct:(NSString *)productId success:(void(^)(SKPaymentTransaction *transaction))successBlock error:(void(^)(NSError *error))errorBlock;
@end
