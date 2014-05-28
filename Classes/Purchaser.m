
#import <StoreKit/StoreKit.h>
#import "Purchaser.h"
#import "ProductCache.h"

@implementation Purchaser
{
    ProductCache *_cache;
    NSMutableDictionary *_observers;
    NSMutableDictionary *_errorBlocks;
    NSMutableDictionary *_successBlocks;
}

- (id)init
{
    if (self = [super init])
    {
        _cache = [[ProductCache alloc] init];
        _observers = [[NSMutableDictionary alloc] init];
        _errorBlocks = [[NSMutableDictionary alloc] init];
        _successBlocks = [[NSMutableDictionary alloc] init];

        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    
    return self;
}

- (void)addObserverForProduct:(NSString *)productId block:(void(^)(SKPaymentTransaction *transaction))block
{
    if (!_observers[productId])
        [_observers setObject:[[NSMutableArray alloc] init] forKey:productId];
    
    NSMutableArray *array = _observers[productId];
    [array addObject:block];
}

- (void)buyProduct:(NSString *)productId success:(void(^)(SKPaymentTransaction *transaction))successBlock error:(void(^)(NSError *error))errorBlock
{
    [_cache loadProduct:productId block:^(SKProduct *product, NSError *error)
     {
         if (error)
             errorBlock(error);
         else
         {
             [_errorBlocks setObject:errorBlock forKey:productId];
             [_successBlocks setObject:successBlock forKey:productId];
             [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
         }
     }];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *t in transactions)
    {
        if (![self transactionIsComplete:t])
            continue;

        if (t.error != nil) {
            void (^errorBlock)(NSError *) = _errorBlocks[t.payment.productIdentifier];
            errorBlock(t.error);
            [_errorBlocks removeObjectForKey:t.payment.productIdentifier];
        }
        
        if ([self transactionIsSuccess:t]) {
            void (^successBlock)(SKPaymentTransaction *) = _successBlocks[t.payment.productIdentifier];
            successBlock(t);
            [_successBlocks removeObjectForKey:t.payment.productIdentifier];
            [self notifyObserversForProduct:t.payment.productIdentifier transaction:t];
        }

        [[SKPaymentQueue defaultQueue] finishTransaction:t];
    }
}

- (BOOL)transactionIsComplete:(SKPaymentTransaction *)transaction
{
    return
        transaction.transactionState == SKPaymentTransactionStatePurchased ||
        transaction.transactionState == SKPaymentTransactionStateRestored ||
        transaction.transactionState == SKPaymentTransactionStateFailed;
}

- (BOOL)transactionIsSuccess:(SKPaymentTransaction *)transaction
{
    return
        transaction.transactionState == SKPaymentTransactionStatePurchased ||
        transaction.transactionState == SKPaymentTransactionStateRestored;
}

- (void)notifyObserversForProduct:(NSString *)productId transaction:(SKPaymentTransaction *)transaction
{
    for (void(^block)(SKPaymentTransaction *) in _observers[productId])
        block(transaction);
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads
{
}

@end
